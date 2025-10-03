local cfg = {}

-- EXAMPLE --

-- [item_name] = {threshold, batch_size} -- keep in mind that no threshold has a better performance!
-- ["Osmium Dust"] = {nil, 64} -- without threshold, batch_size=64
-- ["drop of Molten SpaceTime"] = {1000, 1, "molten_spacetime"} -- with threshold

cfg["items"] = {

}

cfg["sleep"] = 10

return cfg
