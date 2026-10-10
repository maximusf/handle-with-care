-- Interactables and feedback sprites: lever, wall switch, pressure plate,
-- power arrow, photo timer, camera flash.
-- Writes assets/sprites/interactables/* and assets/sprites/fx/* as
-- .aseprite (one tag per frame), a horizontal .png strip and a .json, plus
-- docs/art-review/interactables_preview.png (every frame at 4x).
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local pc = app.pixelColor
local INT = H.SPR .. "interactables/"
local FX = H.SPR .. "fx/"
local REVIEW = H.ROOT .. "docs/art-review/"
for _, d in ipairs({ INT, FX, REVIEW }) do app.fs.makeAllDirectories(d) end

-- a few extra shades the shared palette lacks
local RED_L = H.c("ff8a8c")
local GREEN_L = H.c("a6f7ae")
local ORANGE_D = H.c("b9610f")
local STEEL_L = H.c("b4b8bd")
local LED_OFF = H.c("5a1518")

local assets = {} -- kept for the preview

-- frames: list of { img, tag, dur }
local function export(dir, name, w, h, frames)
  local spr = Sprite(w, h, ColorMode.RGB)
  spr.layers[1].name = "Art"
  for i, f in ipairs(frames) do
    if i > 1 then spr:newEmptyFrame(i) end
    spr:newCel(spr.layers[1], spr.frames[i], f[1], Point(0, 0))
    spr.frames[i].duration = f[3]
    local tag = spr:newTag(i, i)
    tag.name = f[2]
  end
  spr:saveAs(dir .. name .. ".aseprite")
  app.sprite = spr
  app.command.ExportSpriteSheet {
    ui = false, askOverwrite = false, type = SpriteSheetType.HORIZONTAL,
    textureFilename = dir .. name .. ".png", dataFilename = dir .. name .. ".json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY, listTags = true,
  }
  spr:close()
  assets[#assets + 1] = { name = name, w = w, h = h, frames = frames }
  print(name .. " " .. #frames .. " frames " .. w .. "x" .. h)
end

-- Filled circle of radius r + 0.5, rounder than H.ellipse at small sizes.
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

------------------------------------------------------------------ lever
-- Wall plate with a slot, steel handle and red knob. The handle swings over
-- the top from left (off) to right (on); the lamp follows it.
local function lever(kx, ky, lamp)
  local t = H.img(32, 32)
  H.box(t, 6, 13, 21, 18, P.concrete, P.ink)
  H.rect(t, 7, 14, 19, 1, P.concrete_l)
  H.rect(t, 7, 29, 19, 1, P.concrete_d)
  H.rect(t, 25, 15, 1, 14, P.concrete_d)
  for _, p in ipairs({ { 8, 16 }, { 24, 16 }, { 8, 28 }, { 24, 28 } }) do H.px(t, p[1], p[2], P.mat_nd) end
  H.rect(t, 9, 18, 15, 4, P.ink)                  -- slot
  H.rect(t, 10, 21, 13, 1, P.asphalt)
  H.box(t, 14, 24, 5, 5, lamp, P.ink)             -- status lamp
  H.px(t, 15, 25, P.white)
  H.line(t, 16, 20, kx, ky, P.ink, 4)             -- handle
  H.line(t, 16, 20, kx, ky, STEEL_L, 2)
  disc(t, kx, ky, 4, P.xred, P.ink)               -- knob
  for _, p in ipairs({ { 1, 3 }, { 2, 2 }, { 3, 1 }, { 2, 3 }, { 3, 2 } }) do H.px(t, kx + p[1], ky + p[2], P.red_d) end
  for _, p in ipairs({ { -1, -3 }, { -2, -2 }, { -3, -1 } }) do H.px(t, kx + p[1], ky + p[2], RED_L) end
  H.px(t, kx - 2, ky - 2, P.white)
  return t
end

export(INT, "lever", 32, 32, {
  { lever(6, 9, LED_OFF), "off", 0.1 },
  { lever(16, 5, P.yellow), "mid", 0.08 },
  { lever(26, 9, P.mat_g), "on", 0.1 },
})

------------------------------------------------------------------ wall switch
-- Chunky bumper button in a steel housing. Off: red dome standing proud.
-- On: dome pushed in flush and lit green.
local function wall_switch(on)
  local t = H.img(32, 32)
  H.box(t, 5, 2, 22, 28, P.mat_n, P.ink)
  H.rect(t, 6, 3, 20, 1, STEEL_L)
  H.rect(t, 6, 28, 20, 1, P.mat_nd)
  H.rect(t, 25, 4, 1, 24, P.mat_nd)
  for _, p in ipairs({ { 7, 5 }, { 24, 5 }, { 7, 27 }, { 24, 27 } }) do H.px(t, p[1], p[2], P.mat_nd) end
  -- status light
  H.box(t, 13, 4, 6, 4, on and P.mat_g or P.xred, P.ink)
  H.px(t, 14, 5, on and GREEN_L or RED_L)
  -- button
  disc(t, 16, 19, 8, P.mat_nd, P.ink) -- collar
  disc(t, 16, 19, 7, P.asphalt, P.asphalt)
  if on then
    disc(t, 16, 19, 6, P.mat_g, P.ink)
    H.line(t, 13, 23, 19, 23, P.mat_gd); H.line(t, 20, 20, 20, 22, P.mat_gd)
    H.rect(t, 13, 15, 3, 1, GREEN_L); H.rect(t, 12, 16, 1, 2, GREEN_L)
  else
    disc(t, 16, 20, 6, P.red_d, P.ink) -- side of the raised dome
    disc(t, 16, 17, 6, P.xred, P.ink)
    H.line(t, 14, 21, 19, 21, P.red_d); H.line(t, 20, 18, 20, 20, P.red_d)
    H.rect(t, 13, 13, 3, 1, RED_L); H.rect(t, 12, 14, 1, 2, RED_L)
    H.px(t, 14, 14, P.white)
  end
  return t
end

export(INT, "wall_switch", 32, 32, {
  { wall_switch(false), "off", 0.1 },
  { wall_switch(true), "on", 0.1 },
})

------------------------------------------------------------------ pressure plate
-- Gold plate in a steel tray resting on the bottom edge of a 32x16 frame.
local function plate(down)
  local t = H.img(32, 16)
  local y = down and 8 or 6
  H.box(t, 3, y, 26, 7, P.gold, P.ink)
  if down then
    H.rect(t, 4, y + 2, 24, 1, P.gold_d)
  else
    H.rect(t, 4, y + 1, 24, 1, P.cream)
    H.rect(t, 4, y + 4, 24, 1, P.gold_d)
    H.rect(t, 6, y + 2, 2, 1, P.cream)
  end
  H.box(t, 1, 11, 30, 5, P.mat_nd, P.ink) -- tray
  H.rect(t, 2, 12, 28, 1, P.mat_n)
  H.rect(t, 4, 13, 3, 2, down and P.mat_g or LED_OFF)
  H.rect(t, 25, 13, 3, 2, down and P.mat_g or LED_OFF)
  return t
end

export(INT, "pressure_plate", 32, 16, {
  { plate(false), "up", 0.1 },
  { plate(true), "down", 0.1 },
})

------------------------------------------------------------------ power arrow
-- Points right, pivot at the left-middle of the frame (0, 8).
local SEG = {
  { P.mat_g, P.mat_gd }, { P.mat_g, P.mat_gd }, { P.yellow, P.mat_yd },
  { P.orange, ORANGE_D }, { P.xred, P.red_d },
}
local function arrow(charge)
  local t = H.img(64, 16)
  for i = 0, 4 do
    local c = i < charge and SEG[i + 1] or { P.white, P.concrete_l }
    H.box(t, i * 10, 4, 9, 8, c[1], P.ink)
    H.rect(t, i * 10 + 1, 10, 7, 1, c[2])
  end
  for k = 0, 10 do -- arrowhead
    local half = math.max(1, 6 - k // 2)
    H.rect(t, 52 + k, 8 - half, 1, half * 2, P.ink)
  end
  for k = 0, 8 do
    local half = math.max(1, 5 - (k + 1) // 2)
    H.rect(t, 53 + k, 8 - half, 1, half * 2, P.white)
    H.px(t, 53 + k, 8 + half - 1, P.concrete_l)
  end
  H.rect(t, 50, 6, 2, 4, P.ink) -- neck joining the head to the bar
  H.rect(t, 50, 7, 3, 2, P.white)
  return t
end

local af = {}
for c = 0, 5 do af[#af + 1] = { arrow(c), "charge_" .. c, 0.1 } end
export(FX, "power_arrow", 64, 16, af)

------------------------------------------------------------------ photo timer
-- Speech bubble with a stopwatch and the seconds left; green tick when done.
local function bubble(fill, shade)
  local t = H.img(32, 24)
  H.rect(t, 2, 1, 28, 18, fill)
  for _, p in ipairs({ { 2, 1 }, { 29, 1 }, { 2, 18 }, { 29, 18 } }) do H.px(t, p[1], p[2], P.none) end
  H.rect(t, 3, 18, 26, 1, shade)
  H.rect(t, 13, 19, 6, 1, fill)
  H.rect(t, 14, 20, 4, 1, fill)
  H.rect(t, 15, 21, 2, 1, shade)
  A.outline(t, P.ink, false)
  return t
end

local function timer(n)
  local t = bubble(P.mat_y, P.mat_yd)
  H.rect(t, 8, 3, 3, 2, P.ink)                      -- stopwatch button
  H.ellipse(t, 9, 10, 5, 5, P.white, P.ink)
  H.px(t, 9, 6, P.ink); H.px(t, 13, 10, P.ink); H.px(t, 9, 14, P.ink); H.px(t, 5, 10, P.ink)
  local a = -math.pi / 2 + (5 - n) * 2 * math.pi / 5 -- hand sweeps a fifth per second
  H.line(t, 9, 10, math.floor(9 + math.cos(a) * 3 + 0.5), math.floor(10 + math.sin(a) * 3 + 0.5), P.xred)
  H.px(t, 9, 10, P.ink)
  H.text(t, tostring(n), 23, 3, P.ink, { s = 2, align = "center" })
  return t
end

local function timer_done()
  local t = bubble(P.mat_g, P.mat_gd)
  local pts = { { 9, 10 }, { 13, 14 }, { 23, 5 } }
  for _, pass in ipairs({ { P.ink, 5 }, { P.white, 3 } }) do
    for i = 1, 2 do
      H.line(t, pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2], pass[1], pass[2])
    end
  end
  return t
end

local tf = {}
for n = 5, 1, -1 do tf[#tf + 1] = { timer(n), "count_" .. n, 1.0 } end
tf[#tf + 1] = { timer_done(), "done", 0.6 }
export(FX, "photo_timer", 32, 24, tf)

------------------------------------------------------------------ camera flash
-- White starburst with a yellow rim, centred between pixels (15.5, 15.5).
-- card/diag = { inner radius, outer radius, half width at the inner end }.
local function flash(core, card, diag)
  local t = H.img(32, 32)
  local function ray(u, v, r)
    if not r then return false end
    u, v = math.abs(u), math.abs(v)
    if u < r[1] or u > r[2] then return false end
    return v <= r[3] * (1 - (u - r[1]) / (r[2] - r[1])) + 0.5
  end
  local k = math.sqrt(0.5)
  for y = 0, 31 do
    for x = 0, 31 do
      local dx, dy = x - 15.5, y - 15.5
      local u, v = (dx + dy) * k, (dx - dy) * k
      if math.abs(dx) + math.abs(dy) <= core or ray(dx, dy, card) or ray(dy, dx, card) or
        ray(u, v, diag) or ray(v, u, diag) then
        t:drawPixel(x, y, P.white)
      end
    end
  end
  A.outline(t, P.yellow, false)
  return t
end

export(FX, "camera_flash", 32, 32, {
  { flash(3, { 0, 7, 1.2 }, { 0, 4.5, 0.8 }), "flash_0", 0.04 },
  { flash(5.5, { 0, 14.6, 2.4 }, { 0, 11, 1.6 }), "flash_1", 0.06 },
  { flash(2, { 6, 14.6, 1.4 }, { 5.5, 11, 1 }), "flash_2", 0.06 },
  { flash(-1, { 10.5, 14.6, 0.6 }, { 8.5, 11, 0.4 }), "flash_3", 0.06 },
})

------------------------------------------------------------------ review sheet
local PW, PH = 300, 290
local pv = H.img(PW, PH, P.wall)
for x = 0, PW - 1, 16 do H.rect(pv, x, 0, 8, PH, P.wall_l) end

local function row(a, x, y, perRow)
  H.text(pv, (a.name:gsub("_", " ")), x, y, P.base_d)
  y = y + 10
  for i, f in ipairs(a.frames) do
    local col, r = (i - 1) % perRow, (i - 1) // perRow
    local fx, fy = x + col * (a.w + 4), y + r * (a.h + 4)
    H.box(pv, fx - 1, fy - 1, a.w + 2, a.h + 2, P.wall_d, P.base) -- frame bounds
    H.blit(pv, f[1], fx, fy)
  end
end
local by = {}
for _, a in ipairs(assets) do by[a.name] = a end
row(by.lever, 4, 4, 3)
row(by.wall_switch, 120, 4, 2)
row(by.pressure_plate, 204, 4, 2)
row(by.power_arrow, 4, 52, 3)
row(by.photo_timer, 4, 104, 6)
row(by.camera_flash, 4, 144, 4)
-- same flash frames on a dark panel
for i, f in ipairs(by.camera_flash.frames) do
  H.rect(pv, 152 + (i - 1) * 36, 153, 36, 34, P.carpet_d)
  H.blit(pv, f[1], 154 + (i - 1) * 36, 154)
end

-- in-scene scale check next to the player and a package
local FY = 78
local sc = H.img(PW, 100)
H.hallway(sc, FY, 0, PW)
H.rect(sc, 0, 0, PW, 1, P.base)
H.player(sc, 6, FY, 0, 2)
H.package(sc, 60, FY, 0)
H.blit(sc, by.photo_timer.frames[3][1], 60, FY - 54)
H.blit(sc, by.power_arrow.frames[4][1], 90, FY - 22)
H.blit(sc, by.camera_flash.frames[2][1], 96, FY - 70)
H.blit(sc, by.pressure_plate.frames[1][1], 160, FY - 16)
H.blit(sc, by.pressure_plate.frames[2][1], 196, FY - 16)
H.package(sc, 196, FY - 7, 0)
H.blit(sc, by.lever.frames[1][1], 150, FY - 64)
H.blit(sc, by.lever.frames[3][1], 184, FY - 64)
H.blit(sc, by.wall_switch.frames[1][1], 222, FY - 70)
H.blit(sc, by.wall_switch.frames[2][1], 232, FY - 34)
H.blit(pv, sc, 0, PH - 100)

local S = 4
local big = H.img(PW * S, PH * S)
for y = 0, PH - 1 do
  for x = 0, PW - 1 do big:clear(Rectangle(x * S, y * S, S, S), pv:getPixel(x, y)) end
end
big:saveAs(REVIEW .. "interactables_preview.png")
print("saved interactables_preview " .. big.width .. "x" .. big.height)
