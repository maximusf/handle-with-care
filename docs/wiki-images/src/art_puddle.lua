-- Art List: puddle hazard, 4-frame swirl (48x12 per frame).
-- Writes the art_puddle card, art_puddle.gif, and sprites/puddle_48x12 (4 frames).
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local pc = app.pixelColor

local function inside(x, y)
  local function e(cx, cy, rx, ry) return ((x + 0.5 - cx) / rx) ^ 2 + ((y + 0.5 - cy) / ry) ^ 2 <= 1 end
  return e(14, 6.2, 13, 5) or e(34, 6.8, 13.5, 4.8) or e(24, 7, 12, 4.9)
end

local function frame(f)
  local t = H.img(48, 12)
  for y = 0, 11 do
    for x = 0, 47 do
      if inside(x, y) then
        local c = P.water
        if not inside(x, y - 1) or not inside(x, y - 2) then c = P.water_d end
        if not inside(x, y + 1) then c = P.water_l end
        t:drawPixel(x, y, c)
      end
    end
  end
  -- swirl: a flattened spiral rotating a quarter turn per frame
  local phase = f * math.pi / 2
  for k = 0, 60 do
    local s = k / 60
    local ang = phase + s * 2.4 * math.pi
    local r = 1.5 + s * 17
    local x = math.floor(24 + math.cos(ang) * r + 0.5)
    local y = math.floor(6.5 + math.sin(ang) * r * 0.24 + 0.5)
    if inside(x, y) and inside(x, y - 1) and inside(x, y + 1) then t:drawPixel(x, y, P.water_l) end
  end
  -- two glints riding the swirl
  for g = 0, 1 do
    local ang = phase + g * math.pi + 0.6
    local x = math.floor(24 + math.cos(ang) * 12 + 0.5)
    local y = math.floor(6.5 + math.sin(ang) * 12 * 0.24 + 0.5)
    if inside(x, y) then t:drawPixel(x, y, P.white) end
  end
  A.outline(t, P.ink, false)
  return t
end

local frames = {}
for f = 0, 3 do frames[f + 1] = frame(f) end

-- the four frames in a bare 2x2 block, no labels
local im = H.img(100, 28)
for i = 1, 4 do
  H.blit(im, frames[i], ((i - 1) % 2) * 52, ((i - 1) // 2) * 16)
end
H.save(im, "art_puddle", 6)

-- raw 4-frame sprite (game-ready) and an upscaled GIF
local function sprite(w, h, draw)
  local spr = Sprite(w, h, ColorMode.RGB)
  for i = 1, 4 do
    if i > 1 then spr:newEmptyFrame() end
    local img = H.img(w, h)
    draw(img, frames[i])
    spr:newCel(spr.layers[1], spr.frames[i], img, Point(0, 0))
    spr.frames[i].duration = 0.15
  end
  return spr
end

local raw = sprite(48, 12, function(img, fr) H.blit(img, fr, 0, 0) end)
raw:saveAs(A.SPRITES .. "puddle_48x12.aseprite")
local sheet = H.img(192, 12)
for i = 1, 4 do H.blit(sheet, frames[i], (i - 1) * 48, 0) end
sheet:saveAs(A.SPRITES .. "puddle_48x12_sheet.png")
raw:close()

local S = 6
local gif = sprite(48 * S, 12 * S, function(img, fr)
  H.blit(img, fr, 0, 0, 0, 0, 48, 12, false, S)
end)
gif:saveCopyAs(H.OUT .. "art_puddle.gif")
gif:close()
print("gif art_puddle " .. 48 * S .. "x" .. 12 * S)
