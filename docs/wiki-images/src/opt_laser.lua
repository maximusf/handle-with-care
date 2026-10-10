-- Laser interactable options A to E. Each option is a kit: emitter, receiver,
-- tileable beam, impact burst and warning sign.
-- Writes docs/art-options/laser/<code>_<piece>.{aseprite,png,json} and the
-- review sheets docs/art-review/options_laser.png and options_laser_2.png.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local OUT = H.ROOT .. "docs/art-options/laser/"
local REVIEW = H.ROOT .. "docs/art-review/"
for _, d in ipairs({ OUT, REVIEW }) do app.fs.makeAllDirectories(d) end

-- extra shades
local PALE = H.c("ffe1dc")
local RED_L = H.c("ff8a8c")
local RED_DD = H.c("8a1218")
local LED_OFF = H.c("5a1518")
local STEEL_L = H.c("b4b8bd")
local GOLD_L = H.c("ffe08a")
local GREEN_L = H.c("c8ffcc")
local GREEN_OFF = H.c("14401c")
local CYAN_L = H.c("b8ecff")
local CYAN_OFF = H.c("16405c")

------------------------------------------------------------------ helpers
local function flip(src)
  local t = H.img(src.width, src.height)
  H.blit(t, src, 0, 0, 0, 0, src.width, src.height, true)
  return t
end

-- Quarter turn clockwise: a unit facing right ends up facing down.
local function rot(src)
  local t = H.img(src.height, src.width)
  for y = 0, src.height - 1 do
    for x = 0, src.width - 1 do t:drawPixel(src.height - 1 - y, x, src:getPixel(x, y)) end
  end
  return t
end

local function disc(t, cx, cy, r, fill, line)
  local function inside(x, y) return x * x + y * y <= (r + 0.5) ^ 2 end
  for y = -r, r do
    for x = -r, r do
      if inside(x, y) then
        local edge = not (inside(x - 1, y) and inside(x + 1, y) and inside(x, y - 1) and inside(x, y + 1))
        H.px(t, cx + x, cy + y, edge and line or fill)
      end
    end
  end
end

