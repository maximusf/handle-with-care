-- UI kit theme OPTIONS (round 2): several full kits with the same file set and frame
-- layout as assets/ui/, one folder per theme under docs/art-options/ui/.
-- Per theme: button (4 x 48x20), panel, panel_alt (24x24), slider_track,
-- slider_fill (32x8), slider_grabber (2 x 8x12), checkbox (2 x 12x12),
-- keycap (16x16), mouse (3 x 12x16), plus optional extra_*.png decorations.
-- Multi-frame assets get a tagged .aseprite and a horizontal strip .png.
-- Review mocks and a comparison sheet go to docs/art-review/.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local pc = app.pixelColor
local c = H.c
local OUT = H.ROOT .. "docs/art-options/ui/"
local REVIEW = H.ROOT .. "docs/art-review/"
app.fs.makeAllDirectories(OUT)
app.fs.makeAllDirectories(REVIEW)

------------------------------------------------------------------ helpers
-- Corner insets per row for small pixel radii.
local INS = { [0] = {}, { 1 }, { 2, 1 }, { 3, 1, 1 }, { 4, 2, 1, 1 } }

local function rr(im, x, y, w, h, r, col)
  local ins = INS[r] or {}
  for j = 0, h - 1 do
    local d = ins[math.min(j, h - 1 - j) + 1] or 0
    H.rect(im, x + d, y + j, w - 2 * d, 1, col)
  end
end

local function rbox(im, x, y, w, h, r, fill, line, t)
  t = t or 1
  rr(im, x, y, w, h, r, line)
  rr(im, x + t, y + t, w - 2 * t, h - 2 * t, math.max(0, r - t), fill)
end

-- Same pixel in all four corners (mirrored).
local function m4(im, x, y, col)
  local w, h = im.width, im.height
  for _, p in ipairs({ { x, y }, { w - 1 - x, y }, { x, h - 1 - y }, { w - 1 - x, h - 1 - y } }) do
    im:drawPixel(p[1], p[2], col)
  end
end

local function put(dst, src, x, y, s) H.blit(dst, src, x, y, 0, 0, src.width, src.height, false, s or 1) end

local function frame(w, h, body, y)
  local im = H.img(w, h)
  put(im, body, 0, y or 0)
  return im
end

local function recolor(im, from, to, x0, y0, x1, y1)
  for y = y0, y1 do for x = x0, x1 do
    if im:getPixel(x, y) == from then im:drawPixel(x, y, to) end
  end end
end

local function check(im, ox, oy, col)
  local pts = { { 0, 3 }, { 1, 4 }, { 2, 5 }, { 3, 4 }, { 4, 3 }, { 5, 2 }, { 6, 1 }, { 7, 0 } }
  for _, p in ipairs(pts) do H.rect(im, ox + p[1], oy + p[2], 1, 2, col) end
end

local function mk_key(face, lip, line, r, hi)
  return function()
    local im = H.img(16, 16)
    rbox(im, 0, 0, 16, 16, r, face, line)
    recolor(im, face, lip, 0, 12, 15, 15)
    if hi then H.rect(im, 4, 1, 8, 1, hi) end
    return im
  end
end

-- which: 1 left lit, 2 right lit, 3 none
local function mk_mouse(body, btn, line, lit, r)
  return function(which)
    local im = H.img(12, 16)
    rbox(im, 0, 0, 12, 16, r or 3, body, line)
    H.rect(im, 1, 8, 10, 1, line)
    recolor(im, body, which == 1 and lit or btn, 1, 1, 4, 7)
    recolor(im, body, which == 2 and lit or btn, 7, 1, 10, 7)
    H.rect(im, 5, 1, 2, 7, body)
    H.rect(im, 5, 2, 2, 4, line)
    return im
  end
end

-- Stretch src like a Godot StyleBoxTexture. sp.m = fixed margins {l,t,r,b};
-- the centre is stretched, or repeated on an axis when sp.tx / sp.ty is set
-- (axis stretch TILE; the value is the pattern period in px).
local function nine(dst, src, x, y, w, h, sp)
  local m = sp.m
  local sw, sh = src.width, src.height
  local function map(d, n, sn, a, b, tile)
    if d < a then return d end
    if d >= n - b then return sn - (n - d) end
    local span = sn - a - b
    if tile then return a + (d - a) % span end
    return a + ((d - a) * span) // (n - a - b)
  end
  for j = 0, h - 1 do
    for i = 0, w - 1 do
      local p = src:getPixel(map(i, w, sw, m[1], m[3], sp.tx), map(j, h, sh, m[2], m[4], sp.ty))
      if pc.rgbaA(p) > 0 then H.px(dst, x + i, y + j, p) end
    end
  end
end

-- Nine-patch safety: the middle columns must be constant along x in every
-- row (or repeat with period sp.tx when that axis tiles), and with vert the
-- middle rows likewise along y. Returns the number of offending pixels.
local function check9(im, sp, vert)
  local m, bad = sp.m, 0
  for y = 0, im.height - 1 do
    for x = m[1], im.width - m[3] - 1 do
      local rx = sp.tx and (x - sp.tx) or m[1]
      if rx >= m[1] and im:getPixel(x, y) ~= im:getPixel(rx, y) then bad = bad + 1 end
    end
  end
  if vert then
    for x = 0, im.width - 1 do
      for y = m[2], im.height - m[4] - 1 do
        local ry = sp.ty and (y - sp.ty) or m[2]
        if ry >= m[2] and im:getPixel(x, y) ~= im:getPixel(x, ry) then bad = bad + 1 end
      end
    end
  end
  return bad
end

-- Corrugated board seen edge-on: a zigzag of fluting, 3 rows, period 4.
-- Phase follows absolute x so the pattern tiles across a nine-patch.
local function flute(im, x, y, w, paper, gap)
  for i = x, x + w - 1 do
    local k = i % 4
    H.px(im, i, y, k == 1 and paper or gap)
    H.px(im, i, y + 1, (k == 0 or k == 2) and paper or gap)
    H.px(im, i, y + 2, k == 3 and paper or gap)
  end
end

-- A sheet of board face-on with its cut edge along the bottom.
-- M: face, hi, lo (liner line), paper (flute, default hi), deep (gaps), ink.
-- o.fh face rows (default 11), o.flat crushed edge, o.dbl double wall.
local function slab(w, M, o)
  o = o or {}
  local fh = o.fh or 11
  local eh = o.flat and 1 or (o.dbl and 7 or 3)
  local b = H.img(w, fh + eh + 3)
  H.rect(b, 0, 0, w, b.height, M.ink)
  H.rect(b, 1, 1, w - 2, fh, M.face)
  H.rect(b, 1, 1, w - 2, 1, M.hi)
  H.rect(b, 1, fh + 1, w - 2, 1, M.lo)
  if o.flat then
    H.rect(b, 1, fh + 2, w - 2, 1, M.deep)
  else
    flute(b, 1, fh + 2, w - 2, M.paper or M.hi, M.deep)
    if o.dbl then
      H.rect(b, 1, fh + 5, w - 2, 1, M.lo)
      flute(b, 1, fh + 6, w - 2, M.paper or M.hi, M.deep)
    end
  end
  return b
end

-- Key cut from board: face on top, fluted cut edge as the lip.
local function mk_fkey(M)
  return function()
    local im = H.img(16, 16)
    H.box(im, 0, 0, 16, 16, M.face, M.ink)
    H.rect(im, 1, 1, 14, 1, M.hi)
    H.rect(im, 1, 11, 14, 1, M.lo)
    flute(im, 1, 12, 14, M.paper or M.hi, M.deep)
    return im
  end
end

-- Roll of tape seen side-on, as a slider knob.
local function mk_roll(ring, core, hole, line, hot_ring, hot_core)
  return function(hot)
    local im = H.img(8, 12)
    rbox(im, 0, 2, 8, 8, 3, hot and hot_ring or ring, line)
    rbox(im, 2, 4, 4, 4, 1, hole, hot and hot_core or core)
    return im
  end
end

local STAPLE, STAPLE_D = c("dde1e6"), c("5f646c")
local function staple(im, x, y, under)
  H.rect(im, x, y, 4, 1, STAPLE)
  im:drawPixel(x, y, STAPLE_D); im:drawPixel(x + 3, y, STAPLE_D)
  if under then H.rect(im, x, y + 1, 4, 1, under) end
end

-- "This way up" arrow, 5 wide and 7 tall with its base line.
local function uparrow(im, x, y, col)
  im:drawPixel(x + 2, y, col)
  H.rect(im, x + 1, y + 1, 3, 1, col)
  H.rect(im, x, y + 2, 5, 1, col)
  H.rect(im, x + 2, y + 3, 1, 3, col)
  H.rect(im, x, y + 6, 5, 1, col)
end

