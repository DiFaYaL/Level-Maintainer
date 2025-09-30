local component = require "component"
local sides = require "sides"
local filesystem = require "filesystem"

-- Настройки
local chestSide = sides.top                 -- Сторона сундука для сканирования
local configPath = "/home/config.lua"      -- Путь к config.lua

-- Настройки для предметов и жидкостей
local ITEM_BATCH_SIZE = 64                  -- batch_size для обычных предметов
local ITEM_THRESHOLD = nil                  -- threshold для обычных предметов

local FLUID_BATCH_SIZE = 1                  -- batch_size для жидкостей
local FLUID_THRESHOLD = 1000000            -- threshold для жидкостей

-- Загрузка существующего config.lua
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

-- Сериализация таблицы
local function serializeTable(tbl, indent)
    indent = indent or 0
    local result = {}
    local ind = string.rep("  ", indent)
    table.insert(result, "{")
    for k,v in pairs(tbl) do
        local key = type(k)=="string" and string.format("[\"%s\"]", k) or tostring(k)
        table.insert(result, string.format("%s%s = {%s},", ind.."  ", key,
            (v[1] and tostring(v[1]) or "nil") .. ", " .. tostring(v[2] or 1) .. (v[3] and ', "'..v[3]..'"' or "")
        ))
    end
    table.insert(result, ind.."}")
    return table.concat(result, "\n")
end

-- Сканирование сундука и формирование структуры для config.lua
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

                -- Если жидкость (drop of ...), формируем threshold и fluid_name
                if string.find(item_name:lower(), "drop") then
                    threshold = FLUID_THRESHOLD
                    batch_size = FLUID_BATCH_SIZE
                    fluid_name = item_name:lower():gsub("drop of ", ""):gsub(" ", "_")
                end

                items[item_name] = fluid_name and {threshold, batch_size, fluid_name} or {threshold, batch_size}
                addedCount = addedCount + 1
            end
        end
    end
    return items, addedCount
end

-- Сохраняем cfg["items"]
local function saveConfigItems(cfg)
    local file, err = io.open(configPath, "w")
    if not file then error("Ошибка записи config.lua: "..tostring(err)) end

    file:write("local cfg = {}\n\n")
    file:write("cfg[\"items\"] = "..serializeTable(cfg.items).."\n\n")
    file:write("cfg[\"sleep\"] = "..tostring(cfg.sleep).."\n\n")
    file:write("return cfg\n")
    file:close()
end

-- Главная функция
local function main()
    print("Сканирование сундука"..tostring(chestSide).." ...")
    local cfg = loadConfig()
    local newItems, addedCount = scanChest(cfg.items)

    -- Добавляем новые предметы к существующим
    for k,v in pairs(newItems) do
        cfg.items[k] = v
    end

    saveConfigItems(cfg)
    print("config.lua обновлен, добавлено предметов: "..tostring(addedCount))
end

main()
