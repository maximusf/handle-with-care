dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P

local W, Hh = 480, 135
local im = H.img(W, Hh)
local F = 118

local function dashed(x0, x1, y, c)
  for x = x0, x1, 6 do H.rect(im, x, y, 3, 1, c) end
end
local function dotted(x0, y0, x1, y1, c)
  local n = math.floor(math.max(math.abs(x1 - x0), math.abs(y1 - y0)) / 4)
  for i = 0, n do
    H.rect(im, math.floor(x0 + (x1 - x0) * i / n), math.floor(y0 + (y1 - y0) * i / n), 2, 2, c)
  end
end
-- swinging door: open door plus a curved swing arrow off its edge
local function swingdoor(x, num)
  H.door(im, x, F, num, true)
  H.arc(im, x + 12, F - 40, x + 32, F - 40, 10, P.yellow, 2, 1)
  H.arrowhead(im, x + 32, F - 37, 0, 1, P.yellow, 3); H.arrowhead(im, x + 12, F - 37, 0, 1, P.yellow, 3)
end

H.hallway(im, F)
for _, lx in ipairs({ 104, 222, 330 }) do H.lamp(im, lx, 14) end

-- doors
H.door(im, 60, F, 301)
H.mat(im, 54, F, "none", 40)
swingdoor(128, 302)
H.door(im, 262, F, 303)
H.mat(im, 256, F, "none", 40)
swingdoor(346, 304)

-- freight door at the end
local FX = 426
H.rect(im, FX - 3, F - 78, 57, 78, P.base_d)
for y = F - 75, F - 1, 5 do
  H.rect(im, FX, y, 51, 4, P.concrete)
  H.rect(im, FX, y + 4, 51, 1, P.concrete_d)
end
H.box(im, FX + 1, F - 90, 49, 11, P.stripe, P.ink)
H.text(im, "FREIGHT", FX + 26, F - 88, P.ink, { align = "center" })
for x = FX, FX + 48, 8 do H.rect(im, x, F - 4, 4, 3, P.stripe) end

-- hazards
H.cactus(im, 180, F)
H.cactus(im, 318, F)
H.cart(im, 200, F)
dashed(200, 250, F - 44, P.white)
H.arrowhead(im, 198, F - 44, -1, 0, P.white, 3)
H.arrowhead(im, 252, F - 44, 1, 0, P.white, 3)
H.vacuum(im, 292, F)

-- pressure plate linked to the freight door
H.plate(im, 394, F)
dotted(407, F - 6, 407, F - 60, P.yellow)
dotted(407, F - 60, FX - 4, F - 60, P.yellow)

-- player near the start
H.player(im, 2, F, 0, 2)

-- suggested routes
H.arc(im, 48, F - 8, 70, F + 2, 14, P.yellow, 5, 2)
H.arc(im, 48, F - 8, 276, F + 2, 58, P.white, 7, 2)

-- labels
H.tag(im, "LEVEL 03 - GUEST HALLWAY", 3, 3)
H.tag(im, "2 REQUIRED / 4 AVAILABLE", 3, 16, P.yellow)
H.tag(im, "MAT", 58, 125, P.mat_y)
H.tag(im, "MAT", 262, 125, P.mat_y)
H.tag(im, "SWINGING DOOR", 124, 125, P.white)
H.tag(im, "CACTUS", 172, 36, P.mat_g)
H.tag(im, "CART ROUTE", 200, 58, P.white)
H.tag(im, "VACUUM", 288, 125, P.white)
H.tag(im, "PLATE HOLD 2S", 354, 125, P.gold)
H.tag(im, "FREIGHT DOOR", 404, 3, P.stripe)
H.save(im, "15_level03_layout", 4)
