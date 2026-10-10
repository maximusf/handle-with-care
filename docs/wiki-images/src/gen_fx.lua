-- Gameplay feedback effects: kick impact, cardboard debris, dust puff,
-- puddle splash and guest reaction bubbles.
-- Writes assets/sprites/fx/* as .aseprite, a horizontal .png strip and a
-- .json, plus docs/art-review/fx_preview.png (every frame at 6x).
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local FX = H.SPR .. "fx/"
local REVIEW = H.ROOT .. "docs/art-review/"

local DUST, DUST_D = H.c("e6dcc8"), H.c("b4a68c")
local PINK = H.c("ff8a8c")

local assets = {} -- kept for the preview

-- frames: list of images. tags: list of { name, from, to } (1-based), dur in seconds.
local function export(name, w, h, frames, tags, dur)
  local spr = Sprite(w, h, ColorMode.RGB)
  spr.layers[1].name = "Art"
  for i, f in ipairs(frames) do
    if i > 1 then spr:newEmptyFrame(i) end
    spr:newCel(spr.layers[1], spr.frames[i], f, Point(0, 0))
    spr.frames[i].duration = dur
  end
  for _, t in ipairs(tags) do
    local tag = spr:newTag(t[2], t[3])
    tag.name = t[1]
  end
  spr:saveAs(FX .. name .. ".aseprite")
  app.sprite = spr
  app.command.ExportSpriteSheet {
    ui = false, askOverwrite = false, type = SpriteSheetType.HORIZONTAL,
    textureFilename = FX .. name .. ".png", dataFilename = FX .. name .. ".json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY, listTags = true,
  }
  spr:close()
  assets[#assets + 1] = { name = name, w = w, h = h, frames = frames }
  print(name .. " " .. #frames .. " frames " .. w .. "x" .. h)
end

local function round(v) return math.floor(v + 0.5) end

-- Filled circle of radius r + 0.5.
local function disc(t, cx, cy, r, c)
  for y = -r, r do
    for x = -r, r do
      if x * x + y * y <= (r + 0.5) ^ 2 then H.px(t, cx + x, cy + y, c) end
    end
  end
end

local function bmp(t, x, y, rows, pal)
  for j, r in ipairs(rows) do
    for i = 1, #r do
      local c = pal[r:sub(i, i)]
      if c then H.px(t, x + i - 1, y + j - 1, c) end
    end
  end
end

------------------------------------------------------------------ kick impact
-- Starburst centred on the frame: place it where the foot meets the package.
local function impact(core, r0, r1, thick, dots)
  local t = H.img(32, 32)
  local cx, cy = 15.5, 15.5
  for i = 0, 7 do
    local a = i * math.pi / 4 + 0.25
    local k = (i % 2 == 0) and 1 or 0.7 -- alternate long and short spikes
    local ca, sa = math.cos(a), math.sin(a)
    if dots then
      H.rect(t, round(cx + ca * r1 * k), round(cy + sa * r1 * k), 1, 1, P.yellow)
    else
      H.line(t, round(cx + ca * r0), round(cy + sa * r0), round(cx + ca * r1 * k), round(cy + sa * r1 * k),
        i % 2 == 0 and P.white or P.yellow, thick)
    end
  end
  if core > 0 then
    disc(t, 15, 15, core, P.yellow)
    disc(t, 15, 15, core - 1, P.white)
  end
  if not dots then A.outline(t, P.ink, false) end
  return t
end

export("kick_impact", 32, 32, {
  impact(3, 2, 7, 2),
  impact(2, 5, 12, 2),
  impact(0, 9, 14, 1),
  impact(0, 0, 14, 1, true),
}, { { "hit", 1, 4 } }, 0.05)

------------------------------------------------------------------ cardboard debris
-- Chips of cardboard thrown up and out, then falling. Origin is the frame centre.
local CHIPS = {
  { -2.6, -3.4, 4, 3, P.card }, { 2.4, -3.8, 3, 4, P.card_m }, { -1.0, -4.8, 3, 3, P.tape },
  { 1.2, -2.4, 4, 3, P.card_d }, { -3.6, -1.4, 3, 3, P.card_m }, { 3.6, -1.8, 3, 3, P.card },
}
local function debris(f)
  local t = H.img(32, 32)
  for _, c in ipairs(CHIPS) do
    local u = (f + 1) * 0.85 -- the first frame already shows the chips apart
    local x = 14 + c[1] * u
    local y = 17 + c[2] * u + 0.75 * u * u
    local w, h = c[3], c[4]
    if f >= 4 then w, h = 1, 1 elseif f == 3 then w, h = math.max(1, w - 1), math.max(1, h - 1) end
    H.rect(t, round(x), round(y), w, h, c[5])
  end
  if f < 4 then A.outline(t, P.ink, false) end
  return t
end

local df = {}
for f = 0, 4 do df[f + 1] = debris(f) end
export("cardboard_debris", 32, 32, df, { { "burst", 1, 5 } }, 0.07)

------------------------------------------------------------------ dust puff
-- Two puffs rolling out along the floor. The bottom row of the frame is the floor line.
local function dust(f)
  local t = H.img(32, 16)
  local radii = { 2, 3, 4, 3, 2 }
  local r = radii[f + 1]
  for side = -1, 1, 2 do
    local cx = 15 + side * (3 + f * 2.4)
    disc(t, round(cx), 15 - r, r, DUST)
    if f >= 1 and f <= 3 then disc(t, round(cx - side * (r + 1)), 15 - r + 2, r - 1, DUST) end
    if f == 4 then H.px(t, round(cx + side * 3), 10, DUST) end
  end
  if f < 4 then A.outline(t, DUST_D, false) end
  return t
end

local pf = {}
for f = 0, 4 do pf[f + 1] = dust(f) end
export("dust_puff", 32, 16, pf, { { "puff", 1, 5 } }, 0.07)

------------------------------------------------------------------ puddle splash
-- Crown of droplets. The bottom row of the frame is the water surface.
local DROPS = {
  { -4.4, -5.4 }, { -2.2, -7.0 }, { 0, -7.6 }, { 2.2, -7.0 }, { 4.4, -5.4 },
}
local function splash(f)
  local t = H.img(48, 32)
  if f == 0 then
    -- first contact: short column
    H.rect(t, 21, 24, 6, 7, P.water)
    H.rect(t, 22, 22, 4, 2, P.water)
    H.rect(t, 23, 24, 1, 5, P.water_l)
  else
    for _, d in ipairs(DROPS) do
      local x = 23 + d[1] * f * 1.25
      local y = 28 + d[2] * f + 1.1 * f * f
      if y < 30 then
        local sz = f >= 4 and 1 or 2
        H.rect(t, round(x), round(y), sz, sz, P.water)
        if sz == 2 then H.px(t, round(x), round(y), P.water_l) end
      end
    end
    -- ripple spreading on the surface
    local half = 5 + f * 4
    H.rect(t, 24 - half, 30, half * 2, 1, P.water)
    H.rect(t, 24 - half + 2, 30, 3, 1, P.water_l)
    H.rect(t, 24 + half - 6, 30, 3, 1, P.water_l)
    if f <= 2 then H.rect(t, 24 - 3, 29 - (3 - f), 6, 3 - f, P.water) end
  end
  A.outline(t, P.water_d, false)
  return t
end

local sf = {}
for f = 0, 4 do sf[f + 1] = splash(f) end
export("puddle_splash", 48, 32, sf, { { "splash", 1, 5 } }, 0.07)

------------------------------------------------------------------ guest reaction bubbles
-- Speech bubble with a tail at the bottom left, one frame per reaction.
local SYM = {
  exclaim = { pal = { r = P.xred }, rows = { ".rr.", ".rr.", ".rr.", ".rr.", "....", ".rr." } },
  question = { pal = { b = P.water_d }, rows = { ".bbb.", "b...b", "...b.", "..b..", ".....", "..b.." } },
  heart = { pal = { r = P.xred, p = PINK }, rows = { ".rr.rr.", "rprrrrr", "rrrrrrr", ".rrrrr.", "..rrr..", "...r..." } },
  anger = { pal = { r = P.xred }, rows = { ".r...r.", "rr...rr", ".......", ".......", "rr...rr", ".r...r." } },
}
local function bubble(kind)
  local t = H.img(16, 16)
  H.rect(t, 2, 1, 12, 10, P.white)
  H.rect(t, 1, 2, 14, 8, P.white)
  bmp(t, 3, 11, { "###", "##.", "#.." }, { ["#"] = P.white }) -- tail
  A.outline(t, P.ink, false)
  local s = SYM[kind]
  bmp(t, 8 - (#s.rows[1] + 1) // 2 + (#s.rows[1] % 2 == 0 and 1 or 0), 3, s.rows, s.pal)
  return t
end

local order = { "exclaim", "question", "heart", "anger" }
local bf, bt = {}, {}
for i, k in ipairs(order) do bf[i] = bubble(k); bt[i] = { k, i, i } end
export("reaction_bubble", 16, 16, bf, bt, 0.1)

------------------------------------------------------------------ review sheet
local S = 6
local PW = 5 * 52 + 8
local pv = H.img(PW, #assets * 44 + 4, P.wall)
for x = 0, PW - 1, 16 do H.rect(pv, x, 0, 8, pv.height, P.wall_l) end
H.rect(pv, PW // 2, 0, PW - PW // 2, pv.height, P.carpet)
for i, a in ipairs(assets) do
  local y = (i - 1) * 44 + 6
  local x = 4
  for _, f in ipairs(a.frames) do
    H.blit(pv, f, x, y + (32 - a.h))
    x = x + a.w + 4
  end
end
local big = H.img(pv.width * S, pv.height * S)
for y = 0, pv.height - 1 do
  for x = 0, pv.width - 1 do big:clear(Rectangle(x * S, y * S, S, S), pv:getPixel(x, y)) end
end
big:saveAs(REVIEW .. "fx_preview.png")
print("saved fx_preview " .. big.width .. "x" .. big.height)