-- frames: list of { img, tag, dur }; consecutive frames with one tag share it
local function export(name, frames)
  local w, h = frames[1][1].width, frames[1][1].height
  local spr = Sprite(w, h, ColorMode.RGB)
  spr.layers[1].name = "Art"
  for i, f in ipairs(frames) do
    if i > 1 then spr:newEmptyFrame(i) end
    spr:newCel(spr.layers[1], spr.frames[i], f[1], Point(0, 0))
    spr.frames[i].duration = f[3]
  end
  local i = 1
  while i <= #frames do
    local j = i
    while j < #frames and frames[j + 1][2] == frames[i][2] do j = j + 1 end
    local tag = spr:newTag(i, j)
    tag.name = frames[i][2]
    i = j + 1
  end
  spr:saveAs(OUT .. name .. ".aseprite")
  app.sprite = spr
  app.command.ExportSpriteSheet {
    ui = false, askOverwrite = false, type = SpriteSheetType.HORIZONTAL,
    textureFilename = OUT .. name .. ".png", dataFilename = OUT .. name .. ".json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY, listTags = true,
  }
  spr:close()
  print(name .. " " .. #frames .. " x " .. w .. "x" .. h)
  return frames
end

------------------------------------------------------------------ beam helpers
-- Everything is drawn modulo 32 px so a tile always meets its neighbour.
local function seg(t, x, y, w, h, c)
  for i = 0, w - 1 do for j = 0, h - 1 do t:drawPixel((x + i) % 32, y + j, c) end end
end
local function rows(t, y, cols)
  for i, c in ipairs(cols) do H.rect(t, 0, y + i - 1, 32, 1, c) end
end
local function dashes(t, y, h, c, on, period, off)
  for x = off, off + 31, period do seg(t, x, y, on, h, c) end
end

-- lines: list of { y, h, colour } cores. Solid, then dashes, then dots.
local function powerdown(lines, out)
  for f = 1, 3 do
    local t = H.img(32, 16)
    for _, l in ipairs(lines) do
      if f == 1 then H.rect(t, 0, l[1], 32, l[2], l[3])
      elseif f == 2 then dashes(t, l[1], l[2], l[3], 10, 16, 2)
      else dashes(t, l[1], l[2], l[3], 3, 16, 6) end
    end
    out[#out + 1] = { t, "powering_down", 0.08 }
  end
  return out
end

------------------------------------------------------------------ impact
local RAYS = { { 10, 10 }, { 60, 7 }, { 115, 12 }, { 170, 6 }, { 215, 11 }, { 265, 8 }, { 320, 9 } }
local SPAN = { { 0, 0.45 }, { 0.2, 1 }, { 0.6, 1.25 }, { 1.15, 1.35 } }

-- c = { core, mid, edge }; o.thick ray width, o.core burst radius, o.puff = { fill, line }
local function impact(c, o)
  o = o or {}
  local out = {}
  for f = 0, 3 do
    local t = H.img(32, 32)
    if o.puff then
      for i, a in ipairs({ 40, 160, 280 }) do
        local d, r = 3 + f * 3, ({ 2, 3, 3, 2 })[f + 1]
        local an = math.rad(a + f * 15)
        disc(t, math.floor(16 + math.cos(an) * d), math.floor(16 + math.sin(an) * d), r, o.puff[1], o.puff[2])
      end
    end
    for _, r in ipairs(RAYS) do
      local an, len = math.rad(r[1]), r[2] * (o.len or 1)
      local a0, a1 = len * SPAN[f + 1][1], math.min(len * SPAN[f + 1][2], 14)
      local function pt(d) return math.floor(16 + math.cos(an) * d + 0.5), math.floor(16 + math.sin(an) * d + 0.5) end
      local x0, y0 = pt(a0)
      local x1, y1 = pt(a1)
      H.line(t, x0, y0, x1, y1, f < 2 and c[2] or c[3], o.thick or 1)
      if f == 1 then
        local xm, ym = pt((a0 + a1) / 2)
        H.line(t, x0, y0, xm, ym, c[1], o.thick or 1)
      elseif f == 2 then
        H.px(t, x1, y1, c[1])
      end
    end
    local rad = ({ 3, o.core or 4, 1, -1 })[f + 1]
    for y = -rad, rad do
      for x = -rad, rad do
        if math.abs(x) + math.abs(y) <= rad then H.px(t, 16 + x, 16 + y, f == 2 and c[2] or c[1]) end
      end
    end
    if f < 2 then A.outline(t, c[3], false) end
    out[#out + 1] = { t, "impact", 0.06 }
  end
  return out
end

------------------------------------------------------------------ A: tripwire
-- Small grey box with a red lens; beacon only on the receiver.
local function A_unit(lens, core, led, beacon)
  local t = H.img(16, 16)
  if beacon then H.box(t, 5, 0, 6, 4, beacon, P.ink) end
  H.box(t, 0, 2, 3, 12, P.mat_nd, P.ink)
  H.box(t, 2, 3, 11, 10, P.mat_n, P.ink)
  H.rect(t, 3, 4, 9, 1, STEEL_L)
  H.rect(t, 3, 11, 9, 1, P.mat_nd)
  H.box(t, 12, 5, 4, 6, P.asphalt_d, P.ink)
  H.rect(t, 15, 6, 1, 4, lens)
  if core then H.rect(t, 15, 7, 1, 2, core); H.rect(t, 14, 7, 1, 2, lens) end
  H.box(t, 4, 6, 4, 4, led, P.ink)
  return t
end

local function kitA()
  local k = { code = "A", name = "SECURITY TRIPWIRE" }
  k.emitter = export("A_emitter", {
    { A_unit(LED_OFF, nil, P.asphalt), "off", 0.2 },
    { A_unit(P.red_d, nil, P.yellow), "warming", 0.2 },
    { A_unit(P.xred, PALE, P.mat_g), "on", 0.2 },
  })
  k.receiver = export("A_receiver", {
    { flip(A_unit(P.ink, nil, P.asphalt, LED_OFF)), "off", 0.2 },
    { flip(A_unit(P.xred, PALE, P.mat_g, LED_OFF)), "on", 0.2 },
    { flip(A_unit(P.ink, nil, P.xred, P.xred)), "tripped", 0.15 },
    { flip(A_unit(P.ink, nil, LED_OFF, PALE)), "tripped", 0.15 },
  })
  local b = {}
  for f = 0, 3 do
    local t = H.img(32, 16)
    rows(t, 5, { RED_DD, P.xred, PALE, PALE, P.xred, RED_DD })
    seg(t, f * 8, 7, 6, 2, P.white)
    seg(t, f * 8 + 1, 6, 4, 1, RED_L); seg(t, f * 8 + 1, 9, 4, 1, RED_L)
    b[#b + 1] = { t, "on", 0.08 }
  end
  k.beam = export("A_beam", powerdown({ { 7, 2, P.xred } }, b))
  k.impact = export("A_impact", impact({ P.white, P.xred, RED_DD }))
  local w = H.img(16, 16)
  for j = 0, 11 do
    local half = (j * 6 + 6) // 12
    H.rect(w, 8 - half - 1, 2 + j, half * 2 + 2, 1, P.yellow)
  end
  A.outline(w, P.ink, false)
  H.rect(w, 7, 5, 2, 5, P.ink); H.rect(w, 7, 11, 2, 2, P.ink)
  k.warning = export("A_warning", { { w, "sign", 1 } })
  return k
end

------------------------------------------------------------------ B: hotel alarm
-- Brass backplate and cream housing; the receiver carries a little bell.
local function B_unit(lens, core, lamp, bell)
  local t = H.img(16, 32)
  H.box(t, 0, 2, 3, 3, P.gold, P.ink); H.box(t, 0, 27, 3, 3, P.gold, P.ink)
  H.box(t, 0, 4, 4, 24, P.gold, P.ink)
  H.rect(t, 1, 5, 1, 22, GOLD_L)
  H.rect(t, 2, 6, 1, 20, P.gold_d)
  H.box(t, 3, 9, 10, 14, P.cream, P.ink)
  H.rect(t, 4, 21, 8, 1, P.tape)
  H.rect(t, 4, 11, 8, 1, P.gold); H.rect(t, 4, 20, 8, 1, P.gold)
  H.box(t, 12, 12, 4, 8, P.gold, P.ink)
  H.rect(t, 13, 18, 2, 1, P.gold_d); H.rect(t, 13, 13, 2, 1, GOLD_L)
  H.rect(t, 15, 14, 1, 4, lens)
  if core then H.rect(t, 15, 15, 1, 2, core) end
  H.box(t, 6, 13, 4, 6, lamp, P.gold_d)
  if bell then
    disc(t, 8, 5, 3, P.gold, P.ink)
    H.px(t, 7, 3, GOLD_L); H.px(t, 6, 4, GOLD_L)
    H.rect(t, 5, 8, 7, 1, P.ink)
    if bell == 1 then H.line(t, 2, 1, 3, 2, P.ink); H.line(t, 14, 1, 13, 2, P.ink); H.px(t, 8, 0, P.ink)
    elseif bell == 2 then H.line(t, 1, 4, 3, 4, P.ink); H.line(t, 13, 4, 15, 4, P.ink) end
  end
  return t
end

local function kitB()
  local k = { code = "B", name = "HOTEL ALARM" }
  k.emitter = export("B_emitter", {
    { B_unit(P.base_d, nil, P.base_d), "off", 0.2 },
    { B_unit(P.orange, nil, P.orange), "warming", 0.2 },
    { B_unit(P.xred, PALE, P.xred), "on", 0.2 },
  })
  k.receiver = export("B_receiver", {
    { flip(B_unit(P.base_d, nil, P.base_d, 0)), "off", 0.2 },
    { flip(B_unit(P.xred, PALE, P.mat_g, 0)), "on", 0.2 },
    { flip(B_unit(P.base_d, nil, P.xred, 1)), "tripped", 0.12 },
    { flip(B_unit(P.base_d, nil, PALE, 2)), "tripped", 0.12 },
  })
  local b = {}
  local motes = { { 5, 4 }, { 13, 11 }, { 22, 3 }, { 29, 12 } }
  for f = 0, 3 do -- marching dashes with dust motes drifting the other way
    local t = H.img(32, 16)
    dashes(t, 7, 2, P.xred, 4, 8, f * 2)
    dashes(t, 7, 2, PALE, 1, 8, f * 2 + 3)
    for i, m in ipairs(motes) do seg(t, m[1] - f * (i % 2 + 1), m[2], 1, 1, P.cream) end
    b[#b + 1] = { t, "on", 0.1 }
  end
  for f = 0, 1 do -- alarm: the whole line shows
    local t = H.img(32, 16)
    rows(t, 6, f == 0 and { P.red_d, P.xred, P.xred, P.red_d } or { P.xred, PALE, PALE, P.xred })
    b[#b + 1] = { t, "tripped", 0.12 }
  end
  k.beam = export("B_beam", powerdown({ { 7, 2, P.red_d } }, b))
  k.impact = export("B_impact", impact({ P.white, P.gold, P.gold_d }, { puff = { P.cream, P.wall_d }, len = 0.8 }))
  local w = H.img(16, 16)
  H.box(w, 1, 3, 14, 10, P.gold, P.ink)
  H.rect(w, 2, 4, 12, 1, GOLD_L); H.rect(w, 2, 11, 12, 1, P.gold_d)
  disc(w, 5, 8, 2, P.xred, P.base_d)
  H.rect(w, 9, 6, 4, 1, P.base_d); H.rect(w, 9, 8, 4, 1, P.base_d); H.rect(w, 9, 10, 3, 1, P.base_d)
  k.warning = export("B_warning", { { w, "sign", 1 } })
  return k
end

------------------------------------------------------------------ C: cartoon hazard
local function C_unit(face, core, lamp, hi)
  local t = H.img(32, 32)
  H.box(t, 0, 2, 5, 28, P.mat_nd, P.ink)
  H.box(t, 4, 4, 20, 24, P.mat_n, P.ink)
  for y = 5, 26 do
    if y <= 9 or y >= 22 then
      for x = 5, 22 do H.px(t, x, y, ((x + y) // 3) % 2 == 0 and P.ink or P.yellow) end
    end
  end
  H.rect(t, 5, 10, 18, 1, P.ink); H.rect(t, 5, 21, 18, 1, P.ink)
  H.rect(t, 5, 11, 18, 1, STEEL_L)
  H.box(t, 9, 12, 10, 8, lamp, P.ink)
  if hi then H.rect(t, 10, 13, 3, 1, hi); H.px(t, 10, 14, hi) end
  H.box(t, 23, 9, 6, 14, P.asphalt, P.ink)
  H.rect(t, 24, 10, 4, 1, P.gray)
  H.box(t, 28, 11, 4, 10, P.mat_nd, P.ink)
  H.rect(t, 31, 12, 1, 8, face)
  if core then H.rect(t, 31, 14, 1, 4, core); H.rect(t, 29, 14, 2, 4, face) end
  return t
end

local function kitC()
  local k = { code = "C", name = "CARTOON HAZARD" }
  k.emitter = export("C_emitter", {
    { C_unit(P.ink, nil, LED_OFF), "off", 0.2 },
    { C_unit(P.orange, nil, P.orange, P.yellow), "warming", 0.2 },
    { C_unit(P.xred, P.white, P.xred, RED_L), "on", 0.2 },
  })
  k.receiver = export("C_receiver", {
    { flip(C_unit(P.ink, nil, GREEN_OFF)), "off", 0.2 },
    { flip(C_unit(P.xred, P.white, P.mat_g, GREEN_L)), "on", 0.2 },
    { flip(C_unit(P.ink, nil, P.xred, RED_L)), "tripped", 0.12 },
    { flip(C_unit(P.ink, nil, P.white, RED_L)), "tripped", 0.12 },
  })
  local b = {}
  for f = 0, 3 do -- glow bumps crawl along both edges
    local t = H.img(32, 16)
    rows(t, 4, { P.red_d, P.xred, P.yellow, P.white, P.white, P.yellow, P.xred, P.red_d })
    for x = 0, 16, 16 do
      seg(t, x + f * 4, 3, 6, 1, P.red_d); seg(t, x + f * 4 + 1, 4, 4, 1, P.xred)
      seg(t, x + 8 + f * 4, 12, 6, 1, P.red_d); seg(t, x + 9 + f * 4, 11, 4, 1, P.xred)
      seg(t, x + f * 4 + 8, 6, 5, 1, P.white); seg(t, x + f * 4, 9, 5, 1, P.white)
    end
    b[#b + 1] = { t, "on", 0.08 }
  end
  local t = H.img(32, 16) -- first shrink step keeps the white core
  rows(t, 6, { P.xred, P.white, P.white, P.xred })
  b[#b + 1] = { t, "powering_down", 0.08 }
  local pd = powerdown({ { 7, 2, P.xred } }, {})
  b[#b + 1] = pd[2]; b[#b + 1] = pd[3]
  k.beam = export("C_beam", b)
  k.impact = export("C_impact", impact({ P.white, P.yellow, P.xred }, { thick = 2, core = 6, len = 1.15 }))
  local w = H.img(16, 16)
  for y = 0, 15 do
    for x = 0, 15 do
      if math.abs(x - 7.5) + math.abs(y - 7.5) <= 6.5 then w:drawPixel(x, y, P.yellow) end
    end
  end
  A.outline(w, P.ink, false)
  H.rect(w, 4, 7, 8, 2, P.ink); H.rect(w, 7, 4, 2, 8, P.ink)
  H.px(w, 5, 5, P.ink); H.px(w, 10, 5, P.ink); H.px(w, 5, 10, P.ink); H.px(w, 10, 10, P.ink)
  H.rect(w, 7, 7, 2, 2, P.xred)
  k.warning = export("C_warning", { { w, "sign", 1 } })
  return k
end

------------------------------------------------------------------ D: timed pulse
-- Dark unit with a four-cell charge meter that fills before each burst.
local function D_unit(pips, pipc, lens, core)
  local t = H.img(16, 32)
  H.box(t, 0, 2, 12, 28, P.ui_l, P.ink)
  H.rect(t, 1, 3, 10, 1, P.ui_ll)
  for i, y in ipairs({ 21, 16, 10, 5 }) do
    H.box(t, 2, y, 6, 6, i <= pips and pipc or P.ui, P.ink)
    if i <= pips then H.px(t, 3, y + 1, P.white) end
  end
  H.rect(t, 9, 6, 1, 20, P.ui_ll)
  H.box(t, 11, 11, 5, 10, P.mat_n, P.ink)
  H.rect(t, 12, 12, 3, 1, STEEL_L)
  H.rect(t, 15, 13, 1, 6, lens)
  if core then H.rect(t, 15, 15, 1, 2, core); H.rect(t, 13, 15, 2, 2, lens) end
  return t
end

local function kitD()
  local k = { code = "D", name = "TIMED PULSE" }
  local e = { { D_unit(0, P.blue, CYAN_OFF), "off", 0.4 } }
  for i = 1, 4 do e[#e + 1] = { D_unit(i, i == 4 and P.white or P.yellow, i == 4 and P.blue or CYAN_OFF), "warming", 0.25 } end
  e[#e + 1] = { D_unit(4, P.blue, P.blue, P.white), "on", 0.8 }
  k.emitter = export("D_emitter", e)
  k.receiver = export("D_receiver", {
    { flip(D_unit(0, P.blue, CYAN_OFF)), "off", 0.2 },
    { flip(D_unit(4, P.blue, P.blue, P.white)), "on", 0.2 },
    { flip(D_unit(4, P.xred, CYAN_OFF)), "tripped", 0.12 },
    { flip(D_unit(4, PALE, CYAN_OFF)), "tripped", 0.12 },
  })
  local b = {}
  for f = 0, 1 do -- faint guide dots while the meter fills
    local t = H.img(32, 16)
    dashes(t, 7, 2, f == 0 and P.water_d or CYAN_L, 2, 8, f * 4)
    b[#b + 1] = { t, "pre_fire", 0.12 }
  end
  for f = 0, 3 do -- fat nodes travelling along the beam
    local t = H.img(32, 16)
    rows(t, 5, { P.water_d, P.blue, P.white, P.white, P.blue, P.water_d })
    for x = 0, 16, 16 do
      seg(t, x + f * 4, 4, 6, 1, P.water_d); seg(t, x + f * 4, 11, 6, 1, P.water_d)
      seg(t, x + f * 4, 5, 6, 1, P.blue); seg(t, x + f * 4, 10, 6, 1, P.blue)
      seg(t, x + f * 4 + 1, 6, 4, 1, CYAN_L); seg(t, x + f * 4 + 1, 9, 4, 1, CYAN_L)
    end
    b[#b + 1] = { t, "on", 0.08 }
  end
  k.beam = export("D_beam", powerdown({ { 7, 2, P.blue } }, b))
  k.beam_on = 3
  k.impact = export("D_impact", impact({ P.white, P.blue, P.water_d }))
  local w = H.img(16, 16)
  disc(w, 8, 8, 6, P.white, P.ink)
  for y = 3, 7 do for x = 8, 12 do if (x - 8) ^ 2 + (y - 8) ^ 2 <= 25 then w:drawPixel(x, y, P.blue) end end end
  H.rect(w, 8, 3, 1, 6, P.ink); H.rect(w, 8, 8, 5, 1, P.ink)
  H.rect(w, 7, 0, 3, 2, P.ink)
  k.warning = export("D_warning", { { w, "sign", 1 } })
  return k
end

------------------------------------------------------------------ E: green heist grid
-- Slim black strip with three lenses; three thin green beams per tile.
local EY = { 1, 6, 11 }
local function E_unit(cols)
  local t = H.img(16, 16)
  H.box(t, 0, 0, 10, 16, P.asphalt_d, P.ink)
  H.rect(t, 1, 1, 1, 14, P.gray)
  for i, y in ipairs(EY) do
    H.box(t, 9, y, 7, 4, P.asphalt, P.ink)
    H.rect(t, 15, y + 1, 1, 2, cols[i])
    H.rect(t, 4, y + 1, 2, 2, cols[i])
  end
  return t
end

local function kitE()
  local k = { code = "E", name = "GREEN HEIST GRID" }
  local off = { GREEN_OFF, GREEN_OFF, GREEN_OFF }
  local on = { P.mat_g, P.mat_g, P.mat_g }
  k.emitter = export("E_emitter", {
    { E_unit(off), "off", 0.2 },
    { E_unit({ GREEN_OFF, P.yellow, GREEN_OFF }), "warming", 0.15 },
    { E_unit({ P.yellow, GREEN_OFF, P.yellow }), "warming", 0.15 },
    { E_unit(on), "on", 0.2 },
  })
  k.receiver = export("E_receiver", {
    { flip(E_unit(off)), "off", 0.2 },
    { flip(E_unit(on)), "on", 0.2 },
    { flip(E_unit({ P.xred, P.xred, P.xred })), "tripped", 0.12 },
    { flip(E_unit({ LED_OFF, PALE, LED_OFF })), "tripped", 0.12 },
  })
  local b = {}
  for f = 0, 3 do
    local t = H.img(32, 16)
    for i, y in ipairs(EY) do
      rows(t, y, { P.mat_gd, P.mat_g, P.mat_g, P.mat_gd })
      seg(t, f * 8 + i * 11, y + 1, 6, 2, GREEN_L)
      seg(t, f * 8 + i * 11 + 2, y + 1, 2, 2, P.white)
    end
    b[#b + 1] = { t, "on", 0.08 }
  end
  k.beam = export("E_beam", powerdown({ { 2, 2, P.mat_g }, { 7, 2, P.mat_g }, { 12, 2, P.mat_g } }, b))
  k.impact = export("E_impact", impact({ P.white, P.mat_g, P.mat_gd }))
  local w = H.img(16, 16)
  H.box(w, 1, 1, 14, 14, P.ui, P.ink)
  H.rect(w, 2, 2, 12, 1, P.ui_ll)
  for _, y in ipairs({ 4, 7, 10 }) do H.rect(w, 3, y, 10, 1, P.mat_g) end
  H.box(w, 6, 5, 5, 5, P.xred, P.ink)
  H.px(w, 7, 6, PALE)
  k.warning = export("E_warning", { { w, "sign", 1 } })
  return k
end

local kits = { kitA(), kitB(), kitC(), kitD(), kitE() }

------------------------------------------------------------------ review sheets
local tiles = Image { fromFile = H.ROOT .. "assets/tilesets/hotel_tileset.png" }
local lever = Image { fromFile = H.SPR .. "interactables/lever.png" }
local switch = Image { fromFile = H.SPR .. "interactables/wall_switch.png" }
local plate = Image { fromFile = H.SPR .. "interactables/pressure_plate.png" }
local FW, SW, BH = 316, 288, 132 -- frames panel, scene panel, block height

local function room(w)
  local sc = H.img(w, 128)
  for x = 0, w - 1, 32 do
    H.blit(sc, tiles, x, 0, 0, 0, 32, 32)
    H.blit(sc, tiles, x, 32, 0, 0, 32, 32)
    H.blit(sc, tiles, x, 64, 64, 0, 32, 32)
    H.blit(sc, tiles, x, 96, 96, 0, 32, 32)
  end
  return sc
end

local function pillar(sc, x)
  H.box(sc, x, 0, 8, 96, P.base, P.ink)
  H.rect(sc, x + 1, 0, 1, 96, H.c("84523a"))
end

local function scene(k, idx)
  local sc = room(SW)
  local BY, ex = 50, 84
  local on = k.emitter[#k.emitter][1]
  local ew, eh = on.width, on.height
  H.player(sc, 2, 96, 0, 2)
  if idx % 3 == 1 then H.blit(sc, lever, 46, 22, 64, 0, 32, 32)
  elseif idx % 3 == 2 then H.blit(sc, switch, 46, 22, 0, 0, 32, 32)
  else H.blit(sc, plate, 46, 80, 0, 0, 32, 16) end
  pillar(sc, ex - 8); pillar(sc, ex + ew * 2 + 128)
  H.blit(sc, on, ex, BY - eh // 2)
  local bf = k.beam[k.beam_on or 1][1]
  for i = 0, 3 do H.blit(sc, bf, ex + ew + i * 32, BY - 8) end
  H.blit(sc, k.receiver[2][1], ex + ew + 128, BY - eh // 2)
  H.blit(sc, k.warning[1][1], ex + ew + 4, BY - 36)
  local px = ex + ew + 56
  H.package(sc, px, BY + 4, 0)
  H.blit(sc, k.impact[2][1], px, BY - 16)
  return sc
end

local function strip(pv, frames, x, y)
  for _, f in ipairs(frames) do
    local w, h = f[1].width, f[1].height
    H.box(pv, x - 1, y - 1, w + 2, h + 2, P.wall_d, P.base)
    H.blit(pv, f[1], x, y)
    x = x + w + 2
  end
  return x + 4
end

local function block(pv, k, idx, y0)
  H.rect(pv, 0, y0, FW + SW, BH, P.wall)
  for x = 0, FW - 1, 16 do H.rect(pv, x, y0, 8, BH, P.wall_l) end
  H.tag(pv, k.code .. " " .. k.name, 4, y0 + 3)
  local x = strip(pv, k.emitter, 5, y0 + 18)
  x = strip(pv, k.receiver, x, y0 + 18)
  strip(pv, k.warning, x, y0 + 18)
  strip(pv, k.beam, 5, y0 + 55)
  x = strip(pv, k.impact, 5, y0 + 77)
  -- two joined tiles over carpet and over wainscot: seam and contrast check
  local bf = k.beam[k.beam_on or 1][1]
  H.blit(pv, tiles, x + 4, y0 + 77, 96, 0, 32, 16); H.blit(pv, tiles, x + 36, y0 + 77, 96, 0, 32, 16)
  H.blit(pv, tiles, x + 4, y0 + 95, 64, 4, 32, 16); H.blit(pv, tiles, x + 36, y0 + 95, 64, 4, 32, 16)
  for i = 0, 1 do
    H.blit(pv, bf, x + 4 + i * 32, y0 + 77)
    H.blit(pv, bf, x + 4 + i * 32, y0 + 95)
  end
  H.blit(pv, scene(k, idx), FW, y0 + 2)
  H.rect(pv, 0, y0 + BH - 2, FW + SW, 2, P.ui)
end

-- vertical installs: every kit turned a quarter turn, ceiling to floor
local function vertical()
  local sc = room(FW + SW)
  for x = 0, sc.width - 1, 32 do H.blit(sc, tiles, x, 0, 32, 0, 32, 32) end
  H.tag(sc, "VERTICAL INSTALLS (ROTATED 90)", 4, 112)
  for i, k in ipairs(kits) do
    local cx = 40 + (i - 1) * 84
    local e, r = rot(k.emitter[#k.emitter][1]), rot(k.receiver[2][1])
    local b = rot(k.beam[k.beam_on or 1][1])
    H.blit(sc, e, cx - e.width // 2, 0)
    for y = e.height, 96 - r.height - 1, 32 do H.blit(sc, b, cx - 8, y) end
    H.blit(sc, r, cx - r.width // 2, 96 - r.height)
    H.blit(sc, k.warning[1][1], cx + 18, 40)
    H.tag(sc, k.code, cx - 30, 70)
  end
  H.player(sc, 440, 96, 0, 2)
  H.blit(sc, plate, 500, 80, 0, 0, 32, 16)
  H.package(sc, 536, 96, 0)
  return sc
end

local function sheet(name, list, first, extra)
  local n = #list + (extra and 1 or 0)
  local pv = H.img(FW + SW, n * BH, P.ui)
  for i, k in ipairs(list) do block(pv, k, first + i - 1, (i - 1) * BH) end
  if extra then H.blit(pv, extra, 0, #list * BH + 2) end
  local S = 4
  local big = H.img(pv.width * S, pv.height * S)
  for y = 0, pv.height - 1 do
    for x = 0, pv.width - 1 do big:clear(Rectangle(x * S, y * S, S, S), pv:getPixel(x, y)) end
  end
  big:saveAs(REVIEW .. name .. ".png")
  print("saved " .. name .. " " .. big.width .. "x" .. big.height)
end

sheet("options_laser", { kits[1], kits[2], kits[3] }, 1)
sheet("options_laser_2", { kits[4], kits[5] }, 4, vertical())
