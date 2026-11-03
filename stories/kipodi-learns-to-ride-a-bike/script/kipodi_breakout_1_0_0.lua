-- ============================================================================
-- kipodi_breakout_1_0_0.lua -- "Box Breaker" mini-game for "Kipodi learns to
-- ride a bike". Story-local copy of flam-player games/casse-briques
-- breakout_1_0_0.lua (module create/clean, loaded via Global.load_module).
-- Changes from the original: no parental lock, English text only (Latin-1),
-- 2 rows of cardboard boxes, slower ball, 72 px paddle, story backdrop,
-- Back -> args.onBack, auto-launch after 1.5 s, and the game ends the beat:
-- win  -> plays args.win_audio,  then args.onWin()
-- lose -> plays args.lose_audio, then args.onLose()   (3 lives per try)
-- Only the end sounds play (no hit sounds): one audio track, no load while
-- another clip plays.
-- Input: wheel 19/20 moves the paddle one step; key 10 (or a click) launches.
-- ============================================================================

local breakout = {}

local W = Global.visual_width    -- 320
local H = Global.visual_height   -- 212

-- Geometry
local PADDLE_W, PADDLE_H = 72, 8
local PADDLE_Y           = H - 14
local BALL               = 8
local STEP               = 18              -- paddle move per wheel step
local COLS, ROWS         = 8, 2
local GAP, BRICK_TOP     = 2, 24
local BRICK_W            = math.floor((W - (COLS + 1) * GAP) / COLS)  -- 37
local BRICK_H            = 12
local BRICK_X0           = math.floor((W - (COLS * BRICK_W + (COLS - 1) * GAP)) / 2)
local SPEED              = 2               -- px per 25 ms tick (original: 3)
local LIVES              = 3
local LAUNCH_TICKS       = 60              -- auto-launch after 1.5 s
local END_MIN            = 40              -- end sound: >= 1 s on the end message
local END_MAX            = 240             -- 6 s fallback if the end sound never plays

local ROW_COLORS  = { 0xB5835A, 0xC99A6B }  -- cardboard boxes
local COL_PADDLE  = 0x5A3A26
local COL_BALL    = 0xC0573E
local COL_TEXT    = 0xF3E8D2

-- Objects / state (fresh on every require: load_module clears package.loaded)
breakout.styles = {}
breakout.events = {}
breakout.images = {}
local container, paddle, ball, livesLbl, msgLbl, loopTimer
local bricks = {}
local opts
local paddleX
local bx, by, vx, vy
local lives, bricksLeft
local phase          -- "wait" (ball on paddle) | "run" | "end"
local waitTicks, endTicks, won, finished

-- ---------------------------------------------------------------------------
function breakout.clean()
    if loopTimer ~= nil then lv.timer.del(loopTimer); loopTimer = nil end
    for obj, ev in pairs(breakout.events) do
        for _, cb in pairs(ev) do
            lv.obj.remove_event_cb(obj, cb)
        end
    end
    -- No stop-all here: the next screen's priority play cuts in.
    Global.requestAudioStop()
    lv.group.set_editing(document, false)
    lv.group.remove_all_objs(document)
    lv.obj.clean(window)
    container, paddle, ball, livesLbl, msgLbl = nil, nil, nil, nil, nil
    bricks = {}
    breakout.styles = {}
    breakout.events = {}
    breakout.images = {}
end

-- ---------------------------------------------------------------------------
local function initStyles()
    local S = breakout.styles
    S.bg = lv.style.new()
    lv.style.set_bg_color(S.bg, lv.color.black())
    lv.style.set_bg_opa(S.bg, lv.OPA_COVER)
    lv.style.set_pad_all(S.bg, 0)

    S.paddle = lv.style.new()
    lv.style.set_bg_color(S.paddle, lv.color.hex(COL_PADDLE))
    lv.style.set_bg_opa(S.paddle, lv.OPA_COVER)
    lv.style.set_radius(S.paddle, 3)

    S.ball = lv.style.new()
    lv.style.set_bg_color(S.ball, lv.color.hex(COL_BALL))
    lv.style.set_bg_opa(S.ball, lv.OPA_COVER)
    lv.style.set_radius(S.ball, BALL)

    S.text = lv.style.new()
    lv.style.set_text_color(S.text, lv.color.hex(COL_TEXT))
    lv.style.set_text_font(S.text, lv.font.nunito_extrabold_12)

    S.msg = lv.style.new()
    lv.style.set_bg_color(S.msg, lv.color.black())
    lv.style.set_bg_opa(S.msg, 200)
    lv.style.set_text_color(S.msg, lv.color.hex(0xffffff))
    lv.style.set_text_font(S.msg, lv.font.nunito_extrabold_16)
    lv.style.set_pad_all(S.msg, 6)
    lv.style.set_radius(S.msg, 6)

    for r = 1, ROWS do
        S["brick" .. r] = lv.style.new()
        lv.style.set_bg_color(S["brick" .. r], lv.color.hex(ROW_COLORS[r]))
        lv.style.set_bg_opa(S["brick" .. r], lv.OPA_COVER)
        lv.style.set_radius(S["brick" .. r], 2)
    end
