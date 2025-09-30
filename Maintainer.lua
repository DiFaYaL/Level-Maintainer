local term = require("term")
local thread = require("thread")
local event = require("event")
local ae2 = require("src.AE2")
local cfg = require("config")
local util = require("src.Utility")

local items = cfg.items
local sleepInterval = cfg.sleep

local function monitorKeys()
    while true do
        local _, _, _, code = event.pull("key_down")
        if code == 16 then -- Q
            os.exit(0.5)
        end
    end
end

thread.create(monitorKeys)

while true do
    term.clear()
    term.setCursor(1, 1)
    print("Нажмите Q для выхода. Время отмены завязано на sleepInterval в config.lua")

    local itemsCrafting = ae2.checkIfCrafting()

    for item, config in pairs(items) do
        if itemsCrafting[item] == true then
            logInfo(item .. " is already being crafted, skipping...")
        else
            local success, answer = ae2.requestItem(item, config[1], config[2], config[3])
            logInfo(answer)
        end
    end

    os.sleep(sleepInterval)

    local _, _, _, code = term.pull(0, "key_down")
    if code == 16 then -- Q
        os.exit(0.5)
    end
end
