-- Hazard and prop sprites: wet floor sign, robot vacuum, cactus, fountain,
-- housekeeping cart, front desk and the luggage storage door.
-- Writes assets/sprites/props/<name>.aseprite (tagged frames, layer "Art"), a
-- <name>.png for the single-frame props, and docs/art-review/props_preview.png.
-- Strips and JSON for the animated props come from a second CLI call each:
--   Aseprite -b <name>.aseprite --sheet <name>.png --sheet-type horizontal
--     --data <name>.json --format json-array --list-tags
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local OUT = H.ROOT .. "assets/sprites/props/"
local REVIEW = H.ROOT .. "docs/art-review/"
app.fs.makeAllDirectories(OUT)
app.fs.makeAllDirectories(REVIEW)

-- extra shades
local WOOD_L = H.c("84523a")
local ORANGE_D, ORANGE_L = H.c("c46a14"), H.c("ffad55")
local GREEN_L = H.c("78d058")
local PURPLE_D, PURPLE_L = H.c("5a3494"), H.c("9c74de")
local DARK, SHELF = H.c("1c120c"), H.c("3a2217")
local D_RED, D_BLUE, D_TAN, D_GRN = H.c("5e1a1e"), H.c("1f4a6e"), H.c("6b4a25"), H.c("1f5a2a")

local function ink(t) A.outline(t, P.ink, false) end

