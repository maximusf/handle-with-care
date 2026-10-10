-- YEET truck and dolly OPTIONS, round 2: the kept white step van (B) and
-- silver dolly (B), each in a run of wear levels from clean to rough.
-- Writes 1x .aseprite + .png into docs/art-options/trucks/ and 3x review
-- sheets into docs/art-review/.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/yeet_brand.lua")
local P, YP = H.P, Y.P
local pc = app.pixelColor
local OUT = H.ROOT .. "docs/art-options/trucks/"
local REVIEW = H.ROOT .. "docs/art-review/"
local TMP = os.getenv("HWC_TMP") -- optional folder for a 1x check sheet
local W, HT = 192, 96

------------------------------------------------------------------ helpers
local function stamp(im, x, y, rows, map)
  for j, r in ipairs(rows) do
    for i = 1, #r do
      local c = map[r:sub(i, i)]
      if c then H.px(im, x + i - 1, y + j - 1, c) end
    end
  end
end

-- Draw flat fills on a scratch layer, then wrap them in a 1px ink outline.
local function part(fn, w, h)
  local t = H.img(w or W, h or HT)
  fn(t)
  A.outline(t, P.ink, false)
  return t
end

local function over(im, src) H.blit(im, src, 0, 0) end

local function opaque(im, x, y)
  return x >= 0 and y >= 0 and x < im.width and y < im.height and pc.rgbaA(im:getPixel(x, y)) > 0
end

local function set(...)
  local s = {}
  for _, c in ipairs({ ... }) do s[c] = true end
  return s
end

-- Paint a pixel only where the current colour is in `allow`, so wear never
-- lands on the brand graphics, glass or outlines.
local function on(im, x, y, c, allow)
  if x >= 0 and y >= 0 and x < im.width and y < im.height and allow[im:getPixel(x, y)] then
    im:drawPixel(x, y, c)
  end
end

local function fillOn(im, x, y, w, h, c, allow)
  for j = y, y + h - 1 do for i = x, x + w - 1 do on(im, i, j, c, allow) end end
end

local function saveRaw(im, name)
  local spr = Sprite(im.width, im.height, ColorMode.RGB)
  spr.cels[1].image = im
  spr.layers[1].name = "Art"
  spr:saveAs(OUT .. name .. ".aseprite")
  spr:saveCopyAs(OUT .. name .. ".png")
  spr:close()
  print("saved " .. name .. " " .. im.width .. "x" .. im.height)
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

------------------------------------------------------------------ palette
-- Wear colours are kept away from the brand orange and black.
local C = {
  dull1 = H.c("ebe7dc"), dull2 = H.c("e2dccb"), newpanel = H.c("eef4fa"),
  dust = H.c("cfc3a6"), dust_d = H.c("ad9c7c"), mud = H.c("8a7355"), mud_d = H.c("5f4e39"),
  rust = H.c("9a4a24"), rust_d = H.c("5e2c14"), primer = H.c("8a8f96"),
  soot = H.c("3c3a3c"), soot_l = H.c("77726c"),
  fade_o = H.c("f7a57e"), fade_k = H.c("7b7b80"),
  tape = H.c("b9bcc2"), tape_d = H.c("8d9097"),
}

local function livery(body)
  return { body = body or YP.white, hi = body and YP.white or P.white, lo = P.tile_d, seam = YP.gray,
    word = YP.black, wacc = YP.orange, stripe = YP.orange, stripe2 = YP.orange_d,
    mono = YP.black, macc = YP.orange, tag = YP.gray }
end

------------------------------------------------------------------ shared parts
-- Round disc without the single-pixel nubs H.ellipse leaves at the poles.
local function disc(im, cx, cy, r, fill, line)
  for dy = -r, r do
    for dx = -r, r do
      local d = dx * dx + dy * dy
      if d <= r * r + r then
        H.px(im, cx + dx, cy + dy, (line and d > (r - 1) * (r - 1) + r - 1) and line or fill)
      end
    end
  end
end

