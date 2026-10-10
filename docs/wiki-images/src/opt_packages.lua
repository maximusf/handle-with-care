-- Package art, round 3: the flat boxes B and C, two silly boxes that were
-- mailed as-is (cereal, pizza), and the package types with their stages.
-- Writes to docs/art-options/packages/:
--   box_<letter>_<name>, silly_<name>: 3 frames intact, damaged, destroyed
--   type_<name>: 3 to 6 named stages
-- each as a horizontal strip .png plus .aseprite (one tag per frame, layer "Art").
-- The .json next to each strip comes from a second CLI call:
--   Aseprite -b <name>.aseprite --sheet <name>.png --sheet-type horizontal
--     --data <name>.json --format json-array --list-tags
-- Previews: docs/art-review/options_packages_{basic,silly,types}.png.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/yeet_brand.lua")
local P, YP = H.P, Y.P
local pc = app.pixelColor
local OUT = H.ROOT .. "docs/art-options/packages/"
local REVIEW = H.ROOT .. "docs/art-review/"
app.fs.makeAllDirectories(OUT)
app.fs.makeAllDirectories(REVIEW)

local INK = P.box_ink
-- extra shades
local CARD_L, TAPE_D = H.c("f7c97c"), H.c("c4b596")
local WOOD, WOOD_L, WOOD_D, WOOD_DD = H.c("b5733a"), H.c("d39650"), H.c("8a5226"), H.c("5e3516")
local STRAW, STRAW_D = H.c("f0d264"), H.c("c9a23a")
local STEEL, STEEL_L, STEEL_D = H.c("a7a7a2"), H.c("d2d2cc"), H.c("6c6e72")
local PAPER, PAPER_D = H.c("b9793c"), H.c("93592a")
local PURPLE_L, PURPLE_D = H.c("9c74de"), H.c("5a3494")
local TEAL, TEAL_L, TEAL_D, TEAL_DD = H.c("3fb8a8"), H.c("86e0d2"), H.c("2a8a7e"), H.c("1c5f58")
local MAIL, MAIL_D = H.c("f4f1ea"), H.c("cfcabf")
local ICE, ICE_D = H.c("eef8ff"), H.c("b5dcf5")
local SOOT, SOOT_L = H.c("2a2426"), H.c("4a4044")
local DARK = H.c("1c120c")
local FUR = H.c("d98a3c")

------------------------------------------------------------------ helpers

local function opaque(im, x, y)
  return x >= 0 and y >= 0 and x < im.width and y < im.height and pc.rgbaA(im:getPixel(x, y)) > 0
end
local function mpx(im, x, y, c) if opaque(im, x, y) then im:drawPixel(x, y, c) end end
local function mrect(im, x, y, w, h, c)
  for j = y, y + h - 1 do for i = x, x + w - 1 do mpx(im, i, j, c) end end
end
local function mline(im, x0, y0, x1, y1, c)
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    mpx(im, x0, y0, c)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end
local function clr(im, x, y, w, h) H.rect(im, x, y, w or 1, h or 1, P.none) end
local function ol(im, diag) A.outline(im, INK, diag) end

-- rows of "#" / "." ; masked = only paint over opaque pixels
local function bmp(im, x, y, rows, c, masked)
  for j, row in ipairs(rows) do
    for i = 1, #row do
      if row:sub(i, i) == "#" then
        if masked then mpx(im, x + i - 1, y + j - 1, c) else H.px(im, x + i - 1, y + j - 1, c) end
      end
    end
  end
end

-- Convex polygon fill, vertices inclusive.
local function poly(im, pts, c)
  local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
  for _, p in ipairs(pts) do
    x0, y0 = math.min(x0, p[1]), math.min(y0, p[2])
    x1, y1 = math.max(x1, p[1]), math.max(y1, p[2])
  end
  local n = #pts
  for y = y0, y1 do
    for x = x0, x1 do
      local pos, neg = false, false
      for i = 1, n do
        local a, b = pts[i], pts[i % n + 1]
        local cr = (b[1] - a[1]) * (y - a[2]) - (b[2] - a[2]) * (x - a[1])
        if cr > 0 then pos = true elseif cr < 0 then neg = true end
      end
      if not (pos and neg) then H.px(im, x, y, c) end
    end
  end
end

-- One loose piece: filled polygon, optional decoration clipped to it, own outline.
local function piece(im, pts, fill, deco)
  local t = H.img(im.width, im.height)
  poly(t, pts, fill)
  if deco then
    local d = H.img(im.width, im.height)
    deco(d)
    for y = 0, t.height - 1 do
      for x = 0, t.width - 1 do
        if opaque(t, x, y) and opaque(d, x, y) then t:drawPixel(x, y, d:getPixel(x, y)) end
      end
    end
  end
  ol(t)
  H.blit(im, t, 0, 0)
end

-- Outlined loose shape drawn by fn onto a scratch layer.
local function loose(im, fn)
  local t = H.img(im.width, im.height)
  fn(t)
  ol(t)
  H.blit(im, t, 0, 0)
end

local function crumb(im, x, y, c)
  H.px(im, x, y, c)
  H.px(im, x - 1, y, INK); H.px(im, x + 1, y, INK); H.px(im, x, y - 1, INK); H.px(im, x, y + 1, INK)
end

local RR = { { 1 }, { 2, 1 }, { 3, 1, 1 }, { 4, 2, 1, 1 } }
local function rrect(im, x, y, w, h, r, c)
  H.rect(im, x, y, w, h, c)
  for i, n in ipairs(RR[r]) do
    clr(im, x, y + i - 1, n, 1); clr(im, x + w - n, y + i - 1, n, 1)
    clr(im, x, y + h - i, n, 1); clr(im, x + w - n, y + h - i, n, 1)
  end
end

-- Crumpled corner: cut a triangle at corner pixel (cx,cy), shade the fold.
-- (ix,iy) point into the body.
local function corner(im, cx, cy, ix, iy, n, m, d)
  for i = 0, n + 3 do
    for k = 0, n + 3 - i do
      local x, y = cx + ix * k, cy + iy * i
      if k <= n - 1 - i then clr(im, x, y)
      else mpx(im, x, y, (k == n + 3 - i) and d or m) end
    end
  end
end

-- Dents pushed into a vertical / horizontal edge.
local function dentv(im, x, y, ix, len, d)
  clr(im, x, y, 1, len)
  clr(im, x + ix, y + 1, 1, len - 2)
  mpx(im, x + ix, y, d); mpx(im, x + ix, y + len - 1, d)
  mrect(im, x + 2 * ix, y + 1, 1, len - 2, d)
end
local function denth(im, x, y, iy, len, d)
  clr(im, x, y, len, 1)
  clr(im, x + 1, y + iy, len - 2, 1)
  mpx(im, x, y + iy, d); mpx(im, x + len - 1, y + iy, d)
  mrect(im, x + 1, y + 2 * iy, len - 2, 1, d)
end
local function scuff(im, x, y, c, len) mline(im, x, y, x + len, y - len, c) end
local function crack(im, pts, c)
  for i = 1, #pts - 1 do mline(im, pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2], c) end
end

