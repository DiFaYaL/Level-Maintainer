local component = require("component")
local ME = component.me_interface

local AE2 = {}

-- Lightweight cache for specific items only
local itemCache = {}
local cacheTimestamp = 0
local CACHE_DURATION = 600 -- 10 minutes in seconds

-- Function to get or cache a specific craftable item
local function getCraftableForItem(itemName)
    local currentTime = os.time()
    
    -- Check if we have a cached version of this specific item and it's still valid
    if itemCache[itemName] and currentTime - cacheTimestamp < CACHE_DURATION then
        return itemCache[itemName]
    end
    
    -- If cache is too old, clear it completely to save memory
    if currentTime - cacheTimestamp >= CACHE_DURATION then
        itemCache = {}
        cacheTimestamp = currentTime
    end
    
    -- Look for this specific item in craftables
    local craftables = ME.getCraftables({["label"] = itemName})
    if #craftables >= 1 then
        itemCache[itemName] = craftables[1] -- Cache only this one item
        return craftables[1]
    end
    
    itemCache[itemName] = nil -- Cache that it's not craftable
    return nil
end

function AE2.requestItem(name, threshold, count)
    local craftable = getCraftableForItem(name)

    if craftable then
        local item = craftable.getItemStack()
        if threshold ~= nil then
            -- Use the newer getItemInNetwork function
            local itemInSystem = ME.getItemInNetwork(name)
            if itemInSystem ~= nil and itemInSystem.size > threshold then 
                return table.unpack({false, "The amount of " .. itemInSystem.label .. " exceeds threshold! Aborting request."})
            end
        end
        
        if item.label == name then
            local craft = craftable.request(count)

            while craft.isComputing() == true do
                os.sleep(1)
            end
            if craft.hasFailed() then
                return table.unpack({false, "Failed to request " .. name .. " x " .. count})
            else
                return table.unpack({true, "Requested " .. name .. " x " .. count})
            end
        end
    end
    return table.unpack({false, name .. " is not craftable!"})
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

-- Function to manually clear the cache if needed
function AE2.clearCache()
    itemCache = {}
    cacheTimestamp = 0
end

return AE2