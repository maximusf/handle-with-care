dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P

local W, Hh = 480, 180
local im = H.img(W, Hh, P.wall_l)
local F1, F2, F3 = 172, 132, 92

local function dotted(x0, y0, x1, y1, c)
  local n = math.floor(math.max(math.abs(x1 - x0), math.abs(y1 - y0)) / 4)
  for i = 0, n do
    H.rect(im, math.floor(x0 + (x1 - x0) * i / n), math.floor(y0 + (y1 - y0) * i / n), 2, 2, c)
  end
end

-- painted stairwell wall with a stripe band
for x = 0, W - 1, 20 do H.rect(im, x, 0, 1, Hh, P.wall) end
H.rect(im, 0, 150, W, 3, P.orange)
H.rect(im, 0, 110, W, 3, P.orange)
H.rect(im, 0, 70, W, 3, P.orange)

-- solid floor slab from y down to the bottom
local function slab(x, w, y)
  H.rect(im, x, y, w, Hh - y, P.concrete_d)
  H.rect(im, x, y, w, 4, P.concrete)
  H.rect(im, x, y, w, 1, P.concrete_l)
  for yy = y + 10, Hh - 1, 10 do
    for xx = x + ((yy // 10) % 2) * 10, x + w - 1, 20 do H.rect(im, xx, yy, 1, 10, P.gray) end
    H.rect(im, x, yy, w, 1, P.gray)
  end
end
-- staircase of n steps rising from (x, yLow) to yHigh
local function stairs(x, w, yLow, yHigh)
  local n = 5
  local sw, sh = w // n, (yLow - yHigh) // n
  for i = 0, n - 1 do slab(x + i * sw, sw, yLow - (i + 1) * sh) end
  -- handrail
  H.line(im, x, yLow - 16, x + w, yHigh - 16, P.base, 2)
  for i = 0, n do
    local px = math.min(x + i * sw, x + w - 1)
    H.rect(im, px, yLow - i * sh - 16, 1, 16, P.base_d)
  end
end

slab(0, 150, F1)
stairs(150, 50, F1, F2)
slab(200, 120, F2)
stairs(320, 50, F2, F3)
slab(370, 110, F3)

-- landing 1: cart, door, wall switch
H.cart(im, 58, F1)
H.door(im, 112, F1, 401)
H.mat(im, 106, F1, "none", 40)
H.box(im, 80, 110, 9, 13, P.white, P.ink)
H.rect(im, 83, 113, 3, 4, P.xred)

-- landing 2: broken window, vacuum, door
H.window(im, 208, 72, true)
H.vacuum(im, 246, F2)
H.door(im, 280, F2, 402)
H.mat(im, 274, F2, "none", 40)

-- landing 3: intact window, locked door
H.window(im, 376, 48, false)
H.door(im, 420, F3, 403)
H.mat(im, 414, F3, "none", 40)
H.box(im, 432, F3 - 44, 12, 10, P.gold, P.ink)          -- padlock
H.rect(im, 435, F3 - 49, 6, 1, P.ink)
H.rect(im, 434, F3 - 48, 1, 4, P.ink); H.rect(im, 441, F3 - 48, 1, 4, P.ink)
H.rect(im, 437, F3 - 41, 2, 3, P.ink)

-- switch linked to the locked door
dotted(84, 108, 84, 40, P.yellow)
dotted(84, 40, 414, 40, P.yellow)
H.arrowhead(im, 416, 41, 1, 0, P.yellow, 3)

-- player near the start
H.player(im, 2, F1, 0, 2)

-- suggested routes: up to landing 2, then landing 3
H.arc(im, 50, F1 - 10, 292, F2 + 2, 70, P.white, 7, 2)
H.arc(im, 262, F2 - 12, 430, F3 + 2, 34, P.white, 7, 2)

-- labels
H.tag(im, "LEVEL 04 - STAIRWELL", 3, 3)
H.tag(im, "3 REQUIRED / 5 AVAILABLE", 3, 16, P.yellow)
H.tag(im, "WALL SWITCH", 4, 95, P.yellow)
H.tag(im, "CART", 62, 118 + 6, P.white)
H.tag(im, "SHATTERS ON STRONG KICK", 196, 58, P.water_l)
H.tag(im, "VACUUM", 236, 140, P.white)
H.tag(im, "LOCKED", 418, 100, P.xred)
H.tag(im, "LANDING 1", 4, 81, P.white, P.ui_l)
H.tag(im, "LANDING 2", 206, 160, P.white, P.ui_l)
H.tag(im, "LANDING 3", 376, 160, P.white, P.ui_l)
H.save(im, "16_level04_layout", 4)