local KRAFT = { face = P.card, hi = c("f6cc86"), mid = P.card_m, lo = P.card_d, deep = P.card_dd, ink = P.box_ink }
local GREY = { face = P.concrete, hi = P.concrete_l, mid = P.concrete_d, lo = P.concrete_d, deep = P.asphalt, ink = P.asphalt_d }
local function strip(frames)
  local w, h = frames[1].width, frames[1].height
  local im = H.img(w * #frames, h)
  for i, f in ipairs(frames) do put(im, f, (i - 1) * w, 0) end
  return im
end

local function save_frames(dir, name, frames, tags)
  local w, h = frames[1].width, frames[1].height
  if #frames == 1 then frames[1]:saveAs(dir .. name .. ".png"); return end
  local spr = Sprite(w, h, ColorMode.RGB)
  local layer = spr.layers[1]
  layer.name = "Art"
  for i, im in ipairs(frames) do
    if i > 1 then spr:newEmptyFrame() end
    spr:newCel(layer, i, im, Point(0, 0))
  end
  for i, t in ipairs(tags) do
    local tag = spr:newTag(i, i); tag.name = t
  end
  spr:saveAs(dir .. name .. ".aseprite")
  spr:close()
  strip(frames):saveAs(dir .. name .. ".png")
end

local M4 = { 4, 4, 4, 4 }
local THEMES = {}

------------------------------------------------------------------ A: cardboard
do
  local TAPE_D = c("c4b596")
  local HOT = c("ffe7ad")
  local function body(fill, hi, lip, tape, tape_d, line, hi_h)
    local b = H.img(48, 18)
    H.box(b, 0, 0, 48, 18, fill, line)
    H.rect(b, 1, 1, 46, hi_h or 2, hi)
    H.rect(b, 1, 16, 46, 1, lip)
    -- packing tape wrapped round both ends
    H.rect(b, 1, 1, 3, 16, tape); H.rect(b, 44, 1, 3, 16, tape)
    H.rect(b, 3, 1, 1, 16, tape_d); H.rect(b, 44, 1, 1, 16, tape_d)
    return b
  end
  THEMES[#THEMES + 1] = {
    code = "A", name = "CARDBOARD", kept = true, dir = "a_cardboard",
    button = function(st)
      local im = H.img(48, 20)
      if st == "pressed" then
        put(im, body(P.card_m, P.card_dd, P.card, TAPE_D, P.cap, P.ink, 1), 0, 2)
      elseif st == "hover" then
        H.rect(im, 1, 18, 47, 2, P.ink)
        put(im, body(HOT, P.white, P.card, P.red, P.red_d, P.ink), 0, 0)
      elseif st == "disabled" then
        H.rect(im, 1, 19, 47, 1, P.asphalt_d)
        put(im, body(P.concrete, P.concrete_l, P.concrete_d, P.concrete_l, P.concrete_d, P.asphalt_d), 0, 1)
      else
        H.rect(im, 1, 19, 47, 1, P.ink)
        put(im, body(P.card, P.cream, P.card_m, P.tape, TAPE_D, P.ink), 0, 1)
      end
      return im
    end,
    btn_dy = { normal = 1, hover = 0, pressed = 2, disabled = 1 },
    panel = function()
      local im = H.img(24, 24)
      H.rect(im, 2, 2, 22, 22, P.ink)
      H.box(im, 0, 0, 22, 22, P.card_m, P.ink)
      H.rect(im, 1, 1, 20, 1, P.card); H.rect(im, 1, 1, 1, 20, P.card)
      H.rect(im, 1, 20, 20, 1, P.card_d); H.rect(im, 20, 1, 1, 20, P.card_d)
      H.rect(im, 2, 2, 18, 18, P.ui)
      H.rect(im, 2, 2, 18, 1, P.ui_l)
      return im
    end,
    panel_alt = function()
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, P.cream, P.card_dd)
      H.rect(im, 1, 1, 22, 1, P.tape); H.rect(im, 1, 1, 1, 22, P.tape)
      return im
    end,
    track = function()
      local im = H.img(32, 8)
      H.box(im, 0, 2, 32, 4, P.ui_ll, P.ink); H.rect(im, 1, 3, 30, 1, P.ui_l)
      return im
    end,
    fill = function()
      local im = H.img(32, 8)
      H.box(im, 0, 2, 32, 4, P.card_m, P.ink); H.rect(im, 1, 3, 30, 1, P.card)
      return im
    end,
    grabber = function(hot)
      local im = H.img(8, 12)
      H.box(im, 0, 0, 8, 12, hot and HOT or P.card, P.ink)
      H.rect(im, 6, 1, 1, 10, hot and P.card or P.card_m)
      H.rect(im, 1, 10, 6, 1, hot and P.card or P.card_m)
      H.rect(im, 3, 1, 2, 10, hot and P.red or P.tape)
      return im
    end,
    checkbox = function(on)
      local im = H.img(12, 12)
      H.box(im, 0, 0, 12, 12, P.cream, P.ink)
      H.rect(im, 1, 1, 10, 1, P.tape); H.rect(im, 1, 1, 1, 10, P.tape)
      if on then check(im, 2, 3, P.green_d) end
      return im
    end,
    keycap = mk_key(P.cream, P.card_m, P.ink, 1, P.white),
    mouse = mk_mouse(P.cream, P.tape, P.ink, P.red, 3),
    m = { panel = M4, panel_alt = M4 },
    col = {
      btn = { normal = P.box_ink, hover = P.box_ink, pressed = P.box_ink, disabled = P.asphalt },
      head = P.gold, text = P.cream, dim = P.tape, alt = P.box_ink, key = P.box_ink,
    },
  }
end

------------------------------------------------------------------ A2: box flaps (fresh kraft)
do
  local K = KRAFT
  local HOT = { face = c("ffe7ad"), hi = c("fff6dc"), mid = P.card, lo = P.card_m, deep = P.card_dd, ink = K.ink }
  local FLAT = { face = P.card_m, hi = P.card_d, mid = P.card_d, lo = P.card_dd, deep = K.ink, ink = K.ink }
  local IN, IN_D, SIDE, TAPE_D = c("3a2416"), c("21140b"), c("dba04d"), c("c4b596")
  -- a flap seen face-on: hinge score along the top, cut edge along the bottom
  local function flap(im, M, o, y, sh)
    local b = slab(48, M, o)
    H.rect(b, 1, 2, 46, 1, M.mid)
    for j = 12, b.height - 1 do
      b:drawPixel(0, j, P.none); b:drawPixel(47, j, P.none)
      b:drawPixel(1, j, M.ink); b:drawPixel(46, j, M.ink)
    end
    if sh > 0 then H.rect(im, 3, y + b.height, 43, sh, P.ink) end
    put(im, b, 0, y)
  end
  THEMES[#THEMES + 1] = {
    code = "A2", name = "BOX FLAPS", dir = "a2_box_flaps",
    button = function(st)
      local im = H.img(48, 20)
      if st == "pressed" then flap(im, FLAT, { flat = true }, 5, 0)
      elseif st == "hover" then
        flap(im, HOT, nil, 0, 4)
        H.rect(im, 1, 1, 46, 2, P.red) -- fresh strip of red tape over the hinge
      elseif st == "disabled" then flap(im, GREY, nil, 1, 1)
      else flap(im, K, nil, 1, 2) end
      return im
    end,
    btn_dy = { normal = -1, hover = -2, pressed = 3, disabled = -1 },
    -- opened box from above: four flaps folded out round the dark inside
    panel = function()
      local im = H.img(24, 24)
      H.rect(im, 7, 7, 10, 10, IN)
      H.rect(im, 7, 7, 10, 1, IN_D); H.rect(im, 7, 7, 1, 10, IN_D)
      for d = 0, 6 do
        local s = d == 0 and 9 or (d == 1 and 8 or 7)
        for i = s, 23 - s do
          local edge = d == 0 or i == s or i == 23 - s
          local function col(face)
            if edge then return K.ink end
            if d == 1 then return K.hi end
            if d == 6 then return K.lo end
            return face
          end
          im:drawPixel(i, d, col(K.face)); im:drawPixel(i, 23 - d, col(K.face))
          im:drawPixel(d, i, col(SIDE)); im:drawPixel(23 - d, i, col(SIDE))
        end
      end
      return im
    end,
    panel_alt = function() -- packing slip taped down at two corners
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, P.cream, P.card_dd)
      H.rect(im, 0, 0, 4, 4, P.tape); H.rect(im, 3, 0, 1, 4, TAPE_D); H.rect(im, 0, 3, 4, 1, TAPE_D)
      H.rect(im, 20, 20, 4, 4, P.tape); H.rect(im, 20, 20, 1, 4, TAPE_D); H.rect(im, 20, 20, 4, 1, TAPE_D)
      return im
    end,
    track = function()
      local im = H.img(32, 8)
      H.rect(im, 0, 3, 32, 2, K.lo)
      return im
    end,
    fill = function() -- packing tape pulled off the roll
      local im = H.img(32, 8)
      H.rect(im, 0, 1, 32, 6, P.tape)
      H.rect(im, 0, 1, 32, 1, P.cream); H.rect(im, 0, 6, 32, 1, TAPE_D)
      for y = 1, 5, 2 do im:drawPixel(0, y, P.none) end
      return im
    end,
    grabber = mk_roll(P.tape, K.mid, K.deep, K.ink, P.red, P.white),
    checkbox = function(on)
      local im = H.img(12, 12)
      H.box(im, 0, 0, 12, 12, K.hi, K.ink)
      H.rect(im, 1, 10, 10, 1, K.face)
      if on then check(im, 2, 2, K.ink); check(im, 2, 3, K.ink) end
      return im
    end,
    keycap = mk_fkey({ face = K.hi, hi = c("fff6dc"), lo = K.lo, deep = K.deep, ink = K.ink, paper = K.hi }),
    mouse = mk_mouse(K.hi, K.face, K.ink, P.red, 3),
    nine = { button = { m = { 4, 9, 4, 10 }, tx = 4 }, panel = { m = { 10, 10, 10, 10 } }, keycap = { m = { 4, 4, 4, 5 }, tx = 4 } },
    col = {
      btn = { normal = K.ink, hover = K.ink, pressed = K.ink, disabled = P.asphalt },
      head = P.gold, text = P.cream, dim = P.tape, alt = K.ink, key = K.ink,
    },
  }
