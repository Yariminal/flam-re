-- ============================================================================
-- lost_button_1_0_0.lua -- Orchestrator for Lost Button.
-- Session backpack lives on Global.LB (no state writes -> relaunch-safe).
-- Scenes: start -> bus stop -> puddle choice -> find -> backpack -> keep/leave -> title-card.
-- ============================================================================

local game = {}

local LB = {}
Global.LB = LB

function LB.reset()
    LB.path = nil
    LB.has_button = false
    LB.kept = nil
end

function LB.start_menu()
    Global.setBackToLibrary()
    Global.load_module("list-choice", "1_0_0").create({
        title = "Lost Button",
        choices = {
            {
                label = "Begin",
                img = "button.lif",
                audio = "silent.mp3",
                cb = function()
                    LB.reset()
                    Global.load_module("lb_bus", "1_0_0").create({})
                end,
            },
        },
    })
end

function LB.puddle_choice()
    Global.setBackBehavior(function()
        Global.load_module("lb_bus", "1_0_0").create({})
    end)
    Global.load_module("list-choice", "1_0_0").create({
        title = "A rainy bus stop. Which puddle?",
        choices = {
            {
                label = "Left puddle",
                img = "puddle_left.lif",
                audio = "silent.mp3",
                cb = function()
                    LB.path = "left"
                    Global.load_module("lb_find", "1_0_0").create({})
                end,
            },
            {
                label = "Right puddle",
                img = "puddle_right.lif",
                audio = "silent.mp3",
                cb = function()
                    LB.path = "right"
                    Global.load_module("lb_find", "1_0_0").create({})
                end,
            },
        },
    })
end

function LB.show_backpack()
    Global.setBackBehavior(function()
        LB.keep_or_leave()
    end)
    local choices = {}
    if LB.has_button then
        choices[1] = {
            label = "Shiny button",
            img = "button.lif",
            audio = "tone.mp3",
            cb = function()
                LB.keep_or_leave()
            end,
        }
    else
        choices[1] = {
            label = "Backpack is empty",
            img = "empty.lif",
            audio = "silent.mp3",
            cb = function()
                LB.keep_or_leave()
            end,
        }
    end
    Global.load_module("list-choice", "1_0_0").create({
        title = "Backpack",
        choices = choices,
    })
end

function LB.keep_or_leave()
    Global.setBackBehavior(function()
        LB.show_backpack()
    end)
    Global.load_module("list-choice", "1_0_0").create({
        title = "Keep the button, or leave it?",
        choices = {
            {
                label = "Keep it",
                img = "button.lif",
                audio = "silent.mp3",
                cb = function()
                    LB.kept = true
                    LB.ending()
                end,
            },
            {
                label = "Leave it",
                img = "puddle_left.lif",
                audio = "silent.mp3",
                cb = function()
                    LB.kept = false
                    LB.has_button = false
                    LB.ending()
                end,
            },
        },
    })
end

function LB.ending()
    local title, sub
    if LB.kept then
        title = "Safe and dry"
        sub = "The button rides home"
    else
        title = "Left behind"
        sub = "The puddle keeps it"
    end
    -- title-card advances by calling back_callback when audio ends
    Global.setBackBehavior(function()
        LB.start_menu()
    end)
    Global.load_module("title-card", "").display({
        title = title,
        subtitle = sub,
        audio = "silent.mp3",
        img = "button.lif",
    })
end

function game.clean()
    -- Orchestrator has no local UI; list-choice / scenes clean themselves.
end

function game.create(args)
    args = args or {}
    LB.reset()
    LB.start_menu()
end

return game
