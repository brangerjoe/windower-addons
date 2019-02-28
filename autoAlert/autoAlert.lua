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
playerResolution = T {}
playerResolution.x = windower.get_windower_settings().x_res
playerResolution.y = windower.get_windower_settings().y_res
caption = texts.new({})
showing = false
last_trigger = -1
trigger_duration = 3
weapon_skill_category = 7
magic_category = 8
interrupt_id = 28787

windower.register_event(
    "load",
    function()
        create_backgrounds((playerResolution.x / 2) - 250, 50)
        caption:bg_visible(false)
        caption:bold(true)
    end
)

windower.register_event(
    "postrender",
    function()
        if showing then
            local x, y = caption:extents()
            caption:pos(playerResolution.x / 2 - x / 2, 53)
            if os.time() - last_trigger > trigger_duration then
                hide_caption()
            end
        else
        end
    end
)

windower.register_event(
    "addon command",
    function(cmd, ...)
        local arg = ...
        if cmd == "ws" then
            show_caption(arg, "ws")
        elseif cmd == "ma" then
            show_caption(arg, "ma")
        end
    end
)

windower.register_event(
    "action",
    function(act)
        local target = windower.ffxi.get_mob_by_target("t") and windower.ffxi.get_mob_by_target("t").id or nil

        if not target then
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
                skill_name = "Interrupted!"
                show_caption(skill_name, "int")
            else
                show_caption(skill_name, "ma")
            end
        end
    end
)

function create_backgrounds(x, y)
    windower.prim.create(background_ability)
    windower.prim.set_fit_to_texture(background_ability, true)
    windower.prim.set_texture(background_ability, windower.addon_path .. "images/background_ability.png")
    windower.prim.set_position(background_ability, x, y)
    windower.prim.set_visibility(background_ability, false)

    windower.prim.create(background_magic)
    windower.prim.set_fit_to_texture(background_magic, true)
    windower.prim.set_texture(background_magic, windower.addon_path .. "images/background_magic.png")
    windower.prim.set_position(background_magic, x, y)
    windower.prim.set_visibility(background_magic, false)

    windower.prim.create(background_interrupt)
    windower.prim.set_fit_to_texture(background_interrupt, true)
    windower.prim.set_texture(background_interrupt, windower.addon_path .. "images/background_interrupt.png")
    windower.prim.set_position(background_interrupt, x, y)
    windower.prim.set_visibility(background_interrupt, false)
end

function show_caption(text, type)
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
    last_trigger = os.time()
end

function hide_caption()
    showing = false
    caption:hide()
    windower.prim.set_visibility(background_ability, false)
    windower.prim.set_visibility(background_magic, false)
    windower.prim.set_visibility(background_interrupt, false)
end