end

local function overlap(ax, ay, aw, ah, bx2, by2, bw, bh)
    return ax < bx2 + bw and ax + aw > bx2 and ay < by2 + bh and ay + ah > by2
end

-- Ball sits on the paddle until launch (key 10, click, or 1.5 s).
local function holdBall()
    bx = math.floor(paddleX + PADDLE_W / 2 - BALL / 2)
    by = PADDLE_Y - BALL - 2
    vx = (math.floor(paddleX) % 2 == 0) and 1 or -1
    vy = -SPEED
    phase, waitTicks = "wait", 0
    lv.obj.set_pos(ball, bx, by)
end

local function buildBricks()
    bricksLeft = 0
    for r = 1, ROWS do
        for c = 1, COLS do
            local x = BRICK_X0 + (c - 1) * (BRICK_W + GAP)
            local y = BRICK_TOP + (r - 1) * (BRICK_H + GAP)
            local b = lv.obj.new(container)
            lv.obj.remove_style_all(b)
            lv.obj.set_size(b, BRICK_W, BRICK_H)
            lv.obj.add_style(b, breakout.styles["brick" .. r], lv.STATE_DEFAULT)
            lv.obj.set_pos(b, x, y)
            bricks[#bricks + 1] = { obj = b, x = x, y = y, alive = true }
            bricksLeft = bricksLeft + 1
        end
    end
end

local function setMessage(txt)
    if txt == nil then
        lv.obj.add_flag(msgLbl, lv.OBJ_FLAG_HIDDEN)
    else
        lv.label.set_text(msgLbl, txt)
        lv.obj.clear_flag(msgLbl, lv.OBJ_FLAG_HIDDEN)
        lv.obj.align(msgLbl, lv.ALIGN_CENTER, 0, 0)
    end
end

local function refreshLives()
    lv.label.set_text(livesLbl, "Lives " .. lives)
end

local function finish(win)
    phase, endTicks, won = "end", 0, win
    setMessage(win and "You did it!" or "Oh no!")
    Global.requestAudioPlay({ path = win and opts.win_audio or opts.lose_audio,
                              priority = true, showPause = false })
end

-- ---------------------------------------------------------------------------
local function tick()
    if phase == "end" then
        endTicks = endTicks + 1
        -- Leave once the end sound has played (same test as kipodi_scene's
        -- narration lock), or after the fallback time.
        if not finished and endTicks >= END_MIN and
           ((audio.get_status() ~= "play" and Global.audioDelayPath == nil) or endTicks >= END_MAX) then
            finished = true
            if won then opts.onWin() else opts.onLose() end
        end
        return
    end
    if phase == "wait" then
        waitTicks = waitTicks + 1
        if waitTicks >= LAUNCH_TICKS then phase = "run" end
        return
    end

    bx = bx + vx
    by = by + vy

    if bx <= 0 then bx = 0; vx = -vx end
    if bx >= W - BALL then bx = W - BALL; vx = -vx end
    if by <= 0 then by = 0; vy = -vy end

    if by >= H - BALL then
        lives = lives - 1
        refreshLives()
        if lives <= 0 then
            lv.obj.add_flag(ball, lv.OBJ_FLAG_HIDDEN)
            finish(false)
            return
        end
        holdBall()
        return
    end

    if vy > 0 and overlap(bx, by, BALL, BALL, paddleX, PADDLE_Y, PADDLE_W, PADDLE_H) then
        vy = -vy
        by = PADDLE_Y - BALL
        local hit = (bx + BALL / 2) - (paddleX + PADDLE_W / 2)
        vx = math.floor(hit / (PADDLE_W / 2) * SPEED)
        if vx == 0 then vx = (hit < 0) and -1 or 1 end
    end

    for _, b in ipairs(bricks) do
        if b.alive and overlap(bx, by, BALL, BALL, b.x, b.y, BRICK_W, BRICK_H) then
            b.alive = false
            lv.obj.add_flag(b.obj, lv.OBJ_FLAG_HIDDEN)
            bricksLeft = bricksLeft - 1
            vy = -vy
            if bricksLeft <= 0 then
                finish(true)
                return
            end
            break
        end
    end

    lv.obj.set_pos(ball, bx, by)
end

-- ---------------------------------------------------------------------------
local function movePaddle(d)
    paddleX = paddleX + d
    if paddleX < 0 then paddleX = 0 end
    if paddleX > W - PADDLE_W then paddleX = W - PADDLE_W end
    lv.obj.set_pos(paddle, paddleX, PADDLE_Y)
    if phase == "wait" then
        bx = math.floor(paddleX + PADDLE_W / 2 - BALL / 2)
        lv.obj.set_pos(ball, bx, by)
    end
end

local function action(b)
    if phase == "end" then return end
    if b == 20 then
        movePaddle(-STEP)
    elseif b == 19 then
        movePaddle(STEP)
    elseif b == 10 then
        if phase == "wait" then phase = "run" end
    end
end

local function onKey(e)
    local k = lv.event.get_key_value(e)
    if k == nil then return end
    action(string.byte(k))
end

-- On device the wheel click arrives as EVENT_CLICKED (lua-api notes).
local function onClick(e)
    action(10)
end

-- TEST ONLY (tools/sim_driver.lua): read-only snapshot of the game so the
-- simulator driver can steer the paddle with real key events. Never called
-- by the story; inert on device.
function breakout.peek()
    return { bx = bx, by = by, vx = vx, vy = vy, paddleX = paddleX, paddleW = PADDLE_W,
             ball = BALL, step = STEP, W = W, H = H, phase = phase, lives = lives,
             bricksLeft = bricksLeft, container = container }
end

-- args: image (backdrop .lif), audio (start cue), win_audio, lose_audio,
--       onWin, onLose, onBack (functions)
function breakout.create(args)
    opts = args or {}
    -- Start cue first, before any image/UI work, with priority so it cuts in.
    Global.requestAudioPlay({ path = opts.audio, priority = true, showPause = false })

    lv.obj.clean(window)
    lv.group.set_editing(document, true)
    Global.setBackBehavior(opts.onBack)
    initStyles()

    container = lv.obj.new(window)
    lv.obj.remove_style_all(container)
    lv.obj.set_size(container, W, H)
    lv.obj.add_style(container, breakout.styles.bg, lv.STATE_DEFAULT)
    lv.obj.clear_flag(container, lv.OBJ_FLAG_SCROLLABLE)
    breakout.events[container] = {
        key = lv.obj.add_event_cb(container, onKey, lv.EVENT_KEY),
        click = lv.obj.add_event_cb(container, onClick, lv.EVENT_CLICKED),
    }
    lv.group.add_obj(document, container)

    -- Backdrop (320x212 game field art)
    local bg = lv.img.new(container)
    lv.obj.remove_style_all(bg)
    breakout.images.bg = Global.load_image(opts.image)
    lv.img.set_src(bg, breakout.images.bg)
    lv.obj.set_pos(bg, 0, 0)

    paddleX = math.floor((W - PADDLE_W) / 2)
    lives, finished = LIVES, false
    buildBricks()

    paddle = lv.obj.new(container)
    lv.obj.remove_style_all(paddle)
    lv.obj.set_size(paddle, PADDLE_W, PADDLE_H)
    lv.obj.add_style(paddle, breakout.styles.paddle, lv.STATE_DEFAULT)
    lv.obj.set_pos(paddle, paddleX, PADDLE_Y)

    ball = lv.obj.new(container)
    lv.obj.remove_style_all(ball)
    lv.obj.set_size(ball, BALL, BALL)
    lv.obj.add_style(ball, breakout.styles.ball, lv.STATE_DEFAULT)

    livesLbl = lv.label.new(container)
    lv.obj.remove_style_all(livesLbl)
    lv.obj.add_style(livesLbl, breakout.styles.text, lv.STATE_DEFAULT)
    lv.obj.align(livesLbl, lv.ALIGN_TOP_LEFT, 4, 4)
    refreshLives()

    msgLbl = lv.label.new(container)
    lv.obj.remove_style_all(msgLbl)
    lv.obj.add_style(msgLbl, breakout.styles.msg, lv.STATE_DEFAULT)
    lv.label.set_text(msgLbl, "")
    lv.obj.add_flag(msgLbl, lv.OBJ_FLAG_HIDDEN)

    holdBall()
    loopTimer = lv.timer.new(tick, 25, nil)
end

return breakout
