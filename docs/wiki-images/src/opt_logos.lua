-- Option spread for the title logo and the app icon (round 2).
-- Writes docs/art-options/logos/logo_<letter>_<name>.png + .aseprite,
-- docs/art-options/icons/icon_<n>_<name>_64.png + _256.png, and review sheets
-- docs/art-review/options_logos_1.png, options_logos_2.png, options_icons.png.
-- Nothing in assets/ is touched; these are candidates to pick from.
-- Round 1's backing-object logos (B to I) and icons 3-5, 7-10 were rejected and
-- are no longer drawn. Logo A is the kept baseline; J onward are lettering-only.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/yeet_brand.lua")
local P, YP = H.P, Y.P
local pc = app.pixelColor
local LOGOS = H.ROOT .. "docs/art-options/logos/"
local ICONS = H.ROOT .. "docs/art-options/icons/"
local REVIEW = H.ROOT .. "docs/art-review/"
app.fs.makeAllDirectories(LOGOS)
app.fs.makeAllDirectories(ICONS)
app.fs.makeAllDirectories(REVIEW)

------------------------------------------------------------------ helpers
local function solid(im, x, y)
  return x >= 0 and y >= 0 and x < im.width and y < im.height and pc.rgbaA(im:getPixel(x, y)) > 0
end

local function rrect(im, x, y, w, h, r, c)
  for j = 0, h - 1 do
    for i = 0, w - 1 do
      local dx = i < r and (r - 1 - i) or (i >= w - r and (i - (w - r)) or -1)
      local dy = j < r and (r - 1 - j) or (j >= h - r and (j - (h - r)) or -1)
      if dx < 0 or dy < 0 or (dx + 0.5) ^ 2 + (dy + 0.5) ^ 2 <= r * r then H.px(im, x + i, y + j, c) end
    end
  end
end

local function crop(im, M)
  M = M or 2
  local x0, y0, x1, y1 = im.width, im.height, -1, -1
  for y = 0, im.height - 1 do
    for x = 0, im.width - 1 do
      if pc.rgbaA(im:getPixel(x, y)) > 0 then
        x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
      end
    end
  end
  local out = H.img(x1 - x0 + 1 + 2 * M, y1 - y0 + 1 + 2 * M)
  H.blit(out, im, M, M, x0, y0, x1 - x0 + 1, y1 - y0 + 1)
  return out
end

-- Face image -> extruded and outlined copy. o: sd, dx, dy, shadow, shades, ot, outline
local function styled(face, o)
  local w, h = face.width, face.height
  local out = H.img(w, h)
  for d = (o.sd or 0), 1, -1 do
    H.silhouette(out, face, d * (o.dx or 1), d * (o.dy or 1), 0, 0, w, h, false,
      (o.shades and o.shades[d]) or o.shadow)
  end
  H.blit(out, face, 0, 0)
  for _ = 1, (o.ot or 0) do A.outline(out, o.outline or P.ink, true) end
  return out
end

