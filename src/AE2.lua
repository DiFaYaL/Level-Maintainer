local component = require("component")
local ME = component.me_interface

local AE2 = {}

-- Cache for craftables with timestamp
local craftablesCache = {}
local cacheTimestamp = 0
local CACHE_DURATION = 600 -- 10 minutes in seconds

-- Function to get cached craftables or refresh if needed
local function getCachedCraftables()
    local currentTime = os.time()
    
    -- Check if cache is still valid (within 10 minutes)
    if currentTime - cacheTimestamp < CACHE_DURATION and next(craftablesCache) ~= nil then
        return craftablesCache
    end
    
    -- Cache is expired or empty, refresh it
    local allCraftables = ME.getCraftables()
    craftablesCache = {}
    
    -- Index craftables by label for faster lookup
    for _, craftable in pairs(allCraftables) do
        local itemStack = craftable.getItemStack()
        if itemStack and itemStack.label then
            craftablesCache[itemStack.label] = craftable
        end
    end
    
    cacheTimestamp = currentTime
    return craftablesCache
end

function AE2.requestItem(name, threshold, count)
    local cachedCraftables = getCachedCraftables()
    local craftable = cachedCraftables[name]

    if craftable then
        local item = craftable.getItemStack()
        if threshold ~= nil then
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
    craftablesCache = {}
    cacheTimestamp = 0
end

return AE2