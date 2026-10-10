dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P

local im = H.img(240, 135)
local F = 104
H.hallway(im, F)

H.text(im, "PACKAGE HEALTH", 120, 6, P.cream, { s = 2, outline = P.ink, ot = 1, shadow = P.card_d, sd = 2, align = "center" })

local states = { { 0, "INTACT", 3 }, { 1, "DAMAGED", 2 }, { 2, "DESTROYED", 0 } }
for i, s in ipairs(states) do
  local cx = 40 + (i - 1) * 80
  H.package(im, cx - 32, F + 2, s[1], 2)
  H.tag(im, s[2], cx, 108, P.white, P.ui, "center")
  -- health pips
  for k = 0, 2 do
    local on = k < s[3]
    H.box(im, cx - 16 + k * 11, 122, 9, 6, on and P.mat_g or P.ui_l, P.ink)
  end
end

H.save(im, "04_package_states", 8)
