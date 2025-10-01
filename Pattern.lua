local component = require "component"
local sides = require "sides"
local filesystem = require "filesystem"

-- Настройки
local chestSide = sides.top
local configPath = "/home/config.lua"

-- Значения по умолчанию
local ITEM_BATCH_SIZE = 64
local ITEM_THRESHOLD = 128

local FLUID_BATCH_SIZE = 1
local FLUID_THRESHOLD = 1000

local function loadConfig()
    local cfg = {}
    if filesystem.exists(configPath) then
        local ok, chunk = pcall(loadfile, configPath)
        if ok and chunk then
            local status, result = pcall(chunk)
            if status and type(result) == "table" then
                cfg = result
            end
        end
    end
    if not cfg.items then cfg.items = {} end
    if not cfg.sleep then cfg.sleep = 10 end
    return cfg
end

-- Функция для запроса значения у пользователя
local function askValue(prompt, default)
    io.write(prompt .. " [" .. tostring(default) .. "]: ")
    local input = io.read()
    if input == nil or input == "" then
        return default
    else
        return tonumber(input) or default
    end
end

local function scanChest(existingItems)
    if not component.isAvailable("inventory_controller") then
        error("Inventory Controller не найден!")
    end
    local inv = component.inventory_controller
    local size = inv.getInventorySize(chestSide)
    if not size or size < 1 then error("Не удалось прочитать сундук или он пуст") end

    local items = {}
    local addedCount = 0

    for slot=1,size do
        local stack = inv.getStackInSlot(chestSide, slot)
        if stack and stack.size>0 then
            local item_name = stack.label or stack.name
            if not existingItems[item_name] then
                local threshold = ITEM_THRESHOLD
                local batch_size = ITEM_BATCH_SIZE
                local fluid_name = nil

                if string.find(item_name:lower(), "drop") then
                    threshold = FLUID_THRESHOLD
                    batch_size = FLUID_BATCH_SIZE
                    fluid_name = item_name:lower():gsub("drop of ", ""):gsub(" ", "_")
                end

                -- Запрос у пользователя значений
                print("\nНовый предмет найден: " .. item_name)
                threshold = askValue(item_name .. " threshold", threshold)
                batch_size = askValue(item_name .. " batch_size", batch_size)

                items[item_name] = fluid_name and {threshold, batch_size, fluid_name} or {threshold, batch_size}
                addedCount = addedCount + 1
            end
        end
    end
    return items, addedCount
end

local function serializeItems(tbl)
    local result = {}
    local ind = "  "
    table.insert(result, "{")
    for k,v in pairs(tbl) do
        local key = string.format("[\"%s\"]", k)
        table.insert(result, string.format("%s%s = {%s},", ind, key,
            (v[1] and tostring(v[1]) or "nil") .. ", " .. tostring(v[2] or 1) .. (v[3] and ', "'..v[3]..'"' or "")
        ))
    end
    table.insert(result, "}")
    return table.concat(result, "\n")
end

local function updateConfigItems(newItems)
    local content = ""
    local f = io.open(configPath, "r")
    if f then
        content = f:read("*a")
        f:close()
    end

    local startPos, bracePos = content:find('cfg%["items"%]%s*=%s*{')
    if not startPos then
        error("Не найден массив cfg[\"items\"] в config.lua")
    end

    local openBraces = 1
    local i = bracePos + 1
    local endPos = nil
    while i <= #content do
        local c = content:sub(i,i)
        if c == "{" then openBraces = openBraces + 1
        elseif c == "}" then
            openBraces = openBraces - 1
            if openBraces == 0 then
                endPos = i
                break
            end
        end
        i = i + 1
    end
    if not endPos then error("Не удалось определить конец массива cfg[\"items\"]") end

    local serialized = serializeItems(newItems)
    local updatedContent = content:sub(1, startPos-1) .. "cfg[\"items\"] = " .. serialized .. content:sub(endPos+1)

    local f = io.open(configPath, "w")
    f:write(updatedContent)
    f:close()
end

local function main()
    print("Сканирование сундука...")
    local cfg = loadConfig()
    local newItems, addedCount = scanChest(cfg.items)

    for k,v in pairs(newItems) do
        cfg.items[k] = v
    end

    updateConfigItems(cfg.items)
    print("\nconfig.lua обновлен, добавлено предметов: "..tostring(addedCount))
end

main()
