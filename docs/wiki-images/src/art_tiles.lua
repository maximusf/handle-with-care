-- Art List tiles: grassy ground, interior floor, concrete wall, roof.
-- Writes art_ground_grassy, art_ground_interior, art_concrete_wall, art_roof
-- cards plus raw 32x32 tiles in ../sprites/.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local tp = A.tp

------------------------------------------------------------------ grass
local GL = H.c("7ed957")
local DL = H.c("a3703f")

local function dirt(t)
  H.rect(t, 0, 0, 32, 32, P.dirt)
  local peb = { { 3, 14 }, { 12, 20 }, { 22, 12 }, { 27, 24 }, { 7, 27 }, { 17, 30 },
    { 30, 17 }, { 15, 9 }, { 1, 21 }, { 24, 4 }, { 9, 2 }, { 19, 17 } }
  for i, p in ipairs(peb) do
    local x, y = p[1], p[2]
    tp(t, x, y, P.dirt_d); tp(t, x + 1, y, P.dirt_d)
    if i % 2 == 0 then tp(t, x, y + 1, P.dirt_d); tp(t, x + 1, y + 1, P.dirt_d) end
    tp(t, x, y - 1, DL)
  end
  local specks = { { 6, 7 }, { 19, 25 }, { 28, 9 }, { 13, 14 }, { 25, 29 }, { 4, 31 }, { 10, 24 }, { 31, 2 } }
  for _, p in ipairs(specks) do tp(t, p[1], p[2], P.dirt_d) end
end

local wave = { 9, 10, 10, 11, 10, 9, 9, 10, 12, 11, 10, 9, 10, 11, 11, 10,
  9, 9, 10, 11, 12, 12, 11, 10, 9, 10, 10, 11, 10, 9, 9, 9 }

local grass = A.tile(function(t)
  dirt(t)
  for x = 0, 31 do
    local b = wave[x + 1]
    tp(t, x, 0, P.ink)
    tp(t, x, 1, GL)
    for y = 2, b - 1 do tp(t, x, y, P.grass) end
    tp(t, x, b, P.grass_d)
    tp(t, x, b + 1, P.dirt_d)
    if x % 3 == 0 then tp(t, x, 2, GL) end
  end
  local ticks = { { 4, 4 }, { 13, 5 }, { 20, 3 }, { 27, 6 }, { 9, 7 }, { 17, 7 }, { 30, 4 } }
  for _, p in ipairs(ticks) do
    tp(t, p[1], p[2], P.grass_d); tp(t, p[1] - 1, p[2] + 1, P.grass_d); tp(t, p[1] + 1, p[2] + 1, P.grass_d)
  end
end)
local dirtfill = A.tile(dirt)

A.tilecard("art_ground_grassy", { grass, dirtfill })
A.raw(grass, "ground_grassy_32")
A.raw(dirtfill, "ground_dirt_32")

------------------------------------------------------------------ interior
local GROUT = H.c("9c9384")
local SL, SLD, SLL = H.c("5b5a6e"), H.c("48475a"), H.c("7a7892")

local floor = A.tile(function(t)
  for qy = 0, 1 do
    for qx = 0, 1 do
      local x0, y0 = qx * 16, qy * 16
      local dark = (qx + qy) % 2 == 1
      local base, hi, lo, vein = P.marble, P.white, P.tile, P.tile_d
      if dark then base, hi, lo, vein = SL, SLL, SLD, SLL end
      H.rect(t, x0, y0, 16, 16, base)
      H.rect(t, x0 + 1, y0 + 1, 14, 1, hi)
      H.rect(t, x0 + 1, y0 + 1, 1, 14, hi)
      H.rect(t, x0 + 1, y0 + 15, 15, 1, lo)
      H.rect(t, x0 + 15, y0 + 1, 1, 15, lo)
      H.rect(t, x0, y0, 16, 1, GROUT)
      H.rect(t, x0, y0, 1, 16, GROUT)
      if dark then
        H.line(t, x0 + 3, y0 + 5, x0 + 7, y0 + 9, vein)
        H.line(t, x0 + 7, y0 + 9, x0 + 12, y0 + 10, vein)
      else
        H.line(t, x0 + 3, y0 + 12, x0 + 8, y0 + 7, vein)
        H.line(t, x0 + 8, y0 + 7, x0 + 12, y0 + 5, vein)
        H.px(t, x0 + 10, y0 + 11, vein)
      end
    end
  end
end)

A.tilecard("art_ground_interior", { floor, floor })
A.raw(floor, "ground_interior_32")

------------------------------------------------------------------ concrete
local MORTAR = H.c("6a6a66")
local wall = A.tile(function(t)
  H.rect(t, 0, 0, 32, 32, P.concrete)
  for r = 0, 3 do
    local y = r * 8
    local off = (r % 2) * 8
    for bx = off, off + 16, 16 do
      for i = 1, 15 do
        tp(t, bx + i, y, P.concrete_l)
        tp(t, bx + i, y + 6, P.concrete_d)
      end
      for j = 0, 6 do tp(t, bx + 15, y + j, P.concrete_d) end
      for j = 0, 7 do tp(t, bx, y + j, MORTAR) end
    end
    for x = 0, 31 do tp(t, x, y + 7, MORTAR) end
  end
  local dk = { { 5, 3 }, { 12, 12 }, { 22, 2 }, { 27, 19 }, { 3, 26 }, { 18, 28 }, { 9, 20 }, { 29, 10 }, { 15, 4 } }
  for _, p in ipairs(dk) do tp(t, p[1], p[2], P.concrete_d) end
  local lt = { { 5, 11 }, { 20, 18 }, { 26, 4 }, { 13, 27 }, { 2, 18 } }
  for _, p in ipairs(lt) do tp(t, p[1], p[2], P.concrete_l) end
end)

A.tilecard("art_concrete_wall", { wall, wall })
A.raw(wall, "concrete_wall_32")

------------------------------------------------------------------ roof
local R0, R1, R2, R3 = H.c("1b1b21"), H.c("2a2a33"), H.c("383843"), H.c("4f4f5d")
local roof = A.tile(function(t)
  for r = 0, 3 do
    local y = r * 8
    local off = (r % 2) * 4
    for x = 0, 31 do
      tp(t, x, y, P.ink)
      tp(t, x, y + 1, R0)
      tp(t, x, y + 2, R1)
      for j = 3, 5 do tp(t, x, y + j, R2) end
      tp(t, x, y + 6, R3)
      tp(t, x, y + 7, R1)
    end
    -- grain: checker dither in the body
    for x = 0, 31 do
      local h = (x * 7 + r * 13) % 11
      if h == 0 then tp(t, x, y + 3, R1) elseif h == 5 then tp(t, x, y + 5, R1) elseif h == 8 then tp(t, x, y + 4, R3) end
    end
    for k = 0, 3 do
      local sx = off + k * 8
      for j = 1, 7 do tp(t, sx, y + j, P.ink) end
      for j = 2, 6 do tp(t, sx + 1, y + j, R1) end
    end
  end
end)

A.tilecard("art_roof", { roof, roof })
A.raw(roof, "roof_32")
