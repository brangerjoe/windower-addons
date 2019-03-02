_addon.name = "autoAlert"
_addon.author = "Godchain"
_addon.version = "1.1"
_addon.commands = {"autoAlert", "aa"}

config = require("config")
texts = require("texts")
res = require("resources")

background_ability = "background_ability"
background_magic = "background_magic"
background_interrupt = "background_interrupt"
caption = texts.new({})
showing = false
last_trigger = 0
-- trigger_duration = 3
-- emphasize = {}

-- IDs
weapon_skill_category = 7
magic_category = 8
interrupt_id = 28787
-- x_position = playerResolution.x / 2
-- y_position = 50
-- background_size = "regular"

defaults = {}
defaults.x_position = windower.get_windower_settings().x_res / 2
defaults.y_position = 50
defaults.background_size = "regular"
defaults.emphasize = {}
defaults.trigger_duration = 3

settings = config.load(defaults)

windower.register_event(
    "load",
    function()
        create_backgrounds(settings.x_position - 250, settings.y_position)
        caption:bg_visible(false)
        caption:bold(true)
    end
)

windower.register_event(
    "postrender",
    function()
        if showing then
            local x, y = caption:extents()
            local x_offset = settings.x_position - x / 2
            local y_offset =
                defaults.background_size == "regular" and settings.y_position + 10 or settings.y_position + 3
            caption:pos(x_offset, y_offset)
            if os.time() - last_trigger > settings.trigger_duration then
                hide_caption()
            end
        else
        end
    end
)

windower.register_event(
    "addon command",
    function(cmd, ...)
        if not cmd or cmd == "help" then
            print("=== Usage Examples ===")
            print("//aa test ws")
            print("► Shows a test alert (accepts 'ws' for TP moves, 'ma' for magic, 'int' for interrupts).")
            print("//aa emphasize Firaga VI")
            print("► Emphasizes Firaga VI (toggles on and off).")
            print("//aa pos 960 200")
            print("► Moves the display to 960 X (horizontal) and 200 Y (vertical).")
        end

        local args = L {...}
        if cmd == "test" then
            if args[1] == "ws" then
                show_caption("Self-Destruct", "ws")
            elseif args[1] == "ma" then
                show_caption("Tornado II", "ma")
            elseif args[1] == "int" then
                show_caption("Interrupted!", "int")
            end
        elseif cmd == "emphasize" then
            local estring = args:concat(" ")
            local verb = settings.emphasize[estring:lower()] and "Removed" or "Added"
            print("Emphasize: " .. verb .. ' "' .. estring .. '".')
            settings.emphasize[estring:lower()] = settings.emphasize[estring:lower()] and false or true
        elseif cmd == "pos" then
            local x = tonumber(args[1])
            local y = tonumber(args[2])

            if type(x) == "number" and type(y) == "number" then
                settings:save()
                print("Moved display to: " .. args[1] .. ", " .. args[2])
                refresh_backgrounds()
            else
                print("Please specify x and y coordinates.")
            end
        elseif cmd == "size" then
            local size = args[1]

            if size == "small" or size == "regular" then
                settings.background_size = size
                settings:save()
                refresh_backgrounds()
                print("Display size set to " .. size .. ".")
            else
                print('Please specify "small" or "regular" for the size.')
            end
        elseif cmd == "duration" then
            local duration = tonumber(args[1])

            if type(duration) == number and duration > 0 then
                settings.trigger_duration = duration
                print("Display duration set to " .. duration .. " secs.")
            else
                print("Please specify a positive number.")
            end
        end
    end
)

windower.register_event(
    "action",
    function(act)
        local target

        if windower.ffxi.get_mob_by_target("t") and windower.ffxi.get_mob_by_target("t").is_npc then
            target = windower.ffxi.get_mob_by_target("t").id
        elseif windower.ffxi.get_mob_by_target("bt") then
            target = windower.ffxi.get_mob_by_target("bt").id
        else
            return
        end

        if act.category == weapon_skill_category and act.actor_id == target then
            local skill_name =
                res.monster_abilities[act.targets[1].actions[1].param] and
                res.monster_abilities[act.targets[1].actions[1].param].name or
                "???"

            if act.param == interrupt_id then
                skill_name = "Interrupted!"
                show_caption(skill_name, "int")
            else
                show_caption(skill_name, "ws")
            end
        elseif act.category == magic_category and act.actor_id == target then
            local spell_name =
                res.spells[act.targets[1].actions[1].param] and res.spells[act.targets[1].actions[1].param].name or
                "???"

            if act.param == interrupt_id then
                spell_name = "Interrupted!"
                show_caption(spell_name, "int")
            else
                show_caption(spell_name, "ma")
            end
        end
    end
)

function refresh_backgrounds()
    create_backgrounds(settings.x_position - 250, settings.y_position)
end

function create_backgrounds(x, y)
    windower.prim.create(background_ability)
    windower.prim.set_fit_to_texture(background_ability, true)
    windower.prim.set_texture(
        background_ability,
        windower.addon_path .. "images/" .. settings.background_size .. "/background_ability.png"
    )
    windower.prim.set_position(background_ability, x, y)
    windower.prim.set_visibility(background_ability, false)

    windower.prim.create(background_magic)
    windower.prim.set_fit_to_texture(background_magic, true)
    windower.prim.set_texture(
        background_magic,
        windower.addon_path .. "images/" .. settings.background_size .. "/background_magic.png"
    )
    windower.prim.set_position(background_magic, x, y)
    windower.prim.set_visibility(background_magic, false)

    windower.prim.create(background_interrupt)
    windower.prim.set_fit_to_texture(background_interrupt, true)
    windower.prim.set_texture(
        background_interrupt,
        windower.addon_path .. "images/" .. settings.background_size .. "/background_interrupt.png"
    )
    windower.prim.set_position(background_interrupt, x, y)
    windower.prim.set_visibility(background_interrupt, false)
end

function show_caption(text, type)
    hide_caption()
    showing = true
    caption:text(text)
    caption:show()

    if (type == "ws") then
        windower.play_sound(windower.addon_path .. "sounds/ability_alert.wav")
        windower.prim.set_visibility(background_ability, true)
    elseif (type == "ma") then
        windower.play_sound(windower.addon_path .. "sounds/magic_alert.wav")
        windower.prim.set_visibility(background_magic, true)
    elseif (type == "int") then
        windower.play_sound(windower.addon_path .. "sounds/interrupt_alert.wav")
        windower.prim.set_visibility(background_interrupt, true)
    end

    if (settings.emphasize[text:lower()]) then
        windower.play_sound(windower.addon_path .. "sounds/emphasize.wav")
    end

    last_trigger = os.time()
end

function hide_caption()
    showing = false
    caption:hide()
    windower.prim.set_visibility(background_ability, false)
    windower.prim.set_visibility(background_magic, false)
    windower.prim.set_visibility(background_interrupt, false)
end

function print(str)
    windower.add_to_chat(207, str)
end