-- frames: list of images. tags: { { name, from, to }, ... }. dur: seconds or list.
local function save(name, frames, tags, dur)
  local w, h = frames[1].width, frames[1].height
  local spr = Sprite(w, h, ColorMode.RGB)
  spr.layers[1].name = "Art"
  for i, im in ipairs(frames) do
    if i > 1 then spr:newEmptyFrame() end
    spr:newCel(spr.layers[1], spr.frames[i], im, Point(0, 0))
    spr.frames[i].duration = type(dur) == "table" and dur[i] or dur
  end
  for _, tg in ipairs(tags) do
    local tag = spr:newTag(tg[2], tg[3])
    tag.name = tg[1]
  end
  spr:saveAs(OUT .. name .. ".aseprite")
  if #frames == 1 then spr:saveCopyAs(OUT .. name .. ".png") end
  spr:close()
  print("saved " .. name .. " " .. w .. "x" .. h .. " x" .. #frames)
end

------------------------------------------------------------------ wet floor sign (24x32)
local function wet_sign()
  local t = H.img(24, 32)
  local function half(y) return 3 + (y - 3) * 6 // 24 end
  -- back leaf of the A-frame, peeking out to the right
  for y = 4, 27 do H.rect(t, 14 - half(y), y, half(y) * 2, 1, P.mat_yd) end
  H.rect(t, 20, 28, 3, 3, P.mat_yd)
  -- front leaf
  for y = 3, 27 do H.rect(t, 11 - half(y), y, half(y) * 2, 1, P.yellow) end
  for y = 3, 27 do H.px(t, 11 - half(y), y, P.cream) end
  H.rect(t, 2, 28, 4, 3, P.yellow)
  H.rect(t, 16, 28, 4, 3, P.yellow)
  H.rect(t, 2, 30, 4, 1, P.mat_yd)
  H.rect(t, 16, 30, 4, 1, P.mat_yd)
  H.rect(t, 10, 5, 2, 2, P.ink) -- carry slot
  -- exclamation mark and caution stripe
  H.rect(t, 10, 9, 2, 8, P.ink)
  H.rect(t, 10, 18, 2, 2, P.ink)
  H.rect(t, 11 - half(23), 22, half(23) * 2, 3, P.orange)
  H.px(t, 11 - half(23), 22, P.orange)
  ink(t)
  return t
end

------------------------------------------------------------------ robot vacuum (32x16)
local function vacuum(f)
  local t = H.img(32, 16)
  -- wheels and side brush sit under the shell
  for _, x in ipairs({ 7, 20 }) do
    H.rect(t, x, 13, 4, 2, P.asphalt)
    H.px(t, x + 1 + f, 13 + f, P.concrete_l)
  end
  if f == 0 then
    H.rect(t, 26, 13, 4, 1, P.yellow)
    H.px(t, 30, 14, P.yellow)
  else
    H.rect(t, 26, 13, 2, 2, P.yellow)
    H.px(t, 28, 14, P.yellow)
  end
  -- shell: light dome over a dark bumper band
  H.rect(t, 7, 6, 18, 1, P.white)
  H.rect(t, 4, 7, 24, 1, P.concrete_l)
  H.rect(t, 3, 8, 26, 1, P.concrete_l)
  H.rect(t, 9, 7, 8, 1, P.white)
  H.rect(t, 2, 9, 28, 4, P.gray)
  H.rect(t, 2, 9, 28, 1, P.concrete_d)
  H.rect(t, 2, 12, 28, 1, P.mat_nd)
  H.rect(t, 23, 10, 7, 2, P.asphalt) -- front bumper
  -- sensor turret with the blinking light
  H.rect(t, 13, 4, 6, 2, P.asphalt)
  H.rect(t, 14, 3, 4, 1, f == 0 and P.blue or P.water_d)
  if f == 0 then H.px(t, 15, 3, P.white) end
  H.rect(t, 5, 10, 2, 1, f == 0 and P.mat_g or P.mat_gd) -- status LED
  H.rect(t, 9, 10, 10, 1, P.mat_nd) -- vent slot
  ink(t)
  return t
end

------------------------------------------------------------------ cactus (24x40)
local function cactus()
  local t = H.img(24, 40)
  -- pot
  H.rect(t, 4, 27, 16, 3, P.orange)
  H.rect(t, 4, 27, 16, 1, ORANGE_L)
  for y = 30, 38 do
    local i = (y - 30) // 4
    H.rect(t, 5 + i, y, 14 - i * 2, 1, P.orange)
    H.rect(t, 16 - i, y, 3, 1, ORANGE_D)
  end
  H.rect(t, 5, 30, 14, 1, ORANGE_D)
  H.rect(t, 17, 28, 3, 2, ORANGE_D)
  H.rect(t, 7, 32, 1, 5, ORANGE_L)
  -- trunk
  H.rect(t, 9, 4, 6, 23, P.grass)
  H.rect(t, 10, 3, 4, 1, P.grass)
  H.rect(t, 14, 5, 1, 22, P.grass_d)
  H.rect(t, 10, 5, 1, 21, GREEN_L)
  H.rect(t, 12, 6, 1, 20, P.grass_d)
  -- left arm
  H.rect(t, 3, 10, 4, 9, P.grass)
  H.rect(t, 4, 9, 2, 1, P.grass)
  H.rect(t, 7, 16, 2, 3, P.grass)
  H.rect(t, 3, 18, 6, 1, P.grass_d)
  H.rect(t, 4, 11, 1, 6, GREEN_L)
  -- right arm
  H.rect(t, 17, 13, 4, 9, P.grass)
  H.rect(t, 18, 12, 2, 1, P.grass)
  H.rect(t, 15, 19, 2, 3, P.grass)
  H.rect(t, 15, 21, 6, 1, P.grass_d)
  H.rect(t, 20, 14, 1, 7, P.grass_d)
  -- spines and a flower
  for y = 7, 23, 4 do H.px(t, 11, y, P.white); H.px(t, 13, y + 2, P.white) end
  H.px(t, 5, 12, P.white); H.px(t, 5, 15, P.white)
  H.px(t, 18, 15, P.white); H.px(t, 18, 18, P.white)
  H.rect(t, 11, 2, 2, 1, P.red)
  H.px(t, 10, 3, P.red); H.px(t, 13, 3, P.red)
  ink(t)
  return t
end

------------------------------------------------------------------ fountain (96x64, 4 frames)
local function fountain(f)
  local t = H.img(96, 64)
  -- plinth and basin wall
  H.rect(t, 4, 59, 88, 4, P.concrete_d)
  H.rect(t, 4, 59, 88, 1, P.concrete)
  H.rect(t, 7, 50, 82, 9, P.concrete)
  for x = 10, 80, 13 do H.box(t, x, 52, 11, 5, P.concrete, P.concrete_d) end
  H.rect(t, 7, 50, 82, 1, P.concrete_d)
  -- back rim, water, front rim
  H.rect(t, 7, 41, 82, 1, P.concrete_d)
  H.rect(t, 7, 42, 82, 4, P.water)
  H.rect(t, 7, 42, 82, 1, P.water_d)
  for i = 0, 8 do
    local x = 7 + (i * 20 + f * 5) % 82
    H.rect(t, x, 43, math.min(4, 89 - x), 1, P.water_l)
    local x2 = 7 + (i * 20 + 10 + (3 - f) * 5) % 82
    H.rect(t, x2, 45, math.min(5, 89 - x2), 1, P.water_l)
  end
  H.rect(t, 5, 46, 86, 4, P.concrete_l)
  H.rect(t, 5, 46, 86, 1, P.marble)
  H.rect(t, 5, 49, 86, 1, P.concrete)
  -- pillar
  H.rect(t, 42, 43, 12, 3, P.concrete)
  H.rect(t, 44, 23, 8, 20, P.concrete_l)
  H.rect(t, 44, 23, 1, 20, P.marble)
  H.rect(t, 50, 23, 2, 20, P.concrete)
  H.rect(t, 44, 24, 8, 1, P.concrete_d)
  H.rect(t, 44, 33, 8, 1, P.concrete)
  -- upper bowl with its own water line
  H.rect(t, 33, 17, 30, 1, P.water)
  for i = 0, 2 do H.rect(t, 34 + (i * 10 + f * 5) % 26, 17, 3, 1, P.water_l) end
  H.rect(t, 31, 18, 34, 2, P.concrete_l)
  H.rect(t, 31, 18, 34, 1, P.marble)
  H.rect(t, 33, 20, 30, 1, P.concrete_l)
  H.rect(t, 36, 21, 24, 1, P.concrete)
  H.rect(t, 40, 22, 16, 1, P.concrete)
  H.rect(t, 43, 23, 10, 1, P.concrete_d)
  -- finial and bubbling jet
  H.rect(t, 46, 11, 4, 6, P.concrete_l)
  H.rect(t, 49, 11, 1, 6, P.concrete)
  H.rect(t, 45, 9, 6, 2, P.concrete_l)
  H.rect(t, 46, 8, 4, 1, P.marble)
  if f % 2 == 0 then
    H.rect(t, 47, 3, 2, 5, P.water_l)
    H.rect(t, 46, 5, 4, 3, P.water)
    H.rect(t, 47, 4, 1, 3, P.white)
  else
    H.rect(t, 47, 4, 2, 4, P.water_l)
    H.rect(t, 45, 6, 6, 2, P.water)
    H.rect(t, 48, 5, 1, 2, P.white)
  end
  ink(t)
  -- falling streams from the bowl lip, drawn over the outline
  for _, s in ipairs({ { 30, -1 }, { 65, 1 } }) do
    local px, py = s[1], 18
    for y = 18, 44 do
      local x = s[1] + s[2] * math.floor(math.sqrt(y - 18) * 2.4 + 0.5)
      local c = ((y - f * 3) % 12 < 4) and P.white or P.water_l
      H.line(t, px, py, x, y, P.water_d)
      H.line(t, px - s[2], py, x - s[2], y, P.water)
      H.line(t, px - s[2] * 2, py, x - s[2] * 2, y, c)
      px, py = x, y
    end
    -- splash where the stream lands
    local lx = px
    if f % 2 == 0 then
      H.rect(t, lx - 3, 43, 7, 1, P.white)
      H.px(t, lx - 4, 40, P.water_l); H.px(t, lx + 4, 39, P.water_l)
    else
      H.rect(t, lx - 4, 44, 9, 1, P.white)
      H.rect(t, lx - 1, 42, 3, 1, P.white)
      H.px(t, lx - 5, 39, P.water_l); H.px(t, lx + 3, 40, P.water_l)
    end
  end
  return t
end

------------------------------------------------------------------ housekeeping cart (64x56, 2 frames)
local function cart(f)
  local t = H.img(64, 56)
  -- casters
  for _, cx in ipairs({ 14, 41 }) do
    H.rect(t, cx - 1, 45, 3, 4, P.mat_nd)
    H.ellipse(t, cx, 51, 3, 3, P.asphalt)
    if f == 0 then
      H.rect(t, cx - 2, 51, 5, 1, P.concrete_l)
      H.rect(t, cx, 49, 1, 5, P.concrete_l)
    else
      for d = -2, 2 do H.px(t, cx + d, 51 + d, P.concrete_l); H.px(t, cx + d, 51 - d, P.concrete_l) end
    end
    H.px(t, cx, 51, P.ink)
  end
  -- body with two open shelves
  H.box(t, 6, 17, 44, 29, P.concrete_l, P.ink)
  H.rect(t, 47, 18, 2, 27, P.concrete)
  H.rect(t, 5, 15, 46, 3, P.concrete)
  H.rect(t, 5, 15, 46, 1, P.marble)
  H.rect(t, 6, 18, 44, 1, P.ink)
  H.box(t, 9, 20, 38, 11, P.concrete_d, P.ink)
  H.box(t, 9, 33, 38, 11, P.concrete_d, P.ink)
  -- upper shelf: folded towels and toilet rolls
  H.rect(t, 11, 23, 12, 7, P.white)
  H.rect(t, 11, 25, 12, 1, P.tile_d); H.rect(t, 11, 28, 12, 1, P.tile_d)
  H.rect(t, 24, 25, 10, 5, P.sky_l)
  H.rect(t, 24, 27, 10, 1, P.sky)
  for _, x in ipairs({ 36, 41 }) do
    H.rect(t, x, 26, 4, 4, P.white)
    H.rect(t, x + 1, 27, 2, 2, P.tile_d)
  end
  -- lower shelf: linens and a supplies box
  H.rect(t, 11, 37, 16, 6, P.white)
  H.rect(t, 11, 39, 16, 1, P.tile_d); H.rect(t, 11, 41, 16, 1, P.tile_d)
  H.rect(t, 30, 36, 14, 7, P.card)
  H.rect(t, 30, 36, 14, 1, P.card_m)
  H.rect(t, 36, 36, 2, 7, P.tape)
  -- on top: towel stack and spray bottles
  H.rect(t, 9, 8, 16, 7, P.white)
  H.rect(t, 9, 10, 16, 1, P.tile_d); H.rect(t, 9, 13, 16, 1, P.tile_d)
  H.px(t, 9, 8, P.none); H.px(t, 24, 8, P.none)
  H.rect(t, 28, 9, 5, 6, P.blue)
  H.rect(t, 28, 9, 1, 6, P.water_l)
  H.rect(t, 29, 7, 2, 2, P.white)
  H.rect(t, 29, 5, 4, 2, P.red)
  H.px(t, 33, 5, P.red)
  H.rect(t, 36, 10, 4, 5, P.mat_g)
  H.rect(t, 39, 10, 1, 5, P.mat_gd)
  H.rect(t, 37, 8, 2, 2, P.white)
  -- push handle with the laundry bag hung under it
  H.rect(t, 50, 12, 3, 3, P.gray)
  H.rect(t, 51, 12, 9, 2, P.gray)
  H.rect(t, 51, 12, 9, 1, P.concrete_l)
  H.rect(t, 59, 10, 3, 6, P.asphalt)
  H.rect(t, 51, 15, 8, 26, P.purple)
  H.rect(t, 52, 41, 6, 1, P.purple)
  H.rect(t, 53, 42, 4, 1, PURPLE_D)
  H.rect(t, 51, 15, 8, 2, PURPLE_L)
  H.rect(t, 57, 17, 2, 24, PURPLE_D)
  H.rect(t, 53, 20, 1, 14, PURPLE_D)
  H.rect(t, 55, 24, 1, 14, PURPLE_L)
  H.rect(t, 50, 15, 1, 28, P.ink)
  ink(t)
  return t
end

------------------------------------------------------------------ front desk (96x48)
local function front_desk()
  local t = H.img(96, 48)
  -- plinth and body
  H.rect(t, 4, 42, 88, 5, P.base_d)
  H.rect(t, 4, 42, 88, 1, P.frame)
  H.rect(t, 5, 17, 86, 25, P.base)
  H.rect(t, 5, 17, 86, 1, P.base_d)
  for _, x in ipairs({ 8, 79 }) do
    H.box(t, x, 20, 9, 19, P.base, P.base_d)
    H.rect(t, x + 1, 21, 7, 1, WOOD_L)
    H.rect(t, x + 3, 27, 3, 5, P.gold_d)
    H.rect(t, x + 4, 26, 1, 7, P.gold)
  end
  H.rect(t, 5, 40, 86, 1, P.gold_d)
  -- nameplate
  H.box(t, 19, 23, 58, 12, P.gold, P.gold_d)
  H.rect(t, 20, 24, 56, 1, P.cream)
  H.text(t, "RECEPTION", 48, 26, P.base_d, { align = "center" })
  H.rect(t, 19, 36, 58, 1, P.base_d)
  -- counter top with gold trim
  H.rect(t, 2, 12, 92, 4, P.base)
  H.rect(t, 2, 12, 92, 1, WOOD_L)
  H.rect(t, 2, 15, 92, 1, P.base_d)
  H.rect(t, 5, 16, 86, 1, P.gold)
  -- guest book and pen pot
  H.rect(t, 10, 9, 16, 3, P.red_d)
  H.rect(t, 11, 10, 15, 1, P.cream)
  H.rect(t, 30, 8, 4, 4, P.asphalt)
  H.rect(t, 31, 4, 1, 4, P.blue)
  H.rect(t, 33, 5, 1, 3, P.white)
  -- service bell
  H.rect(t, 64, 4, 2, 2, P.gold_d)
  H.rect(t, 62, 6, 6, 1, P.gold)
  H.rect(t, 61, 7, 8, 1, P.gold)
  H.rect(t, 60, 8, 10, 2, P.gold)
  H.rect(t, 60, 10, 10, 1, P.gold_d)
  H.rect(t, 67, 7, 2, 3, P.gold_d)
  H.rect(t, 62, 7, 2, 1, P.cream)
  H.px(t, 61, 8, P.cream)
  H.rect(t, 59, 11, 12, 1, P.asphalt)
  ink(t)
  return t
end

------------------------------------------------------------------ luggage door (64x96, 3 frames)
-- Same footprint as the tileset doors: 40px opening in a 46px frame.
local DX, DW, DH = 12, 40, 78
local DY = 96 - DH

local function suitcase(im, x, bottom, w, h, col)
  local y = bottom - h + 1
  H.rect(im, x, y, w, h, col)
  H.rect(im, x + w // 2 - 2, y - 2, 4, 1, col)
  H.px(im, x + w // 2 - 2, y - 1, col); H.px(im, x + w // 2 + 1, y - 1, col)
  H.rect(im, x + 2, y, 1, h, DARK)
  H.rect(im, x + w - 3, y, 1, h, DARK)
end

local slab = H.img(DW, DH)
H.box(slab, 0, 0, DW, DH, P.card_m, P.ink)
for x = 10, 30, 10 do H.rect(slab, x, 5, 1, DH - 18, P.card_d) end
H.rect(slab, 1, 5, DW - 2, 4, P.card_d) -- top and middle rails
H.rect(slab, 1, 5, DW - 2, 1, P.card)
H.rect(slab, 1, 36, DW - 2, 4, P.card_d)
H.rect(slab, 1, 36, DW - 2, 1, P.card)
H.box(slab, 12, 13, 16, 17, P.tape, P.ink) -- luggage pictogram plate
H.rect(slab, 15, 20, 10, 7, P.ink)
H.rect(slab, 18, 17, 4, 1, P.ink)
H.px(slab, 18, 18, P.ink); H.px(slab, 18, 19, P.ink)
H.px(slab, 21, 18, P.ink); H.px(slab, 21, 19, P.ink)
H.rect(slab, 17, 21, 1, 5, P.tape); H.rect(slab, 22, 21, 1, 5, P.tape)
H.box(slab, 3, 43, 4, 16, P.gold, P.ink) -- pull handle on the leading edge
H.rect(slab, 5, 44, 1, 14, P.gold_d)
H.rect(slab, 0, DH - 14, DW, 1, P.ink) -- brass kick plate
H.rect(slab, 1, DH - 13, DW - 2, 12, P.gold_d)
H.rect(slab, 1, DH - 13, DW - 2, 1, P.gold)
for x = 4, DW - 5, 10 do H.px(slab, x, DH - 10, P.gold); H.px(slab, x, DH - 4, P.gold) end

-- off = how far the slab has slid right into the wall pocket.
local function luggage_door(off)
  local im = H.img(64, 96)
  H.rect(im, DX - 3, DY - 3, DW + 6, DH + 3, P.frame)
  -- the luggage room behind
  H.rect(im, DX, DY, DW, DH, DARK)
  H.rect(im, DX, DY + 30, DW, 2, SHELF)
  H.rect(im, DX, DY + 54, DW, 2, SHELF)
  suitcase(im, DX + 3, DY + 29, 14, 12, D_BLUE)
  suitcase(im, DX + 20, DY + 29, 16, 9, D_TAN)
  suitcase(im, DX + 6, DY + 53, 18, 13, D_RED)
  suitcase(im, DX + 27, DY + 53, 10, 16, D_GRN)
  suitcase(im, DX + 2, DY + 77, 16, 14, D_TAN)
  suitcase(im, DX + 21, DY + 77, 15, 18, D_BLUE)
  if off < DW then H.blit(im, slab, DX + off, DY, 0, 0, DW - off, DH) end
  -- overhead track and sign plate
  H.box(im, DX, DY, DW, 4, P.mat_n, P.ink)
  H.rect(im, DX + 1, DY + 1, DW - 2, 1, P.concrete_l)
  H.box(im, 8, 2, 48, 11, P.gold, P.ink)
  H.rect(im, 9, 11, 46, 1, P.gold_d)
  H.text(im, "LUGGAGE", 32, 4, P.ink, { align = "center" })
  return im
end

------------------------------------------------------------------ build and save
local sign = wet_sign()
local vac = { vacuum(0), vacuum(1) }
local cac = cactus()
local fnt = {}
for f = 0, 3 do fnt[f + 1] = fountain(f) end
local crt = { cart(0), cart(1) }
local desk = front_desk()
local door = { luggage_door(0), luggage_door(20), luggage_door(35) }

save("wet_floor_sign", { sign }, { { "idle", 1, 1 } }, 0.1)
save("robot_vacuum", vac, { { "patrol", 1, 2 } }, 0.25)
save("cactus", { cac }, { { "idle", 1, 1 } }, 0.1)
save("fountain", fnt, { { "flow", 1, 4 } }, 0.12)
save("housekeeping_cart", crt, { { "roll", 1, 2 } }, 0.12)
save("front_desk", { desk }, { { "idle", 1, 1 } }, 0.1)
save("luggage_door", door, { { "closed", 1, 1 }, { "half", 2, 2 }, { "open", 3, 3 } }, 0.1)

------------------------------------------------------------------ review sheet
local tiles = Image { fromFile = H.ROOT .. "assets/tilesets/hotel_tileset.png" }
local player = H.load("player/player_idle.png")
local FLOOR = 96

local function row(items)
  local im = H.img(512, 128)
  for x = 0, 511, 32 do
    H.blit(im, tiles, x, 0, 0, 0, 32, 32)
    H.blit(im, tiles, x, 32, 0, 0, 32, 32)
    H.blit(im, tiles, x, 64, 64, 0, 32, 32)
    H.blit(im, tiles, x, 96, 96, 0, 32, 32)
  end
  local x = 8
  for _, it in ipairs(items) do
    if it == "player" then
      H.blit(im, player, x, FLOOR - 64, 0, 0, 48, 64); x = x + 48 + 8
    elseif it == "package" then
      H.package(im, x, FLOOR, 0); x = x + 32 + 8
    else
      H.blit(im, it, x, FLOOR - it.height); x = x + it.width + 8
    end
  end
  return im
end

local rows = {
  row({ "player", "package", sign, vac[1], vac[2], cac, crt[1], crt[2], desk }),
  row({ "player", fnt[1], fnt[2], fnt[3], fnt[4] }),
  row({ door[1], door[2], door[3], "player", "package", cac, sign, vac[1] }),
}
local S = 4
local big = H.img(512 * S, 128 * #rows * S)
for i, r in ipairs(rows) do H.blit(big, r, 0, (i - 1) * 128 * S, 0, 0, 512, 128, false, S) end
big:saveAs(REVIEW .. "props_preview.png")
print("saved props_preview " .. big.width .. "x" .. big.height)