-- hub: nil = standard cap, "bare" = missing cap, or a colour for an odd cap.
local function wheel(im, cx, cy, r, hub)
  disc(im, cx, cy, r, P.asphalt, P.ink)
  disc(im, cx, cy, r - 2, P.asphalt_d)
  if hub == "bare" then
    disc(im, cx, cy, r - 5, P.ui_l, P.ink)
    for _, d in ipairs({ { 0, -3 }, { 3, 0 }, { 0, 3 }, { -3, 0 } }) do H.px(im, cx + d[1], cy + d[2], P.gray) end
  elseif hub then
    disc(im, cx, cy, r - 5, hub, P.ink)
    H.ellipse(im, cx, cy, 2, 2, P.ink, P.ink)
  else
    disc(im, cx, cy, r - 5, P.concrete_l, P.ink)
    H.ellipse(im, cx, cy, 2, 2, YP.orange, YP.orange)
    for _, d in ipairs({ { 0, -4 }, { 4, 0 }, { 0, 4 }, { -4, 0 } }) do H.px(im, cx + d[1], cy + d[2], P.concrete_d) end
  end
  H.px(im, cx - r + 5, cy - r + 4, P.gray); H.px(im, cx - r + 4, cy - r + 5, P.gray); H.px(im, cx - r + 3, cy - r + 7, P.gray)
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

-- The low speed-stripe graphic from the brand sheet: three leaning bands with
-- ragged trailing ends. 21 px tall, about w + 10 wide.
local function speedgraphic(im, x, y, w, c, c2)
  local bands = {
    { 0, 5, w, { 0, 0, -12, -12, -5 }, c },
    { 7, 6, math.floor(w * 0.76), { 8, 8, -8, -8, 0, 0 }, c },
    { 15, 6, math.floor(w * 0.44), { 12, 12, 0, 0, -10, -10 }, c2 },
  }
  for _, b in ipairs(bands) do
    for r = 0, b[2] - 1 do
      local sh = (20 - (b[1] + r)) // 2
      H.rect(im, x + sh, y + b[1] + r, b[3] + b[4][r + 1], 1, b[5])
    end
  end
end

local function tagline(im, x, y, c)
  -- unreadable-at-this-size strapline under the wordmark
  for _, s in ipairs({ { 0, 9 }, { 11, 15 }, { 28, 21 }, { 51, 3 }, { 56, 19 } }) do
    H.rect(im, x + s[1], y, s[2], 1, c)
  end
end

local function markers(im, xs, y, c)
  for _, x in ipairs(xs) do H.box(im, x, y, 4, 3, c or YP.orange, P.ink) end
end

------------------------------------------------------------------ step van
local WY, WR, FWX, RWX = 84, 11, 30, 152

