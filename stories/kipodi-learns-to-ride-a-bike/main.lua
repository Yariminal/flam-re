-- ============================================================================
-- main.lua -- "Kipodi learns to ride a bike" bootstrap (Flam homebrew story).
-- Device rules: no top-level require; Global is global.
-- Chapter map = Chapter Map Canary pattern: Global.progression.create in setup,
-- single-branch (isMultiBranches = false) so chapterView jumps call _G[cb]().
-- Deviation from the canary: no state pre-seeding (chapterData carries no
-- inventory, so the jump never merges into state.inventory; the backpack is
-- restored from the chapter's `carry` list in the session table instead).
-- ============================================================================

function ChapterOne()   Global.KB.jump_chapter(1) end
function ChapterTwo()   Global.KB.jump_chapter(2) end
function ChapterThree() Global.KB.jump_chapter(3) end
function ChapterFour()  Global.KB.jump_chapter(4) end
function ChapterFive()  Global.KB.jump_chapter(5) end

function setup()
    Global = require("global")
    Global.init()
    Global.isMultiBranches = false
    Global.setBackToLibrary()

    Global.progression.create({
        totalChapters = 5,
        backBehavior = function()
            if Global.KB ~= nil then
                Global.KB.hub()
            end
        end,
        chapterViewLabel = "Chapters",
    })

    Global.load_module("kipodi_bike", "1_0_0").create({})
end
