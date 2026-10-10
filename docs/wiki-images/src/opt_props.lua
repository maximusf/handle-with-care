-- Hotel props, all variants: animated vacuums, carts and fountains (A to D),
-- sign, cactus, desk and luggage door variants, and the extra hotel props.
-- Writes each sprite twice: docs/art-options/props/<name>.{aseprite,png} and the
-- game copy assets/sprites/props/<name>.{aseprite,png} ("new_" prefix dropped),
-- plus the review sheets docs/art-review/options_props_*.png and final_props_*.png.
-- JSON for the multi-frame files (printed as "MULTI <name>") comes from a second
-- CLI call each, run from inside the folder so the image path stays relative:
--   Aseprite -b <name>.aseprite --sheet <name>.png --sheet-type horizontal
--     --data <name>.json --format json-array --list-tags
-- The static A designs (sign, cactus, desk, luggage door) are drawn by
-- gen_props.lua and are read back here from docs/art-options/props/.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local pc = app.pixelColor
local OPT = H.ROOT .. "docs/art-options/props/"
local FIN = H.ROOT .. "assets/sprites/props/"
local REVIEW = H.ROOT .. "docs/art-review/"
app.fs.makeAllDirectories(OPT)
app.fs.makeAllDirectories(FIN)
app.fs.makeAllDirectories(REVIEW)

local R, B, L, E, PX, T = H.rect, H.box, H.line, H.ellipse, H.px, H.text
local floor = math.floor

-- extra shades
local WOOD_L = H.c("84523a")
local ORANGE_D, ORANGE_L = H.c("c46a14"), H.c("ffad55")
local GREEN_L = H.c("78d058")
local PURPLE_D, PURPLE_L = H.c("5a3494"), H.c("9c74de")
local DARK, SHELF = H.c("1c120c"), H.c("3a2217")
local D_RED, D_BLUE, D_TAN, D_GRN = H.c("5e1a1e"), H.c("1f4a6e"), H.c("6b4a25"), H.c("1f5a2a")
local TEAL, TEAL_D, TEAL_L = H.c("2f8f8a"), H.c("1f625f"), H.c("52b8b0")
local PINK, SKIN = H.c("ff8fb0"), H.c("e8b890")
local SAD, SAD_D, SAD_L = H.c("a3ab4c"), H.c("747a30"), H.c("c6cc6a")
local PATINA, PATINA_D, PATINA_L = H.c("5aa08c"), H.c("3c7a68"), H.c("8cc8b4")
local SLAT_D = H.c("11601b")
local BODY, BODY_D, BODY_L = H.c("6f86a6"), H.c("4a5c78"), H.c("a9bdd6")
local MAG = H.c("ff00ff")

local function ink(t) A.outline(t, P.ink, false) end

-- rows y0..y1 with the left and right edges interpolated (inclusive)
local function trap(t, y0, y1, l0, r0, l1, r1, c)
  for y = y0, y1 do
    local k = (y1 == y0) and 0 or (y - y0) / (y1 - y0)
    local l, r = floor(l0 + (l1 - l0) * k + 0.5), floor(r0 + (r1 - r0) * k + 0.5)
    R(t, l, y, r - l + 1, 1, c)
  end
end

local function bezpts(x0, y0, cx, cy, x1, y1, n)
  local pts = {}
  for i = 0, n - 1 do
    local u = i / (n - 1)
    pts[#pts + 1] = { floor((1 - u) ^ 2 * x0 + 2 * u * (1 - u) * cx + u * u * x1 + 0.5),
      floor((1 - u) ^ 2 * y0 + 2 * u * (1 - u) * cy + u * u * y1 + 0.5) }
  end
  return pts
end

local function bez(t, x0, y0, cx, cy, x1, y1, c, th, fn)
  local px, py
  for i, p in ipairs(bezpts(x0, y0, cx, cy, x1, y1, 25)) do
    if px then L(t, px, py, p[1], p[2], c, th) end
    if fn then fn(p[1], p[2], i - 1) end
    px, py = p[1], p[2]
  end
end

local function shear(t, pivot, k)
  local o = H.img(t.width, t.height)
  for x = 0, t.width - 1 do
    local d = floor((x - pivot) * k + 0.5)
    for y = 0, t.height - 1 do
      local p = t:getPixel(x, y)
      if pc.rgbaA(p) > 0 then PX(o, x, y - d, p) end
    end
  end
  return o
end

-- drop n evenly spaced columns from x0..x1, keeping the x1 edge in place
local function squash(img, x0, x1, n)
  local o, drop, w = H.img(img.width, img.height), {}, x1 - x0 + 1
  for i = 1, n do drop[x0 + floor(w * i / (n + 1))] = true end
  local dx = x1
  for x = x1, x0, -1 do
    if not drop[x] then
      for y = 0, img.height - 1 do
        local p = img:getPixel(x, y)
        if pc.rgbaA(p) > 0 then o:drawPixel(dx, y, p) end
      end
      dx = dx - 1
    end
  end
  return o
end

local function sub(src, x, y, w, h)
  local o = H.img(w, h)
  H.blit(o, src, 0, 0, x, y, w, h)
  return o
end

local function merge(a, b)
  for k, v in pairs(b or {}) do a[k] = v end
  return a
end

local FINAL = {}

