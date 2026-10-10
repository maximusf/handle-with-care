dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P

local W, Hh = 480, 135
local im = H.img(W, Hh, P.wall)
local F = 114

local function dashed(x0, x1, y, c)
  for x = x0, x1, 6 do H.rect(im, x, y, 3, 1, c) end
end
local function dotted(x0, y0, x1, y1, c)
  local n = math.floor(math.max(math.abs(x1 - x0), math.abs(y1 - y0)) / 4)
  for i = 0, n do
    H.rect(im, math.floor(x0 + (x1 - x0) * i / n), math.floor(y0 + (y1 - y0) * i / n), 2, 2, c)
  end
end

-- lobby wall: pilasters, crown, wainscot
for x = 0, W - 1, 60 do
  H.rect(im, x + 50, 0, 10, F, P.wall_l)
  H.rect(im, x + 50, 0, 1, F, P.wall_d)
end
H.rect(im, 0, 0, W, 5, P.base)
H.rect(im, 0, F - 18, W, 18, P.wall_d)
H.rect(im, 0, F - 18, W, 1, P.base)
H.rect(im, 0, F - 4, W, 4, P.base)

-- marble checker floor
for y = F, Hh - 1, 7 do
  for x = 0, W - 1, 14 do
    local odd = ((x // 14) + (y - F) // 7) % 2 == 1
    H.rect(im, x, y, 14, 7, odd and P.tile_d or P.marble)
  end
end
H.rect(im, 0, F, W, 1, P.tile_d)

-- chandelier
H.rect(im, 239, 5, 2, 8, P.gold_d)
H.box(im, 225, 13, 30, 5, P.gold, P.gold_d)
for x = 227, 252, 6 do H.rect(im, x, 18, 2, 4, P.cream) end

-- entrance glass doors on the left
H.rect(im, 0, F - 62, 30, 62, P.frame)
H.box(im, 0, F - 59, 27, 59, P.sky, P.ink)
H.line(im, 5, F - 20, 18, F - 50, P.sky_l)
H.dolly(im, 32, F, 3)

-- wet floor
H.puddle(im, 126, F, 36)
H.wetsign(im, 160, F)

-- robot vacuum and patrol route
H.vacuum(im, 204, F)
dashed(186, 262, F - 16, P.ink)
H.arrowhead(im, 184, F - 16, -1, 0, P.ink, 3)
H.arrowhead(im, 264, F - 16, 1, 0, P.ink, 3)

-- fountain
H.fountain(im, 270, F)

-- luggage storage: cutaway room with roll-up shutter
local LX, LW = 352, 52
H.rect(im, LX - 3, F - 66, LW + 6, 66, P.frame)
H.rect(im, LX, F - 63, LW, 63, P.ui)
H.rect(im, LX + 4, F - 40, LW - 8, 2, P.base)          -- shelf
H.box(im, LX + 6, F - 52, 12, 12, P.purple, P.ink)      -- suitcase
H.box(im, LX + 22, F - 50, 16, 10, P.xred, P.ink)
for y = F - 63, F - 34, 4 do                            -- shutter half down
  H.rect(im, LX, y, LW, 3, P.concrete)
  H.rect(im, LX, y + 3, LW, 1, P.concrete_d)
end
H.rect(im, LX, F - 31, LW, 2, P.ink)
H.mat(im, LX + 4, F, "none", 40)

-- wall lever linked to the shutter
H.lever(im, 326, 40, false)
dotted(344, 42, 360, 30, P.yellow)
dotted(360, 30, 378, 30, P.yellow)
dotted(378, 30, 378, F - 64, P.yellow)

-- bell desk with mat in front
local DX = 414
H.box(im, DX, F - 30, 66, 30, P.base, P.ink)
H.rect(im, DX - 2, F - 33, 70, 4, P.gold_d)
H.rect(im, DX - 2, F - 33, 70, 1, P.gold)
for x = DX + 6, DX + 60, 16 do H.box(im, x, F - 24, 10, 18, P.base, P.base_d) end
H.ellipse(im, DX + 30, F - 36, 4, 3, P.gold, P.gold_d)  -- service bell
H.rect(im, DX + 29, F - 41, 2, 2, P.gold_d)
H.mat(im, 408, F, "none", 40)

-- player near the start
H.player(im, 72, F, 0, 2)

-- suggested routes: over the puddle and the fountain to the desk mat
H.arc(im, 120, F - 8, 262, F - 2, 36, P.white, 7, 2)
H.arc(im, 262, F - 2, 424, F + 2, 50, P.white, 7, 2)

-- labels
H.tag(im, "LEVEL 02 - LOBBY", 3, 8)
H.tag(im, "2 REQUIRED / 3 AVAILABLE", 3, 21, P.yellow)
H.tag(im, "DOLLY", 34, 36, P.white, P.ui_l)
H.tag(im, "WET FLOOR", 120, 124, P.water_l)
H.tag(im, "VACUUM PATROL", 180, 124, P.white)
H.tag(im, "FOUNTAIN", 232, 44, P.water_l)
H.tag(im, "LEVER", 304, 20, P.white)
H.tag(im, "LUGGAGE STORAGE", 334, 124, P.mat_y)
H.tag(im, "BELL DESK", 418, 60, P.mat_y)
H.save(im, "14_level02_layout", 4)
