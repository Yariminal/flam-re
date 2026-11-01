-- flamtool playback proof: write a marker to the SD from inside a minted story
local marker = "FLAMTOOL_OK fw2.4.2 unwrap=Enc_devkey(keyfile) sk=C0 iv=C1\n"
local paths = {
  "/sd0/FLAMTOOL_OK.txt", "/SD0/FLAMTOOL_OK.txt",
  "/sd/FLAMTOOL_OK.txt", "/sdcard/FLAMTOOL_OK.txt",
  "FLAMTOOL_OK.txt",
}
local function w(p)
  local f = io.open(p, "w")
  if f then f:write(marker) f:close() end
end
local function main()
  for _, p in ipairs(paths) do pcall(w, p) end
end
main()
