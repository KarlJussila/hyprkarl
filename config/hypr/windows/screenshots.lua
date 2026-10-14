-- Remove the 1px border / animation around hyprshot's selection overlay
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
