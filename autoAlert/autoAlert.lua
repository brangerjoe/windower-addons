_addon.name = "autoAlert"
_addon.author = "Godchain"
_addon.version = "1.0"
_addon.commands = {"autoAlert", "aa"}

config = require("config")
texts = require("texts")
res = require("resources")
packets = require("packets")
alertBox = "alertBox"
alertBox_MA = "alertBox_MA"
playerResolution = T {}
playerResolution.x = windower.get_windower_settings().x_res
playerResolution.y = windower.get_windower_settings().y_res
--settings = config.load({})
default = {}
default.Show = {
    burst = _static,
    pet = S {"BST", "SMN"},
    props = _static,
    spell = S {"SCH", "BLU"},
    step = _static,
    timer = _static,
    weapon = _static
}
caption = texts.new({})

showing = false
trigger_time = -1

windower.register_event(
    "load",
    function()
        caption:bg_visible(false)
        caption:bold(true)
        windower.prim.create(alertBox)
        windower.prim.set_fit_to_texture(alertBox, true)
        windower.prim.set_texture(alertBox, windower.addon_path .. "images/background.png")
        windower.prim.set_position(alertBox, (playerResolution.x / 2) - 250, 50)
        windower.prim.set_visibility(alertBox, false)

        windower.prim.create(alertBox_MA)
        windower.prim.set_fit_to_texture(alertBox_MA, true)
        windower.prim.set_texture(alertBox_MA, windower.addon_path .. "images/background_magic.png")
        windower.prim.set_position(alertBox_MA, (playerResolution.x / 2) - 250, 50)
        windower.prim.set_visibility(alertBox_MA, false)
    end
)

windower.register_event(
    "postrender",
    function()
        if showing then
            local x, y = caption:extents()
            caption:pos(playerResolution.x / 2 - x / 2, 53)
            if os.time() - trigger_time > 3 then
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

        if act.category == 7 and act.actor_id == target then
            local skill_name =
                res.monster_abilities[act.targets[1].actions[1].param] and
                res.monster_abilities[act.targets[1].actions[1].param].name or
                "???"
            local caption_display = act.param == 28787 and "Interrupted!" or skill_name
            show_caption(caption_display, "ws")
        elseif act.category == 8 and act.actor_id == target then
            local spell_name =
                res.spells[act.targets[1].actions[1].param] and res.spells[act.targets[1].actions[1].param].name or
                "???"

            local caption_display = act.param == 28787 and "Interrupted!" or spell_name
            show_caption(caption_display, "ma")
        end
    end
)

function show_caption(text, type)
    showing = true
    caption:text(text)
    caption:show()
    windower.play_sound(windower.addon_path .. "sounds/alert.wav")

    if (type == "ws") then
        windower.prim.set_visibility(alertBox, true)
    elseif (type == "ma") then
        windower.prim.set_visibility(alertBox_MA, true)
    end
    trigger_time = os.time()
end

function hide_caption()
    showing = false
    caption:hide()
    windower.prim.set_visibility(alertBox, false)
    windower.prim.set_visibility(alertBox_MA, false)
end
