local component = require("component")
local ME = component.me_interface

local AE2 = {}

local itemCache = {}
local cacheTimestamp = 0
local CACHE_DURATION = 600 -- 10 минут

local function formatNumber(num)
    if type(num) ~= "number" then return tostring(num) end
    local str = tostring(num)
    local parts = {}
    local len = #str
    local firstGroup = len % 3
    if firstGroup == 0 then firstGroup = 3 end
    table.insert(parts, str:sub(1, firstGroup))
    local i = firstGroup + 1
    while i <= len do
        table.insert(parts, str:sub(i, i + 2))
        i = i + 3
    end
    return table.concat(parts, "_")
end

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
    local craftable = craftables[1]
    itemCache[itemName] = craftable
    return craftable
end

function AE2.requestItem(name, threshold, count)
    local craftable = getCraftableForItem(name)
    if not craftable then
        return false, "is not craftable!"
    end

    local item = craftable.getItemStack()
    local itemInSystem = nil

    if threshold then
        local itemsInSystem = ME.getItemsInNetwork({label = name})
        itemInSystem = itemsInSystem[1]

        if itemInSystem and itemInSystem.size >= threshold then
            local currentAmount = formatNumber(itemInSystem.size)
            local thresholdFmt = formatNumber(threshold)
            return false, "The amount (" .. currentAmount .. ") threshold (" .. thresholdFmt .. ")! Aborting request."
        end
    end

    if item.label == name then
        local craft = craftable.request(count)
        while craft.isComputing() do os.sleep(1) end

        if craft.hasFailed() then
            return false, "Failed to request " .. formatNumber(count)
        else
            return true, "Requested " .. formatNumber(count)
        end
    end

    return false, "is not craftable!"
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

-- Очистка кэша
function AE2.clearCache()
    itemCache = {}
    cacheTimestamp = 0
end

return AE2
