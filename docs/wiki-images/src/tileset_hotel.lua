-- Hotel tileset: 32px tiles built from the wiki concept art.
-- Writes assets/tilesets/hotel_tileset.{aseprite,png} plus a 3x preview room.
-- Patterns are re-pitched to 16px so every tile repeats on the 32px grid.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local T = 32
local COLS, ROWS = 8, 7
local OUT = H.ROOT .. "assets/tilesets/"
local WOOD_L = H.c("84523a")

local sheet = H.img(COLS * T, ROWS * T)
local function put(im, col, row) H.blit(sheet, im, col * T, row * T) end
local function file(name) return Image { fromFile = A.SPRITES .. name .. ".png" } end

------------------------------------------------------------------ row 0: hotel interior
local function wallpaper(t)
  H.rect(t, 0, 0, T, T, P.wall)
  for x = 0, T - 1, 16 do H.rect(t, x, 0, 8, T, P.wall_l) end
end

local function carpet(t, top)
  H.rect(t, 0, 0, T, T, P.carpet)
  for r = 0, 3 do
    for x = (r % 2) * 8, T - 1, 16 do H.rect(t, x, r * 8 + 3, 3, 1, P.carpet_d) end
  end
  if top then H.rect(t, 0, 0, T, 1, P.carpet_l) end
end

put(A.tile(wallpaper), 0, 0)

put(A.tile(function(t) -- wallpaper with crown molding, for the top row of a room
  wallpaper(t)
  H.rect(t, 0, 0, T, 6, P.base)
  H.rect(t, 0, 0, T, 1, P.base_d)
  H.rect(t, 0, 2, T, 1, WOOD_L)
  H.rect(t, 0, 5, T, 1, P.base_d)
end), 1, 0)

put(A.tile(function(t) -- wainscot panels and baseboard, sits directly on the floor
  H.rect(t, 0, 0, T, 24, P.wall_d)
  for x = 2, T - 1, 16 do H.box(t, x, 3, 12, 18, P.wall_d, P.base, 1) end
  H.rect(t, 0, 24, T, 8, P.base)
  H.rect(t, 0, 24, T, 1, P.base_d)
end), 2, 0)

put(A.tile(function(t) carpet(t, true) end), 3, 0)
put(A.tile(function(t) carpet(t, false) end), 4, 0)

put(A.tile(function(t) -- wood block for ledges, pillars and shelves
  H.rect(t, 0, 0, T, T, P.base)
  for _, y in ipairs({ 0, 16 }) do
    H.rect(t, 0, y, T, 1, WOOD_L)
    H.rect(t, 0, y + 15, T, 1, P.base_d)
  end
  H.rect(t, 10, 1, 1, 14, P.base_d)
  H.rect(t, 24, 17, 1, 14, P.base_d)
end), 5, 0)

put(file("ground_interior_32"), 6, 0)
put(file("concrete_wall_32"), 7, 0)

------------------------------------------------------------------ row 1: exterior and stairs
put(file("ground_grassy_32"), 0, 1)
put(file("ground_dirt_32"), 1, 1)
put(file("roof_32"), 2, 1)

local function asphalt(t, top)
  H.rect(t, 0, 0, T, T, P.asphalt)
  local specks = { { 4, 6 }, { 13, 11 }, { 22, 5 }, { 28, 14 }, { 8, 20 }, { 18, 25 }, { 26, 28 }, { 2, 29 }, { 15, 17 } }
  for _, p in ipairs(specks) do H.rect(t, p[1], p[2], 2, 1, P.asphalt_d) end
  if top then
    H.rect(t, 0, 0, T, 1, P.ink)
    H.rect(t, 0, 1, T, 1, P.gray)
  end
end
put(A.tile(function(t) asphalt(t, true) end), 3, 1)
put(A.tile(function(t) asphalt(t, false) end), 4, 1)

put(A.tile(function(t) -- sidewalk slab
  H.rect(t, 0, 0, T, T, P.concrete)
  H.rect(t, 0, 0, T, 1, P.ink)
  H.rect(t, 0, 1, T, 2, P.concrete_l)
  H.rect(t, T - 1, 1, 1, T - 1, P.concrete_d)
  for _, p in ipairs({ { 6, 9 }, { 19, 14 }, { 11, 24 }, { 25, 27 }, { 3, 18 } }) do
    H.px(t, p[1], p[2], P.concrete_d)
  end
end), 5, 1)

local stair = A.tile(function(t) -- two 16px steps rising to the right
  for i = 0, 1 do
    local x, y = i * 16, 16 - i * 16
    H.rect(t, x, y, 16, T - y, P.concrete)
    H.rect(t, x, y, 16, 1, P.ink)
    H.rect(t, x, y + 1, 16, 2, P.concrete_l)
    H.rect(t, x, y + 1, 1, 15, P.ink)
  end
  H.rect(t, 0, 19, 1, 13, P.concrete_d)
end)
put(stair, 6, 1)
H.blit(sheet, stair, 7 * T, 1 * T, 0, 0, T, T, true)

------------------------------------------------------------------ rows 2-4: doors (2x3 tiles)
local DX, DW, DH = 12, 40, 78
local DY = 96 - DH

