dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P
dofile(H.SRC .. "arrows_local.lua")

local im = H.img(240, 135)
local F = 118
H.hallway(im, F)
H.lamp(im, 100, 8)

-- walking courier with left / right arrows
H.player(im, 14, F, 6, 2)
A_arrow(im, 22, 78, 5, 78)
A_arrow(im, 56, 78, 73, 78)
H.tag(im, "A", 9, 60, P.white, P.ui, "center")
H.tag(im, "D", 69, 60, P.white, P.ui, "center")

-- package waiting on the floor
H.package(im, 92, F, 0)

-- jumping courier: motion dashes, up arrow
local jx, jy = 150, 96
for _, dx in ipairs({ 18, 26, 34 }) do H.line(im, jx + dx, jy + 4, jx + dx, jy + 12, P.white) end
H.player(im, jx, jy, 11, 3)
A_arrow(im, jx + 26, 34, jx + 26, 20)
H.tag(im, "SPACE", jx + 26, 6, P.white, P.ui, "center")

H.tag(im, "WALK", 40, 122, P.white, P.ui, "center")
H.tag(im, "JUMP", jx + 26, 122, P.white, P.ui, "center")

H.save(im, "02_movement", 8)
