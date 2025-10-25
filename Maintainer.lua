local term = require("term")
local event = require("event")
local component = require("component")
local gpu = component.gpu

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

local function logInfoColoredAfterColon(msg, color)

if type(msg) ~= "string" then msg = tostring(msg) end
    local before, after = msg:match("^(.-):%s*(.+)$")
    if not before then
    print(msg)
    return
end

local old = gpu.getForeground()
    io.write("[" .. os.date("%H:%M:%S") .. "] " .. before .. ": ")
    if color then gpu.setForeground(color) end
    io.write(after .. "\n")
    gpu.setForeground(old)

end

local function logInfo(msg)
  print("[" .. os.date("%H:%M:%S") .. "] " .. msg)
end

while true do
  term.clear()
  term.setCursor(1, 1)
  print("Press Q to exit. Item inspection interval: " .. sleepInterval .. " сек.\n")

local itemsCrafting = ae2.checkIfCrafting()

  for item, cfgItem in pairs(items) do
    if itemsCrafting[item] then
      logInfo(item .. ": is already being crafted, skipping...")
    else
      
    local success, msg = ae2.requestItem(item, cfgItem[1], cfgItem[2], cfgItem[3])
      local color = nil
      if msg:find("^Failed to request") then
        color = 0xFF0000 -- красный
      elseif msg:find("^Requested") then
        color = 0xFFFF00 -- жёлтый
      elseif msg:find("The amount %(") and msg:find("Aborting request%.$") then
        color = 0x00FF00 -- зелёный
      end

      logInfoColoredAfterColon(item .. ": " .. msg, color)
    end
  end

    local _, _, _, code = event.pull(sleepInterval, "key_down")
    if code == 0x10 then -- Q
    exitMaintainer()
  end
end