end

------------------------------------------------------------------ A3: recycled board, stapled
do
  local R = { face = c("b59d80"), hi = c("cdb89c"), mid = c("9a846c"), lo = c("7c6855"), deep = c("4f4136"), ink = c("2a211b") }
  local R_HOT = { face = c("d9c8ad"), hi = c("eadcc6"), mid = R.face, lo = R.mid, deep = R.deep, ink = R.ink }
  local R_FLAT = { face = R.mid, hi = R.lo, mid = R.lo, lo = R.deep, deep = R.ink, ink = R.ink }
  local R_OFF = { face = c("d5cfc4"), hi = c("e3ded5"), mid = c("c4bdb1"), lo = c("a9a297"), deep = c("77726a"), ink = c("5f5b55") }
  local STAMP, PAPER_D = c("d4313a"), c("d9d2c2")
  local function board(M, o, stapled, label)
    local b = slab(48, M, o)
    math.randomseed(5)
    for _ = 1, 18 do -- recycled flecks
      local x, y = math.random(8, 39), math.random(2, 10)
      b:drawPixel(x, y, math.random() < 0.5 and M.mid or M.hi)
    end
    H.rect(b, 7, 1, 1, 11, M.lo); H.rect(b, 40, 1, 1, 11, M.lo) -- glued joint inside each end
    if label then H.rect(b, 6, 2, 36, 9, P.white); H.rect(b, 6, 10, 36, 1, PAPER_D) end
    for _, x in ipairs({ 2, 42 }) do for _, y in ipairs({ 3, 8 }) do
      if stapled then staple(b, x, y, M.lo)
      else b:drawPixel(x, y, M.deep); b:drawPixel(x + 3, y, M.deep) end
    end end
    return b
  end
  THEMES[#THEMES + 1] = {
    code = "A3", name = "RECYCLED STAPLED", dir = "a3_recycled_stapled",
    button = function(st)
      local im = H.img(48, 20)
      if st == "pressed" then put(im, board(R_FLAT, { flat = true }, true), 0, 5)
      elseif st == "hover" then
        H.rect(im, 3, 17, 44, 3, P.ink)
        put(im, board(R_HOT, nil, true, true), 0, 0)
      elseif st == "disabled" then
        H.rect(im, 2, 18, 45, 1, R_OFF.ink)
        put(im, board(R_OFF, nil, false), 0, 1)
      else
        H.rect(im, 2, 18, 45, 2, P.ink)
        put(im, board(R, nil, true), 0, 1)
      end
      return im
    end,
    btn_dy = { normal = -2, hover = -3, pressed = 2, disabled = -2 },
    -- flattened box blank: dashed score lines, stapled corners, cut edge below
    panel = function()
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, R.face, R.ink)
      H.rect(im, 1, 1, 22, 1, R.hi)
      H.rect(im, 1, 19, 22, 1, R.lo); flute(im, 1, 20, 22, R.hi, R.deep)
      for i = 4, 17 do
        if i % 4 < 2 then
          im:drawPixel(i, 4, R.lo); im:drawPixel(i, 17, R.lo)
          im:drawPixel(4, i, R.lo); im:drawPixel(17, i, R.lo)
        end
      end
      staple(im, 2, 2, R.lo); staple(im, 18, 2, R.lo)
      return im
    end,
    panel_alt = function() -- grey paper slip stapled on
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, c("e8e1d2"), R.lo)
      H.rect(im, 1, 22, 22, 1, c("cfc7b6"))
      staple(im, 2, 2, c("cfc7b6")); staple(im, 18, 2, c("cfc7b6"))
      return im
    end,
    track = function() -- die-cut slot
      local im = H.img(32, 8)
      rbox(im, 0, 2, 32, 4, 2, R.deep, R.ink)
      return im
    end,
    fill = function()
      local im = H.img(32, 8)
      rbox(im, 0, 2, 32, 4, 2, STAMP, R.ink)
      return im
    end,
    grabber = function(hot) -- pull tab with a finger hole
      local im = H.img(8, 12)
      rbox(im, 0, 0, 8, 12, 2, hot and P.white or R.hi, R.ink)
      rr(im, 2, 2, 4, 3, 1, hot and STAMP or R.deep)
      H.rect(im, 1, 8, 6, 1, hot and PAPER_D or R.lo)
      return im
    end,
    checkbox = function(on)
      local im = H.img(12, 12)
      H.box(im, 0, 0, 12, 12, R.hi, R.ink)
      H.rect(im, 1, 10, 10, 1, R.face)
      if on then check(im, 2, 2, STAMP); check(im, 2, 3, STAMP) end
      return im
    end,
    keycap = function() -- cut tab with a dashed fold
      local im = H.img(16, 16)
      H.box(im, 0, 0, 16, 16, R.hi, R.ink)
      H.rect(im, 1, 1, 14, 1, c("e0d0b8"))
      H.rect(im, 1, 12, 14, 3, R.mid)
      for x = 1, 14 do if x % 4 < 2 then im:drawPixel(x, 11, R.lo) end end
      return im
    end,
    mouse = mk_mouse(R.hi, R.face, R.ink, STAMP, 3),
    nine = {
      button = { m = { 8, 9, 8, 10 }, tx = 32 }, panel = { m = { 8, 8, 8, 8 }, tx = 4, ty = 4 },
      panel_alt = { m = { 6, 6, 6, 6 } }, keycap = { m = { 4, 4, 4, 5 }, tx = 4 },
    },
    col = {
      btn = { normal = R.ink, hover = R.ink, pressed = R.ink, disabled = c("8f8a82") },
      head = R.ink, text = R.ink, dim = R.deep, alt = R.ink, key = R.ink,
    },
  }
end

------------------------------------------------------------------ A4: printed carton (white top, red print)
do
  local K = KRAFT
  local W = { face = c("f6f1e7"), hi = P.white, mid = c("d9d2c2"), lo = K.face, paper = K.hi, deep = K.deep, ink = K.ink }
  local W_HOT = { face = P.xred, hi = c("ff6b6e"), lo = K.face, paper = c("fff6dc"), deep = K.deep, ink = K.ink }
  local W_FLAT = { face = c("d9d2c2"), hi = c("bdb5a3"), lo = K.lo, deep = K.ink, ink = K.ink }
  local W_OFF = { face = c("e6e2da"), hi = c("f0ede6"), lo = GREY.mid, paper = GREY.hi, deep = GREY.deep, ink = GREY.ink }
  -- white-coated face, printed block with a this-way-up arrow, kraft cut edge
  local function carton(M, o, block, arrow, stripe)
    local b = slab(48, M, o)
    H.rect(b, 1, 1, 7, 11, block); uparrow(b, 2, 3, arrow)
    if stripe then H.rect(b, 8, 11, 39, 1, stripe) end
    return b
  end
  THEMES[#THEMES + 1] = {
    code = "A4", name = "PRINTED CARTON", dir = "a4_printed_carton",
    button = function(st)
      local im = H.img(48, 20)
      if st == "pressed" then put(im, carton(W_FLAT, { flat = true }, P.red_d, c("d9d2c2"), P.red_d), 0, 5)
      elseif st == "hover" then
        H.rect(im, 3, 17, 44, 3, P.ink)
        put(im, carton(W_HOT, nil, P.white, P.xred, P.white), 0, 0)
      elseif st == "disabled" then
        H.rect(im, 2, 18, 45, 1, GREY.ink)
        put(im, carton(W_OFF, nil, c("b5b0a6"), c("e6e2da"), nil), 0, 1)
      else
        H.rect(im, 2, 18, 45, 2, P.ink)
        put(im, carton(W, nil, P.xred, P.white, P.xred), 0, 1)
      end
      return im
    end,
    btn_dy = { normal = -2, hover = -3, pressed = 2, disabled = -2 },
    panel = function()
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, W.face, K.ink)
      H.rect(im, 1, 1, 22, 1, P.white)
      H.rect(im, 1, 2, 22, 3, P.xred); H.rect(im, 1, 5, 22, 1, P.red_d)
      H.rect(im, 1, 18, 22, 1, P.xred)
      H.rect(im, 1, 19, 22, 1, K.face); flute(im, 1, 20, 22, K.hi, K.deep)
      -- printed handling mark, top right
      H.box(im, 11, 7, 11, 9, W.face, K.ink)
      for _, x in ipairs({ 13, 17 }) do
        im:drawPixel(x + 1, 9, K.ink); H.rect(im, x, 10, 3, 1, K.ink); H.rect(im, x + 1, 11, 1, 2, K.ink)
      end
      H.rect(im, 13, 13, 7, 1, K.ink)
      return im
    end,
    panel_alt = function() -- unprinted kraft inside
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, K.face, K.deep)
      H.rect(im, 1, 1, 22, 1, K.lo); H.rect(im, 1, 1, 1, 22, K.lo)
      return im
    end,
    track = function() -- printed cut-here dashes
      local im = H.img(32, 8)
      for x = 0, 31 do if x % 4 < 2 then H.rect(im, x, 3, 1, 2, K.ink) end end
      return im
    end,
    fill = function() -- red printed tape
      local im = H.img(32, 8)
      H.rect(im, 0, 1, 32, 6, P.xred)
      H.rect(im, 0, 1, 32, 1, c("ff6b6e")); H.rect(im, 0, 6, 32, 1, P.red_d)
      return im
    end,
    grabber = mk_roll(P.white, P.xred, K.ink, K.ink, P.xred, P.white),
    checkbox = function(on)
      local im = H.img(12, 12)
      H.box(im, 0, 0, 12, 12, W.face, K.ink)
      H.rect(im, 1, 10, 10, 1, W.mid)
      if on then check(im, 2, 2, P.xred); check(im, 2, 3, P.xred) end
      return im
    end,
    keycap = function()
      local im = mk_fkey({ face = W.face, hi = P.white, lo = K.face, paper = K.hi, deep = K.deep, ink = K.ink })()
      H.rect(im, 1, 1, 14, 1, P.xred)
      return im
    end,
    mouse = mk_mouse(W.face, W.mid, K.ink, P.xred, 3),
    nine = {
      button = { m = { 8, 9, 4, 10 }, tx = 4 }, panel = { m = { 6, 16, 14, 6 }, tx = 4 },
      keycap = { m = { 4, 4, 4, 5 }, tx = 4 }, track = { m = { 2, 0, 2, 0 }, tx = 4 },
    },
    col = {
      btn = { normal = K.ink, hover = P.white, pressed = K.ink, disabled = c("8f8a82") },
      head = K.ink, text = K.ink, dim = c("8f8a82"), alt = K.ink, key = K.ink,
    },
  }
