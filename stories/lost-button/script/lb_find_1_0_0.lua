-- ============================================================================
-- lb_find_1_0_0.lua -- Spot the shiny button, put it in the backpack.
-- ============================================================================

local scene = {}
scene.styles = {}
scene.events = {}
scene.images = {}

local container, ticks, lastEnter
local KEY_ENTER = 10

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
    Global.requestAudioStop(true, true)
    lv.group.set_editing(document, false)
    lv.group.remove_all_objs(document)
    lv.obj.clean(window)
    container = nil
    scene.styles = {}
    scene.events = {}
    scene.images = {}
end

local function take_button()
    if Global.LB ~= nil then
        Global.LB.has_button = true
        Global.LB.show_backpack()
    end
end

local function action(b)
    if b == KEY_ENTER then
        if ticks - lastEnter < 4 then return end
        lastEnter = ticks
        take_button()
    elseif b == 19 or b == 20 then
        take_button()
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

local function tick()
    ticks = ticks + 1
end

function scene.create(args)
    args = args or {}
    ticks, lastEnter = 0, -100

    lv.obj.clean(window)
    lv.group.set_editing(document, true)
    Global.setBackBehavior(function()
        if Global.LB ~= nil then
            Global.LB.puddle_choice()
        end
    end)

    local S = scene.styles
    S.bg = lv.style.new()
    lv.style.set_bg_color(S.bg, lv.color.hex(0x243044))
    lv.style.set_bg_opa(S.bg, lv.OPA_COVER)

    S.text = lv.style.new()
    lv.style.set_text_color(S.text, lv.color.hex(0xefedea))
    lv.style.set_text_font(S.text, lv.font.nunito_extrabold_16)
    lv.style.set_text_align(S.text, lv.TEXT_ALIGN_CENTER)

    S.hint = lv.style.new()
    lv.style.set_text_color(S.hint, lv.color.hex(0xfbbd2a))
    lv.style.set_text_font(S.hint, lv.font.nunito_bold_12)
    lv.style.set_text_align(S.hint, lv.TEXT_ALIGN_CENTER)

    container = lv.obj.new(window)
    lv.obj.remove_style_all(container)
    lv.obj.set_size(container, Global.visual_width, Global.visual_height)
    lv.obj.add_style(container, S.bg, lv.STATE_DEFAULT)
    lv.obj.clear_flag(container, lv.OBJ_FLAG_SCROLLABLE)
    scene.events[container] = {
        key = lv.obj.add_event_cb(container, onKey, lv.EVENT_KEY),
        click = lv.obj.add_event_cb(container, onClick, lv.EVENT_CLICKED),
    }
    lv.group.add_obj(document, container)

    local side = "left"
    if Global.LB ~= nil and Global.LB.path ~= nil then
        side = Global.LB.path
    end

    local data = Global.load_image("button.lif")
    scene.images.btn = data
    local img = lv.img.new(container)
    lv.obj.remove_style_all(img)
    lv.img.set_src(img, data)
    lv.obj.align(img, lv.ALIGN_CENTER, 0, -10)

    local label = lv.label.new(container)
    lv.obj.remove_style_all(label)
    lv.obj.set_width(label, 300)
    lv.label.set_long_mode(label, lv.LABEL_LONG_WRAP)
    lv.label.set_text(label, "In the " .. side .. " puddle:\na shiny button.")
    lv.obj.add_style(label, S.text, lv.STATE_DEFAULT)
    lv.obj.align(label, lv.ALIGN_TOP_MID, 0, 8)

    local hint = lv.label.new(container)
    lv.obj.remove_style_all(hint)
    lv.obj.set_width(hint, 300)
    lv.label.set_text(hint, "Click to put it in your backpack")
    lv.obj.add_style(hint, S.hint, lv.STATE_DEFAULT)
    lv.obj.align(hint, lv.ALIGN_BOTTOM_MID, 0, -6)

    scene._timer = lv.timer.new(tick, 25, nil)
end

return scene