-- Recolour the top edge of every shape in the face (a 1 px lit rim).
local function top_highlight(face, c)
  local hit = {}
  for y = 0, face.height - 1 do
    for x = 0, face.width - 1 do
      if solid(face, x, y) and not solid(face, x, y - 1) then hit[#hit + 1] = { x, y } end
    end
  end
  for _, p in ipairs(hit) do face:drawPixel(p[1], p[2], c) end
end

-- Knock the single pixel off every convex corner, softening blocky glyphs.
local function round_corners(face)
  local hit = {}
  for y = 0, face.height - 1 do
    for x = 0, face.width - 1 do
      if solid(face, x, y) then
        for _, d in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
          if not solid(face, x + d[1], y) and not solid(face, x, y + d[2]) then hit[#hit + 1] = { x, y } end
        end
      end
    end
  end
  for _, p in ipairs(hit) do face:drawPixel(p[1], p[2], P.none) end
end

local function bitmap(im, rows, x, y, c, s)
  s = s or 1
  for j, row in ipairs(rows) do
    for i = 1, #row do
      if row:sub(i, i) == "#" then H.rect(im, x + (i - 1) * s, y + (j - 1) * s, s, s, c) end
    end
  end
end

------------------------------------------------------------------ letterforms
local function rep(row, n)
  local t = {}
  for _ = 1, n do t[#t + 1] = row end
  return t
end
local function cat(...)
  local t = {}
  for _, part in ipairs({ ... }) do
    if type(part) == "string" then t[#t + 1] = part else for _, r in ipairs(part) do t[#t + 1] = r end end
  end
  return t
end

-- Heavy sans, 10 rows, 2 px strokes everywhere.
local BOLD = {
  H = cat(rep("##   ##", 4), rep("#######", 2), rep("##   ##", 4)),
  A = cat("  ###  ", " ##### ", rep("##   ##", 3), rep("#######", 2), rep("##   ##", 3)),
  N = { "##   ##", "###  ##", "###  ##", "#### ##", "#######", "## ####", "##  ###", "##  ###", "##   ##", "##   ##" },
  D = cat("#####  ", "###### ", rep("##   ##", 6), "###### ", "#####  "),
  L = cat(rep("##    ", 8), rep("######", 2)),
  E = { "######", "######", "##    ", "##    ", "##### ", "##### ", "##    ", "##    ", "######", "######" },
  W = cat(rep("##     ##", 4), "##  #  ##", "## ### ##", "## ### ##", "#########", "#### ####", "###   ###"),
  I = rep("##", 10),
  T = cat(rep("######", 2), rep("  ##  ", 8)),
  C = cat(" ##### ", "#######", "##   ##", rep("##     ", 4), "##   ##", "#######", " ##### "),
  R = { "#####  ", "###### ", "##   ##", "##   ##", "###### ", "#####  ", "## ##  ", "##  ## ", "##   ##", "##   ##" },
}

-- Slab serif, 11 rows, thick stems and thin hairlines.
local SERIF = {
  H = cat("###  ###", rep(" ##  ## ", 4), " ###### ", rep(" ##  ## ", 4), "###  ###"),
  A = { "   ##   ", "   ##   ", "  # ##  ", "  # ##  ", "  #  ## ", " #   ## ", " ###### ", " #   ## ", " #   ## ", " #   ## ", "### ####" },
  N = { "###  ###", " ##   # ", " ###  # ", " # ## # ", " # ## # ", " #  ### ", " #  ### ", " #   ## ", " #   ## ", " #   ## ", "###   # " },
  D = cat("######  ", " ##  ## ", rep(" ##   ##", 7), " ##  ## ", "######  "),
  L = cat("####    ", rep(" ##     ", 7), " ##    #", " ##   ##", "########"),
  E = { "########", " ##   ##", " ##    #", " ##     ", " ##  #  ", " #####  ", " ##  #  ", " ##     ", " ##    #", " ##   ##", "########" },
  W = { "### ### ###", " ##  #  ## ", " ##  #  ## ", " ##  #  ## ", " ## ### ## ", " ## ### ## ", " ## # # ## ", " #### #### ", "  ### ###  ", "  ##   ##  ", "  ##   ##  " },
  I = cat("####", rep(" ## ", 9), "####"),
  T = cat("########", "#  ##  #", "#  ##  #", rep("   ##   ", 7), "  ####  "),
  C = cat("  ##### ", " ##   ##", "##     #", rep("##      ", 5), "##     #", " ##   ##", "  ##### "),
  R = { "######  ", " ##  ## ", " ##   ##", " ##   ##", " ##  ## ", " #####  ", " ## ##  ", " ##  ## ", " ##  ## ", " ##   ##", "###   ##" },
}

-- o: s or sx/sy (scale), gap and space (font px), lean (px rows per 1 px of italic shift)
local function textw(font, str, o)
  o = o or {}
  local sx, gap, sp = o.sx or o.s or 1, o.gap or 1, o.space or 4
  local w = 0
  for i = 1, #str do
    local ch = str:sub(i, i)
    if ch == " " then w = w + sp * sx else w = w + (#font[ch][1] + gap) * sx end
  end
  w = w - gap * sx
  if o.lean then w = w + (#font.H * (o.sy or o.s or 1) - 1) // o.lean end
  return w
end

local function text(im, font, str, x, y, c, o)
  o = o or {}
  local sx, sy, gap, sp = o.sx or o.s or 1, o.sy or o.s or 1, o.gap or 1, o.space or 4
  local hh = #font.H * sy
  if o.align == "center" then x = x - textw(font, str, o) // 2 end
  for i = 1, #str do
    local ch = str:sub(i, i)
    if ch == " " then
      x = x + sp * sx
    else
      local g = font[ch]
      for r = 1, #g do
        local row = g[r]
        for j = 0, sy - 1 do
          local py = (r - 1) * sy + j
          local sh = o.lean and (hh - 1 - py) // o.lean or 0
          for k = 1, #row do
            if row:sub(k, k) == "#" then H.rect(im, x + (k - 1) * sx + sh, y + py, sx, 1, c) end
          end
        end
      end
      x = x + (#g[1] + gap) * sx
    end
  end
  return x
end

-- Three speed bars whose right ends follow the italic slope of a line hh px tall.
local function speed(face, xr, y, hh, lean, lens, th, c)
  for i, f in ipairs({ 0.14, 0.44, 0.74 }) do
    local r = math.floor(hh * f)
    H.rect(face, xr - lens[i] + (hh - 1 - r) // lean, y + r, lens[i], th, c)
  end
end

------------------------------------------------------------------ logos
local CARD = { sd = 3, shades = { P.card_m, P.card_d, P.card_dd }, ot = 2 }
local FW, FC = 300, 150 -- working canvas and its centre line

-- The shipped lettering (5x7 font at 3x) as a bare face, HANDLE optionally nudged.
-- Letter cells are 18 px apart: HANDLE starts at FC-52, WITH CARE at FC-72.
local function block_face(hx)
  local face = H.img(FW, 130)
  H.text(face, "HANDLE", hx or FC, 10, P.cream, { s = 3, align = "center" })
  H.text(face, "WITH CARE", FC, 38, P.cream, { s = 3, align = "center" })
  return face
end

-- A (kept): the shipped cardboard block logo with a lit top rim and a stepped side.
local function logo_block()
  local face = block_face()
  top_highlight(face, P.white)
  return crop(styled(face, CARD))
end

-- Two centred lines in one font.
local function two_lines(font, o, c, gap)
  local face = H.img(FW, 130)
  local oc = { align = "center" }
  for k, v in pairs(o) do oc[k] = v end
  local lh = #font.H * (o.sy or o.s)
  text(face, font, "HANDLE", FC, 12, c, oc)
  text(face, font, "WITH CARE", FC, 12 + lh + gap, c, oc)
  return face
end

-- J: A's recipe in the heavy sans, so every stroke is a third thicker.
local function logo_heavy()
  local face = two_lines(BOLD, { s = 2 }, P.cream, 8)
  top_highlight(face, P.white)
  return crop(styled(face, CARD))
end

-- K: three-line stack, WITH set small between rules, cream on a dark red side.
local function logo_stack()
  local face = H.img(FW, 130)
  local big = { s = 3, align = "center" }
  local hw = textw(BOLD, "HANDLE", big)
  text(face, BOLD, "HANDLE", FC, 12, P.cream, big)
  local ww = textw(BOLD, "WITH", { s = 1 })
  text(face, BOLD, "WITH", FC, 49, P.cream, { s = 1, align = "center" })
  local bar = (hw - ww) // 2 - 6
  H.rect(face, FC - hw // 2, 52, bar, 4, P.cream)
  H.rect(face, FC + hw // 2 - bar + hw % 2, 52, bar, 4, P.cream)
  -- CARE letterspaced out to HANDLE's width
  text(face, BOLD, "CARE", FC, 66, P.cream, { s = 3, gap = 6, align = "center" })
  top_highlight(face, P.white)
  return crop(styled(face, { sd = 3, shades = { P.door, P.carpet, P.carpet_d }, ot = 2 }))
end

-- L: everything on one line, white on a YEET orange side.
local function logo_oneline()
  local face = H.img(FW, 60)
  text(face, BOLD, "HANDLE WITH CARE", FC, 12, P.white, { s = 2, align = "center" })
  return crop(styled(face, { sd = 3, shades = { YP.orange, YP.orange, YP.orange_d }, ot = 2 }))
end

-- M: slab serif in brass with a deep hotel-red side.
local function logo_slab()
  local face = two_lines(SERIF, { s = 2 }, P.gold, 8)
  top_highlight(face, P.cream)
  return crop(styled(face, { sd = 3, shades = { P.door, P.carpet, P.carpet_d }, ot = 2 }))
end

-- N: heavy sans with softened corners and a tall side dropping straight down.
local function logo_round()
  local face = two_lines(BOLD, { s = 2 }, P.cream, 11)
  round_corners(face)
  top_highlight(face, P.white)
  return crop(styled(face, { sd = 5, dx = 0, shades = { P.card, P.card_m, P.card_m, P.card_d, P.card_dd }, ot = 2 }))
end

-- O: extended heavy sans, hotel red face, gold side thrown down-left.
local function logo_wide()
  local face = two_lines(BOLD, { sx = 3, sy = 2 }, P.red, 8)
  top_highlight(face, H.c("ff8f86"))
  return crop(styled(face, { sd = 3, dx = -1, shades = { P.gold, P.gold, P.gold_d }, ot = 2 }))
end

-- P / Q: bold italic, both lines level, speed bars filling the top line's indent.
local function rush_face(c, bar)
  local o = { s = 2, lean = 3, space = 6 }
  local face = H.img(FW, 130)
  local X = 60
  local w1, w2 = textw(BOLD, "HANDLE", o), textw(BOLD, "WITH CARE", o)
  local x1 = X + w2 - w1 + 8
  text(face, BOLD, "HANDLE", x1, 12, c, o)
  speed(face, x1 - 5, 12, 20, 3, { 30, 40, 24 }, 3, bar)
  text(face, BOLD, "WITH CARE", X, 40, c, o)
  return face
end
local function logo_rush()
  return crop(styled(rush_face(P.white, YP.orange), { sd = 3, shades = { YP.orange, YP.orange, YP.orange_d }, ot = 2 }))
end
local function logo_rush_card()
  local face = rush_face(P.cream, P.card)
  top_highlight(face, P.white)
  return crop(styled(face, CARD))
end

-- R: italic with size contrast: HANDLE, a small WITH, then CARE half as big again.
local function logo_rush_big()
  local face = H.img(FW, 130)
  local o2, o1, o3 = { s = 2, lean = 3 }, { s = 1, lean = 3 }, { s = 3, lean = 3 }
  local x1, y = 70, 12
  local xe = text(face, BOLD, "HANDLE", x1, y, P.yellow, o2)
  local xw = text(face, BOLD, "WITH", xe + 4, y + 10, P.yellow, o1)
  local cw = textw(BOLD, "CARE", o3)
  local cx = xw - 1 - cw - 6
  text(face, BOLD, "CARE", cx, y + 28, P.yellow, o3)
  speed(face, cx - 6, y + 28, 30, 3, { 26, 36, 20 }, 4, YP.orange)
  top_highlight(face, P.cream)
  return crop(styled(face, { sd = 3, shades = { YP.orange, YP.orange_d, YP.orange_d }, ot = 2 }))
end

-- Short strip of tape centred on cx,cy at angle ang, inked and laid over a logo.
local function strip(out, cx, cy, ang, hl, hw, colfn)
  local layer = H.img(out.width, out.height)
  local ca, sa = math.cos(ang), math.sin(ang)
  for y = cy - hl - 2, cy + hl + 2 do
    for x = cx - hl - 2, cx + hl + 2 do
      local dx, dy = x - cx, y - cy
      local u, v = dx * ca + dy * sa, -dx * sa + dy * ca
      if math.abs(u) <= hl and math.abs(v) <= hw then layer:drawPixel(x, y, colfn(u, v)) end
    end
  end
  A.outline(layer, P.ink, true)
  H.blit(out, layer, 0, 0)
end

-- S: A stuck up with a strip of parcel tape over two opposite corners.
local function logo_taped()
  local face = block_face()
  top_highlight(face, P.white)
  local out = styled(face, CARD)
  local function tape(u, v) return v > 1.5 and H.c("c4b592") or P.tape end
  strip(out, FC - 52, 11, -math.pi / 4, 10, 3, tape)
  strip(out, FC + 72 + 2, 60, -math.pi / 4, 10, 3, tape)
  return crop(out)
end

-- U: A with a red "this way up" arrow pair tucked into the short top line.
local function logo_arrows()
  local UP = { " #   # ", "### ###", " #   # ", " #   # ", " #   # ", "       ", "#######" }
  local face = block_face(FC - 13)
  bitmap(face, UP, FC - 13 + 53 + 6, 10, P.red, 3)
  top_highlight(face, P.white)
  return crop(styled(face, CARD))
end

local logos = {
  { "a", "block", "A (KEPT)", "CARDBOARD BLOCK", logo_block() },
  { "j", "heavy", "J", "HEAVY BLOCK", logo_heavy() },
  { "k", "stack", "K", "STACK, SMALL WITH", logo_stack() },
  { "l", "oneline", "L", "ONE LINE, ORANGE", logo_oneline() },
  { "m", "slab", "M", "BRASS SLAB", logo_slab() },
  { "n", "round", "N", "ROUNDED, TALL DROP", logo_round() },
  { "o", "wide", "O", "WIDE, RED + GOLD", logo_wide() },
  { "p", "rush", "P", "RUSH ITALIC", logo_rush() },
  { "q", "rush_card", "Q", "RUSH, CARDBOARD", logo_rush_card() },
  { "r", "rush_big", "R", "RUSH, BIG CARE", logo_rush_big() },
  { "s", "taped", "S", "A + TAPED CORNERS", logo_taped() },
  { "u", "arrows", "U", "A + THIS WAY UP", logo_arrows() },
}
for _, l in ipairs(logos) do
  local im = l[5]
  local name = "logo_" .. l[1] .. "_" .. l[2]
  local spr = Sprite(im.width, im.height, ColorMode.RGB)
  spr.cels[1].image = im
  spr.layers[1].name = "Art"
  spr:saveAs(LOGOS .. name .. ".aseprite")
  spr:saveCopyAs(LOGOS .. name .. ".png")
  spr:close()
  print(string.format("%s %dx%d", name, im.width, im.height))
end

------------------------------------------------------------------ icons
local function icon_bg(face, lip, hi)
  local im = H.img(64, 64)
  rrect(im, 0, 0, 64, 64, 11, P.ink)
  rrect(im, 1, 1, 62, 62, 10, lip)
  rrect(im, 1, 1, 62, 59, 10, hi)
  rrect(im, 1, 3, 62, 57, 10, face)
  return im
end
local INSIDE = H.img(64, 64)
rrect(INSIDE, 1, 1, 62, 62, 10, P.ink)

-- Composite a 64x64 layer onto an icon, keeping it inside the rounded border.
local function clipped(im, layer)
  for y = 0, 63 do
    for x = 0, 63 do
      local p = layer:getPixel(x, y)
      if pc.rgbaA(p) > 0 and solid(INSIDE, x, y) then im:drawPixel(x, y, p) end
    end
  end
end

local PK, HEAD = H.load("package/package_intact.png"), H.load("player/player_head.png")
-- opaque bounds: package 27x27 at (2,4); aim-forward head 31x26 at (11,1) of frame 2
local function package(im, x, y) H.blit(im, PK, x, y, 2, 4, 27, 27, false, 2) end
local function head(im, x, y) H.blit(im, HEAD, x, y, 2 * 48 + 11, 1, 31, 26, false, 2) end

local RED = { P.door, P.door_d, P.door_l }
local ORANGE = { YP.orange, YP.orange_d, YP.orange_l }

local function icon_package(bg)
  local im = icon_bg(bg[1], bg[2], bg[3])
  package(im, 5, 4)
  return im
end

local function icon_courier_package()
  local im = icon_bg(ORANGE[1], ORANGE[2], ORANGE[3])
  local l = H.img(64, 64)
  head(l, -7, -1)
  package(l, 27, 30)
  clipped(im, l)
  return im
end

-- Numbers match round 1; the gaps are the rejected options.
local icons = {
  { 1, "package_red", "PACKAGE ON HOTEL RED", icon_package(RED) },
  { 2, "package_orange", "PACKAGE ON YEET ORANGE", icon_package(ORANGE) },
  { 6, "courier_package", "COURIER + PACKAGE", icon_courier_package() },
}

local function scaled(src, s)
  local im = H.img(src.width * s, src.height * s)
  H.blit(im, src, 0, 0, 0, 0, src.width, src.height, false, s)
  return im
end
local function half(src) -- nearest-neighbour 64 -> 32
  local im = H.img(32, 32)
  for y = 0, 31 do for x = 0, 31 do im:drawPixel(x, y, src:getPixel(x * 2 + 1, y * 2 + 1)) end end
  return im
end
for _, ic in ipairs(icons) do
  local name = "icon_" .. ic[1] .. "_" .. ic[2]
  ic[4]:saveAs(ICONS .. name .. "_64.png")
  scaled(ic[4], 4):saveAs(ICONS .. name .. "_256.png")
  print(name .. " 64x64 + 256x256")
end

------------------------------------------------------------------ previews
local function tag2(im, str, x, y)
  local w = H.textw(str, 2) + 12
  H.rect(im, x, y, w, 22, P.ui)
  H.text(im, str, x + 6, y + 4, P.white, { s = 2 })
  return w
end

-- Sheet 1: every logo at 3x on wallpaper, A first.
do
  local S, COLS, CW = 3, 3, 740
  local rows, y = {}, 16
  for i = 1, #logos, COLS do
    local mh = 0
    for j = i, math.min(i + COLS - 1, #logos) do mh = math.max(mh, logos[j][5].height) end
    rows[#rows + 1] = { y = y, h = mh }
    y = y + 30 + mh * S + 30
  end
  local pv = H.img(COLS * CW + 16, y, P.wall)
  for i, l in ipairs(logos) do
    local col, row = (i - 1) % COLS, rows[(i - 1) // COLS + 1]
    local x = 16 + col * CW
    tag2(pv, string.format("%s: %s  %dx%d", l[3], l[4], l[5].width, l[5].height), x, row.y)
    H.blit(pv, l[5], x, row.y + 30, 0, 0, l[5].width, l[5].height, false, S)
  end
  pv:saveAs(REVIEW .. "options_logos_1.png")
  print("options_logos_1 " .. pv.width .. "x" .. pv.height)
end

-- Sheet 2: every logo at 1x over a hallway strip and over the dark menu colour.
do
  local COLS, SW, HH, DH = 5, 250, 150, 96
  local CH = 28 + HH + 4 + DH + 16
  local pv = H.img(COLS * (SW + 12) + 12, math.ceil(#logos / COLS) * CH + 8, H.c("5a5d63"))
  for i, l in ipairs(logos) do
    local x = 12 + ((i - 1) % COLS) * (SW + 12)
    local y = 8 + ((i - 1) // COLS) * CH
    tag2(pv, l[3] .. ": " .. l[2]:gsub("_", " "):upper(), x, y)
    local hall = H.img(SW, HH)
    H.hallway(hall, 128)
    H.door(hall, 8, 128, 12)
    H.door(hall, SW - 44, 128, 13)
    local lg = l[5]
    H.blit(hall, lg, (SW - lg.width) // 2, math.max(2, (88 - lg.height) // 2))
    H.blit(pv, hall, x, y + 28)
    local dark = H.img(SW, DH, P.ui)
    H.blit(dark, lg, (SW - lg.width) // 2, (DH - lg.height) // 2)
    H.blit(pv, dark, x, y + 28 + HH + 4)
  end
  pv:saveAs(REVIEW .. "options_logos_2.png")
  print("options_logos_2 " .. pv.width .. "x" .. pv.height)
end

-- Icon sheet: 4x, then 64 px and 32 px on a light and a dark ground.
do
  local CW, CH = 284, 28 + 256 + 8 + 76 + 12
  local pv = H.img(#icons * CW + 16, CH + 8, H.c("5a5d63"))
  for i, ic in ipairs(icons) do
    local x, y = 16 + (i - 1) * CW, 8
    tag2(pv, ic[1] .. ": " .. ic[3], x, y)
    H.blit(pv, ic[4], x, y + 28, 0, 0, 64, 64, false, 4)
    local small = half(ic[4])
    for k, bg in ipairs({ H.c("ececec"), H.c("1e1e22") }) do
      local bx, by = x + (k - 1) * 130, y + 28 + 256 + 8
      H.rect(pv, bx, by, 126, 76, bg)
      H.blit(pv, ic[4], bx + 8, by + 6)
      H.blit(pv, small, bx + 84, by + 22)
    end
  end
  pv:saveAs(REVIEW .. "options_icons.png")
  print("options_icons " .. pv.width .. "x" .. pv.height)
end

-- Optional close-ups for checking letter shapes: set HWC_OPT_DEBUG to a folder.
local dbg = os.getenv("HWC_OPT_DEBUG")
if dbg and dbg ~= "" then
  for _, l in ipairs(logos) do
    local im = H.img(l[5].width * 5 + 20, l[5].height * 5 + 20, P.wall)
    H.blit(im, l[5], 10, 10, 0, 0, l[5].width, l[5].height, false, 5)
    im:saveAs(dbg .. "/logo_" .. l[1] .. ".png")
  end
end
