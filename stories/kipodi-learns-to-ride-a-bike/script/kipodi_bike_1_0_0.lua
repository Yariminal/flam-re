-- ============================================================================
-- kipodi_bike_1_0_0.lua -- "Kipodi learns to ride a bike" story orchestrator.
-- Story data (one `-- beat: <id>` block per beat) lives in kipodi_data.lua.
-- Session only: backpack, traits and the game's loss count live in Global.KB
-- (never in `state`).
-- Features: hub (title) screen, session Backpack (Lost Button list-choice),
-- locked choice (choice.requires -> locked_to), Box Breaker mini-game
-- (kipodi_breakout), Chapter map (Global.progression + chapterView, canary).
-- ============================================================================

local game = {}

local KB = {}
Global.KB = KB

local function names(list, dict)
    local out = {}
    for i = 1, #list do
        out[i] = dict[list[i]] or list[i]
    end
    return table.concat(out, ", ")
end

local function show(args)
    Global.load_module("kipodi_scene", "1_0_0").create(args)
end

local function has_all(list)
    for i = 1, #list do
        if not KB.have[list[i]] then return false end
    end
    return true
end

function KB.reset()
    KB.backpack = {}   -- item ids, in the order they were added
    KB.have = {}       -- set of item ids
    KB.traits = {}     -- trait ids, in the order they were earned
    KB.path = {}       -- beat ids visited this run
    KB.losses = 0      -- Box Breaker losses since the last win / assist
    KB.current = nil   -- beat on screen (nil = no story in progress)
end

