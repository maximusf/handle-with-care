dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
dofile(H.SRC .. "ui_common.lua")
local P = H.P

local W, Hh = 320, 180
local im = U.scene(W, Hh)
U.blur(im, 2)
H.shade(im, 0, 0, W, Hh, P.ui, 0.5)

H.panel(im, 12, 6, 294, 166)
H.text(im, "SETTINGS", 160, 12, P.cream, { s = 2, outline = P.ink, shadow = P.card_d, sd = 1, align = "center" })
H.rect(im, 20, 32, 280, 1, P.ui_ll)
H.rect(im, 154, 38, 1, 100, P.ui_ll)

-- audio
local L = 22
H.text(im, "AUDIO", L, 40, P.gold)
H.text(im, "MUSIC", L, 53, P.white)
H.slider(im, 58, 52, 70, 0.8)
H.text(im, "80%", 132, 53, P.gray)
H.text(im, "SFX", L, 67, P.white)
H.slider(im, 58, 66, 70, 0.6)
H.text(im, "60%", 132, 67, P.gray)

-- credits
H.text(im, "CREDITS", L, 86, P.gold)
H.text(im, "THE MUCKSLINGER GANG", L, 98, P.orange)
H.text(im, "RAVEN JAIME", L, 110, P.white)
H.text(im, "CARLOS MENDOZA", L, 120, P.white)
H.text(im, "MAXIMUS FERNANDEZ", L, 130, P.white)

-- controls
local R, A = 160, 230
H.text(im, "CONTROLS", R, 40, P.gold)
local rows = {
  { "A / D", "MOVE" }, { "SPACE", "JUMP" }, { "HOLD LMB", "AIM + CHARGE" },
  { "RELEASE LMB", "KICK" }, { "RMB", "CANCEL KICK" }, { "R", "RESTART" },
}
for i, r in ipairs(rows) do
  local y = 53 + (i - 1) * 13
  H.text(im, r[1], R, y, P.yellow)
  H.text(im, r[2], A, y, P.white)
end

H.button(im, 160, 146, "BACK", 72, true)
H.save(im, "10_settings", 6)
