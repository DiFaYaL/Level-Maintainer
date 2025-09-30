local component = require("component")
local ME = component.me_interface

local AE2 = {}

local itemCache = {}
local cacheTimestamp = 0
local CACHE_DURATION = 600 -- 10 минут

local function getCraftableForItem(itemName)
    local currentTime = os.time()

    if itemCache[itemName] and currentTime - cacheTimestamp < CACHE_DURATION then
        return itemCache[itemName]
    end

    if currentTime - cacheTimestamp >= CACHE_DURATION then
        itemCache = {}
        cacheTimestamp = currentTime
    end

    local craftables = ME.getCraftables({["label"] = itemName})
    if #craftables >= 1 then
        itemCache[itemName] = craftables[1]
        return craftables[1]
    end

    itemCache[itemName] = nil
    return nil
end

function AE2.requestItem(name, threshold, count, fluidName)
    local craftable = getCraftableForItem(name)

    if craftable then
        local item = craftable.getItemStack()
        local itemInSystem = nil

        -- Threshold проверка (для жидкостей и обычных предметов)
        if threshold ~= nil then
            local itemsInSystem = ME.getItemsInNetwork({["label"] = name})
            if #itemsInSystem > 0 then
                itemInSystem = itemsInSystem[1]
            end

            if itemInSystem and itemInSystem.size >= threshold then
                return false, "The amount of " .. (itemInSystem.label or name) .. 
                    " (" .. itemInSystem.size .. ") meets or exceeds threshold (" .. threshold .. ")! Aborting request."
            end
        end

        -- Запрос крафта
        if item.label == name then
            local craft = craftable.request(count)
            while craft.isComputing() do os.sleep(1) end

            if craft.hasFailed() then
                return false, "Failed to request " .. name .. " x " .. count
            else
                return true, "Requested " .. name .. " x " .. count
            end
        end
    end

    return false, name .. " is not craftable!"
end

function AE2.checkIfCrafting()
    local cpus = ME.getCpus()
    local items = {}
    for k, v in pairs(cpus) do
        local finaloutput = v.cpu.finalOutput()
        if finaloutput ~= nil then
            items[finaloutput.label] = true
        end
    end
    return items
end

function AE2.clearCache()
    itemCache = {}
    cacheTimestamp = 0
end

return AE2
