-- ============================================================================
-- kipodi_scene_1_0_0.lua -- One story screen for "Kipodi learns to ride a bike".
-- (Copied from the beach story's scene; hotspot style removed.)
-- Picture + text + optional info line (backpack / traits) + choice rows.
-- Wheel (keys 19/20) moves the selection, click confirms. Only a click ever
-- confirms; the wheel never advances a "Next" screen.
-- Accidental-input guards: on choice screens wheel and click are ignored until
-- the narration has finished; one wheel step per 150 ms; no wrap-around.
-- ============================================================================

local scene = {}
scene.styles = {}
scene.events = {}
scene.images = {}

local container, ticks, lastEnter, lastWheel, locked
local rows, rowLabels, choices, sel
local img
local KEY_ENTER = 10
local GUARD = 32       -- ticks (25 ms): 800 ms, longer than the 500 ms audio delayer
local WHEEL_GAP = 6    -- 150 ms between wheel steps
local CLICK_GAP = 12   -- 300 ms between clicks (and after the screen opens)
local PENDING_MAX = 120 -- 3 s

local COL_BG = 0x1a2433
local COL_TEXT = 0xefedea
local COL_INFO = 0xfbbd2a
local COL_ROW = 0x1a2433
local COL_SEL = 0xfbbd2a

function scene.clean()
    if scene._timer ~= nil then
        lv.timer.del(scene._timer)
        scene._timer = nil
    end
    for obj, ev in pairs(scene.events) do
        for _, cb in pairs(ev) do
            lv.obj.remove_event_cb(obj, cb)
        end
    end
    -- No stop-all here: the next screen's priority play cuts in (handoff doc, section 2).
    Global.requestAudioStop()
    lv.group.set_editing(document, false)
    lv.group.remove_all_objs(document)
    lv.obj.clean(window)
    if Global.KB ~= nil then
        Global.KB.ui = nil
    end
    container = nil
    rows, rowLabels, choices, sel = nil, nil, nil, nil
    img = nil
    scene.styles = {}
    scene.events = {}
    scene.images = {}
end

local function show_image(name)
    if img == nil or name == nil then return end
    local data = scene.images[name]
    if data == nil then
        data = Global.load_image(name)
        scene.images[name] = data
    end
    lv.img.set_src(img, data)
end

local function paint()
    if rows == nil then return end
    for i = 1, #rows do
        if i == sel then
            lv.obj.set_style_bg_color(rows[i], lv.color.hex(COL_SEL), lv.STATE_DEFAULT)
            lv.obj.set_style_bg_opa(rows[i], lv.OPA_COVER, lv.STATE_DEFAULT)
            lv.obj.set_style_text_color(rowLabels[i], lv.color.hex(COL_BG), lv.STATE_DEFAULT)
            lv.label.set_text(rowLabels[i], "> " .. choices[i].label .. " <")
        else
            lv.obj.set_style_bg_color(rows[i], lv.color.hex(COL_ROW), lv.STATE_DEFAULT)
            lv.obj.set_style_bg_opa(rows[i], 190, lv.STATE_DEFAULT)
            lv.obj.set_style_text_color(rowLabels[i], lv.color.hex(COL_TEXT), lv.STATE_DEFAULT)
            lv.label.set_text(rowLabels[i], choices[i].label)
        end
    end
    if Global.KB ~= nil and Global.KB.ui ~= nil then
        Global.KB.ui.sel = sel
    end
end

local function confirm()
    if choices == nil or choices[sel] == nil then return end
    local fn = choices[sel].onSelect
    if fn ~= nil then fn() end
end

local function action(b)
    if choices == nil or locked then return end
    if b == KEY_ENTER then
        if ticks - lastEnter < CLICK_GAP then return end
        lastEnter = ticks
        confirm()
    elseif b == 19 or b == 20 then
        if #choices < 2 or ticks - lastWheel < WHEEL_GAP then return end
        lastWheel = ticks
        local s = sel + ((b == 19) and 1 or -1)
        if s >= 1 and s <= #choices then   -- clamp, no wrap-around
            sel = s
            paint()
        end
    end
end

local function onKey(e)
    local k = lv.event.get_key_value(e)
    if k == nil then return end
    action(string.byte(k))
end

local function onClick(e)
    action(KEY_ENTER)
end

local function unlock()
    locked = false
    paint()
    if Global.KB ~= nil and Global.KB.ui ~= nil then
        Global.KB.ui.ready = true
    end
end

local function tick()
    ticks = ticks + 1
    -- Choice screens open once the narration is over. Global.audioDelayPath is
    -- the runtime's pending request: while it is set our clip has not started
    -- yet (the delayer may be between stopping the old clip and loading ours).
    -- After 3 s with a request still pending (load failed) open anyway.
    if locked and ticks >= GUARD and audio.get_status() ~= "play"
        and (Global.audioDelayPath == nil or ticks >= PENDING_MAX) then
        unlock()
    end
end

local function count_lines(s, per_line)
    local n = 0
    for line in string.gmatch(s .. "\n", "(.-)\n") do
        n = n + 1 + math.max(0, math.floor((#line - 1) / per_line))
    end
    return n
end

-- args: image, text, info (string or nil), choices = { {label, onSelect} } (max 5),
--       audio (string or nil), onBack (function) or home = true, id (string)
function scene.create(args)
    args = args or {}
    -- Narration first, before any image/UI work, with priority so it cuts in.
    if args.audio ~= nil then
        Global.requestAudioPlay({ path = args.audio, priority = true, showPause = false })
    end
    ticks, lastEnter, lastWheel = 0, 0, -100
    choices = args.choices or {}
    locked = (#choices > 1)
    sel = 1

    lv.obj.clean(window)
    lv.group.set_editing(document, true)
    if args.home then
        -- Story home screen: back leaves to the library (Relance pattern).
        back_callback = function()
            Global.requestAudioStop(true, true)
            goto_library()
        end
    else
        Global.setBackBehavior(args.onBack)
    end

    local S = scene.styles
    S.bg = lv.style.new()
    lv.style.set_bg_color(S.bg, lv.color.hex(COL_BG))
    lv.style.set_bg_opa(S.bg, lv.OPA_COVER)
    lv.style.set_pad_all(S.bg, 0)

    S.band = lv.style.new()
    lv.style.set_bg_color(S.band, lv.color.black())
    lv.style.set_bg_opa(S.band, 150)
    lv.style.set_pad_all(S.band, 0)

    S.text = lv.style.new()
    lv.style.set_text_color(S.text, lv.color.hex(COL_TEXT))
    lv.style.set_text_font(S.text, lv.font.nunito_extrabold_16)
    lv.style.set_text_align(S.text, lv.TEXT_ALIGN_CENTER)

    S.info = lv.style.new()
    lv.style.set_text_color(S.info, lv.color.hex(COL_INFO))
    lv.style.set_text_font(S.info, lv.font.nunito_extrabold_12)
    lv.style.set_text_align(S.info, lv.TEXT_ALIGN_CENTER)

    S.row = lv.style.new()
    lv.style.set_radius(S.row, 8)
    lv.style.set_pad_all(S.row, 0)

    S.rowText = lv.style.new()
    lv.style.set_text_font(S.rowText, lv.font.nunito_extrabold_14)
    lv.style.set_text_align(S.rowText, lv.TEXT_ALIGN_CENTER)

    local W, H = Global.visual_width, Global.visual_height

    container = lv.obj.new(window)
    lv.obj.remove_style_all(container)
    lv.obj.set_size(container, W, H)
    lv.obj.add_style(container, S.bg, lv.STATE_DEFAULT)
    lv.obj.clear_flag(container, lv.OBJ_FLAG_SCROLLABLE)
    scene.events[container] = {
        key = lv.obj.add_event_cb(container, onKey, lv.EVENT_KEY),
        click = lv.obj.add_event_cb(container, onClick, lv.EVENT_CLICKED),
    }
    lv.group.add_obj(document, container)

    -- Picture (320x240 art, centred vertically in the 212 px window)
    if args.image ~= nil then
        img = lv.img.new(container)
        lv.obj.remove_style_all(img)
        show_image(args.image)
        lv.obj.set_pos(img, 0, math.floor((H - 240) / 2))
    end

    -- Top band: text + info
    local textLines = count_lines(args.text or "", 34)
    local infoLines = 0
    if args.info ~= nil and args.info ~= "" then
        infoLines = count_lines(args.info, 46)
    end
    local bandH = 8 + textLines * 20 + infoLines * 16 + 4
    local band = lv.obj.new(container)
    lv.obj.remove_style_all(band)
    lv.obj.add_style(band, S.band, lv.STATE_DEFAULT)
    lv.obj.set_size(band, W, bandH)
    lv.obj.set_pos(band, 0, 0)
    lv.obj.clear_flag(band, lv.OBJ_FLAG_SCROLLABLE)

    local label = lv.label.new(band)
    lv.obj.remove_style_all(label)
    lv.obj.set_width(label, W - 16)
    lv.label.set_long_mode(label, lv.LABEL_LONG_WRAP)
    lv.label.set_text(label, args.text or "")
    lv.obj.add_style(label, S.text, lv.STATE_DEFAULT)
    lv.obj.align(label, lv.ALIGN_TOP_MID, 0, 6)

    if infoLines > 0 then
        local info = lv.label.new(band)
        lv.obj.remove_style_all(info)
        lv.obj.set_width(info, W - 16)
        lv.label.set_long_mode(info, lv.LABEL_LONG_WRAP)
        lv.label.set_text(info, args.info)
        lv.obj.add_style(info, S.info, lv.STATE_DEFAULT)
        lv.obj.align(info, lv.ALIGN_TOP_MID, 0, 8 + textLines * 20)
    end

    -- Choice rows, stacked at the bottom
    rows, rowLabels = {}, {}
    local n = #choices
    local rowH, gap = 24, 3
    local rowW, rowX = 240, math.floor((W - 240) / 2)
    if n == 1 then
        rowW, rowX = 120, W - 120 - 8
    end
    for i = 1, n do
        local r = lv.obj.new(container)
        lv.obj.remove_style_all(r)
        lv.obj.add_style(r, S.row, lv.STATE_DEFAULT)
        lv.obj.set_size(r, rowW, rowH)
        lv.obj.set_pos(r, rowX, H - 6 - (n - i + 1) * rowH - (n - i) * gap)
        lv.obj.clear_flag(r, lv.OBJ_FLAG_SCROLLABLE)
        local t = lv.label.new(r)
        lv.obj.remove_style_all(t)
        lv.obj.add_style(t, S.rowText, lv.STATE_DEFAULT)
        lv.obj.align(t, lv.ALIGN_CENTER, 0, 0)
        rows[i] = r
        rowLabels[i] = t
    end

    -- Test/debug handle (read-only view of the screen; no behaviour change)
    if Global.KB ~= nil then
        local labels = {}
        for i = 1, #choices do labels[i] = choices[i].label end
        Global.KB.ui = { id = args.id, container = container, n = #choices, sel = sel,
                         info = args.info, ready = not locked, labels = labels }
    end
    paint()

    scene._timer = lv.timer.new(tick, 25, nil)
end

return scene
