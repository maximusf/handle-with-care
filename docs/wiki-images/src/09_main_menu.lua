dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
dofile(H.SRC .. "ui_common.lua")
local P = H.P

local im = U.scene(240, 135, { nofly = true, matpkg = 1 })
H.shade(im, 0, 0, 240, 135, P.ui, 0.45)

H.title(im, 120, 3)

H.button(im, 120, 66, "START", 84, true)
H.button(im, 120, 88, "SETTINGS", 84)
H.button(im, 120, 110, "EXIT", 84)
H.cursor(im, 150, 74)

H.save(im, "09_main_menu", 8)
