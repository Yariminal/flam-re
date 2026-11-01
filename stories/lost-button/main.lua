-- ============================================================================
-- main.lua -- Lost Button bootstrap (Flam homebrew).
-- Device rules: no top-level require; Global is global; game = module.
-- ============================================================================

function setup()
    Global = require("global")
    Global.init()
    Global.isMultiBranches = true
    Global.setBackToLibrary()
    Global.load_module("lost_button", "1_0_0").create({})
end