end

------------------------------------------------------------------ A5: battered, re-used box
do
  local K = KRAFT
  local O = { face = c("d2a264"), hi = c("e2bb82"), mid = c("b3854c"), lo = c("946a3a"), deep = c("5f4122"), ink = K.ink }
  local O_HOT = { face = c("ecc98f"), hi = c("f7ddb0"), mid = O.face, lo = O.mid, deep = O.deep, ink = K.ink }
  local O_FLAT = { face = O.mid, hi = O.lo, mid = O.lo, lo = O.deep, deep = K.ink, ink = K.ink }
  local O_OFF = { face = c("cbc3b3"), hi = c("dad4c7"), mid = c("b3ab9b"), lo = c("a39b8b"), deep = c("6d675c"), ink = P.asphalt }
  local RES, RES_H, RES_D, LABEL, MARK = c("eadfc4"), c("f6efdc"), c("cdbf9f"), c("e9e2d0"), c("d4313a")
  local function old(M, o, under)
    local b = slab(48, M, o)
    -- dog-eared corner and its crease
    b:drawPixel(0, 0, P.none); b:drawPixel(1, 0, P.none); b:drawPixel(0, 1, P.none); b:drawPixel(1, 1, M.ink)
    b:drawPixel(3, 1, M.lo); b:drawPixel(2, 2, M.lo); b:drawPixel(1, 3, M.lo)
    -- scrap of an old label, crossed out in marker
    H.rect(b, 2, 5, 5, 5, LABEL); b:drawPixel(6, 5, M.face); b:drawPixel(2, 9, M.face)
    H.line(b, 2, 6, 6, 8, K.ink); H.line(b, 2, 8, 6, 6, K.ink)
    -- old tape residue
    H.rect(b, 41, 1, 5, 6, RES); H.rect(b, 45, 1, 1, 6, RES_D)
    for _, x in ipairs({ 41, 43, 45 }) do b:drawPixel(x, 6, M.face) end
    -- outer liner torn away, fluting showing
    flute(b, 42, 9, 4, M.hi, M.deep)
    b:drawPixel(41, 10, M.deep); b:drawPixel(41, 11, M.deep)
    if under then -- ringed in red marker
      H.rect(b, 8, 1, 33, 1, under); H.rect(b, 7, 11, 33, 1, under)
      H.rect(b, 7, 2, 1, 9, under); H.rect(b, 40, 2, 1, 9, under)
      b:drawPixel(41, 1, under); b:drawPixel(6, 11, under)
    end
    return b
  end
  THEMES[#THEMES + 1] = {
    code = "A5", name = "BATTERED REUSED", dir = "a5_battered_reused",
    button = function(st)
      local im = H.img(48, 20)
      if st == "pressed" then put(im, old(O_FLAT, { flat = true }), 0, 5)
      elseif st == "hover" then
        H.rect(im, 3, 17, 44, 3, P.ink)
        put(im, old(O_HOT, nil, MARK), 0, 0)
      elseif st == "disabled" then
        H.rect(im, 2, 18, 45, 1, P.asphalt)
        put(im, old(O_OFF), 0, 1)
      else
        H.rect(im, 2, 18, 45, 2, P.ink)
        put(im, old(O), 0, 1)
      end
      return im
    end,
    btn_dy = { normal = -2, hover = -3, pressed = 2, disabled = -2 },
    panel = function()
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, O.face, K.ink)
      H.rect(im, 1, 1, 22, 1, O.hi)
      -- old tape along the top seam, torn short of the corners
      for y = 2, 5 do
        local x0 = y % 2 == 0 and 2 or 3
        H.rect(im, x0, y, 24 - 2 * x0, 1, y == 2 and RES_H or (y == 5 and RES_D or RES))
      end
      H.rect(im, 1, 19, 22, 1, O.lo); flute(im, 1, 20, 22, O.hi, O.deep)
      -- corner torn off, a dent crease opposite
      for j = 0, 3 do
        H.rect(im, 20 + j, 23 - j, 4 - j, 1, P.none)
        im:drawPixel(19 + j, 23 - j, K.ink)
      end
      im:drawPixel(1, 17, O.lo); im:drawPixel(2, 18, O.lo); im:drawPixel(3, 19, O.lo)
      im:drawPixel(2, 7, O.hi); im:drawPixel(3, 6, O.hi); im:drawPixel(4, 7, O.hi)
      return im
    end,
    panel_alt = function() -- old label, one corner peeled, one torn
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, LABEL, O.lo)
      for i = 0, 2 do
        H.rect(im, 0, i, 3 - i, 1, P.none); im:drawPixel(3 - i, i, O.lo)
        H.rect(im, 21 + i, 23 - i, 3 - i, 1, P.none); im:drawPixel(20 + i, 23 - i, O.lo)
      end
      im:drawPixel(3, 3, RES_D); im:drawPixel(4, 2, RES_D); im:drawPixel(2, 4, RES_D)
      return im
    end,
    track = function() -- marker line
      local im = H.img(32, 8)
      H.rect(im, 1, 3, 30, 2, K.ink)
      im:drawPixel(0, 4, K.ink); im:drawPixel(31, 3, K.ink)
      return im
    end,
    fill = function()
      local im = H.img(32, 8)
      H.rect(im, 0, 2, 32, 4, MARK)
      im:drawPixel(0, 2, P.none); im:drawPixel(0, 5, P.none)
      return im
    end,
    grabber = function(hot) -- marker pen cap
      local im = H.img(8, 12)
      rbox(im, 1, 0, 6, 12, 1, hot and MARK or c("2b2d33"), P.ink)
      H.rect(im, 3, 2, 1, 6, hot and c("ff8a8f") or c("60646f"))
      H.rect(im, 2, 9, 4, 1, hot and P.red_d or P.ink)
      return im
    end,
    checkbox = function(on) -- box drawn on in marker
      local im = H.img(12, 12)
      H.box(im, 0, 0, 12, 12, O.hi, K.ink, 2)
      for _, p in ipairs({ { 0, 0 }, { 11, 0 }, { 0, 11 }, { 11, 11 }, { 11, 5 } }) do im:drawPixel(p[1], p[2], P.none) end
      if on then check(im, 2, 1, MARK); check(im, 2, 2, MARK); check(im, 2, 3, MARK) end
      return im
    end,
    keycap = function()
      local im = mk_fkey({ face = O.hi, hi = c("f0d2a0"), lo = O.lo, paper = O.hi, deep = O.deep, ink = K.ink })()
      im:drawPixel(15, 0, P.none); im:drawPixel(14, 0, P.none); im:drawPixel(15, 1, P.none); im:drawPixel(14, 1, K.ink)
      im:drawPixel(12, 1, O.lo); im:drawPixel(13, 2, O.lo); im:drawPixel(14, 3, O.lo)
      return im
    end,
    mouse = mk_mouse(O.hi, O.face, K.ink, MARK, 3),
    nine = {
      button = { m = { 8, 9, 8, 10 }, tx = 4 }, panel = { m = { 8, 8, 8, 8 }, tx = 4 },
      panel_alt = { m = { 6, 6, 6, 6 } }, keycap = { m = { 4, 4, 4, 5 }, tx = 4 },
    },
    col = {
      btn = { normal = K.ink, hover = K.ink, pressed = K.ink, disabled = c("857f72") },
      head = K.ink, text = K.ink, dim = O.deep, alt = K.ink, key = K.ink,
    },
  }
