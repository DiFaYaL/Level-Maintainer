local term = require("term")
local event = require("event")
local ae2 = require("src.AE2")
local cfg = require("config")

local items = cfg.items
local sleepInterval = cfg.sleep

local function exitMaintainer()
    term.clear()
    term.setCursor(1, 1)
    print("Exit from Maintainer...")
    os.exit(0.5)
end

local function logInfo(msg)
    if type(msg) == "string" then
        print("[" .. os.date("%H:%M:%S") .. "] " .. msg)
    end
end

while true do
    term.clear()
    term.setCursor(1, 1)
    print("Press Q to exit. Item inspection interval: "..sleepInterval.." сек.\n")

    local itemsCrafting = ae2.checkIfCrafting()

    for item, cfgItem in pairs(items) do
        if itemsCrafting[item] then
            logInfo(item .. " is already being crafted, skipping...")
        else
            local success, msg = ae2.requestItem(item, cfgItem[1], cfgItem[2], cfgItem[3])
            logInfo(item .. ": " .. msg)
        end
    end

    local _, _, _, code = event.pull(sleepInterval, "key_down")
    if code == 0x10 then -- Q
        exitMaintainer()
    end
end
