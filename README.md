# Infinite Maintainer

Lets you passive lines easily, without lag and randomness of AE2 maintainer.
Also supports having a threshold.

# Setup

- Full block ME interface connected to an adapter
- Crafting Monitors on your CPUs
- (Internet card)
- OC stuff to make a basic computer
- Adapter with an Inventory Controller Upgrade installed  
- Vanilla chest connected to the Adapter  

# Installation

Download it

```bash
wget https://raw.githubusercontent.com/DiFaYaL/Level-Maintainer/master/installer.lua && installer
```

Run it

```bash
Maintainer
```

```bash
Pattern
```

# Config

You can change maintained items in `config.lua`. Pattern is as follows: `["item_name"] = {threshold, batch_size}` as well as the time inbetween craft checks.

**!! Keep in mind that threshold should only be added if necessary and preferrably not in mainnet, since it has a performance impact !!**

# Pattern

You can use `Pattern.lua` to automatically add items or fluids into `config.lua` directly from a chest connected to the Adapter with an Inventory Controller Upgrade installed.  

This is useful if you don’t want to edit `config.lua` manually.  

- Put desired items or fluid drops into the chest.  

- The script will add new entries to `config.lua` in the correct format without overwriting existing ones.  

Reboot after changing values.