-- Standard "damaged" pass for a rectangular body whose fill is x,y,w,h.
local function wear(im, x, y, w, h, v, m, d, dd)
  m, d, dd = m or P.card_m, d or P.card_d, dd or P.card_dd
  local x1, y1 = x + w - 1, y + h - 1
  if v == 1 then
    corner(im, x1, y, -1, 1, 5, m, d)
    corner(im, x, y1, 1, -1, 2, m, d)
    dentv(im, x, y + h // 2 - 2, 1, 6, d)
    denth(im, x + w // 2 + 3, y1, -1, 6, d)
    scuff(im, x + 4, y + 8, d, 2); scuff(im, x + w - 8, y1 - 4, d, 2)
    crack(im, { { x + 5, y }, { x + 6, y + 2 }, { x + 4, y + 4 }, { x + 6, y + 6 } }, dd)
  else
    corner(im, x, y, 1, 1, 5, m, d)
    corner(im, x1, y1, -1, -1, 2, m, d)
    dentv(im, x1, y + h // 2 - 1, -1, 6, d)
    denth(im, x + 5, y1, -1, 6, d)
    scuff(im, x1 - 6, y + 6, d, 2); scuff(im, x + 4, y1 - 4, d, 2)
    crack(im, { { x1 - 5, y }, { x1 - 6, y + 2 }, { x1 - 4, y + 4 }, { x1 - 6, y + 6 } }, dd)
  end
end

local function label(im, x, y, w, h)
  H.rect(im, x, y, w, h, P.cream)
  H.rect(im, x + 1, y + 1, w - 4, 1, P.box_ink)
  H.rect(im, x + 1, y + 3, w - 3, 1, P.gray)
  for i = x + 1, x + w - 2, 2 do H.rect(im, i, y + h - 3, 1, 2, P.box_ink) end
end

local I_ARROWS = { ".#...#.", "###.###", ".#...#.", ".#...#.", ".#...#.", ".......", "#######" }
local I_GLASS = { "#...#", "#...#", "#...#", ".###.", "..#..", "..#..", ".###." }
local I_UMBR = { "...#...", ".#####.", "#######", "...#...", "...#...", ".#.#...", "..#...." }
local I_BIGGLASS = { "#.....#", "#.....#", "#.....#", ".#...#.", "..###..", "...#...", "...#...", "...#...", ".#####." }
local I_SNOW = { "#..#..#", ".#.#.#.", "..###..", "#######", "..###..", ".#.#.#.", "#..#..#" }
local I_WEIGHT = { "..###..", ".#...#.", ".#...#.", ".#####.", "#######", "#######", "#######" }
local I_PAW = { ".#.#.", "#...#", ".###.", "#####", ".###." }
local I_ANVIL = { "#########", ".########", "...####..", "...####..", "..######.", ".########" }
local FUR_D = H.c("b06a26")
local NAVY, SHOE, SHOE_L = H.c("1f4a6e"), H.c("2f78b8"), H.c("6fb4e8")
local BORK = H.c("1f4f9e")
local GREASE = H.c("d2a04a")
local OOZE, OOZE_D = H.c("9fbe3a"), H.c("5f7a1e")
local WET = H.c("8a5226")
local TAPEY, TAPEY_D = H.c("e9c75a"), H.c("b8922c")

------------------------------------------------------------------ wreck helpers

local function bounds(im)
  local x0, y0, x1, y1 = im.width, im.height, -1, -1
  for y = 0, im.height - 1 do
    for x = 0, im.width - 1 do
      if opaque(im, x, y) then
        x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
      end
    end
  end
  return x0, y0, x1, y1
end
-- Shift the art so its bounding box sits in the middle of the frame.
local function recentre(im)
  local x0, y0, x1, y1 = bounds(im)
  if x1 < 0 then return im end
  local dx = (im.width - (x1 - x0 + 1)) // 2 - x0
  local dy = (im.height - (y1 - y0 + 1)) // 2 - y0
  if dx == 0 and dy == 0 then return im end
  local out = H.img(im.width, im.height)
  H.blit(out, im, dx, dy)
  return out
end

-- Crop art from a larger canvas into a w x h frame, centred.
local function fit(im, w, h, what)
  local x0, y0, x1, y1 = bounds(im)
  local bw, bh = x1 - x0 + 1, y1 - y0 + 1
  if bw > w - 2 or bh > h - 2 then print("TOO BIG " .. what .. " " .. bw .. "x" .. bh) end
  local out = H.img(w, h)
  H.blit(out, im, (w - bw) // 2 - x0, (h - bh) // 2 - y0)
  return out
end
local function coltop(im, x)
  for y = 0, im.height - 1 do if opaque(im, x, y) then return y end end
end
local function colbot(im, x)
  for y = im.height - 1, 0, -1 do if opaque(im, x, y) then return y end end
end
local function rowleft(im, y)
  for x = 0, im.width - 1 do if opaque(im, x, y) then return x end end
end
local function rowright(im, y)
  for x = im.width - 1, 0, -1 do if opaque(im, x, y) then return x end end
end

-- Resample src through an inverse map fn(x, y) -> sx, sy (nil = empty).
local function warp(src, fn)
  local out = H.img(src.width, src.height)
  for y = 0, out.height - 1 do
    for x = 0, out.width - 1 do
      local sx, sy = fn(x, y)
      if sx then
        sx, sy = math.floor(sx + 0.5), math.floor(sy + 0.5)
        if opaque(src, sx, sy) then out:drawPixel(x, y, src:getPixel(sx, sy)) end
      end
    end
  end
  return out
end

-- Squash an un-outlined body into a wavy pancake about the frame centre.
local function pancake(body, c)
  local bx0, by0, bx1, by1 = bounds(body)
  local sxc, syc = (bx0 + bx1) / 2, (by0 + by1) / 2
  local cx, cy = c.cx or (body.width - 1) / 2, c.cy or (body.height - 1) / 2
  local ph = c.phase or 0
  return warp(body, function(x, y)
    local dx = x - cx
    local wob = (c.amp or 1.1) * math.sin(dx * (c.freq or 0.5) + ph)
    local ky = c.ky * (1 + 0.2 * math.sin(dx * 0.31 + ph * 2))
    return sxc + dx / c.kx, syc + (y - cy - wob) / ky
  end)
end

-- "Crushed flat": the pancake, creased, with a torn notch, a ripped-off
-- corner lying beside it, a strand of tape and a couple of packing peanuts.
local function crush(im, body, c, col)
  local t = pancake(body, c)
  local x0, y0, x1, y1 = bounds(t)
  if c.ux then
    loose(im, function(u)
      poly(u, { { x0 + 2 + c.ux, y0 + 3 }, { x1 + c.ux, y0 + 2 }, { x1 - 1 + c.ux, y1 + 2 }, { x0 + 1 + c.ux, y1 + 1 } },
        col.under)
    end)
  end
  for i, f in ipairs(c.creases or { 0.33, 0.7 }) do
    local x = math.floor(x0 + (x1 - x0) * f)
    for y = y0, y1 do
      mpx(t, x + (((y + i) % 3 == 0) and 1 or 0) - (((y + i) % 5 == 0) and 1 or 0), y, col.dd)
    end
  end
  local my, mx = (y0 + y1) // 2, (x0 + x1) // 2
  mline(t, x0 + 1, my + 1, mx, my - 1, col.d); mline(t, mx, my - 1, x1 - 1, my + 1, col.d)
  local nx = math.floor(x0 + (x1 - x0) * (c.notch or 0.45))
  for i = -2, 2 do
    local ty = coltop(t, nx + i)
    if ty then clr(t, nx + i, ty, 1, 3 - math.abs(i)) end
  end
  local side = c.rip or 1
  local ex = side > 0 and x1 or x0
  for i = 0, 4 do
    local ty = coltop(t, ex - side * i)
    if ty then clr(t, ex - side * i, ty, 1, 5 - i) end
  end
  ol(t)
  H.blit(im, t, 0, 0)
  if not c.norip then
    local px, py = ex - side * 2, (coltop(t, ex - side * 5) or y0) - 5
    piece(im, { { px - 2, py + 1 }, { px + 2, py }, { px + 1, py + 3 } }, col.base)
  end
  if col.tape and not c.notape then
    local tx = math.floor(x0 + (x1 - x0) * (side > 0 and 0.25 or 0.75))
    local by = colbot(t, tx) or y1
    loose(im, function(u) H.px(u, tx, by + 1, col.tape); H.px(u, tx, by + 2, col.tape); H.px(u, tx + 1, by + 3, col.tape) end)
  end
  if not c.nopeanuts then
    crumb(im, x0 + 4, y0 - 3, P.cream); crumb(im, x1 - 7, y1 + 4, P.cream)
  end
  return x0, y0, x1, y1
end

------------------------------------------------------------------ basic boxes (32x32)

local BASIC, SILLY = {}, {}
local function BOX(list, code, name, note, def)
  def.code, def.name, def.note = code, name, note
  list[#list + 1] = def
end

-- Busts are drawn by hand: a few big flat panels (each with its own outline,
-- like package_destroyed.png), one crease, one strip of tape, one identifying mark.
local function panel(im, pts, fill, deco) piece(im, pts, fill, deco) end

-- B: folded top flaps with a lip, tape tab and a shipping label.
BOX(BASIC, "b", "flaps", "flap lip, tape tab, label", {
  square = true,
  draw = function(im, st)
    H.rect(im, 4, 10, 24, 17, P.card)
    H.rect(im, 4, 10, 24, 1, P.card_d)
    bmp(im, 6, 15, I_ARROWS, P.card_dd)
    label(im, 16, 15, 10, 9)
    if st == 0 then
      H.rect(im, 3, 5, 26, 5, CARD_L)
      H.rect(im, 13, 5, 6, 9, P.tape)
      H.rect(im, 13, 5, 1, 9, TAPE_D); H.rect(im, 18, 5, 1, 9, TAPE_D)
    else
      -- one flap popped with the tape torn, one dented corner, one tear
      H.rect(im, 16, 10, 12, 2, P.card_dd)
      H.rect(im, 3, 5, 13, 5, CARD_L)
      poly(im, { { 16, 6 }, { 27, 2 }, { 28, 5 }, { 16, 9 } }, CARD_L)
      H.line(im, 17, 9, 27, 6, P.card_m)
      H.rect(im, 12, 5, 4, 7, P.tape); H.rect(im, 12, 12, 2, 2, P.tape); H.rect(im, 12, 5, 1, 7, TAPE_D)
      corner(im, 4, 26, 1, -1, 4, P.card_m, P.card_d)
      crack(im, { { 27, 19 }, { 25, 20 }, { 26, 22 }, { 24, 23 } }, P.card_dd)
    end
  end,
  bust = function(im)
    panel(im, { { 3, 13 }, { 18, 11 }, { 20, 17 }, { 4, 19 } }, P.card_m, function(d)
      H.rect(d, 7, 10, 3, 9, P.tape); H.rect(d, 7, 10, 1, 9, TAPE_D)
    end)
    panel(im, { { 19, 16 }, { 25, 8 }, { 29, 11 }, { 25, 18 } }, CARD_L, function(d)
      H.line(d, 21, 15, 26, 10, P.card_m)
    end)
    panel(im, { { 2, 17 }, { 27, 15 }, { 29, 23 }, { 4, 25 } }, P.card, function(d)
      H.rect(d, 7, 15, 3, 6, P.tape); H.rect(d, 7, 15, 1, 6, TAPE_D); H.rect(d, 8, 21, 2, 1, P.tape)
      H.line(d, 13, 15, 15, 25, P.card_dd)
      label(d, 17, 17, 10, 6)
    end)
  end,
})

-- C: YEET kraft box, orange diagonal stripes and the Y monogram.
local function yeet_stripes(im, y0, y1, xtop)
  for y = y0, y1 do
    local xs = xtop - (y - y0) // 2
    mrect(im, xs, y, 3, 1, YP.orange)
    mrect(im, xs + 4, y, 2, 1, YP.orange)
  end
end
BOX(BASIC, "c", "yeet", "YEET stripes and Y mark", {
  square = true,
  draw = function(im, st)
    H.rect(im, 3, 6, 26, 20, P.card)
    yeet_stripes(im, 6, 25, 23)
    Y.mono(im, 4, 9, 1, YP.char, YP.orange)
    label(im, 5, 18, 8, 6)
    if st == 1 then
      -- one crumpled corner, one tear, the label lifting
      corner(im, 28, 6, -1, 1, 5, P.card_m, P.card_d)
      crack(im, { { 16, 25 }, { 17, 22 }, { 15, 20 }, { 16, 18 } }, P.card_dd)
      H.rect(im, 11, 18, 2, 1, P.card); H.rect(im, 12, 19, 1, 1, P.card)
    end
  end,
  bust = function(im)
    panel(im, { { 9, 12 }, { 25, 10 }, { 27, 17 }, { 10, 18 } }, P.card_d)
    panel(im, { { 3, 18 }, { 5, 9 }, { 10, 10 }, { 10, 19 } }, P.card_m, function(d)
      H.line(d, 5, 16, 8, 11, P.card_d)
    end)
    panel(im, { { 2, 17 }, { 27, 15 }, { 29, 23 }, { 4, 25 } }, P.card, function(d)
      for y = 14, 26 do
        local xs = 25 - (y - 14) // 2
        H.rect(d, xs, y, 3, 1, YP.orange); H.rect(d, xs + 4, y, 2, 1, YP.orange)
      end
      Y.mono(d, 4, 17, 1, YP.char, YP.orange)
    end)
  end,
})

------------------------------------------------------------------ silly boxes (32x32)

local LOOPS = { P.red, P.green, P.purple, P.blue, P.orange }
local TAPE_BR, TAPE_BRD = H.c("c9a064"), H.c("a07a40")

-- white address label stuck on crooked: two text lines and a barcode
local function address(im, pts, border)
  poly(im, pts, P.white)
  if border then
    for i = 1, 4 do
      local a, b = pts[i], pts[i % 4 + 1]
      H.line(im, a[1], a[2], b[1], b[2], border)
    end
  end
  local x, y = pts[1][1] + 2, pts[1][2] + 1
  H.rect(im, x, y, 4, 1, P.ink)
  H.rect(im, x, y + 2, 6, 1, P.gray)
  for i = 0, 2 do H.rect(im, x + i * 2, y + 4, 1, 2, P.ink) end
end
local function stamp(im, x, y)
  H.rect(im, x, y, 4, 5, P.white)
  H.rect(im, x + 1, y + 1, 2, 3, P.purple); H.px(im, x + 1, y + 1, PURPLE_L)
end

-- cereal: someone mailed the cereal box as-is
BOX(SILLY, "s1", "cereal", "cereal box, mailed as-is", {
  square = true,
  draw = function(im, st)
    H.rect(im, 7, 3, 18, 26, P.yellow)
    H.rect(im, 7, 3, 18, 9, P.blue)
    H.text(im, "YUM", 16, 4, P.white, { align = "center" })
    H.rect(im, 12, 13, 2, 2, P.orange); H.rect(im, 19, 13, 2, 2, P.orange)
    H.ellipse(im, 16, 17, 4, 3, P.orange)
    H.px(im, 14, 16, P.ink); H.px(im, 18, 16, P.ink); H.px(im, 14, 15, P.white); H.px(im, 18, 15, P.white)
    H.px(im, 15, 18, P.ink); H.px(im, 16, 19, P.ink); H.px(im, 17, 18, P.ink)
    bmp(im, 8, 23, { "########", ".######.", "..####.." }, P.white)
    for i, x in ipairs({ 9, 11, 13 }) do H.px(im, x, 22, LOOPS[i]); H.px(im, x + 1, 21 + (i % 2), LOOPS[i % 5 + 1]) end
    H.rect(im, 7, 27, 18, 2, P.red)
    if st == 1 then
      corner(im, 24, 3, -1, 1, 4, P.mat_yd, P.gold_d)
      crack(im, { { 7, 16 }, { 9, 17 }, { 8, 19 }, { 10, 20 } }, P.base_d)
    end
    -- packing tape round the box, address label, stamp
    H.rect(im, 7, 11, 18, 2, TAPE_BR); H.rect(im, 7, 12, 18, 1, TAPE_BRD)
    H.rect(im, 7, 26, 18, 2, TAPE_BR); H.rect(im, 7, 27, 18, 1, TAPE_BRD)
    address(im, { { 14, 19 }, { 23, 18 }, { 24, 25 }, { 15, 26 } })
    stamp(im, 20, 13)
    if st == 1 then
      clr(im, 22, 26, 3, 2); H.rect(im, 25, 27, 1, 3, TAPE_BR) -- tape lifting
    end
  end,
  bust = function(im)
    panel(im, { { 4, 18 }, { 21, 16 }, { 23, 24 }, { 6, 26 } }, P.mat_yd)
    panel(im, { { 2, 15 }, { 5, 9 }, { 9, 11 }, { 7, 18 } }, P.tile, function(d) H.line(d, 4, 14, 7, 12, P.tile_d) end)
    panel(im, { { 3, 14 }, { 21, 12 }, { 23, 21 }, { 5, 23 } }, P.yellow, function(d)
      H.rect(d, 0, 0, 9, 32, P.blue)
      bmp(d, 5, 15, { "#.#", "#.#", ".#.", ".#." }, P.white)
      H.rect(d, 20, 0, 4, 32, P.red)
      H.ellipse(d, 12, 15, 2, 2, P.orange); H.px(d, 11, 15, P.ink); H.px(d, 13, 15, P.ink)
      H.rect(d, 9, 19, 14, 2, TAPE_BR)
      address(d, { { 14, 14 }, { 21, 13 }, { 22, 20 }, { 15, 21 } })
      H.line(d, 9, 12, 10, 23, P.gold_d)
    end)
    -- the loops, in one neat pile
    loose(im, function(u)
      local rows = { "...##...", "..####..", ".######.", "########" }
      for j, r in ipairs(rows) do
        for i = 1, #r do
          if r:sub(i, i) == "#" then H.px(u, 21 + i, 20 + j, LOOPS[(i * 2 + j * 3) % 5 + 1]) end
        end
      end
    end)
  end,
})

-- pizza: a wide thin pizza box reused as a parcel (whatever is inside, it is not pizza)
BOX(SILLY, "s2", "pizza", "pizza box, mailed as-is", {
  square = true,
  draw = function(im, st)
    H.rect(im, 2, 12, 28, 9, P.cream)
    H.rect(im, 2, 12, 4, 9, P.xred); H.rect(im, 26, 12, 4, 9, P.xred)
    H.rect(im, 2, 14, 28, 1, P.tile_d)
    bmp(im, 13, 15, { "#########", ".#######.", "..#####..", "...###...", "....#...." }, P.yellow)
    H.rect(im, 13, 15, 9, 1, P.orange); H.px(im, 15, 16, P.red); H.px(im, 18, 17, P.red); H.px(im, 17, 16, P.red)
    if st == 1 then
      corner(im, 29, 12, -1, 1, 3, P.tile_d, P.gray)
      denth(im, 14, 20, -1, 6, P.tile_d)
      crack(im, { { 8, 12 }, { 9, 14 }, { 8, 16 } }, P.tile_d)
    end
    H.rect(im, 23, 12, 2, 9, TAPE_BR); H.rect(im, 24, 12, 1, 9, TAPE_BRD)
    address(im, { { 4, 14 }, { 11, 13 }, { 12, 19 }, { 5, 20 } }, P.gray)
    if st == 1 then H.rect(im, 23, 12, 2, 2, P.cream); H.rect(im, 25, 11, 1, 2, TAPE_BR) end
  end,
  bust = function(im)
    -- empty box crumpled into a zigzag: three bent sections, nothing spilling out
    panel(im, { { 2, 13 }, { 11, 18 }, { 11, 25 }, { 3, 20 } }, P.cream, function(d)
      H.rect(d, 0, 0, 5, 32, P.xred)
      address(d, { { 5, 16 }, { 10, 18 }, { 10, 23 }, { 5, 21 } }, P.gray)
    end)
    panel(im, { { 11, 18 }, { 20, 12 }, { 21, 19 }, { 11, 25 } }, P.tile, function(d)
      H.line(d, 13, 19, 17, 21, P.tile_d)
      H.line(d, 15, 16, 19, 17, P.tile_d)
      H.rect(d, 14, 0, 2, 32, TAPE_BR)
    end)
    panel(im, { { 20, 12 }, { 29, 16 }, { 28, 23 }, { 21, 19 } }, P.cream, function(d)
      H.rect(d, 26, 0, 6, 32, P.xred)
      H.line(d, 22, 17, 25, 16, P.tile_d)
    end)
  end,
})

local BOXSTAGES = { "intact", "damaged", "destroyed" }
local function box_frames(def)
  local a = H.img(32, 32); def.draw(a, 0); ol(a, def.square); if def.post then def.post(a, 0) end
  local d = H.img(32, 32); def.draw(d, 1); ol(d); if def.post then def.post(d, 1) end
  local b = H.img(32, 32); def.bust(b)
  return { a, d, recentre(b) }
end

------------------------------------------------------------------ package types

local TYPES = {}
local function T(name, fw, fh, note, stages, fn)
  TYPES[#TYPES + 1] = { name = name, fw = fw, fh = fh, note = note, stages = stages, fn = fn }
end
local S3 = { "intact", "damaged", "destroyed" }

-- small parcel, 14 px
T("small", 16, 16, "light, flies far", S3, function(im, k)
  local function body(b)
    H.rect(b, 2, 2, 12, 12, CARD_L)
    H.rect(b, 7, 2, 2, 12, P.tape)
    H.rect(b, 10, 9, 3, 3, P.cream); H.px(b, 11, 10, P.box_ink)
  end
  if k == 3 then
    local b = H.img(16, 16); body(b)
    crush(im, b, { kx = 1.05, ky = 0.42, phase = 0.5, amp = 0.8, freq = 0.8, creases = { 0.3, 0.75 }, nopeanuts = true,
      norip = true, notape = true }, { base = CARD_L, m = P.card, d = P.card_m, dd = P.card_dd })
    crumb(im, 13, 3, CARD_L)
    return
  end
  body(im)
  if k == 2 then
    H.rect(im, 7, 6, 2, 4, P.card_dd); H.px(im, 7, 6, P.tape); H.px(im, 8, 9, P.tape)
    corner(im, 13, 2, -1, 1, 3, P.card, P.card_d)
    dentv(im, 2, 7, 1, 4, P.card_d)
    denth(im, 4, 13, -1, 4, P.card_d)
  end
  ol(im, k == 1)
end)

-- large wooden crate with metal corners, 44 px
local function crate_body(im, k)
  H.rect(im, 3, 3, 42, 42, WOOD)
  for _, y in ipairs({ 11, 19, 29, 37 }) do H.rect(im, 3, y, 42, 1, WOOD_DD) end
  for _, y in ipairs({ 7, 15, 33, 41 }) do H.rect(im, 9, y, 30, 1, WOOD_D) end
  H.rect(im, 3, 3, 6, 42, WOOD_L); H.rect(im, 39, 3, 6, 42, WOOD_L)
  H.rect(im, 8, 3, 1, 42, WOOD_DD); H.rect(im, 39, 3, 1, 42, WOOD_DD)
  for _, y in ipairs({ 14, 24, 34 }) do H.px(im, 5, y, WOOD_DD); H.px(im, 42, y, WOOD_DD) end
  H.text(im, "50KG", 24, 21, WOOD_DD, { align = "center" })
  if k >= 2 then
    crack(im, { { 12, 31 }, { 16, 33 }, { 19, 31 }, { 23, 34 }, { 27, 32 }, { 31, 35 } }, WOOD_DD)
    crack(im, { { 19, 31 }, { 20, 36 } }, WOOD_DD)
    scuff(im, 32, 17, WOOD_D, 3)
  end
  if k >= 3 then
    H.rect(im, 14, 30, 15, 7, DARK)
    bmp(im, 13, 30, { "#.#...#....#..#.#", "...........#....." }, WOOD)
    bmp(im, 13, 35, { "..#.....#........", "#.##..#.#.##..#.#" }, WOOD)
    mline(im, 16, 36, 19, 31, STRAW); mline(im, 21, 36, 22, 32, STRAW); mline(im, 26, 36, 24, 33, STRAW_D)
    H.rect(im, 12, 12, 9, 7, DARK) -- a second slat gone
    bmp(im, 12, 12, { "#..#....#", "........." }, WOOD); bmp(im, 12, 17, { ".........", "#.#..##.#" }, WOOD)
    crack(im, { { 30, 3 }, { 31, 6 }, { 29, 8 }, { 31, 10 } }, WOOD_DD)
    crack(im, { { 9, 24 }, { 13, 25 }, { 16, 23 }, { 20, 24 } }, WOOD_DD)
    scuff(im, 12, 43, WOOD_D, 2)
  end
  local function bracket(x, y, ix, iy)
    local bx, by = ix > 0 and x or x - 6, iy > 0 and y or y - 6
    mrect(im, bx, iy > 0 and y or y - 2, 7, 3, STEEL)
    mrect(im, ix > 0 and x or x - 2, by, 3, 7, STEEL)
    mrect(im, bx, y, 7, 1, STEEL_L); mrect(im, x, by, 1, 7, STEEL_L)
    mpx(im, x + ix, y + iy, STEEL_D); mpx(im, x + ix * 5, y + iy, STEEL_D); mpx(im, x + ix, y + iy * 5, STEEL_D)
  end
  bracket(3, 3, 1, 1); bracket(3, 44, 1, -1); bracket(44, 44, -1, -1)
  if k < 3 then bracket(44, 3, -1, 1)
  else
    corner(im, 44, 3, -1, 1, 5, WOOD_D, WOOD_DD)
    dentv(im, 3, 20, 1, 7, WOOD_DD)
    denth(im, 30, 44, -1, 7, WOOD_DD)
    -- bent bracket hanging off the broken corner
    H.rect(im, 38, 3, 3, 2, STEEL); H.rect(im, 36, 5, 3, 2, STEEL); H.px(im, 39, 3, STEEL_L)
  end
end
T("large", 48, 48, "heavy crate, hard to move", { "clean", "cracked", "broken", "split", "collapsed" }, function(im, k)
  if k <= 3 then
    crate_body(im, k)
    ol(im, k == 1)
  elseif k == 4 then
    local b = H.img(48, 48); crate_body(b, 3)
    local t = warp(b, function(x, y)
      local xs = 24 + (x - 23.5 - 0.11 * (24 - y)) / 0.9
      local ys = 25 + (y - 25.5) / 0.93
      local split = 22 + ((math.floor(ys) % 4 < 2) and 1 or -1) + math.floor(ys / 9)
      if xs >= split - 1 and xs <= split + 1 then return nil end
      if xs > split then ys = ys - 2; xs = xs - 1.5 else xs = xs + 1 end
      return xs, ys
    end)
    ol(t); H.blit(im, t, 0, 0)
    loose(im, function(u) mline(u, 24, 6, 26, 2, STRAW); mline(u, 22, 8, 21, 3, STRAW_D) end)
  else
    -- collapsed: a low, wide heap of planks
    local b = H.img(48, 48); crate_body(b, 1)
    local function plank(pts, c, ox, oy)
      piece(im, pts, c, function(d)
        H.line(d, (pts[1][1] + pts[4][1]) // 2, (pts[1][2] + pts[4][2]) // 2,
          (pts[2][1] + pts[3][1]) // 2, (pts[2][2] + pts[3][2]) // 2, WOOD_D)
        H.px(d, pts[1][1] + 2, pts[1][2] + 2, WOOD_DD); H.px(d, pts[3][1] - 2, pts[3][2] - 2, WOOD_DD)
        if ox then H.text(d, "50KG", ox, oy, WOOD_DD, { align = "center" }) end
      end)
    end
    loose(im, function(u)
      H.ellipse(u, 24, 30, 16, 5, STRAW)
      for i = 0, 12 do mline(u, 10 + i * 2, 27 + (i * 5) % 6, 13 + i * 2, 30 + (i * 5) % 6, STRAW_D) end
    end)
    plank({ { 2, 31 }, { 30, 33 }, { 30, 38 }, { 2, 36 } }, WOOD_L)
    plank({ { 17, 34 }, { 44, 31 }, { 45, 36 }, { 18, 39 } }, WOOD)
    plank({ { 5, 24 }, { 34, 20 }, { 35, 28 }, { 6, 32 } }, WOOD, 21, 22)
    plank({ { 20, 26 }, { 44, 24 }, { 44, 29 }, { 21, 31 } }, WOOD_L)
    plank({ { 9, 18 }, { 15, 16 }, { 22, 27 }, { 17, 30 } }, WOOD)
    plank({ { 31, 15 }, { 37, 17 }, { 33, 30 }, { 28, 28 } }, WOOD_L)
    loose(im, function(u) H.rect(u, 38, 20, 7, 3, STEEL); H.rect(u, 42, 20, 3, 7, STEEL); H.px(u, 43, 21, STEEL_D) end)
    loose(im, function(u) H.rect(u, 3, 26, 3, 6, STEEL); H.rect(u, 3, 26, 6, 3, STEEL); H.px(u, 4, 27, STEEL_D) end)
    crumb(im, 25, 13, WOOD); crumb(im, 42, 40, WOOD_L); crumb(im, 6, 41, WOOD)
  end
end)

-- long poster tube, 56x12
T("long", 64, 16, "awkward, spins", S3, function(im, k)
  local function body(b, capped)
    H.rect(b, 5, 3, 54, 10, P.card)
    for x = 14, 46, 8 do mline(b, x, 12, x + 5, 3, P.card_m) end
    H.rect(b, 11, 3, 2, 10, YP.orange); H.rect(b, 51, 3, 2, 10, YP.orange)
    label(b, 25, 5, 12, 6)
    H.rect(b, 5, 3, 4, 10, P.white); H.rect(b, 8, 3, 1, 10, P.tile_d)
    clr(b, 5, 3); clr(b, 5, 12)
    if capped then
      H.rect(b, 55, 3, 4, 10, P.white); H.rect(b, 55, 3, 1, 10, P.tile_d)
      clr(b, 58, 3); clr(b, 58, 12)
    end
  end
  if k == 3 then
    -- flattened and folded into a zigzag, far end torn open and unravelling
    local b = H.img(64, 16); body(b, false)
    local KX = { 4, 22, 40, 56 }
    local KY = { 5, 8, 5, 7.5 }
    local t = warp(b, function(x, y)
      if x < 4 or x > 56 then return nil end
      local cy, near = 6, 99
      for i = 1, 3 do
        if x >= KX[i] and x <= KX[i + 1] then
          cy = KY[i] + (KY[i + 1] - KY[i]) * (x - KX[i]) / (KX[i + 1] - KX[i])
        end
      end
      near = math.min(math.abs(x - 22), math.abs(x - 40))
      local th = 4 + 5 * math.min(1, near / 9)
      if x > 52 and (x + y) % 3 == 0 then return nil end
      return x + 1, 7.5 + (y - cy - 1) / th * 10
    end)
    for _, x in ipairs({ 22, 40 }) do
      for y = 0, 15 do mpx(t, x + (y % 2), y, P.card_dd); mpx(t, x - 2, y, P.card_d); mpx(t, x + 3, y, P.card_d) end
    end
    mline(t, 28, 6, 33, 9, P.card_dd); mline(t, 9, 5, 14, 8, P.card_d)
    ol(t); H.blit(im, t, 0, 0)
    loose(im, function(u) -- unravelled spiral strip
      for i = 0, 3 do H.rect(u, 57 + i, 3 + ((i % 2 == 0) and 0 or 2) + i, 2, 2, P.card_m) end
    end)
    loose(im, function(u) H.rect(u, 44, 12, 5, 2, P.white) end) -- the cap that popped
    crumb(im, 31, 2, P.card)
    return
  end
  body(im, k == 1)
  if k == 2 then
    H.rect(im, 55, 3, 4, 10, P.card_dd); H.rect(im, 55, 5, 3, 6, P.white); H.rect(im, 55, 7, 2, 2, P.blue)
    clr(im, 58, 3, 1, 2); clr(im, 58, 11, 1, 2)
    H.rect(im, 59, 5, 3, 8, P.white); H.rect(im, 59, 5, 1, 8, P.tile_d)
    clr(im, 39, 3, 8, 1); clr(im, 41, 4, 4, 1); clr(im, 42, 5, 2, 1)
    clr(im, 41, 12, 4, 1)
    mline(im, 40, 4, 42, 6, P.card_d); mline(im, 45, 4, 43, 6, P.card_d)
    mline(im, 42, 6, 42, 11, P.card_dd); mline(im, 43, 7, 44, 11, P.card_d)
    denth(im, 17, 12, -1, 5, P.card_d); denth(im, 19, 3, 1, 4, P.card_d)
    scuff(im, 31, 12, P.card_d, 2)
  end
  ol(im)
end)

-- fragile: white box, red tape, glass icon; the vase inside is blue
T("fragile", 32, 32, "breaks in few hits", S3, function(im, k)
  local function body(b)
    H.rect(b, 4, 4, 24, 24, P.cream)
    H.rect(b, 4, 6, 24, 3, P.red); H.rect(b, 4, 23, 24, 3, P.red)
    bmp(b, 13, 11, I_BIGGLASS, P.red_d)
  end
  local function shard(a, b, c2, col)
    piece(im, { a, b, c2 }, col, function(d) H.line(d, a[1], a[2], (b[1] + c2[1]) // 2, (b[2] + c2[2]) // 2, P.white) end)
  end
  if k == 3 then
    -- crushed flat with the vase come through it in pieces
    local b = H.img(32, 32); body(b)
    local x0, y0, x1, y1 = crush(im, b, { kx = 1.05, ky = 0.45, phase = 1.4, ux = 2, rip = -1, cy = 17, nopeanuts = true },
      { base = P.cream, m = P.tile, d = P.tile_d, dd = P.gray, under = P.tile_d })
    shard({ 9, y0 + 3 }, { 12, y0 - 6 }, { 14, y0 + 2 }, P.blue)
    shard({ 16, y0 + 4 }, { 21, y0 - 4 }, { 21, y0 + 3 }, P.water_d)
    shard({ 23, y1 - 2 }, { 28, y1 + 3 }, { 21, y1 + 2 }, P.blue)
    shard({ 5, y1 + 1 }, { 9, y1 - 1 }, { 8, y1 + 4 }, P.water_d)
    shard({ 3, y0 - 3 }, { 6, y0 - 5 }, { 6, y0 - 1 }, P.blue)
    return
  end
  body(im)
  if k == 2 then
    H.rect(im, 12, 6, 3, 3, P.cream); H.px(im, 12, 7, P.red); H.px(im, 14, 6, P.red)
    wear(im, 4, 4, 24, 24, 2, P.tile, P.tile_d, P.gray)
    crack(im, { { 14, 12 }, { 16, 14 }, { 15, 16 }, { 18, 18 }, { 17, 21 } }, P.gray)
    crack(im, { { 16, 14 }, { 20, 13 }, { 22, 15 } }, P.gray)
    H.rect(im, 22, 16, 3, 4, DARK)
  end
  ol(im, k == 1)
  if k == 2 then shard({ 23, 15 }, { 29, 13 }, { 24, 19 }, P.blue) end
end)

-- bouncy: beach ball with a shipping label slapped on
local BALL = { P.red, P.white, P.yellow, P.white, P.blue, P.white }
local function ball(im, ax, ay, cy, twist, cut)
  local cx = 15.5
  for y = 0, 31 do
    for x = 0, 31 do
      local dx, dy = x - cx, y - cy
      local a = math.atan(dy / ay, dx / ax) + math.pi
      local r2 = (dx / ax) ^ 2 + (dy / ay) ^ 2
      local lim = cut and cut(a, dx / ax, dy / ay) or 1
      if lim > 0 and r2 <= lim * lim then
        local sec = math.floor((a + 0.35 + twist * math.sqrt(r2)) / (2 * math.pi) * 6) % 6
        local c = BALL[sec + 1]
        if r2 * ax * ay < 6.76 then c = P.white end
        im:drawPixel(x, y, c)
      end
    end
  end
end
local function ball_label(im, x, y, w, h)
  local d = H.img(32, 32); label(d, x, y, w, h)
  for j = 0, 31 do for i = 0, 31 do if opaque(d, i, j) then mpx(im, i, j, d:getPixel(i, j)) end end end
end
T("bouncy", 32, 32, "bounces a lot", { "full", "soft", "half", "flat", "popped" }, function(im, k)
  if k == 1 then
    ball(im, 11.6, 11.6, 15.5, 0)
    label(im, 7, 15, 9, 7)
    mline(im, 20, 6, 23, 9, P.white); mline(im, 6, 11, 8, 8, P.cream)
  elseif k == 2 then
    ball(im, 12.2, 10.4, 16.5, 0, function(a, u, v) return v > 0.86 and 0 or 1 end)
    ball_label(im, 7, 16, 9, 7)
    mline(im, 20, 8, 23, 11, P.white)
    mline(im, 18, 21, 22, 19, P.gray)
  elseif k == 3 then
    ball(im, 12.8, 8.2, 17, 0.1, function(a, u, v)
      if v < -0.5 and math.abs(u - 0.15) < 0.32 - (v + 1) * 0.3 then return 0 end
      return v > 0.84 and 0 or 1
    end)
    ball_label(im, 6, 16, 9, 6)
    mline(im, 13, 22, 21, 17, P.gray); mline(im, 19, 13, 23, 15, P.gray); mline(im, 9, 12, 12, 14, P.gray)
    bmp(im, 22, 19, { "#.#", ".#.", "#.#" }, P.box_ink, true)
  elseif k == 4 then
    ball(im, 13.4, 5.2, 17.5, 0.3, function(a) return 1 + 0.07 * math.sin(a * 6) end)
    ball_label(im, 5, 16, 7, 4)
    mline(im, 8, 15, 13, 19, P.gray); mline(im, 16, 14, 19, 20, P.gray); mline(im, 22, 20, 26, 16, P.gray)
    mline(im, 12, 21, 15, 18, P.gray)
    bmp(im, 21, 16, { "#.#", ".#.", "#.#" }, P.box_ink, true)
  else
    -- popped: ragged flat skin split open from one side
    ball(im, 13.6, 5.6, 17, 0.9, function(a, u, v)
      if u > -0.1 and math.abs(v + 0.1 - u * 0.2) < 0.34 * (u + 0.1) then return 0 end
      return 0.84 + 0.16 * math.abs(math.sin(a * 4 + 0.6))
    end)
    ball_label(im, 4, 15, 6, 4)
    mline(im, 7, 13, 11, 18, P.gray); mline(im, 13, 13, 12, 21, P.gray); mline(im, 18, 12, 21, 14, P.gray)
    mline(im, 17, 22, 22, 20, P.gray)
    H.rect(im, 13, 16, 3, 3, P.box_ink); H.px(im, 14, 17, P.gray)
  end
  ol(im)
  if k == 5 then crumb(im, 27, 9, P.red); crumb(im, 29, 22, P.yellow); crumb(im, 24, 25, P.blue) end
end)

-- mailer: padded poly envelope with an orange flap
T("mailer", 32, 24, "flat and floaty", S3, function(im, k)
  local function body(b)
    rrect(b, 3, 4, 26, 16, 2, MAIL)
    mrect(b, 3, 4, 6, 16, YP.orange); mrect(b, 9, 4, 1, 16, YP.orange_d)
    mrect(b, 10, 18, 19, 1, MAIL_D); mrect(b, 27, 4, 1, 16, MAIL_D)
    Y.mono(b, 11, 8, 1, YP.char, YP.orange)
  end
  if k == 3 then
    -- ripped clean across, bubble wrap lining hanging out of the tear
    local b = H.img(32, 24); body(b)
    local function edge(y) return 15.5 + (y - 12) * 0.25 + ((y % 4 < 2) and 1 or -1) end
    local t = warp(b, function(x, y)
      local xs = 16 + (x - 15.5) / 0.9
      local e = edge(y)
      if xs < e - 1.6 then return xs + 1.6, y + 1 - (xs - 3) * 0.12
      elseif xs > e + 1.6 then return xs - 1.6, y - 2 + (xs - 16) * 0.14 end
      return nil
    end)
    for y = 4, 20 do
      local e = math.floor(15.5 + (edge(y) - 16) * 0.9 + 0.5)
      for x = e - 2, e + 2 do
        if not opaque(t, x, y) and y > 5 and y < 19 then
          t:drawPixel(x, y, ((x + y) % 2 == 0) and P.sky_l or P.sky)
        end
      end
    end
    mline(t, 5, 16, 10, 12, MAIL_D); mline(t, 21, 8, 26, 13, MAIL_D); mline(t, 22, 17, 25, 15, MAIL_D)
    for i = 0, 3 do local ty = coltop(t, 28 - i); if ty then clr(t, 28 - i, ty, 1, 4 - i) end end
    ol(t); H.blit(im, t, 0, 0)
    piece(im, { { 26, 2 }, { 29, 3 }, { 28, 6 } }, MAIL)
    crumb(im, 15, 21, P.sky_l); crumb(im, 18, 2, P.sky_l)
    return
  end
  body(im)
  if k == 2 then
    for j = 0, 6 do
      for i = 0, 7 - j do mpx(im, 28 - i, 4 + j, ((i + j) % 2 == 0) and P.sky_l or P.sky) end
    end
    clr(im, 26, 4, 3, 1); clr(im, 28, 5, 1, 2)
    clr(im, 3, 4, 4, 2); clr(im, 3, 6, 2, 1)
    mline(im, 4, 7, 8, 4, YP.orange_d)
    mline(im, 12, 19, 17, 15, MAIL_D); mline(im, 18, 6, 21, 4, MAIL_D); mline(im, 22, 17, 26, 13, MAIL_D)
    denth(im, 14, 19, -1, 6, MAIL_D)
    dentv(im, 3, 11, 1, 5, YP.orange_d)
  end
  ol(im)
end)

-- cold: insulated box that melts away
local function puddle(u, cx, cy, rx, ry, ph)
  for y = 0, 31 do
    for x = 0, 31 do
      local dx, dy = (x - cx) / rx, (y - cy) / ry
      local a = math.atan(dy, dx)
      if dx * dx + dy * dy <= (0.86 + 0.14 * math.sin(a * 5 + ph)) ^ 2 then u:drawPixel(x, y, P.water) end
    end
  end
  mrect(u, cx - rx + 3, cy + 1, 5, 1, P.water_l); mrect(u, cx + 2, cy + ry - 3, 5, 1, P.water_l)
  mrect(u, cx + rx - 8, cy - 2, 4, 1, P.water_l); mrect(u, cx - 3, cy + ry - 2, 4, 1, P.water_d)
end
local function lid(im, pts)
  piece(im, pts, P.blue, function(d)
    H.line(d, pts[1][1], pts[1][2] + 1, pts[2][1], pts[2][2] + 1, P.sky)
    H.line(d, pts[4][1], pts[4][2], pts[3][1], pts[3][2], P.water_d)
  end)
end
T("cold", 32, 32, "melts over time", { "frosty", "sweating", "dripping", "sagging", "puddling", "puddle" }, function(im, k)
  if k <= 3 then
    H.rect(im, 4, 9, 24, 18, ICE)
    H.rect(im, 4, 23, 24, 2, P.sky)
    H.rect(im, 4, 9, 24, 1, ICE_D)
    bmp(im, 13, 13, I_SNOW, P.blue)
    if k <= 2 then
      H.rect(im, 3, 4, 26, 5, P.blue)
      H.rect(im, 3, 4, 26, 1, P.sky); H.rect(im, 3, 8, 26, 1, P.water_d)
    end
    if k == 2 then
      for _, p in ipairs({ { 7, 12 }, { 23, 11 }, { 10, 19 }, { 21, 18 }, { 25, 21 }, { 6, 21 } }) do
        H.px(im, p[1], p[2], P.water); H.px(im, p[1], p[2] + 1, P.water_l)
      end
      H.rect(im, 9, 27, 2, 1, P.water); H.rect(im, 20, 27, 2, 1, P.water)
    elseif k == 3 then
      H.rect(im, 4, 9, 24, 2, P.water_d)
      poly(im, { { 3, 7 }, { 27, 2 }, { 29, 6 }, { 4, 11 } }, P.blue)
      H.line(im, 4, 7, 27, 3, P.sky); H.line(im, 5, 11, 28, 7, P.water_d)
      H.rect(im, 13, 17, 7, 3, ICE); H.px(im, 16, 17, P.blue); H.px(im, 16, 18, P.water); H.px(im, 14, 17, P.water)
      H.rect(im, 7, 12, 1, 9, P.water); H.px(im, 7, 21, P.water_l)
      H.rect(im, 22, 12, 1, 6, P.water); H.px(im, 22, 18, P.water_l)
      H.rect(im, 25, 13, 1, 12, P.water)
      H.rect(im, 4, 25, 24, 2, P.sky)
      H.rect(im, 8, 27, 3, 2, P.water); H.px(im, 9, 29, P.water)
      H.rect(im, 19, 27, 2, 3, P.water)
      H.rect(im, 25, 27, 2, 1, P.water)
      corner(im, 4, 26, 1, -1, 3, ICE_D, P.sky)
      dentv(im, 27, 15, -1, 5, ICE_D)
    end
    ol(im, k <= 2)
  elseif k == 4 then
    loose(im, function(u) puddle(u, 15.5, 25.5, 14, 3.4, 0.4) end)
    loose(im, function(u)
      -- slumped body, wider at the foot
      for y = 15, 26 do
        local w = 9 + (y - 15) * 0.38 + ((y % 3 == 0) and 0.5 or 0)
        H.rect(u, math.floor(15.5 - w), y, math.floor(2 * w), 1, ICE)
      end
      mrect(u, 3, 23, 26, 2, P.sky); mrect(u, 4, 15, 24, 1, P.water_d)
      mrect(u, 14, 18, 1, 3, P.blue); mrect(u, 17, 19, 1, 2, P.blue); mrect(u, 15, 19, 2, 1, P.water)
      mrect(u, 8, 16, 1, 8, P.water); mrect(u, 22, 16, 1, 9, P.water); mrect(u, 25, 19, 1, 6, P.water)
      mrect(u, 11, 20, 1, 5, P.water_l)
    end)
    lid(im, { { 4, 12 }, { 25, 8 }, { 27, 12 }, { 6, 16 } })
  elseif k == 5 then
    loose(im, function(u) puddle(u, 15.5, 19.5, 14.5, 8, 1.0) end)
    loose(im, function(u)
      H.ellipse(u, 15, 17, 8, 3, ICE); mrect(u, 8, 18, 15, 1, P.sky); mrect(u, 9, 19, 13, 1, P.water_l)
    end)
    lid(im, { { 7, 12 }, { 24, 9 }, { 25, 13 }, { 8, 16 } })
    loose(im, function(u) H.rect(u, 22, 20, 3, 3, ICE); H.px(u, 24, 22, ICE_D) end)
  else
    loose(im, function(u) puddle(u, 15.5, 17.5, 14.5, 9, 2.2) end)
    lid(im, { { 6, 14 }, { 25, 13 }, { 25, 17 }, { 6, 18 } })
    H.rect(im, 7, 18, 18, 1, P.water); H.rect(im, 9, 17, 4, 1, P.water_l); H.rect(im, 19, 18, 4, 1, P.water_l)
    H.px(im, 12, 23, P.water_l); H.px(im, 13, 23, P.water_l)
  end
end)

-- heavy: small dense iron box with an anvil mark
local function iron(im)
  H.rect(im, 3, 3, 18, 18, YP.char_l)
  H.rect(im, 3, 3, 18, 2, YP.char); H.rect(im, 3, 19, 18, 2, YP.char)
  H.rect(im, 3, 3, 2, 18, YP.char); H.rect(im, 19, 3, 2, 18, YP.char)
  for _, p in ipairs({ { 6, 6 }, { 17, 6 }, { 6, 17 }, { 17, 17 } }) do H.px(im, p[1], p[2], STEEL) end
  bmp(im, 8, 9, I_ANVIL, P.yellow)
end
local function iron_dents(im)
  H.px(im, 17, 6, YP.char_l)
  mline(im, 6, 14, 10, 10, STEEL); mline(im, 13, 18, 18, 13, STEEL); mline(im, 14, 7, 16, 5, STEEL)
  corner(im, 20, 3, -1, 1, 2, YP.char, YP.black)
  dentv(im, 3, 9, 1, 5, YP.black)
  denth(im, 9, 20, -1, 5, YP.black)
end
local function iron_seam(y) return 11 + ((y % 4 < 2) and 1 or 0) - ((y % 7 == 3) and 1 or 0) end
T("heavy", 24, 24, "dense, barely moves", { "clean", "dented", "cracked", "split", "pieces" }, function(im, k)
  if k <= 3 then
    iron(im)
    if k >= 2 then iron_dents(im) end
    if k == 3 then
      for y = 3, 20 do
        local x = iron_seam(y)
        H.px(im, x, y, DARK); mpx(im, x - 1, y, STEEL_D)
        if y < 9 then H.px(im, x + 1, y, DARK) end
      end
      clr(im, 11, 3, 3, 1); clr(im, 12, 4, 1, 1)
    end
    ol(im, k == 1)
  elseif k == 4 then
    local b = H.img(24, 24); iron(b); iron_dents(b)
    local t = warp(b, function(x, y)
      local xs, ys = 12 + (x - 11.5) / 0.84, 12 + (y - 11.5) / 0.88
      local s = iron_seam(math.floor(ys))
      if x < 11.5 then
        xs = xs + 2 + (ys - 12) * 0.1; ys = ys - 1
        if xs > s then return nil end
      else
        xs = xs - 2 + (ys - 12) * 0.12; ys = ys + 1
        if xs <= s then return nil end
      end
      return xs, ys
    end)
    ol(t); H.blit(im, t, 0, 0)
    crumb(im, 12, 3, YP.char_l)
  else
    local b = H.img(24, 24); iron(b); iron_dents(b)
    local function chunk(pts, ox, oy)
      local t = H.img(24, 24)
      poly(t, pts, YP.char_l)
      for y = 0, 23 do for x = 0, 23 do
        if opaque(t, x, y) and opaque(b, x - ox, y - oy) then t:drawPixel(x, y, b:getPixel(x - ox, y - oy)) end
      end end
      ol(t); H.blit(im, t, 0, 0)
    end
    chunk({ { 2, 3 }, { 9, 2 }, { 10, 8 }, { 4, 11 } }, -1, -1)
    chunk({ { 13, 2 }, { 21, 5 }, { 19, 11 }, { 14, 8 } }, 1, 0)
    chunk({ { 2, 14 }, { 8, 13 }, { 10, 20 }, { 5, 21 } }, -1, 1)
    chunk({ { 13, 13 }, { 20, 14 }, { 21, 19 }, { 14, 21 } }, 1, 1)
    chunk({ { 9, 10 }, { 14, 10 }, { 12, 14 } }, 0, 0)
    crumb(im, 11, 4, YP.char_l); crumb(im, 21, 12, STEEL_D)
  end
end)

-- balloon: gift box hanging from a balloon
local function gift(im, x, y, st)
  H.rect(im, x, y, 18, 12, P.purple)
  H.rect(im, x - 1, y, 20, 3, PURPLE_L)
  H.rect(im, x, y + 3, 18, 1, PURPLE_D)
  H.rect(im, x + 8, y, 2, 12, P.yellow)
  if st == 1 then
    corner(im, x + 17, y, -1, 1, 3, PURPLE_D, PURPLE_D)
    dentv(im, x, y + 5, 1, 5, PURPLE_D)
    denth(im, x + 9, y + 11, -1, 5, PURPLE_D)
    H.rect(im, x + 8, y + 6, 2, 3, PURPLE_D)
  end
end
local function bow(im, x, y)
  H.rect(im, x + 5, y - 3, 3, 3, P.yellow); H.rect(im, x + 10, y - 3, 3, 3, P.yellow)
  H.rect(im, x + 8, y - 2, 2, 2, P.gold_d)
end
local GIFTC = { base = P.purple, m = PURPLE_D, d = PURPLE_D, dd = DARK, under = PURPLE_D }
local function gift_crushed(im, w, h, x, y, cy)
  local b = H.img(w, h); gift(b, x, y, 0); bow(b, x, y)
  return crush(im, b, { kx = w < 32 and 0.95 or 1.1, ky = 0.5, phase = 0.7, cy = cy, cx = x + 8.5, amp = 1, creases = { 0.3, 0.8 }, rip = 1,
    nopeanuts = true, notape = true }, GIFTC)
end
-- stage 1 full .. 5 popped, centred on (cx, cy); returns the knot position
local function balloon(im, cx, cy, k)
  if k == 1 then
    H.ellipse(im, cx, cy, 9, 10, P.red)
    H.rect(im, cx - 1, cy + 11, 3, 1, P.red); H.px(im, cx, cy + 12, P.red_d)
    mline(im, cx - 5, cy - 6, cx - 6, cy - 3, P.white); mpx(im, cx - 4, cy - 7, P.white)
    mline(im, cx + 5, cy + 6, cx + 3, cy + 8, P.red_d)
    return cx, cy + 13
  elseif k == 2 then
    H.ellipse(im, cx, cy + 2, 8, 8, P.red)
    H.rect(im, cx - 1, cy + 11, 3, 1, P.red); H.px(im, cx, cy + 12, P.red_d)
    mline(im, cx - 4, cy - 3, cx - 5, cy, P.white)
    mline(im, cx + 3, cy + 5, cx + 1, cy + 9, P.red_d); mline(im, cx - 3, cy + 6, cx - 2, cy + 9, P.red_d)
    return cx, cy + 13
  elseif k == 3 then
    H.ellipse(im, cx + 2, cy + 5, 6, 6, P.red)
    H.rect(im, cx + 1, cy + 12, 3, 1, P.red)
    mline(im, cx - 2, cy + 2, cx, cy + 7, P.red_d); mline(im, cx + 4, cy, cx + 5, cy + 6, P.red_d)
    mline(im, cx + 1, cy + 8, cx + 3, cy + 10, P.red_d); mpx(im, cx - 1, cy + 1, P.white)
    return cx + 2, cy + 13
  elseif k == 4 then
    H.ellipse(im, cx + 3, cy + 9, 5, 4, P.red)
    H.rect(im, cx - 3, cy + 10, 2, 2, P.red)
    mline(im, cx, cy + 7, cx + 2, cy + 11, P.red_d); mline(im, cx + 4, cy + 6, cx + 6, cy + 11, P.red_d)
    mline(im, cx + 1, cy + 9, cx + 5, cy + 9, P.red_d)
    return cx - 3, cy + 12
  end
end
local function scraps(im, x, y)
  piece(im, { { x, y }, { x + 5, y - 1 }, { x + 6, y + 3 }, { x + 2, y + 4 } }, P.red, function(d)
    H.line(d, x + 1, y + 1, x + 4, y + 3, P.red_d)
  end)
  piece(im, { { x + 6, y + 2 }, { x + 9, y + 3 }, { x + 7, y + 6 } }, P.red_d)
end
T("balloon", 32, 48, "falls slowly", { "full", "soft", "sagging", "drooping", "popped", "crushed" }, function(im, k)
  if k == 6 then
    local x0, y0, x1 = gift_crushed(im, 32, 48, 7, 33, 40)
    scraps(im, 15, y0 - 3)
    for _, p in ipairs({ { 14, y0 - 2 }, { 13, y0 - 1 }, { 12, y0 - 1 }, { 11, y0 }, { 10, y0 + 1 }, { 9, y0 + 1 } }) do
      H.px(im, p[1], p[2], INK)
    end
    crumb(im, 6, y0 - 5, P.red); crumb(im, 26, y0 - 6, P.red)
    return
  end
  local string
  if k == 1 then
    balloon(im, 16, 12, 1)
    string = { { 16, 25 }, { 16, 26 }, { 16, 27 }, { 16, 28 }, { 16, 29 } }
  elseif k == 2 then
    balloon(im, 16, 12, 2)
    string = { { 16, 25 }, { 17, 26 }, { 17, 27 }, { 16, 28 }, { 16, 29 } }
  elseif k == 3 then
    balloon(im, 16, 12, 3)
    string = { { 18, 26 }, { 19, 27 }, { 19, 28 }, { 18, 29 }, { 17, 29 } }
  elseif k == 4 then
    -- flopped onto the lid
    H.ellipse(im, 23, 28, 5, 4, P.red)
    mline(im, 20, 26, 22, 30, P.red_d); mline(im, 24, 25, 26, 30, P.red_d); mline(im, 21, 28, 25, 28, P.red_d)
    string = { { 18, 27 }, { 17, 26 }, { 16, 26 }, { 15, 27 }, { 15, 28 }, { 16, 29 } }
  end
  gift(im, 7, 33, k >= 4 and 1 or 0)
  bow(im, 7, 33)
  ol(im)
  for _, p in ipairs(string or {}) do H.px(im, p[1], p[2], INK) end
  if k == 5 then
    scraps(im, 18, 29)
    for _, p in ipairs({ { 16, 29 }, { 15, 28 }, { 14, 28 }, { 13, 29 }, { 12, 30 }, { 11, 32 }, { 11, 31 }, { 10, 33 },
      { 10, 34 }, { 9, 35 } }) do H.px(im, p[1], p[2], INK) end
    crumb(im, 8, 24, P.red); crumb(im, 25, 22, P.red); crumb(im, 15, 20, P.red_d)
  end
end)
-- the two halves on their own, for a box that tumbles under a balloon that does not
T("balloon_box", 24, 24, "box half of balloon", S3, function(im, k)
  if k == 3 then gift_crushed(im, 24, 24, 3, 9, 14); return end
  gift(im, 3, 9, k == 2 and 1 or 0)
  bow(im, 3, 9)
  ol(im)
end)
T("balloon_balloon", 24, 32, "balloon half, string drawn in engine", { "full", "soft", "sagging", "drooping", "popped" },
  function(im, k)
    if k == 5 then
      scraps(im, 7, 22)
      crumb(im, 5, 12, P.red); crumb(im, 18, 9, P.red); crumb(im, 12, 16, P.red_d); crumb(im, 19, 20, P.red)
      return
    end
    balloon(im, 11, 14, k)
    ol(im)
  end)

-- explosive: red TNT box with hazard stripes
local function star(t, rin, rout, n, c, ph)
  for y = 0, 31 do
    for x = 0, 31 do
      local dx, dy = x - 15.5, y - 15.5
      local a = (math.atan(dy, dx) + math.pi) / (2 * math.pi)
      local kk = math.abs(((a * n + ph) % 1) * 2 - 1)
      if math.sqrt(dx * dx + dy * dy) <= rin + (rout - rin) * kk then t:drawPixel(x, y, c) end
    end
  end
end
local function tnt(im)
  H.rect(im, 4, 4, 24, 24, P.xred)
  for y = 4, 27 do
    if y <= 8 or y >= 23 then
      for x = 4, 27 do im:drawPixel(x, y, ((x + y) // 3) % 2 == 0 and P.ink or P.yellow) end
    end
  end
  H.rect(im, 4, 9, 24, 1, P.red_d); H.rect(im, 4, 22, 24, 1, P.red_d)
  H.text(im, "TNT", 16, 12, P.white, { align = "center" })
end
local function spark(im, x, y, big)
  loose(im, function(u)
    if big then
      bmp(u, x - 3, y - 3, { "...#...", ".#.#.#.", "..###..", "#######", "..###..", ".#.#.#.", "...#..." }, P.yellow)
      H.rect(u, x - 1, y - 1, 3, 3, P.white); H.px(u, x - 2, y, P.orange); H.px(u, x + 2, y, P.orange)
    else
      bmp(u, x - 1, y - 1, { ".#.", "###", ".#." }, P.yellow); H.px(u, x, y, P.white)
    end
  end)
end
T("explosive", 32, 32, "do not kick hard", { "clean", "scuffed", "fuse_lit", "bulging", "blast", "scorch" }, function(im, k)
  local FUSE = { { 22, 3 }, { 23, 2 }, { 24, 2 }, { 25, 3 }, { 26, 3 }, { 27, 2 } }
  if k == 1 then
    tnt(im); ol(im, true)
  elseif k == 2 or k == 3 then
    tnt(im)
    scuff(im, 8, 19, P.red_d, 2); scuff(im, 21, 14, P.red_d, 2); scuff(im, 12, 7, P.xred, 2)
    denth(im, 9, 27, -1, 5, P.red_d)
    corner(im, 4, 4, 1, 1, 2, P.red_d, SOOT_L)
    if k == 3 then
      wear(im, 4, 4, 24, 24, 1, P.red_d, SOOT_L, SOOT)
      H.ellipse(im, 9, 20, 3, 2, SOOT); H.ellipse(im, 9, 20, 1, 1, SOOT_L)
    end
    ol(im)
    if k == 2 then for _, p in ipairs(FUSE) do H.px(im, p[1], p[2], INK) end
    else
      for i = 1, 4 do H.px(im, FUSE[i][1] - (k == 3 and 1 or 0), FUSE[i][2] + 1, INK) end
      spark(im, 26, 4, false)
    end
  elseif k == 4 then
    -- swollen, glowing through the cracks, fuse nearly gone
    local b = H.img(32, 32); tnt(b)
    local t = warp(b, function(x, y)
      local dx, dy = x - 15.5, y - 15.5
      local sx = 1.02 + 0.14 * (1 - math.min(1, (dy / 12.5) ^ 2))
      local sy = 1.02 + 0.14 * (1 - math.min(1, (dx / 12.5) ^ 2))
      return 15.5 + dx / sx, 15.5 + dy / sy
    end)
    for y = 0, 31 do
      for x = 0, 31 do
        local r = math.sqrt((x - 15.5) ^ 2 + (y - 15.5) ^ 2)
        if opaque(t, x, y) and t:getPixel(x, y) == P.xred then
          if r < 6 then t:drawPixel(x, y, P.orange) elseif r < 9 and (x + y) % 2 == 0 then t:drawPixel(x, y, P.orange) end
        end
      end
    end
    for _, c in ipairs({ { { 15, 15 }, { 11, 12 }, { 9, 8 }, { 5, 6 } }, { { 16, 16 }, { 21, 13 }, { 23, 9 }, { 27, 7 } },
      { { 15, 16 }, { 12, 21 }, { 8, 23 }, { 6, 27 } }, { { 16, 16 }, { 20, 20 }, { 24, 22 }, { 27, 26 } },
      { { 16, 15 }, { 17, 9 }, { 15, 4 } }, { { 16, 17 }, { 15, 23 }, { 17, 28 } } }) do
      crack(t, c, P.yellow)
    end
    H.rect(t, 14, 14, 4, 4, P.white); mrect(t, 13, 15, 6, 2, P.yellow)
    ol(t); H.blit(im, t, 0, 0)
    spark(im, 26, 5, true)
  elseif k == 5 then
    star(im, 8, 13.5, 9, SOOT, 0)
    ol(im)
    star(im, 6, 11.5, 9, P.xred, 0.5)
    star(im, 4.5, 9.5, 9, P.orange, 0)
    star(im, 2.5, 7, 9, P.yellow, 0.5)
    star(im, 1.5, 4, 9, P.white, 0)
    crumb(im, 3, 4, P.xred); crumb(im, 28, 5, P.yellow); crumb(im, 4, 27, P.yellow); crumb(im, 28, 27, P.xred)
  else
    -- what is left: a scorch mark, charred scraps of the box, a few embers
    star(im, 6.5, 12, 11, SOOT, 0.3)
    ol(im)
    star(im, 3.5, 8, 11, SOOT_L, 0.8)
    star(im, 1.5, 4, 7, SOOT, 0)
    local b = H.img(32, 32); tnt(b)
    local function scrap(pts, ox, oy)
      local t = H.img(32, 32)
      poly(t, pts, P.red_d)
      for y = 0, 31 do for x = 0, 31 do
        if opaque(t, x, y) and opaque(b, x - ox, y - oy) then
          local p = b:getPixel(x - ox, y - oy)
          t:drawPixel(x, y, p == P.xred and P.red_d or (p == P.yellow and P.gold_d or p))
        end
      end end
      mpx(t, pts[1][1], pts[1][2], SOOT); mpx(t, pts[3][1], pts[3][2], SOOT)
      ol(t); H.blit(im, t, 0, 0)
    end
    scrap({ { 3, 5 }, { 10, 3 }, { 11, 8 }, { 5, 10 } }, -1, -1)
    scrap({ { 22, 21 }, { 29, 22 }, { 27, 28 }, { 21, 26 } }, 1, 0)
    scrap({ { 21, 5 }, { 27, 4 }, { 28, 9 }, { 23, 10 } }, 2, -8)
    scrap({ { 4, 22 }, { 9, 21 }, { 10, 27 }, { 5, 27 } }, -4, 9)
    for _, p in ipairs({ { 13, 13 }, { 18, 17 }, { 15, 20 }, { 20, 12 }, { 11, 18 } }) do H.px(im, p[1], p[2], P.orange) end
    H.px(im, 16, 15, P.yellow)
    for _, p in ipairs({ { 14, 3 }, { 15, 2 }, { 15, 1 }, { 18, 4 }, { 19, 3 }, { 19, 2 } }) do H.px(im, p[1], p[2], P.gray) end
  end
end)

-- live animal: pet carrier; whatever is inside gets out unharmed
local function carrier(im, door)
  rrect(im, 4, 8, 40, 20, 3, TEAL)
  mrect(im, 4, 8, 40, 1, TEAL_L)
  mrect(im, 4, 22, 40, 6, TEAL_D); mrect(im, 4, 22, 40, 1, TEAL_DD)
  H.rect(im, 18, 4, 12, 2, TEAL_D); H.rect(im, 18, 6, 2, 2, TEAL_D); H.rect(im, 28, 6, 2, 2, TEAL_D)
  H.rect(im, 7, 10, 20, 12, TEAL_L)
  H.rect(im, 8, 11, 18, 10, DARK)
  if door then H.rect(im, 27, 15, 2, 3, P.gold) end
  for _, p in ipairs({ { 32, 12 }, { 36, 12 }, { 40, 12 }, { 32, 17 }, { 36, 17 }, { 40, 17 } }) do
    H.rect(im, p[1], p[2], 2, 2, DARK)
  end
end
local function door_hanging(im)
  loose(im, function(u)
    poly(u, { { 5, 19 }, { 9, 18 }, { 15, 28 }, { 10, 29 } }, STEEL_D)
    for i = 0, 3 do mline(u, 6 + i, 19 + i * 2, 10 + i, 20 + i * 2, STEEL_L) end
  end)
end
T("animal", 48, 32, "wriggles, steers itself", { "calm", "worried", "paw_out", "escaping", "empty", "wrecked" },
  function(im, k)
    if k == 6 then
      -- flattened, empty shell; door and handle lying loose
      local b = H.img(48, 32); carrier(b, false)
      clr(b, 18, 4, 12, 4)
      local t = pancake(b, { kx = 1.0, ky = 0.55, phase = 1.3, amp = 1.6, freq = 0.35, cy = 18 })
      local x0, y0, x1, y1 = bounds(t)
      for _, f in ipairs({ 0.2, 0.55, 0.8 }) do
        local x = math.floor(x0 + (x1 - x0) * f)
        for y = y0, y1 do mpx(t, x + ((y % 3 == 0) and 1 or 0), y, TEAL_DD) end
      end
      for i = -3, 3 do local ty = coltop(t, 34 + i); if ty then clr(t, 34 + i, ty, 1, 4 - math.abs(i)) end end
      for i = 0, 4 do local ty = coltop(t, x1 - i); if ty then clr(t, x1 - i, ty, 1, 5 - i) end end
      ol(t); H.blit(im, t, 0, 0)
      loose(im, function(u)
        poly(u, { { 3, 24 }, { 15, 22 }, { 16, 28 }, { 4, 30 } }, STEEL_D)
        for i = 0, 3 do mline(u, 5 + i * 3, 23, 6 + i * 3, 29, STEEL_L) end
      end)
      loose(im, function(u) H.rect(u, 30, 4, 9, 2, TEAL_D); H.rect(u, 30, 6, 2, 2, TEAL_D) end)
      piece(im, { { 41, 5 }, { 45, 6 }, { 43, 9 } }, TEAL)
      return
    end
    carrier(im, k <= 3)
    if k == 1 then
      H.rect(im, 12, 14, 3, 3, P.white); H.rect(im, 18, 14, 3, 3, P.white)
      H.px(im, 13, 15, P.ink); H.px(im, 19, 15, P.ink)
      for _, x in ipairs({ 10, 16, 22 }) do H.rect(im, x, 11, 1, 10, STEEL) end
    elseif k == 2 then
      H.rect(im, 11, 13, 4, 4, P.white); H.rect(im, 18, 13, 4, 4, P.white)
      H.px(im, 13, 15, P.ink); H.px(im, 20, 15, P.ink)
      for _, x in ipairs({ 10, 16, 22 }) do H.rect(im, x, 11, 1, 10, STEEL) end
      scuff(im, 30, 12, TEAL_D, 2); scuff(im, 37, 25, TEAL_DD, 2)
      denth(im, 32, 8, 1, 5, TEAL_DD)
    elseif k == 3 then
      H.rect(im, 11, 13, 4, 4, P.white); H.rect(im, 18, 13, 4, 4, P.white)
      H.px(im, 13, 14, P.ink); H.px(im, 20, 14, P.ink)
      H.rect(im, 10, 11, 1, 10, STEEL)
      H.rect(im, 16, 11, 1, 3, STEEL); H.rect(im, 17, 14, 1, 4, STEEL); H.rect(im, 16, 18, 1, 3, STEEL)
      H.rect(im, 22, 11, 1, 2, STEEL); H.rect(im, 23, 13, 1, 3, STEEL)
      crack(im, { { 43, 14 }, { 39, 15 }, { 37, 19 }, { 33, 20 }, { 31, 24 } }, TEAL_DD)
      denth(im, 32, 8, 1, 6, TEAL_DD)
      denth(im, 10, 27, -1, 6, TEAL_DD)
      scuff(im, 30, 12, TEAL_D, 2)
    else
      crack(im, { { 43, 14 }, { 39, 15 }, { 37, 19 }, { 33, 20 }, { 31, 24 } }, TEAL_DD)
      denth(im, 32, 8, 1, 6, TEAL_DD)
      denth(im, 30, 27, -1, 6, TEAL_DD)
      corner(im, 43, 27, -1, -1, 3, TEAL_D, TEAL_DD)
    end
    ol(im)
    if k == 3 then
      -- paw reaching out between the bent bars
      loose(im, function(u) H.rect(u, 22, 17, 7, 3, FUR); H.rect(u, 27, 16, 3, 5, FUR); H.px(u, 29, 17, P.white); H.px(u, 29, 19, P.white) end)
    elseif k == 4 then
      door_hanging(im)
      loose(im, function(u) -- half way out and pleased about it
        H.rect(u, 12, 15, 11, 6, FUR)
        H.ellipse(u, 17, 12, 6, 4, FUR)
        poly(u, { { 11, 10 }, { 12, 5 }, { 15, 8 } }, FUR); poly(u, { { 19, 8 }, { 22, 5 }, { 23, 10 } }, FUR)
        H.rect(u, 11, 20, 4, 3, FUR); H.rect(u, 19, 20, 4, 3, FUR)
        mline(u, 15, 16, 16, 19, FUR_D); mline(u, 19, 16, 18, 19, FUR_D)
        H.rect(u, 14, 11, 2, 2, P.white); H.rect(u, 19, 11, 2, 2, P.white)
        H.px(u, 15, 11, P.ink); H.px(u, 20, 11, P.ink)
        H.px(u, 17, 13, P.cap); H.px(u, 16, 14, P.ink); H.px(u, 18, 14, P.ink)
        H.px(u, 11, 22, P.white); H.px(u, 13, 22, P.white); H.px(u, 19, 22, P.white); H.px(u, 21, 22, P.white)
        H.px(u, 12, 7, P.cap); H.px(u, 21, 7, P.cap)
      end)
    elseif k == 5 then
      door_hanging(im)
      bmp(im, 22, 1, I_PAW, P.base_d); bmp(im, 30, 0 + 1, I_PAW, P.base_d)
      H.px(im, 12, 20, FUR); H.px(im, 13, 19, FUR); H.px(im, 14, 20, FUR)
    end
  end)

------------------------------------------------------------------ build + save

local function edge_px(im)
  local n = 0
  for x = 0, im.width - 1 do
    if opaque(im, x, 0) or opaque(im, x, im.height - 1) then n = n + 1 end
  end
  for y = 0, im.height - 1 do
    if opaque(im, 0, y) or opaque(im, im.width - 1, y) then n = n + 1 end
  end
  return n
end

local function save(name, frames, names)
  local fw, fh = frames[1].width, frames[1].height
  local spr = Sprite(fw, fh, ColorMode.RGB)
  spr.layers[1].name = "Art"
  for i, im in ipairs(frames) do
    if i > 1 then spr:newEmptyFrame() end
    spr:newCel(spr.layers[1], spr.frames[i], im, Point(0, 0))
  end
  for i, n in ipairs(names) do
    local tag = spr:newTag(i, i)
    tag.name = n
  end
  spr:saveAs(OUT .. name .. ".aseprite")
  spr:close()
  local strip = H.img(fw * #frames, fh)
  for i, im in ipairs(frames) do H.blit(strip, im, (i - 1) * fw, 0) end
  strip:saveAs(OUT .. name .. ".png")
  local warn = ""
  for i, im in ipairs(frames) do
    if edge_px(im) > 0 then warn = warn .. " EDGE:" .. names[i] end
  end
  print("saved " .. name .. " strip " .. fw * #frames .. "x" .. fh .. " (" .. #frames .. " frames)" .. warn)
end

for _, b in ipairs(BASIC) do
  b.frames = box_frames(b)
  save("box_" .. b.code .. "_" .. b.name, b.frames, BOXSTAGES)
end
for _, b in ipairs(SILLY) do
  b.frames = box_frames(b)
  save("silly_" .. b.name, b.frames, BOXSTAGES)
end
for _, t in ipairs(TYPES) do
  t.frames = {}
  for k = 1, #t.stages do
    local im = H.img(t.fw, t.fh)
    t.fn(im, k)
    if k == #t.stages and edge_px(im) > 0 then im = recentre(im) end
    t.frames[k] = im
  end
  save("type_" .. t.name, t.frames, t.stages)
end
------------------------------------------------------------------ previews

local TS = Image { fromFile = H.ROOT .. "assets/tilesets/hotel_tileset.png" }
local PLAYER = Image { fromFile = H.SPR .. "player/player_idle.png" }
local CUR = Image { fromFile = H.SPR .. "package/package_states.png" }
local ROW, FLOOR = 96, 64

local function crop(src, sx, sy, sw, sh)
  local t = H.img(sw, sh)
  H.blit(t, src, 0, 0, sx, sy, sw, sh)
  return t
end

-- Nearest-neighbour rotation about the image centre.
local function rot(src, deg)
  local n = math.ceil(math.sqrt(src.width ^ 2 + src.height ^ 2))
  if deg % 90 == 0 then n = math.max(src.width, src.height) end
  local out = H.img(n, n)
  local a = math.rad(deg)
  local c, s = math.cos(a), math.sin(a)
  local ox, oy, cx, cy = (n - 1) / 2, (n - 1) / 2, (src.width - 1) / 2, (src.height - 1) / 2
  for y = 0, n - 1 do
    for x = 0, n - 1 do
      local dx, dy = x - ox, y - oy
      local sx = math.floor(c * dx + s * dy + cx + 0.5)
      local sy = math.floor(-s * dx + c * dy + cy + 0.5)
      if sx >= 0 and sy >= 0 and sx < src.width and sy < src.height then
        local p = src:getPixel(sx, sy)
        if pc.rgbaA(p) > 0 then out:drawPixel(x, y, p) end
      end
    end
  end
  return out
end

-- Draw im with its lowest opaque row resting on floorY, centred on cx.
local function stand(dst, im, cx, floorY)
  local low = im.height - 1
  for j = im.height - 1, 0, -1 do
    local hit = false
    for i = 0, im.width - 1 do if opaque(im, i, j) then hit = true; break end end
    if hit then low = j; break end
  end
  H.blit(dst, im, cx - im.width // 2, floorY - (low + 1))
end

local function scaled(im, s)
  local big = Image(im.width * s, im.height * s, ColorMode.RGB)
  for y = 0, im.height - 1 do
    for x = 0, im.width - 1 do
      local p = im:getPixel(x, y)
      if pc.rgbaA(p) > 0 then big:clear(Rectangle(x * s, y * s, s, s), p) end
    end
  end
  return big
end

local function hallway(im, y, w)
  for tx = 0, w - 1, 32 do
    H.blit(im, TS, tx, y, 0, 0, 32, 32)
    H.blit(im, TS, tx, y + 32, 64, 0, 32, 32)
    H.blit(im, TS, tx, y + 64, 96, 0, 32, 32)
  end
end

-- blocks: { title, tagcol, note, cells = { { img, caption }, ... } }, flowed into rows of width W.
-- Returns the 1x canvas.
local function sheet(W, blocks)
  local rows, cur, x = {}, {}, 44
  for _, b in ipairs(blocks) do
    local w = 0
    for _, c in ipairs(b.cells) do w = w + c[1].width + 2 end
    b.w = math.max(w, H.textw(b.title) + 8) + 10
    if (x + b.w > W or b.newrow) and #cur > 0 then rows[#rows + 1] = cur; cur, x = {}, 44 end
    b.x = x
    cur[#cur + 1] = b
    x = x + b.w
  end
  rows[#rows + 1] = cur
  local im = H.img(W, ROW * #rows)
  for r, row in ipairs(rows) do
    local y = (r - 1) * ROW
    hallway(im, y, W)
    local floorY = y + FLOOR
    H.blit(im, PLAYER, -2, floorY - 64)
    for _, b in ipairs(row) do
      local cx = b.x
      for i, c in ipairs(b.cells) do
        local mid = cx + (c[1].width + 2) // 2
        stand(im, c[1], mid, floorY)
        local lines = c[1].width < 24 and 3 or 2
        H.text(im, c[2], mid, floorY + (lines == 3 and 3 or 6) + ((i - 1) % lines) * (lines == 3 and 9 or 11), P.cream,
          { align = "center" })
        cx = cx + c[1].width + 2
      end
      H.tag(im, b.title, b.x + (cx - b.x) // 2, y + 3, P.white, b.tagcol or P.ui, "center")
      if b.note then H.text(im, b.note, cx + 10, y + 5, P.base_d) end
    end
  end
  return im
end

local function save_preview(big, name)
  big:saveAs(REVIEW .. name)
  print("preview " .. name .. " " .. big.width .. "x" .. big.height)
end

local function box_block(b, prefix)
  local f = b.frames
  return { title = prefix .. " " .. b.name:upper(), note = b.note, cells = {
    { f[1], "NEW" }, { f[2], "HIT" }, { f[3], "BUST" },
  } }
end

local CURF = { crop(CUR, 0, 0, 32, 32), crop(CUR, 32, 0, 32, 32), crop(CUR, 64, 0, 32, 32) }

do
  local blocks = { { title = "CURRENT", tagcol = P.xred, cells = { { CURF[1], "NEW" }, { CURF[2], "HIT" }, { CURF[3], "BUST" } } } }
  for _, b in ipairs(BASIC) do
    local bl = box_block(b, b.code:upper())
    bl.note = nil
    blocks[#blocks + 1] = bl
  end
  local big = scaled(sheet(608, blocks), 4)
  -- true 1x strip underneath: every box at game size, no scaling
  local strip = H.img(big.width, 112)
  H.rect(strip, 0, 0, big.width, 16, P.ui)
  H.text(strip, "TRUE 1X, NO SCALING: NEW / HIT / BUST FOR EACH BOX, THEN ALL BUSTS", 8, 1, P.white, { s = 2 })
  hallway(strip, 16, big.width)
  local floorY = 16 + FLOOR
  H.blit(strip, PLAYER, 4, floorY - 64)
  local sets = { CURF }
  for _, b in ipairs(BASIC) do sets[#sets + 1] = b.frames end
  for _, b in ipairs(SILLY) do sets[#sets + 1] = b.frames end
  local x = 80
  for _, f in ipairs(sets) do
    for i = 1, 3 do stand(strip, f[i], x, floorY); x = x + 40 end
    x = x + 24
  end
  x = x + 40
  H.blit(strip, PLAYER, x - 70, floorY - 64)
  for _, f in ipairs(sets) do stand(strip, f[3], x, floorY); x = x + 44 end
  local out = Image(big.width, big.height + strip.height, ColorMode.RGB)
  out:drawImage(big, Point(0, 0))
  out:drawImage(strip, Point(0, big.height))
  save_preview(out, "options_packages_basic.png")
end
do
  local blocks = {}
  for _, b in ipairs(SILLY) do
    local bl = box_block(b, b.code:upper())
    bl.newrow = true
    blocks[#blocks + 1] = bl
  end
  save_preview(scaled(sheet(608, blocks), 4), "options_packages_silly.png")
end
do
  local blocks = {}
  for _, t in ipairs(TYPES) do
    local cells = {}
    for i, im in ipairs(t.frames) do cells[i] = { im, (t.stages[i]:gsub("_", " ")):upper() } end
    blocks[#blocks + 1] = { title = t.name:upper():gsub("_", " ") .. " " .. t.fw .. "X" .. t.fh, cells = cells }
  end
  save_preview(scaled(sheet(608, blocks), 4), "options_packages_types.png")
end