end

------------------------------------------------------------------ A6: dark double-wall board, paper tape
do
  local K = KRAFT
  local D = { face = c("8a5a36"), hi = c("a87242"), mid = c("6f4728"), lo = c("5a3920"), paper = c("c18440"), deep = c("2e1b0e"), ink = c("140b06") }
  local D_HOT = { face = K.face, hi = K.hi, lo = K.lo, paper = K.hi, deep = D.deep, ink = D.ink }
  local D_FLAT = { face = D.lo, hi = c("47290f"), lo = D.deep, deep = D.ink, ink = D.ink }
  local D_OFF = { face = c("6b655f"), hi = c("7d7770"), lo = c("55504b"), paper = c("8f8982"), deep = c("2f2c29"), ink = c("1f1d1b") }
  local TAN, TAN_H, TAN_D = c("d9c08f"), c("f0deb4"), c("b0925c")
  -- reinforced paper tape wrapped round both ends, threads showing
  local function wall(M, o, t, th, td)
    local b = slab(48, M, o)
    for _, x in ipairs({ 1, 41 }) do
      H.rect(b, x, 1, 6, b.height - 2, t)
      H.rect(b, x, 1, 6, 1, th)
      for y = 3, b.height - 2, 3 do H.rect(b, x, y, 6, 1, td) end
      H.rect(b, x == 1 and 6 or 41, 1, 1, b.height - 2, td)
    end
    return b
  end
  local DBL = { fh = 9, dbl = true }
  THEMES[#THEMES + 1] = {
    code = "A6", name = "DOUBLE WALL", dir = "a6_double_wall",
    button = function(st)
      local im = H.img(48, 20)
      if st == "pressed" then put(im, wall(D_FLAT, { fh = 9, flat = true }, TAN_D, TAN, c("8f7545")), 0, 7)
      elseif st == "hover" then
        H.rect(im, 2, 19, 46, 1, P.ink)
        put(im, wall(D_HOT, DBL, P.cream, P.white, TAN), 0, 0)
      elseif st == "disabled" then
        put(im, wall(D_OFF, DBL, c("9a958c"), c("aaa59c"), c("7f7a72")), 0, 0)
      else
        H.rect(im, 2, 19, 46, 1, P.ink)
        put(im, wall(D, DBL, TAN, TAN_H, TAN_D), 0, 0)
      end
      return im
    end,
    btn_dy = { normal = -4, hover = -4, pressed = 3, disabled = -4 },
    panel = function()
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, D.mid, D.ink)
      H.rect(im, 1, 1, 22, 1, D.face)
      local rows = { TAN_H, TAN, TAN_D, TAN, TAN_D }
      for k, col in ipairs(rows) do
        local y = k + 1
        local x0 = y % 2 == 0 and 2 or 3
        H.rect(im, x0, y, 24 - 2 * x0, 1, col)
      end
      H.rect(im, 1, 15, 22, 1, D.lo); flute(im, 1, 16, 22, D.paper, D.deep)
      H.rect(im, 1, 19, 22, 1, D.lo); flute(im, 1, 20, 22, D.paper, D.deep)
      return im
    end,
    panel_alt = function() -- window cut through to the dark inside
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, D.deep, D.lo)
      H.rect(im, 1, 1, 22, 1, D.ink); H.rect(im, 1, 1, 1, 22, D.ink)
      return im
    end,
    track = function()
      local im = H.img(32, 8)
      H.box(im, 0, 2, 32, 4, D.deep, D.ink)
      return im
    end,
    fill = function() -- gummed paper tape
      local im = H.img(32, 8)
      H.rect(im, 0, 1, 32, 6, TAN)
      H.rect(im, 0, 1, 32, 1, TAN_H); H.rect(im, 0, 3, 32, 1, TAN_D); H.rect(im, 0, 6, 32, 1, TAN_D)
      return im
    end,
    grabber = mk_roll(TAN, D.face, D.deep, D.ink, P.cream, K.face),
    checkbox = function(on)
      local im = H.img(12, 12)
      H.box(im, 0, 0, 12, 12, on and D.face or D.deep, P.cream)
      if on then check(im, 2, 2, P.cream); check(im, 2, 3, P.cream) end
      return im
    end,
    keycap = mk_fkey({ face = K.mid, hi = c("d99a4e"), lo = D.lo, paper = K.face, deep = D.deep, ink = D.ink }),
    mouse = mk_mouse(TAN, TAN_D, D.ink, c("f08a24"), 3),
    nine = { button = { m = { 8, 9, 8, 10 }, tx = 4 }, panel = { m = { 8, 8, 8, 9 }, tx = 4 }, keycap = { m = { 4, 4, 4, 5 }, tx = 4 } },
    col = {
      btn = { normal = P.cream, hover = K.ink, pressed = P.cream, disabled = c("b5b0a6") },
      head = TAN_H, text = P.cream, dim = TAN, alt = P.cream, key = D.ink,
    },
  }
end

------------------------------------------------------------------ C: hotel brass
do
  local RED, RED_L, GOLD_L, DARK = c("a8202c"), c("c33a43"), c("ffe08a"), P.base_d
  local function body(fill, hi, lip, ring, line)
    local b = H.img(48, 20)
    H.box(b, 0, 0, 48, 20, fill, line)
    H.rect(b, 1, 1, 46, 1, hi)
    H.rect(b, 1, 18, 46, 1, lip)
    -- engraved inner frame with chamfered corners
    H.rect(b, 4, 2, 40, 1, ring); H.rect(b, 4, 17, 40, 1, ring)
    H.rect(b, 2, 4, 1, 12, ring); H.rect(b, 45, 4, 1, 12, ring)
    m4(b, 3, 3, ring)
    return b
  end
  THEMES[#THEMES + 1] = {
    code = "C", name = "HOTEL BRASS", kept = true, dir = "c_hotel_brass",
    button = function(st)
      if st == "hover" then return body(RED, RED_L, P.door_d, P.gold, DARK) end
      if st == "pressed" then return body(P.gold_d, c("8a6420"), P.gold, c("8a6420"), DARK) end
      if st == "disabled" then return body(P.cap, c("c49a86"), P.cap_d, P.cap_d, P.base) end
      return body(P.gold, GOLD_L, P.gold_d, P.gold_d, DARK)
    end,
    btn_dy = { normal = 0, hover = 0, pressed = 1, disabled = 0 },
    panel = function()
      local im = H.img(24, 24)
      H.rect(im, 0, 0, 24, 24, DARK)
      H.rect(im, 1, 1, 22, 22, P.gold)
      H.rect(im, 1, 1, 22, 1, GOLD_L); H.rect(im, 1, 1, 1, 22, GOLD_L)
      H.rect(im, 1, 22, 22, 1, P.gold_d); H.rect(im, 22, 1, 1, 22, P.gold_d)
      H.rect(im, 3, 3, 18, 18, DARK)
      H.rect(im, 4, 4, 16, 16, P.carpet)
      -- thin inner line, broken at the corners around a brass stud
      H.rect(im, 8, 6, 8, 1, P.gold_d); H.rect(im, 8, 17, 8, 1, P.gold_d)
      H.rect(im, 6, 8, 1, 8, P.gold_d); H.rect(im, 17, 8, 1, 8, P.gold_d)
      m4(im, 7, 6, P.gold_d); m4(im, 6, 7, P.gold_d)
      m4(im, 5, 5, P.gold); m4(im, 6, 5, P.gold_d); m4(im, 5, 6, P.gold_d)
      -- corner brackets with a rivet
      for _, o in ipairs({ { 0, 0 }, { 19, 0 }, { 0, 19 }, { 19, 19 } }) do
        H.box(im, o[1], o[2], 5, 5, GOLD_L, DARK)
        im:drawPixel(o[1] + 2, o[2] + 2, P.gold_d)
      end
      return im
    end,
    panel_alt = function()
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, P.cream, P.gold_d)
      H.rect(im, 3, 2, 18, 1, P.gold); H.rect(im, 3, 21, 18, 1, P.gold)
      H.rect(im, 2, 3, 1, 18, P.gold); H.rect(im, 21, 3, 1, 18, P.gold)
      m4(im, 0, 0, P.none)
      return im
    end,
    track = function()
      local im = H.img(32, 8)
      H.box(im, 0, 2, 32, 4, DARK, P.gold_d)
      return im
    end,
    fill = function()
      local im = H.img(32, 8)
      H.box(im, 0, 2, 32, 4, P.gold, DARK); H.rect(im, 1, 3, 30, 1, GOLD_L)
      return im
    end,
    grabber = function(hot)
      local im = H.img(8, 12)
      rbox(im, 0, 0, 8, 12, 2, hot and P.cream or P.gold, DARK)
      H.rect(im, 2, 2, 1, 4, hot and P.white or GOLD_L)
      H.rect(im, 5, 3, 1, 7, hot and P.gold or P.gold_d)
      H.rect(im, 2, 9, 4, 1, hot and P.gold or P.gold_d)
      return im
    end,
    checkbox = function(on)
      local im = H.img(12, 12)
      H.box(im, 0, 0, 12, 12, P.gold, DARK)
      H.rect(im, 2, 2, 8, 8, P.cream)
      if on then check(im, 2, 3, RED) end
      return im
    end,
    keycap = mk_key(P.cream, P.gold_d, DARK, 2, P.white),
    mouse = mk_mouse(P.cream, P.tape, DARK, RED, 3),
    m = { panel = { 8, 8, 8, 8 }, panel_alt = M4 },
    col = {
      btn = { normal = DARK, hover = P.cream, pressed = DARK, disabled = P.base },
      head = P.gold, text = P.cream, dim = c("e0a8a8"), alt = DARK, key = DARK,
    },
    extras = function()
      local im = H.img(61, 5)
      H.rect(im, 0, 2, 61, 1, P.gold_d)
      for _, x in ipairs({ 0, 60 }) do H.rect(im, x, 1, 1, 3, P.gold) end
      for i = 0, 2 do H.rect(im, 30 - i, i, 2 * i + 1, 5 - 2 * i, P.gold) end
      im:drawPixel(30, 2, GOLD_L)
      return { divider = im }
    end,
    deco = function(pv, T, L)
      put(pv, T.x.divider, L.px + L.pw // 2 - 30, L.py + 19)
    end,
  }
