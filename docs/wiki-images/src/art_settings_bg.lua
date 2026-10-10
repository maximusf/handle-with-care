dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
dofile(H.SRC .. "ui_common.lua")
local P = H.P

local im = U.scene(240, 135)
U.blur(im, 2)
H.shade(im, 0, 0, 240, 135, P.ui, 0.5)
H.save(im, "art_settings_bg", 8)
