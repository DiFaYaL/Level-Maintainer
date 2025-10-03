local tostring = tostring
local pairs = pairs
local tonumber = tonumber
local math_floor = math.floor
local os_date = os.date
local string_gsub = string.gsub

function dump(o, depth)
    depth = depth or 0
    if depth > 10 then return "..." end

    if type(o) == 'table' then
        local t = {"{ "}
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            t[#t + 1] = '[' .. k .. '] = ' .. dump(v, depth + 1) .. ',\n'
        end
        t[#t + 1] = '} '
        return table.concat(t)
    else
        return tostring(o)
    end
end

function parser(str)
    if type(str) ~= "string" then return 0 end
    local numStr = string_gsub(str, "([^0-9]+)", "")
    return tonumber(numStr) and math_floor(tonumber(numStr)) or 0
end

function logInfo(msg)
    if type(msg) == "string" then
        print("[" .. os_date("%H:%M:%S") .. "] " .. msg)
    end
end
