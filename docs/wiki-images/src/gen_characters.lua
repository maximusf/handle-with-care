-- Game-ready character and vehicle sprites: delivery truck, dolly, three hotel
-- guests and the courier's eyebrow (kick power) head frames.
-- Writes .aseprite sources into assets/sprites/{vehicles,guests,player}/ and 4x
-- review sheets into docs/art-review/. The PNG strips and JSON are exported
-- from the .aseprite files by the Aseprite CLI (see the bottom of this file).
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local pc = app.pixelColor
local REVIEW = H.ROOT .. "docs/art-review/"
local TMP = os.getenv("HWC_TMP") -- optional folder for zoomed check crops

------------------------------------------------------------------ helpers
-- Paint a small bitmap from strings; map gives a colour per character.
local function stamp(im, x, y, rows, map)
  for j, r in ipairs(rows) do
    for i = 1, #r do
      local c = map[r:sub(i, i)]
      if c then H.px(im, x + i - 1, y + j - 1, c) end
    end
  end
end

-- Draw flat fills on a scratch layer, then wrap them in a 1px ink outline.
local function part(w, h, fn)
  local t = H.img(w, h)
  fn(t)
  A.outline(t, P.ink, false)
  return t
end

local function over(im, src) H.blit(im, src, 0, 0) end

local function opaque(im, x, y)
  return x >= 0 and y >= 0 and x < im.width and y < im.height and pc.rgbaA(im:getPixel(x, y)) > 0
end

