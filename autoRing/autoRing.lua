_addon.name = "autoRing"
_addon.author = "Godchain"
_addon.version = "1.0"
_addon.commands = {"autoRing", "ar"}

require("logger")
extdata = require("extdata")

lang = string.lower(windower.ffxi.get_info().language)
item_info = {
    ["facility"] = {id = 26165, japanese = "ファシリティリング", english = "Facility Ring", slot = 13},
    ["capacity"] = {id = 28546, japanese = "キャパシティリング", english = "Capacity Ring", slot = 13},
    ["warp"] = {id = 28540, japanese = "デジョンリング", english = "Warp Ring", slot = 13},
    ["caliber"] = {id = 26164, japanese = "カリバーリング", english = "Caliber Ring", slot = 13},
    ["empress"] = {id = 15762, japanese = "女帝の指輪", english = "Empress Band", slot = 13},
    ["dem"] = {id = 26177, japanese = "Ｄ．デムリング", english = "Dim. Ring (Dem)", slot = 13},
    ["echad"] = {id = 27556, japanese = "エチャドリング", english = "Echad Ring", slot = 13}
}

function search_item(ring)
    local item_array = {}
    local bags = {0, 8, 10, 11, 12} --inventory,wardrobe1-4
    local get_items = windower.ffxi.get_items
    for i = 1, #bags do
        for _, item in ipairs(get_items(bags[i])) do
            if item.id > 0 then
                item_array[item.id] = item
                item_array[item.id].bag = bags[i]
            end
        end
    end

    local stats = item_info[ring]
    local item = item_array[stats.id]
    local set_equip = windower.ffxi.set_equip
    if item then
        local ext = extdata.decode(item)
        local charges = ext.charges_remaining
        local enchant = ext.type == "Enchanted Equipment"
        local recast = enchant and charges > 0 and math.max(ext.next_use_time + 18000 - os.time(), 0)
        local usable = recast and recast == 0
        if (charges == 0) then
            log(stats[lang] .. ": out of charges.")
        elseif (recast > 0) then
            log(stats[lang] .. ": " .. recast .. " sec. on recast.")
        else
            log(stats[lang] .. ": equipped (" .. charges .. " left).")
        end
        if usable or ext.type == "General" then
            if enchant and item.status ~= 5 then --not equipped
                set_equip(item.slot, stats.slot, item.bag)
                log_flag = true
                repeat --waiting cast delay
                    coroutine.sleep(1)
                    local ext = extdata.decode(get_items(item.bag, item.slot))
                    local delay = ext.activation_time + 18000 - os.time()
                    if delay > 0 then
                        log(delay)
                    elseif log_flag then
                        log_flag = false
                        log("Using " .. stats[lang] .. ".")
                    end
                until ext.usable or delay > 10
            end
            windower.chat.input('/item "' .. windower.to_shift_jis(stats[lang]) .. '" <me>')
        end
    else
        log("You don't have " .. stats[lang] .. ".")
    end
end

function Set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end

windower.register_event(
    "addon command",
    function(cmd)
        local player = windower.ffxi.get_player()
        local get_spells = windower.ffxi.get_spells()
        if cmd == "cap" or cmd == "capacityring" then
            cmd = "capacity"
        end
        if cmd == "fac" or cmd == "facilityring" then
            cmd = "facility"
        end
        if cmd == "wa" then
            cmd = "warp"
        end

        if item_info[cmd] == nil then
            log("Invalid command. Try things like 'warp' (or 'wa'), 'capacity' (or 'cap'), 'dem', etc.")
        else
            log("Searching for: " .. cmd)
            search_item(cmd)
        end
    end
)
