local cfg = {}

-- EXAMPLE --

-- [item_name] = {threshold, batch_size, fluid_name} -- fluid_name is REQUIRED for fluid drops
-- ["Osmium Dust"] = {nil, 64} -- regular item without threshold
-- ["drop of Molten SpaceTime"] = {1000000, 1, "spacetime"} -- fluid drop with threshold and fluid name

cfg["items"] = {
    ["drop of Molten SpaceTime"] = {nil, 1, "spacetime"},
    ["drop of Molten White Dwarf Matter"] = {nil, 1, "white_dwarf_matter"}
}

cfg["sleep"] = 10

return cfg