-- frames: list of Images. tags: { name, from, to } (1-based). durs: ms per frame.
local function saveAnim(rel, frames, tags, durs)
  local spr = Sprite(frames[1].width, frames[1].height, ColorMode.RGB)
  spr.layers[1].name = "Art"
  spr.cels[1].image = frames[1]
  for i = 2, #frames do
    spr:newEmptyFrame(i)
    spr:newCel(spr.layers[1], i, frames[i], Point(0, 0))
  end
  for i, f in ipairs(spr.frames) do f.duration = (durs[i] or durs[1]) / 1000 end
  for _, t in ipairs(tags) do
    local tag = spr:newTag(t[2], t[3])
    tag.name = t[1]
  end
  spr:saveAs(H.SPR .. rel .. ".aseprite")
  if #frames == 1 then spr:saveCopyAs(H.SPR .. rel .. ".png") end
  spr:close()
  print("saved " .. rel .. " " .. #frames .. " x " .. frames[1].width .. "x" .. frames[1].height)
end

local function saveScaled(im, path, s)
  local big = H.img(im.width * s, im.height * s)
  for y = 0, im.height - 1 do
    for x = 0, im.width - 1 do
      local p = im:getPixel(x, y)
      if pc.rgbaA(p) > 0 then big:clear(Rectangle(x * s, y * s, s, s), p) end
    end
  end
  big:saveAs(path)
  print("saved " .. path .. " " .. big.width .. "x" .. big.height)
end

local function crop(im, x, y, w, h)
  local t = H.img(w, h)
  for j = 0, h - 1 do for i = 0, w - 1 do t:drawPixel(i, j, im:getPixel(x + i, y + j)) end end
  return t
end

------------------------------------------------------------------ delivery truck
local function wheel(im, cx, cy, r)
  H.ellipse(im, cx, cy, r, r, P.asphalt, P.ink)
  H.ellipse(im, cx, cy, r - 2, r - 2, P.asphalt_d, P.asphalt_d)
  H.ellipse(im, cx, cy, r - 5, r - 5, P.concrete_l, P.ink)
  H.ellipse(im, cx, cy, 2, 2, P.gray, P.gray)
  for _, d in ipairs({ { 0, -4 }, { 4, 0 }, { 0, 4 }, { -4, 0 } }) do H.px(im, cx + d[1], cy + d[2], P.concrete_d) end
  -- tyre glint, upper left
  H.px(im, cx - 6, cy - 7, P.gray); H.px(im, cx - 7, cy - 6, P.gray); H.px(im, cx - 8, cy - 4, P.gray)
end

-- Dark wheel well cut into whatever body is already drawn above the wheel.
local function arch(im, cx, cy, r, ymax)
  for dy = -r, 0 do
    for dx = -r, r do
      local d = dx * dx + dy * dy
      local x, y = cx + dx, cy + dy
      if d <= r * r + r and y <= ymax and opaque(im, x, y) then
        im:drawPixel(x, y, d >= (r - 1) * (r - 1) + r and P.ink or P.ui)
      end
    end
  end
end

local function truck()
  local W, HT = 192, 96
  local im = H.img(W, HT)
  local WY, WR = 84, 11
  local FWX, RWX = 34, 148

  -- chassis rail, fuel tank, rear step, mud flap
  H.box(im, 12, 71, 177, 8, P.asphalt_d, P.ink)
  H.rect(im, 59, 72, 129, 2, P.ink)
  H.box(im, 76, 78, 30, 10, P.gray, P.ink)
  H.rect(im, 77, 79, 28, 1, P.concrete)
  H.rect(im, 77, 86, 28, 1, P.asphalt)
  H.rect(im, 84, 79, 1, 8, P.ink); H.rect(im, 97, 79, 1, 8, P.ink)
  H.box(im, 177, 76, 14, 5, P.gray, P.ink)
  H.rect(im, 178, 77, 12, 1, P.concrete_l)
  H.rect(im, 164, 79, 2, 12, P.ink)

  -- cargo box
  H.box(im, 58, 4, 132, 68, P.white, P.ink)
  H.rect(im, 59, 5, 130, 4, P.concrete_l)
  H.rect(im, 59, 9, 130, 1, P.tile_d)
  for x = 63, 172, 8 do H.px(im, x, 7, P.concrete_d) end
  H.rect(im, 59, 66, 130, 1, P.tile)
  H.rect(im, 59, 67, 130, 4, P.tile_d)
  for x = 63, 172, 8 do H.px(im, x, 69, P.concrete_d) end

  -- rear roll-up door, seen as a slatted strip at the tail end
  H.rect(im, 175, 5, 1, 66, P.ink)
  H.rect(im, 176, 5, 13, 66, P.concrete)
  H.rect(im, 176, 5, 13, 2, P.concrete_l)
  for y = 9, 65, 4 do H.rect(im, 176, y, 13, 1, P.concrete_d) end
  H.rect(im, 176, 66, 13, 5, P.yellow)
  for x = 176, 188, 6 do H.rect(im, x, 66, 3, 5, P.ink) end
  H.rect(im, 176, 65, 13, 1, P.ink)
  H.box(im, 179, 58, 7, 4, P.gray, P.ink)
  H.rect(im, 188, 77, 2, 3, P.xred)

  -- livery
  H.text(im, "NOT", 65, 13, P.ink, { s = 2 })
  H.text(im, "AMAZON", 65, 30, P.ink, { s = 3 })
  for x = 65, 160 do
    local t = (x - 65) / 95
    local y = 55 + math.floor(6 * 4 * t * (1 - t) + 0.5)
    H.rect(im, x, y, 1, 3, P.orange)
  end
  stamp(im, 157, 51, {
    "....oo....",
    "....ooo...",
    "....oooo..",
    ".ooooooooo",
    "oooooooooo",
    "ooooooooo.",
    "....oooo..",
    "....ooo...",
    "....oo....",
  }, { o = P.orange })

  -- roof fairing between cab and box
  over(im, part(W, HT, function(t)
    for y = 12, 29 do
      local xl = 57 - math.floor((y - 12) * 22 / 17 + 0.5)
      H.rect(t, xl, y, 58 - xl, 1, P.white)
      H.rect(t, xl, y, 2, 1, P.concrete_l)
    end
  end))

  -- cab: raked windscreen at the front (left), flat back against the box
  local function nose(y) return y < 52 and 11 + math.floor((52 - y) * 11 / 21 + 0.5) or 11 end
  over(im, part(W, HT, function(t)
    for y = 31, 75 do H.rect(t, nose(y), y, 58 - nose(y), 1, P.white) end
  end))
  H.rect(im, 12, 72, 46, 4, P.tile_d)
  H.rect(im, 12, 63, 46, 2, P.orange)
  -- side window with glint
  over(im, part(W, HT, function(t)
    for y = 36, 51 do H.rect(t, nose(y) + 4, y, 43 - nose(y) - 3, 1, P.sky) end
  end))
  H.line(im, 28, 46, 35, 38, P.sky_l); H.line(im, 31, 47, 37, 40, P.sky_l)
  H.px(im, 40, 38, P.white); H.px(im, 41, 38, P.white); H.px(im, 41, 39, P.white)
  -- door seams and handle
  H.rect(im, 47, 33, 1, 38, P.concrete_d)
  H.rect(im, 22, 54, 1, 9, P.concrete_d); H.rect(im, 22, 65, 1, 4, P.concrete_d)
  H.rect(im, 39, 56, 5, 2, P.ink)
  -- mirror, headlight, indicator, bumper
  H.rect(im, 13, 46, 4, 1, P.ink)
  H.box(im, 10, 41, 4, 9, P.gray, P.ink)
  H.box(im, 10, 55, 5, 7, P.gold, P.ink)
  H.px(im, 12, 57, P.cream); H.px(im, 12, 58, P.cream)
  H.box(im, 6, 69, 13, 8, P.gray, P.ink)
  H.rect(im, 7, 70, 11, 1, P.concrete_l)
  H.rect(im, 7, 75, 11, 1, P.asphalt)

  arch(im, FWX, WY, WR + 3, 78)
  arch(im, RWX, WY, WR + 3, 78)
  wheel(im, FWX, WY, WR)
  wheel(im, RWX, WY, WR)
  return im
end

------------------------------------------------------------------ dolly
-- 40x64: wheel on the bottom edge, 31px toe plate, no packages.
local DOLLY_PKG = { x = 11, y = 29, pitch = 20 } -- where a 32px package sprite sits on the plate
local function dolly(rot)
  local W, HT = 40, 64
  local im = H.img(W, HT)
  -- toe plate
  H.box(im, 9, 60, 31, 3, P.concrete_l, P.ink)
  H.rect(im, 36, 61, 3, 1, P.gray)
  -- upright rail, bent-back handle, axle brace
  over(im, part(W, HT, function(t)
    H.line(t, 9, 44, 5, 56, P.gray, 2)
    H.rect(t, 10, 7, 2, 53, P.gray)
    H.rect(t, 9, 5, 2, 3, P.gray)
    H.rect(t, 7, 4, 3, 2, P.gray)
    H.rect(t, 2, 3, 6, 2, P.orange)
  end))
  H.rect(im, 10, 8, 1, 52, P.concrete_l)
  H.rect(im, 2, 3, 6, 1, P.yellow)
  -- back straps hinting at the frame's cross bars
  for _, y in ipairs({ 20, 36 }) do H.rect(im, 12, y, 2, 3, P.ink); H.px(im, 12, y + 1, P.gray) end
  -- wheel
  local cx, cy = 7, 57
  H.ellipse(im, cx, cy, 6, 6, P.asphalt, P.ink)
  H.ellipse(im, cx, cy, 3, 3, P.concrete_l, P.concrete_l)
  if rot == 0 then
    H.rect(im, cx - 3, cy, 7, 1, P.ink); H.rect(im, cx, cy - 3, 1, 7, P.ink)
    for _, d in ipairs({ { -3, -3 }, { 3, -3 }, { 3, 3 }, { -3, 3 } }) do H.px(im, cx + d[1], cy + d[2], P.gray) end
  else
    H.line(im, cx - 2, cy - 2, cx + 2, cy + 2, P.ink); H.line(im, cx - 2, cy + 2, cx + 2, cy - 2, P.ink)
    for _, d in ipairs({ { 0, -4 }, { 4, 0 }, { 0, 4 }, { -4, 0 } }) do H.px(im, cx + d[1], cy + d[2], P.gray) end
  end
  H.px(im, cx, cy, P.orange)
  return im
end

------------------------------------------------------------------ guests
-- Same build as the courier (round head, ringed eyes, floating mitten hands)
-- but drawn front-on. Feet rest on row 62, the floor boundary is y = 63.
local EYES = {
  open = { "..DDDDDD..", ".DDGGGGDD.", "DDGGGGRGDD", "DGGGGRRRGD", "DGGGGGRGGD", "DDGGGGGGDD", ".DDGGGGDD.", "..DDDDDD.." },
  sleepy = { "..........", "..........", "..........", "##########", "DGGGGGRGGD", "DDGGGGGGDD", ".DDGGGGDD.", "..DDDDDD.." },
  happy = { "..........", "..........", "...####...", "..######..", ".##....##.", ".#......#.", "..........", ".........." },
  shocked = { "..DDDDDD..", ".DCCCCCCD.", "DCCCCCCCCD", "DCCC##CCCD", "DCCC##CCCD", "DCCCCCCCCD", ".DCCCCCCD.", "..DDDDDD.." },
}
local MOUTHS = {
  smile = { "#...#", ".###." },
  flat = { ".###." },
  grin = { "#######", "#rrrrr#", ".#ppp#.", "..###.." },
  gasp = { ".###.", "#rrr#", "#rrr#", ".###." },
}
local TONGUE = H.c("ff8a8e")

local function eyes(im, cx, ey, kind, ring)
  local map = { D = ring, G = P.ink, R = P.white, C = P.white, ["#"] = P.ink }
  stamp(im, cx - 10, ey, EYES[kind], map)
  stamp(im, cx + 1, ey, EYES[kind], map)
end

local function mouth(im, cx, y, kind)
  local rows = MOUTHS[kind]
  stamp(im, cx - #rows[1] // 2, y, rows, { ["#"] = P.ink, r = P.door_d, p = TONGUE })
end

local function hand(im, x, y)
  stamp(im, x - 3, y - 3, { "..###..", ".#WWW#.", "#WWWWW#", "#WWWWW#", "#WWWWW#", ".#WWW#.", "..###.." },
    { ["#"] = P.ink, W = P.white })
end

local function neck(im, cx, y0, y1)
  H.rect(im, cx - 2, y0, 4, y1 - y0 + 1, P.ink)
  H.rect(im, cx - 1, y0, 2, y1 - y0 + 1, P.white)
end

local function blush(im, cx, y, c)
  H.rect(im, cx - 10, y, 2, 1, c); H.rect(im, cx + 9, y, 2, 1, c)
end

-- Round head (25x21 with its outline) plus any hair or hat fills drawn by
-- extra(t), all wrapped in one outline so nothing gets a seam.
local function head(im, cx, hy, skin, extra)
  over(im, part(48, 64, function(t)
    H.ellipse(t, cx, hy, 11, 9, skin)
    if extra then extra(t) end
  end))
end

-- Guest A: spa night. Towel turban, face mask, bathrobe, fluffy slippers.
local MASK, PINK, PINK_D, PINK_L = H.c("b4e6a2"), H.c("ff7fb6"), H.c("d4558c"), H.c("ffc2dd")
local function guest_a(expr)
  local im = H.img(48, 64)
  local cx, hy = 24, 21
  local ey = hy - 5
  for _, x in ipairs({ 15, 25 }) do
    stamp(im, x, 57, { "..####..", ".#LLLL#.", "#ppLLpp#", "#pppppp#", "#dddddd#", "########" },
      { ["#"] = P.ink, p = PINK, L = PINK_L, d = PINK_D })
  end
  neck(im, cx, hy + 8, 35)
  local function hw(y) return 3 + math.floor((y - 34) * 8 / 19 + 0.5) end
  over(im, part(48, 64, function(t)
    for y = 34, 53 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, P.marble) end
  end))
  for y = 36, 53 do H.px(im, cx - hw(y) + 2, y, P.tile_d) end
  H.rect(im, cx - 11, 52, 23, 2, PINK)
  H.line(im, cx - 3, 34, cx, 41, PINK); H.line(im, cx + 3, 34, cx, 41, PINK)
  H.rect(im, cx - hw(43), 43, hw(43) * 2 + 1, 2, PINK_D)
  H.rect(im, cx + 1, 42, 3, 4, PINK)
  H.rect(im, cx + 1, 46, 1, 4, PINK); H.rect(im, cx + 3, 46, 1, 3, PINK)

  head(im, cx, hy, MASK)
  -- towel wrapped into a dome, leaning back a little
  over(im, part(48, 64, function(t)
    H.ellipse(t, cx, hy - 11, 12, 3, P.sky_l)
    H.ellipse(t, cx + 1, hy - 14, 9, 6, P.sky_l)
    H.rect(t, cx + 6, hy - 20, 4, 3, P.sky_l) -- tucked end
  end))
  H.line(im, cx - 10, hy - 10, cx + 4, hy - 19, P.sky)
  H.line(im, cx - 4, hy - 9, cx + 8, hy - 17, P.sky)
  H.line(im, cx + 3, hy - 9, cx + 10, hy - 13, P.sky)
  H.rect(im, cx + 6, hy - 18, 3, 1, P.sky)

  if expr == "idle" then
    eyes(im, cx, ey, "open", PINK)
    mouth(im, cx, hy + 5, "smile")
    hand(im, cx - 14, 47); hand(im, cx + 14, 47)
  elseif expr == "happy" then
    eyes(im, cx, ey, "happy", PINK)
    blush(im, cx, hy + 2, PINK)
    mouth(im, cx, hy + 3, "grin")
    hand(im, cx - 14, 37); hand(im, cx + 14, 37)
  else
    eyes(im, cx, ey, "shocked", PINK)
    mouth(im, cx, hy + 4, "gasp")
    hand(im, cx - 12, hy + 6); hand(im, cx + 12, hy + 6)
  end
  return im
end

-- Guest B: the business traveller. Side parting, moustache, suit and tie.
local SUIT, SUIT_D, HAIR, HAIR_L = H.c("5670bd"), H.c("3a4f92"), H.c("5a3324"), H.c("84523a")
local function guest_b(expr)
  local im = H.img(48, 64)
  local cx = 24
  local hy = expr == "shocked" and 15 or 16
  local ey = hy - 5
  for _, x in ipairs({ 15, 25 }) do
    stamp(im, x, 58, { ".######.", "#kkggkk#", "#kkkkkk#", "#kkkkkk#", "########" },
      { ["#"] = P.ink, k = P.base, g = HAIR_L })
  end
  neck(im, cx, hy + 8, 29)
  over(im, part(48, 64, function(t)
    H.rect(t, cx - 6, 28, 13, 1, SUIT)
    H.rect(t, cx - 8, 29, 17, 1, SUIT)
    H.rect(t, cx - 9, 30, 19, 16, SUIT)
    H.rect(t, cx - 8, 46, 8, 8, SUIT_D); H.rect(t, cx + 1, 46, 8, 8, SUIT_D)
  end))
  H.rect(im, cx - 9, 45, 19, 1, SUIT_D)
  H.rect(im, cx - 8, 31, 1, 14, SUIT_D)
  for y = 28, 37 do
    local w = 3 - (y - 28) // 3
    if w >= 0 then H.rect(im, cx - w, y, w * 2 + 1, 1, P.white) end
  end
  H.line(im, cx - 4, 28, cx - 1, 38, SUIT_D); H.line(im, cx + 4, 28, cx + 1, 38, SUIT_D)
  H.rect(im, cx - 1, 29, 3, 2, P.gold_d)
  H.rect(im, cx, 31, 1, 2, P.gold); H.rect(im, cx - 1, 33, 3, 7, P.gold); H.px(im, cx, 40, P.gold)
  H.rect(im, cx + 1, 34, 1, 6, P.gold_d)
  H.px(im, cx + 2, 42, P.ink); H.px(im, cx + 2, 44, P.ink)
  H.rect(im, cx + 5, 34, 3, 1, P.white)

  -- quiff (or hair standing on end) shares the head outline
  head(im, cx, hy, P.white, function(t)
    if expr == "shocked" then
      for _, x in ipairs({ cx - 7, cx - 3, cx + 1, cx + 5 }) do H.rect(t, x, hy - 13, 2, 5, HAIR) end
    else
      H.ellipse(t, cx - 3, hy - 9, 6, 2, HAIR)
    end
  end)
  -- hair fills the top of the head, parted on his right, with sideburns
  for y = hy - 9, hy - 4 do
    for x = cx - 11, cx + 11 do
      local line = x > cx - 5 and hy - 6 or hy - 7
      if (y <= line or math.abs(x - cx) >= 11) and im:getPixel(x, y) == P.white then im:drawPixel(x, y, HAIR) end
    end
  end
  H.rect(im, cx - 5, hy - 9, 1, 3, HAIR_L)
  H.rect(im, cx - 1, hy - 8, 5, 1, HAIR_L)
  local tash = { ".###.###.", "####.####" }
  local tmap = { ["#"] = HAIR }

  if expr == "idle" then
    eyes(im, cx, ey, "open", P.orange)
    stamp(im, cx - 4, hy + 4, tash, tmap)
    hand(im, cx - 14, 45); hand(im, cx + 14, 45)
  elseif expr == "happy" then
    eyes(im, cx, ey, "happy", P.orange)
    stamp(im, cx - 4, hy + 3, tash, tmap)
    stamp(im, cx - 3, hy + 5, { "#######", "#ppppp#", ".#####." }, { ["#"] = P.ink, p = TONGUE })
    hand(im, cx - 14, 45); hand(im, cx + 15, 30)
    H.rect(im, cx + 14, 25, 3, 3, P.ink); H.rect(im, cx + 15, 26, 1, 2, P.white) -- thumb up
  else
    eyes(im, cx, ey, "shocked", P.orange)
    stamp(im, cx - 4, hy + 4, tash, tmap)
    -- jaw drops through the chin line
    stamp(im, cx - 3, hy + 7, { "#######", "#rrrrr#", "#rrrrr#", "#rpppr#", ".#####." },
      { ["#"] = P.ink, r = P.door_d, p = TONGUE })
    hand(im, cx - 15, 26); hand(im, cx + 15, 26)
  end
  return im
end

-- Guest C: the short one in striped pyjamas, nightcap and bunny slippers.
local PJ, PJ_D, CAPC, CAPC_D = H.c("cdb4f5"), H.c("9a76dc"), P.purple, H.c("5a3496")
local function guest_c(expr)
  local im = H.img(48, 64)
  local cx, hy = 24, 25
  local ey = hy - 5
  for _, x in ipairs({ 15, 25 }) do
    stamp(im, x, 56, { ".##..##.", ".#W##W#.", "#WWWWWW#", "#W#WW#W#", "#WWppWW#", "#WWWWWW#", "########" },
      { ["#"] = P.ink, W = P.white, p = PINK })
  end
  neck(im, cx, hy + 8, 39)
  local hws = { 4, 6, 7, 8 }
  local function hw(y)
    if y >= 53 then return 7 elseif y == 52 then return 8 end
    return hws[y - 37] or 9
  end
  over(im, part(48, 64, function(t)
    for y = 38, 53 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, PJ) end
  end))
  for y = 38, 53 do
    for _, dx in ipairs({ -8, -4, 4, 8 }) do
      if math.abs(dx) <= hw(y) then H.px(im, cx + dx, y, PJ_D) end
    end
  end
  for _, y in ipairs({ 42, 46, 50 }) do H.px(im, cx, y, P.white) end
  H.rect(im, cx - 3, 38, 3, 1, P.white); H.rect(im, cx + 1, 38, 3, 1, P.white)
  H.px(im, cx - 2, 39, P.white); H.px(im, cx + 2, 39, P.white)

  head(im, cx, hy, P.white)
  -- nightcap: fluffy band, cone, tail and pom-pom (the tail whips up when shocked)
  local function edge(y) return math.floor(cx + 3 - 13 * (y - (hy - 18)) / 7 + 0.5) end
  over(im, part(48, 64, function(t)
    for y = hy - 18, hy - 11 do
      local xr = math.floor(cx + 7 + 3 * (y - (hy - 18)) / 7 + 0.5)
      H.rect(t, edge(y), y, xr - edge(y) + 1, 1, CAPC)
    end
    H.rect(t, cx - 11, hy - 10, 23, 3, P.tile)
    if expr == "shocked" then
      H.line(t, cx + 6, hy - 18, cx + 11, hy - 21, CAPC, 3)
      H.ellipse(t, cx + 13, hy - 21, 2, 2, P.white)
    else
      H.line(t, cx + 7, hy - 17, cx + 13, hy - 12, CAPC, 3)
      H.ellipse(t, cx + 14, hy - 9, 2, 2, P.white)
    end
  end))
  for y = hy - 16, hy - 11 do H.px(im, edge(y) + 2, y, CAPC_D) end
  H.rect(im, cx - 11, hy - 8, 23, 1, P.tile_d)

  if expr == "idle" then
    eyes(im, cx, ey, "sleepy", P.green)
    mouth(im, cx, hy + 5, "flat")
    hand(im, cx - 14, 47); hand(im, cx + 14, 47)
  elseif expr == "happy" then
    eyes(im, cx, ey, "happy", P.green)
    blush(im, cx, hy + 2, PINK)
    mouth(im, cx, hy + 3, "grin")
    hand(im, cx - 15, 38); hand(im, cx + 15, 38)
  else
    eyes(im, cx, ey, "shocked", P.green)
    mouth(im, cx, hy + 4, "gasp")
    hand(im, cx - 12, hy + 6); hand(im, cx + 12, hy + 6)
  end
  return im
