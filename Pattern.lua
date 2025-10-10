local component = require "component"
local sides = require "sides"
local filesystem = require "filesystem"

-- Настройки
local chestSide = sides.top
local configPath = "/home/config.lua"
local shrcPath = "/home/.shrc"

-- Значения по умолчанию
local ITEM_BATCH_SIZE = 64
local ITEM_THRESHOLD = 128
local FLUID_BATCH_SIZE = 1
local FLUID_THRESHOLD = 1000

local function parseExpression(str)
    if type(str) ~= "string" then return nil, "not a string" end

    -- Поддержка 1k, 1m, 1g, 1t, 1p
    str = str:gsub("([0-9%.]+)%s*[kK]", "%1*1000")
    str = str:gsub("([0-9%.]+)%s*[mM]", "%1*1000000")
    str = str:gsub("([0-9%.]+)%s*[gG]", "%1*1000000000")
    str = str:gsub("([0-9%.]+)%s*[tT]", "%1*1000000000000")
    str = str:gsub("([0-9%.]+)%s*[pP]", "%1*1000000000000000")

    str = str:gsub("%s+", "")

    if str:match("[^0-9%+%-%*/%.%(%)]+") then
        return nil, "invalid characters"
    end

    local f, err = load("return " .. str)
    if not f then return nil, err end

    local ok, result = pcall(f)
    if not ok or type(result) ~= "number" then
        return nil, "invalid expression"
    end

    return math.floor(result)
end

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

-- Функция ввода с поддержкой сокращений
local function askValue(prompt, default)
    io.write(prompt .. " [" .. tostring(default) .. "]: ")
    local input = io.read()
    if input == nil or input == "" then
        return default
    end

    local value, err = parseExpression(input)
    if not value then
        print("Ошибка: " .. tostring(err) .. ". Используется значение по умолчанию.")
        return default
    end
    return value
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
        if stack and stack.size > 0 then
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

local function ensureAutorun()
    local f = io.open(shrcPath, "r")
    local content = f:read("*a")
    f:close()

    if content:match("Maintainer") then
        return
    end

    io.write("Добавить Maintainer.lua в автозапуск? (y/n): ")
    local answer = io.read()
    if answer and answer:lower() == "y" then
        local fw = io.open(shrcPath, "a")
        fw:write("\nMaintainer\n")
        fw:close()
        print("Maintainer.lua добавлен в автозапуск")
    end
end

-- Главная функция
local function main()
    print("Сканирование сундука...")
    local cfg = loadConfig()
    local newItems, addedCount = scanChest(cfg.items)

    for k,v in pairs(newItems) do
        cfg.items[k] = v
    end

    updateConfigItems(cfg.items)
    print("\nconfig.lua обновлен, добавлено предметов: "..tostring(addedCount))

    ensureAutorun()
    os.execute("reboot")
end

main()