end

------------------------------------------------------------------ D: shipping label
do
  local W, K, R, SH = P.white, P.ink, P.xred, P.asphalt_d
  local MANILA = c("ece2c8")
  THEMES[#THEMES + 1] = {
    code = "D", name = "SHIPPING LABEL", kept = true, dir = "d_shipping_label",
    button = function(st)
      local im = H.img(48, 20)
      if st == "pressed" then
        rr(im, 0, 2, 48, 18, 2, K)
        rbox(im, 1, 3, 46, 16, 1, K, W)
        return im
      end
      rr(im, 1, 2, 47, 18, 2, st == "disabled" and P.gray or SH)
      if st == "hover" then
        rr(im, 0, 0, 48, 18, 2, K)
        rbox(im, 1, 1, 46, 16, 1, R, W)
      elseif st == "disabled" then
        rbox(im, 0, 0, 48, 18, 2, c("d9d9d4"), P.mat_n, 2)
      else
        rbox(im, 0, 0, 48, 18, 2, W, K, 2)
      end
      return im
    end,
    btn_dy = { pressed = 2 },
    panel = function()
      local im = H.img(24, 24)
      rbox(im, 0, 0, 24, 24, 2, W, K, 2)
      H.rect(im, 4, 3, 16, 1, K); H.rect(im, 4, 20, 16, 1, K)
      H.rect(im, 3, 4, 1, 16, K); H.rect(im, 20, 4, 1, 16, K)
      return im
    end,
    panel_alt = function()
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, MANILA, K)
      H.rect(im, 0, 0, 3, 24, K)
      return im
    end,
    track = function()
      local im = H.img(32, 8)
      H.box(im, 0, 2, 32, 4, W, K)
      return im
    end,
    fill = function()
      local im = H.img(32, 8)
      H.box(im, 0, 2, 32, 4, R, K)
      return im
    end,
    grabber = function(hot)
      local im = H.img(8, 12)
      rr(im, 0, 0, 8, 12, 1, K)
      rbox(im, 1, 1, 6, 10, 0, hot and R or W, hot and W or K)
      return im
    end,
    checkbox = function(on)
      local im = H.img(12, 12)
      H.box(im, 0, 0, 12, 12, on and K or W, K, 2)
      if on then check(im, 2, 3, W) end
      return im
    end,
    keycap = mk_key(W, K, K, 1),
    mouse = mk_mouse(W, c("d9d9d4"), K, R, 3),
    m = { panel = M4, panel_alt = M4 },
    col = {
      btn = { normal = K, hover = W, pressed = W, disabled = P.gray },
      head = K, text = K, dim = P.gray, alt = K, key = K,
    },
    extras = function()
      local bar = H.img(44, 10)
      local x, on = 0, true
      local ws = { 2, 1, 1, 2, 3, 1, 1, 1, 2, 1, 3, 1, 1, 2, 2, 1, 1, 3, 1, 1, 2, 1, 1, 2, 3, 1, 1, 2 }
      for _, w in ipairs(ws) do
        if on then H.rect(bar, x, 0, w, 10, K) end
        x, on = x + w, not on
      end
      local st = H.img(55, 13)
      H.box(st, 0, 0, 55, 13, P.none, R, 2)
      H.rect(st, 2, 2, 51, 9, W)
      H.text(st, "PRIORITY", 28, 3, R, { align = "center" })
      return { barcode = bar, stamp = st }
    end,
    deco = function(pv, T, L)
      put(pv, T.x.stamp, L.px + 10, L.py + 7)
      put(pv, T.x.barcode, L.px + L.pw - 54, L.py + 8)
    end,
  }
end