end

------------------------------------------------------------------ head power frames
-- Eyebrows over the five open-eye aim frames of player_head.png. The eyes
-- slide up under the cap as the head aims up, so each brow is placed from
-- that frame's eye-top row and clipped to the face (rows below the cap).
local DIRS = { "aim_down", "aim_forward_down", "aim_forward", "aim_forward_up", "aim_up" }
local EYE_TOP = { 15, 14, 13, 12, 11 }   -- top row of the blue rings, per source frame
local MOUTH_Y = { 23, 23, 22, 21, 21 }   -- row of the grin's two upright pixels
local ROOM = { 2, 2, 1, 0, 0 }           -- clear face rows usable above both eyes
local EX_L, EX_R = 14, 26                -- left edge of each 10px eye
local FACE_TOP = 11

local function headFrame(src, d, variant)
  local im = crop(src, (d - 1) * 48, 0, 48, 64)
  local ey, my = EYE_TOP[d], MOUTH_Y[d]
  local function put(x, y, c)
    if y >= FACE_TOP and opaque(im, x, y) then im:drawPixel(x, y, c) end
  end

  if variant == "relaxed" then
    -- thin arcs floating above the eyes, or hugging the rings when the cap leaves no room
    local y = ey - ROOM[d]
    for _, ex in ipairs({ EX_L, EX_R }) do
      for i = 2, 7 do put(ex + i, y, P.ink) end
      put(ex + 1, y + 1, P.ink); put(ex + 8, y + 1, P.ink)
    end
  elseif variant == "focused" then
    -- level bars pressed onto the eyes so their tops are cut flat, and a flat mouth
    for _, ex in ipairs({ EX_L, EX_R }) do
      for i = 0, 9 do put(ex + i, ey, P.ink); put(ex + i, ey + 1, P.ink) end
    end
    put(22, my, P.white); put(26, my, P.white)
  else
    -- furrowed: brows slant down to the nose and cut across the eyes
    for _, e in ipairs({ { EX_L, false }, { EX_R, true } }) do
      for i = 0, 9 do
        local k = e[2] and (9 - i) or i -- 0 at the outer end, 9 at the nose
        local c = ey - 1 + k // 2
        local x = e[1] + i
        for y = ey, c - 2 do put(x, y, P.white) end
        put(x, c - 1, P.ink); put(x, c, P.ink)
      end
    end
    -- gritted teeth
    stamp(im, 21, my - 1, { "#######", "#W#W#W#", "#######" }, { ["#"] = P.ink, W = P.white })
    -- sweat drop off the back of the head
    stamp(im, 5, ey - 2, { "..#..", ".#b#.", "#bwb#", "#bbb#", ".###." },
      { ["#"] = P.ink, b = P.water, w = P.water_l })
  end
  return im
