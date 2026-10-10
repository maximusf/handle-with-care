dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P

local W, Hh = 480, 135
local im = H.img(W, Hh, P.sky)
local F = 118        -- lot surface
local CURB = 114     -- sidewalk top after the curb
local PLAT = 94      -- receiving platform top

-- sky + clouds
H.rect(im, 0, 0, W, 30, P.sky_l)
for _, c in ipairs({ { 120, 20 }, { 230, 14 }, { 300, 28 } }) do
  H.ellipse(im, c[1], c[2], 14, 4, P.white)
  H.ellipse(im, c[1] + 10, c[2] - 3, 9, 4, P.white)
end

-- asphalt lot with parking stripes
H.rect(im, 0, F, 262, Hh - F, P.asphalt)
H.rect(im, 0, F, 262, 1, P.asphalt_d)
for x = 8, 240, 40 do H.rect(im, x, F + 8, 16, 2, P.stripe) end

-- curb and sidewalk
H.rect(im, 262, CURB, W - 262, Hh - CURB, P.concrete)
H.rect(im, 262, CURB, W - 262, 1, P.concrete_l)
H.rect(im, 262, CURB, 3, Hh - CURB, P.concrete_d)
for x = 290, W, 28 do H.rect(im, x, CURB + 1, 1, Hh - CURB, P.concrete_d) end

-- hotel facade
local HX = 362
H.rect(im, HX, 20, W - HX, PLAT - 20, P.wall)
for x = HX, W - 1, 16 do H.rect(im, x, 20, 8, PLAT - 20, P.wall_l) end
H.rect(im, HX - 4, 16, W - HX + 4, 6, P.base)
H.box(im, 396, 4, 72, 13, P.carpet, P.ink)
H.text(im, "HOTEL", 432, 7, P.gold, { align = "center" })
H.window(im, 368, 30, false)

-- receiving platform + steps
H.rect(im, 330, PLAT, W - 330, CURB - PLAT, P.concrete_l)
H.rect(im, 330, PLAT, W - 330, 1, P.white)
H.rect(im, 330, PLAT + 2, W - 330, 1, P.concrete_d)
local function step(x, top)
  H.rect(im, x, top, 12, CURB - top, P.concrete_l)
  H.rect(im, x, top, 12, 1, P.white)
  H.rect(im, x, top, 1, CURB - top, P.concrete_d)
end
step(294, 107); step(306, 101); step(318, 97)
H.rect(im, 330, PLAT, 1, CURB - PLAT, P.concrete_d)

-- glass double doors
local DX = 414
H.rect(im, DX - 3, PLAT - 58, 50, 58, P.frame)
for i = 0, 1 do
  H.box(im, DX + i * 22, PLAT - 55, 22, 55, P.sky, P.ink)
  H.line(im, DX + i * 22 + 4, PLAT - 20, DX + i * 22 + 14, PLAT - 46, P.sky_l)
  H.rect(im, DX + i * 22 + (i == 0 and 18 or 2), PLAT - 30, 2, 8, P.gold)
end
H.mat(im, 406, PLAT, "none", 50)

-- truck and dolly
H.truck(im, 2, F)
H.dolly(im, 160, F, 2)

-- puddle on the sidewalk
H.puddle(im, 268, CURB, 24)

-- player near the start
H.player(im, 200, F, 0, 2)

-- suggested kick routes: up the steps, and one long lob
H.arc(im, 248, 108, 424, PLAT - 2, 50, P.white, 7, 2)
H.arc(im, 248, 112, 300, 104, 12, P.yellow, 6, 2)
H.arc(im, 300, 104, 416, PLAT - 2, 18, P.yellow, 6, 2)

-- labels
H.tag(im, "LEVEL 01 - HOTEL EXTERIOR", 3, 3)
H.tag(im, "1 REQUIRED / 2 AVAILABLE", 3, 16, P.yellow)
H.tag(im, "TRUCK", 150, 16, P.white, P.ui_l)
H.tag(im, "DOLLY", 160, F - 78, P.white, P.ui_l)
H.tag(im, "A/D MOVE", 196, 28, P.mat_g)
H.tag(im, "HOLD LMB", 196, 40, P.mat_g)
H.tag(im, "CURB", 250, 124, P.white)
H.tag(im, "PUDDLE", 266, 124 - 23, P.water_l)
H.tag(im, "STEPS", 300, 83, P.white)
H.tag(im, "DELIVERY MAT", 408, 104, P.mat_y)
H.save(im, "13_level01_layout", 4)
