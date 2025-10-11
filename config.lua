local cfg = {}

-- EXAMPLE --

-- ["item_name"] = {{item_id, item_meta},threshold, batchsize} -- keep in mind that no threshold has a better performance!
-- ["fluid_name"] = {{fluid_tag item},threshold, batchsize}}  -- keep in mind that no threshold has a better performance!
-- ["Osmium Dust"] = {{ item_id = "gregtech:gt.metaitem.01", item_meta = "2083"}, 1000, 64}, -- without threshold, batch_size=64
-- ["drop of Molten SpaceTime"] = {{ fluid_tag = "molten.spacetime"}, 1000, 64} -- with threshold, batch_size=64

cfg["items"] = {

}

cfg["sleep"] = 10

return cfg