------------------------------------------------------------------ G: clipboard (three button sets on one kit)
do
  local BOARD, BOARD_D, BOARD_L = c("9a6a3c"), c("5e3b1e"), c("bd8c55")
  local PAPER, PAPER_D, PEN = c("f7f2e3"), c("d6cdb4"), c("1d2b53")
  local REDPEN, BLUEPEN, SHADOW = c("d4313a"), c("3d5fc4"), c("3a2614")
  local WIRE, WIRE_D = c("8d93a0"), c("5a606b")

  -- Everything except the buttons is shared by G, G2 and G3.
  local function kit(t)
    t.panel = function()
      local im = H.img(24, 24)
      rr(im, 0, 0, 24, 24, 2, BOARD_D)
      rr(im, 1, 1, 22, 22, 1, BOARD)
      H.rect(im, 2, 1, 20, 1, BOARD_L); H.rect(im, 1, 2, 1, 20, BOARD_L)
      H.rect(im, 4, 4, 16, 16, PAPER)
      H.rect(im, 4, 20, 17, 1, BOARD_D); H.rect(im, 20, 4, 1, 16, BOARD_D)
      return im
    end
    t.panel_alt = function()
      local im = H.img(24, 24)
      H.box(im, 0, 0, 24, 24, c("fdf1a6"), c("cdb64a"))
      H.rect(im, 1, 1, 22, 2, c("ecd45a"))
      H.rect(im, 3, 3, 1, 20, c("e2686e"))
      return im
    end
    t.track = function()
      local im = H.img(32, 8)
      H.box(im, 0, 2, 32, 4, PAPER_D, PEN)
      return im
    end
    t.fill = function()
      local im = H.img(32, 8)
      H.box(im, 0, 2, 32, 4, REDPEN, PEN)
      return im
    end
    t.grabber = function(hot) -- binder clip
      local im = H.img(8, 12)
      H.box(im, 2, 0, 4, 5, P.none, c("7c818c"))
      H.rect(im, 0, 4, 8, 8, hot and REDPEN or c("23252b"))
      H.rect(im, 1, 5, 6, 1, hot and c("ff8a8f") or c("555965"))
      return im
    end
    t.checkbox = function(on)
      local im = H.img(12, 12)
      H.box(im, 0, 0, 12, 12, P.white, PEN)
      if on then check(im, 2, 3, REDPEN) end
      return im
    end
    t.keycap = mk_key(P.white, PAPER_D, PEN, 1)
    t.mouse = mk_mouse(P.white, PAPER_D, PEN, BLUEPEN, 3)
    t.col.head, t.col.text, t.col.dim, t.col.alt, t.col.key = PEN, PEN, c("6b7390"), PEN, PEN
    t.extras = function()
      local im = H.img(40, 13)
      local M1, M2, M3 = c("c3c7cf"), c("7c818c"), c("eceef2")
      rbox(im, 12, 0, 16, 8, 3, P.none, M2, 2)
      rbox(im, 0, 5, 40, 8, 2, M1, c("3b3e46"))
      H.rect(im, 2, 6, 36, 1, M3)
      H.rect(im, 2, 11, 36, 1, M2)
      return { clip = im }
    end
    t.deco = function(pv, T, L) put(pv, T.x.clip, L.px + L.pw // 2 - 20, L.py - 8) end
    THEMES[#THEMES + 1] = t
  end

  -- G: manila index cards with a tab, ruled lines and a punched hole
  local MAN, MAN_H, MAN_D, MAN_E = c("e6cf98"), c("f3e3b8"), c("cdb57c"), c("7d6634")
  local function card(face, hi, edge, r1, r2, r2h, hole, clip)
    local b = H.img(48, 17)
    H.rect(b, 37, 0, 10, 3, edge); H.rect(b, 38, 1, 8, 2, face)
    b:drawPixel(37, 0, P.none); b:drawPixel(46, 0, P.none); b:drawPixel(38, 1, edge); b:drawPixel(45, 1, edge)
    H.box(b, 0, 2, 48, 15, face, edge)
    H.rect(b, 39, 2, 6, 1, face)
    H.rect(b, 1, 3, 36, 1, hi)
    if r1 then H.rect(b, 1, 4, 46, 1, r1) end
    if r2 then H.rect(b, 1, 14, 46, r2h or 1, r2) end
    if hole then rbox(b, 2, 7, 4, 4, 1, hole, edge) end
    if clip then
      H.rect(b, 2, 1, 1, 10, WIRE); H.rect(b, 3, 0, 3, 1, WIRE); H.rect(b, 6, 1, 1, 8, WIRE)
      b:drawPixel(3, 11, WIRE); H.rect(b, 4, 3, 1, 8, WIRE_D); b:drawPixel(5, 2, WIRE_D)
    end
    return b
  end
  kit({
    code = "G", name = "CLIPBOARD INDEX CARDS", dir = "g_clipboard_notes",
    button = function(st)
      local im = H.img(48, 20)
      if st == "pressed" then
        put(im, card(MAN_D, MAN_D, MAN_E, c("b5484d"), c("6f8fbf"), 1, SHADOW), 0, 3)
      elseif st == "hover" then
        H.rect(im, 3, 17, 45, 3, SHADOW)
        put(im, card(MAN_H, P.white, MAN_E, REDPEN, REDPEN, 2, nil, true), 0, 0)
      elseif st == "disabled" then
        H.rect(im, 2, 18, 46, 1, SHADOW)
        put(im, card(c("d8d4c8"), c("e4e1d8"), c("8f8b80"), c("bdb9ad"), c("bdb9ad"), 1, c("8f8b80")), 0, 1)
      else
        H.rect(im, 2, 18, 46, 2, SHADOW)
        put(im, card(MAN, MAN_H, MAN_E, REDPEN, c("7fa3d9"), 1, SHADOW), 0, 1)
      end
      return im
    end,
    btn_dy = { normal = 1, hover = 0, pressed = 3, disabled = 1 },
    nine = { button = { m = { 8, 9, 12, 10 } } },
    col = { btn = { normal = PEN, hover = PEN, pressed = PEN, disabled = c("8a867b") } },
  })

  -- G2: torn strips of kraft paper, hover tapes them down with blue tape
  local TORN = { 2, 0, 1, 3, 1, 0, 2, 1, 0, 2, 3, 1, 0, 1, 2, 0 }
  local BLUE, BLUE_H, BLUE_D = c("4f8fd6"), c("86b8ee"), c("2f67ab")
  local function torn(face, hi, lo)
    local b = H.img(48, 16)
    for j = 0, 15 do
      local a, r = TORN[j + 1], TORN[16 - j]
      H.rect(b, a, j, 48 - a - r, 1, face)
      b:drawPixel(a, j, hi); b:drawPixel(47 - r, j, hi)
    end
    H.rect(b, 4, 0, 40, 1, hi); H.rect(b, 4, 15, 40, 1, lo)
    return b
  end
  local function bluetape(im)
    for _, x in ipairs({ 1, 42 }) do
      H.rect(im, x, 0, 5, 19, BLUE)
      H.rect(im, x, 0, 1, 19, BLUE_H); H.rect(im, x + 4, 0, 1, 19, BLUE_D)
      im:drawPixel(x, 0, P.none); im:drawPixel(x + 2, 0, P.none)
      im:drawPixel(x + 1, 18, P.none); im:drawPixel(x + 3, 18, P.none)
    end
  end
  kit({
    code = "G2", name = "CLIPBOARD KRAFT STRIPS", dir = "g2_clipboard_kraft_strips",
    button = function(st)
      local im = H.img(48, 20)
      if st == "pressed" then put(im, torn(c("9c7440"), c("b08a55"), c("73532b")), 0, 4)
      elseif st == "hover" then
        H.rect(im, 5, 17, 40, 3, SHADOW)
        put(im, torn(c("d9b47e"), c("ecd2a8"), c("a57d49")), 0, 1)
        bluetape(im)
      elseif st == "disabled" then
        H.rect(im, 4, 18, 41, 1, SHADOW)
        put(im, torn(c("cfcabd"), c("dedad0"), c("a9a497")), 0, 2)
      else
        H.rect(im, 4, 18, 41, 2, SHADOW)
        put(im, torn(c("bb8d55"), c("d4ad78"), c("8a6535")), 0, 2)
      end
      return im
    end,
    btn_dy = { normal = 0, hover = -1, pressed = 2, disabled = 0 },
    nine = { button = { m = { 8, 9, 8, 10 } } },
    col = { btn = { normal = c("1a1208"), hover = c("1a1208"), pressed = c("1a1208"), disabled = c("8a867b") } },
  })

  -- G3: brown paper luggage tags with a reinforced hole and string
  local STR = c("f1e9d8")
  local function tag(face, hi, lo, line, ring, stamp)
    local b = H.img(48, 16)
    H.box(b, 0, 0, 48, 16, face, line)
    H.rect(b, 1, 1, 46, 1, hi)
    H.rect(b, 1, 14, 46, 1, lo)
    for i = 0, 3 do
      H.rect(b, 0, i, 4 - i, 1, P.none); b:drawPixel(4 - i, i, line)
      H.rect(b, 0, 15 - i, 4 - i, 1, P.none); b:drawPixel(4 - i, 15 - i, line)
    end
    if stamp then
      H.rect(b, 11, 2, 35, 1, stamp); H.rect(b, 11, 13, 35, 1, stamp)
      H.rect(b, 11, 2, 1, 12, stamp); H.rect(b, 45, 2, 1, 12, stamp)
    end
    rbox(b, 4, 5, 6, 6, 2, ring, line)
    H.rect(b, 6, 7, 2, 2, SHADOW)
    H.line(b, 6, 7, 0, 5, STR); H.line(b, 6, 8, 0, 11, STR)
    return b
  end
  local TAG_L = c("5e4424")
  kit({
    code = "G3", name = "CLIPBOARD LUGGAGE TAGS", dir = "g3_clipboard_luggage_tags",
    button = function(st)
      local im = H.img(48, 20)
      if st == "pressed" then put(im, tag(c("b9925a"), c("a57d49"), c("94703f"), TAG_L, c("d9cdb4")), 0, 4)
      elseif st == "hover" then
        H.rect(im, 5, 17, 43, 3, SHADOW)
        put(im, tag(c("ecd2a0"), P.cream, c("c9a66b"), TAG_L, P.white, REDPEN), 0, 1)
      elseif st == "disabled" then
        H.rect(im, 4, 18, 44, 1, SHADOW)
        put(im, tag(c("cfcabd"), c("dedad0"), c("b5b0a3"), c("8f8b80"), c("e4e1d8")), 0, 2)
      else
        H.rect(im, 4, 18, 44, 2, SHADOW)
        put(im, tag(c("d6ae70"), c("e8c995"), c("b08a4f"), TAG_L, c("f4ead2")), 0, 2)
      end
      return im
    end,
    btn_dy = { normal = 0, hover = -1, pressed = 2, disabled = 0 },
    nine = { button = { m = { 12, 9, 4, 10 } } },
    col = { btn = { normal = c("2a1a0c"), hover = c("2a1a0c"), pressed = c("2a1a0c"), disabled = c("8a867b") } },
  })
end


------------------------------------------------------------------ build, check, save
local BSTATES = { "normal", "hover", "pressed", "disabled" }
local DEF = {
  button = { m = M4 }, panel = { m = M4 }, panel_alt = { m = M4 }, keycap = { m = M4 },
  track = { m = { 2, 0, 2, 0 } }, fill = { m = { 2, 0, 2, 0 } },
}
local bad_total = 0
for _, T in ipairs(THEMES) do
  local dir = OUT .. T.dir .. "/"
  app.fs.makeAllDirectories(dir)
  -- nine-patch spec per asset: T.nine, else the older T.m margins, else 4 px
  local sp = {}
  for k, d in pairs(DEF) do
    sp[k] = (T.nine and T.nine[k]) or (T.m and T.m[k] and { m = T.m[k] }) or d
  end
  T.sp = sp
  T.btn_dy = T.btn_dy or {}
  T.btn = {}
  for i, s in ipairs(BSTATES) do T.btn[s] = T.button(s); T.btn[i] = T.btn[s] end
  T.pn, T.pa = T.panel(), T.panel_alt()
  T.tr, T.fl = T.track(), T.fill()
  T.gr = { T.grabber(false), T.grabber(true) }
  T.cb = { T.checkbox(false), T.checkbox(true) }
  T.kc = T.keycap()
  T.ms = { T.mouse(1), T.mouse(2), T.mouse(3) }
  T.x = T.extras and T.extras() or {}

  save_frames(dir, "button", T.btn, BSTATES)
  save_frames(dir, "panel", { T.pn })
  save_frames(dir, "panel_alt", { T.pa })
  save_frames(dir, "slider_track", { T.tr })
  save_frames(dir, "slider_fill", { T.fl })
  save_frames(dir, "slider_grabber", T.gr, { "normal", "hover" })
  save_frames(dir, "checkbox", T.cb, { "off", "on" })
  save_frames(dir, "keycap", { T.kc })
  save_frames(dir, "mouse", T.ms, { "left", "right", "none" })
  local xn = {}
  for k, im in pairs(T.x) do im:saveAs(dir .. "extra_" .. k .. ".png"); xn[#xn + 1] = k end
  table.sort(xn); T.xn = xn

  local rep = {}
  local function chk(name, im, s, vert)
    local n = check9(im, s, vert)
    bad_total = bad_total + n
    local how = string.format(" %d/%d/%d/%d", s.m[1], s.m[2], s.m[3], s.m[4])
      .. (s.tx and (" tileX" .. s.tx) or "") .. (s.ty and (" tileY" .. s.ty) or "")
    rep[#rep + 1] = name .. how .. (n == 0 and " ok" or (" BAD " .. n))
  end
  for _, s in ipairs(BSTATES) do chk("button." .. s, T.btn[s], sp.button, true) end
  chk("panel", T.pn, sp.panel, true)
  chk("panel_alt", T.pa, sp.panel_alt, true)
  chk("keycap", T.kc, sp.keycap, true)
  chk("track", T.tr, sp.track, false)
  chk("fill", T.fl, sp.fill, false)
  print(T.code .. " " .. T.name .. ": " .. table.concat(rep, ", "))
end
print("nine-patch offending pixels total: " .. bad_total)

------------------------------------------------------------------ previews
local TMP = "C:/Users/maxda/AppData/Local/Temp/claude/G--System2-Documents-Game-Dev-Projects-parcel-runner/f9b6e383-9339-40a2-8baf-8ad65c5d35c5/scratchpad/opt-ui/"
app.fs.makeAllDirectories(TMP)

local function scaled(src, s)
  local im = H.img(src.width * s, src.height * s)
  put(im, src, 0, 0, s)
  return im
end

local function slider(dst, T, x, y, w, v, hot)
  nine(dst, T.tr, x, y, w, 8, T.sp.track)
  local k = math.floor((w - 8) * v)
  if k > 0 then nine(dst, T.fl, x, y, k + 4, 8, T.sp.fill) end
  put(dst, T.gr[hot and 2 or 1], x + k, y - 2)
end

local function label_button(dst, T, state, cx, y, w, text)
  nine(dst, T.btn[state], cx - w // 2, y, w, 20, T.sp.button)
  local sh = T.col.btn_shadow and T.col.btn_shadow[state]
  H.text(dst, text, cx, y + 6 + (T.btn_dy[state] or 0), T.col.btn[state], { align = "center", shadow = sh })
end

local function key(dst, T, x, y, w, text)
  nine(dst, T.kc, x, y, w, 16, T.sp.keycap)
  H.text(dst, text, x + w // 2, y + 3, T.col.key, { align = "center" })
end

local function title(T) return T.code .. ": " .. T.name .. (T.kept and " (KEPT)" or "") end

local tiles = Image { fromFile = H.ROOT .. "assets/tilesets/hotel_tileset.png" }
local logo = Image { fromFile = H.ROOT .. "assets/ui/title_logo.png" }

local function mock(T)
  local pv = H.img(480, 270)
  local rows = { 1, 0, 0, 0, 0, 2, 3, 4, 4 }
  for r, col in ipairs(rows) do
    for cx = 0, 14 do H.blit(pv, tiles, cx * 32, (r - 1) * 32, col * 32, 0, 32, 32) end
  end
  put(pv, logo, 240 - logo.width // 2, 4)

  local L = { mx = 124, my = 108, px = 248, py = 72, pw = 224, ph = 192 }
  label_button(pv, T, "normal", L.mx, L.my, 96, "START")
  label_button(pv, T, "hover", L.mx, L.my + 26, 96, "SETTINGS")
  label_button(pv, T, "normal", L.mx, L.my + 52, 96, "EXIT")
  H.cursor(pv, L.mx + 30, L.my + 37)

  local px, py, pw, ph = L.px, L.py, L.pw, L.ph
  nine(pv, T.pn, px, py, pw, ph, T.sp.panel)
  H.text(pv, "SETTINGS", px + pw // 2, py + 10, T.col.head, { align = "center" })
  H.text(pv, "MUSIC", px + 12, py + 28, T.col.text)
  slider(pv, T, px + 56, py + 28, 112, 0.8)
  H.text(pv, "80%", px + 176, py + 28, T.col.dim)
  H.text(pv, "SFX", px + 12, py + 43, T.col.text)
  slider(pv, T, px + 56, py + 43, 112, 0.35, true)
  H.text(pv, "35%", px + 176, py + 43, T.col.dim)
  put(pv, T.cb[2], px + 12, py + 55)
  H.text(pv, "FULLSCREEN", px + 28, py + 57, T.col.text)
  put(pv, T.cb[1], px + 112, py + 55)
  H.text(pv, "SCREEN SHAKE", px + 128, py + 57, T.col.text)

  local ax, ay, aw, ah = px + 10, py + 71, pw - 20, 86
  nine(pv, T.pa, ax, ay, aw, ah, T.sp.panel_alt)
  local ry = ay + 5
  key(pv, T, ax + 8, ry, 16, "A"); key(pv, T, ax + 26, ry, 16, "D")
  H.text(pv, "MOVE", ax + 48, ry + 4, T.col.alt)
  key(pv, T, ax + 100, ry, 40, "SPACE")
  H.text(pv, "JUMP", ax + 146, ry + 4, T.col.alt)
  ry = ry + 19
  put(pv, T.ms[1], ax + 10, ry)
  H.text(pv, "HOLD TO AIM AND CHARGE", ax + 28, ry + 4, T.col.alt)
  ry = ry + 19
  put(pv, T.ms[3], ax + 10, ry)
  H.text(pv, "RELEASE TO KICK", ax + 28, ry + 4, T.col.alt)
  ry = ry + 19
  put(pv, T.ms[2], ax + 10, ry)
  H.text(pv, "CANCEL", ax + 28, ry + 4, T.col.alt)
  key(pv, T, ax + 100, ry, 16, "R")
  H.text(pv, "RESTART", ax + 122, ry + 4, T.col.alt)

  label_button(pv, T, "pressed", px + 50, py + 162, 72, "BACK")
  label_button(pv, T, "normal", px + pw - 54, py + 162, 80, "CREDITS")
  if T.deco then T.deco(pv, T, L) end

  H.tag(pv, title(T), 4, 255, P.white, P.ui)
  local name = "options_ui_" .. T.dir .. ".png"
  scaled(pv, 4):saveAs(REVIEW .. name)
  -- zoomed crop for checking pixels (temp, not a deliverable)
  local a = H.img(480, 200)
  H.blit(a, pv, 0, 0, 0, 70, 480, 200)
  scaled(a, 3):saveAs(TMP .. "crop_" .. T.code:lower() .. ".png")
  print("saved " .. name)
end

for _, T in ipairs(THEMES) do mock(T) end

do -- every frame of every asset, one band per theme
  local S, RH = 3, 54
  local BAND = RH * S + 34
  local sh = H.img(1440, 30 + #THEMES * BAND, P.gray)
  H.text(sh, "UI THEME OPTIONS: BUTTON N/H/P/D, PANEL, PANEL ALT, GRABBER, CHECKBOX, KEYCAP, MOUSE L/R/NONE, EXTRAS, TRACK, FILL", 12, 8, P.ink, { s = 2 })
  for i, T in ipairs(THEMES) do
    local y0 = 30 + (i - 1) * BAND
    H.text(sh, title(T), 12, y0 + 6, P.white, { s = 2, outline = P.ink })
    local r = H.img(480, RH)
    for k = 1, 4 do put(r, T.btn[k], 4 + (k - 1) * 52, 0) end
    local lab = { "START", "HOVER", "PRESS", "OFF" }
    for k, s in ipairs(BSTATES) do label_button(r, T, s, 28 + (k - 1) * 52, 26, 48, lab[k]) end
    put(r, T.pn, 216, 0); put(r, T.pa, 244, 0)
    put(r, T.gr[1], 274, 0); put(r, T.gr[2], 284, 0)
    put(r, T.cb[1], 298, 0); put(r, T.cb[2], 312, 0)
    put(r, T.kc, 330, 0); key(r, T, 350, 0, 16, "R"); key(r, T, 370, 0, 40, "SPACE")
    put(r, T.ms[1], 418, 0); put(r, T.ms[2], 432, 0); put(r, T.ms[3], 446, 0)
    put(r, T.tr, 216, 28); put(r, T.fl, 216, 38)
    slider(r, T, 256, 30, 72, 0.6); slider(r, T, 256, 44, 72, 0.2, true)
    local x = 336
    for _, k in ipairs(T.xn) do put(r, T.x[k], x, 28 + (T.x[k].height < 12 and 2 or 0)); x = x + T.x[k].width + 4 end
    put(sh, r, 0, y0 + 28, S)
    -- temp zoom of the button frames for checking
    local z = H.img(272, RH, P.gray)
    H.blit(z, r, 0, 0, 0, 0, 272, RH)
    scaled(z, 5):saveAs(TMP .. "btn_" .. T.code:lower() .. ".png")
  end
  sh:saveAs(REVIEW .. "options_ui_themes_sheet.png")
  print("saved options_ui_themes_sheet " .. sh.width .. "x" .. sh.height)
end