-- Tall one-piece body, stubby nose, sliding cab door. Clean, as kept option B.
local function stepvan(L)
  local im = H.img(W, HT)
  local function left(y)
    if y < 10 then return 36 end
    if y <= 38 then return 36 - math.floor((y - 10) * 10 / 28 + 0.5) end
    if y == 39 then return 22 elseif y == 40 then return 16 elseif y == 41 then return 12 end
    return 11
  end

  -- chassis rail, battery box, rear step, mud flap
  H.box(im, 14, 72, 175, 7, P.asphalt_d, P.ink)
  H.box(im, 84, 76, 28, 10, P.gray, P.ink)
  H.rect(im, 85, 77, 26, 1, P.concrete)
  H.rect(im, 85, 84, 26, 1, P.asphalt)
  H.rect(im, 97, 77, 1, 8, P.ink)
  H.box(im, 178, 75, 14, 5, P.gray, P.ink)
  H.rect(im, 179, 76, 12, 1, P.concrete_l)
  H.rect(im, 169, 79, 2, 12, P.ink)

  -- body shell
  over(im, part(function(t)
    for y = 5, 73 do H.rect(t, left(y), y, 190 - left(y), 1, L.body) end
  end))
  for y = 5, 7 do H.rect(im, left(y), y, 190 - left(y), 1, L.hi) end
  H.rect(im, 13, 42, 12, 1, L.hi)
  H.rect(im, 11, 66, 179, 1, L.seam)
  H.rect(im, 11, 67, 179, 7, L.lo)

  -- rear roll-up door at the tail end
  H.rect(im, 177, 8, 1, 58, L.seam)
  for y = 12, 64, 4 do H.rect(im, 179, y, 11, 1, L.seam) end
  H.box(im, 181, 49, 6, 4, P.gray, P.ink)
  H.box(im, 185, 56, 5, 9, P.xred, P.ink)
  H.rect(im, 186, 57, 3, 2, YP.orange_l)
  markers(im, { 182 }, 2, P.xred)

  -- windscreen seen edge-on, following the rake
  over(im, part(function(t)
    for y = 13, 36 do H.rect(t, left(y) + 2, y, 6, 1, P.sky) end
  end))
  for y = 14, 24 do H.px(im, left(y) + 3, y, P.sky_l) end
  H.px(im, left(15) + 5, 15, P.white); H.px(im, left(16) + 5, 16, P.white)

  -- sliding cab door
  H.rect(im, 46, 8, 1, 59, L.seam)
  H.rect(im, 71, 8, 1, 59, L.seam)
  H.rect(im, 46, 8, 60, 1, L.seam)
  H.box(im, 49, 12, 20, 27, P.sky, P.ink)
  H.line(im, 52, 31, 60, 19, P.sky_l); H.line(im, 55, 33, 63, 22, P.sky_l)
  H.px(im, 64, 15, P.white); H.px(im, 65, 15, P.white); H.px(im, 65, 16, P.white)
  H.box(im, 49, 44, 3, 8, P.gray, P.ink)
  Y.mono(im, 54, 45, 1, L.mono, L.macc)
  H.box(im, 48, 66, 22, 8, P.ui, P.ink)
  H.rect(im, 49, 70, 20, 1, P.gray)

  -- nose: headlight, indicator, grille slats, hood seam, mirror
  H.box(im, 10, 45, 6, 7, P.gold, P.ink)
  H.px(im, 12, 47, P.cream); H.px(im, 12, 48, P.cream)
  H.box(im, 10, 53, 4, 4, YP.orange_l, P.ink)
  for y = 59, 64, 2 do H.rect(im, 11, y, 7, 1, P.ink) end
  H.rect(im, 26, 43, 1, 23, L.seam)
  H.rect(im, 26, 21, 6, 1, P.ink)
  H.box(im, 22, 16, 5, 11, P.gray, P.ink)
  H.rect(im, 23, 17, 1, 9, P.concrete_l)
  markers(im, { 40, 47, 54 }, 2)

  -- livery
  Y.wordmark(im, 80, 15, 2, L.word, L.wacc)
  tagline(im, 98, 32, L.tag)
  speedgraphic(im, 75, 41, 88, L.stripe, L.stripe2)

  arch(im, FWX, WY, WR + 3, 78)
  arch(im, RWX, WY, WR + 3, 78)
  H.box(im, 3, 67, 15, 8, P.gray, P.ink)
  H.rect(im, 4, 68, 13, 1, P.concrete_l)
  H.rect(im, 4, 73, 13, 1, P.asphalt)
  wheel(im, FWX, WY, WR)
  wheel(im, RWX, WY, WR)
  return im
end

------------------------------------------------------------------ wear passes
-- Each pass paints over a finished truck. L is the livery it was drawn with.
local function paint(L) return set(L.body, L.hi, C.dust, C.dust_d) end

-- Road dust creeping up from the sills and out of the wheel arches. lvl 1..3.
local function dust(im, L, lvl)
  local body, sill = paint(L), set(L.lo, C.dust_d, C.mud)
  -- a solid, lumpy tide line: higher behind each wheel, never single specks
  for x = 11, 189 do
    local h = lvl + math.floor(lvl * 2.4 * (0.5 + 0.5 * math.sin(x * 0.19 + lvl)) * (0.5 + 0.5 * math.sin(x * 0.071)) + 0.5)
    for _, cx in ipairs({ FWX, RWX }) do
      h = h + math.floor(lvl * 3.2 * math.exp(-((x - cx - 17) / 11) ^ 2) + lvl * 1.5 * math.exp(-((x - cx + 17) / 7) ^ 2))
    end
    h = math.min(h, 16)
    for i = 0, h - 1 do
      local c = C.dust
      if i < lvl - 1 then c = lvl == 3 and C.mud or C.dust_d elseif i < h // 2 then c = C.dust_d end
      on(im, x, 65 - i, c, body)
    end
  end
  if lvl >= 2 then fillOn(im, 11, 67, 179, 7, lvl == 3 and C.mud or C.dust_d, sill) end
  local clump = lvl == 3 and C.mud_d or (lvl == 2 and C.mud or C.dust_d)
  for x = 20, 184, 13 do
    local y = 68 + (x * 5) % 4
    fillOn(im, x + (x * 3) % 5, y, 4, 2, clump, sill)
    on(im, x + (x * 3) % 5 + 1, y - 1, clump, sill)
  end
  -- dirty lip round each arch
  local any = set(L.body, L.hi, L.lo, C.dust, C.dust_d, C.mud)
  local lip = lvl == 1 and C.dust_d or (lvl == 2 and C.mud or C.mud_d)
  for _, cx in ipairs({ FWX, RWX }) do
    for dy = -20, 0 do
      for dx = -20, 20 do
        local d = math.sqrt(dx * dx + dy * dy)
        if d >= 14.5 and d <= 15.5 + lvl then on(im, cx + dx, WY + dy, lip, any) end
      end
    end
  end
  if lvl >= 2 then
    -- mud on the tyres and the flap
    for _, cx in ipairs({ FWX, RWX }) do
      for _, d in ipairs({ { -9, 2 }, { -8, 5 }, { 8, 4 }, { 5, 8 }, { -4, 9 }, { 9, -1 } }) do
        H.rect(im, cx + d[1], WY + d[2], 2, 1, C.mud)
      end
    end
    stamp(im, 168, 84, { ".mm.", "mmmm", "mMmm", "mMMm", "mMMm", "MMMM", "MMMM" }, { m = C.mud, M = C.mud_d })
  end
