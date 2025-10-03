local component = require("component")
local ME = component.me_interface

local AE2 = {}

local itemCache = {}
local cacheTimestamp = 0
local CACHE_DURATION = 600 -- 10 минут

local function getCraftableForItem(itemName)
    local currentTime = os.time()

    if currentTime - cacheTimestamp >= CACHE_DURATION then
        itemCache = {}
        cacheTimestamp = currentTime
    else
        if itemCache[itemName] then
            return itemCache[itemName]
        end
    end

    local craftables = ME.getCraftables({label = itemName})
    local craftable = craftables[1] -- nil если нет
    itemCache[itemName] = craftable
    return craftable
end

function AE2.requestItem(name, threshold, count)
    local craftable = getCraftableForItem(name)
    if not craftable then
        return false, name .. " is not craftable!"
    end

    local item = craftable.getItemStack()
    local itemInSystem = nil

    if threshold then
        local itemsInSystem = ME.getItemsInNetwork({label = name})
        itemInSystem = itemsInSystem[1]

        if itemInSystem and itemInSystem.size >= threshold then
            return false, "The amount of " .. (itemInSystem.label or name) .. 
                " (" .. itemInSystem.size .. ") meets or exceeds threshold (" .. threshold .. ")! Aborting request."
        end
    end

    if item.label == name then
        local craft = craftable.request(count)
        while craft.isComputing() do os.sleep(1) end

        if craft.hasFailed() then
            return false, "Failed to request " .. name .. " x " .. count
        else
            return true, "Requested " .. name .. " x " .. count
        end
    end

    return false, name .. " is not craftable!"
end

function AE2.checkIfCrafting()
    local items = {}
    for _, cpu in pairs(ME.getCpus()) do
        local final = cpu.cpu.finalOutput()
        if final then
            items[final.label] = true
        end
    end
    return items
end

function AE2.clearCache()
    itemCache = {}
    cacheTimestamp = 0
end

return AE2
