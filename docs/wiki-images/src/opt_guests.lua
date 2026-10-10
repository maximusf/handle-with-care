-- Guest OPTIONS: the three shipped guests redrawn with an 8-frame expression
-- set, plus ten new guests on the same build (round head, ringed eyes,
-- floating mitten hands, front-on, feet on row 62).
-- Writes .aseprite sources into docs/art-options/guests/ and 4x review sheets
-- into docs/art-review/. The PNG strips and JSON are exported from the
-- .aseprite files by the Aseprite CLI:
--   Aseprite.exe -b guest_x.aseprite --sheet guest_x.png --sheet-type horizontal
--     --data guest_x.json --format json-array --list-tags
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local pc = app.pixelColor
local OUT = H.ROOT .. "docs/art-options/guests/"
local REVIEW = H.ROOT .. "docs/art-review/"
local TMP = os.getenv("HWC_TMP") -- optional folder for zoomed check strips

local EXPR = { "idle", "blink", "happy", "laughing", "shocked", "angry", "confused", "sad" }
local BOB = { laughing = -1, shocked = -1, sad = 1 } -- head lift / droop per expression

------------------------------------------------------------------ helpers
local function stamp(im, x, y, rows, map)
  for j, r in ipairs(rows) do
    for i = 1, #r do
      local c = map[r:sub(i, i)]
      if c then H.px(im, x + i - 1, y + j - 1, c) end
    end
  end
end

local function flip(rows)
  local o = {}
  for i, r in ipairs(rows) do o[i] = r:reverse() end
  return o
end

-- Draw flat fills on a scratch layer, then wrap them in a 1px ink outline.
local function part(w, h, fn)
  local t = H.img(w, h)
  fn(t)
  A.outline(t, P.ink, false)
  return t
end

local function over(im, src) H.blit(im, src, 0, 0) end
local function shape(im, fn) over(im, part(48, 64, fn)) end