end

-- A few short scratches in the paint.
local function scuffs(im)
  for _, s in ipairs({ { 164, 56, 168, 53 }, { 166, 58, 170, 55 }, { 18, 51, 22, 48 }, { 20, 53, 24, 50 },
    { 58, 60, 62, 57 }, { 60, 62, 64, 59 } }) do
    H.line(im, s[1], s[2], s[3], s[4], P.concrete_d)
  end
end

-- Dirt runs coming down from the roof gutter, door edges and window corners.
local function streaks(im, L, heavy)
  local body = paint(L)
  local list = { { 74, 9, 15, 2 }, { 175, 9, 22, 2 }, { 44, 12, 22, 1 }, { 72, 40, 22, 1 }, { 49, 40, 9, 1 },
    { 68, 40, 13, 2 }, { 100, 9, 5, 2 }, { 128, 9, 5, 1 }, { 151, 9, 5, 2 }, { 14, 53, 6, 1 } }
  if heavy then
    for _, s in ipairs({ { 86, 9, 5, 2 }, { 113, 9, 5, 2 }, { 164, 9, 5, 1 }, { 77, 9, 26, 1 }, { 173, 9, 30, 1 },
      { 42, 40, 20, 2 }, { 60, 53, 9, 2 }, { 20, 44, 14, 2 } }) do list[#list + 1] = s end
  end
  for _, s in ipairs(list) do
    for i = 0, s[3] - 1 do
      for k = 0, s[4] - 1 do
        local short = k == 1 and i > s[3] * 2 // 3
        if not short then
          local c = (heavy and i < s[3] // 3) and C.mud or C.dust_d
          on(im, s[1] + k, s[2] + i, c, body)
        end
      end
    end
  end
end

local function bumperScuff(im)
  H.rect(im, 5, 70, 5, 1, P.asphalt); H.rect(im, 7, 71, 6, 1, P.asphalt)
  H.rect(im, 12, 69, 3, 1, P.asphalt_d); H.rect(im, 4, 72, 3, 1, P.asphalt_d)
  H.px(im, 14, 71, C.rust); H.px(im, 15, 71, C.rust); H.px(im, 15, 72, C.rust)
end

-- Sun-bleached patch of the speed stripe.
local function fadedStripe(im)
  local o = set(YP.orange)
  for y = 41, 53 do fillOn(im, 122 - (y - 41) // 2, y, 22, 1, C.fade_o, o) end
end

local function dent(im)
  stamp(im, 163, 46, {
    "...sssss....",
    "..sdddddss..",
    ".sdd....dsh.",
    ".sd......hh.",
    ".sd......hh.",
    ".s.......hh.",
    "..s.....hh..",
    "...hhhhhh...",
  }, { s = P.tile_d, d = P.concrete_d, h = P.white })
  H.line(im, 166, 49, 170, 52, P.tile_d)
end

-- Rear roof corner dragged along something low: paint gone down to primer.
local function scrape(im)
  H.rect(im, 176, 5, 14, 4, C.primer)
  H.rect(im, 179, 9, 11, 2, C.primer); H.rect(im, 184, 11, 6, 2, C.primer)
  H.rect(im, 150, 6, 26, 1, C.primer); H.rect(im, 160, 7, 16, 1, C.primer)
  H.rect(im, 140, 6, 6, 1, C.primer)
  H.rect(im, 178, 6, 9, 1, P.asphalt); H.rect(im, 182, 8, 6, 1, P.asphalt); H.rect(im, 186, 11, 3, 1, P.asphalt)
end

local function crackedMirror(im)
  for _, p in ipairs({ { 25, 17 }, { 24, 18 }, { 24, 19 }, { 25, 20 }, { 24, 21 }, { 23, 22 }, { 24, 23 }, { 25, 24 }, { 23, 20 } }) do
    H.px(im, p[1], p[2], P.ink)
  end
end

-- Cab door swapped for one off another van: a cooler, cleaner white.
local function newDoor(im, L)
  fillOn(im, 47, 9, 24, 57, C.newpanel, paint(L))
end

local function tape(im)
  -- across the tail light
  H.rect(im, 183, 58, 7, 2, C.tape); H.rect(im, 183, 62, 7, 2, C.tape)
  H.rect(im, 183, 59, 7, 1, C.tape_d); H.rect(im, 183, 63, 7, 1, C.tape_d)
  -- strapping the bumper to the nose
  H.rect(im, 8, 63, 3, 12, C.tape); H.rect(im, 10, 63, 1, 12, C.tape_d)
  H.rect(im, 13, 65, 3, 10, C.tape); H.rect(im, 15, 65, 1, 10, C.tape_d)
end

-- Wordmark bleached on the tail half. from = first faded column at the baseline.
local function sunfade(im, from)
  for y = 15, 28 do
    for x = 80, 172 do
      if x - (28 - y) // 2 >= from then
        on(im, x, y, C.fade_k, set(YP.black)); on(im, x, y, C.fade_o, set(YP.orange))
      end
    end
  end
end

local function rustBloom(im, x, y)
  stamp(im, x, y, {
    "..rrr....",
    ".rrdrr.r.",
    "rrdddrrr.",
    "rrrddrr..",
    ".rrdrrr..",
    "..rr.rr..",
    "..r...r..",
    "..r......",
  }, { r = C.rust, d = C.rust_d })
end

local function rustSills(im)
  local map = { r = C.rust, d = C.rust_d }
  for x = 12, 186, 3 do
    if (x * 11) % 7 < 5 then H.rect(im, x, 73, 2, 1, C.rust) end
    if (x * 5) % 9 < 3 then H.rect(im, x, 72, 2, 1, C.rust_d) end
  end
  for _, x in ipairs({ 58, 74, 97, 118, 172, 181 }) do
    stamp(im, x, 67 + x % 2, { ".rrr.r", "rrdrrr", "rddrr.", ".rrr.." }, map)
  end
  rustBloom(im, 132, 60); rustBloom(im, 42, 61)
  stamp(im, 14, 61, { "r.rr", "rrdr", ".rrd", "..r." }, map)
  stamp(im, 180, 26, { ".rr.", "rrdr", ".rr.", ".r..", ".r.." }, map)
end

-- Stripe decal lifting off in pieces.
local function peel(im, L)
  local o, body = set(YP.orange, YP.orange_d, C.fade_o), L.body
  fillOn(im, 157, 41, 18, 2, body, o); fillOn(im, 150, 43, 16, 3, body, o)
  stamp(im, 148, 44, { "..oo", ".oo.", "oo.." }, { o = YP.orange_d })
  fillOn(im, 108, 48, 8, 6, body, o); fillOn(im, 112, 50, 7, 4, body, o)
  fillOn(im, 104, 56, 26, 6, body, o)
  stamp(im, 101, 59, { "..o", ".oo", "oo.", "o.." }, { o = YP.orange_d })
  fillOn(im, 84, 58, 5, 2, body, o)
end

local function tapedWindow(im)
  stamp(im, 60, 11, {
    "..ttttttttt",
    "..tttTtttTt",
    "...ttttTttt",
    "...tTtttttt",
    "....tttTttt",
    ".....tttttt",
    "......tTttt",
    ".......tttt",
  }, { t = C.tape, T = C.tape_d })
  H.line(im, 62, 16, 55, 26, P.white); H.line(im, 58, 21, 53, 22, P.white)
end

local function wiper(im, stuck)
  if stuck then
    H.line(im, 26, 38, 19, 30, P.ink); H.px(im, 18, 29, P.ink); H.px(im, 20, 30, P.ink)
  else
    H.line(im, 24, 38, 26, 30, P.ink)
  end
end

local function exhaustSoot(im)
  H.box(im, 178, 80, 11, 3, P.gray, P.ink)
  H.px(im, 187, 81, P.ink)
  stamp(im, 177, 62, {
    "....ss.....",
    "...ssss.s..",
    "..ssSss.ss.",
    "..sSSSsss..",
    ".ssSSSSss..",
    ".sSSSSSsss.",
    "ssSSSSSSss.",
    "ssSSSSSSSss",
    ".sSSSSSSSs.",
  }, { s = C.soot_l, S = C.soot })
  H.rect(im, 181, 76, 9, 1, C.soot)
end

-- Dust thick enough to write in.
local function washMe(im, L)
  local body = set(L.body, L.hi, C.dust, C.dust_d)
  fillOn(im, 128, 54, 44, 11, C.dust_d, body)
  fillOn(im, 126, 56, 48, 8, C.dust_d, body)
  H.text(im, "WASH ME", 130, 56, P.white)
end

-- Splatter thrown up and back from both wheels, for the mud-season van.
local function mudSpray(im, L)
  local any = set(L.body, L.hi, L.lo, C.dust, C.dust_d, C.mud)
  math.randomseed(11)
  for _, cx in ipairs({ FWX, RWX }) do
    for i = 1, 18 do
      local a = math.rad(10 + math.random() * 60)
      local r = 19 + math.random() * 22
      local x, y = math.floor(cx + math.cos(a) * r * 1.3), math.floor(WY - math.sin(a) * r)
      local c = r < 29 and C.mud or C.dust_d
      fillOn(im, x, y, 3, 2, c, any); fillOn(im, x + 1, y - 1, 2, 1, c, any)
      if r < 29 then fillOn(im, x - 1, y + 1, 2, 1, c, any) end
    end
  end
  for i = 1, 10 do
    local x, y = 179 + math.random(0, 9), 40 + math.random(0, 24)
    fillOn(im, x, y, 2, 2, C.dust_d, any)
  end
end

-- Courier-life clutter: no damage, just evidence somebody works out of it.
local function clutter(im)
  -- parking ticket under the wiper
  wiper(im, false)
  H.box(im, 20, 30, 6, 6, H.c("ffe36e"), P.ink)
  H.rect(im, 22, 32, 2, 1, P.ink); H.rect(im, 22, 34, 2, 1, P.ink)
  -- air freshener hanging in the cab
  H.rect(im, 57, 13, 1, 4, P.ink)
  stamp(im, 54, 17, { "...g...", "..ggg..", ".ggggg.", "..ggg..", ".ggggg.", "ggggggg", "...b..." },
    { g = P.grass, b = P.base })
  H.px(im, 57, 19, P.grass_d); H.px(im, 56, 21, P.grass_d); H.px(im, 58, 22, P.grass_d)
  -- coffee cup forgotten on the hood
  H.box(im, 15, 35, 6, 7, P.white, P.ink)
  H.rect(im, 16, 38, 4, 2, P.card_m)
  H.rect(im, 14, 35, 8, 1, P.ink)
  -- stickers on the roll-up door
  H.box(im, 179, 36, 10, 6, P.blue, P.ink); H.rect(im, 181, 38, 6, 1, P.white)
  H.box(im, 180, 28, 8, 6, P.yellow, P.ink); H.rect(im, 182, 30, 4, 2, P.ink)
  -- traffic cone riding on the rear step
  over(im, part(function(t)
    stamp(t, 181, 64, {
      "...oo...",
      "...oo...",
      "..oooo..",
      "..wwww..",
      "..oooo..",
      ".oooooo.",
      ".wwwwww.",
      ".oooooo.",
      ".oooooo.",
      "oooooooo",
      "oooooooo",
    }, { o = P.orange, w = P.white })
  end))
end

------------------------------------------------------------------ build trucks
-- Each entry: code, file slug, label, builder. B1-B5 run clean to rough;
-- B6-B8 sit to the side of that scale.
local function build(body, fn)
  local L = livery(body)
  local im = stepvan(L)
  if fn then fn(im, L) end
  return im
end

local function working(im, L)
  dust(im, L, 2); streaks(im, L); scuffs(im); bumperScuff(im); fadedStripe(im)
end
local function stories(im, L)
  working(im, L); dent(im); scrape(im); crackedMirror(im)
  wheel(im, RWX, WY, WR, P.gold)
end

local TRUCKS = {
  { "B", "stepvan_white", "B (KEPT)", build() },
  { "B1", "lightly_used", "B1 LIGHTLY USED", build(C.dull1, function(im, L)
    dust(im, L, 1); scuffs(im)
  end) },
  { "B2", "working_truck", "B2 WORKING TRUCK", build(C.dull1, working) },
  { "B3", "a_few_stories", "B3 A FEW STORIES", build(C.dull1, stories) },
  { "B4", "patched_up", "B4 PATCHED UP", build(C.dull2, function(im, L)
    stories(im, L); newDoor(im, L); tape(im); sunfade(im, 128); rustBloom(im, 132, 60)
  end) },
  { "B5", "overdue", "B5 OVERDUE FOR RETIREMENT", build(C.dull2, function(im, L)
    dust(im, L, 3); streaks(im, L, true); scuffs(im); bumperScuff(im); fadedStripe(im)
    dent(im); scrape(im); crackedMirror(im); newDoor(im, L); sunfade(im, 104)
    peel(im, L); washMe(im, L); rustSills(im); exhaustSoot(im); tape(im)
    tapedWindow(im); wiper(im, true)
    wheel(im, RWX, WY, WR, "bare"); wheel(im, FWX, WY, WR, P.gold)
  end) },
  { "B6", "courier_life", "B6 COURIER LIFE (SIDE)", build(C.dull1, function(im, L)
    dust(im, L, 1); clutter(im)
  end) },
  { "B7", "mud_season", "B7 MUD SEASON (SIDE)", build(C.dull1, function(im, L)
    dust(im, L, 3); mudSpray(im, L)
  end) },
  { "B8", "lived_in", "B8 LIVED IN (SIDE)", build(C.dull1, function(im, L)
    working(im, L); dent(im); clutter(im)
    H.rect(im, 183, 58, 7, 2, C.tape); H.rect(im, 183, 59, 7, 1, C.tape_d)
    wheel(im, FWX, WY, WR, P.gold)
  end) },
}
for i, t in ipairs(TRUCKS) do
  saveRaw(t[4], i == 1 and "truck_B_stepvan_white" or ("truck_" .. t[1] .. "_" .. t[2]))
end

------------------------------------------------------------------ dolly variants
-- Recolour of the shipped dolly (3 frames of 40x64), then light wear per frame.
local SRC = Image { fromFile = H.SPR .. "vehicles/dolly.png" }
local function dollyBase()
  local map = { [P.gray] = YP.gray, [P.concrete_l] = YP.white, [P.orange] = YP.orange, [P.yellow] = YP.orange_l }
  local im = H.img(SRC.width, SRC.height)
  for y = 0, SRC.height - 1 do
    for x = 0, SRC.width - 1 do
      local p = SRC:getPixel(x, y)
      if pc.rgbaA(p) > 0 then im:drawPixel(x, y, map[p] or p) end
    end
  end
  return im
end

local function dollyWear(lvl)
  local im = dollyBase()
  for f = 0, 2 do
    local x = f * 40
    -- chipped paint on the rail, grime on the plate, mud on the tyre
    for _, y in ipairs({ 14, 27, 45 }) do H.rect(im, x + 10, y, 2, lvl == 2 and 4 or 2, P.asphalt) end
    H.rect(im, x + 14, 61, 5, 1, C.dust_d); H.rect(im, x + 24, 61, 7, 1, C.dust_d)
    for _, d in ipairs({ { 2, 59 }, { 10, 60 }, { 3, 53 }, { 11, 55 } }) do
      H.rect(im, x + d[1] + (f % 2), d[2], 2, 1, C.mud)
    end
    if lvl == 2 then
      -- tape wound round the grip and a splinted rail
      H.rect(im, x + 4, 3, 3, 2, C.tape); H.px(im, x + 5, 4, C.tape_d)
      H.rect(im, x + 9, 34, 4, 5, C.tape); H.rect(im, x + 9, 36, 4, 1, C.tape_d)
      H.rect(im, x + 10, 50, 2, 3, C.rust)
      H.rect(im, x + 19, 61, 4, 1, C.rust)
      -- toe-plate corner bent upward
      H.rect(im, x + 35, 59, 5, 4, P.none)
      for i = 0, 4 do
        local y = 60 - (i + 1) // 2
        H.px(im, x + 35 + i, y, P.ink); H.px(im, x + 35 + i, y + 1, YP.white); H.px(im, x + 35 + i, y + 2, P.ink)
      end
      H.rect(im, x + 39, 58, 1, 3, P.ink)
    end
  end
  return im
end

local DOLLIES = {
  { "B", "white", "DOLLY B (KEPT)", dollyBase() },
  { "B1", "white_scuffed", "DOLLY B1 SCUFFED", dollyWear(1) },
  { "B2", "white_well_used", "DOLLY B2 WELL USED", dollyWear(2) },
}
for _, d in ipairs(DOLLIES) do saveRaw(d[4], "dolly_" .. d[1] .. (d[1] == "B" and "_white" or ("_" .. d[2]))) end

------------------------------------------------------------------ review sheets
local CW, RH = 262, 126
local idle = H.load("player/player_idle.png")
local pkg = H.load("package/package_intact.png")

local function ground(pv, y, top, fill, hi)
  H.rect(pv, 0, y, pv.width, 14, fill)
  H.rect(pv, 0, y, pv.width, 1, top)
  if hi then H.rect(pv, 0, y + 1, pv.width, 1, hi) end
end

-- 3x3 grid of every truck with the courier beside it. y0 = top of the grid.
local function grid(pv, y0, gtop, gfill, ghi)
  for i, t in ipairs(TRUCKS) do
    local col, row = (i - 1) % 3, (i - 1) // 3
    local x, g = 6 + col * CW, y0 + row * RH + 112
    if col == 0 then ground(pv, g, gtop, gfill, ghi) end
    H.tag(pv, t[3], x, g - 110)
    H.blit(pv, t[4], x, g - 96)
    H.blit(pv, idle, x + 198, g - 64, 0, 0, 48, 64)
  end
end

-- Sheet 1: sky, plus the dolly row.
local pv = H.img(CW * 3 + 8, RH * 3 + 104, P.sky_l)
grid(pv, 0, P.ink, P.concrete, P.concrete_l)
local dg = RH * 3 + 88
ground(pv, dg, P.ink, P.concrete, P.concrete_l)
for i, d in ipairs(DOLLIES) do
  local x = 6 + (i - 1) * CW
  H.tag(pv, d[3], x, dg - 84)
  for f = 0, 2 do H.blit(pv, d[4], x + f * 40, dg - 64, f * 40, 0, 40, 64) end
  -- loaded dolly: packages at frame offset (11, 29), 20 px pitch
  local lx = x + 128
  H.blit(pv, d[4], lx, dg - 64, 0, 0, 40, 64)
  H.blit(pv, pkg, lx + 11, dg - 64 + 29, 0, 0, 32, 32)
  H.blit(pv, pkg, lx + 11, dg - 64 + 9, 0, 0, 32, 32)
  H.blit(pv, idle, lx + 46, dg - 64, 0, 0, 48, 64)
end
saveScaled(pv, REVIEW .. "options_trucks.png", 3)

-- Sheet 2: the level 1 loading area colours. Top half is a concrete hotel
-- wall over asphalt, bottom half is a plain asphalt backdrop.
local bg = H.img(CW * 3 + 8, RH * 6 + 16, P.concrete)
for y = 0, RH * 3 - 1, 16 do
  H.rect(bg, 0, y, bg.width, 1, P.concrete_d)
  for x = ((y // 16) % 2) * 24, bg.width - 1, 48 do H.rect(bg, x, y, 1, 16, P.concrete_d) end
end
grid(bg, 0, P.ink, P.asphalt, P.asphalt_d)
H.rect(bg, 0, RH * 3, bg.width, bg.height - RH * 3, P.asphalt)
grid(bg, RH * 3, P.ink, P.asphalt_d, nil)
saveScaled(bg, REVIEW .. "options_trucks_backgrounds.png", 3)

-- Optional 1x check: all trucks then all dollies, actual game pixels.
if TMP then
  local one = H.img(192 * 3, 96 * 3 + 64, P.sky_l)
  for i, t in ipairs(TRUCKS) do H.blit(one, t[4], ((i - 1) % 3) * 192, ((i - 1) // 3) * 96) end
  for i, d in ipairs(DOLLIES) do H.blit(one, d[4], (i - 1) * 192, 288) end
  one:saveAs(TMP .. "/check_1x.png")
  saveScaled(one, TMP .. "/check_4x.png", 4)
end
