-- flamtool proof v2: on-screen label + save marker
local function main()
  pcall(function()
    local l = lv.label.new(window)
    lv.label.set_text(l, "FLAMTOOL EXEC OK")
  end)
  pcall(function()
    local f = io.open("/sd0/FLAMTOOL_OK.txt", "w")
    if f then f:write("ok\n") f:close() end
  end)
end
main()
