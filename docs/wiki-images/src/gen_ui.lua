-- Menu UI art: title logo, button/panel/slider skins, confetti loop, app icon.
-- Writes assets/ui/<name>.aseprite (one frame per state, tagged, layer "Art")
-- and a .png for the single-frame assets, plus 4x review sheets in docs/art-review/.
-- Strips and JSON for the multi-frame assets come from a CLI pass afterwards
-- (run from assets/ui so the JSON stores a relative image name):
--   Aseprite -b button.aseprite --sheet button.png --sheet-type horizontal \
--     --data button.json --format json-array --list-tags
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local pc = app.pixelColor
local OUT = H.ROOT .. "assets/ui/"
local REVIEW = H.ROOT .. "docs/art-review/"
app.fs.makeAllDirectories(OUT)
app.fs.makeAllDirectories(REVIEW)

local CARD_L = H.c("f6cc86") -- hover cardboard, card lifted toward cream

-- frames: list of same-size images. tags: list of names, one per frame, or
-- { name = , from = , to = } entries. dur: seconds per frame.
local function save(name, frames, tags, dur)
  local w, h = frames[1].width, frames[1].height
  local spr = Sprite(w, h, ColorMode.RGB)
  local layer = spr.layers[1]
  layer.name = "Art"
  for i, im in ipairs(frames) do
    if i > 1 then spr:newEmptyFrame() end
    spr:newCel(layer, i, im, Point(0, 0))
    if dur then spr.frames[i].duration = dur end
  end
  for i, t in ipairs(tags or {}) do
    local tag
    if type(t) == "table" then
      tag = spr:newTag(t.from, t.to); tag.name = t.name
    else
      tag = spr:newTag(i, i); tag.name = t
    end
  end
  spr:saveAs(OUT .. name .. ".aseprite")
  if #frames == 1 then spr:saveCopyAs(OUT .. name .. ".png") end
  spr:close()
  print(string.format("saved %s  frame %dx%d  frames %d", name, w, h, #frames))
end

------------------------------------------------------------------ title logo
local function title_logo()
  local big = H.img(220, 90)
  local o = { s = 3, outline = P.ink, ot = 2, shadow = P.card_d, sd = 3, align = "center" }
  H.text(big, "HANDLE", 110, 8, P.cream, o)
  H.text(big, "WITH CARE", 110, 36, P.cream, o)
  local x0, y0, x1, y1 = big.width, big.height, -1, -1
  for y = 0, big.height - 1 do
    for x = 0, big.width - 1 do
      if pc.rgbaA(big:getPixel(x, y)) > 0 then
        x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
      end
    end
  end
  local M = 2
  local im = H.img(x1 - x0 + 1 + 2 * M, y1 - y0 + 1 + 2 * M)
  H.blit(im, big, M, M, x0, y0, x1 - x0 + 1, y1 - y0 + 1)
  return im
end
local logo = title_logo()
save("title_logo", { logo })

------------------------------------------------------------------ button (nine-patch, 4px margins)
local BW, BH = 48, 20
local function button(state)
  local im = H.img(BW, BH)
  local fill, hi, lip, edge, line = P.card, P.cream, P.card_m, P.card_m, P.ink
  if state == "hover" then fill, hi, lip, edge = CARD_L, P.white, P.card, P.card end
  if state == "disabled" then
    fill, hi, lip, edge, line = P.concrete, P.concrete_l, P.concrete_d, P.concrete_d, P.asphalt_d
  end
  if state == "pressed" then
    -- sunk 2px onto where the shadow was: inner shadow on top and left
    H.box(im, 0, 2, BW, 18, P.card_m, line)
    H.rect(im, 1, 3, BW - 2, 1, P.card_d)
    H.rect(im, 1, 3, 1, 16, P.card_d)
    H.rect(im, 2, 18, BW - 3, 1, P.card)
    return im
  end
  H.rect(im, 1, 18, BW - 1, 2, line)
  H.box(im, 0, 0, BW, 18, fill, line)
  H.rect(im, 1, 1, BW - 2, 2, hi)
  H.rect(im, BW - 2, 3, 1, 14, edge)
  H.rect(im, 1, 16, BW - 2, 1, lip)
  return im
end
local BSTATES = { "normal", "hover", "pressed", "disabled" }
local btn = {}
for i, s in ipairs(BSTATES) do btn[s] = button(s); btn[i] = btn[s] end
save("button", btn, BSTATES)

------------------------------------------------------------------ panel (nine-patch, 4px margins)
local panel = H.img(24, 24)
H.panel(panel, 0, 0, 22, 22)
save("panel", { panel })

------------------------------------------------------------------ slider
local function track(top, bottom)
  local im = H.img(32, 8)
  H.box(im, 0, 2, 32, 4, bottom, P.ink)
  H.rect(im, 1, 3, 30, 1, top)
  return im
end
local s_track = track(P.ui_l, P.ui_ll)
local s_fill = track(P.mat_g, P.mat_gd)
save("slider_track", { s_track })
save("slider_fill", { s_fill })

local function grabber(hot)
  local im = H.img(8, 12)
  local fill, shade, grip = P.white, P.concrete_l, P.gray
  if hot then fill, shade, grip = P.yellow, P.gold_d, P.base_d end
  H.box(im, 0, 0, 8, 12, fill, P.ink)
  H.rect(im, 6, 1, 1, 10, shade)
  H.rect(im, 1, 10, 6, 1, shade)
  if hot then H.rect(im, 1, 1, 5, 1, P.cream) end
  H.rect(im, 2, 4, 4, 1, grip)
  H.rect(im, 2, 6, 4, 1, grip)
  -- knock the corners off so the knob reads as rounded
  for _, c in ipairs({ { 0, 0 }, { 7, 0 }, { 0, 11 }, { 7, 11 } }) do
    im:drawPixel(c[1], c[2], P.none)
    im:drawPixel(c[1] == 0 and 1 or 6, c[2] == 0 and 1 or 10, P.ink)
  end
  return im
end
local grab = { grabber(false), grabber(true) }
save("slider_grabber", grab, { "normal", "hover" })

------------------------------------------------------------------ confetti loop
-- Pieces fall in chains: m identical pieces share one wavy path, spaced CH/m
-- apart, and each travels exactly CH/m over the 8 frames. Every piece ends
-- the loop where the next one in its chain started, so frame 8+1 == frame 1
-- while the fall stays slow (4 to 8 px per frame instead of a full screen).
local CW, CH, CF = 240, 135, 8
local chains = {}
do
  math.randomseed(11)
  local cols = { P.red, P.yellow, P.mat_g, P.blue, P.purple, P.orange, P.white }
  local ms = { 2, 3, 3, 4 }
  for i = 1, 34 do
    chains[i] = {
      m = ms[math.random(1, #ms)], x0 = math.random(0, CW - 1), y0 = math.random(0, CH - 1),
      col = cols[math.random(1, #cols)], amp = math.random(0, 4), waves = math.random(1, 2),
      phi = math.random() * math.pi * 2, flip = math.random(0, 1), every = math.random(1, 2),
    }
  end
end

-- x, y, tall for copy j (0-based) of chain c at frame f (0-based)
local function piece(c, j, f)
  local yf = (c.y0 + j * CH / c.m + f * CH / (CF * c.m)) % CH
  local x = (c.x0 + math.floor(c.amp * math.sin(2 * math.pi * c.waves * yf / CH + c.phi) + 0.5)) % CW
  local tall = ((f // c.every) + c.flip) % 2 == 1
  return x, math.floor(yf), tall
end

local function confetti_frame(f)
  local im = H.img(CW, CH)
  for _, c in ipairs(chains) do
    for j = 0, c.m - 1 do
      local x, y, tall = piece(c, j, f)
      local w, h = tall and 2 or 3, tall and 3 or 2
      -- also draw the wrapped copies so pieces slide through the edges
      for _, oy in ipairs({ 0, -CH }) do
        for _, ox in ipairs({ 0, -CW }) do H.rect(im, x + ox, y + oy, w, h, c.col) end
      end
    end
  end
  return im
end

local conf = {}
for f = 0, CF - 1 do conf[f + 1] = confetti_frame(f) end
save("confetti", conf, { { name = "fall", from = 1, to = CF } }, 0.1)

do -- loop check: frame 8+1 must equal frame 1, piece by piece and pixel by pixel
  local n, bad = 0, 0
  for _, c in ipairs(chains) do
    for j = 0, c.m - 1 do
      local ax, ay, at = piece(c, j, CF)
      local bx, by, bt = piece(c, (j + 1) % c.m, 0)
      n = n + 1
      if ax ~= bx or ay ~= by or at ~= bt then bad = bad + 1 end
    end
  end
  print(string.format("confetti loop: %d pieces in %d chains, %d mismatches at frame %d+1 vs frame 1",
    n, #chains, bad, CF))
  print("confetti loop: frame 9 image equals frame 1 image: " .. tostring(confetti_frame(CF):isEqual(conf[1])))
  print("confetti loop: frame 2 image equals frame 1 image (should be false): " .. tostring(conf[2]:isEqual(conf[1])))
end

------------------------------------------------------------------ icon
local function rrect(im, x, y, w, h, r, c)
  for j = 0, h - 1 do
    for i = 0, w - 1 do
      local dx = i < r and (r - 1 - i) or (i >= w - r and (i - (w - r)) or -1)
      local dy = j < r and (r - 1 - j) or (j >= h - r and (j - (h - r)) or -1)
      if dx < 0 or dy < 0 or (dx + 0.5) ^ 2 + (dy + 0.5) ^ 2 <= r * r then H.px(im, x + i, y + j, c) end
    end
  end
end

local function icon()
  local im = H.img(64, 64)
  rrect(im, 0, 0, 64, 64, 11, P.ink)
  rrect(im, 1, 1, 62, 62, 10, P.door_d)
  rrect(im, 1, 1, 62, 59, 10, P.door_l)
  rrect(im, 1, 3, 62, 57, 10, P.door)
  local src = H.load("package/package_intact.png")
  local x0, y0, x1, y1 = 32, 32, -1, -1
  for y = 0, 31 do for x = 0, 31 do
    if pc.rgbaA(src:getPixel(x, y)) > 0 then
      x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
    end
  end end
  local w, h = (x1 - x0 + 1) * 2, (y1 - y0 + 1) * 2
  print(string.format("icon: package content %dx%d at 2x", w, h))
  H.blit(im, src, (64 - w) // 2, 4, x0, y0, x1 - x0 + 1, y1 - y0 + 1, false, 2)
  -- FRAGILE sticker slapped across the bottom of the box
  H.box(im, 9, 50, 46, 11, P.cream, P.ink)
  H.rect(im, 10, 59, 44, 1, P.tape)
  H.text(im, "FRAGILE", 32, 52, P.red_d, { align = "center" })
  return im
end
local ico = icon()

local function scaled(src, s)
  local im = H.img(src.width * s, src.height * s)
  H.blit(im, src, 0, 0, 0, 0, src.width, src.height, false, s)
  return im
end
ico:saveAs(OUT .. "icon_64.png")
local ico256 = scaled(ico, 4)
ico256:saveAs(OUT .. "icon_256.png")
print("saved icon_64 64x64, icon_256 256x256")

------------------------------------------------------------------ previews
-- Stretch src like a Godot StyleBoxTexture: fixed margins, stretched centre.
local function nine(dst, src, x, y, w, h, ml, mt, mr, mb)
  local sw, sh = src.width, src.height
  local function map(d, n, sn, a, b)
    if d < a then return d end
    if d >= n - b then return sn - (n - d) end
    return a + ((d - a) * (sn - a - b)) // (n - a - b)
  end
  for j = 0, h - 1 do
    for i = 0, w - 1 do
      local p = src:getPixel(map(i, w, sw, ml, mr), map(j, h, sh, mt, mb))
      if pc.rgbaA(p) > 0 then H.px(dst, x + i, y + j, p) end
    end
  end
end

local function slider(dst, x, y, w, v, g)
  nine(dst, s_track, x, y, w, 8, 2, 0, 2, 0)
  local k = math.floor((w - 8) * v)
  nine(dst, s_fill, x, y, k + 4, 8, 2, 0, 2, 0)
  H.blit(dst, g or grab[1], x + k, y - 2)
end

local function label_button(dst, state, cx, y, w, text)
  nine(dst, btn[state], cx - w // 2, y, w, BH, 4, 4, 4, 4)
  local ty = y + 6 + (state == "pressed" and 2 or 0)
  H.text(dst, text, cx, ty, state == "disabled" and P.asphalt or P.box_ink, { align = "center" })
end

do -- mock main menu, 480x270
  local pv = H.img(480, 270)
  local tiles = Image { fromFile = H.ROOT .. "assets/tilesets/hotel_tileset.png" }
  local rows = { 1, 0, 0, 0, 0, 2, 3, 4, 4 }
  for r, col in ipairs(rows) do
    for c = 0, 14 do H.blit(pv, tiles, c * 32, (r - 1) * 32, col * 32, 0, 32, 32) end
  end
  H.blit(pv, logo, 240 - logo.width, 8, 0, 0, logo.width, logo.height, false, 2)
  label_button(pv, "hover", 150, 144, 96, "START")
  label_button(pv, "normal", 150, 170, 96, "SETTINGS")
  label_button(pv, "normal", 150, 196, 96, "EXIT")
  nine(pv, panel, 250, 150, 162, 62, 4, 4, 4, 4)
  H.text(pv, "MUSIC", 260, 160, P.gold)
  H.text(pv, "60%", 382, 176, P.ui_ll)
  slider(pv, 260, 176, 112, 0.6)
  H.text(pv, "SFX", 260, 194, P.gold)
  H.blit(pv, conf[3], 0, 0, 0, 0, CW, CH, false, 2)
  scaled(pv, 4):saveAs(REVIEW .. "ui_preview.png")
  print("saved ui_preview 1920x1080")
end

do -- every frame of every asset
  local S = 4
  local sh = H.img(1960, 1010, P.gray)
  local function cap(str, x, y) H.text(sh, str, x, y, P.ink, { s = 2 }) end
  local function put(im, x, y, s) H.blit(sh, im, x, y, 0, 0, im.width, im.height, false, s or S) end

  cap("TITLE LOGO " .. logo.width .. "X" .. logo.height, 12, 10)
  put(logo, 12, 30)
  cap("ICON 64 AT 4X", 680, 10)
  put(ico, 680, 30)
  cap("ICON 256 AT 1X", 960, 10)
  put(ico256, 960, 30, 1)
  cap("ICON 64 AT 1X", 1240, 10)
  put(ico, 1240, 30, 1)

  cap("BUTTON 48X20: NORMAL, HOVER, PRESSED, DISABLED", 12, 300)
  for i = 1, 4 do put(btn[i], 12 + (i - 1) * 208, 320) end
  cap("PANEL 24X24", 860, 300)
  put(panel, 860, 320)
  cap("TRACK, FILL 32X8", 1040, 300)
  put(s_track, 1040, 320)
  put(s_fill, 1040, 360)
  cap("GRABBER 8X12", 1300, 300)
  put(grab[1], 1300, 320)
  put(grab[2], 1348, 320)

  cap("NINE-PATCH STRETCH TESTS", 12, 420)
  local t = H.img(480, 80)
  label_button(t, "normal", 50, 2, 96, "START")
  label_button(t, "hover", 150, 2, 96, "SETTINGS")
  label_button(t, "pressed", 250, 2, 96, "EXIT")
  label_button(t, "disabled", 350, 2, 96, "LOCKED")
  nine(t, btn.normal, 2, 28, 140, 34, 4, 4, 4, 4)
  nine(t, btn.hover, 148, 28, 20, 34, 4, 4, 4, 4)
  nine(t, panel, 176, 28, 120, 44, 4, 4, 4, 4)
  slider(t, 186, 38, 100, 0.6)
  slider(t, 186, 54, 100, 0.0, grab[2])
  nine(t, panel, 304, 28, 90, 44, 4, 4, 4, 4)
  slider(t, 312, 38, 70, 1.0)
  slider(t, 312, 54, 70, 0.25, grab[2])
  nine(t, panel, 402, 28, 12, 12, 4, 4, 4, 4)
  put(t, 12, 440)

  cap("CONFETTI 240X135, 8 FRAMES AT 1X", 12, 780)
  for f = 1, CF do
    local x = 12 + (f - 1) * 243
    H.rect(sh, x, 800, CW, CH, P.ui_l)
    put(conf[f], x, 800, 1)
  end
  sh:saveAs(REVIEW .. "ui_sheet_preview.png")
  print("saved ui_sheet_preview " .. sh.width .. "x" .. sh.height)
end
