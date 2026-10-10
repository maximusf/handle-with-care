-- Screen OPTIONS: HUD, win screen and lose screen components plus 480x270
-- layout mockups for the user to choose from.
-- Writes docs/art-options/screens/<name>.png (+ .aseprite, strips are
-- horizontal with one tag per frame), 4x mock previews to
-- docs/art-review/options_<hud|win|lose>_<letter>.png and a labelled
-- component sheet to docs/art-review/options_screens_components.png.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
dofile(H.SRC .. "ui_common.lua")
dofile(H.SRC .. "yeet_brand.lua")
local P = H.P
local pc = app.pixelColor
local OUT = H.ROOT .. "docs/art-options/screens/"
local REVIEW = H.ROOT .. "docs/art-review/"
local TMP = "C:/Users/maxda/AppData/Local/Temp/claude/G--System2-Documents-Game-Dev-Projects-parcel-runner/f9b6e383-9339-40a2-8baf-8ad65c5d35c5/scratchpad/opt-screens/"
app.fs.makeAllDirectories(OUT)
app.fs.makeAllDirectories(REVIEW)
app.fs.makeAllDirectories(TMP)

local CARD_L = H.c("f6cc86")
local PAPER = Y.P.white
local PAPER_D = H.c("d9d3c4")
local W, HH, FLOOR = 480, 270, 192