function KB.give(it)
    if KB.have[it] then return false end
    KB.have[it] = true
    KB.backpack[#KB.backpack + 1] = it
    return true
end

function KB.add_trait(t)
    for i = 1, #KB.traits do
        if KB.traits[i] == t then return end
    end
    KB.traits[#KB.traits + 1] = t
end

-- Chapter beats are saved for the chapter map (canary recipe B). The cb is a
-- string: chapterView calls _G[cb]() (single-branch). No inventory snapshot.
local function mark_chapter(n)
    local c = KB.data.chapters[n]
    Global.progression.setProgression({
        currentFunction = c.beat,
        ischapter = true,
        chapterData = {
            label = c.label,
            cb = c.fn,
            img = c.img,
            audio = c.audio,
            order = n,
        },
    })
end

-- Chapter map jump (ChapterOne..ChapterFive in main.lua): fresh session with
-- the backpack the child always holds on arrival (story `carry`).
function KB.jump_chapter(n)
    local c = KB.data.chapters[n]
    if c == nil then
        KB.hub()
        return
    end
    KB.reset()
    for i = 1, #c.carry do KB.give(c.carry[i]) end
    KB.go(c.beat)
end

local function play_game(id, beat)
    Global.load_module("kipodi_breakout", "1_0_0").create({
        image = beat.image,
        audio = beat.audio,
        win_audio = KB.data.game_win,
        lose_audio = KB.data.game_lose,
        onBack = function() KB.hub() end,
        onWin = function()
            KB.losses = 0
            KB.go(beat.win_goto)
        end,
        onLose = function()
            KB.losses = KB.losses + 1
            if KB.losses >= beat.max_tries then
                KB.losses = 0
                KB.go(beat.assist_goto)
            else
                KB.go(beat.retry_goto)
            end
        end,
    })
end

-- resume = true: "Continue" from the hub (same beat, not added to the path).
function KB.go(id, resume)
    local D = KB.data
    local beat = D.beats[id]
    if beat == nil then
        KB.hub()
        return
    end
    KB.current = id
    if not resume then
        KB.path[#KB.path + 1] = id
    end

    -- Backpack grants happen when the beat is entered
    local added = {}
    for i = 1, #beat.grants do
        if KB.give(beat.grants[i]) then
            added[#added + 1] = beat.grants[i]
        end
    end

    -- setProgression resets Back to the progression behaviour (hub); the
    -- screen below sets its own Back after this.
    if beat.chapter ~= nil then
        mark_chapter(beat.chapter)
    end

    if beat.kind == "minigame" then
        play_game(id, beat)
        return
    end

    local info = nil
    local choices = {}
    if beat.kind == "ending" then
        local lines = {}
        if #KB.traits > 0 then
            lines[#lines + 1] = "Kipodi was: " .. names(KB.traits, D.traits)
        end
        lines[#lines + 1] = "Backpack: " .. names(KB.backpack, D.items)
        info = table.concat(lines, "\n")
        choices[1] = { label = "Play again", onSelect = function()
            KB.reset()
            KB.go(D.start)
        end }
        choices[2] = { label = "Back to title", onSelect = function()
            KB.current = nil
            KB.hub()
        end }
    else
        if #added > 0 then
            info = "Added to backpack: " .. names(added, D.items)
        elseif #beat.requires > 0 then
            info = "Kipodi uses: " .. names(beat.requires, D.items)
        end
        for i = 1, #beat.choices do
            local c = beat.choices[i]
            choices[i] = { label = c.label, onSelect = function()
                if c.trait ~= nil then KB.add_trait(c.trait) end
                -- Locked choice: without the required items go to locked_to.
                if c.requires ~= nil and not has_all(c.requires) then
                    KB.go(c.locked_to)
                else
                    KB.go(c.to)
                end
            end }
        end
    end

    show({
        id = id,
        image = beat.image,
        text = beat.text,
        info = info,
        audio = beat.audio,
        choices = choices,
        onBack = function() KB.hub() end,
    })
end

-- Backpack (Lost Button pattern): list-choice titled "Backpack". Back or a
-- click on any row returns to `ret`.
function KB.show_backpack(ret)
    local D = KB.data
    local rows = {}
    for i = 1, #KB.backpack do
        local it = KB.backpack[i]
        rows[#rows + 1] = { label = D.items[it], img = D.item_img[it], audio = D.tone,
                            cb = function() ret() end }
    end
    if #rows == 0 then
        rows[1] = { label = "Backpack is empty", img = "empty.lif", audio = "silent.mp3",
                    cb = function() ret() end }
    end
    Global.setBackBehavior(function() ret() end)
    Global.load_module("list-choice", "1_0_0").create({
        title = "Backpack",
        title_audio = D.tone,
        choices = rows,
    })
    -- Test/debug handle (read-only; no behaviour change)
    KB.ui = { id = "backpack", n = #rows, ready = true, list = true,
              labels = names(KB.backpack, D.items) }
end

function KB.open_chapters()
    Global.progression.displayChapters(true)
    KB.ui = { id = "chapters", n = 0, ready = true, list = true }
end

-- Hub = story title screen. Back here leaves to the library.
function KB.hub()
    local D = KB.data
    local rows = {}
    if KB.current ~= nil then
        rows[#rows + 1] = { label = "Continue", onSelect = function()
            KB.go(KB.current, true)
        end }
    end
    rows[#rows + 1] = { label = (KB.current ~= nil) and "Start again" or "Begin", onSelect = function()
        KB.reset()
        KB.go(D.start)
    end }
    rows[#rows + 1] = { label = "Backpack", onSelect = function()
        KB.show_backpack(KB.hub)
    end }
    if Global.progression.isStoryStarted() then
        rows[#rows + 1] = { label = "Chapters", onSelect = function()
            KB.open_chapters()
        end }
    end
    rows[#rows + 1] = { label = "Back to library", onSelect = function()
        Global.requestAudioStop(true, true)
        goto_library()
    end }
    show({
        id = "title",
        home = true,
        image = "morning.lif",
        text = D.title,
        audio = D.title_audio,
        choices = rows,
    })
end

function game.clean()
end

function game.create(args)
    KB.data = require("kipodi_data")
    KB.reset()
    KB.hub()
end

return game
