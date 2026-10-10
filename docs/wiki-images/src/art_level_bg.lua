-- Art List: Level Main BG concept. Empty hotel hallway backdrop.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P

local im = H.img(240, 135, P.wall)
local FY = 115
H.hallway(im, FY)

-- crown molding
H.rect(im, 0, 0, 240, 5, P.base)
H.rect(im, 0, 5, 240, 1, P.base_d)
H.rect(im, 0, 6, 240, 2, P.wall_d)
H.rect(im, 0, 1, 240, 1, P.frame)

-- framed painting: little landscape
local function painting(x, y, w, h)
  H.rect(im, x + 2, y + 2, w, h, P.wall_d)
  H.box(im, x, y, w, h, P.gold, P.ink)
  H.rect(im, x + 1, y + 1, w - 2, 1, P.cream)
  H.rect(im, x + 3, y + 3, w - 6, h - 6, P.gold_d)
  local ix, iy, iw, ih = x + 4, y + 4, w - 8, h - 8
  local pic = H.img(iw, ih, P.sky)
  H.rect(pic, 0, 0, iw, ih // 3, P.sky_l)
  H.ellipse(pic, iw - 7, 5, 3, 3, P.yellow, P.yellow)
  H.ellipse(pic, iw // 3, ih + 2, iw // 2, ih // 2, P.grass, P.grass)
  H.ellipse(pic, iw - 4, ih + 3, iw // 2, ih // 2 - 1, P.grass_d, P.grass_d)
  H.blit(im, pic, ix, iy)
end

-- sconce: brass arm, cream shade, soft round glow
local function sconce(x, y)
  for r, a in ipairs({ 0.14, 0.14, 0.16 }) do
    local rad = 22 - r * 5
    for j = -rad, rad do
      for i = -rad, rad do
        if i * i + j * j <= rad * rad then H.blendpx(im, x + 4 + i, y + 10 + j, P.cream, a) end
      end
    end
  end
  H.box(im, x + 2, y + 12, 4, 8, P.gold, P.ink)
  H.rect(im, x + 3, y + 8, 2, 4, P.gold_d)
  for j = 0, 6 do H.rect(im, x + 1 - j // 3, y + 2 + j, 6 + 2 * (j // 3), 1, P.cream) end
  H.rect(im, x + 1, y + 1, 6, 1, P.ink)
  H.rect(im, x - 2, y + 9, 12, 1, P.ink)
  H.rect(im, x + 2, y + 2, 1, 4, P.white)
end

-- potted plant standing on the carpet
local function plant(x)
  local leaves = { { 8, -30, 5, 9 }, { 3, -24, 5, 7 }, { 13, -24, 5, 7 }, { 8, -20, 6, 6 } }
  for _, l in ipairs(leaves) do H.ellipse(im, x + l[1], FY + l[2], l[3], l[4], P.grass, P.ink) end
  H.line(im, x + 8, FY - 34, x + 8, FY - 16, P.grass_d)
  H.line(im, x + 3, FY - 27, x + 6, FY - 20, P.grass_d)
  H.line(im, x + 13, FY - 27, x + 10, FY - 20, P.grass_d)
  H.box(im, x + 1, FY - 14, 15, 14, P.orange, P.ink)
  H.box(im, x, FY - 15, 17, 4, P.card_d, P.ink)
  H.rect(im, x + 2, FY - 10, 1, 9, P.gold)
end

-- console table with a vase of flowers
local function table_(x)
  H.box(im, x, FY - 22, 40, 4, P.frame, P.ink)
  H.rect(im, x + 1, FY - 21, 38, 1, P.base)
  H.box(im, x + 3, FY - 19, 3, 19, P.frame, P.ink)
  H.box(im, x + 34, FY - 19, 3, 19, P.frame, P.ink)
  H.rect(im, x + 6, FY - 9, 28, 2, P.ink)
  H.box(im, x + 16, FY - 32, 8, 10, P.blue, P.ink)
  H.rect(im, x + 17, FY - 31, 1, 7, P.sky_l)
  local fl = { { 18, -38, P.red }, { 22, -40, P.yellow }, { 14, -36, P.white }, { 25, -35, P.red } }
  for _, f in ipairs(fl) do
    H.line(im, x + 20, FY - 32, x + f[1], FY + f[2], P.grass_d)
  end
  for _, f in ipairs(fl) do H.ellipse(im, x + f[1], FY + f[2], 1, 1, f[3], P.ink) end
end

H.window(im, 28, 18)
H.window(im, 178, 18)
painting(96, 20, 48, 34)
painting(79, 30, 14, 18)
painting(148, 30, 14, 18)
sconce(14, 26)
sconce(68, 26)
sconce(168, 26)
sconce(218, 26)
table_(100)
plant(6)
plant(217)

-- carpet runner border
H.rect(im, 0, FY + 4, 240, 1, P.gold_d)
H.rect(im, 0, 131, 240, 1, P.gold_d)

H.save(im, "art_level_bg", 8)