local function doorframe(im)
  H.rect(im, DX - 3, DY - 3, DW + 6, DH + 3, P.frame)
  H.box(im, 23, 5, 18, 9, P.gold, P.gold_d) -- blank room number plaque
end

local closed = H.img(64, 96)
doorframe(closed)
H.box(closed, DX, DY, DW, DH, P.door, P.ink)
H.box(closed, DX + 5, DY + 6, DW - 10, 26, P.door, P.door_d)
H.box(closed, DX + 5, DY + 38, DW - 10, 34, P.door, P.door_d)
H.rect(closed, DX + 1, DY + 1, DW - 2, 1, P.door_l)
H.box(closed, DX + DW - 8, DY + 40, 4, 6, P.gold, P.gold_d)
put(closed, 0, 2)

local open = H.img(64, 96)
doorframe(open)
H.rect(open, DX, DY, DW, DH, P.ink)
H.box(open, DX, DY, 8, DH, P.door_d, P.ink)
put(open, 2, 2)

local freight = H.img(64, 96)
H.rect(freight, 4, 15, 56, 81, P.frame)
H.box(freight, 7, 18, 50, 78, P.concrete, P.ink)
for y = 22, 88, 4 do H.rect(freight, 8, y, 48, 1, P.concrete_d) end
H.rect(freight, 8, 90, 48, 5, P.yellow)
for x = 8, 52, 8 do H.rect(freight, x, 90, 4, 5, P.ink) end
H.box(freight, 10, 2, 44, 11, P.yellow, P.ink)
H.text(freight, "FREIGHT", 32, 4, P.ink, { align = "center" })
put(freight, 4, 2)

------------------------------------------------------------------ windows (2x2 tiles)
local function window(broken)
  local im = H.img(64, 64)
  H.box(im, 8, 5, 48, 54, P.sky, P.frame, 3)
  H.line(im, 14, 22, 23, 11, P.sky_l)
  H.line(im, 38, 51, 48, 39, P.sky_l)
  if broken then
    H.line(im, 16, 12, 46, 50, P.white)
    H.line(im, 46, 10, 20, 52, P.white)
    H.line(im, 12, 33, 51, 28, P.white)
  end
  H.rect(im, 30, 8, 4, 48, P.frame)
  H.rect(im, 11, 30, 42, 3, P.frame)
  return im
end
put(window(false), 6, 2)
put(window(true), 6, 4)

------------------------------------------------------------------ row 5: delivery mats (2x1 tiles)
-- Each mat is drawn at the top of its cell so it overlays a carpet top tile.
for i, state in ipairs({ "none", "wait", "done" }) do
  local im = H.img(64, 32)
  H.mat(im, 12, 0, state, 34)
  put(im, (i - 1) * 2, 5)
end

------------------------------------------------------------------ row 6: wall decor
put(A.tile(function(t) -- wall lamp
  H.rect(t, 15, 3, 2, 11, P.gold_d)
  H.box(t, 11, 14, 10, 8, P.cream, P.gold_d)
end), 0, 6)

put(A.tile(function(t) -- loose room number plaque
  H.box(t, 7, 11, 18, 9, P.gold, P.gold_d)
end), 1, 6)

------------------------------------------------------------------ save sheet
local spr = Sprite(sheet.width, sheet.height, ColorMode.RGB)
spr.cels[1].image = sheet
spr.layers[1].name = "Tiles"
spr.gridBounds = Rectangle(0, 0, T, T)
spr:saveAs(OUT .. "hotel_tileset.aseprite")
spr:saveCopyAs(OUT .. "hotel_tileset.png")
spr:close()
print("saved hotel_tileset " .. sheet.width .. "x" .. sheet.height)

------------------------------------------------------------------ preview room
local PW, PH = 13, 6
local pv = H.img(PW * T, PH * T, P.ui)
local function place(col, row, sc, sr, w, h)
  H.blit(pv, sheet, col * T, row * T, sc * T, sr * T, (w or 1) * T, (h or 1) * T)
end
for c = 0, PW - 1 do
  place(c, 0, 1, 0)
  place(c, 1, 0, 0)
  place(c, 2, 0, 0)
  place(c, 3, 2, 0)
  place(c, 4, 3, 0)
  place(c, 5, 4, 0)
end
place(1, 1, 0, 2, 2, 3)  -- closed door
place(1, 4, 2, 5, 2, 1)  -- waiting mat
place(3, 1, 0, 6)        -- lamp
place(4, 1, 2, 2, 2, 3)  -- open door
place(4, 4, 4, 5, 2, 1)  -- delivered mat
place(6, 1, 6, 2, 2, 2)  -- window
place(8, 1, 0, 6)        -- lamp
place(8, 3, 5, 0)        -- wood block
place(9, 2, 6, 1)        -- stair
place(9, 3, 7, 0)        -- concrete under the stair
place(10, 1, 4, 2, 2, 3) -- freight door

local S = 3
local big = H.img(pv.width * S, pv.height * S)
for y = 0, pv.height - 1 do
  for x = 0, pv.width - 1 do
    big:clear(Rectangle(x * S, y * S, S, S), pv:getPixel(x, y))
  end
end
big:saveAs(OUT .. "hotel_tileset_preview.png")
print("saved hotel_tileset_preview " .. big.width .. "x" .. big.height)
