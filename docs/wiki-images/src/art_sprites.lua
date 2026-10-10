-- Art List sprites: package states, check/X icons, spikes.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
local P = H.P
local pc = app.pixelColor

------------------------------------------------------------------ packages
-- Art List images are the bare sprite on transparency: no label, frame or shadow.
local function pkgcard(name, file)
  local im = H.img(32, 32)
  H.blit(im, H.load("package/" .. file), 0, 0, 0, 0, 32, 32)
  H.save(im, name, 12)
end
pkgcard("art_package_damaged", "package_damaged.png")
pkgcard("art_package_destroyed", "package_destroyed.png")

------------------------------------------------------------------ icons
-- Thick 3px stroke through pts, ink outline, then top light / bottom shade.
local function icon(segs, base, dark, light)
  local t = H.img(16, 16)
  for _, s in ipairs(segs) do H.line(t, s[1], s[2], s[3], s[4], base, 3) end
  local fill = {}
  for y = 0, 15 do for x = 0, 15 do fill[y * 16 + x] = pc.rgbaA(t:getPixel(x, y)) > 0 end end
  local function f(x, y) return x >= 0 and y >= 0 and x < 16 and y < 16 and fill[y * 16 + x] end
  for y = 0, 15 do
    for x = 0, 15 do
      if f(x, y) then
        if not f(x, y + 1) then t:drawPixel(x, y, dark)
        elseif not f(x, y - 1) then t:drawPixel(x, y, light) end
      end
    end
  end
  A.outline(t, P.ink, true)
  return t
end

local check = icon({ { 3, 8, 6, 11 }, { 6, 11, 12, 5 } }, P.green, P.green_d, H.c("7ef08a"))
local xmark = icon({ { 3, 3, 12, 12 }, { 12, 3, 3, 12 } }, P.xred, P.red_d, H.c("ff8a8e"))
A.raw(check, "checkmark_16")
A.raw(xmark, "xmark_16")

H.save(check, "art_checkmark", 16)
H.save(xmark, "art_xmark", 16)

------------------------------------------------------------------ spikes
local STEEL_L, STEEL = H.c("e4e6ea"), H.c("a9adb5")
local floor = H.img(32, 16)
for i = 0, 3 do
  -- odd widths around a 1px tip so the points stay sharp
  local cx = i * 8 + 4
  local widths = { 1, 1, 1, 3, 3, 3, 5, 5, 5, 7, 7 }
  for r, w in ipairs(widths) do
    local y = r
    for x = cx - w // 2, cx + w // 2 do
      local c = STEEL
      if x < cx then c = STEEL_L elseif x == cx then c = P.white end
      floor:drawPixel(x, y, c)
    end
  end
end
A.outline(floor, P.ink, false)
H.box(floor, 0, 12, 32, 4, P.asphalt, P.ink)
H.rect(floor, 1, 13, 30, 1, P.gray)
for x = 3, 31, 8 do floor:drawPixel(x, 14, P.asphalt_d) end

-- wall variant: rotate 90 degrees so spikes point right, plate on the left
local wall = H.img(16, 32)
for y = 0, 15 do
  for x = 0, 31 do
    wall:drawPixel(15 - y, x, floor:getPixel(x, y))
  end
end
A.raw(floor, "spikes_floor_32x16")
A.raw(wall, "spikes_wall_16x32")

local im = H.img(56, 32)
H.blit(im, floor, 0, 16)
H.blit(im, wall, 40, 0)
H.save(im, "art_spikes", 8)