local function saveAnim(name, frames, tags, dur)
  local spr = Sprite(frames[1].width, frames[1].height, ColorMode.RGB)
  spr.layers[1].name = "Art"
  spr.cels[1].image = frames[1]
  for i = 2, #frames do
    spr:newEmptyFrame(i)
    spr:newCel(spr.layers[1], i, frames[i], Point(0, 0))
  end
  for _, f in ipairs(spr.frames) do f.duration = dur / 1000 end
  for i, t in ipairs(tags) do
    local tag = spr:newTag(i, i)
    tag.name = t
  end
  spr:saveAs(OUT .. name .. ".aseprite")
  spr:close()
  print("saved " .. name .. " " .. #frames .. " x " .. frames[1].width .. "x" .. frames[1].height)
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

------------------------------------------------------------------ face kit
local EYES = {
  open = { "..DDDDDD..", ".DDGGGGDD.", "DDGGGGRGDD", "DGGGGRRRGD", "DGGGGGRGGD", "DDGGGGGGDD", ".DDGGGGDD.", "..DDDDDD.." },
  sleepy = { "..........", "..........", "..........", "##########", "DGGGGGRGGD", "DDGGGGGGDD", ".DDGGGGDD.", "..DDDDDD.." },
  closed = { "..........", "..........", "..........", "..........", "##......##", ".########.", "..........", ".........." },
  happy = { "..........", "..........", "...####...", "..######..", ".##....##.", ".#......#.", "..........", ".........." },
  squint = { "..........", ".##.......", "..###.....", "....####..", "....####..", "..###.....", ".##.......", ".........." },
  shocked = { "..DDDDDD..", ".DCCCCCCD.", "DCCCCCCCCD", "DCCC##CCCD", "DCCC##CCCD", "DCCCCCCCCD", ".DCCCCCCD.", "..DDDDDD.." },
}
local MOUTHS = {
  smile = { 5, { "#...#", ".###." } },
  flat = { 5, { ".###." } },
  grin = { 3, { "#######", "#rrrrr#", ".#ppp#.", "..###.." } },
  laugh = { 3, { "#########", "#WWWWWWW#", "#rrrrrrr#", ".#rpppr#.", "..#####.." } },
  gasp = { 4, { ".###.", "#rrr#", "#rrr#", ".###." } },
  teeth = { 4, { "#######", "#W#W#W#", "#######" } },
  skew = { 5, { ".##...", "#..###" } },
  frown = { 5, { ".###.", "#...#" } },
}
local TONGUE = H.c("ff8a8e")
local PINK, PINK_D, PINK_L = H.c("ff7fb6"), H.c("d4558c"), H.c("ffc2dd")
local GLOOM = H.c("6f7fd6")

local function hand(im, x, y, col)
  stamp(im, x - 3, y - 3, { "..###..", ".#WWW#.", "#WWWWW#", "#WWWWW#", "#WWWWW#", ".#WWW#.", "..###.." },
    { ["#"] = P.ink, W = col or P.white })
end

local function neck(im, cx, y0, y1, col)
  H.rect(im, cx - 2, y0, 4, y1 - y0 + 1, P.ink)
  H.rect(im, cx - 1, y0, 2, y1 - y0 + 1, col or P.white)
end

local function blush(im, cx, y, c)
  H.rect(im, cx - 10, y, 2, 1, c); H.rect(im, cx + 9, y, 2, 1, c)
end

-- Round head (25x21 with its outline) plus any hair or hat fills drawn by
-- extra(t), all wrapped in one outline so nothing gets a seam.
local function head(im, cx, hy, skin, extra, pre)
  shape(im, function(t)
    if pre then pre(t) end
    H.ellipse(t, cx, hy, 11, 9, skin)
    if extra then extra(t) end
  end)
end

-- Repaint the face part of the head over hair drawn behind it. top(dx) is the
-- first skin row for a column.
local function facefill(t, cx, hy, skin, top)
  for y = -9, 9 do
    for x = -11, 11 do
      if x * x / 121.3 + y * y / 81.3 <= 1 and hy + y >= top(x) then H.px(t, cx + x, hy + y, skin) end
    end
  end
end

-- Recolour skin pixels above a hairline. line(dx) is the last hair row.
local function fringe(im, cx, hy, skin, col, line)
  for y = hy - 9, hy + 9 do
    for x = cx - 11, cx + 11 do
      if im:getPixel(x, y) == skin and y <= line(x - cx) then im:drawPixel(x, y, col) end
    end
  end
end

-- Open eye with a slanted lid: angry (brow drops to the nose) or sad (droops outward).
local function cutEye(im, x, y, map, innerRight, mode)
  local rows = EYES.open
  for i = 0, 9 do
    local k = innerRight and i or (9 - i) -- 0 at the outer end, 9 at the nose
    local c = mode == "angry" and (1 + k // 3) or (1 + (9 - k) // 3)
    for j = c + 1, 7 do
      local col = map[rows[j + 1]:sub(i + 1, i + 1)]
      if col then H.px(im, x + i, y + j, col) end
    end
    H.px(im, x + i, y + c, P.ink)
    if mode == "angry" then H.px(im, x + i, y + c - 1, P.ink) end
  end
end

-- o: ring, eyemap, idleEyes, idleMouth, blush, lashes, tash {rows, col}, decor(im, e)
local function face(im, cx, hy, e, o)
  local ey = hy - 5
  local map = o.eyemap or { D = o.ring, G = P.ink, R = P.white, C = P.white, ["#"] = P.ink }
  local lx, rx = cx - 10, cx + 1
  local function both(k) stamp(im, lx, ey, EYES[k], map); stamp(im, rx, ey, EYES[k], map) end
  if e == "idle" then both(o.idleEyes or "open")
  elseif e == "blink" then both("closed")
  elseif e == "happy" then both("happy"); blush(im, cx, hy + 2, o.blush or PINK)
  elseif e == "laughing" then
    stamp(im, lx, ey, EYES.squint, map); stamp(im, rx, ey, flip(EYES.squint), map)
    for _, x in ipairs({ cx - 10, cx + 9 }) do
      H.rect(im, x, hy + 1, 2, 3, P.water); H.px(im, x, hy + 1, P.water_l)
    end
  elseif e == "shocked" then both("shocked")
  elseif e == "angry" then
    cutEye(im, lx, ey, map, true, "angry"); cutEye(im, rx, ey, map, false, "angry")
  elseif e == "confused" then
    stamp(im, lx, ey, EYES.open, map); stamp(im, rx, ey, EYES.sleepy, map)
  else
    cutEye(im, lx, ey, map, true, "sad"); cutEye(im, rx, ey, map, false, "sad")
    stamp(im, cx - 9, hy + 3, { ".b.", "bwb", "bbb", "bbb" }, { b = P.water, w = P.water_l })
  end
  if o.lashes and (e == "idle" or e == "shocked" or e == "confused") then
    H.px(im, lx, ey + 1, P.ink); H.px(im, lx - 1, ey, P.ink)
    if e ~= "confused" then H.px(im, rx + 9, ey + 1, P.ink); H.px(im, rx + 10, ey, P.ink) end
  end
  if o.decor then o.decor(im, e) end

  local kind = ({ idle = o.idleMouth or "smile", blink = o.idleMouth or "smile", happy = "grin", laughing = "laugh",
    shocked = "gasp", angry = "teeth", confused = "skew", sad = "frown" })[e]
  local dy = 0
  if o.tash then
    local up = (e == "happy" or e == "laughing") and 3 or 4
    stamp(im, cx - #o.tash[1][1] // 2, hy + up, o.tash[1], { ["#"] = o.tash[2] })
    dy = 2
    if e == "idle" or e == "blink" then kind = nil end
  end
  if kind then
    local m = MOUTHS[kind]
    stamp(im, cx - #m[2][1] // 2, hy + m[1] + dy, m[2], { ["#"] = P.ink, r = P.door_d, p = TONGUE, W = P.white })
  end
end

-- o: rest (y of hanging hands), dx, hand (colour), pos[e] = { lx, ly, rx, ry } with x relative to cx
local function hands(im, cx, hy, e, o)
  local r, dx = o.rest, o.dx or 14
  local p = (o.pos and o.pos[e]) or ({
    idle = { -dx, r, dx, r }, blink = { -dx, r, dx, r },
    happy = { -dx, r - 10, dx, r - 10 },
    laughing = { -5, r - 3, 5, r - 3 },
    shocked = { -12, hy + 6, 12, hy + 6 },
    angry = { -dx, r - 1, math.min(dx + 1, 16), hy + 10 },
    confused = { -dx, r, 7, hy + 11 },
    sad = { -3, r - 7, 4, r - 7 },
  })[e]
  hand(im, cx + p[1], p[2], o.hand)
  hand(im, cx + p[3], p[4], o.hand)
end

local ACC = {
  happy = { { "..y..", "..y..", "yy.yy", "..y..", "..y.." }, { y = P.yellow } },
  laughing = { { "w....", "w..w.", "..w..", ".....", "ww..." }, { w = P.white } },
  shocked = { { "..b..", ".bbb.", "bbwbb", "bbbwb", ".bbb." }, { b = P.water, w = P.water_l } },
  angry = { { ".r.r.", "rr.rr", ".....", "rr.rr", ".r.r." }, { r = P.xred } },
  confused = { { ".yyy.", "y...y", "....y", "...y.", "..y..", ".....", "..y.." }, { y = P.yellow } },
  sad = { { "b.b.b", "b.b.b", "b.b.b", "b...b", "b...." }, { b = GLOOM } },
}
-- Small outlined mark beside the head. at = { x, y }; laughing also marks the other side.
local function accent(im, e, at, at2)
  local a = ACC[e]
  if not a then return end
  local function put(x, y)
    local rows = (e == "laughing" and x < 24) and flip(a[1]) or a[1]
    shape(im, function(t) stamp(t, x, math.max(1, y), rows, a[2]) end)
  end
  put(at[1], at[2])
  if e == "laughing" and at2 ~= false then
    at2 = at2 or { 48 - at[1] - 5, at[2] }
    put(at2[1], at2[2])
  end
end

local function finish(im, cx, hy, e, o)
  face(im, cx, hy, e, o)
  hands(im, cx, hy, e, o)
  if o.after then o.after(im, e) end
  accent(im, e, o.acc or { cx + 14, hy - 13 }, o.acc2)
end

local SLIPPER = { "..####..", ".#LLLL#.", "#ppLLpp#", "#pppppp#", "#dddddd#", "########" }
local SHOE = { ".######.", "#kkggkk#", "#kkkkkk#", "#kkkkkk#", "########" }
local HAIR, HAIR_L = H.c("5a3324"), H.c("84523a")

------------------------------------------------------------------ A: spa night
local MASK = H.c("b4e6a2")
local function guest_a(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 21 + (BOB[e] or 0)
  for _, x in ipairs({ 15, 25 }) do
    stamp(im, x, 57, SLIPPER, { ["#"] = P.ink, p = PINK, L = PINK_L, d = PINK_D })
  end
  neck(im, cx, hy + 8, 35)
  local function hw(y) return 3 + math.floor((y - 34) * 8 / 19 + 0.5) end
  shape(im, function(t)
    for y = 34, 53 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, P.marble) end
  end)
  for y = 36, 53 do H.px(im, cx - hw(y) + 2, y, P.tile_d) end
  H.rect(im, cx - 11, 52, 23, 2, PINK)
  H.line(im, cx - 3, 34, cx, 41, PINK); H.line(im, cx + 3, 34, cx, 41, PINK)
  H.rect(im, cx - hw(43), 43, hw(43) * 2 + 1, 2, PINK_D)
  H.rect(im, cx + 1, 42, 3, 4, PINK)
  H.rect(im, cx + 1, 46, 1, 4, PINK); H.rect(im, cx + 3, 46, 1, 3, PINK)

  head(im, cx, hy, MASK)
  shape(im, function(t)
    H.ellipse(t, cx, hy - 11, 12, 3, P.sky_l)
    H.ellipse(t, cx + 1, hy - 14, 9, 6, P.sky_l)
    H.rect(t, cx + 6, hy - 20, 4, 3, P.sky_l)
  end)
  H.line(im, cx - 10, hy - 10, cx + 4, hy - 19, P.sky)
  H.line(im, cx - 4, hy - 9, cx + 8, hy - 17, P.sky)
  H.line(im, cx + 3, hy - 9, cx + 10, hy - 13, P.sky)
  H.rect(im, cx + 6, hy - 18, 3, 1, P.sky)
  finish(im, cx, hy, e, { ring = PINK, rest = 47 })
  return im
end

------------------------------------------------------------------ B: business traveller
local SUIT, SUIT_D = H.c("5670bd"), H.c("3a4f92")
local function guest_b(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 16 + (BOB[e] or 0)
  for _, x in ipairs({ 15, 25 }) do stamp(im, x, 58, SHOE, { ["#"] = P.ink, k = P.base, g = HAIR_L }) end
  neck(im, cx, hy + 8, 29)
  shape(im, function(t)
    H.rect(t, cx - 6, 28, 13, 1, SUIT)
    H.rect(t, cx - 8, 29, 17, 1, SUIT)
    H.rect(t, cx - 9, 30, 19, 16, SUIT)
    H.rect(t, cx - 8, 46, 8, 8, SUIT_D); H.rect(t, cx + 1, 46, 8, 8, SUIT_D)
  end)
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
    if e == "shocked" then
      for _, x in ipairs({ cx - 7, cx - 3, cx + 1, cx + 5 }) do H.rect(t, x, hy - 13, 2, 5, HAIR) end
    else
      H.ellipse(t, cx - 3, hy - 9, 6, 2, HAIR)
    end
  end)
  for y = hy - 9, hy - 4 do
    for x = cx - 11, cx + 11 do
      local line = x > cx - 5 and hy - 6 or hy - 7
      if (y <= line or math.abs(x - cx) >= 11) and im:getPixel(x, y) == P.white then im:drawPixel(x, y, HAIR) end
    end
  end
  H.rect(im, cx - 5, hy - 9, 1, 3, HAIR_L)
  H.rect(im, cx - 1, hy - 8, 5, 1, HAIR_L)
  finish(im, cx, hy, e, {
    ring = P.orange, rest = 45, tash = { { ".###.###.", "####.####" }, HAIR },
    pos = { happy = { -14, 45, 15, 30 }, shocked = { -15, hy + 11, 15, hy + 11 } },
    after = function(im2, ex)
      if ex == "happy" then -- thumb up
        H.rect(im2, cx + 14, 25, 3, 3, P.ink); H.rect(im2, cx + 15, 26, 1, 2, P.white)
      end
    end,
  })
  return im
end

------------------------------------------------------------------ C: the sleeper
local PJ, PJ_D, CAPC, CAPC_D = H.c("cdb4f5"), H.c("9a76dc"), P.purple, H.c("5a3496")
local function guest_c(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 25 + (BOB[e] or 0)
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
  shape(im, function(t)
    for y = 38, 53 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, PJ) end
  end)
  for y = 38, 53 do
    for _, dx in ipairs({ -8, -4, 4, 8 }) do
      if math.abs(dx) <= hw(y) then H.px(im, cx + dx, y, PJ_D) end
    end
  end
  for _, y in ipairs({ 42, 46, 50 }) do H.px(im, cx, y, P.white) end
  H.rect(im, cx - 3, 38, 3, 1, P.white); H.rect(im, cx + 1, 38, 3, 1, P.white)
  H.px(im, cx - 2, 39, P.white); H.px(im, cx + 2, 39, P.white)

  head(im, cx, hy, P.white)
  -- nightcap: fluffy band, cone, tail and pom-pom (the tail whips up when startled)
  local up = e == "shocked" or e == "angry"
  local function edge(y) return math.floor(cx + 3 - 13 * (y - (hy - 18)) / 7 + 0.5) end
  shape(im, function(t)
    for y = hy - 18, hy - 11 do
      local xr = math.floor(cx + 7 + 3 * (y - (hy - 18)) / 7 + 0.5)
      H.rect(t, edge(y), y, xr - edge(y) + 1, 1, CAPC)
    end
    H.rect(t, cx - 11, hy - 10, 23, 3, P.tile)
    if up then
      H.line(t, cx + 6, hy - 18, cx + 11, hy - 21, CAPC, 3)
      H.ellipse(t, cx + 13, hy - 21, 2, 2, P.white)
    else
      H.line(t, cx + 7, hy - 17, cx + 13, hy - 12, CAPC, 3)
      H.ellipse(t, cx + 14, hy - 9, 2, 2, P.white)
    end
  end)
  for y = hy - 16, hy - 11 do H.px(im, edge(y) + 2, y, CAPC_D) end
  H.rect(im, cx - 11, hy - 8, 23, 1, P.tile_d)
  finish(im, cx, hy, e, {
    ring = P.green, rest = 47, idleEyes = "sleepy", idleMouth = "flat",
    acc = { 5, hy - 16 }, acc2 = false,
  })
  return im
end

------------------------------------------------------------------ D: gran in curlers
local ROSE, ROSE_D, ROSE_L, GREY, LILAC, LILAC_D = H.c("e86a92"), H.c("b8456c"), H.c("ffb3c7"), H.c("c9c4d6"),
  H.c("b79cf0"), H.c("8a6ad0")
local function guest_d(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 28 + (BOB[e] or 0)
  for _, x in ipairs({ 15, 25 }) do
    stamp(im, x, 57, SLIPPER, { ["#"] = P.ink, p = LILAC, L = P.white, d = LILAC_D })
  end
  neck(im, cx, hy + 8, 41)
  local function hw(y) return 5 + math.floor((y - 40) * 6 / 14 + 0.5) end
  shape(im, function(t)
    for y = 40, 54 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, ROSE) end
  end)
  for y = 41, 54 do H.px(im, cx - hw(y) + 1, y, ROSE_D) end
  H.rect(im, cx - hw(53), 53, hw(53) * 2 + 1, 2, P.white)
  H.line(im, cx - 4, 40, cx, 46, ROSE_L); H.line(im, cx + 4, 40, cx, 46, ROSE_L)
  H.rect(im, cx - hw(47), 47, hw(47) * 2 + 1, 1, ROSE_D)
  for _, f in ipairs({ { -6, 50 }, { 0, 50 }, { 6, 50 }, { -4, 44 }, { 4, 44 } }) do
    local x, y = cx + f[1], f[2]
    H.px(im, x - 1, y, P.white); H.px(im, x + 1, y, P.white); H.px(im, x, y - 1, P.white); H.px(im, x, y + 1, P.white)
    H.px(im, x, y, P.yellow)
  end

  head(im, cx, hy, P.white, function(t)
    H.ellipse(t, cx, hy - 6, 12, 5, GREY)
    facefill(t, cx, hy, P.white, function() return hy - 6 end)
  end)
  H.rect(im, cx - 6, hy - 8, 3, 1, P.white); H.rect(im, cx + 3, hy - 9, 4, 1, P.white)
  shape(im, function(t)
    H.rect(t, cx - 10, hy - 14, 6, 4, PINK); H.rect(t, cx - 3, hy - 15, 6, 4, PINK); H.rect(t, cx + 4, hy - 14, 6, 4, PINK)
  end)
  for _, c in ipairs({ { -10, -14 }, { -3, -15 }, { 4, -14 } }) do
    H.rect(im, cx + c[1], hy + c[2], 6, 1, PINK_L)
    H.rect(im, cx + c[1] + 2, hy + c[2] + 1, 1, 3, PINK_D); H.rect(im, cx + c[1] + 4, hy + c[2] + 1, 1, 3, PINK_D)
  end
  finish(im, cx, hy, e, {
    ring = LILAC, rest = 49, lashes = true,
    decor = function(im2) blush(im2, cx, hy + 3, ROSE_L) end,
  })
  return im
end

------------------------------------------------------------------ E: tourist
local PEACH, STRAW, STRAW_D, ALOHA, ALOHA_D, OLIVE, OLIVE_D, SANDAL =
  H.c("ffc9ae"), H.c("f0d58a"), H.c("c9a851"), H.c("ffb22e"), H.c("d98a12"), H.c("7f8a4a"), H.c("5c6634"), H.c("8a5a36")
local function guest_e(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 21 + (BOB[e] or 0)
  for _, x in ipairs({ 15, 25 }) do
    stamp(im, x, 57, { "..####..", ".#wwww#.", "#wwwwww#", "#sswwss#", "#ssssss#", "########" },
      { ["#"] = P.ink, w = P.white, s = SANDAL })
  end
  shape(im, function(t) H.rect(t, 17, 52, 4, 5, PEACH); H.rect(t, 27, 52, 4, 5, PEACH) end)
  shape(im, function(t)
    H.rect(t, cx - 8, 45, 17, 4, OLIVE); H.rect(t, cx - 8, 49, 8, 3, OLIVE); H.rect(t, cx + 1, 49, 8, 3, OLIVE)
  end)
  H.rect(im, cx - 8, 51, 8, 1, OLIVE_D); H.rect(im, cx + 1, 51, 8, 1, OLIVE_D)
  neck(im, cx, hy + 8, 32, PEACH)
  shape(im, function(t)
    H.rect(t, cx - 9, 31, 19, 15, ALOHA)
    H.rect(t, cx - 12, 31, 3, 6, ALOHA); H.rect(t, cx + 10, 31, 3, 6, ALOHA)
  end)
  H.rect(im, cx - 12, 36, 3, 1, ALOHA_D); H.rect(im, cx + 10, 36, 3, 1, ALOHA_D)
  for y = 31, 34 do
    local w = 2 - (y - 31) // 2
    H.rect(im, cx - w, y, w * 2 + 1, 1, PEACH)
  end
  H.line(im, cx - 4, 31, cx - 1, 36, ALOHA_D); H.line(im, cx + 4, 31, cx + 1, 36, ALOHA_D)
  for _, f in ipairs({ { -7, 34, PINK }, { 7, 40, PINK }, { -6, 42, P.white }, { 6, 33, P.white }, { -3, 44, P.green },
    { 3, 44, PINK }, { 8, 44, P.green }, { -8, 38, P.green } }) do
    H.rect(im, cx + f[1] - 1, f[2], 3, 1, f[3]); H.rect(im, cx + f[1], f[2] - 1, 1, 3, f[3])
  end
  -- camera on a neck strap
  H.line(im, cx - 5, 31, cx - 3, 37, P.base_d); H.line(im, cx + 5, 31, cx + 3, 37, P.base_d)
  H.rect(im, cx - 2, 36, 4, 1, P.ink)
  H.box(im, cx - 5, 37, 11, 7, P.mat_nd, P.ink)
  H.ellipse(im, cx, 40, 2, 2, P.sky, P.ink)
  H.px(im, cx + 1, 39, P.white); H.px(im, cx - 4, 38, P.yellow); H.px(im, cx + 4, 38, P.concrete_l)

  head(im, cx, hy, PEACH)
  shape(im, function(t)
    H.ellipse(t, cx, hy - 8, 15, 2, STRAW)
    H.ellipse(t, cx, hy - 12, 8, 5, STRAW)
  end)
  H.rect(im, cx - 7, hy - 11, 15, 2, P.blue)
  for x = cx - 13, cx + 13, 3 do H.px(im, x, hy - 8, STRAW_D) end
  for x = cx - 5, cx + 5, 3 do H.px(im, x, hy - 14, STRAW_D) end
  finish(im, cx, hy, e, {
    ring = SANDAL, rest = 44, dx = 15, hand = PEACH, blush = H.c("ff6a5a"),
    acc = { 38, 2 },
    decor = function(im2, ex)
      H.rect(im2, cx - 10, hy + 3, 3, 1, H.c("ff8f7a")); H.rect(im2, cx + 8, hy + 3, 3, 1, H.c("ff8f7a"))
      H.rect(im2, cx - 1, hy + 2, 3, 2, P.white) -- sunscreen on the nose
    end,
  })
  return im
end

------------------------------------------------------------------ F: kid in a dinosaur onesie
local DINO, DINO_D, BELLY, SPIKE = H.c("4fc24a"), H.c("2f8f35"), H.c("e2f59a"), P.orange
local function guest_f(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 31 + (BOB[e] or 0)
  for _, x in ipairs({ 14, 26 }) do
    stamp(im, x, 57, { "..####..", ".#gggg#.", "#gggggg#", "#gggggg#", "#w#w#wg#", "########" },
      { ["#"] = P.ink, g = DINO, w = P.white })
  end
  local function hw(y) return 6 + math.floor((y - 41) * 4 / 15 + 0.5) end
  shape(im, function(t)
    for y = 41, 56 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, DINO) end
    H.line(t, cx + 8, 55, cx + 16, 53, DINO, 3)
  end)
  H.ellipse(im, cx, 50, 5, 5, BELLY)
  H.px(im, cx + 12, 52, SPIKE); H.px(im, cx + 15, 51, SPIKE)
  for y = 43, 55 do H.px(im, cx - hw(y) + 1, y, DINO_D) end

  -- hood: a second, bigger ellipse behind the face, with eye bumps and a crest
  head(im, cx, hy, P.white, nil, function(t)
    H.ellipse(t, cx, hy - 1, 14, 12, DINO)
    H.ellipse(t, cx - 8, hy - 11, 3, 3, DINO); H.ellipse(t, cx + 8, hy - 11, 3, 3, DINO)
    H.rect(t, cx - 1, hy - 16, 3, 4, SPIKE)
  end)
  H.ellipse(im, cx, hy, 11, 9, P.white, P.ink)
  for _, s in ipairs({ -1, 1 }) do
    H.rect(im, cx + s * 8 - 1, hy - 12, 2, 2, P.white); H.px(im, cx + s * 8, hy - 11, P.ink)
  end
  for _, dx in ipairs({ -8, -5, -2, 1, 4, 7 }) do
    local top = -math.floor(math.sqrt(math.max(0, (1 - (dx + 0.5) ^ 2 / 121.3) * 81.3)))
    H.rect(im, cx + dx, hy + top - 2, 2, 2, P.white)
  end
  for y = hy - 4, hy + 6 do H.px(im, cx - 13, y, DINO_D) end
  finish(im, cx, hy, e, { ring = H.c("f5b700"), rest = 47, hand = DINO })
  return im
end

------------------------------------------------------------------ G: gym bro
local TAN, TANK, TANK_D, NAVY, BAND = H.c("d99a66"), H.c("1fb7d6"), H.c("1589a3"), H.c("2f3b66"), P.yellow
local function guest_g(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 15 + (BOB[e] or 0)
  for _, x in ipairs({ 15, 25 }) do
    stamp(im, x, 58, { ".######.", "#wwcwww#", "#wwwwww#", "#gggggg#", "########" },
      { ["#"] = P.ink, w = P.white, c = TANK, g = P.concrete_l })
  end
  shape(im, function(t) H.rect(t, 17, 52, 4, 6, TAN); H.rect(t, 27, 52, 4, 6, TAN) end)
  shape(im, function(t)
    H.rect(t, cx - 8, 45, 17, 4, NAVY); H.rect(t, cx - 8, 49, 8, 3, NAVY); H.rect(t, cx + 1, 49, 8, 3, NAVY)
  end)
  H.rect(im, cx - 8, 45, 1, 7, P.white); H.rect(im, cx + 8, 45, 1, 7, P.white)
  local function hw(y)
    if y == 27 then return 11 elseif y == 28 then return 12 elseif y <= 32 then return 13 end
    return 13 - math.floor((y - 32) * 5 / 12 + 0.5)
  end
  shape(im, function(t)
    for y = 27, 44 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, TAN) end
  end)
  for y = 27, 44 do
    if y < 31 then
      H.rect(im, cx - 7, y, 3, 1, TANK); H.rect(im, cx + 5, y, 3, 1, TANK)
    else
      local tw = math.min(hw(y) - 1, 5 + (y - 30), 8)
      H.rect(im, cx - tw, y, tw * 2 + 1, 1, TANK)
    end
  end
  H.rect(im, cx - 6, 35, 5, 1, TANK_D); H.rect(im, cx + 2, 35, 5, 1, TANK_D)
  H.px(im, cx - 12, 33, H.c("b87c4c")); H.px(im, cx + 12, 33, H.c("b87c4c"))
  -- towel round the neck
  shape(im, function(t)
    H.rect(t, cx - 7, 25, 15, 3, P.white)
    H.rect(t, cx - 9, 26, 5, 12, P.white); H.rect(t, cx + 5, 26, 5, 8, P.white)
  end)
  H.rect(im, cx - 9, 35, 5, 1, TANK); H.rect(im, cx + 5, 31, 5, 1, TANK)
  H.rect(im, cx - 9, 37, 5, 1, P.tile_d); H.rect(im, cx + 5, 33, 5, 1, P.tile_d)
  neck(im, cx, hy + 8, 27, TAN)

  head(im, cx, hy, TAN, function(t) H.rect(t, cx - 8, hy - 12, 17, 4, HAIR) end)
  fringe(im, cx, hy, TAN, HAIR, function() return hy - 9 end)
  fringe(im, cx, hy, TAN, BAND, function() return hy - 6 end)
  H.rect(im, cx - 9, hy - 7, 19, 1, P.white)
  H.rect(im, cx - 6, hy - 12, 13, 1, HAIR_L)
  finish(im, cx, hy, e, {
    ring = P.white, rest = 44, dx = 16, hand = TAN,
    pos = { happy = { -16, 27, 16, 27 } }, -- double flex
  })
  return im
end

------------------------------------------------------------------ H: rocker
local MAG, MAG_D, JKT, JKT_L, TEE, JEAN, JEAN_D, STEEL = H.c("e83fb4"), H.c("a8237f"), H.c("7a45c9"), H.c("a67cf0"),
  H.c("2a2a33"), H.c("46608f"), H.c("31466b"), H.c("5d6168")
local function spike(t, bx, by, ax, ay, w, col)
  for y = ay, by do
    local f = (y - ay) / math.max(1, by - ay)
    local c, h = ax + (bx - ax) * f, w * f
    H.rect(t, math.floor(c - h + 0.5), y, math.max(1, math.floor(2 * h + 1.5)), 1, col)
  end
end
local function guest_h(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 20 + (BOB[e] or 0)
  for _, x in ipairs({ 15, 25 }) do
    stamp(im, x, 56, { ".#####..", "#bbbbb#.", "#bsssb#.", "#bbbbb##", "#bbbbbb#", "#gggggg#", "########" },
      { ["#"] = P.ink, b = STEEL, s = P.concrete_l, g = P.mat_n })
  end
  shape(im, function(t)
    H.rect(t, 17, 44, 14, 3, JEAN); H.rect(t, 17, 47, 5, 9, JEAN); H.rect(t, 26, 47, 5, 9, JEAN)
  end)
  H.rect(im, 18, 51, 3, 1, P.white); H.rect(im, 27, 49, 2, 1, P.white); H.rect(im, 17, 47, 1, 9, JEAN_D)
  H.rect(im, 26, 47, 1, 9, JEAN_D)
  neck(im, cx, hy + 8, 30)
  shape(im, function(t)
    H.rect(t, cx - 6, 29, 13, 1, JKT); H.rect(t, cx - 8, 30, 17, 15, JKT)
  end)
  H.rect(im, cx - 2, 30, 5, 15, TEE)
  stamp(im, cx - 1, 33, { "..y", ".yy", "yy.", "yyy", ".yy", "yy.", "y.." }, { y = P.yellow })
  H.line(im, cx - 4, 29, cx - 3, 38, JKT_L); H.line(im, cx + 4, 29, cx + 3, 38, JKT_L)
  for _, x in ipairs({ -7, -5, 5, 7 }) do H.px(im, cx + x, 31, P.white) end
  H.rect(im, cx - 8, 43, 17, 1, P.ink)
  for x = cx - 7, cx + 7, 2 do H.px(im, x, 43, P.concrete_l) end
  H.rect(im, cx - 8, 31, 1, 12, H.c("5a2fa0"))

  head(im, cx, hy, P.white, function(t)
    spike(t, cx - 9, hy - 6, cx - 12, hy - 12, 3, MAG)
    spike(t, cx - 5, hy - 6, cx - 7, hy - 16, 3, MAG)
    spike(t, cx, hy - 6, cx, hy - 18, 3, MAG)
    spike(t, cx + 5, hy - 6, cx + 7, hy - 16, 3, MAG)
    spike(t, cx + 9, hy - 6, cx + 12, hy - 12, 3, MAG)
  end)
  fringe(im, cx, hy, P.white, MAG, function() return hy - 7 end)
  for _, x in ipairs({ -7, -2, 3, 8 }) do H.rect(im, cx + x, hy - 11, 1, 4, MAG_D) end
  finish(im, cx, hy, e, {
    ring = H.c("4b2a7a"), rest = 43, acc = { 39, 1 },
    decor = function(im2)
      H.px(im2, cx - 11, hy + 3, P.concrete_l); H.px(im2, cx - 11, hy + 4, P.concrete_l) -- earring
    end,
  })
  return im
end

------------------------------------------------------------------ I: chef
local WARM, TASH, CHECK = H.c("f6d3b0"), H.c("3a2418"), H.c("6f7f9c")
local function guest_i(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 25 + (BOB[e] or 0)
  for _, x in ipairs({ 15, 25 }) do stamp(im, x, 58, SHOE, { ["#"] = P.ink, k = P.asphalt, g = P.gray }) end
  shape(im, function(t) H.rect(t, cx - 8, 49, 8, 9, P.white); H.rect(t, cx + 1, 49, 8, 9, P.white) end)
  for y = 49, 57 do
    for x = cx - 8, cx + 8 do
      if im:getPixel(x, y) == P.white and ((x // 2 + y // 2) % 2 == 0) then im:drawPixel(x, y, CHECK) end
    end
  end
  neck(im, cx, hy + 8, 35, WARM)
  local function hw(y)
    if y == 34 then return 9 elseif y <= 37 or y >= 47 then return 10 end
    return 11
  end
  shape(im, function(t)
    for y = 34, 48 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, P.white) end
  end)
  for y = 36, 48 do H.px(im, cx - hw(y) + 1, y, P.tile_d) end
  H.rect(im, cx + 6, 36, 1, 13, P.tile_d)
  for _, y in ipairs({ 38, 42, 46 }) do H.rect(im, cx - 3, y, 2, 1, P.ink); H.rect(im, cx + 2, y, 2, 1, P.ink) end
  shape(im, function(t)
    H.rect(t, cx - 5, 33, 11, 2, P.xred); H.rect(t, cx - 1, 35, 3, 2, P.xred)
  end)

  head(im, cx, hy, WARM)
  shape(im, function(t)
    H.rect(t, cx - 9, hy - 13, 19, 6, P.white)
    H.ellipse(t, cx - 6, hy - 17, 5, 4, P.white); H.ellipse(t, cx + 6, hy - 17, 5, 4, P.white)
    H.ellipse(t, cx, hy - 19, 6, 4, P.white)
  end)
  H.rect(im, cx - 9, hy - 9, 19, 1, P.tile_d); H.rect(im, cx - 9, hy - 13, 19, 1, P.tile_d)
  H.rect(im, cx - 4, hy - 19, 1, 5, P.tile_d); H.rect(im, cx + 4, hy - 19, 1, 5, P.tile_d)
  finish(im, cx, hy, e, {
    ring = H.c("1fb5a3"), rest = 48, dx = 15, hand = WARM,
    tash = { { "#.........#", ".####.####." }, TASH },
  })
  return im
end

------------------------------------------------------------------ J: honeymooner
local BROWN, JHAIR, JHAIR_L, ROBE, ROBE_D = H.c("a66a44"), H.c("5c2e1c"), H.c("86482c"), H.c("ffb3c7"), H.c("e0789a")
local HEART = { "h.h", "hhh", ".h." }
local function guest_j(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 21 + (BOB[e] or 0)
  for _, x in ipairs({ 15, 25 }) do
    stamp(im, x, 57, { "..####..", ".#wwww#.", "#wrwrww#", "#wwrwww#", "#tttttt#", "########" },
      { ["#"] = P.ink, w = P.white, r = P.xred, t = P.tile_d })
  end
  neck(im, cx, hy + 8, 35, BROWN)
  local function hw(y) return math.min(10, 5 + (y - 34) // 3) end
  shape(im, function(t)
    for y = 34, 54 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, ROBE) end
  end)
  for y = 36, 54 do H.px(im, cx - hw(y) + 1, y, ROBE_D) end
  H.rect(im, cx - hw(53), 53, hw(53) * 2 + 1, 2, P.white)
  H.line(im, cx - 4, 34, cx, 42, P.white, 2); H.line(im, cx + 4, 34, cx + 1, 42, P.white, 2)
  H.rect(im, cx - hw(44), 44, hw(44) * 2 + 1, 2, ROBE_D)
  H.rect(im, cx - 3, 43, 2, 4, ROBE_D); H.rect(im, cx + 1, 43, 2, 4, ROBE_D)
  for _, h in ipairs({ { -7, 48 }, { 3, 48 }, { -2, 50 }, { 7, 50 }, { -6, 39 }, { 4, 39 } }) do
    stamp(im, cx + h[1] - 1, h[2] - 1, HEART, { h = P.xred })
  end

  head(im, cx, hy, BROWN, function(t)
    H.ellipse(t, cx, hy - 3, 13, 10, JHAIR)
    H.rect(t, cx - 13, hy - 2, 4, 15, JHAIR); H.rect(t, cx + 10, hy - 2, 4, 15, JHAIR)
    facefill(t, cx, hy, BROWN, function(dx) return hy - 7 + math.abs(dx) // 4 end)
  end)
  H.line(im, cx - 9, hy - 8, cx - 4, hy - 11, JHAIR_L); H.line(im, cx + 3, hy - 11, cx + 9, hy - 7, JHAIR_L)
  H.rect(im, cx - 12, hy + 2, 1, 9, JHAIR_L); H.rect(im, cx + 12, hy + 2, 1, 9, JHAIR_L)
  shape(im, function(t) stamp(t, cx + 5, hy - 12, { "h.h", "hhh", "hhh", ".h." }, { h = P.xred }) end)
  finish(im, cx, hy, e, { ring = PINK_L, rest = 47, hand = BROWN, lashes = true, blush = H.c("e8323a") })
  return im
end

------------------------------------------------------------------ K: gamer
local HOODIE, HOODIE_D, JOG, JOG_D, HS, LIME = P.orange, H.c("c2670f"), H.c("8a8f96"), H.c("5d6168"), H.c("4b4d52"),
  H.c("9dff3a")
local function guest_k(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 23 + (BOB[e] or 0)
  for _, x in ipairs({ 15, 25 }) do
    stamp(im, x, 58, { ".######.", "#wwwwww#", "#llllll#", "#wwwwww#", "########" },
      { ["#"] = P.ink, w = P.white, l = LIME })
  end
  shape(im, function(t) H.rect(t, cx - 8, 50, 8, 8, JOG); H.rect(t, cx + 1, 50, 8, 8, JOG) end)
  H.rect(im, cx - 8, 57, 8, 1, JOG_D); H.rect(im, cx + 1, 57, 8, 1, JOG_D)
  local function hw(y) return (y <= 34 or y >= 49) and 9 or 10 end
  shape(im, function(t)
    H.ellipse(t, cx, 33, 10, 3, HOODIE)
    for y = 33, 50 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, HOODIE) end
  end)
  H.rect(im, cx - 9, 49, 19, 1, HOODIE_D)
  for y = 43, 47 do
    local w = 4 + (y - 43) // 2
    H.rect(im, cx - w, y, w * 2 + 1, 1, HOODIE_D)
  end
  H.rect(im, cx - 2, 36, 1, 5, P.white); H.rect(im, cx + 2, 36, 1, 4, P.white)
  H.rect(im, cx - 7, 31, 15, 1, HOODIE_D)
  neck(im, cx, hy + 8, 34)

  head(im, cx, hy, P.white, function(t)
    H.rect(t, cx - 7, hy - 11, 3, 3, HAIR); H.rect(t, cx - 2, hy - 12, 4, 3, HAIR); H.rect(t, cx + 4, hy - 11, 3, 3, HAIR)
  end)
  fringe(im, cx, hy, P.white, HAIR, function(dx) return hy - 7 + ((dx % 3 == 0) and 1 or 0) end)
  -- headset: band, ear cups, boom mic
  shape(im, function(t)
    H.ellipse(t, cx, hy - 1, 13, 12, HS); H.ellipse(t, cx, hy - 1, 12, 11, P.none)
    t:clear(Rectangle(0, hy - 3, 48, 40), P.none)
  end)
  shape(im, function(t) H.rect(t, cx - 14, hy - 4, 3, 8, HS); H.rect(t, cx + 12, hy - 4, 3, 8, HS) end)
  H.rect(im, cx - 13, hy - 2, 1, 4, LIME); H.rect(im, cx + 13, hy - 2, 1, 4, LIME)
  H.line(im, cx - 12, hy + 5, cx - 9, hy + 8, P.ink)
  H.rect(im, cx - 9, hy + 7, 3, 2, P.ink); H.px(im, cx - 8, hy + 7, LIME)
  finish(im, cx, hy, e, {
    ring = H.c("7b6bff"), rest = 47, dx = 15, idleMouth = "flat",
    decor = function(im2, ex)
      if ex ~= "happy" and ex ~= "laughing" then -- late-night eye bags
        H.rect(im2, cx - 8, hy + 3, 5, 1, P.tile_d); H.rect(im2, cx + 4, hy + 3, 5, 1, P.tile_d)
      end
    end,
  })
  return im
end

------------------------------------------------------------------ L: mysterious guest
local COAT, COAT_D, COAT_L, HAT, HAT_D, MID, GLOVE = H.c("8f9458"), H.c("5f6338"), H.c("b3b87a"), H.c("5f6338"),
  H.c("43462a"), H.c("c98f62"), H.c("8a5a36")
local function guest_l(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 22 + (BOB[e] or 0)
  for _, x in ipairs({ 15, 25 }) do stamp(im, x, 58, SHOE, { ["#"] = P.ink, k = P.base, g = HAIR_L }) end
  neck(im, cx, hy + 8, 32, MID)
  local function hw(y)
    if y == 31 then return 6 end
    return 8 + (y - 32) * 2 // 24
  end
  shape(im, function(t)
    for y = 31, 57 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, COAT) end
  end)
  for y = 33, 57 do H.px(im, cx - hw(y) + 1, y, COAT_D) end
  H.line(im, cx - 5, 31, cx - 1, 41, COAT_L, 2); H.line(im, cx + 5, 31, cx + 2, 41, COAT_L, 2)
  H.rect(im, cx - hw(43), 43, hw(43) * 2 + 1, 2, COAT_D)
  H.box(im, cx - 2, 42, 5, 4, P.gold, P.ink)
  H.rect(im, cx, 46, 1, 12, COAT_D)
  for _, y in ipairs({ 49, 53 }) do H.px(im, cx - 3, y, P.ink); H.px(im, cx + 3, y, P.ink) end

  head(im, cx, hy, MID)
  -- turned-up collar hides the cheeks
  shape(im, function(t)
    for y = hy + 3, hy + 11 do
      local w = 3 + (y - (hy + 3)) * 5 // 8
      H.rect(t, cx - 12, y, w, 1, COAT); H.rect(t, cx + 13 - w, y, w, 1, COAT)
    end
  end)
  for y = hy + 4, hy + 11 do
    local w = 3 + (y - (hy + 3)) * 5 // 8
    H.px(im, cx - 12 + w - 1, y, COAT_L); H.px(im, cx + 13 - w, y, COAT_L)
  end
  local lift = e == "shocked" and 3 or 0 -- hat jumps
  shape(im, function(t)
    H.ellipse(t, cx, hy - 8 - lift, 14, 2, HAT)
    H.rect(t, cx - 8, hy - 16 - lift, 17, 7, HAT); H.rect(t, cx - 7, hy - 17 - lift, 15, 1, HAT)
  end)
  H.rect(im, cx - 8, hy - 12 - lift, 17, 2, P.xred)
  H.rect(im, cx - 3, hy - 17 - lift, 7, 1, HAT_D); H.rect(im, cx - 12, hy - 7 - lift, 25, 1, HAT_D)
  finish(im, cx, hy, e, {
    eyemap = { D = P.gray, G = P.ui, R = P.concrete_l, C = P.white, ["#"] = P.ink },
    rest = 47, hand = GLOVE, idleMouth = "flat", acc = { 38, 1 },
    decor = function(im2, ex)
      if ex == "idle" or ex == "confused" or ex == "angry" or ex == "sad" or ex == "shocked" then
        H.px(im2, cx, hy - 2, P.gray) -- bridge of the shades
      end
    end,
  })
  return im
end

------------------------------------------------------------------ M: lady with a tiny dog
local GOWN, GOWN_D, BLONDE, BLONDE_D, FUR, FUR_L = H.c("1f9a5a"), H.c("136b3d"), H.c("f5d547"), H.c("c9a51c"),
  H.c("f0a85a"), H.c("ffe0b0")
local function guest_m(e)
  local im = H.img(48, 64)
  local cx, hy = 24, 20 + (BOB[e] or 0)
  neck(im, cx, hy + 8, 32)
  local function hw(y)
    if y == 31 then return 4 end
    return 5 + math.max(0, y - 44) * 4 // 17
  end
  shape(im, function(t)
    for y = 31, 61 do H.rect(t, cx - hw(y), y, hw(y) * 2 + 1, 1, GOWN) end
  end)
  for y = 33, 61 do H.px(im, cx - hw(y) + 1, y, GOWN_D) end
  H.line(im, cx + 1, 46, cx + 4, 61, GOWN_D)
  for _, s in ipairs({ { -2, 40 }, { 2, 50 }, { -5, 56 }, { 6, 58 }, { 1, 37 } }) do H.px(im, cx + s[1], s[2], P.white) end
  H.rect(im, cx - 9, 61, 19, 1, P.gold)
  -- fur stole
  shape(im, function(t)
    H.ellipse(t, cx, 32, 9, 2, P.white)
  end)
  for _, s in ipairs({ { -7, 32 }, { -4, 33 }, { 0, 33 }, { 3, 33 }, { 7, 32 } }) do H.px(im, cx + s[1], s[2], P.tile_d) end
  neck(im, cx, hy + 8, 30)

  head(im, cx, hy, P.white, function(t)
    H.ellipse(t, cx, hy - 8, 12, 7, BLONDE)
    facefill(t, cx, hy, P.white, function(dx) return hy - 6 - (dx + 11) // 8 end)
  end)
  H.line(im, cx - 9, hy - 9, cx - 2, hy - 13, BLONDE_D); H.line(im, cx + 1, hy - 13, cx + 9, hy - 10, BLONDE_D)
  H.rect(im, cx - 4, hy - 9, 6, 1, BLONDE_D)
  -- the dog, tucked under her arm
  shape(im, function(t) H.ellipse(t, cx + 11, 47, 5, 3, FUR) end)
  local dog = { ".#.....#.", "#o#...#o#", "#oo###oo#", "#ooooooo#", "#o#ooo#o#", "#oommmoo#", "#oom#moo#", ".#ommmo#.", "..#####.." }
  if e == "shocked" then dog[5] = "#oWoooWo#"; dog[4] = "#o#ooo#o#"
  elseif e == "angry" then dog[4] = "#o#ooo#o#"; dog[5] = "#oo#o#oo#"; dog[8] = ".#oW#Wo#."
  elseif e == "happy" or e == "laughing" then dog[8] = ".#omPmo#."
  elseif e == "sad" then dog[4] = "#oo#o#oo#" end
  stamp(im, cx + 7, 36, dog, { ["#"] = P.ink, o = FUR, m = FUR_L, W = P.white, P = TONGUE })
  finish(im, cx, hy, e, {
    ring = H.c("a13fa8"), rest = 46, lashes = true,
    pos = {
      idle = { -13, 46, 12, 50 }, blink = { -13, 46, 12, 50 }, happy = { -14, 33, 12, 50 },
      laughing = { -5, 41, 12, 50 }, shocked = { -12, hy + 6, 12, 50 }, angry = { -15, hy + 10, 12, 50 },
      confused = { -7, hy + 11, 12, 50 }, sad = { -3, 40, 12, 50 },
    },
    decor = function(im2)
      H.px(im2, cx + 6, hy + 5, P.ink) -- beauty mark
      H.rect(im2, cx - 12, hy + 3, 1, 3, P.gold); H.rect(im2, cx + 12, hy + 3, 1, 3, P.gold)
    end,
  })
  return im
end

------------------------------------------------------------------ build + save
local LIST = {
  { "a", "SPA NIGHT", guest_a }, { "b", "BUSINESS", guest_b }, { "c", "SLEEPER", guest_c },
  { "d", "GRAN", guest_d }, { "e", "TOURIST", guest_e }, { "f", "DINO KID", guest_f },
  { "g", "GYM BRO", guest_g }, { "h", "ROCKER", guest_h }, { "i", "CHEF", guest_i },
  { "j", "HONEYMOON", guest_j }, { "k", "GAMER", guest_k }, { "l", "MYSTERY", guest_l },
  { "m", "DOG LADY", guest_m },
}
local guests = {}
for gi, g in ipairs(LIST) do
  local fr = {}
  for i, e in ipairs(EXPR) do fr[i] = g[3](e) end
  guests[gi] = fr
  saveAnim("guest_" .. g[1], fr, EXPR, 500)
  -- sanity: lowest opaque row and horizontal extent across all frames
  local low, x0, x1 = 0, 47, 0
  for _, im in ipairs(fr) do
    for y = 0, 63 do
      for x = 0, 47 do
        if pc.rgbaA(im:getPixel(x, y)) > 0 then
          if y > low then low = y end
          if x < x0 then x0 = x end
          if x > x1 then x1 = x end
        end
      end
    end
  end
  print(string.format("  guest_%s lowest row %d, x %d..%d", g[1], low, x0, x1))
end

------------------------------------------------------------------ review sheets
local tiles = Image { fromFile = H.ROOT .. "assets/tilesets/hotel_tileset.png" }
local courier = Image { fromFile = H.SPR .. "player/player_idle.png" }
print("player_idle " .. courier.width .. "x" .. courier.height)

-- Lineup: idle frames in open doorways, courier at the left of each row.
local COLS, PITCH, LEFT, ROWH = 7, 68, 56, 134
local nrows = math.ceil(#LIST / COLS)
local lu = H.img(LEFT + COLS * PITCH + 4, nrows * ROWH, P.wall)
for r = 0, nrows - 1 do
  local floor = r * ROWH + 26 + 96
  H.rect(lu, 0, floor, lu.width, ROWH - 122, P.carpet)
  H.rect(lu, 0, floor, lu.width, 1, P.carpet_l)
  H.blit(lu, courier, 4, floor - 63, 0, 0, 48, 64)
  H.tag(lu, "COURIER", 28, r * ROWH + 14, P.white, P.ui_ll, "center")
  for c = 0, COLS - 1 do
    local gi = r * COLS + c + 1
    if LIST[gi] then
      local x = LEFT + c * PITCH
      H.blit(lu, tiles, x, floor - 96, 64, 64, 64, 96)
      H.blit(lu, guests[gi][1], x + 8, floor - 63)
      H.tag(lu, LIST[gi][1], x + 32, r * ROWH + 1, P.yellow, P.ui, "center")
      H.tag(lu, LIST[gi][2], x + 32, r * ROWH + 13, P.white, P.ui, "center")
    end
  end
end
saveScaled(lu, REVIEW .. "options_guests_lineup.png", 4)

-- Expression grids on a mid-tone background, split so each stays under ~2400px.
local BG, BG2, FLOOR = H.c("8792a2"), H.c("7c8797"), H.c("5f6978")
local function grid(from, to, path)
  local n = to - from + 1
  local LW, CW, RH, HD = 70, 50, 67, 14
  local im = H.img(LW + #EXPR * CW, HD + n * RH, BG)
  for i, e in ipairs(EXPR) do
    if i % 2 == 0 then H.rect(im, LW + (i - 1) * CW, 0, CW, im.height, BG2) end
    H.text(im, e, LW + (i - 1) * CW + CW // 2, 4, P.white, { align = "center" })
  end
  for k = 0, n - 1 do
    local gi = from + k
    local y = HD + k * RH
    H.rect(im, 0, y + 63, im.width, 1, FLOOR)
    H.text(im, LIST[gi][1], 4, y + 20, P.yellow, { s = 2, outline = P.ink })
    H.text(im, LIST[gi][2], 2, y + 40, P.white)
    for i = 1, #EXPR do H.blit(im, guests[gi][i], LW + (i - 1) * CW + 1, y) end
  end
  saveScaled(im, path, 4)
end
grid(1, 7, REVIEW .. "options_guests_expressions_1.png")
grid(8, #LIST, REVIEW .. "options_guests_expressions_2.png")

-- Zoomed strips for checking faces (only written when HWC_TMP is set):
-- left half on the mid-tone, right half repeats the frames on door black.
if TMP then
  for gi, g in ipairs(LIST) do
    local z = H.img(8 * 48, 128, BG)
    H.rect(z, 0, 64, 384, 64, P.ink)
    for i = 1, 8 do
      H.blit(z, guests[gi][i], (i - 1) * 48, 0)
      H.blit(z, guests[gi][i], (i - 1) * 48, 64)
    end
    saveScaled(z, TMP .. "zoom_" .. g[1] .. ".png", 5)
  end
end