-- frames: list of images. tags: { { name, from, to }, ... }. dur: seconds or list.
local function emit(name, frames, tags, dur)
  if frames.width then frames = { frames } end
  tags, dur = tags or { { "idle", 1, 1 } }, dur or 0.1
  local w, h = frames[1].width, frames[1].height
  local spr = Sprite(w, h, ColorMode.RGB)
  spr.layers[1].name = "Art"
  local strip = H.img(w * #frames, h)
  for i, im in ipairs(frames) do
    if i > 1 then spr:newEmptyFrame() end
    spr:newCel(spr.layers[1], spr.frames[i], im, Point(0, 0))
    spr.frames[i].duration = type(dur) == "table" and dur[i] or dur
    H.blit(strip, im, (i - 1) * w, 0)
  end
  local names = {}
  for _, tg in ipairs(tags) do
    local tag = spr:newTag(tg[2], tg[3])
    tag.name = tg[1]
    names[#names + 1] = tg[1]
  end
  local fname = name:gsub("^new_", "")
  spr:saveCopyAs(OPT .. name .. ".aseprite")
  strip:saveAs(OPT .. name .. ".png")
  spr:saveAs(FIN .. fname .. ".aseprite")
  strip:saveAs(FIN .. fname .. ".png")
  spr:close()
  print("MANIFEST " .. fname .. " " .. w .. " " .. h .. " " .. #frames .. " " .. table.concat(names, ","))
  if #frames > 1 then print("MULTI " .. name .. " " .. fname) end
  FINAL[#FINAL + 1] = { name = fname, img = frames[1] }
  return frames
end

------------------------------------------------------------------ shared bits
local function bell(t, cx, by) -- by = row of the base plate
  R(t, cx - 6, by, 12, 1, P.asphalt)
  R(t, cx - 5, by - 3, 10, 2, P.gold); R(t, cx - 5, by - 1, 10, 1, P.gold_d)
  R(t, cx - 4, by - 4, 8, 1, P.gold); R(t, cx - 3, by - 5, 6, 1, P.gold)
  R(t, cx + 2, by - 4, 2, 3, P.gold_d)
  R(t, cx - 3, by - 4, 2, 1, P.cream); PX(t, cx - 4, by - 3, P.cream)
  R(t, cx - 1, by - 7, 2, 2, P.gold_d)
end

local function case(t, x, bottom, w, h, c, d, hl)
  local y = bottom - h + 1
  R(t, x, y, w, h, c); R(t, x, y + h - 2, w, 2, d); R(t, x, y, w, 1, hl or c)
  R(t, x + 3, y, 2, h, d); R(t, x + w - 5, y, 2, h, d)
  R(t, x + w // 2 - 3, y - 2, 6, 1, P.asphalt)
  PX(t, x + w // 2 - 3, y - 1, P.asphalt); PX(t, x + w // 2 + 2, y - 1, P.asphalt)
end

-- wheel with one white spoke and rim marker, a quarter turn per step
local function wheel(t, cx, cy, r, f)
  E(t, cx, cy, r, r, P.asphalt)
  local d = ({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } })[f % 4 + 1]
  L(t, cx, cy, cx + d[1] * (r - 1), cy + d[2] * (r - 1), P.white)
  PX(t, cx + d[1] * (r - 1) + d[2], cy + d[2] * (r - 1) + d[1], P.white)
  PX(t, cx + d[1] * (r - 1) - d[2], cy + d[2] * (r - 1) - d[1], P.white)
  PX(t, cx, cy, P.gray)
end

local function hclip(t, x, y, w, c, x0, x1)
  local a, b = math.max(x, x0), math.min(x + w - 1, x1)
  if b >= a then R(t, a, y, b - a + 1, 1, c) end
end

-- Water travelling along pts as fat drops joined by a thin thread, with gaps
-- between them unless solid.
-- Moves 4 points a frame on a 16 point cycle, so it loops every 4 frames.
local function stream(t, pts, f, thin, thick, solid)
  for k, p in ipairs(pts) do
    local ph = (k - 1 - f * 4) % 16
    if solid or (ph >= 4 and ph < 10) then R(t, p[1], p[2], thin, thin, P.water) end
  end
  for k, p in ipairs(pts) do
    if (k - 1 - f * 4) % 16 < 4 then R(t, p[1] - 1, p[2] - 1, thick, thick, P.water_l) end
  end
  for k, p in ipairs(pts) do
    if (k - 1 - f * 4) % 16 < 4 and k < #pts - 1 then R(t, p[1], p[2], thick - 2, thick - 2, P.white) end
  end
end

------------------------------------------------------------------ WET FLOOR SIGNS
local function sign_b() -- tall cone
  local t = H.img(24, 40)
  R(t, 2, 35, 20, 4, P.mat_yd); R(t, 2, 35, 20, 1, P.yellow)
  trap(t, 4, 34, 10, 13, 5, 18, P.yellow)
  R(t, 10, 3, 4, 1, P.yellow)
  trap(t, 4, 34, 13, 13, 16, 18, P.mat_yd)
  trap(t, 5, 33, 10, 10, 6, 6, P.cream)
  trap(t, 9, 12, 9, 14, 9, 14, P.ink)
  trap(t, 13, 13, 8, 15, 8, 15, P.ink)
  R(t, 11, 17, 2, 9, P.ink); R(t, 11, 28, 2, 2, P.ink)
  ink(t)
  return t
end

local function sign_c() -- folding board with a slipping figure
  local t = H.img(32, 40)
  R(t, 4, 4, 24, 32, P.yellow); R(t, 5, 3, 22, 1, P.yellow)
  R(t, 4, 36, 4, 3, P.yellow); R(t, 24, 36, 4, 3, P.yellow)
  R(t, 4, 38, 4, 1, P.mat_yd); R(t, 24, 38, 4, 1, P.mat_yd)
  R(t, 26, 5, 2, 31, P.mat_yd); R(t, 4, 5, 1, 30, P.cream)
  R(t, 13, 5, 6, 2, P.ink)
  E(t, 20, 11, 1, 1, P.ink) -- head
  L(t, 18, 13, 13, 18, P.ink, 2) -- torso thrown back
  L(t, 18, 14, 23, 17, P.ink); L(t, 16, 14, 11, 11, P.ink) -- arms
  L(t, 13, 19, 7, 17, P.ink, 2); L(t, 14, 19, 19, 22, P.ink, 2) -- legs
  R(t, 7, 24, 18, 1, P.blue); R(t, 10, 25, 5, 1, P.blue); R(t, 19, 23, 3, 1, P.blue)
  T(t, "WET", 16, 27, P.ink, { align = "center" })
  ink(t)
  return t
end

local function sign_d() -- peeled banana standing in a yellow base
  local t = H.img(32, 40)
  local function cx(y) return 15 + floor(((23 - y) / 19) ^ 2 * 4 + 0.5) end
  -- back peel flap, then the two side flaps flopping outwards
  bez(t, 17, 20, 22, 8, 27, 14, P.mat_yd, 3)
  R(t, 27, 14, 2, 2, P.card_dd)
  bez(t, 12, 21, 0, 14, 3, 28, P.yellow, 4)
  bez(t, 19, 21, 31, 16, 27, 29, P.yellow, 4)
  bez(t, 13, 23, 4, 18, 5, 27, P.cream, 2)
  bez(t, 19, 23, 28, 19, 26, 28, P.cream, 2)
  R(t, 3, 30, 3, 2, P.card_dd); R(t, 27, 31, 3, 2, P.card_dd)
  -- the fruit, curving to the right
  for y = 4, 23 do
    local w = y < 6 and 3 or (y < 8 and 5 or 7)
    local x = cx(y) - w // 2
    R(t, x, y, w, 1, P.cream)
    PX(t, x + w - 1, y, P.tape)
    if y > 8 and y % 5 == 0 then PX(t, x + 2, y, P.tape) end
  end
  R(t, cx(3) - 1, 2, 2, 2, P.card_dd)
  -- skin still on below, widening into a weighted base
  trap(t, 22, 37, 11, 19, 6, 25, P.yellow)
  trap(t, 23, 37, 18, 19, 22, 25, P.mat_yd)
  R(t, 6, 36, 20, 2, P.mat_yd)
  trap(t, 23, 35, 12, 12, 8, 8, P.cream)
  R(t, 15, 25, 2, 6, P.ink); R(t, 15, 33, 2, 2, P.ink)
  ink(t)
  return t
end

------------------------------------------------------------------ ROBOT VACUUMS
-- All four share one frame order: patrol 1-4, bump 5-6, stuck 7-8 (24 px tall).
-- o: brush 0..3, light on/off/red/warn, bob, puff 0..3, wheel, dx, squash,
-- tilt, rock, excl, spark, plus per-variant extras.
local LIGHT = { on = P.blue, off = P.asphalt_d, red = P.xred, warn = P.yellow }
local LED = { on = P.mat_g, off = P.asphalt_d, red = P.xred, warn = P.yellow }

local function a_shell(sh, o)
  local bx, bw = 10, 28
  R(sh, bx + 5, 12, bw - 10, 1, P.white)
  R(sh, bx + 2, 13, bw - 4, 1, P.concrete_l)
  R(sh, bx + 1, 14, bw - 2, 1, P.concrete_l)
  R(sh, bx + 7, 13, 8, 1, P.white)
  R(sh, bx, 15, bw, 5, P.gray)
  R(sh, bx, 15, bw, 1, P.concrete_d)
  R(sh, bx, 19, bw, 1, P.mat_nd)
  R(sh, bx + bw - 7, 16, 7, 3, P.asphalt)
  R(sh, bx + 7, 17, 9, 1, P.mat_nd)
  R(sh, bx + 2, 16, 3, 2, LED[o.light])
end

local function a_top(t, o, ox, oyb, lift)
  local tx, oy = 21 + ox, oyb - lift(21)
  R(t, tx, 10 + oy, 6, 2, P.asphalt)
  R(t, tx + 1, 8 + oy, 4, 2, LIGHT[o.light])
  if o.light ~= "off" then R(t, tx + 2, 8 + oy, 2, 1, P.white) end
end

local function a_fx(t, o, ox, oyb, lift)
  if o.light == "on" or o.light == "red" then
    local g = o.light == "on" and P.water_l or P.red
    local tx, oy = 21 + ox, oyb - lift(21)
    PX(t, tx - 1, 7 + oy, g); PX(t, tx + 6, 7 + oy, g); R(t, tx + 2, 6 + oy, 2, 1, g)
  end
end

local function b_shell(sh, o) -- steel-blue dome with a scanning sensor strip
  for y = 8, 19 do
    local k = (19 - y) / 11.5
    local hw = floor(13 * math.sqrt(1 - k * k) + 0.5)
    R(sh, 24 - hw, y, hw * 2, 1, BODY)
    R(sh, 24 + hw - 3, y, 3, 1, BODY_D)
  end
  R(sh, 16, 10, 6, 1, BODY_L); R(sh, 13, 12, 2, 4, BODY_L); PX(sh, 15, 11, BODY_L)
  R(sh, 10, 18, 28, 2, P.concrete_l); R(sh, 10, 19, 28, 1, P.gray)
  R(sh, 21, 8, 6, 1, LED[o.light])
  R(sh, 21, 13, 13, 3, P.ink)
  if o.light == "warn" then
    R(sh, 21, 13, 13, 3, P.yellow)
  elseif o.scan == "all" then
    R(sh, 21, 13, 13, 3, P.xred); R(sh, 22, 13, 11, 1, P.red)
  elseif o.scan ~= "none" then
    R(sh, 21 + (o.scan or 0), 13, 5, 3, P.xred); R(sh, 22 + (o.scan or 0), 13, 2, 1, P.white)
  end
end

local function c_shell(sh, o) -- white box, the eyes go on afterwards
  R(sh, 10, 11, 26, 9, P.white)
  R(sh, 10, 17, 26, 3, P.tile_d); R(sh, 10, 16, 26, 1, P.orange)
  R(sh, 33, 12, 3, 4, P.gray)
  R(sh, 12, 13, 3, 2, LED[o.light])
end

local function c_fx(t, o, ox, oyb, lift) -- googly eyes
  local e = o.eyes or {}
  for i, q in ipairs({ { 20, e.j1 or 0, e.p1 or { 1, 0 } }, { 29, e.j2 or 0, e.p2 or { 1, 0 } } }) do
    local cx, cy = q[1] + ox, 9 + oyb - lift(q[1]) - q[2] - (e.pop or 0)
    E(t, cx, cy, 4, 4, P.white, P.ink)
    if e.small then R(t, cx + q[3][1], cy + q[3][2], 2, 2, P.ink)
    else R(t, cx - 1 + q[3][1], cy - 1 + q[3][2], 3, 3, P.ink) end
  end
end

local function d_top(t, o, ox, oyb, lift) -- A's turret plus the taped-on knife
  a_top(t, o, ox, oyb, lift)
  local oy, kw = oyb - lift(27), o.kw or 0
  local hx = 27 + ox + (o.kdx or 0)
  R(t, hx, 10 + oy, 5, 2, P.base_d)
  for i = 0, 12 do
    local x, yc = hx + 5 + i, 10 + oy + floor(kw * i / 12 + 0.5)
    if i < 9 then PX(t, x, yc - 1, P.concrete_l) end
    if i < 11 then R(t, x, yc, 1, 2, P.white) else PX(t, x, yc, P.white) end
  end
  R(t, hx + 1, 9 + oy, 2, 6, P.tape)
  R(t, hx + 7, 8 + oy, 2, 5, P.tape)
end

local VAC = {
  a = { w = 40, bx = 10, x1 = 37, cx = 23, shell = a_shell, top = a_top, fx = a_fx, ex = {} },
  b = { w = 40, bx = 10, x1 = 37, cx = 23, shell = b_shell,
    ex = { { scan = 0 }, { scan = 4 }, { scan = 8 }, { scan = 4 }, {}, {}, { scan = "all" }, { scan = "none" } } },
  c = { w = 40, bx = 10, x1 = 35, cx = 22, shell = c_shell, fx = c_fx, noexcl = true, ex = {
    { eyes = { p1 = { 1, 0 }, p2 = { 1, 0 } } },
    { eyes = { j1 = 1, p1 = { 0, 1 }, p2 = { 0, 1 } } },
    { eyes = { p1 = { -1, 0 }, p2 = { -1, 0 } } },
    { eyes = { j2 = 1, p1 = { 1, -1 }, p2 = { -1, 1 } } },
    { eyes = { pop = 2, small = true, p1 = { 0, 0 }, p2 = { -1, 0 } } },
    { eyes = { pop = 1, small = true, p1 = { -2, 0 }, p2 = { 1, 0 } } },
    { eyes = { p1 = { -1, -1 }, p2 = { 1, 1 } } },
    { eyes = { j1 = 1, p1 = { 1, 1 }, p2 = { -1, -1 } } },
  } },
  d = { w = 48, bx = 10, x1 = 37, cx = 23, sparkx = 47, shell = a_shell, top = d_top, fx = a_fx,
    ex = { { kw = 0 }, { kw = -2 }, { kw = 0 }, { kw = 2 }, { kw = -3, kdx = -2 }, { kw = 3 }, { kw = 4 }, { kw = 6 } } },
}

local function vac(V, o)
  local t = H.img(V.w, 24)
  local bx, x1, dx = V.bx, V.x1, o.dx or 0
  local function lift(x) return o.tilt and math.max(0, floor((x - bx - 4) * 0.25 + 0.5)) or 0 end
  local rock = o.rock or 0
  local oyb = rock - (o.bob or 0)
  if o.tilt then -- the stray sock it has climbed
    R(t, x1 - 12, 19, 11, 4, P.white); R(t, x1 - 10, 18, 7, 1, P.white)
    R(t, x1 - 9, 18, 2, 5, P.red); R(t, x1 - 5, 19, 2, 4, P.red); R(t, x1 - 12, 22, 11, 1, P.tile_d)
  end
  for i, wx in ipairs({ bx + 4, x1 - 8 }) do
    local wy = 20 - (i == 2 and lift(wx + 2) - rock or 0)
    R(t, wx + dx, wy, 5, 3, P.asphalt)
    R(t, wx + dx + 1, wy + 1, 3, 1, P.gray)
    local m = ({ { 0, 0 }, { 4, 0 }, { 4, 2 }, { 0, 2 } })[(o.wheel or 0) % 4 + 1]
    PX(t, wx + dx + m[1], wy + m[2], P.concrete_l)
  end
  local px0, bp = x1 - 4 + dx, (o.brush or 0) % 4
  local yb = 20 - lift(x1 - 4) + rock
  if bp == 0 then
    R(t, px0, yb + 1, 6, 2, P.yellow); R(t, px0 + 4, yb + 1, 2, 2, P.orange)
  elseif bp == 1 then
    for k = 0, 2 do R(t, px0 + k, yb + k, 3, 1, P.yellow) end
    R(t, px0 + 3, yb + 2, 2, 1, P.orange)
  elseif bp == 2 then
    R(t, px0 - 1, yb, 3, 3, P.yellow); R(t, px0 - 1, yb + 2, 3, 1, P.orange)
  else
    for k = 0, 2 do R(t, px0 - 2 - k, yb + k, 3, 1, P.yellow) end
    R(t, px0 - 5, yb + 2, 2, 1, P.orange)
  end
  local sh = H.img(V.w, 24)
  V.shell(sh, o)
  if o.squash then sh = squash(sh, bx, x1, 3) end
  if o.tilt then sh = shear(sh, bx + 4, 0.25) end
  H.blit(t, sh, dx, oyb)
  local ox = dx + (o.squash and 2 or 0)
  if V.top then V.top(t, o, ox, oyb, lift) end
  if o.excl and not V.noexcl then R(t, V.cx + ox, 1, 2, 4, P.yellow); R(t, V.cx + ox, 6, 2, 1, P.yellow) end
  ink(t)
  -- unoutlined effects on top
  if V.fx then V.fx(t, o, ox, oyb, lift) end
  if o.spark then
    local sx = V.sparkx or x1 + 2
    L(t, sx, 9, sx - 2, 11, P.yellow); L(t, sx, 17, sx - 2, 15, P.yellow)
    R(t, sx - 1, 13, 2, 1, P.white); PX(t, sx - 3, 7, P.white); PX(t, sx - 3, 19, P.white)
  end
  if o.spin then
    R(t, x1 - 2, 13, 2, 1, P.white); R(t, x1, 15, 1, 2, P.white); R(t, x1 - 10, 14, 1, 2, P.white)
  end
  if o.puff then
    local c1, c2 = P.white, P.concrete_l
    if o.puff == 0 then
      R(t, bx - 4, 18, 3, 3, c1)
    elseif o.puff == 1 then
      R(t, bx - 7, 16, 5, 4, c1); R(t, bx - 6, 15, 3, 1, c1); R(t, bx - 7, 19, 5, 1, c2)
    elseif o.puff == 2 then
      R(t, bx - 10, 12, 6, 5, c1); R(t, bx - 9, 11, 4, 1, c1); R(t, bx - 10, 16, 6, 1, c2)
      R(t, bx - 4, 18, 3, 3, c1)
    else
      R(t, bx - 10, 8, 2, 2, c2); R(t, bx - 6, 10, 2, 2, c2); R(t, bx - 9, 13, 2, 1, c2)
      R(t, bx - 7, 16, 5, 4, c1); R(t, bx - 6, 15, 3, 1, c1); R(t, bx - 7, 19, 5, 1, c2)
    end
  end
  return t
end

local function vacset(V)
  local fr = {}
  for i = 0, 3 do
    fr[i + 1] = vac(V, merge({ brush = i, light = i < 2 and "on" or "off", bob = i % 2, puff = i, wheel = i }, V.ex[i + 1]))
  end
  fr[5] = vac(V, merge({ squash = true, light = "warn", brush = 2, excl = true, spark = true }, V.ex[5]))
  fr[6] = vac(V, merge({ dx = -3, light = "warn", brush = 0, bob = 1, excl = true, wheel = 2 }, V.ex[6]))
  fr[7] = vac(V, merge({ tilt = true, light = "red", brush = 1 }, V.ex[7]))
  fr[8] = vac(V, merge({ tilt = true, light = "off", brush = 3, wheel = 2, rock = 1, spin = true }, V.ex[8]))
  return fr
end

------------------------------------------------------------------ CACTI
local function pot(t, x, y, w, h) -- terracotta, rim at y
  R(t, x, y, w, 3, P.orange); R(t, x, y, w, 1, ORANGE_L); R(t, x + w - 3, y + 1, 3, 2, ORANGE_D)
  for j = 0, h - 4 do
    local i = j * 2 // (h - 3)
    R(t, x + 1 + i, y + 3 + j, w - 2 - i * 2, 1, P.orange)
    R(t, x + w - 4 - i, y + 3 + j, 3, 1, ORANGE_D)
  end
  R(t, x + 1, y + 3, w - 2, 1, ORANGE_D)
  R(t, x + 3, y + 5, 1, h - 7, ORANGE_L)
end

local function cactus_b() -- tall saguaro, white planter
  local t = H.img(32, 60)
  R(t, 6, 46, 20, 3, P.white); R(t, 23, 47, 3, 2, P.tile_d)
  trap(t, 49, 58, 7, 24, 10, 21, P.tile)
  trap(t, 49, 58, 21, 24, 19, 21, P.tile_d)
  R(t, 7, 49, 18, 1, P.tile_d)
  R(t, 9, 52, 12, 1, P.blue); R(t, 10, 54, 10, 1, P.blue)
  R(t, 12, 4, 8, 42, P.grass); R(t, 13, 3, 6, 1, P.grass); R(t, 14, 2, 4, 1, P.grass)
  R(t, 18, 4, 2, 42, P.grass_d); R(t, 13, 4, 1, 42, GREEN_L); R(t, 15, 5, 1, 41, P.grass_d)
  R(t, 4, 11, 5, 15, P.grass); R(t, 5, 10, 3, 1, P.grass); R(t, 9, 22, 3, 4, P.grass)
  R(t, 4, 25, 8, 1, P.grass_d); R(t, 5, 12, 1, 12, GREEN_L)
  R(t, 23, 17, 5, 17, P.grass); R(t, 24, 16, 3, 1, P.grass); R(t, 20, 30, 3, 4, P.grass)
  R(t, 20, 33, 8, 1, P.grass_d); R(t, 26, 18, 2, 15, P.grass_d)
  R(t, 7, 32, 3, 8, P.grass); R(t, 8, 31, 1, 1, P.grass); R(t, 10, 36, 2, 4, P.grass); R(t, 7, 39, 5, 1, P.grass_d)
  for y = 6, 43, 5 do PX(t, 14, y, P.white); PX(t, 17, y + 2, P.white) end
  for y = 13, 22, 4 do PX(t, 6, y, P.white) end
  for y = 19, 31, 4 do PX(t, 25, y, P.white) end
  R(t, 15, 1, 2, 1, P.cream); PX(t, 14, 2, P.cream); PX(t, 17, 2, P.cream)
  ink(t)
  return t
end

local function cactus_c() -- barrel with a flower, blue glazed bowl
  local t = H.img(32, 32)
  local function inside(x, y) return ((x - 15.5) / 10) ^ 2 + ((y - 14) / 9) ^ 2 <= 1 end
  for y = 4, 22 do
    for x = 4, 27 do
      if inside(x, y) then
        local c = P.grass
        if (x - 6) % 4 == 0 then c = P.grass_d end
        if x >= 23 then c = P.grass_d end
        if (x - 6) % 4 == 1 and x < 14 then c = GREEN_L end
        if (x - 6) % 4 == 2 and (y + x) % 3 == 0 then c = P.white end
        PX(t, x, y, c)
      end
    end
  end
  R(t, 13, 3, 6, 2, PINK); R(t, 14, 2, 4, 1, PINK); R(t, 12, 4, 8, 1, PINK)
  R(t, 15, 3, 2, 2, P.yellow)
  R(t, 4, 20, 24, 3, P.blue); R(t, 4, 20, 24, 1, P.water_l)
  trap(t, 23, 30, 5, 26, 9, 22, P.water_d)
  trap(t, 24, 28, 7, 7, 9, 9, P.blue)
  R(t, 5, 23, 22, 1, H.c("1f5a8c"))
  ink(t)
  return t
end

local function cactus_d() -- prickly pear
  local t = H.img(32, 44)
  E(t, 9, 12, 5, 7, P.grass, P.grass_d)
  E(t, 23, 14, 5, 6, P.grass, P.grass_d)
  E(t, 16, 23, 7, 9, P.grass, P.grass_d)
  E(t, 25, 5, 2, 2, P.grass, P.grass_d)
  R(t, 8, 3, 3, 3, P.red); PX(t, 9, 2, P.red_d)
  R(t, 20, 6, 3, 3, P.red); PX(t, 21, 5, P.red_d)
  R(t, 15, 12, 3, 3, PINK)
  for _, p in ipairs({ { 8, 9 }, { 11, 13 }, { 7, 15 }, { 22, 12 }, { 25, 16 }, { 21, 17 }, { 14, 19 },
    { 18, 21 }, { 13, 24 }, { 17, 26 }, { 20, 24 }, { 15, 29 }, { 25, 5 } }) do
    PX(t, p[1], p[2], P.white)
  end
  R(t, 11, 20, 1, 6, GREEN_L); R(t, 6, 9, 1, 5, GREEN_L)
  pot(t, 7, 30, 18, 13)
  ink(t)
  return t
end

local function cactus_e() -- wilting: slumped trunk, arms hanging, unhappy face
  local t = H.img(32, 40)
  -- limp arms first so the trunk overlaps their shoulders
  bez(t, 11, 17, 2, 13, 4, 25, SAD, 3)
  bez(t, 17, 19, 27, 15, 26, 27, SAD, 3)
  bez(t, 12, 19, 4, 15, 5, 25, SAD_D, 1)
  R(t, 3, 26, 3, 2, P.dirt); R(t, 25, 28, 3, 2, P.dirt)
  -- trunk leaning left, its top folded over
  for y = 9, 27 do
    local x = 11 - floor(((27 - y) / 18) ^ 2 * 2 + 0.5)
    R(t, x, y, 8, 1, SAD)
    PX(t, x, y, SAD_L); R(t, x + 6, y, 2, 1, SAD_D)
  end
  bez(t, 12, 9, 13, 3, 21, 8, SAD, 5)
  bez(t, 14, 11, 17, 9, 22, 11, SAD_D, 1)
  R(t, 22, 9, 3, 4, SAD); R(t, 23, 13, 2, 2, P.dirt)
  R(t, 11, 22, 3, 2, P.dirt); PX(t, 15, 13, P.dirt)
  -- face
  R(t, 11, 15, 2, 2, P.ink); R(t, 15, 15, 2, 2, P.ink)
  PX(t, 10, 13, P.ink); PX(t, 11, 14, P.ink); PX(t, 17, 13, P.ink); PX(t, 16, 14, P.ink)
  R(t, 12, 19, 4, 1, P.ink); PX(t, 11, 20, P.ink); PX(t, 16, 20, P.ink)
  PX(t, 18, 17, P.water_l); PX(t, 18, 18, P.water)
  pot(t, 6, 27, 16, 12)
  L(t, 11, 30, 13, 33, P.ink); L(t, 13, 33, 11, 36, P.ink); L(t, 13, 33, 15, 34, P.ink)
  ink(t)
  PX(t, 25, 37, P.white); PX(t, 27, 38, P.white); R(t, 24, 38, 2, 1, SAD_D); PX(t, 3, 38, P.white)
  return t
end

------------------------------------------------------------------ FOUNTAINS (8 frame loops)
local function arc_pts(x0, dir)
  local raw, cum = {}, { 0 }
  for i = 0, 400 do
    local u = i / 400
    raw[i + 1] = { x0 + dir * 14 * u, 17 + 27 * u * u }
    if i > 0 then
      local a, b = raw[i], raw[i + 1]
      cum[i + 1] = cum[i] + math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
    end
  end
  local pts, j = {}, 1
  for k = 0, 31 do
    local want = cum[#cum] * k / 31
    while j < #cum and cum[j] < want do j = j + 1 end
    pts[k + 1] = { floor(raw[j][1] + 0.5), floor(raw[j][2] + 0.5) }
  end
  return pts
end
local ARCS = { arc_pts(30, -1), arc_pts(65, 1) }
local JET = { 2, 5, 7, 4, 1, 4, 7, 5 }

local function fountain_a(f)
  local t = H.img(96, 64)
  R(t, 4, 59, 88, 4, P.concrete_d); R(t, 4, 59, 88, 1, P.concrete)
  R(t, 7, 50, 82, 9, P.concrete)
  for x = 10, 80, 13 do B(t, x, 52, 11, 5, P.concrete, P.concrete_d) end
  R(t, 7, 50, 82, 1, P.concrete_d)
  R(t, 7, 41, 82, 1, P.concrete_d)
  R(t, 7, 42, 82, 4, P.water); R(t, 7, 42, 82, 1, P.water_d)
  for i = -1, 3 do
    hclip(t, 7 + (f * 3) % 24 + i * 24, 43, 7, P.water_l, 7, 88)
    hclip(t, 19 + (24 - f * 3) % 24 + i * 24, 45, 8, P.water_l, 7, 88)
  end
  R(t, 5, 46, 86, 4, P.concrete_l); R(t, 5, 46, 86, 1, P.marble); R(t, 5, 49, 86, 1, P.concrete)
  R(t, 42, 43, 12, 3, P.concrete)
  R(t, 44, 23, 8, 20, P.concrete_l); R(t, 44, 23, 1, 20, P.marble); R(t, 50, 23, 2, 20, P.concrete)
  R(t, 44, 24, 8, 1, P.concrete_d); R(t, 44, 33, 8, 1, P.concrete)
  R(t, 33, 17, 30, 1, P.water)
  for i = -1, 3 do hclip(t, 33 + f % 8 + i * 8, 17, 4, P.water_l, 33, 62) end
  R(t, 31, 18, 34, 2, P.concrete_l); R(t, 31, 18, 34, 1, P.marble)
  R(t, 33, 20, 30, 1, P.concrete_l); R(t, 36, 21, 24, 1, P.concrete)
  R(t, 40, 22, 16, 1, P.concrete); R(t, 43, 23, 10, 1, P.concrete_d)
  R(t, 46, 11, 4, 6, P.concrete_l); R(t, 49, 11, 1, 6, P.concrete)
  R(t, 45, 9, 6, 2, P.concrete_l); R(t, 46, 8, 4, 1, P.marble)
  -- pulsing jet
  local jh = JET[f + 1]
  R(t, 47, 8 - jh, 2, jh, P.water_l)
  R(t, 46, 8 - jh, 4, math.min(2, jh), P.water)
  R(t, 47, 8 - jh, 2, 1, P.white)
  if jh >= 5 then R(t, 45, 9 - jh, 6, 1, P.water) end
  ink(t)
  if jh >= 4 then
    PX(t, 43, 11 - jh, P.water_l); PX(t, 52, 12 - jh, P.water_l)
    PX(t, 42, 14 - jh, P.water); PX(t, 53, 15 - jh, P.water)
  end
  for i, pts in ipairs(ARCS) do
    stream(t, pts, f, 1, 3, true)
    -- splash ring where the stream lands
    local lx, ph = pts[32][1], (f + 1) % 4
    if ph == 0 then
      R(t, lx - 2, 42, 5, 3, P.white)
      PX(t, lx - 4, 39, P.white); PX(t, lx + 4, 38, P.white); PX(t, lx - 1, 37, P.water_l); PX(t, lx + 2, 39, P.water_l)
    elseif ph == 1 then
      R(t, lx - 4, 44, 3, 1, P.white); R(t, lx + 2, 44, 3, 1, P.white); R(t, lx - 1, 43, 3, 1, P.water_l)
      PX(t, lx - 5, 40, P.water_l); PX(t, lx + 5, 40, P.water_l)
    elseif ph == 2 then
      R(t, lx - 7, 44, 3, 1, P.white); R(t, lx + 5, 44, 3, 1, P.white)
      R(t, lx - 5, 45, 2, 1, P.water_l); R(t, lx + 4, 45, 2, 1, P.water_l)
    else
      hclip(t, lx - 10, 45, 3, P.water_l, 7, 88); hclip(t, lx + 8, 45, 3, P.water_l, 7, 88)
    end
  end
  return t
end

local FISH_PTS = bezpts(46, 12, 62, 0, 67, 34, 36)

local function fountain_b(f) -- fish spout over a round bowl
  local t = H.img(80, 64)
  R(t, 22, 58, 36, 5, P.concrete_d); R(t, 22, 58, 36, 1, P.concrete)
  trap(t, 50, 57, 31, 48, 35, 44, P.concrete)
  R(t, 31, 50, 18, 1, P.concrete_d)
  trap(t, 40, 49, 6, 73, 26, 53, P.concrete_l)
  trap(t, 44, 49, 14, 65, 26, 53, P.concrete)
  R(t, 7, 35, 66, 2, P.water); R(t, 7, 35, 66, 1, P.water_d)
  for i = -1, 3 do hclip(t, 7 + (f * 3) % 24 + i * 24, 36, 7, P.water_l, 7, 72) end
  R(t, 4, 37, 72, 3, P.concrete_l); R(t, 4, 37, 72, 1, P.marble); R(t, 4, 39, 72, 1, P.concrete)
  R(t, 33, 31, 12, 6, P.concrete_l); R(t, 42, 31, 3, 6, P.concrete); R(t, 33, 31, 12, 1, P.marble)
  -- bronze fish balancing on its tail
  trap(t, 26, 30, 36, 41, 32, 45, PATINA_D)
  E(t, 38, 19, 5, 8, PATINA)
  E(t, 41, 11, 4, 4, PATINA)
  trap(t, 13, 22, 32, 33, 30, 33, PATINA_D)
  R(t, 35, 14, 1, 10, PATINA_L); R(t, 39, 9, 3, 1, PATINA_L)
  for _, p in ipairs({ { 37, 16 }, { 40, 18 }, { 37, 20 }, { 40, 22 }, { 38, 24 } }) do R(t, p[1], p[2], 2, 1, PATINA_D) end
  R(t, 42, 10, 2, 2, P.white); PX(t, 43, 11, P.ink)
  R(t, 44, 13, 2, 2, P.ink)
  ink(t)
  stream(t, FISH_PTS, f, 2, 4)
  local lx, ph = 67, f % 4
  if ph == 0 then
    R(t, lx - 3, 33, 7, 3, P.white)
    PX(t, lx - 5, 30, P.white); PX(t, lx + 4, 29, P.white); PX(t, lx - 2, 28, P.water_l); PX(t, lx + 2, 31, P.water_l)
  elseif ph == 1 then
    hclip(t, lx - 5, 36, 3, P.white, 7, 72); hclip(t, lx + 3, 36, 3, P.white, 7, 72)
    R(t, lx - 1, 35, 3, 1, P.water_l); PX(t, lx - 6, 31, P.water_l); PX(t, lx + 5, 32, P.water_l)
  elseif ph == 2 then
    hclip(t, lx - 9, 36, 4, P.white, 7, 72); hclip(t, lx + 4, 36, 2, P.white, 7, 72)
  else
    hclip(t, lx - 13, 36, 4, P.water_l, 7, 72)
  end
  -- drips off the bowl lip
  for i, x in ipairs({ 5, 74 }) do
    local y = 41 + (f * 3 + i * 12) % 24
    if y < 60 then R(t, x, y, 1, 3, P.water_l); PX(t, x, y + 2, P.white) end
  end
  return t
end

local function fountain_c(f) -- modern slab with a water wall
  local t = H.img(64, 72)
  R(t, 3, 60, 58, 11, P.concrete); R(t, 3, 60, 58, 2, P.concrete_l); R(t, 3, 69, 58, 2, P.concrete_d)
  R(t, 12, 3, 40, 57, P.asphalt); R(t, 12, 3, 40, 2, P.gray); R(t, 49, 5, 3, 55, P.asphalt_d)
  R(t, 15, 6, 32, 54, P.water_d)
  for x = 15, 46 do
    for y = 6, 59 do
      if (y + x * 3) % 9 < 4 then PX(t, x, y, P.water) end
    end
  end
  -- bright bands sliding down the sheet, 2 px a frame
  for b = 0, 3 do
    local yb = 6 + (f * 2 + b * 16) % 64
    for x = 15, 46 do
      local y = yb + (x * 7) % 3
      if y <= 57 then PX(t, x, y, P.white) end
      if y + 1 <= 58 then PX(t, x, y + 1, x % 3 == 0 and P.white or P.water_l) end
      if y + 2 <= 59 then PX(t, x, y + 2, P.water_l) end
    end
  end
  R(t, 14, 5, 34, 1, P.water_l)
  R(t, 6, 58, 52, 2, P.water); R(t, 6, 58, 52, 1, P.water_l)
  for x = 15 + (f % 2) * 3, 44, 6 do R(t, x, 57, 3, 1, P.white); R(t, x + 1, 56, 1, 1, P.white) end
  for i = -1, 3 do hclip(t, 6 + (f * 3) % 24 + i * 24, 59, 6, P.white, 6, 57) end
  B(t, 24, 63, 16, 5, P.concrete_d, P.concrete_d); R(t, 26, 65, 12, 1, P.gold)
  ink(t)
  return t
end

local function fountain_d(f) -- wall-mounted lion head
  local t = H.img(40, 64)
  R(t, 6, 8, 28, 44, P.concrete); trap(t, 3, 7, 13, 26, 6, 33, P.concrete)
  R(t, 8, 9, 24, 1, P.concrete_l); R(t, 8, 9, 1, 40, P.concrete_l); R(t, 31, 9, 1, 40, P.concrete_d)
  R(t, 14, 5, 12, 1, P.concrete_l)
  E(t, 20, 20, 9, 9, P.gold_d)
  for a = 0, 11 do
    local x, y = 20 + math.cos(a * math.pi / 6) * 9, 20 + math.sin(a * math.pi / 6) * 9
    R(t, floor(x + 0.5) - 1, floor(y + 0.5) - 1, 2, 2, P.gold)
  end
  E(t, 20, 21, 6, 6, P.gold)
  R(t, 14, 13, 3, 3, P.gold); R(t, 23, 13, 3, 3, P.gold)
  R(t, 16, 18, 2, 2, P.ink); R(t, 22, 18, 2, 2, P.ink)
  R(t, 18, 21, 4, 2, P.gold_d); R(t, 19, 20, 2, 1, P.cream)
  R(t, 17, 24, 6, 3, P.ink)
  -- falling gulps of water, 3 px a frame
  for y = 26, 47 do
    local ph = (y - 26 - f * 3) % 12
    if ph < 5 then
      R(t, 17, y, 6, 1, P.water_l); R(t, 19, y, 2, 1, P.white)
    elseif ph < 9 then
      R(t, 19, y, 2, 1, P.water)
    end
  end
  R(t, 6, 47, 28, 3, P.water); R(t, 6, 47, 28, 1, P.water_d)
  local ph = (f + 2) % 4
  if ph == 0 then
    R(t, 16, 45, 8, 4, P.white); PX(t, 14, 43, P.white); PX(t, 25, 42, P.white); PX(t, 12, 45, P.water_l); PX(t, 27, 45, P.water_l)
  elseif ph == 1 then
    R(t, 12, 48, 4, 1, P.white); R(t, 24, 48, 4, 1, P.white); R(t, 18, 48, 4, 1, P.water_l)
  elseif ph == 2 then
    R(t, 8, 49, 4, 1, P.white); R(t, 28, 49, 4, 1, P.white)
  else
    R(t, 6, 49, 3, 1, P.water_l); R(t, 31, 49, 3, 1, P.water_l); R(t, 17, 48, 6, 1, P.water_l)
  end
  R(t, 3, 50, 34, 3, P.concrete_l); R(t, 3, 50, 34, 1, P.marble); R(t, 3, 52, 34, 1, P.concrete)
  trap(t, 53, 62, 4, 35, 10, 29, P.concrete)
  trap(t, 53, 62, 30, 35, 26, 29, P.concrete_d)
  R(t, 10, 62, 20, 1, P.concrete_d)
  ink(t)
  return t
end

------------------------------------------------------------------ CARTS (4 frame rolls)
local function cart_a(f)
  local u = H.img(64, 60)
  for _, cx in ipairs({ 14, 41 }) do R(u, cx - 1, 45, 3, 3, P.mat_nd) end
  B(u, 6, 17, 44, 29, P.concrete_l, P.ink)
  R(u, 47, 18, 2, 27, P.concrete)
  R(u, 5, 15, 46, 3, P.concrete); R(u, 5, 15, 46, 1, P.marble)
  R(u, 6, 18, 44, 1, P.ink)
  B(u, 9, 20, 38, 11, P.concrete_d, P.ink)
  B(u, 9, 33, 38, 11, P.concrete_d, P.ink)
  R(u, 11, 23, 12, 7, P.white)
  R(u, 11, 25, 12, 1, P.tile_d); R(u, 11, 28, 12, 1, P.tile_d)
  R(u, 24, 25, 10, 5, P.sky_l); R(u, 24, 27, 10, 1, P.sky)
  for _, x in ipairs({ 36, 41 }) do R(u, x, 26, 4, 4, P.white); R(u, x + 1, 27, 2, 2, P.tile_d) end
  R(u, 11, 37, 16, 6, P.white)
  R(u, 11, 39, 16, 1, P.tile_d); R(u, 11, 41, 16, 1, P.tile_d)
  R(u, 30, 36, 14, 7, P.card); R(u, 30, 36, 14, 1, P.card_m); R(u, 36, 36, 2, 7, P.tape)
  -- towel stack: bounces and the top towel slides
  local j, lean = f % 2, ({ 0, 2, 0, -2 })[f + 1]
  R(u, 9, 11 - j, 16, 4, P.white); R(u, 9, 13 - j, 16, 1, P.tile_d)
  R(u, 9 + lean, 6 - j * 2, 16, 5, P.white); R(u, 9 + lean, 8 - j * 2, 16, 1, P.tile_d)
  R(u, 9 + lean, 10 - j * 2, 16, 1, P.tile_d)
  -- spray bottles rocking opposite ways
  local w = ({ -1, 0, 1, 0 })[f + 1]
  R(u, 28, 12, 5, 3, P.blue); R(u, 28 + w, 9, 5, 3, P.blue); R(u, 28 + w, 9, 1, 3, P.water_l)
  R(u, 29 + w * 2, 7, 2, 2, P.white); R(u, 29 + w * 2, 5, 4, 2, P.red); PX(u, 33 + w * 2, 5, P.red)
  R(u, 36, 13, 4, 2, P.mat_g); R(u, 36 - w, 10, 4, 3, P.mat_g); R(u, 39 - w, 10, 1, 3, P.mat_gd)
  R(u, 37 - w * 2, 8, 2, 2, P.white)
  -- handle and the swinging laundry bag
  R(u, 50, 12, 3, 3, P.gray); R(u, 51, 12, 9, 2, P.gray); R(u, 51, 12, 9, 1, P.concrete_l)
  R(u, 59, 10, 3, 6, P.asphalt)
  local sw = ({ 0, 3, 0, -3 })[f + 1]
  for y = 15, 42 do
    local o = floor(sw * (y - 15) / 27 + 0.5)
    local x0, wd = 51 + o, 8
    if y == 41 then x0, wd = 52 + o, 6 elseif y == 42 then x0, wd = 53 + o, 4 end
    R(u, x0, y, wd, 1, y == 42 and PURPLE_D or P.purple)
    if y <= 16 then R(u, x0, y, wd, 1, PURPLE_L) end
    if y > 16 and y < 41 then R(u, 57 + o, y, 2, 1, PURPLE_D) end
    if y >= 20 and y < 34 then PX(u, 53 + o, y, PURPLE_D) end
    if y >= 24 and y < 38 then PX(u, 55 + o, y, PURPLE_L) end
    PX(u, x0 - 1, y, P.ink)
  end
  local t = H.img(64, 56)
  H.blit(t, u, 0, -2)
  wheel(t, 14, 50, 4, f); wheel(t, 41, 50, 4, f)
  ink(t)
  return t
end

local function cart_b(f) -- tall linen hamper
  local t = H.img(48, 72)
  R(t, 9, 62, 3, 3, P.mat_nd); R(t, 35, 62, 3, 3, P.mat_nd)
  wheel(t, 10, 67, 3, f); wheel(t, 36, 67, 3, f + 1)
  R(t, 5, 59, 37, 3, P.gray); R(t, 5, 59, 37, 1, P.concrete_l)
  R(t, 5, 20, 2, 39, P.gray); R(t, 40, 20, 2, 39, P.gray)
  -- overflowing linens, each lump heaving on its own beat
  local a, b, c = ({ 0, 3, 0, 1 })[f + 1], ({ 2, 0, 3, 0 })[f + 1], ({ 0, 2, 0, 3 })[f + 1]
  E(t, 14, 15 - a, 7, 6, P.white); E(t, 27, 13 - b, 8, 7, P.white); E(t, 35, 16 - c, 5, 5, P.sky_l)
  bez(t, 9, 16 - a, 14, 10 - a, 19, 15 - a, P.tile_d, 1); bez(t, 21, 12 - b, 27, 8 - b, 33, 14 - b, P.tile_d, 1)
  R(t, 33, 15 - c, 5, 1, P.sky)
  R(t, 8, 17, 32, 4, P.white)
  -- canvas bag
  R(t, 7, 22, 33, 37, P.tile)
  for x = 12, 36, 6 do R(t, x, 25, 1, 32, P.tile_d) end
  R(t, 35, 23, 5, 36, P.tile_d)
  R(t, 6, 20, 35, 3, P.blue); R(t, 6, 20, 35, 1, P.water_l)
  -- sheet flopping over the rim
  local ln, lean = ({ 0, 4, 1, 5 })[f + 1], ({ 0, 1, 0, -1 })[f + 1]
  R(t, 16 + lean, 20, 10, 13 + ln, P.white); R(t, 17 + lean, 33 + ln, 8, 1, P.white)
  R(t, 20 + lean, 22, 1, 10 + ln, P.tile_d)
  R(t, 9, 42, 29, 9, P.white)
  T(t, "LINEN", 23, 43, P.water_d, { align = "center" })
  R(t, 42, 26, 4, 2, P.gray); R(t, 45, 23, 2, 8, P.asphalt)
  ink(t)
  return t
end

local function cart_c(f) -- room-service trolley
  local t = H.img(56, 48)
  local j = f % 2
  local w = ({ 0, 1, 0, -1 })[f + 1]
  R(t, 11, 34, 2, 7, P.gold_d); R(t, 43, 34, 2, 7, P.gold_d)
  wheel(t, 12, 43, 3, f); wheel(t, 44, 43, 3, f + 2)
  R(t, 9, 35, 38, 2, P.gold); R(t, 9, 36, 38, 1, P.gold_d)
  R(t, 16 + w * 2, 31 - j, 10, 4, P.white); R(t, 16 + w * 2, 33 - j, 10, 1, P.tile_d) -- spare plates
  -- tablecloth with a swaying hem
  R(t, 5, 18, 46, 3, P.white); R(t, 5, 20, 46, 1, P.tile_d)
  R(t, 6, 21, 44, 8, P.white)
  local ph = ({ 0, 3, 0, -3 })[f + 1]
  for x = 6, 49 do
    local d = (x - 6 + ph) % 11
    local h = d < 6 and d or 10 - d
    R(t, x, 29, 1, h // 2 + 1, P.white)
    if d == 0 then R(t, x, 22, 1, 7, P.tile_d) end
  end
  R(t, 6, 27, 44, 1, P.red_d)
  -- cloche hopping off its plate
  local cdy, cdx = ({ 0, 3, 0, 1 })[f + 1], ({ 0, 1, 0, -1 })[f + 1]
  R(t, 9, 16, 24, 2, P.gray); R(t, 9, 16, 24, 1, P.concrete_l)
  if cdy > 1 then R(t, 13, 14, 16, 2, P.card_m); R(t, 15, 13, 12, 1, P.card) end -- the roast underneath
  for y = 7, 15 do
    local k = (15 - y) / 8.5
    local hw = floor(10 * math.sqrt(1 - k * k) + 0.5)
    R(t, 21 + cdx - hw, y - cdy, hw * 2, 1, P.concrete_l)
    R(t, 21 + cdx + hw - 3, y - cdy, 3, 1, P.concrete_d)
  end
  R(t, 14 + cdx, 9 - cdy, 2, 4, P.white); R(t, 16 + cdx, 8 - cdy, 3, 1, P.white)
  R(t, 20 + cdx, 5 - cdy, 3, 2, P.gray)
  -- bottle rocking, wine sloshing, flower nodding
  R(t, 36, 13, 4, 5, P.green_d); R(t, 36 + w, 8, 4, 5, P.green_d)
  R(t, 37 + w * 2, 3, 2, 5, P.green_d); R(t, 36 + w, 10, 4, 3, P.cream); R(t, 37 + w * 2, 2, 2, 1, P.gold)
  R(t, 42, 10, 4, 4, P.sky_l); R(t, 42, 12 - j, 4, 2 + j, P.red_d); R(t, 43, 14, 2, 3, P.white); R(t, 42, 17, 4, 1, P.white)
  R(t, 48, 13, 3, 5, P.blue); R(t, 49 - w, 8, 1, 5, P.grass_d)
  R(t, 48 - w * 2, 6 + j, 3, 3, P.red); PX(t, 49 - w * 2, 7 + j, P.yellow)
  -- push handle
  R(t, 2, 15, 4, 2, P.gold); R(t, 2, 15, 2, 9, P.gold_d)
  ink(t)
  return t
end

local function cart_d(f) -- luggage bell cart with a brass arch
  local t = H.img(56, 72)
  R(t, 9, 62, 3, 3, P.gold_d); R(t, 44, 62, 3, 3, P.gold_d)
  wheel(t, 10, 67, 3, f); wheel(t, 45, 67, 3, f + 3)
  -- arch
  R(t, 5, 12, 2, 46, P.gold); R(t, 49, 12, 2, 46, P.gold)
  R(t, 6, 12, 1, 46, P.gold_d); R(t, 50, 12, 1, 46, P.gold_d)
  bez(t, 5, 12, 5, 4, 14, 4, P.gold, 2); bez(t, 50, 12, 50, 4, 41, 4, P.gold, 2)
  R(t, 14, 4, 28, 2, P.gold); R(t, 14, 5, 28, 1, P.gold_d)
  E(t, 28, 3, 2, 2, P.gold); PX(t, 27, 2, P.cream)
  R(t, 7, 15, 42, 1, P.gold_d) -- hanging rail
  -- garment bag swinging on its hanger
  local sw = ({ 0, 4, 0, -4 })[f + 1]
  R(t, 38, 14, 1, 3, P.gray)
  R(t, 34, 16, 9, 1, P.asphalt)
  for y = 17, 40 do
    local o = floor(sw * (y - 16) / 24 + 0.5)
    R(t, 33 + o, y, 11, 1, P.asphalt); PX(t, 38 + o, y, P.gray); R(t, 42 + o, y, 2, 1, P.asphalt_d)
  end
  -- suitcases: the top one slides and hops, the red one hops on the off beat
  local s, j, j2 = ({ 0, 2, 0, -2 })[f + 1], ({ 0, 2, 0, 2 })[f + 1], ({ 2, 0, 2, 0 })[f + 1]
  case(t, 8, 56, 23, 17, P.water_d, D_BLUE, P.water)
  case(t, 11 + s, 37 - j, 16, 10, P.card_m, P.card_dd, P.card)
  case(t, 33, 56 - j2, 14, 12, P.red_d, P.door_d, P.red)
  R(t, 18 + (f % 2) * 2, 45, 4, 5 + f % 2, P.cream); PX(t, 19 + (f % 2) * 2, 46, P.ink)
  -- carpeted deck
  R(t, 3, 57, 50, 5, P.carpet); R(t, 3, 57, 50, 1, P.gold); R(t, 3, 61, 50, 1, P.carpet_d)
  R(t, 3, 58, 2, 3, P.gold_d); R(t, 51, 58, 2, 3, P.gold_d)
  ink(t)
  return t
end

------------------------------------------------------------------ FRONT DESKS
local function desk_b() -- curved, light wood slats
  local t = H.img(96, 48)
  E(t, 11, 32, 7, 14, P.card_d); E(t, 84, 32, 7, 14, P.card_d)
  R(t, 11, 18, 74, 29, P.card_d)
  for x = 8, 88, 5 do
    R(t, x, 20, 1, 24, P.card_dd)
    R(t, x + 1, 20, 1, 24, P.card_m)
  end
  R(t, 5, 21, 86, 2, P.gold); R(t, 5, 22, 86, 1, P.gold_d)
  R(t, 6, 43, 84, 1, P.gold_d)
  R(t, 7, 44, 82, 3, P.card_dd)
  PX(t, 4, 21, P.none); PX(t, 91, 21, P.none)
  -- thick rounded counter
  R(t, 3, 12, 90, 1, WOOD_L); R(t, 2, 13, 92, 3, P.base); R(t, 3, 16, 90, 1, P.base_d)
  R(t, 4, 13, 88, 1, WOOD_L)
  -- banker's lamp
  R(t, 17, 10, 10, 2, P.gold_d); R(t, 21, 5, 2, 5, P.gold)
  R(t, 14, 2, 16, 4, P.green_d); R(t, 15, 1, 14, 1, P.green_d); R(t, 15, 2, 6, 1, P.green)
  R(t, 15, 6, 14, 1, P.cream)
  bell(t, 56, 11)
  -- flowers
  R(t, 74, 6, 5, 6, P.white); R(t, 78, 7, 1, 5, P.tile_d)
  R(t, 73, 2, 3, 3, P.red); R(t, 77, 1, 3, 3, PINK); R(t, 75, 4, 3, 2, P.grass); PX(t, 74, 3, P.yellow); PX(t, 78, 2, P.yellow)
  ink(t)
  return t
end

local function desk_c() -- marble topped
  local t = H.img(96, 52)
  R(t, 5, 46, 86, 5, P.frame); R(t, 5, 46, 86, 1, P.base_d)
  R(t, 6, 20, 84, 26, P.base_d)
  for i = 0, 2 do
    local x = 10 + i * 27
    B(t, x, 24, 22, 18, P.marble, P.gold_d)
    L(t, x + 3, 39, x + 10, 27, P.tile_d); L(t, x + 12, 40, x + 18, 30, P.tile_d)
    L(t, x + 10, 27, x + 14, 26, P.tile_d)
  end
  R(t, 6, 20, 84, 1, P.gold); R(t, 6, 44, 84, 1, P.gold_d)
  R(t, 2, 14, 92, 6, P.marble); R(t, 2, 14, 92, 1, P.white); R(t, 2, 19, 92, 1, P.tile_d)
  for x = 8, 80, 18 do L(t, x, 18, x + 7, 15, P.tile_d); L(t, x + 9, 17, x + 13, 16, P.tile_d) end
  -- monitor, bell, pen
  R(t, 24, 11, 4, 3, P.asphalt); R(t, 21, 13, 10, 1, P.asphalt)
  B(t, 17, 1, 18, 11, P.sky, P.asphalt); R(t, 19, 3, 8, 1, P.white); R(t, 19, 5, 12, 1, P.sky_l); R(t, 19, 7, 6, 1, P.sky_l)
  bell(t, 60, 13)
  R(t, 76, 10, 4, 4, P.asphalt); R(t, 77, 6, 1, 4, P.blue); R(t, 79, 7, 1, 3, P.gold)
  ink(t)
  return t
end

local function desk_d() -- small bell stand
  local t = H.img(40, 52)
  R(t, 4, 46, 32, 5, P.base_d); R(t, 4, 46, 32, 1, P.frame)
  R(t, 6, 18, 28, 28, P.base); R(t, 6, 18, 28, 1, P.base_d); R(t, 31, 19, 3, 27, P.base_d)
  B(t, 6, 22, 28, 11, P.gold, P.gold_d); R(t, 7, 23, 26, 1, P.cream)
  T(t, "BELL", 20, 24, P.base_d, { align = "center" })
  B(t, 10, 36, 20, 8, P.base, P.base_d); R(t, 11, 37, 18, 1, WOOD_L)
  R(t, 3, 14, 34, 4, P.base); R(t, 3, 14, 34, 1, WOOD_L); R(t, 3, 17, 34, 1, P.base_d)
  -- big bell
  R(t, 12, 13, 16, 1, P.asphalt)
  R(t, 13, 9, 14, 3, P.gold); R(t, 13, 12, 14, 1, P.gold_d)
  R(t, 14, 7, 12, 2, P.gold); R(t, 16, 5, 8, 2, P.gold)
  R(t, 23, 7, 3, 5, P.gold_d); R(t, 15, 8, 2, 2, P.cream); R(t, 17, 6, 2, 1, P.cream)
  R(t, 19, 2, 2, 3, P.gold_d)
  ink(t)
  return t
end

------------------------------------------------------------------ LUGGAGE DOORS (s = 1 closed, 2 half, 3 open)
local DX, DW, DH = 12, 40, 78
local DY = 96 - DH

local function dimcase(im, x, bottom, w, h, col)
  local y = bottom - h + 1
  R(im, x, y, w, h, col)
  R(im, x + w // 2 - 2, y - 2, 4, 1, col)
  PX(im, x + w // 2 - 2, y - 1, col); PX(im, x + w // 2 + 1, y - 1, col)
  R(im, x + 2, y, 1, h, DARK); R(im, x + w - 3, y, 1, h, DARK)
end

local function door_base()
  local im = H.img(64, 96)
  R(im, DX - 3, DY - 3, DW + 6, DH + 3, P.frame)
  R(im, DX, DY, DW, DH, DARK)
  R(im, DX, DY + 30, DW, 2, SHELF); R(im, DX, DY + 54, DW, 2, SHELF)
  dimcase(im, DX + 3, DY + 29, 14, 12, D_BLUE); dimcase(im, DX + 20, DY + 29, 16, 9, D_TAN)
  dimcase(im, DX + 6, DY + 53, 18, 13, D_RED); dimcase(im, DX + 27, DY + 53, 10, 16, D_GRN)
  dimcase(im, DX + 2, DY + 77, 16, 14, D_TAN); dimcase(im, DX + 21, DY + 77, 15, 18, D_BLUE)
  return im
end

local function door_sign(im)
  B(im, 8, 2, 48, 11, P.gold, P.ink)
  R(im, 9, 11, 46, 1, P.gold_d)
  T(im, "LUGGAGE", 32, 4, P.ink, { align = "center" })
end

local function door_b(s) -- green roller shutter
  local im = door_base()
  local hh = ({ DH, 46, 15 })[s]
  B(im, DX, DY, DW, hh, P.green_d, P.ink)
  for y = DY + 3, DY + hh - 7, 4 do
    R(im, DX + 1, y, DW - 2, 1, SLAT_D); R(im, DX + 1, y + 1, DW - 2, 1, P.grass)
  end
  R(im, DX, DY + hh - 6, DW, 6, P.ink)
  R(im, DX + 1, DY + hh - 5, DW - 2, 4, P.gold_d); R(im, DX + 1, DY + hh - 5, DW - 2, 1, P.gold)
  B(im, DX + 15, DY + hh - 5, 10, 4, P.asphalt, P.ink)
  B(im, DX - 1, DY - 2, DW + 2, 5, P.mat_n, P.ink); R(im, DX, DY - 1, DW, 1, P.concrete_l)
  door_sign(im)
  return im
end

local function door_c(s) -- teal double swing doors with portholes
  local im = door_base()
  if s == 3 then
    B(im, DX, DY, 7, DH, TEAL_D, P.ink); R(im, DX + 1, DY + 1, 2, DH - 2, TEAL)
    B(im, DX + DW - 7, DY, 7, DH, TEAL_D, P.ink); R(im, DX + DW - 3, DY + 1, 2, DH - 2, TEAL)
  elseif s == 2 then -- leaves swung halfway, seen foreshortened
    for i = 0, 1 do
      local x = i == 0 and DX or DX + DW - 13
      B(im, x, DY, 13, DH, TEAL, P.ink)
      R(im, x + 1, DY + 1, 11, 1, TEAL_L)
      R(im, i == 0 and x + 8 or x + 1, DY + 2, 4, DH - 3, TEAL_D)
      E(im, x + 6, DY + 20, 4, 6, P.gold, P.ink)
      E(im, x + 6, DY + 20, 2, 4, P.sky, P.gold_d)
      B(im, i == 0 and x + 8 or x + 2, DY + 36, 3, 13, P.concrete_l, P.mat_nd)
      R(im, x + 1, DY + DH - 13, 11, 12, P.concrete); R(im, x + 1, DY + DH - 13, 11, 1, P.concrete_l)
      R(im, x + 1, DY + DH - 14, 11, 1, P.ink)
    end
  else
    for i = 0, 1 do
      local x = DX + i * 20
      B(im, x, DY, 20, DH, TEAL, P.ink)
      R(im, x + 1, DY + 1, 18, 1, TEAL_L)
      R(im, x + (i == 0 and 1 or 17), DY + 2, 2, DH - 3, i == 0 and TEAL_L or TEAL_D)
      E(im, x + 10, DY + 20, 6, 6, P.gold, P.ink)
      E(im, x + 10, DY + 20, 4, 4, P.sky, P.gold_d)
      L(im, x + 8, DY + 21, x + 11, DY + 18, P.white)
      local hx = i == 0 and x + 13 or x + 3
      B(im, hx, DY + 36, 5, 13, P.concrete_l, P.mat_nd)
      R(im, x + 1, DY + DH - 13, 18, 12, P.concrete); R(im, x + 1, DY + DH - 13, 18, 1, P.concrete_l)
      R(im, x + 1, DY + DH - 14, 18, 1, P.ink)
    end
  end
  door_sign(im)
  return im
end

local function door_d(s) -- brass cage lift gate, folding to the left
  local im = door_base()
  local w, per, bar = ({ DW, 25, 11 })[s], ({ 10, 6, 4 })[s], ({ 13, 8, 5 })[s]
  local th = s == 1 and 2 or 1
  for y = DY + 2, DY + DH - 3 do
    for x = DX + 1, DX + w - 2 do
      local a, b = (x - DX + y) % per, (x - DX - y) % per
      if a < th or b < th then PX(im, x, y, P.gold) end
      if s == 1 and (a == 2 or b == 2) then PX(im, x, y, P.gold_d) end
    end
  end
  for x = DX, DX + w - 1, bar do
    R(im, x, DY, 2, DH, P.gold); R(im, x + 1, DY, 1, DH, P.gold_d)
  end
  R(im, DX + w - 2, DY, 2, DH, P.gold); R(im, DX + w - 1, DY, 1, DH, P.gold_d)
  R(im, DX, DY, w, 3, P.gold); R(im, DX, DY + 2, w, 1, P.gold_d)
  R(im, DX, DY + DH - 4, w, 4, P.gold); R(im, DX, DY + DH - 4, w, 1, P.cream); R(im, DX, DY + DH - 1, w, 1, P.gold_d)
  if s > 1 then R(im, DX + w, DY, 1, DH, P.ink) end
  if s < 3 then B(im, DX + w - 9, DY + 36, 6, 10, P.gold, P.ink); R(im, DX + w - 7, DY + 38, 2, 6, P.gold_d) end
  door_sign(im)
  return im
end

------------------------------------------------------------------ EXTRA HOTEL PROPS
local function new_palm()
  local t = H.img(40, 72)
  local function frond(x1, y1, lift)
    bez(t, 20, 30, (20 + x1) / 2, math.min(30, y1) - lift, x1, y1, P.grass, 2, function(x, y, i)
      if i > 3 and i % 2 == 0 then R(t, x, y + 1, 1, 4, P.grass_d) end
      if i > 3 and i % 2 == 1 then R(t, x, y + 1, 1, 3, P.grass) end
      if i > 2 then PX(t, x, y, GREEN_L) end
    end)
  end
  frond(2, 42, 16); frond(37, 42, 16)
  frond(2, 24, 14); frond(37, 24, 14)
  frond(8, 6, 6); frond(31, 7, 6); frond(20, 2, 0)
  R(t, 18, 30, 4, 27, P.dirt); R(t, 21, 30, 1, 27, P.dirt_d)
  for y = 33, 54, 4 do R(t, 18, y, 4, 1, P.dirt_d) end
  R(t, 11, 56, 18, 3, P.gold); R(t, 11, 56, 18, 1, P.cream)
  trap(t, 59, 70, 12, 27, 15, 24, P.gold_d)
  trap(t, 60, 69, 14, 14, 16, 16, P.gold)
  R(t, 13, 63, 14, 1, P.gold)
  ink(t)
  return t
end

local function seat(w, c, d, l, n)
  local t = H.img(w, 44)
  R(t, 6, 38, 3, 5, P.base_d); R(t, w - 9, 38, 3, 5, P.base_d)
  R(t, 8, 4, w - 16, 24, c); R(t, 10, 3, w - 20, 1, c); R(t, 9, 4, w - 18, 1, l)
  for x = 13, w - 14, 7 do
    for y = 9, 19, 5 do PX(t, x + ((y // 5) % 2) * 3, y, d) end
  end
  local cw = (w - 20) // n
  for i = 0, n - 1 do
    R(t, 10 + i * cw, 24, cw, 7, l); R(t, 10 + i * cw, 30, cw, 1, d)
    if i > 0 then R(t, 10 + i * cw, 24, 1, 7, d) end
  end
  R(t, 10, 31, w - 20, 7, d); R(t, 10, 37, w - 20, 1, P.gold_d)
  for _, x in ipairs({ 3, w - 10 }) do
    R(t, x, 18, 7, 20, c); R(t, x + 1, 17, 5, 1, c); R(t, x, 18, 7, 2, l); R(t, x, 36, 7, 2, d)
  end
  ink(t)
  return t
end

local function new_table_lamp()
  local t = H.img(32, 60)
  R(t, 8, 55, 16, 4, P.base_d); R(t, 14, 39, 4, 16, P.base); R(t, 17, 39, 1, 16, P.base_d)
  R(t, 4, 35, 24, 4, P.base); R(t, 4, 35, 24, 1, WOOD_L); R(t, 4, 38, 24, 1, P.base_d)
  R(t, 12, 32, 8, 3, P.gold_d); R(t, 15, 21, 2, 11, P.gold); E(t, 16, 27, 2, 3, P.gold)
  trap(t, 8, 20, 11, 20, 6, 25, P.cream)
  trap(t, 8, 20, 18, 20, 22, 25, P.tape)
  R(t, 6, 20, 20, 1, P.gold_d); R(t, 11, 8, 10, 1, P.gold_d)
  ink(t)
  return t
end

local function new_floor_lamp()
  local t = H.img(24, 80)
  R(t, 5, 75, 14, 4, P.gold_d); R(t, 7, 74, 10, 1, P.gold); R(t, 5, 75, 14, 1, P.gold)
  R(t, 11, 22, 2, 52, P.gold); R(t, 12, 22, 1, 52, P.gold_d)
  E(t, 11, 48, 2, 2, P.gold)
  trap(t, 4, 21, 8, 15, 3, 20, P.cream)
  trap(t, 4, 21, 13, 15, 17, 20, P.tape)
  R(t, 3, 21, 18, 1, P.gold_d); R(t, 8, 4, 8, 1, P.gold_d)
  R(t, 16, 22, 1, 6, P.gold_d); R(t, 15, 28, 3, 2, P.gold)
  ink(t)
  return t
end

local function new_luggage_pile()
  local t = H.img(56, 48)
  case(t, 45, 46, 9, 26, P.green_d, D_GRN, P.green)
  -- steamer trunk
  R(t, 3, 27, 40, 20, P.card_d); R(t, 3, 27, 40, 1, P.card_m); R(t, 3, 45, 40, 2, P.card_dd)
  R(t, 10, 27, 3, 20, P.card_dd); R(t, 33, 27, 3, 20, P.card_dd)
  R(t, 3, 34, 40, 1, P.card_dd)
  for _, p in ipairs({ { 3, 27 }, { 40, 27 }, { 3, 44 }, { 40, 44 } }) do R(t, p[1], p[2], 3, 3, P.gold) end
  B(t, 20, 32, 6, 5, P.gold, P.gold_d)
  case(t, 7, 26, 28, 12, P.blue, P.water_d, P.water_l)
  R(t, 25, 18, 5, 4, P.cream); PX(t, 26, 19, P.red)
  -- hat box
  R(t, 13, 6, 16, 7, PINK); R(t, 12, 5, 18, 2, P.white); R(t, 13, 12, 16, 1, P.door_l)
  R(t, 20, 5, 2, 8, P.red)
  ink(t)
  return t
end

local function new_suitcase()
  local t = H.img(24, 36)
  R(t, 8, 2, 8, 2, P.gray); R(t, 8, 4, 1, 6, P.gray); R(t, 15, 4, 1, 6, P.gray)
  R(t, 4, 10, 16, 22, P.red); R(t, 4, 10, 16, 1, P.door_l); R(t, 17, 11, 3, 21, P.red_d)
  R(t, 4, 30, 16, 2, P.red_d)
  for x = 7, 16, 3 do R(t, x, 13, 1, 16, P.red_d) end
  R(t, 9, 9, 6, 1, P.asphalt)
  R(t, 5, 32, 3, 3, P.asphalt); R(t, 16, 32, 3, 3, P.asphalt)
  R(t, 12, 16, 5, 6, P.cream); PX(t, 13, 17, P.ink); R(t, 13, 19, 3, 1, P.gray)
  ink(t)
  return t
end

local function new_tray()
  local t = H.img(32, 16)
  R(t, 2, 12, 28, 3, P.concrete_l); R(t, 2, 12, 28, 1, P.white); R(t, 2, 14, 28, 1, P.concrete_d)
  R(t, 1, 11, 2, 2, P.gray); R(t, 29, 11, 2, 2, P.gray)
  for y = 5, 11 do
    local k = (11 - y) / 6.5
    local hw = floor(7 * math.sqrt(1 - k * k) + 0.5)
    R(t, 11 - hw, y, hw * 2, 1, P.concrete_l); R(t, 11 + hw - 2, y, 2, 1, P.concrete_d)
  end
  R(t, 7, 7, 2, 3, P.white); R(t, 10, 3, 2, 2, P.gray)
  R(t, 20, 6, 4, 6, P.sky_l); R(t, 20, 9, 4, 3, P.orange); R(t, 20, 6, 1, 6, P.white)
  R(t, 25, 9, 4, 3, P.white); PX(t, 26, 8, P.white); R(t, 26, 10, 2, 1, P.tile_d)
  ink(t)
  return t
end

local function new_ice_machine()
  local t = H.img(40, 72)
  R(t, 5, 68, 5, 3, P.asphalt); R(t, 30, 68, 5, 3, P.asphalt)
  R(t, 4, 5, 32, 63, P.concrete_l); R(t, 33, 6, 3, 62, P.concrete); R(t, 4, 5, 32, 1, P.white)
  R(t, 6, 8, 28, 13, P.blue); R(t, 6, 8, 28, 1, P.water_l); R(t, 6, 20, 28, 1, P.water_d)
  T(t, "ICE", 20, 11, P.white, { align = "center" })
  PX(t, 9, 11, P.white); PX(t, 8, 12, P.white); PX(t, 10, 12, P.white); PX(t, 9, 13, P.white)
  PX(t, 30, 15, P.white); PX(t, 29, 16, P.white); PX(t, 31, 16, P.white); PX(t, 30, 17, P.white)
  B(t, 8, 25, 24, 18, P.asphalt_d, P.ink)
  R(t, 17, 26, 6, 4, P.gray); R(t, 18, 30, 4, 2, P.concrete_d)
  for _, p in ipairs({ { 11, 38 }, { 15, 36 }, { 19, 38 }, { 23, 37 }, { 26, 38 }, { 14, 39 }, { 21, 35 } }) do
    R(t, p[1], p[2], 3, 3, P.sky_l); PX(t, p[1], p[2], P.white)
  end
  R(t, 9, 41, 22, 1, P.gray)
  R(t, 28, 46, 5, 3, P.xred); R(t, 8, 46, 12, 3, P.asphalt); R(t, 9, 47, 4, 1, P.mat_g)
  for y = 53, 64, 3 do R(t, 8, y, 24, 1, P.concrete_d) end
  ink(t)
  return t
end

local function new_vending()
  local t = H.img(44, 76)
  R(t, 4, 72, 5, 3, P.asphalt); R(t, 35, 72, 5, 3, P.asphalt)
  R(t, 3, 3, 38, 69, P.red_d); R(t, 3, 3, 38, 1, P.red); R(t, 38, 4, 3, 68, P.door_d)
  T(t, "SNACKS", 22, 5, P.white, { align = "center" })
  B(t, 5, 14, 24, 43, P.asphalt_d, P.ink)
  local cols = { P.yellow, P.blue, P.mat_g, P.orange, P.purple, P.white, P.red, P.card }
  for r = 0, 3 do
    R(t, 6, 24 + r * 10, 22, 1, P.gray)
    for c = 0, 3 do
      local col = cols[(r * 3 + c * 5) % #cols + 1]
      R(t, 7 + c * 5, 17 + r * 10, 4, 7, col); R(t, 7 + c * 5, 19 + r * 10, 4, 2, P.white)
    end
  end
  R(t, 31, 14, 8, 6, P.ink); R(t, 32, 15, 6, 2, P.mat_g)
  B(t, 31, 22, 8, 11, P.asphalt, P.ink)
  for r = 0, 2 do for c = 0, 1 do R(t, 33 + c * 3, 24 + r * 3, 2, 2, P.concrete_l) end end
  R(t, 33, 36, 4, 1, P.ink); R(t, 32, 39, 6, 4, P.asphalt)
  B(t, 5, 60, 24, 9, P.asphalt, P.ink); R(t, 7, 62, 20, 2, P.gray)
  ink(t)
  return t
end

local lift_panel = H.img(22, 78)
B(lift_panel, 0, 0, 22, 78, P.gold, P.ink)
R(lift_panel, 1, 1, 20, 1, P.cream); R(lift_panel, 18, 2, 3, 75, P.gold_d)
B(lift_panel, 4, 6, 14, 28, P.gold, P.gold_d); B(lift_panel, 4, 38, 14, 34, P.gold, P.gold_d)
for d = 0, 5 do PX(lift_panel, 11 - d, 14 + d, P.cream); PX(lift_panel, 10 + d, 14 + d, P.cream) end

local function new_elevator(s) -- the two brass panels slide apart into the wall
  local im = H.img(64, 96)
  local slide = ({ 0, 10, 17 })[s]
  R(im, 5, 13, 54, 83, P.mat_nd); R(im, 6, 14, 52, 82, P.mat_n); R(im, 6, 14, 52, 1, P.concrete_l)
  B(im, 9, 17, 46, 79, P.ink, P.ink)
  if s > 1 then
    R(im, 10, 18, 44, 78, P.base)
    for x = 10, 53, 11 do R(im, x, 18, 1, 60, P.base_d) end
    B(im, 16, 24, 32, 22, P.sky_l, P.gold_d); L(im, 20, 40, 30, 28, P.white); L(im, 26, 42, 34, 32, P.white)
    R(im, 10, 54, 44, 2, P.gold); R(im, 10, 56, 44, 1, P.gold_d)
    R(im, 10, 78, 44, 18, P.carpet_d); R(im, 10, 78, 44, 1, P.base_d)
    R(im, 22, 19, 20, 2, P.cream)
  end
  H.blit(im, lift_panel, 10, 18, slide, 0, 22 - slide, 78)
  H.blit(im, lift_panel, 32 + slide, 18, 0, 0, 22 - slide, 78)
  -- floor dial and call button
  B(im, 20, 1, 24, 11, P.cream, P.ink)
  for a = 0, 4 do
    local ang = math.pi + a * math.pi / 4
    PX(im, floor(32 + math.cos(ang) * 9 + 0.5), floor(10 + math.sin(ang) * 7 + 0.5), P.ink)
  end
  local nx = ({ { 37, 4 }, { 32, 3 }, { 26, 5 } })[s]
  L(im, 32, 10, nx[1], nx[2], P.xred)
  R(im, 31, 9, 3, 2, P.gold_d)
  B(im, 59, 48, 5, 12, P.gold, P.ink); R(im, 61, 51, 1, 2, s > 1 and P.mat_g or P.cream); R(im, 61, 55, 1, 2, P.cream)
  return im
end

local function frame(w, h, canvas)
  local t = H.img(w, h)
  R(t, 1, 1, w - 2, h - 2, P.gold)
  B(t, 2, 2, w - 4, h - 4, P.gold, P.gold_d)
  R(t, 1, 1, w - 2, 1, P.cream)
  for _, p in ipairs({ { 1, 1 }, { w - 4, 1 }, { 1, h - 4 }, { w - 4, h - 4 } }) do R(t, p[1], p[2], 3, 3, P.gold_d) end
  B(t, 4, 4, w - 8, h - 8, canvas, P.ink)
  return t
end

local function new_painting_a() -- landscape
  local t = frame(48, 40, P.sky)
  R(t, 5, 5, 38, 8, P.sky_l)
  E(t, 34, 12, 3, 3, P.yellow)
  trap(t, 14, 24, 14, 14, 5, 24, P.purple); trap(t, 17, 24, 28, 28, 20, 38, PURPLE_L)
  for x = 5, 42 do
    local y = floor(25 + math.sin(x / 6) * 2 + 0.5)
    R(t, x, y, 1, 35 - y, P.grass)
    if x % 3 == 0 then PX(t, x, y, GREEN_L) end
  end
  R(t, 14, 29, 20, 4, P.water); R(t, 17, 30, 8, 1, P.water_l); R(t, 12, 30, 2, 2, P.water); R(t, 34, 30, 2, 2, P.water)
  R(t, 8, 23, 1, 4, P.dirt_d); E(t, 8, 21, 2, 2, P.grass_d)
  ink(t)
  return t
end

local function new_painting_b() -- stern portrait
  local t = frame(32, 44, P.base_d)
  R(t, 5, 5, 22, 10, P.frame)
  R(t, 8, 29, 16, 10, P.asphalt); R(t, 14, 29, 4, 6, P.white); R(t, 15, 31, 2, 6, P.red_d)
  R(t, 14, 26, 4, 3, SKIN)
  E(t, 16, 19, 5, 6, SKIN)
  R(t, 11, 11, 10, 4, P.ink); R(t, 10, 13, 2, 6, P.ink); R(t, 20, 13, 2, 6, P.ink)
  R(t, 13, 18, 2, 1, P.ink); R(t, 17, 18, 2, 1, P.ink)
  R(t, 12, 16, 3, 1, P.ink); R(t, 17, 16, 3, 1, P.ink)
  R(t, 13, 22, 6, 1, P.ink); PX(t, 12, 23, P.ink); PX(t, 19, 23, P.ink)
  PX(t, 16, 20, P.cap_d)
  ink(t)
  return t
end

local function new_painting_c() -- ship at sea
  local t = frame(48, 40, P.sky_l)
  R(t, 5, 5, 38, 6, P.cream)
  R(t, 5, 24, 38, 11, P.water_d)
  for y = 25, 33, 3 do
    for x = 6 + (y % 2) * 4, 40, 8 do R(t, x, y, 4, 1, P.water) end
  end
  trap(t, 21, 25, 12, 34, 15, 31, P.base_d); R(t, 12, 21, 23, 1, P.gold_d)
  R(t, 22, 7, 1, 14, P.base_d); R(t, 30, 10, 1, 11, P.base_d)
  trap(t, 8, 19, 23, 23, 23, 29, P.white); trap(t, 9, 19, 21, 21, 15, 21, P.white)
  trap(t, 11, 19, 31, 31, 31, 35, P.tile)
  R(t, 23, 6, 3, 2, P.red)
  R(t, 9, 9, 5, 2, P.white); R(t, 36, 13, 4, 1, P.white)
  ink(t)
  return t
end

local function new_clock()
  local t = H.img(24, 24)
  E(t, 12, 12, 10, 10, P.gold); E(t, 12, 12, 9, 9, P.gold_d); E(t, 12, 12, 8, 8, P.cream)
  for a = 0, 11 do
    local x, y = 12 + math.cos(a * math.pi / 6) * 6.6, 12 + math.sin(a * math.pi / 6) * 6.6
    PX(t, floor(x + 0.5), floor(y + 0.5), a % 3 == 0 and P.ink or P.gold_d)
  end
  L(t, 12, 12, 12, 7, P.ink); L(t, 12, 12, 16, 14, P.ink); PX(t, 12, 12, P.xred)
  ink(t)
  return t
end

local function new_extinguisher()
  local t = H.img(16, 36)
  R(t, 4, 12, 8, 22, P.red); R(t, 5, 11, 6, 1, P.red); R(t, 10, 12, 2, 22, P.red_d)
  R(t, 5, 13, 1, 19, P.door_l); R(t, 4, 33, 8, 2, P.red_d)
  R(t, 4, 19, 8, 6, P.cream); R(t, 6, 21, 4, 1, P.red); R(t, 6, 23, 3, 1, P.ink)
  R(t, 6, 7, 4, 4, P.asphalt); R(t, 4, 5, 8, 2, P.asphalt); R(t, 3, 3, 6, 2, P.xred)
  L(t, 11, 8, 13, 11, P.asphalt); R(t, 13, 11, 1, 14, P.asphalt); R(t, 12, 25, 3, 3, P.asphalt)
  PX(t, 8, 8, P.gold)
  ink(t)
  return t
end

local function new_bin()
  local t = H.img(24, 32)
  R(t, 4, 28, 16, 3, P.gold); R(t, 4, 30, 16, 1, P.gold_d)
  R(t, 5, 8, 14, 20, P.gold_d); R(t, 6, 8, 2, 20, P.gold); R(t, 16, 8, 3, 20, H.c("8f6620"))
  R(t, 5, 16, 14, 1, P.gold); R(t, 5, 17, 14, 1, H.c("8f6620"))
  B(t, 8, 10, 8, 5, P.ink, P.ink); R(t, 9, 13, 3, 2, P.white)
  R(t, 3, 5, 18, 3, P.gold); R(t, 3, 5, 18, 1, P.cream); R(t, 3, 7, 18, 1, P.gold_d)
  R(t, 6, 4, 12, 1, P.tape); R(t, 9, 2, 1, 2, P.white); PX(t, 9, 1, P.orange); R(t, 13, 3, 3, 1, P.white)
  ink(t)
  return t
end

local function new_umbrella_stand()
  local t = H.img(24, 44)
  -- umbrellas
  R(t, 8, 7, 3, 20, P.red); R(t, 9, 7, 1, 20, P.red_d)
  R(t, 9, 3, 1, 4, P.base); R(t, 9, 2, 4, 1, P.base); R(t, 12, 3, 1, 3, P.base)
  L(t, 13, 26, 17, 9, P.blue, 2); L(t, 17, 8, 18, 4, P.base_d); R(t, 18, 3, 3, 1, P.base_d); PX(t, 20, 4, P.base_d)
  R(t, 12, 13, 2, 14, P.yellow); R(t, 12, 9, 2, 4, P.asphalt); R(t, 11, 7, 4, 2, P.asphalt)
  -- stand
  R(t, 5, 26, 14, 16, P.asphalt); R(t, 6, 26, 2, 16, P.gray); R(t, 16, 26, 3, 16, P.asphalt_d)
  R(t, 4, 25, 16, 2, P.gold); R(t, 4, 25, 16, 1, P.cream)
  R(t, 5, 34, 14, 1, P.gold_d); R(t, 4, 41, 16, 2, P.gold_d)
  ink(t)
  return t
end

local function new_stanchion()
  local t = H.img(56, 44)
  bez(t, 8, 14, 28, 32, 47, 14, P.carpet_d, 3)
  bez(t, 8, 13, 28, 31, 47, 13, P.carpet_l, 2)
  for _, x in ipairs({ 7, 47 }) do
    R(t, x - 5, 40, 11, 3, P.gold_d); R(t, x - 4, 39, 9, 1, P.gold); R(t, x - 5, 40, 11, 1, P.gold)
    R(t, x - 1, 11, 3, 28, P.gold); R(t, x + 1, 11, 1, 28, P.gold_d)
    R(t, x - 2, 10, 5, 2, P.gold_d)
    E(t, x, 6, 3, 3, P.gold); PX(t, x - 1, 5, P.cream); R(t, x + 1, 7, 2, 2, P.gold_d)
    R(t, x - 3, 13, 2, 3, P.gold_d); R(t, x + 2, 13, 2, 3, P.gold_d)
  end
  ink(t)
  return t
end

local function new_exit_sign()
  local t = H.img(32, 16)
  R(t, 8, 1, 2, 3, P.gray); R(t, 22, 1, 2, 3, P.gray)
  R(t, 2, 4, 28, 11, P.green_d); R(t, 2, 4, 28, 1, P.green); R(t, 2, 14, 28, 1, SLAT_D)
  T(t, "EXIT", 16, 6, P.white, { align = "center" })
  ink(t)
  return t
end

local function new_chandelier()
  local t = H.img(56, 40)
  R(t, 27, 1, 2, 9, P.gold_d); R(t, 25, 1, 6, 2, P.gold)
  for _, s in ipairs({ -1, 1 }) do
    for _, a in ipairs({ { 12, 17 }, { 23, 14 } }) do
      local x = 28 + s * a[1]
      bez(t, 28 + s * 3, 16, 28 + s * (a[1] / 2), a[2] + 14, x, a[2] + 2, P.gold, 2)
      R(t, x - 2, a[2], 5, 2, P.gold_d)
      R(t, x - 1, a[2] - 5, 3, 5, P.cream); R(t, x + 1, a[2] - 5, 1, 5, P.tape)
      R(t, x, a[2] - 8, 1, 3, P.yellow); PX(t, x, a[2] - 6, P.orange)
      PX(t, x, a[2] + 3, P.white); R(t, x, a[2] + 4, 1, 2, P.sky_l)
    end
  end
  E(t, 28, 14, 4, 4, P.gold); R(t, 26, 12, 2, 2, P.cream)
  R(t, 26, 19, 5, 4, P.gold_d); E(t, 28, 26, 2, 2, P.gold)
  R(t, 28, 29, 1, 2, P.white); R(t, 27, 31, 3, 3, P.sky_l); PX(t, 28, 34, P.white)
  ink(t)
  return t
end

local function new_newspapers()
  local t = H.img(28, 16)
  for i = 0, 3 do
    local o = ({ 0, 1, -1, 0 })[i + 1]
    R(t, 3 + o, 12 - i * 3, 22, 3, P.white); R(t, 3 + o, 14 - i * 3, 22, 1, P.tile_d)
  end
  R(t, 5, 4, 10, 1, P.ink); R(t, 5, 6, 6, 1, P.gray); R(t, 17, 4, 6, 3, P.gray)
  R(t, 13, 3, 2, 12, P.card_m)
  ink(t)
  return t
end

local function new_dnd_hanger()
  local t = H.img(16, 28)
  R(t, 3, 2, 10, 24, P.red); R(t, 4, 1, 8, 1, P.red); R(t, 3, 25, 10, 1, P.red_d); R(t, 11, 3, 2, 22, P.red_d)
  E(t, 8, 6, 2, 2, P.none); R(t, 6, 4, 5, 5, P.none)
  R(t, 5, 12, 6, 1, P.white); R(t, 5, 14, 6, 1, P.white); R(t, 6, 16, 4, 1, P.white)
  E(t, 8, 21, 2, 2, P.white); R(t, 6, 21, 5, 1, P.red)
  ink(t)
  return t
end

------------------------------------------------------------------ build everything
local function fromfile(name) return Image { fromFile = OPT .. name .. ".png" } end
local doorA = fromfile("luggage_door_a")
local D3 = { { "closed", 1, 1 }, { "half", 2, 2 }, { "open", 3, 3 } }
local VAC_TAGS = { { "patrol", 1, 4 }, { "bump", 5, 6 }, { "stuck", 7, 8 } }
local VAC_DUR = { 0.12, 0.12, 0.12, 0.12, 0.1, 0.25, 0.3, 0.3 }
local ROLL, FLOW = { { "roll", 1, 4 } }, { { "flow", 1, 8 } }
local function seq(fn, n)
  local fr = {}
  for f = 0, n - 1 do fr[f + 1] = fn(f) end
  return fr
end

local opts = {}
opts.sign = {
  { "A", "A-FRAME", emit("wet_floor_sign_a", fromfile("wet_floor_sign_a")) },
  { "B", "TALL CONE", emit("wet_floor_sign_b", sign_b()) },
  { "C", "SLIP BOARD", emit("wet_floor_sign_c", sign_c()) },
  { "D", "BANANA", emit("wet_floor_sign_d", sign_d()) },
}
opts.vacuum = {
  { "A", "DISC", emit("robot_vacuum_a", vacset(VAC.a), VAC_TAGS, VAC_DUR) },
  { "B", "ROUND DOME", emit("robot_vacuum_b", vacset(VAC.b), VAC_TAGS, VAC_DUR) },
  { "C", "GOOGLY EYES", emit("robot_vacuum_c", vacset(VAC.c), VAC_TAGS, VAC_DUR) },
  { "D", "KNIFE TAPED ON", emit("robot_vacuum_d", vacset(VAC.d), VAC_TAGS, VAC_DUR) },
}
opts.cactus = {
  { "A", "SAGUARO", emit("cactus_a", fromfile("cactus_a")) },
  { "B", "TALL SAGUARO", emit("cactus_b", cactus_b()) },
  { "C", "BARREL", emit("cactus_c", cactus_c()) },
  { "D", "PRICKLY PEAR", emit("cactus_d", cactus_d()) },
  { "E", "SAD ONE", emit("cactus_e", cactus_e()) },
}
opts.fountain = {
  { "A", "TIERED", emit("fountain_a", seq(fountain_a, 8), FLOW, 0.1) },
  { "B", "FISH SPOUT", emit("fountain_b", seq(fountain_b, 8), FLOW, 0.1) },
  { "C", "WATER WALL", emit("fountain_c", seq(fountain_c, 8), FLOW, 0.1) },
  { "D", "LION HEAD", emit("fountain_d", seq(fountain_d, 8), FLOW, 0.1) },
}
opts.cart = {
  { "A", "HOUSEKEEPING", emit("housekeeping_cart_a", seq(cart_a, 4), ROLL, 0.12) },
  { "B", "LINEN HAMPER", emit("housekeeping_cart_b", seq(cart_b, 4), ROLL, 0.12) },
  { "C", "ROOM SERVICE", emit("housekeeping_cart_c", seq(cart_c, 4), ROLL, 0.12) },
  { "D", "BELL CART", emit("housekeeping_cart_d", seq(cart_d, 4), ROLL, 0.12) },
}
opts.desk = {
  { "A", "RECEPTION", emit("front_desk_a", fromfile("front_desk_a")) },
  { "B", "CURVED", emit("front_desk_b", desk_b()) },
  { "C", "MARBLE", emit("front_desk_c", desk_c()) },
  { "D", "BELL STAND", emit("front_desk_d", desk_d()) },
}
opts.door = {
  { "A", "SLIDING", emit("luggage_door_a", { sub(doorA, 0, 0, 64, 96), sub(doorA, 64, 0, 64, 96), sub(doorA, 128, 0, 64, 96) }, D3) },
  { "B", "SHUTTER", emit("luggage_door_b", { door_b(1), door_b(2), door_b(3) }, D3) },
  { "C", "SWING", emit("luggage_door_c", { door_c(1), door_c(2), door_c(3) }, D3) },
  { "D", "CAGE GATE", emit("luggage_door_d", { door_d(1), door_d(2), door_d(3) }, D3) },
}

local N = {
  palm = emit("new_potted_palm", new_palm()),
  armchair = emit("new_armchair", seat(40, TEAL, TEAL_D, TEAL_L, 1)),
  sofa = emit("new_sofa", seat(80, P.door, P.door_d, P.door_l, 3)),
  table_lamp = emit("new_side_table_lamp", new_table_lamp()),
  floor_lamp = emit("new_floor_lamp", new_floor_lamp()),
  pile = emit("new_luggage_pile", new_luggage_pile()),
  suitcase = emit("new_suitcase", new_suitcase()),
  tray = emit("new_room_service_tray", new_tray()),
  ice = emit("new_ice_machine", new_ice_machine()),
  vending = emit("new_vending_machine", new_vending()),
  elevator = emit("new_elevator", { new_elevator(1), new_elevator(2), new_elevator(3) }, D3),
  paint_a = emit("new_painting_a", new_painting_a()),
  paint_b = emit("new_painting_b", new_painting_b()),
  paint_c = emit("new_painting_c", new_painting_c()),
  clock = emit("new_wall_clock", new_clock()),
  exting = emit("new_fire_extinguisher", new_extinguisher()),
  bin = emit("new_ashtray_bin", new_bin()),
  umbrella = emit("new_umbrella_stand", new_umbrella_stand()),
  rope = emit("new_rope_stanchion", new_stanchion()),
  exit = emit("new_exit_sign", new_exit_sign()),
  chandelier = emit("new_chandelier", new_chandelier()),
  papers = emit("new_newspaper_stack", new_newspapers()),
  hanger = emit("new_dnd_hanger", new_dnd_hanger()),
}

------------------------------------------------------------------ review sheets
local tiles = Image { fromFile = H.ROOT .. "assets/tilesets/hotel_tileset.png" }
local player = H.load("player/player_idle.png")
local PW, S = 600, 4

local function scene(w, wallH, carpetH)
  local im = H.img(w, wallH + carpetH)
  for x = 0, w - 1, 32 do
    for y = wallH - 64, -32, -32 do H.blit(im, tiles, x, y, 0, 0, 32, 32) end
    H.blit(im, tiles, x, wallH - 32, 64, 0, 32, 32)
    H.blit(im, tiles, x, wallH, 96, 0, 32, 32)
    H.blit(im, tiles, x, wallH + 32, 128, 0, 32, 32)
  end
  return im
end

-- items: { img=, label=, lift= }. Labels alternate between two lines on the carpet.
local function row(wallH, title, items, o)
  o = o or {}
  local gap = o.gap or 8
  local im = scene(PW, wallH, 30)
  local x = 6
  H.blit(im, player, x, wallH - 64, 0, 0, 48, 64); x = x + 48 + gap
  if not o.nopkg then H.package(im, x, wallH, 0); x = x + 32 + gap end
  for i, it in ipairs(items) do
    local w = it.img.width
    H.blit(im, it.img, x, wallH - it.img.height - (it.lift or 0))
    H.tag(im, it.label, x + w // 2, wallH + 3 + ((i % 2 == 0) and 13 or 0), P.white, P.ui, "center")
    x = x + w + gap
  end
  if x > PW then print("WARN row too wide: " .. title .. " " .. x) end
  H.tag(im, title, 60, 3, P.yellow, P.ui)
  return im
end

local function sheet(name, rows)
  local h = 0
  for _, r in ipairs(rows) do h = h + r.height end
  local big = H.img(PW * S, h * S)
  local y = 0
  for _, r in ipairs(rows) do
    H.blit(big, r, 0, y * S, 0, 0, r.width, r.height, false, S)
    y = y + r.height
  end
  big:saveAs(REVIEW .. name .. ".png")
  print("saved " .. name .. " " .. big.width .. "x" .. big.height)
end

local function optrow(wallH, title, list, o)
  local items = {}
  for _, e in ipairs(list) do
    local frames = e[3]
    items[#items + 1] = { img = frames[1], label = e[1] .. " " .. e[2] }
    if o and o.ends then items[#items + 1] = { img = frames[#frames], label = e[1] .. " OPEN" } end
  end
  return row(wallH, title, items, o)
end

sheet("options_props_alternatives_1", {
  optrow(72, "WET FLOOR SIGN", opts.sign, { gap = 30 }),
  optrow(72, "ROBOT VACUUM", opts.vacuum, { gap = 30 }),
  optrow(72, "CACTUS", opts.cactus, { gap = 30 }),
  optrow(80, "FOUNTAIN", opts.fountain, { gap = 16 }),
})
sheet("options_props_alternatives_2", {
  optrow(80, "HOUSEKEEPING CART", opts.cart, { gap = 20 }),
  optrow(72, "FRONT DESK", opts.desk, { nopkg = true }),
  optrow(108, "LUGGAGE DOOR", opts.door, { nopkg = true, gap = 2, ends = true }),
})
sheet("options_props_new", {
  row(108, "NEW PROPS: TALL", {
    { img = N.palm[1], label = "POTTED PALM" }, { img = N.floor_lamp[1], label = "FLOOR LAMP" },
    { img = N.table_lamp[1], label = "TABLE LAMP" }, { img = N.ice[1], label = "ICE MACHINE" },
    { img = N.vending[1], label = "VENDING" }, { img = N.elevator[1], label = "ELEVATOR" },
    { img = N.elevator[3], label = "ELEVATOR OPEN" },
  }),
  row(72, "NEW PROPS: FLOOR", {
    { img = N.armchair[1], label = "ARMCHAIR" }, { img = N.sofa[1], label = "SOFA" },
    { img = N.pile[1], label = "LUGGAGE PILE" }, { img = N.suitcase[1], label = "SUITCASE" },
    { img = N.bin[1], label = "ASH BIN" }, { img = N.umbrella[1], label = "UMBRELLAS" },
    { img = N.rope[1], label = "ROPE POSTS" }, { img = N.exting[1], label = "EXTING." },
    { img = N.tray[1], label = "TRAY" }, { img = N.papers[1], label = "PAPERS" },
  }, { nopkg = true }),
  row(76, "NEW PROPS: WALL AND CEILING", {
    { img = N.paint_a[1], label = "PAINTING A", lift = 26 }, { img = N.paint_b[1], label = "PAINTING B", lift = 24 },
    { img = N.paint_c[1], label = "PAINTING C", lift = 26 }, { img = N.clock[1], label = "CLOCK", lift = 40 },
    { img = N.exit[1], label = "EXIT SIGN", lift = 58 }, { img = N.chandelier[1], label = "CHANDELIER", lift = 36 },
    { img = N.hanger[1], label = "DND HANGER", lift = 28 },
  }),
})

---- animations: frame strips with a changed-pixel row beneath each
local function diff(prev, cur)
  local o, n = H.img(cur.width, cur.height), 0
  local ur, ug, ub = pc.rgbaR(P.ui), pc.rgbaG(P.ui), pc.rgbaB(P.ui)
  local function m(v, u) return floor(v * 0.35 + u * 0.65) end
  for y = 0, cur.height - 1 do
    for x = 0, cur.width - 1 do
      local p, q = cur:getPixel(x, y), prev:getPixel(x, y)
      local pa, qa = pc.rgbaA(p), pc.rgbaA(q)
      if (pa > 0 or qa > 0) and p ~= q then
        o:drawPixel(x, y, MAG); n = n + 1
      elseif pa > 0 then
        o:drawPixel(x, y, pc.rgba(m(pc.rgbaR(p), ur), m(pc.rgbaG(p), ug), m(pc.rgbaB(p), ub), 255))
      end
    end
  end
  return o, n
end

-- segs: { { key=, title=, frames=, tags=, pitch=, first=, last= }, ... } laid left to
-- right on one hallway strip, with the difference strip under it unless nodiff.
local function animrow(segs, wallH, nodiff)
  local fh = 0
  for _, sg in ipairs(segs) do fh = math.max(fh, sg.frames[1].height) end
  local sc = scene(PW, wallH, 13)
  local df = H.img(PW, fh + 15, P.ui)
  H.blit(sc, player, 4, wallH - 64, 0, 0, 48, 64)
  H.text(df, "CHANGED", 6, 4, P.ui_ll); H.text(df, "VS PREV.", 6, 14, P.ui_ll); H.text(df, "FRAME", 6, 24, P.ui_ll)
  local x = 58
  for _, sg in ipairs(segs) do
    local prev = {}
    for _, tg in ipairs(sg.tags) do
      for i = tg[2], tg[3] do prev[i] = (i == tg[2]) and tg[3] or i - 1 end
    end
    local fw = sg.frames[1].width
    if sg.title then H.tag(sc, sg.title, x, 3, P.yellow, P.ui) end
    for i = sg.first or 1, sg.last or #sg.frames do
      H.blit(sc, sg.frames[i], x, wallH - sg.frames[i].height)
      H.tag(sc, tostring(i), x + fw // 2, wallH + 2, P.white, P.ui, "center")
      local d, n = diff(sg.frames[prev[i]], sg.frames[i])
      H.blit(df, d, x, 1 + fh - d.height)
      H.text(df, prev[i] .. ">" .. i .. ":" .. n, x + fw // 2, fh + 5, MAG, { align = "center" })
      print("DIFF " .. sg.key .. " " .. prev[i] .. ">" .. i .. " " .. n)
      x = x + sg.pitch
    end
    x = x + 10
  end
  if x - 10 > PW then print("WARN anim row too wide " .. segs[1].key .. " " .. x) end
  if nodiff then return { sc } end
  return { sc, df }
end

local function rows(...)
  local out = {}
  for _, list in ipairs({ ... }) do for _, r in ipairs(list) do out[#out + 1] = r end end
  return out
end

local function vseg(l) return { key = "vacuum_" .. l, title = "ROBOT VACUUM " .. l:upper() .. ": PATROL 1-4, BUMP 5-6, STUCK 7-8",
  frames = opts.vacuum[l:byte() - 96][3], tags = VAC_TAGS, pitch = l == "d" and 54 or 48 } end
sheet("options_props_animations_1", rows(animrow({ vseg("a") }, 68), animrow({ vseg("b") }, 68),
  animrow({ vseg("c") }, 68), animrow({ vseg("d") }, 68)))

local function cseg(l, pitch) return { key = "cart_" .. l, title = "CART " .. l:upper() .. ": ROLL 1-4",
  frames = opts.cart[l:byte() - 96][3], tags = ROLL, pitch = pitch } end
sheet("options_props_animations_2", rows(animrow({ cseg("a", 66), cseg("b", 52) }, 90),
  animrow({ cseg("c", 60), cseg("d", 60) }, 90)))

local function fseg(l, pitch, first, last)
  return { key = "fountain_" .. l, title = first == 1 and ("FOUNTAIN " .. l:upper() .. ": FLOW 1-8") or nil,
    frames = opts.fountain[l:byte() - 96][3], tags = FLOW, pitch = pitch, first = first, last = last }
end
sheet("options_props_animations_3", rows(animrow({ fseg("a", 102, 1, 4) }, 82), animrow({ fseg("a", 102, 5, 8) }, 68),
  animrow({ fseg("c", 67, 1, 8) }, 90)))
sheet("options_props_animations_4", rows(animrow({ fseg("b", 86, 1, 4) }, 82), animrow({ fseg("b", 86, 5, 8) }, 68),
  animrow({ fseg("d", 46, 1, 8) }, 82)))

local function dseg(key, title, frames) return { key = key, title = title, frames = frames, tags = { { "all", 1, 3 } }, pitch = 68 } end
sheet("options_props_animations_5", rows(
  animrow({ dseg("door_a", "DOOR A: CLOSED, HALF, OPEN", opts.door[1][3]), dseg("door_b", "DOOR B", opts.door[2][3]) }, 114, true),
  animrow({ dseg("door_c", "DOOR C", opts.door[3][3]), dseg("door_d", "DOOR D", opts.door[4][3]) }, 114, true),
  animrow({ dseg("elevator", "ELEVATOR: CLOSED, HALF, OPEN", N.elevator) }, 114, true)))

---- final contact sheet: first frame of every promoted file, labelled with its file name
local function ftagw(str)
  local w = 0
  for ch in str:gmatch(".") do w = w + (ch == "_" and 5 or H.textw(ch) + 1) end
  return w - 1
end
local function ftag(im, str, cx, y)
  local w = ftagw(str) + 6
  local x = cx - w // 2
  R(im, x + 1, y, w - 2, 11, P.ui); R(im, x, y + 1, w, 9, P.ui)
  x = x + 3
  for ch in str:gmatch(".") do
    if ch == "_" then
      R(im, x, y + 8, 4, 1, P.white); x = x + 5
    else
      H.text(im, ch, x, y + 2, P.white); x = x + H.textw(ch) + 1
    end
  end
end

local LIFT = { painting_a = 26, painting_b = 24, painting_c = 26, wall_clock = 40, exit_sign = 52, chandelier = "top", dnd_hanger = 28 }
local frows, cur, x = {}, {}, 60
for _, it in ipairs(FINAL) do
  local pitch = math.max(it.img.width + 8, 46)
  if x + pitch > PW - 44 then frows[#frows + 1] = cur; cur, x = {}, 60 end
  cur[#cur + 1] = { it = it, x = x + (pitch - it.img.width) // 2 }
  x = x + pitch
end
frows[#frows + 1] = cur

local sheets, acc, acch = {}, {}, 0
for _, list in ipairs(frows) do
  local wallH = 72
  for _, e in ipairs(list) do wallH = math.max(wallH, e.it.img.height + 10) end
  local im = scene(PW, wallH, 44)
  H.blit(im, player, 4, wallH - 64, 0, 0, 48, 64)
  for i, e in ipairs(list) do
    local img, lf = e.it.img, LIFT[e.it.name] or 0
    if lf == "top" then lf = wallH - img.height end
    H.blit(im, img, e.x, wallH - img.height - lf)
    ftag(im, e.it.name, e.x + img.width // 2, wallH + 3 + ((i - 1) % 3) * 13)
  end
  if acch + im.height > 600 then sheets[#sheets + 1] = acc; acc, acch = {}, 0 end
  acc[#acc + 1] = im; acch = acch + im.height
end
sheets[#sheets + 1] = acc
for i, list in ipairs(sheets) do sheet(#sheets == 1 and "final_props" or ("final_props_" .. i), list) end