end

------------------------------------------------------------------ build + save
local truckIm = truck()
saveAnim("vehicles/delivery_truck", { truckIm }, { { "parked", 1, 1 } }, { 100 })

local dollyF = { dolly(0), dolly(1), dolly(0) }
saveAnim("vehicles/dolly", dollyF, { { "idle", 1, 1 }, { "roll", 2, 3 } }, { 100, 90, 90 })

local EXPR = { "idle", "happy", "shocked" }
local guests = {}
for _, g in ipairs({ { "guest_a", guest_a }, { "guest_b", guest_b }, { "guest_c", guest_c } }) do
  local fr = {}
  for i, e in ipairs(EXPR) do fr[i] = g[2](e) end
  guests[#guests + 1] = fr
  saveAnim("guests/" .. g[1], fr, { { "idle", 1, 1 }, { "happy", 2, 2 }, { "shocked", 3, 3 } }, { 500 })
end

local headSrc = Image { fromFile = H.SPR .. "player/player_head.png" }
local VARS = { "relaxed", "focused", "max" }
local heads, headTags = {}, {}
for d = 1, 5 do
  for _, v in ipairs(VARS) do
    heads[#heads + 1] = headFrame(headSrc, d, v)
    headTags[#headTags + 1] = { DIRS[d] .. "_" .. v, #heads, #heads }
  end
end
saveAnim("player/player_head_power", heads, headTags, { 100 })

------------------------------------------------------------------ review sheets
local body = Image { fromFile = H.SPR .. "player/player_body.png" }
local pkg = Image { fromFile = H.SPR .. "package/package_intact.png" }
local tiles = Image { fromFile = H.ROOT .. "assets/tilesets/hotel_tileset.png" }

-- Courier with feet on the floor boundary row floorY.
local function courier(im, x, floorY, head)
  H.blit(im, body, x, floorY - 63, 0, 0, 48, 64)
  H.blit(im, head or headSrc, x, floorY - 63, head and 0 or 96, 0, 48, 64)
end

local PW, PH = 716, 232
local pv = H.img(PW, PH, P.sky)
local G1 = 104
H.rect(pv, 0, G1, PW, 8, P.asphalt)
H.rect(pv, 0, G1, PW, 1, P.ink)
H.blit(pv, truckIm, 8, G1 - 96)
local dx = 214
H.blit(pv, dollyF[1], dx, G1 - 64)
H.blit(pv, pkg, dx + DOLLY_PKG.x, G1 - 64 + DOLLY_PKG.y)
H.blit(pv, pkg, dx + DOLLY_PKG.x, G1 - 64 + DOLLY_PKG.y - DOLLY_PKG.pitch)
courier(pv, 262, G1)
for i = 1, 3 do H.blit(pv, dollyF[i], 330 + (i - 1) * 48, G1 - 64) end
H.text(pv, "DOLLY IDLE / ROLL", 330, G1 - 76, P.ink)

local G2 = 220
H.rect(pv, 0, 112, PW, G2 - 112, P.wall)
H.rect(pv, 0, G2, PW, PH - G2, P.carpet)
H.rect(pv, 0, G2, PW, 1, P.carpet_l)
for gi, fr in ipairs(guests) do
  local x0 = 6 + (gi - 1) * 236
  courier(pv, x0, G2)
  for i = 1, 3 do
    local cx = x0 + 44 + (i - 1) * 64
    H.blit(pv, tiles, cx, G2 - 96, 64, 64, 64, 96)
    H.blit(pv, fr[i], cx + 8, G2 - 63)
  end
end
saveScaled(pv, REVIEW .. "characters_preview.png", 4)

local hp = H.img(46 + 5 * 48, 12 + 3 * 64, P.wall)
local short = { "DOWN", "FWD-DN", "FWD", "FWD-UP", "UP" }
for d = 1, 5 do H.text(hp, short[d], 46 + (d - 1) * 48 + 24, 3, P.base_d, { align = "center" }) end
for v = 1, 3 do
  H.text(hp, VARS[v], 2, 12 + (v - 1) * 64 + 16, P.base_d)
  H.rect(hp, 46, 12 + v * 64 - 1, 240, 1, P.wall_d)
  for d = 1, 5 do
    courier(hp, 46 + (d - 1) * 48, 12 + v * 64 - 1, heads[(d - 1) * 3 + v])
  end
end
saveScaled(hp, REVIEW .. "head_power_preview.png", 4)

-- Zoomed crops for checking faces (only written when HWC_TMP is set).
if TMP then
  local z = H.img(5 * 30, 3 * 30, P.wall)
  for d = 1, 5 do
    for v = 1, 3 do H.blit(z, heads[(d - 1) * 3 + v], (d - 1) * 30 - 8, (v - 1) * 30, 0, 0, 48, 30) end
  end
  saveScaled(z, TMP .. "zoom_heads.png", 10)
  local gz = H.img(3 * 48, 3 * 64, P.ui_l)
  H.rect(gz, 0, 64, 144, 64, P.wall)
  for gi, fr in ipairs(guests) do
    for i = 1, 3 do H.blit(gz, fr[i], (i - 1) * 48, (gi - 1) * 64) end
  end
  saveScaled(gz, TMP .. "zoom_guests.png", 8)
  local vz = H.img(192 + 3 * 44, 100, P.sky)
  H.blit(vz, truckIm, 0, 2)
  for i = 1, 3 do H.blit(vz, dollyF[i], 196 + (i - 1) * 44, 34) end
  saveScaled(vz, TMP .. "zoom_vehicles.png", 6)
end
