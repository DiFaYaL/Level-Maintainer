local cfg = {}

-- EXAMPLE --

-- [item_name] = {threshold, batch_size} -- keep in mind that no threshold has a better performance!
-- ["Osmium Dust"] = {nil, 64} -- without threshold, batch_size=64
-- ["drop of Molten SpaceTime"] = {1000000, 1} -- with threshold


cfg["items"] = {
  ["Osmium Dust"] = {256, 64},
  ["drop of Molten Polybenzimidazole"] = {100, 1, "molten_polybenzimidazole"},
  ["drop of Americium Plasma"] = {100, 1, "americium_plasma"},
  ["Phosphorus Dust"] = {256, 64},
  ["drop of Phosphoric Acid"] = {100, 1, "phosphoric_acid"},
}

cfg["sleep"] = 10

return cfg