------------------------------------------------------------------ helpers
local function save_frames(name, frames, tags)
  local w, h = frames[1].width, frames[1].height
  local spr = Sprite(w, h, ColorMode.RGB)
  local layer = spr.layers[1]
  layer.name = "Art"
  for i, im in ipairs(frames) do
    if i > 1 then spr:newEmptyFrame() end
    spr:newCel(layer, i, im, Point(0, 0))
  end
  for i, t in ipairs(tags or {}) do
    local tag = spr:newTag(i, i); tag.name = t
  end
  spr:saveAs(OUT .. name .. ".aseprite")
  spr:close()
  local strip = H.img(w * #frames, h)
  for i, im in ipairs(frames) do H.blit(strip, im, (i - 1) * w, 0) end
  strip:saveAs(OUT .. name .. ".png")
  print(string.format("saved %s  frame %dx%d  frames %d", name, w, h, #frames))
end

local function scaled(src, s)
  local im = H.img(src.width * s, src.height * s)
  H.blit(im, src, 0, 0, 0, 0, src.width, src.height, false, s)
  return im
end

local function sub(src, x, y, w, h)
  local im = H.img(w, h)
  H.blit(im, src, 0, 0, x, y, w, h)
  return im
end

-- Stretch src like a Godot StyleBoxTexture: fixed margins, stretched centre.
local function nine(dst, src, x, y, w, h, m)
  m = m or 4
  local sw, sh = src.width, src.height
  local function map(d, n, sn)
    if d < m then return d end
    if d >= n - m then return sn - (n - d) end
    return m + ((d - m) * (sn - 2 * m)) // (n - 2 * m)
  end
  for j = 0, h - 1 do
    for i = 0, w - 1 do
      local p = src:getPixel(map(i, w, sw), map(j, h, sh))
      if pc.rgbaA(p) > 0 then H.px(dst, x + i, y + j, p) end
    end
  end
end

local function drawmap(im, x, y, rows, pal)
  for j, row in ipairs(rows) do
    for i = 1, #row do
      local c = pal[row:sub(i, i)]
      if c then H.px(im, x + i - 1, y + j - 1, c) end
    end
  end
end

-- Draw with fn into a scratch image, wrap it in an ink outline, blit.
local function outlined(im, x, y, w, h, fn, line)
  local t = H.img(w + 2, h + 2)
  fn(t, 1, 1)
  A.outline(t, line or P.ink, true)
  H.blit(im, t, x - 1, y - 1)
end

local function rtext(im, str, xr, y, c, o)
  o = o or {}
  return H.text(im, str, xr - H.textw(str, o.s or 1), y, c, o)
end

-- Text image stretched by sx, sy (tall stamp lettering).
local function stext(str, c, sx, sy)
  local w = H.textw(str, 1)
  local t = H.img(w, 7)
  H.text(t, str, 0, 0, c)
  local out = H.img(w * sx, 7 * sy)
  for j = 0, 6 do for i = 0, w - 1 do
    if pc.rgbaA(t:getPixel(i, j)) > 0 then H.rect(out, i * sx, j * sy, sx, sy, c) end
  end end
  return out
end

-- Punch text-shaped holes (knockout lettering on a filled bar).
local function knockout(im, str, cx, y)
  local w = H.textw(str, 1)
  local t = H.img(w, 7)
  H.text(t, str, 0, 0, P.ink)
  for j = 0, 6 do for i = 0, w - 1 do
    if pc.rgbaA(t:getPixel(i, j)) > 0 then im:drawPixel(cx - w // 2 + i, y + j, P.none) end
  end end
end

-- Worn rubber-stamp look: knock random pixels out of the inked shape.
local function rough(im, seed, pct)
  math.randomseed(seed)
  for y = 0, im.height - 1 do for x = 0, im.width - 1 do
    if pc.rgbaA(im:getPixel(x, y)) > 0 and math.random() < pct then im:drawPixel(x, y, P.none) end
  end end
  for _ = 1, math.max(2, im.width // 30) do -- a few dry streaks
    local x, y, n = math.random(4, im.width - 12), math.random(2, im.height - 3), math.random(3, 6)
    for i = 0, n do im:drawPixel(x + i, y, P.none) end
  end
end

-- Vertical shear: columns stay intact, so pixel text survives the tilt.
local function shear(src, slope)
  local rise = math.floor((src.width - 1) * slope)
  local out = H.img(src.width, src.height + rise)
  for x = 0, src.width - 1 do
    local off = rise - math.floor(x * slope)
    for y = 0, src.height - 1 do
      local p = src:getPixel(x, y)
      if pc.rgbaA(p) > 0 then out:drawPixel(x, y + off, p) end
    end
  end
  return out
end

local function desaturate(im, amt)
  for y = 0, im.height - 1 do for x = 0, im.width - 1 do
    local p = im:getPixel(x, y)
    local r, g, b = pc.rgbaR(p), pc.rgbaG(p), pc.rgbaB(p)
    local l = (r * 3 + g * 6 + b) // 10
    local function m(v) return math.floor(v + (l - v) * amt + 0.5) end
    im:drawPixel(x, y, pc.rgba(m(r), m(g), m(b), 255))
  end end
end

local function barcode(im, x, y, w, h, seed, c)
  math.randomseed(seed)
  local i = 0
  while i < w do
    local bw = math.random(1, 2)
    if i + bw > w then bw = w - i end
    H.rect(im, x + i, y, bw, h, c)
    i = i + bw + math.random(1, 2)
  end
end

local function dashes(im, x0, x1, y, c, on, off)
  on, off = on or 3, off or 2
  for x = x0, x1, on + off do H.rect(im, x, y, math.min(on, x1 - x + 1), 1, c) end
end

------------------------------------------------------------------ components
-- 15x16 purpose-made package icon (same three-face box as the 32px sprite).
local PKG = {
  "......###......",
  "....##TTT##....",
  "..##TTTTTtt##..",
  "##TTTTTTttTTT##",
  "#L##TTTttTT##R#",
  "#LLL##TTT##RRR#",
  "#LLLLL###RRRRR#",
  "#LLLLLL#RRRRRR#",
  "#LLLLLL#RRRRRR#",
  "#LLLLLL#RRccRR#",
  "#LLLLLL#RRccRR#",
  "#LLLLLL#RRRRRR#",
  "##LLLLL#RRRRR##",
  "..##LLL#RRR##..",
  "....##L#R##....",
  "......###......",
}
-- crushed box for the lost state: flattened, lid torn open
local PKG_LOST = {
  "...............",
  "...............",
  "...............",
  "...............",
  ".........##....",
  "..##....#TT#...",
  ".#TT#..#TTT#...",
  ".#TTT##TT##.###",
  "##LTTTTT#RR#RR#",
  "#LL##TT#RRRRRR#",
  "#LLLL##RRR#RRR#",
  "#LL#LL#RR#RRRR#",
  "##LLLL#RRRRR###",
  "..##LL#RRR##...",
  "....######.....",
  "...............",
}
local PAL_PKG = { ["#"] = P.ink, T = CARD_L, L = P.card, R = P.card_m, t = P.tape, c = P.cream }
local PAL_LOST = { ["#"] = P.ink, T = P.mat_n, L = P.mat_nd, R = H.c("4b4d52") }

local function small_check(im, x, y) -- 9x7 body
  outlined(im, x, y, 9, 7, function(t, ox, oy)
    H.line(t, ox, oy + 3, ox + 2, oy + 5, P.green, 2)
    H.line(t, ox + 2, oy + 5, ox + 7, oy, P.green, 2)
  end)
end
local function small_x(im, x, y) -- 8x8 body
  outlined(im, x, y, 8, 8, function(t, ox, oy)
    H.line(t, ox, oy, ox + 6, oy + 6, P.xred, 2)
    H.line(t, ox + 6, oy, ox, oy + 6, P.xred, 2)
  end)
end

local function slot(state)
  local im = H.img(20, 20)
  local map, pal = PKG, PAL_PKG
  if state == "lost" then map, pal = PKG_LOST, PAL_LOST end
  if state == "active" then
    local t = H.img(20, 20)
    drawmap(t, 2, 2, map, pal)
    A.outline(t, P.white, true)
    A.outline(t, P.white, false)
    H.blit(im, t, 0, 0)
  else
    drawmap(im, 2, 2, map, pal)
  end
  if state == "delivered" then small_check(im, 9, 11) end
  if state == "lost" then small_x(im, 10, 2) end
  return im
end
local SLOTS = { "waiting", "active", "delivered", "lost" }
local slots = {}
for i, s in ipairs(SLOTS) do slots[i] = slot(s); slots[s] = slots[i] end
save_frames("hud_package_slot", slots, SLOTS)

local function bullet(state)
  local im = H.img(8, 8)
  H.rect(im, 1, 0, 6, 8, P.ink); H.rect(im, 0, 1, 8, 6, P.ink)
  if state == "pending" then
    H.rect(im, 1, 1, 6, 6, P.concrete_l); H.rect(im, 2, 2, 4, 4, P.ui_l)
  elseif state == "done" then
    H.rect(im, 1, 1, 6, 6, P.green)
    for _, p in ipairs({ { 1, 4 }, { 2, 5 }, { 3, 4 }, { 4, 3 }, { 5, 2 }, { 2, 4 }, { 3, 5 }, { 6, 2 } }) do
      im:drawPixel(p[1], p[2], P.white)
    end
  else
    H.rect(im, 1, 1, 6, 6, P.xred)
    for i = 2, 5 do im:drawPixel(i, i, P.white); im:drawPixel(7 - i, i, P.white) end
  end
  return im
end
local BULLETS = { "pending", "done", "failed" }
local bullets = {}
for i, s in ipairs(BULLETS) do bullets[i] = bullet(s); bullets[s] = bullets[i] end
save_frames("hud_objective_bullet", bullets, BULLETS)

local function key_r()
  local im = H.img(28, 12)
  H.rect(im, 1, 0, 10, 12, P.ink); H.rect(im, 0, 1, 12, 10, P.ink)
  H.rect(im, 1, 1, 10, 8, P.white)
  H.rect(im, 1, 9, 10, 2, P.concrete)
  H.text(im, "R", 4, 1, P.ink)
  local ARROW = {
    "...####...",
    "..#....#.#",
    ".#......##",
    ".#.....###",
    ".#........",
    ".#........",
    ".#......#.",
    "..#....#..",
    "...####...",
  }
  outlined(im, 16, 2, 10, 9, function(t, ox, oy) drawmap(t, ox, oy, ARROW, { ["#"] = P.white }) end)
  return im
end
local keyr = key_r()
save_frames("hud_key_r", { keyr })

local function star(kind)
  local im = H.img(16, 16)
  local pts = {}
  for i = 0, 9 do
    local a = -math.pi / 2 + i * math.pi / 5
    local r = (i % 2 == 0) and 7.6 or 3.4
    pts[#pts + 1] = { 8 + math.cos(a) * r, 8.4 + math.sin(a) * r }
  end
  local function inside(px, py)
    local hit = false
    local j = #pts
    for i = 1, #pts do
      local xi, yi, xj, yj = pts[i][1], pts[i][2], pts[j][1], pts[j][2]
      if (yi > py) ~= (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi then hit = not hit end
      j = i
    end
    return hit
  end
  local m = {}
  for y = 0, 15 do for x = 0, 15 do m[y * 16 + x] = inside(x + 0.5, y + 0.5) end end
  local function at(x, y) return x >= 0 and y >= 0 and x < 16 and y < 16 and m[y * 16 + x] end
  for y = 0, 15 do for x = 0, 15 do
    if at(x, y) then
      local edge = not (at(x - 1, y) and at(x + 1, y) and at(x, y - 1) and at(x, y + 1))
      local lit = kind == "full" or (kind == "half" and x <= 7)
      local c
      if edge then c = P.ink
      elseif lit then c = y >= 9 and P.gold or P.yellow
      else c = y >= 9 and P.ui_l or P.ui_ll end
      im:drawPixel(x, y, c)
    end
  end end
  if kind ~= "empty" then im:drawPixel(6, 6, P.cream); im:drawPixel(7, 5, P.cream); im:drawPixel(7, 4, P.cream) end
  return im
end
local STARS = { "empty", "half", "full" }
local stars = {}
for i, s in ipairs(STARS) do stars[i] = star(s); stars[s] = stars[i] end
save_frames("star", stars, STARS)

local function stat_icon(kind)
  local im = H.img(12, 12)
  if kind == "delivered" then
    H.rect(im, 0, 0, 10, 10, P.ink)
    H.rect(im, 1, 1, 8, 2, CARD_L)
    H.rect(im, 1, 4, 8, 5, P.card)
    H.rect(im, 4, 1, 2, 2, P.tape)
    outlined(im, 4, 5, 7, 6, function(t, ox, oy)
      H.line(t, ox, oy + 2, ox + 1, oy + 3, P.green, 2)
      H.line(t, ox + 1, oy + 3, ox + 5, oy, P.green, 2)
    end)
  elseif kind == "destroyed" then
    drawmap(im, 0, 5, {
      "..#....#...",
      ".#T#..#T#..",
      "#TTT##TTT#.",
      "#LL#TT#RRR#",
      "#LLL##RR#R#",
      "#L#LL#RRRR#",
      "###########",
    }, PAL_LOST)
    outlined(im, 5, 1, 6, 6, function(t, ox, oy)
      H.line(t, ox, oy, ox + 4, oy + 4, P.xred, 2)
      H.line(t, ox + 4, oy, ox, oy + 4, P.xred, 2)
    end)
  elseif kind == "kicks" then
    drawmap(im, 0, 0, {
      "............",
      "............",
      "..####......",
      "..#WW#......",
      "..#WW#......",
      "..#WWW##....",
      "..#WWWWW##..",
      ".#RWWWWWWW#.",
      ".#RRRRRRRRR#",
      ".#SSSSSSSSS#",
      ".###########",
      "............",
    }, { ["#"] = P.ink, W = P.white, R = P.red, S = P.concrete })
  else
    H.ellipse(im, 5, 6, 5, 5, P.white, P.ink)
    H.line(im, 5, 6, 5, 3, P.ink)
    H.line(im, 5, 6, 8, 6, P.ink)
    H.rect(im, 4, 0, 3, 1, P.ink)
  end
  return im
end
local STATS = { "delivered", "destroyed", "kicks", "time" }
local stat = {}
for i, s in ipairs(STATS) do stat[i] = stat_icon(s); stat[s] = stat[i] end
save_frames("stat_icons", stat, STATS)

---------------------------------------------------------------- stamps
local function stamp_frame(im, col)
  local w, h = im.width, im.height
  H.rect(im, 2, 0, w - 4, h, col); H.rect(im, 0, 2, w, h - 4, col); H.rect(im, 1, 1, w - 2, h - 2, col)
  im:clear(Rectangle(2, 2, w - 4, h - 4), P.none)
  im:drawPixel(2, 2, col); im:drawPixel(w - 3, 2, col); im:drawPixel(2, h - 3, col); im:drawPixel(w - 3, h - 3, col)
  H.rect(im, 5, 4, w - 10, 1, col); H.rect(im, 5, h - 5, w - 10, 1, col)
  H.rect(im, 4, 5, 1, h - 10, col); H.rect(im, w - 5, 5, 1, h - 10, col)
end

local function stamp_delivered()
  local im = H.img(80, 32)
  local col = P.green_d
  stamp_frame(im, col)
  local t = stext("DELIVERED", col, 1, 2)
  H.blit(im, t, 40 - t.width // 2, 9)
  for _, x in ipairs({ 8, 68 }) do -- side ticks
    H.rect(im, x, 12, 4, 2, col); H.rect(im, x, 18, 4, 2, col)
  end
  rough(im, 21, 0.045)
  return im
end
local function stamp_return()
  local im = H.img(80, 32)
  local col = P.xred
  stamp_frame(im, col)
  H.text(im, "RETURN TO", 40, 7, col, { align = "center" })
  H.rect(im, 7, 16, 66, 10, col)
  knockout(im, "SENDER", 40, 18)
  rough(im, 33, 0.04)
  return im
end
-- round 1 stamps: no longer exported, kept only because the lose C mock
-- (unchanged by request) is drawn with the old RETURN TO SENDER stamp
local st_return = stamp_return()

---------------------------------------------------------------- banners
-- style 1: ribbon with swallowtails, one line of 2x text
local function banner_ribbon(str, fill, dark)
  local bw = H.textw("SUCCESSFUL DELIVERY", 2) + 14 -- both ribbons share one size
  local im = H.img(bw + 36, 40)
  U.banner(im, 18, 1, bw, 30, fill, dark)
  H.text(im, str, 18 + bw // 2, 9, P.cream, { s = 2, outline = P.ink, ot = 1, shadow = dark, sd = 1, align = "center" })
  return im
end
-- style 2: rubber stamp, ink only on transparent
local function banner_stamp(str, col, seed)
  local tw = H.textw(str, 2)
  local im = H.img(tw + 24, 30)
  stamp_frame(im, col)
  H.text(im, str, im.width // 2, 8, col, { s = 2, align = "center" })
  rough(im, seed, 0.035)
  return im
end
-- style 3: shipping label strip with the YEET mark and a status block
local function banner_label(l1, l2, ok)
  local im = H.img(196, 40)
  H.box(im, 0, 0, 196, 40, PAPER, P.ink)
  H.rect(im, 1, 1, 35, 38, Y.P.orange)
  Y.mono(im, 3, 13, 2, Y.P.black, Y.P.white)
  H.rect(im, 36, 1, 1, 38, P.ink)
  H.text(im, l1, 42, 5, ok and P.green_d or P.red_d, { s = 2 })
  H.text(im, l2, 42, 22, P.ink, { s = 2 })
  H.rect(im, 163, 1, 1, 38, P.ink)
  H.rect(im, 164, 1, 31, 38, ok and P.green or P.xred)
  if ok then
    H.line(im, 171, 20, 176, 25, P.white, 3); H.line(im, 176, 25, 187, 13, P.white, 3)
  else
    H.line(im, 172, 13, 185, 26, P.white, 3); H.line(im, 185, 13, 172, 26, P.white, 3)
  end
  for y = 3, 36, 4 do H.rect(im, 160, y, 1, 2, PAPER_D) end
  return im
end
local BAN = {
  success = {
    ribbon = banner_ribbon("SUCCESSFUL DELIVERY", P.green, P.green_d),
    stamp = banner_stamp("SUCCESSFUL DELIVERY", P.green_d, 5),
    label = banner_label("SUCCESSFUL", "DELIVERY", true),
  },
  failed = {
    ribbon = banner_ribbon("FAILED DELIVERY", P.xred, P.red_d),
    stamp = banner_stamp("FAILED DELIVERY", P.xred, 9),
    label = banner_label("FAILED", "DELIVERY", false),
  },
}
for _, k in ipairs({ "success", "failed" }) do
  for _, st in ipairs({ "ribbon", "stamp", "label" }) do
    save_frames("banner_" .. k .. "_" .. st, { BAN[k][st] })
  end
end

---------------------------------------------------------------- stamps (round 2)
-- Chunky rubber stamps with the tilt baked in. Each one is drawn upright as a
-- one-colour mask, rotated by 4x4 supersampling with a 50% coverage cut (hard
-- pixels, no blending), tidied, then given a few chips and one lighter patch.
-- Every stamp is saved plain (ink on transparent) and backed (paper behind).
local SS = 4
local function opaque(im, x, y)
  return x >= 0 and y >= 0 and x < im.width and y < im.height and pc.rgbaA(im:getPixel(x, y)) > 0
end

local function rotmask(src, deg) -- positive deg rises to the right
  local a = math.rad(deg)
  local ca, sa = math.cos(a), math.sin(a)
  local sw, sh = src.width, src.height
  local dw = math.ceil(sw * math.abs(ca) + sh * math.abs(sa))
  local dh = math.ceil(sw * math.abs(sa) + sh * math.abs(ca))
  local m = { w = dw, h = dh }
  for y = 0, dh - 1 do for x = 0, dw - 1 do
    local n = 0
    for j = 0, SS - 1 do for i = 0, SS - 1 do
      local px, py = x + (i + 0.5) / SS - dw / 2, y + (j + 0.5) / SS - dh / 2
      if opaque(src, math.floor(px * ca - py * sa + sw / 2), math.floor(px * sa + py * ca + sh / 2)) then n = n + 1 end
    end end
    m[y * dw + x] = n * 2 >= SS * SS
  end end
  return m
end

local function mget(m, x, y) return x >= 0 and y >= 0 and x < m.w and y < m.h and m[y * m.w + x] end

-- Drop orphan pixels and fill pinholes left by the resample.
local function tidy(m)
  local set, clr = {}, {}
  for y = 0, m.h - 1 do for x = 0, m.w - 1 do
    local n = (mget(m, x - 1, y) and 1 or 0) + (mget(m, x + 1, y) and 1 or 0) +
      (mget(m, x, y - 1) and 1 or 0) + (mget(m, x, y + 1) and 1 or 0)
    if m[y * m.w + x] then
      if n == 0 then clr[#clr + 1] = y * m.w + x end
    elseif n == 4 then set[#set + 1] = y * m.w + x end
  end end
  for _, i in ipairs(clr) do m[i] = false end
  for _, i in ipairs(set) do m[i] = true end
end

-- Controlled wear: a handful of chips, and one patch that printed lighter.
local function wear(m, hull, seed, chips)
  math.randomseed(seed)
  local ink = {} -- chips only nibble the outer edge, never the lettering
  for y = 0, m.h - 1 do for x = 0, m.w - 1 do
    if m[y * m.w + x] and not (mget(hull, x - 5, y) and mget(hull, x + 5, y) and mget(hull, x, y - 5) and mget(hull, x, y + 5)) then
      ink[#ink + 1] = y * m.w + x
    end
  end end
  for _ = 1, chips do
    local i = ink[math.random(1, #ink)]
    local cx, cy, r = i % m.w, i // m.w, math.random(1, 2)
    for y = -r, r do for x = -r, r do
      local xx, yy = cx + x, cy + y
      if x * x + y * y <= r * r and xx >= 0 and xx < m.w and yy >= 0 and yy < m.h then
        m[yy * m.w + xx] = false
      end
    end end
  end
  local light = {}
  local cx, cy = m.w * (0.25 + math.random() * 0.5), m.h * (0.3 + math.random() * 0.4)
  local rx, ry = m.w * 0.14, m.h * 0.26
  for y = 0, m.h - 1 do for x = 0, m.w - 1 do
    local dx, dy = (x - cx) / rx, (y - cy + (x - cx) * 0.3) / ry
    if dx * dx + dy * dy <= 1 then light[y * m.w + x] = true end
  end end
  return light
end

local function mixc(a, b, t)
  local function m(f) return math.floor(f(a) * (1 - t) + f(b) * t + 0.5) end
  return pc.rgba(m(pc.rgbaR), m(pc.rgbaG), m(pc.rgbaB), 255)
end

local function compose(m, hull, col, seed, chips)
  tidy(m); tidy(hull)
  local light = wear(m, hull, seed, chips or 6)
  local lc = mixc(col, PAPER, 0.2)
  local plain, backed = H.img(m.w, m.h), H.img(m.w, m.h)
  for y = 0, m.h - 1 do for x = 0, m.w - 1 do
    local i = y * m.w + x
    if hull[i] then backed:drawPixel(x, y, PAPER) end
    if m[i] then
      local c = light[i] and lc or col
      plain:drawPixel(x, y, c); backed:drawPixel(x, y, c)
    end
  end end
  return { plain = plain, backed = backed }
end

local MG = 3 -- paper margin around the inked shape in the backed variant
local function hull_rect(w, h)
  local im = H.img(w, h, P.ink)
  for _, c in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { w - 1, 0 }, { w - 2, 0 }, { w - 1, 1 },
    { 0, h - 1 }, { 1, h - 1 }, { 0, h - 2 }, { w - 1, h - 1 }, { w - 2, h - 1 }, { w - 1, h - 2 } }) do
    im:drawPixel(c[1], c[2], P.none)
  end
  return im
end

-- heavy rounded frame: 3px outer rule, 2px gap, 2px inner rule
local function frame_a(im, x, y, w, h)
  local function rr(x0, y0, ww, hh, c)
    H.rect(im, x0 + 2, y0, ww - 4, hh, c); H.rect(im, x0, y0 + 2, ww, hh - 4, c); H.rect(im, x0 + 1, y0 + 1, ww - 2, hh - 2, c)
  end
  rr(x, y, w, h, P.ink)
  rr(x + 3, y + 3, w - 6, h - 6, P.none)
  rr(x + 5, y + 5, w - 10, h - 10, P.ink)
  H.rect(im, x + 7, y + 7, w - 14, h - 14, P.none)
end

-- Bold stamp lettering: the 5x7 font at 2x, thickened to 3px strokes and
-- letter-spaced so the gaps survive the rotation. Returns a 15px-tall mask.
local function bold(str)
  local parts, w = {}, 0
  for i = 1, #str do
    local ch = str:sub(i, i)
    local gw = H.textw(ch, 2)
    local g = H.img(gw + 1, 15)
    if ch ~= " " then
      local t = H.img(gw, 14)
      H.text(t, ch, 0, 0, P.ink, { s = 2 })
      for dy = 0, 1 do for dx = 0, 1 do H.blit(g, t, dx, dy) end end
    end
    parts[#parts + 1] = { g, w }
    w = w + gw + 4
  end
  local im = H.img(w - 3, 15)
  for _, q in ipairs(parts) do H.blit(im, q[1], q[2], 0) end
  return im
end
local function knock(im, t, x, y)
  for j = 0, t.height - 1 do for i = 0, t.width - 1 do
    if pc.rgbaA(t:getPixel(i, j)) > 0 then im:drawPixel(x + i, y + j, P.none) end
  end end
end

-- style a: classic rectangular double border
local function src_delivered_a()
  local t = bold("DELIVERED")
  local w, h = t.width + 22, 35
  local im = H.img(w + 2 * MG, h + 2 * MG)
  frame_a(im, MG, MG, w, h)
  H.blit(im, t, MG + 11, MG + 10)
  return im
end
local function src_return_a()
  local t1, t2 = bold("RETURN TO"), bold("SENDER")
  local w, h = t1.width + 22, 54
  local im = H.img(w + 2 * MG, h + 2 * MG)
  frame_a(im, MG, MG, w, h)
  H.blit(im, t1, MG + 11, MG + 10)
  local x2 = MG + (w - t2.width) // 2
  H.blit(im, t2, x2, MG + 29)
  local bl = x2 - (MG + 11) - 5
  for _, x in ipairs({ MG + 11, x2 + t2.width + 5 }) do
    H.rect(im, x, MG + 32, bl, 3, P.ink); H.rect(im, x, MG + 38, bl, 3, P.ink)
  end
  return im
end

-- style c: knockout word on a solid bar, with a badge or arrow
local function src_delivered_c()
  local t = bold("DELIVERED")
  local w, h = 36 + t.width + 7, 31
  local im = H.img(w + 2 * MG, h + 2 * MG)
  H.rect(im, MG + 18, MG + 4, w - 18, 23, P.ink)
  H.rect(im, MG + 18, MG, w - 18, 2, P.ink); H.rect(im, MG + 18, MG + 29, w - 18, 2, P.ink)
  H.ellipse(im, MG + 15, MG + 15, 17, 17, P.none)
  H.ellipse(im, MG + 15, MG + 15, 15, 15, P.ink)
  H.line(im, MG + 8, MG + 15, MG + 13, MG + 20, P.none, 4)
  H.line(im, MG + 13, MG + 20, MG + 22, MG + 9, P.none, 4)
  knock(im, t, MG + 36, MG + 8)
  return im
end
local function src_return_c()
  local t1, t2 = bold("RETURN TO"), bold("SENDER")
  local w, h = 36 + t2.width + 8, 43
  local im = H.img(w + 2 * MG, h + 2 * MG)
  H.blit(im, t1, MG + (w - t1.width) // 2, MG)
  H.rect(im, MG, MG + 18, w, 25, P.ink)
  for i = 0, 9 do H.rect(im, MG + 6 + i, MG + 30 - i, 1, 2 * i + 1, P.none) end -- arrow head, pointing back
  H.rect(im, MG + 16, MG + 28, 14, 5, P.none)
  knock(im, t2, MG + 36, MG + 23)
  return im
end

local function rect_stamp(src, deg, col, seed)
  return compose(rotmask(src, deg), rotmask(hull_rect(src.width, src.height), deg), col, seed)
end

-- style b: round postmark. Lettering is warped onto the ring (2x glyphs), a
-- bold icon sits in the middle. Drawn straight into the tilted frame.
local function star_in(dx, dy, R, r)
  local seg = math.pi / 5
  local v = math.atan(dx, -dy) % (2 * seg)
  local t = math.min(v, 2 * seg - v)
  local d = math.sqrt(dx * dx + dy * dy)
  local px, py = d * math.cos(t), d * math.sin(t)
  local bx, by = r * math.cos(seg), r * math.sin(seg)
  local function side(x, y) return (bx - R) * y - by * (x - R) end
  return side(px, py) * side(0, 0) >= 0
end
local function segdist(px, py, ax, ay, bx, by)
  local vx, vy = bx - ax, by - ay
  local t = math.max(0, math.min(1, ((px - ax) * vx + (py - ay) * vy) / (vx * vx + vy * vy)))
  local dx, dy = px - ax - vx * t, py - ay - vy * t
  return math.sqrt(dx * dx + dy * dy)
end
local function wrap(a) return (a + math.pi) % (2 * math.pi) - math.pi end

local function round_stamp(kind, deg, col, seed)
  local RT, D = 36, 104
  local top = bold(kind == "delivered" and "DELIVERED" or "RETURN TO")
  local bot = kind ~= "delivered" and bold("SENDER") or nil
  local a = math.rad(deg)
  local ca, sa = math.cos(a), math.sin(a)
  local function ink(qx, qy)
    local r = math.sqrt(qx * qx + qy * qy)
    if r >= 45.5 and r <= 49.5 then return true end
    if r >= 23.5 and r <= 25.5 then return true end
    local th = math.atan(qy, qx)
    if r >= RT - 7.5 and r < RT + 7.5 then
      local u = wrap(th + math.pi / 2) * RT + top.width / 2
      if u >= 0 and u < top.width and opaque(top, math.floor(u), math.floor(RT + 7.5 - r)) then return true end
      if bot then
        local ub = -wrap(th - math.pi / 2) * RT + bot.width / 2
        if ub >= 0 and ub < bot.width and opaque(bot, math.floor(ub), math.floor(r - (RT - 7.5))) then return true end
      end
    end
    if kind == "delivered" then
      for k = -1, 1 do
        local sa2 = math.pi / 2 + k * 0.62
        local cx, cy = RT * math.cos(sa2), RT * math.sin(sa2)
        if star_in(qx - cx, qy - cy, 7.5, 3.2) then return true end
      end
      for _, s in ipairs({ -1, 1 }) do
        local dx, dy = qx - s * RT * math.cos(0.36), qy - RT * math.sin(0.36)
        if dx * dx + dy * dy <= 6.5 then return true end
      end
      return segdist(qx, qy, -12, 1, -4, 9) <= 2.8 or segdist(qx, qy, -4, 9, 12, -9) <= 2.8
    else
      for _, s in ipairs({ -1, 1 }) do
        local dx, dy = qx - s * RT * math.cos(0.25), qy - RT * math.sin(0.25)
        if dx * dx + dy * dy <= 9 then return true end
      end
      if qx >= -4 and qx <= 14 and math.abs(qy) <= 3.5 then return true end
      return qx >= -15 and qx <= -4 and math.abs(qy) <= (qx + 15) * 0.95
    end
  end
  local m, hull = { w = D, h = D }, { w = D, h = D }
  for y = 0, D - 1 do for x = 0, D - 1 do
    local n = 0
    for j = 0, SS - 1 do for i = 0, SS - 1 do
      local px, py = x + (i + 0.5) / SS - D / 2, y + (j + 0.5) / SS - D / 2
      if ink(px * ca - py * sa, px * sa + py * ca) then n = n + 1 end
    end end
    m[y * D + x] = n * 2 >= SS * SS
    local dx, dy = x + 0.5 - D / 2, y + 0.5 - D / 2
    hull[y * D + x] = dx * dx + dy * dy <= 51.6 * 51.6
  end end
  return compose(m, hull, col, seed, 7)
end

local INK_GREEN, INK_BLUE, INK_RED = P.green_d, H.c("1d2b53"), H.c("d3262d")
local STAMP = {
  delivered = {
    a = rect_stamp(src_delivered_a(), 10, INK_GREEN, 41),
    b = round_stamp("delivered", 10, INK_BLUE, 42),
    c = rect_stamp(src_delivered_c(), 9, INK_GREEN, 43),
  },
  ["return"] = {
    a = rect_stamp(src_return_a(), -9, INK_RED, 44),
    b = round_stamp("return", -10, INK_RED, 45),
    c = rect_stamp(src_return_c(), -9, INK_RED, 46),
  },
}
local STAMP_ORDER = {}
for _, k in ipairs({ "delivered", "return" }) do
  for _, st in ipairs({ "a", "b", "c" }) do
    local s = STAMP[k][st]
    save_frames("stamp_" .. k .. "_" .. st, { s.plain })
    save_frames("stamp_" .. k .. "_" .. st .. "_backed", { s.backed })
    STAMP_ORDER[#STAMP_ORDER + 1] = { name = "stamp_" .. k .. "_" .. st, im = s.plain }
    STAMP_ORDER[#STAMP_ORDER + 1] = { name = "stamp_" .. k .. "_" .. st .. "_backed", im = s.backed }
  end
end

------------------------------------------------------------------ scene
local tiles = Image { fromFile = H.ROOT .. "assets/tilesets/hotel_tileset.png" }
local kit_btn = Image { fromFile = H.ROOT .. "assets/ui/button.png" }
local kit_panel = Image { fromFile = H.ROOT .. "assets/ui/panel.png" }
local kit_conf = Image { fromFile = H.ROOT .. "assets/ui/confetti.png" }
local btn_normal, btn_hover = sub(kit_btn, 0, 0, 48, 20), sub(kit_btn, 48, 0, 48, 20)

local function button(im, cx, y, w, label, hot)
  nine(im, hot and btn_hover or btn_normal, cx - w // 2, y, w, 20)
  H.text(im, label, cx, y + 6, P.box_ink, { align = "center" })
end

local function door(im, x, open, num)
  H.blit(im, tiles, x, FLOOR - 96, open and 64 or 0, 64, 64, 96)
  if num then H.text(im, num, x + 32, FLOOR - 96 + 7, P.base_d, { align = "center" }) end
end

local GROUND = FLOOR + 6 -- walking line, a little way onto the carpet

-- kind: "play" (mid-level), "win", "lose"
local function scene(kind)
  local im = H.img(W, HH)
  local rows = { 1, 0, 0, 0, 0, 2, 3, 4, 4 }
  for r, col in ipairs(rows) do
    for c = 0, 14 do H.blit(im, tiles, c * 32, (r - 1) * 32, col * 32, 0, 32, 32) end
  end
  H.lamp(im, 196, 70); H.lamp(im, 300, 70)
  door(im, 16, false, "213")
  H.mat(im, 22, FLOOR, kind == "lose" and "none" or "done", 46)
  if kind ~= "lose" then H.package(im, 34, FLOOR + 5, 0) end
  if kind == "play" then
    door(im, 376, false, "214")
    H.mat(im, 382, FLOOR, "wait", 46)
    H.package(im, 108, GROUND, 0)
    H.package(im, 306, GROUND, 2)
    H.player(im, 168, GROUND, 0, 2)
    H.package(im, 220, GROUND, 0)
    U.aim(im, 244, GROUND - 22, -0.62, 46, 3)
  elseif kind == "win" then
    door(im, 376, true, "214")
    H.blit(im, H.load("guests/guest_a.png"), 384, FLOOR - 64, 96, 0, 48, 64) -- frame 2 = happy
    H.mat(im, 382, FLOOR, "done", 46)
    H.package(im, 366, FLOOR + 5, 1)
    H.package(im, 250, GROUND, 2)
    H.player(im, 300, GROUND, 0, 2)
  else
    door(im, 376, true, "214")
    H.blit(im, H.load("guests/guest_b.png"), 384, FLOOR - 64, 192, 0, 48, 64) -- frame 4 = shocked
    H.mat(im, 382, FLOOR, "none", 46)
    H.package(im, 40, GROUND, 2)
    H.package(im, 130, GROUND, 2); H.package(im, 214, GROUND, 2)
    H.package(im, 340, GROUND, 2)
    H.player(im, 268, GROUND, 0, 2)
  end
  return im
end

local function confetti(im, f)
  H.blit(im, kit_conf, 0, 0, f * 240, 0, 240, 135, false, 2)
end

local function preview(im, file, label, corner)
  local c = im:clone()
  local w = H.textw(label, 1) + 6
  local x, y = W - w - 3, 3
  if corner == "bl" then x, y = 3, HH - 14 elseif corner == "br" then y = HH - 14 elseif corner == "tl" then x = 3 end
  H.tag(c, label, x, y, P.yellow, P.ink)
  scaled(c, 4):saveAs(REVIEW .. file .. ".png")
  print("preview " .. file)
end

local function mock(im, name) im:saveAs(OUT .. name .. ".png") end

local OL = { outline = P.ink }

------------------------------------------------------------------ HUD
do -- A: design-document layout
  local im = scene("play")
  U.glass(im, 6, 6, 162, 40)
  H.blit(im, bullets.pending, 11, 11)
  H.text(im, "DELIVER PACKAGES", 23, 11, P.white)
  rtext(im, "1/4", 162, 11, P.mat_g)
  H.blit(im, bullets.pending, 11, 21)
  H.text(im, "UNDER 5 MINUTES", 23, 21, P.yellow)
  rtext(im, "1:42", 162, 21, P.concrete_l)
  H.blit(im, bullets.failed, 11, 31)
  H.text(im, "NO PACKAGE DESTROYED", 23, 31, H.c("d0686c"))
  U.glass(im, 6, 240, 96, 26)
  for i, s in ipairs({ "delivered", "active", "lost", "waiting" }) do H.blit(im, slots[s], 10 + (i - 1) * 22, 243) end
  U.glass(im, 396, 250, 78, 16)
  H.blit(im, keyr, 399, 252)
  H.text(im, "RESTART", 429, 255, P.white)
  mock(im, "mock_hud_a")
  preview(im, "options_hud_a", "HUD A  DESIGN DOC", "tr")
end

do -- B: one compact top bar
  local im = scene("play")
  H.shade(im, 0, 0, W, 26, P.ui, 0.82)
  H.rect(im, 0, 26, W, 1, P.ink)
  Y.mono(im, 6, 10, 1)
  for i, s in ipairs({ "delivered", "active", "lost", "waiting" }) do H.blit(im, slots[s], 27 + (i - 1) * 22, 3) end
  H.rect(im, 119, 5, 1, 16, P.ui_ll)
  H.blit(im, stat.delivered, 126, 7)
  H.text(im, "1/4", 142, 10, P.mat_g)
  H.rect(im, 166, 5, 1, 16, P.ui_ll)
  H.blit(im, bullets.pending, 173, 9)
  H.text(im, "UNDER 5 MIN", 185, 10, P.yellow)
  H.text(im, "1:42", 253, 10, P.concrete_l)
  H.rect(im, 281, 5, 1, 16, P.ui_ll)
  H.blit(im, bullets.failed, 288, 9)
  H.text(im, "NO PACKAGE DESTROYED", 300, 10, H.c("d0686c"))
  H.blit(im, keyr, 446, 7)
  mock(im, "mock_hud_b")
  preview(im, "options_hud_b", "HUD B  TOP BAR", "br")
end

do -- C: delivery-app tracking card
  local im = scene("play")
  local x, y, w, h = 6, 5, 134, 92
  H.rect(im, x + 2, y + 2, w, h, P.ink)
  H.box(im, x, y, w, h, PAPER, P.ink)
  H.rect(im, x + 1, y + 1, w - 2, 14, Y.P.orange)
  H.rect(im, x + 1, y + 15, w - 2, 1, P.ink)
  Y.wordmark(im, x + 5, y + 5, 1, Y.P.black, Y.P.white)
  rtext(im, "TRACKING", x + w - 5, y + 5, Y.P.white)
  local rows = {
    { "done", "PKG 1", "DELIVERED", P.green_d },
    { "pending", "PKG 2", "IN TRANSIT", Y.P.orange_d },
    { "failed", "PKG 3", "LOST", P.red_d },
    { "pending", "PKG 4", "WAITING", P.gray },
  }
  H.rect(im, x + 1, y + 29, w - 2, 11, H.c("ffdcc0")) -- current package row
  H.rect(im, x + 9, y + 24, 1, 34, PAPER_D)
  for i, r in ipairs(rows) do
    local ry = y + 20 + (i - 1) * 11
    H.blit(im, bullets[r[1]], x + 6, ry - 1)
    H.text(im, r[2], x + 18, ry, P.ink)
    rtext(im, r[3], x + w - 5, ry, r[4])
  end
  H.rect(im, x + 7, y + 31, 6, 6, Y.P.orange); H.rect(im, x + 8, y + 32, 4, 4, Y.P.white) -- "you are here"
  dashes(im, x + 4, x + w - 5, y + 65, P.gray, 2, 2)
  H.blit(im, bullets.pending, x + 6, y + 69)
  H.text(im, "UNDER 5 MIN", x + 18, y + 70, P.ink)
  rtext(im, "1:42", x + w - 5, y + 70, P.gray)
  H.blit(im, bullets.failed, x + 6, y + 80)
  H.text(im, "NO DAMAGE", x + 18, y + 81, P.red_d)
  rtext(im, "FAILED", x + w - 5, y + 81, P.red_d)
  H.blit(im, keyr, 446, 253)
  mock(im, "mock_hud_c")
  preview(im, "options_hud_c", "HUD C  TRACKING APP", "tr")
end

do -- D: minimal, icons only
  local im = scene("play")
  for i, s in ipairs({ "delivered", "active", "lost", "waiting" }) do H.blit(im, slots[s], 6 + (i - 1) * 21, 245) end
  H.blit(im, stat.delivered, 7, 6)
  H.text(im, "1/4", 22, 9, P.white, OL)
  H.blit(im, stat.time, 7, 21)
  H.text(im, "1:42", 22, 24, P.white, OL)
  H.blit(im, stat.destroyed, 7, 36)
  H.blit(im, bullets.failed, 22, 39)
  H.blit(im, keyr, 446, 253)
  mock(im, "mock_hud_d")
  preview(im, "options_hud_d", "HUD D  MINIMAL", "tr")
end

------------------------------------------------------------------ win / lose shared
local WIN = { deliv = "3/4", lost = "1", kicks = "14", time = "2:31", stars = 2.5 }
local LOSE = { deliv = "0/4", lost = "4", kicks = "9", time = "1:07", stars = 0 }

local function star_row(im, x, y, n, total, s, gap)
  s, gap = s or 1, gap or 2
  for i = 1, total do
    local k = "empty"
    if n >= i then k = "full" elseif n >= i - 0.5 then k = "half" end
    H.blit(im, stars[k], x + (i - 1) * (16 * s + gap), y, 0, 0, 16, 16, false, s)
  end
end

-- rows of icon, label, dotted leader, value
local function stat_rows(im, x0, x1, y, step, d, fg, good, bad, dot)
  local rows = {
    { stat.delivered, "DELIVERED", d.deliv, good },
    { stat.destroyed, "DESTROYED / LOST", d.lost, bad },
    { stat.kicks, "KICKS", d.kicks, fg },
    { stat.time, "TIME", d.time, fg },
  }
  for i, r in ipairs(rows) do
    local ry = y + (i - 1) * step
    H.blit(im, r[1], x0, ry - 3)
    local lw = H.text(im, r[2], x0 + 16, ry, fg)
    local vw = H.textw(r[3], 1)
    for x = x0 + 16 + lw + 4, x1 - vw - 4, 3 do H.px(im, x, ry + 6, dot) end
    rtext(im, r[3], x1, ry, r[4])
  end
end

-- icon + value pairs spread along one line
local function stat_strip(im, x0, x1, y, d, fg, good, bad)
  local items = { { stat.delivered, d.deliv, good }, { stat.destroyed, d.lost, bad },
    { stat.kicks, d.kicks, fg }, { stat.time, d.time, fg } }
  local step = (x1 - x0) // 4
  for i, it in ipairs(items) do
    local x = x0 + (i - 1) * step
    H.blit(im, it[1], x, y - 3)
    H.text(im, it[2], x + 15, y, it[3])
  end
end

-- 2x head-and-shoulders crop of a guest frame in a gold picture frame
local function portrait(im, rel, frame, x, y, w, h, bg)
  local src = H.load(rel)
  local fx = frame * 48
  local x0, x1, y0 = 48, -1, 64
  for j = 0, 63 do for i = 0, 47 do
    if pc.rgbaA(src:getPixel(fx + i, j)) > 0 then
      x0, x1, y0 = math.min(x0, i), math.max(x1, i), math.min(y0, j)
    end
  end end
  H.rect(im, x + 2, y + 2, w, h, P.ink)
  H.box(im, x, y, w, h, P.gold, P.ink)
  H.rect(im, x + 1, y + h - 3, w - 2, 2, P.gold_d)
  H.box(im, x + 3, y + 3, w - 6, h - 6, bg, P.ink)
  local ix, iy, iw, ih = x + 4, y + 4, w - 8, h - 8
  for i = 0, iw - 1, 8 do H.rect(im, ix + i, iy, math.min(4, iw - i), ih, P.wall_l) end
  local cw, ch = iw // 2, ih // 2
  local sx = math.max(0, math.min(48 - cw, (x0 + x1) // 2 - cw // 2))
  local sy = math.max(0, y0 - 3)
  for j = 0, ch - 1 do for i = 0, cw - 1 do
    if sy + j < 64 then
      local p = src:getPixel(fx + sx + i, sy + j)
      if pc.rgbaA(p) > 0 then H.rect(im, ix + i * 2, iy + j * 2, 2, 2, p) end
    end
  end end
end

-- A: centred panel
local function screen_a(win)
  local d = win and WIN or LOSE
  local im = scene(win and "win" or "lose")
  if win then
    H.shade(im, 0, 0, W, HH, P.ink, 0.5)
    confetti(im, 2)
  else
    desaturate(im, 0.6)
    H.shade(im, 0, 0, W, HH, H.c("3a0a10"), 0.62)
  end
  local x, y, w, h = 132, 50, 216, 182
  if win then
    nine(im, kit_panel, x, y, w + 2, h + 2)
  else
    H.rect(im, x + 2, y + 2, w, h, P.ink)
    H.box(im, x, y, w, h, H.c("24121a"), P.ink)
    H.rect(im, x + 1, y + 1, w - 2, 1, P.red_d)
  end
  local b = win and BAN.success.ribbon or BAN.failed.ribbon
  H.blit(im, b, 240 - b.width // 2, y - 14)
  star_row(im, 240 - 55, y + 32, d.stars, 3, 2, 7)
  H.text(im, win and "CUSTOMER SATISFACTION" or "CUSTOMER NOT SATISFIED", 240, y + 70, win and P.gold or P.gray, { align = "center" })
  H.rect(im, x + 12, y + 82, w - 24, 1, win and P.ui_ll or H.c("4a2a30"))
  stat_rows(im, x + 16, x + w - 16, y + 91, 14, d, P.white, win and P.mat_g or P.gray, P.xred, win and P.ui_ll or H.c("5a3a40"))
  button(im, 240, y + 152, 96, "BACK", true)
  return im
end

-- B: customer review card
local function screen_b(win)
  local d = win and WIN or LOSE
  local im = scene(win and "win" or "lose")
  if win then
    H.shade(im, 0, 0, W, HH, P.ink, 0.45)
    confetti(im, 5)
  else
    desaturate(im, 0.7)
    H.shade(im, 0, 0, W, HH, P.ink, 0.6)
  end
  local b = win and BAN.success.label or BAN.failed.label
  H.rect(im, 240 - b.width // 2 + 2, 10, b.width, b.height, P.ink)
  H.blit(im, b, 240 - b.width // 2, 8)
  local x, y, w, h = 72, 58, 336, 148
  H.rect(im, x + 2, y + 2, w, h, P.ink)
  H.box(im, x, y, w, h, PAPER, P.ink)
  H.rect(im, x + 1, y + 1, w - 2, 16, win and Y.P.orange or Y.P.char)
  H.rect(im, x + 1, y + 17, w - 2, 1, P.ink)
  if win then Y.wordmark(im, x + 6, y + 6, 1, Y.P.black, Y.P.white) else Y.wordmark(im, x + 6, y + 6, 1) end
  rtext(im, "CUSTOMER REVIEW", x + w - 7, y + 6, Y.P.white)
  if win then portrait(im, "guests/guest_a.png", 2, x + 10, y + 26, 84, 86, P.wall)
  else portrait(im, "guests/guest_b.png", 4, x + 10, y + 26, 84, 86, P.wall) end
  local tx = x + 108
  H.text(im, "ROOM 214", tx, y + 27, P.ink, { s = 2 })
  rtext(im, "VERIFIED GUEST", x + w - 10, y + 31, P.gray)
  local n = win and 4.5 or 1
  star_row(im, tx, y + 47, n, 5, 1, 2)
  H.text(im, win and "4.5 / 5" or "1 / 5", tx + 96, y + 52, win and P.green_d or P.red_d)
  local q = win and { '"IT ARRIVED IN ONE PIECE.', 'MOSTLY. I HEARD IT COMING', 'DOWN THE HALL. 10/10."' }
    or { '"I ORDERED A VASE.', 'I RECEIVED A JIGSAW PUZZLE', 'AND A FOOTPRINT."' }
  H.rect(im, tx, y + 70, 2, 34, win and Y.P.orange or P.red_d)
  for i, l in ipairs(q) do H.text(im, l, tx + 7, y + 71 + (i - 1) * 12, P.ink) end
  dashes(im, x + 8, x + w - 9, y + 121, P.gray, 2, 2)
  stat_strip(im, x + 22, x + w - 10, y + 132, d, P.ink, win and P.green_d or P.gray, P.red_d)
  button(im, 240, 222, 96, "BACK", true)
  return im
end

do
  local im = screen_a(true)
  mock(im, "mock_win_a"); preview(im, "options_win_a", "WIN A  CENTRED PANEL", "bl")
  im = screen_a(false)
  mock(im, "mock_lose_a"); preview(im, "options_lose_a", "LOSE A  DARK PANEL", "bl")
  im = screen_b(false)
  mock(im, "mock_lose_b"); preview(im, "options_lose_b", "LOSE B  ONE-STAR REVIEW", "bl")
end

------------------------------------------------------------------ win A variants (round 2)
-- Same structure as win A (centred panel, title, big stars, stat rows, BACK,
-- confetti); only the treatment changes.
local function recolor(src, map)
  local im = src:clone()
  for y = 0, im.height - 1 do for x = 0, im.width - 1 do
    local c = map[im:getPixel(x, y)]
    if c then im:drawPixel(x, y, c) end
  end end
  return im
end
local function star_set(hi, lo) -- stars with a different "empty" fill
  local t = {}
  for _, k in ipairs(STARS) do t[k] = recolor(stars[k], { [P.ui_ll] = hi, [P.ui_l] = lo }) end
  return t
end
local function star_row2(im, set, x, y, n, total, s, gap)
  for i = 1, total do
    local k = "empty"
    if n >= i then k = "full" elseif n >= i - 0.5 then k = "half" end
    H.blit(im, set[k], x + (i - 1) * (16 * s + gap), y, 0, 0, 16, 16, false, s)
  end
end
local function win_base(dim, f)
  local im = scene("win")
  H.shade(im, 0, 0, W, HH, P.ink, dim)
  confetti(im, f or 2)
  return im
end
local function tape(im, x, y, w, h)
  for r = 0, h - 1 do
    local cut = (r % 4 < 2) and 0 or 2
    H.rect(im, x + cut, y + r, w - 2 * cut, 1, P.tape)
  end
  H.rect(im, x + 2, y, w - 4, 1, P.cream)
  H.rect(im, x + 2, y + h - 1, w - 4, 1, H.c("bfae8a"))
end
local STARS_LIGHT = star_set(H.c("cfc8b8"), H.c("b5ad9b"))

-- A2 (light) was chosen: it is now built in the final section at the end of
-- this file, from the exported sprites.

do -- A3: cardboard sheet, title on packing tape
  local im = win_base(0.55)
  local x, y, w, h = 132, 50, 216, 182
  H.rect(im, x + 3, y + 3, w, h, P.ink)
  H.box(im, x, y, w, h, P.card, P.ink)
  math.randomseed(17)
  for _ = 1, 150 do
    local fx, fy, fl = x + math.random(3, w - 10), y + math.random(3, h - 8), math.random(2, 5)
    H.rect(im, fx, fy, fl, 1, math.random() < 0.7 and P.card_m or CARD_L)
  end
  H.rect(im, x + 1, y + 1, w - 2, 1, CARD_L)
  H.rect(im, x + 1, y + h - 5, w - 2, 4, P.card_m)
  for i = x + 2, x + w - 4, 4 do H.rect(im, i, y + h - 4, 2, 2, P.card_d) end
  tape(im, 240 - 9, y + 1, 18, h - 6) -- seam tape down the middle of the sheet
  tape(im, 240 - 126, y - 12, 252, 26)
  H.text(im, "SUCCESSFUL DELIVERY", 240, y - 6, P.box_ink, { s = 2, align = "center" })
  H.rect(im, 240 - 66, y + 27, 136, 44, P.card_d)
  H.box(im, 240 - 68, y + 25, 136, 44, P.cream, P.ink)
  star_row2(im, STARS_LIGHT, 240 - 55, y + 31, WIN.stars, 3, 2, 7)
  H.box(im, x + 10, y + 76, w - 20, 68, CARD_L, P.card_d)
  H.text(im, "CUSTOMER SATISFACTION", 240, y + 80, P.card_dd, { align = "center" })
  stat_rows(im, x + 16, x + w - 16, y + 94, 12, WIN, P.box_ink, H.c("0f6a1c"), H.c("9e1a1e"), P.card_m)
  for _, ax in ipairs({ x + 12, x + 24 }) do -- printed THIS WAY UP arrows
    for i = 0, 4 do H.rect(im, ax + 4 - i, y + 150 + i, 2 * i + 1, 1, P.card_dd) end
    H.rect(im, ax + 3, y + 155, 3, 8, P.card_dd)
  end
  H.rect(im, x + 12, y + 165, 21, 2, P.card_dd)
  rtext(im, "FRAGILE", x + w - 12, y + 158, P.card_dd)
  button(im, 240, y + 150, 96, "BACK", true)
  mock(im, "mock_win_a3"); preview(im, "options_win_a3", "WIN A3  CARDBOARD", "bl")
end

do -- A4: hotel award plaque, red with a brass frame
  local im = win_base(0.55)
  local x, y, w, h = 132, 50, 216, 182
  H.rect(im, x + 3, y + 3, w, h, P.ink)
  H.box(im, x, y, w, h, P.gold, P.ink)
  H.rect(im, x + 1, y + 1, w - 2, 1, P.cream); H.rect(im, x + 1, y + 1, 1, h - 2, P.cream)
  H.rect(im, x + 1, y + h - 2, w - 2, 1, P.gold_d); H.rect(im, x + w - 2, y + 1, 1, h - 2, P.gold_d)
  H.box(im, x + 5, y + 5, w - 10, h - 10, P.door, P.ink)
  H.rect(im, x + 6, y + 6, w - 12, 2, P.door_d); H.rect(im, x + 6, y + 6, 2, h - 12, P.door_d)
  local function pin(i, c)
    H.rect(im, x + i, y + i, w - 2 * i, 1, c); H.rect(im, x + i, y + h - i - 1, w - 2 * i, 1, c)
    H.rect(im, x + i, y + i, 1, h - 2 * i, c); H.rect(im, x + w - i - 1, y + i, 1, h - 2 * i, c)
  end
  pin(11, P.gold_d)
  for _, c in ipairs({ { x + 10, y + 10 }, { x + w - 13, y + 10 }, { x + 10, y + h - 13 }, { x + w - 13, y + h - 13 } }) do
    H.box(im, c[1], c[2], 3, 3, P.gold, P.gold_d)
  end
  -- engraved brass title plate
  local px, pw = 240 - 120, 240
  H.rect(im, px + 2, y - 12, pw, 28, P.ink)
  H.box(im, px, y - 14, pw, 28, P.gold, P.ink)
  H.rect(im, px + 1, y - 13, pw - 2, 2, P.cream)
  H.rect(im, px + 1, y + 11, pw - 2, 2, P.gold_d)
  for _, sx in ipairs({ px + 4, px + pw - 7 }) do H.box(im, sx, y - 2, 3, 3, P.gold_d, P.base_d) end
  H.text(im, "SUCCESSFUL DELIVERY", 240, y - 7, P.base_d, { s = 2, align = "center", shadow = P.cream, sd = 1 })
  star_row2(im, star_set(P.door_d, H.c("5e0f18")), 240 - 55, y + 32, WIN.stars, 3, 2, 7)
  H.text(im, "CUSTOMER SATISFACTION", 240, y + 70, P.gold, { align = "center" })
  H.rect(im, x + 18, y + 82, w - 36, 1, P.gold_d)
  stat_rows(im, x + 20, x + w - 20, y + 91, 14, WIN, P.cream, P.yellow, P.cream, P.door_l)
  button(im, 240, y + 150, 96, "BACK", true)
  mock(im, "mock_win_a4"); preview(im, "options_win_a4", "WIN A4  BRASS PLAQUE", "bl")
end

do -- A5: shipping label, the DELIVERED stamp is the title
  local im = win_base(0.62, 4)
  local WHITE = H.c("fbfaf6")
  local x, y, w, h = 116, 20, 248, 232
  H.rect(im, x + 3, y + 3, w, h, P.ink)
  H.box(im, x, y, w, h, WHITE, P.ink, 2)
  H.text(im, "SHIP TO", x + 10, y + 7, P.gray)
  H.text(im, "ROOM 214", x + 10, y + 17, P.ink, { s = 2 })
  H.rect(im, x + 116, y + 2, 1, 34, P.ink)
  rtext(im, "SUCCESSFUL DELIVERY", x + w - 10, y + 7, P.ink)
  barcode(im, x + 129, y + 18, 109, 14, 12, P.ink)
  H.rect(im, x + 2, y + 36, w - 4, 2, P.ink)
  local st = STAMP.delivered.a.plain
  H.blit(im, st, 240 - st.width // 2, y + 42)
  star_row2(im, STARS_LIGHT, 240 - 55, y + 100, WIN.stars, 3, 2, 7)
  H.rect(im, x + 2, y + 138, w - 4, 1, P.ink)
  stat_rows(im, x + 12, x + w - 12, y + 147, 13, WIN, P.ink, P.green_d, P.red_d, H.c("c4bdac"))
  H.rect(im, x + 2, y + 200, w - 4, 1, P.ink)
  button(im, 240, y + 206, 96, "BACK", true)
  mock(im, "mock_win_a5"); preview(im, "options_win_a5", "WIN A5  SHIPPING LABEL", "bl")
end

do -- A6: award rosette on the dark panel
  local im = win_base(0.5)
  local x, y, w, h = 122, 54, 236, 198
  nine(im, kit_panel, x, y, w + 2, h + 2)
  local t = H.img(72, 84)
  local cx, cy = 36, 30
  for j = 0, 34 do -- two splayed tails
    H.rect(t, cx - 16 - j // 3, cy + 12 + j, 12, 1, P.green_d)
    H.rect(t, cx + 4 + j // 3, cy + 12 + j, 12, 1, P.green_d)
  end
  for k = 0, 13 do
    local a = k * math.pi / 7
    H.ellipse(t, cx + math.floor(math.cos(a) * 21 + 0.5), cy + math.floor(math.sin(a) * 21 + 0.5), 5, 5, P.green)
  end
  H.ellipse(t, cx, cy, 21, 21, P.green)
  for k = 0, 13 do
    local a = (k + 0.5) * math.pi / 7
    H.line(t, cx + math.floor(math.cos(a) * 16), cy + math.floor(math.sin(a) * 16),
      cx + math.floor(math.cos(a) * 23), cy + math.floor(math.sin(a) * 23), P.green_d)
  end
  H.ellipse(t, cx, cy, 15, 15, P.gold, P.gold_d)
  H.ellipse(t, cx, cy, 12, 12, P.cream)
  H.blit(t, stars.full, cx - 8, cy - 8)
  A.outline(t, P.ink, true)
  H.blit(im, t, 240 - 36, y - 30)
  H.text(im, "SUCCESSFUL DELIVERY", 240, y + 50, P.cream, { s = 2, align = "center", outline = P.ink, shadow = P.green_d, sd = 1 })
  star_row(im, 240 - 55, y + 72, WIN.stars, 3, 2, 7)
  H.rect(im, x + 12, y + 110, w - 24, 1, P.ui_ll)
  stat_rows(im, x + 18, x + w - 18, y + 118, 13, WIN, P.white, P.mat_g, P.xred, P.ui_ll)
  button(im, 240, y + 170, 96, "BACK", true)
  mock(im, "mock_win_a6"); preview(im, "options_win_a6", "WIN A6  ROSETTE", "bl")
end

do -- A7: the rating is the hero, stats shrink to one strip
  local im = win_base(0.5, 3)
  local x, y, w, h = 122, 62, 236, 156
  nine(im, kit_panel, x, y, w + 2, h + 2)
  local b = BAN.success.ribbon
  H.blit(im, b, 240 - b.width // 2, y - 14)
  star_row(im, 240 - 84, y + 30, WIN.stars, 3, 3, 12)
  H.text(im, "CUSTOMER SATISFACTION", 240, y + 86, P.gold, { align = "center" })
  H.rect(im, x + 12, y + 98, w - 24, 1, P.ui_ll)
  stat_strip(im, x + 16, x + w - 4, y + 108, WIN, P.white, P.mat_g, P.xred)
  button(im, 240, y + 126, 96, "BACK", true)
  mock(im, "mock_win_a7"); preview(im, "options_win_a7", "WIN A7  BIG STARS", "bl")
end

do -- lose C: shipping label stamped RETURN TO SENDER over a grey level
  local im = scene("lose")
  desaturate(im, 1)
  H.shade(im, 0, 0, W, HH, P.ink, 0.35)
  local b = BAN.failed.stamp
  local bx = 240 - (b.width + 12) // 2
  H.rect(im, bx + 2, 6, b.width + 12, b.height + 10, P.ink)
  H.box(im, bx, 4, b.width + 12, b.height + 10, PAPER, P.ink)
  H.blit(im, b, bx + 6, 9)
  local x, y, w, h = 90, 54, 300, 168
  H.rect(im, x + 3, y + 3, w, h, P.ink)
  H.box(im, x, y, w, h, PAPER, P.ink, 2)
  -- header
  Y.wordmark(im, x + 9, y + 8, 2, Y.P.black, Y.P.orange)
  rtext(im, "STANDARD-ISH SHIPPING", x + w - 10, y + 8, P.ink)
  rtext(im, "TRACKING 0214-YEET", x + w - 10, y + 18, P.gray)
  H.rect(im, x + 2, y + 30, w - 4, 2, P.ink)
  -- address row with barcode
  H.text(im, "SHIP TO", x + 10, y + 38, P.gray)
  H.text(im, "ROOM 214", x + 10, y + 48, P.ink, { s = 2 })
  H.text(im, "THE GRAND HOTEL", x + 10, y + 66, P.ink)
  H.rect(im, x + 150, y + 32, 1, 48, P.ink)
  barcode(im, x + 162, y + 38, 126, 26, 8, P.ink)
  H.text(im, "0214 0000 YEET", x + 225, y + 68, P.gray, { align = "center" })
  H.rect(im, x + 2, y + 80, w - 4, 1, P.ink)
  -- run statistics, and the stamp slammed on the blank half
  stat_rows(im, x + 10, x + 127, y + 98, 15, LOSE, P.ink, P.gray, P.red_d, PAPER_D)
  local st = shear(scaled(st_return, 2), 0.1)
  H.blit(im, st, x + 135, y + 84)
  button(im, 240, 232, 96, "BACK", true)
  mock(im, "mock_lose_c"); preview(im, "options_lose_c", "LOSE C  RETURN TO SENDER", "bl")
end

------------------------------------------------------------------ component sheet
do
  local S = 4
  local sh = H.img(2160, 3600, P.gray)
  local function cap(str, x, y) H.text(sh, str:gsub("_", " "), x, y, P.ink, { s = 2 }) end
  local function put(im, x, y, s) H.blit(sh, im, x, y, 0, 0, im.width, im.height, false, s or S) end
  local function strip(list, x, y, s)
    for i, im in ipairs(list) do put(im, x + (i - 1) * im.width * (s or S), y, s) end
  end

  cap("HUD_PACKAGE_SLOT 4X 20X20: WAITING, ACTIVE, DELIVERED, LOST", 12, 10)
  strip(slots, 12, 30)
  cap("AT 1X ON DARK / CARPET / WALL", 360, 120)
  for k, c in ipairs({ P.ui, P.carpet, P.wall }) do
    H.rect(sh, 360 + (k - 1) * 100, 60, 92, 26, c)
    strip(slots, 364 + (k - 1) * 100, 63, 1)
  end
  cap("HUD_OBJECTIVE_BULLET 3X 8X8", 760, 10)
  strip(bullets, 760, 30)
  cap("PENDING, DONE, FAILED", 760, 70)
  cap("HUD_KEY_R 28X12", 1100, 10)
  put(keyr, 1100, 30)
  cap("STAR 3X 16X16: EMPTY, HALF, FULL", 1300, 10)
  strip(stars, 1300, 30)
  H.rect(sh, 1520, 30, 60, 22, P.ui); strip(stars, 1526, 33, 1)
  H.rect(sh, 1520, 56, 60, 22, PAPER); strip(stars, 1526, 59, 1)

  cap("STAT_ICONS 4X 12X12: DELIVERED, DESTROYED, KICKS, TIME", 12, 150)
  strip(stat, 12, 170)
  H.rect(sh, 220, 170, 60, 20, P.ui); strip(stat, 226, 174, 1)
  H.rect(sh, 220, 194, 60, 20, PAPER); strip(stat, 226, 198, 1)

  local y = 240
  for _, st in ipairs({ "ribbon", "stamp", "label" }) do
    local a, b = BAN.success[st], BAN.failed[st]
    cap("BANNER_SUCCESS_" .. st:upper() .. " " .. a.width .. "X" .. a.height, 12, y)
    cap("BANNER_FAILED_" .. st:upper() .. " " .. b.width .. "X" .. b.height, 1084, y)
    if st == "stamp" then
      H.rect(sh, 8, y + 18, a.width * S + 8, a.height * S + 4, PAPER)
      H.rect(sh, 1080, y + 18, b.width * S + 8, b.height * S + 4, PAPER)
    end
    put(a, 12, y + 20); put(b, 1084, y + 20)
    y = y + 20 + a.height * S + 24
  end
  -- round 2 stamps: every style, plain and backed, 4x, then true size on paper and on a busy hallway
  y = y + 10
  cap("STAMPS: PLAIN (INK ONLY) AND BACKED (PAPER BEHIND), 4X ON MID GREY", 12, y)
  y = y + 24
  local fx, rowh = 12, 0
  for _, e in ipairs(STAMP_ORDER) do
    local ww, hh = e.im.width * S, e.im.height * S
    if fx + ww > sh.width - 12 then fx, y, rowh = 12, y + rowh + 30, 0 end
    cap(e.name .. " " .. e.im.width .. "X" .. e.im.height, fx, y)
    put(e.im, fx, y + 18)
    fx, rowh = fx + ww + 16, math.max(rowh, hh + 18)
  end
  y = y + rowh + 30
  local hall = scene("play")
  local sw = H.img(1760, 232, P.gray)
  H.rect(sw, 0, 0, 1760, 112, PAPER)
  for i = 0, 3 do H.blit(sw, hall, i * 480, 116, 0, 108, 480, 116) end
  local px = 6
  for i = 1, #STAMP_ORDER, 2 do
    local a, b = STAMP_ORDER[i].im, STAMP_ORDER[i + 1].im
    H.blit(sw, a, px, 56 - a.height // 2); H.blit(sw, a, px, 174 - a.height // 2)
    px = px + a.width + 6
    H.blit(sw, b, px, 56 - b.height // 2); H.blit(sw, b, px, 174 - b.height // 2)
    px = px + b.width + 6
  end
  sw = sub(sw, 0, 0, math.min(px, 1760), 232)
  cap("STAMPS AT 1X: ON PAPER (TOP) AND OVER A BUSY HALLWAY (BOTTOM)", 12, y)
  put(sw, 12, y + 20, 1)
  sw:saveAs(TMP .. "stamps_1x.png")
  for k = 0, 2 do -- scratch crops at 1x, for the instant-read check
    sub(sw, k * (sw.width // 3), 0, sw.width // 3, 232):saveAs(TMP .. "stamps_1x_" .. k .. ".png")
  end
  y = y + 20 + 232 + 12
  sh = sub(sh, 0, 0, 2160, y)
  sh:saveAs(REVIEW .. "options_screens_components.png")
  print("saved options_screens_components " .. sh.width .. "x" .. sh.height)

  -- true-size crops for the 1x legibility check (scratch only)
  local t = H.img(260, 150, P.gray)
  local function put(im, x, y) H.blit(t, im, x, y) end
  local function strip(list, x, y) for i, im in ipairs(list) do put(im, x + (i - 1) * im.width, y) end end
  H.rect(t, 0, 0, 130, 150, P.ui)
  strip(slots, 4, 4, 1); strip(slots, 134, 4, 1)
  strip(bullets, 4, 30, 1); strip(bullets, 134, 30, 1)
  put(keyr, 40, 28, 1); put(keyr, 170, 28, 1)
  strip(stars, 4, 44, 1); strip(stars, 134, 44, 1)
  strip(stat, 60, 46, 1); strip(stat, 190, 46, 1)
  H.rect(t, 0, 66, 260, 84, PAPER)
  put(BAN.success.stamp, 4, 110, 1)
  scaled(t, 2):saveAs(TMP .. "components_2x.png")
  t:saveAs(TMP .. "components_1x.png")
end
------------------------------------------------------------------ final assets (round 3)
-- The chosen screens (HUD A, win A2, lose A2) as game-ready sprites in
-- assets/ui/screens/, then the three screens rebuilt from the exported PNGs
-- alone (plus the cardboard kit button and text) to prove the set is complete.
do
  local FIN = H.ROOT .. "assets/ui/screens/"
  app.fs.makeAllDirectories(FIN)
  local MAN = {}

  -- .aseprite (layer "Art", one tag per frame), .png strip, .json for strips
  local function export(name, frames, tags, margins)
    local w, h = frames[1].width, frames[1].height
    local spr = Sprite(w, h, ColorMode.RGB)
    local layer = spr.layers[1]
    layer.name = "Art"
    for i, im in ipairs(frames) do
      if i > 1 then spr:newEmptyFrame() end
      spr:newCel(layer, i, im, Point(0, 0))
    end
    for i, t in ipairs(tags or {}) do
      local tag = spr:newTag(i, i); tag.name = t
    end
    spr:saveAs(FIN .. name .. ".aseprite")
    spr:close()
    local strip = H.img(w * #frames, h)
    for i, im in ipairs(frames) do H.blit(strip, im, (i - 1) * w, 0) end
    strip:saveAs(FIN .. name .. ".png")
    if #frames > 1 then
      local f = io.open(FIN .. name .. ".json", "w")
      f:write('{ "frames": [\n')
      for i = 1, #frames do
        f:write(string.format('   {\n    "filename": "%s %d.aseprite",\n    "frame": { "x": %d, "y": 0, "w": %d, "h": %d },\n' ..
          '    "rotated": false,\n    "trimmed": false,\n    "spriteSourceSize": { "x": 0, "y": 0, "w": %d, "h": %d },\n' ..
          '    "sourceSize": { "w": %d, "h": %d },\n    "duration": 100\n   }%s\n',
          name, i - 1, (i - 1) * w, w, h, w, h, w, h, i < #frames and "," or ""))
      end
      f:write(string.format(' ],\n "meta": {\n  "app": "https://www.aseprite.org/",\n  "image": "%s.png",\n' ..
        '  "format": "RGBA8888",\n  "size": { "w": %d, "h": %d },\n  "scale": "1",\n  "frameTags": [\n', name, w * #frames, h))
      for i, t in ipairs(tags) do
        f:write(string.format('   { "name": "%s", "from": %d, "to": %d, "direction": "forward", "color": "#000000ff" }%s\n',
          t, i - 1, i - 1, i < #tags and "," or ""))
      end
      f:write('  ]\n }\n}\n')
      f:close()
    end
    MAN[#MAN + 1] = { name = name, w = w, h = h, n = #frames, tags = tags, m = margins }
    print(string.format("final %s  frame %dx%d  frames %d", name, w, h, #frames))
  end

  ---------------------------------------------------------------- build
  local paper = H.img(24, 24) -- nine-patch: L4 T4 R6 B6 (right and bottom carry the 3px shadow)
  H.rect(paper, 3, 3, 21, 21, P.ink)
  H.box(paper, 0, 0, 21, 21, PAPER, P.ink)
  H.rect(paper, 1, 1, 19, 1, P.white)
  H.rect(paper, 1, 18, 19, 2, PAPER_D)
  export("paper_panel", { paper }, nil, { 4, 4, 6, 6 })

  local glass = H.img(12, 12) -- nine-patch: 2 all round, fill is 72% opaque
  glass:clear(Rectangle(1, 1, 10, 10), pc.rgba(pc.rgbaR(P.ui), pc.rgbaG(P.ui), pc.rgbaB(P.ui), 184))
  H.rect(glass, 1, 0, 10, 1, P.ink); H.rect(glass, 1, 11, 10, 1, P.ink)
  H.rect(glass, 0, 1, 1, 10, P.ink); H.rect(glass, 11, 1, 1, 10, P.ink)
  export("hud_panel", { glass }, nil, { 2, 2, 2, 2 })

  export("banner_success_ribbon", { BAN.success.ribbon })
  export("banner_failed_ribbon", { BAN.failed.ribbon })
  export("star", { STARS_LIGHT.empty, STARS_LIGHT.half, STARS_LIGHT.full }, STARS)

  -- delivered icon redrawn: three-face box with the check clear of the lid
  local deliv = H.img(12, 12)
  drawmap(deliv, 0, 0, {
    "...###......",
    ".##TTT##....",
    "#TTTTTTT#...",
    "#L#TTT#R#...",
    "#LL###RR#...",
    "#LLL#RRR#...",
    "#LLL#RRR#...",
    "#LLL#RRR#...",
    ".##L#R##....",
    "...###......",
  }, PAL_PKG)
  outlined(deliv, 5, 6, 6, 5, function(t, ox, oy)
    H.line(t, ox, oy + 2, ox + 1, oy + 3, P.green, 2)
    H.line(t, ox + 1, oy + 3, ox + 4, oy, P.green, 2)
  end)
  export("stat_icons", { deliv, stat.destroyed, stat.kicks, stat.time }, STATS)

  export("hud_package_slot", { slots[1], slots[2], slots[3], slots[4] }, SLOTS)
  export("hud_objective_bullet", { bullets[1], bullets[2], bullets[3] }, BULLETS)
  export("hud_key_r", { keyr })
  local dots = H.img(3, 1) -- tile horizontally for the stat-row leader
  dots:drawPixel(0, 0, H.c("c4bdac"))
  export("leader_dots", { dots })

  ---------------------------------------------------------------- rebuild from the files on disk
  local function load(name) return Image { fromFile = FIN .. name .. ".png" } end
  local function frames(name, w)
    local src, t = load(name), {}
    for i = 0, src.width // w - 1 do t[i + 1] = sub(src, i * w, 0, w, src.height) end
    return t
  end
  -- alpha-aware blit and nine-patch with separate margins
  local function put(dst, src, x, y, s)
    s = s or 1
    for j = 0, src.height - 1 do for i = 0, src.width - 1 do
      local p = src:getPixel(i, j)
      local a = pc.rgbaA(p)
      for b = 0, s - 1 do for c = 0, s - 1 do
        if a == 255 then H.px(dst, x + i * s + c, y + j * s + b, p)
        elseif a > 0 then H.blendpx(dst, x + i * s + c, y + j * s + b, p, a / 255) end
      end end
    end end
  end
  local function nine4(dst, src, x, y, w, h, m)
    local sw, sh = src.width, src.height
    local function map(d, n, sn, a, b)
      if d < a then return d end
      if d >= n - b then return sn - (n - d) end
      return a + ((d - a) * (sn - a - b)) // (n - a - b)
    end
    for j = 0, h - 1 do for i = 0, w - 1 do
      local p = src:getPixel(map(i, w, sw, m[1], m[3]), map(j, h, sh, m[2], m[4]))
      local a = pc.rgbaA(p)
      if a == 255 then H.px(dst, x + i, y + j, p) elseif a > 0 then H.blendpx(dst, x + i, y + j, p, a / 255) end
    end end
  end

  local F = {
    paper = load("paper_panel"), glass = load("hud_panel"), dots = load("leader_dots"),
    ok = load("banner_success_ribbon"), fail = load("banner_failed_ribbon"),
    star = frames("star", 16), stat = frames("stat_icons", 12),
    slot = frames("hud_package_slot", 20), bullet = frames("hud_objective_bullet", 8), key = load("hud_key_r"),
  }

  local function result(win)
    local d = win and WIN or LOSE
    local im
    if win then
      im = win_base(0.7)
    else
      im = scene("lose")
      desaturate(im, 0.7)
      H.shade(im, 0, 0, W, HH, H.c("3a0a10"), 0.66)
    end
    local x, y, w, h = 132, 50, 216, 182
    nine4(im, F.paper, x, y, w + 3, h + 3, { 4, 4, 6, 6 })
    local b = win and F.ok or F.fail
    put(im, b, 240 - b.width // 2, y - 14)
    for i = 1, 3 do
      local k = 1
      if d.stars >= i then k = 3 elseif d.stars >= i - 0.5 then k = 2 end
      put(im, F.star[k], 185 + (i - 1) * 39, y + 32, 2)
    end
    H.text(im, win and "CUSTOMER SATISFACTION" or "CUSTOMER NOT SATISFIED", 240, y + 70, win and P.card_d or P.red_d, { align = "center" })
    H.rect(im, x + 12, y + 82, w - 24, 1, PAPER_D)
    local rows = {
      { "DELIVERED", d.deliv, win and P.green_d or P.gray },
      { "DESTROYED / LOST", d.lost, P.red_d },
      { "KICKS", d.kicks, P.ink },
      { "TIME", d.time, P.ink },
    }
    local x0, x1 = x + 16, x + w - 16
    for i, r in ipairs(rows) do
      local ry = y + 91 + (i - 1) * 14
      put(im, F.stat[i], x0, ry - 3)
      local lw = H.text(im, r[1], x0 + 16, ry, P.ink)
      for dx = x0 + 16 + lw + 4, x1 - H.textw(r[2], 1) - 4, 3 do put(im, F.dots, dx, ry + 6) end
      rtext(im, r[2], x1, ry, r[3])
    end
    button(im, 240, y + 152, 96, "BACK", true)
    return im
  end

  local function hud()
    local im = scene("play")
    nine4(im, F.glass, 6, 6, 162, 40, { 2, 2, 2, 2 })
    put(im, F.bullet[1], 11, 11)
    H.text(im, "DELIVER PACKAGES", 23, 11, P.white)
    rtext(im, "1/4", 162, 11, P.mat_g)
    put(im, F.bullet[1], 11, 21)
    H.text(im, "UNDER 5 MINUTES", 23, 21, P.yellow)
    rtext(im, "1:42", 162, 21, P.concrete_l)
    put(im, F.bullet[3], 11, 31)
    H.text(im, "NO PACKAGE DESTROYED", 23, 31, H.c("d0686c"))
    nine4(im, F.glass, 6, 240, 96, 26, { 2, 2, 2, 2 })
    for i, k in ipairs({ 3, 2, 4, 1 }) do put(im, F.slot[k], 10 + (i - 1) * 22, 243) end
    nine4(im, F.glass, 396, 250, 78, 16, { 2, 2, 2, 2 })
    put(im, F.key, 399, 252)
    H.text(im, "RESTART", 429, 255, P.white)
    return im
  end

  local s_hud, s_win, s_lose = hud(), result(true), result(false)
  do -- how far the rebuilt HUD is from the approved round 1 mock
    local old, n = Image { fromFile = OUT .. "mock_hud_a.png" }, 0
    for yy = 0, HH - 1 do for xx = 0, W - 1 do
      if old:getPixel(xx, yy) ~= s_hud:getPixel(xx, yy) then n = n + 1 end
    end end
    print("final HUD vs mock_hud_a: " .. n .. " differing pixels")
  end
  mock(s_win, "mock_win_a2"); preview(s_win, "options_win_a2", "WIN A2  LIGHT", "br")
  mock(s_lose, "mock_lose_a2"); preview(s_lose, "options_lose_a2", "LOSE A2  LIGHT", "br")
  scaled(s_hud, 4):saveAs(TMP .. "final_hud_4x.png")

  ---------------------------------------------------------------- proof sheet
  local S = 4
  local sh = H.img(1944, 5200, P.gray)
  -- caption text with real underscores (the 5x7 font has none)
  local function cap(str, x, y)
    for ch in str:gmatch(".") do
      if ch == "_" then H.rect(sh, x, y + 12, 10, 2, P.ink) else H.text(sh, ch, x, y, P.ink, { s = 2 }) end
      x = x + (ch == "_" and 12 or H.textw(ch, 2) + 2)
    end
  end
  local y = 12
  for _, e in ipairs({ { "HUD A, REBUILT FROM assets/ui/screens ONLY", s_hud }, { "WIN A2", s_win }, { "LOSE A2", s_lose } }) do
    cap(e[1], 12, y)
    put(sh, e[2], 12, y + 20, S)
    y = y + 20 + HH * S + 16
  end
  cap("EXPORTED SPRITES IN assets/ui/screens/ AT 4X (FILE, FRAME SIZE, FRAMES, NINE-PATCH MARGINS L T R B)", 12, y)
  y = y + 28
  local fx, rowh = 12, 0
  for _, e in ipairs(MAN) do
    local src = load(e.name)
    local label = e.name .. ".png " .. e.w .. "x" .. e.h
    if e.n > 1 then label = label .. " x" .. e.n end
    if e.m then label = label .. " m " .. table.concat(e.m, " ") end
    local ww = math.max(src.width * S, #label * 12)
    if fx + ww > sh.width - 12 then fx, y, rowh = 12, y + rowh + 26, 0 end
    cap(label, fx, y)
    if e.name == "hud_panel" then H.rect(sh, fx, y + 20, src.width * S, src.height * S, P.wall) end
    put(sh, src, fx, y + 20, S)
    fx, rowh = fx + ww + 20, math.max(rowh, src.height * S + 20)
  end
  y = y + rowh + 26
  cap("NINE-PATCH STRETCH TESTS: paper_panel 60x40 AND 140x60, hud_panel 60x20 AND 120x44 OVER WALL AND CARPET", 12, y)
  local t = H.img(470, 70)
  nine4(t, F.paper, 2, 2, 60, 40, { 4, 4, 6, 6 })
  nine4(t, F.paper, 70, 2, 140, 60, { 4, 4, 6, 6 })
  H.rect(t, 220, 0, 120, 70, P.wall); H.rect(t, 340, 0, 130, 70, P.carpet)
  nine4(t, F.glass, 226, 6, 60, 20, { 2, 2, 2, 2 })
  nine4(t, F.glass, 280, 20, 120, 44, { 2, 2, 2, 2 })
  put(sh, t, 12, y + 22, S)
  y = y + 22 + 70 * S + 12
  sh = sub(sh, 0, 0, sh.width, y)
  sh:saveAs(REVIEW .. "final_screens.png")
  sub(sh, 0, 3 * (HH * S + 36), sh.width, y - 3 * (HH * S + 36)):saveAs(TMP .. "final_sprites.png")
  print("saved final_screens " .. sh.width .. "x" .. sh.height)
end
print("opt_screens done")
