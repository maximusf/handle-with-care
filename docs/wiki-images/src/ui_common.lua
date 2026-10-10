-- Local helpers for the interface mockups (08-11 and the menu/overlay art).
-- Loaded after hwc.lua; never modifies H.
local P = H.P
local pc = app.pixelColor
U = {}

-- Text-free gameplay backdrop scaled to any canvas: hallway, door 214, mat.
-- opts: kick (courier mid-kick + flying package), mat ("done"/"wait"/"none"),
-- matpkg (package state resting on the mat), player (false hides the courier)
function U.scene(w, h, o)
  o = o or {}
  local im = H.img(w, h)
  local F = h - 17
  H.hallway(im, F)
  H.lamp(im, w // 2 - 2, 8)
  local dx = w - 44
  H.door(im, dx, F, 214)
  H.mat(im, dx - 20, F, o.mat or "done", 44)
  if o.matpkg then H.package(im, dx - 12, F + 3, o.matpkg) end
  if o.kick ~= false then
    H.line(im, 50, F - 19, 56, F - 22, P.white)
    H.line(im, 51, F - 14, 58, F - 14, P.white)
    H.line(im, 50, F - 9, 56, F - 6, P.white)
    H.player(im, 2, F, 17, 3)
    H.arc(im, 58, F - 18, dx, F - 2, 46, P.white, 7, 2)
    if not o.nofly then H.package(im, 106, F - 34, 1) end
  end
  return im
end

-- 3x3 box blur, for the soft menu backdrop.
function U.blur(im, passes)
  for _ = 1, passes or 1 do
    local src = im:clone()
    for y = 0, im.height - 1 do
      for x = 0, im.width - 1 do
        local r, g, b, n = 0, 0, 0, 0
        for j = -1, 1 do for i = -1, 1 do
          local xx, yy = x + i, y + j
          if xx >= 0 and yy >= 0 and xx < im.width and yy < im.height then
            local p = src:getPixel(xx, yy)
            r, g, b, n = r + pc.rgbaR(p), g + pc.rgbaG(p), b + pc.rgbaB(p), n + 1
          end
        end end
        im:drawPixel(x, y, pc.rgba(r // n, g // n, b // n, 255))
      end
    end
  end
  return im
end

-- 16px package icon (2x downsample of the 32px sprite) with ink + white outline.
local function lum(p) return (pc.rgbaR(p) * 3 + pc.rgbaG(p) * 6 + pc.rgbaB(p)) / 10 end
function U.minipkg(im, x, y, state, ring)
  local names = { intact = "package/package_intact.png", damaged = "package/package_damaged.png",
    destroyed = "package/package_destroyed.png" }
  local src = H.load(names[state or "intact"])
  local cells, mask = {}, {}
  for j = 0, 15 do
    for i = 0, 15 do
      local best, n = nil, 0
      for b = 0, 1 do for a = 0, 1 do
        local p = src:getPixel(i * 2 + a, j * 2 + b)
        if pc.rgbaA(p) > 0 then
          n = n + 1
          if not best or lum(p) < 60 and lum(p) < lum(best) then best = p end
        end
      end end
      if n >= 2 then cells[j * 16 + i] = best; mask[j * 16 + i] = true end
    end
  end
  local function dil(r, c)
    for j = 0, 15 do for i = 0, 15 do
      if mask[j * 16 + i] then
        for b = -r, r do for a = -r, r do H.px(im, x + i + a, y + j + b, c) end end
      end
    end end
  end
  dil(2, P.ink)
  dil(1, ring or P.white)
  for j = 0, 15 do for i = 0, 15 do
    local p = cells[j * 16 + i]
    if p then H.px(im, x + i, y + j, p) end
  end end
end

-- Translucent HUD box: dark fill blended over the scene, ink border.
function U.glass(im, x, y, w, h, a)
  H.shade(im, x + 1, y + 1, w - 2, h - 2, P.ui, a or 0.72)
  H.rect(im, x + 1, y, w - 2, 1, P.ink)
  H.rect(im, x + 1, y + h - 1, w - 2, 1, P.ink)
  H.rect(im, x, y + 1, 1, h - 2, P.ink)
  H.rect(im, x + w - 1, y + 1, 1, h - 2, P.ink)
end

-- Confetti burst: pieces thrown outward from (cx,cy) along rays.
function U.burst(im, cx, cy, n, rmin, rmax, seed)
  math.randomseed(seed or 3)
  local cols = { P.red, P.yellow, P.mat_g, P.blue, P.purple, P.orange, P.white }
  for _ = 1, n do
    local a = math.random() * math.pi * 2
    local r = rmin + math.random() * (rmax - rmin)
    local x, y = cx + math.floor(math.cos(a) * r * 1.6), cy + math.floor(math.sin(a) * r)
    local c = cols[math.random(1, #cols)]
    if math.random() < 0.5 then H.rect(im, x, y, 3, 2, c) else H.rect(im, x, y, 2, 3, c) end
  end
end

-- Ribbon banner with notched tails, spanning x..x+w, height h.
function U.banner(im, x, y, w, h, fill, dark)
  -- tails
  -- tails: rows of a swallowtail, notch depth shrinks away from the middle row
  local half = h // 2
  for r = 0, h - 1 do
    local notch = math.max(0, 7 - math.abs(r - half) * 7 // half)
    local len = 18 - notch
    local yy = y + 6 + r
    local edge = (r == 0 or r == h - 1)
    H.rect(im, x - len, yy, len, 1, edge and P.ink or dark)
    H.px(im, x - len, yy, P.ink)
    H.rect(im, x + w, yy, len, 1, edge and P.ink or dark)
    H.px(im, x + w + len - 1, yy, P.ink)
  end
  H.rect(im, x + 2, y + h, w, 2, P.ink)
  H.box(im, x, y, w, h, fill, P.ink)
  H.rect(im, x + 1, y + 1, w - 2, 2, dark == P.green_d and P.mat_g or P.door_l)
  H.rect(im, x + 1, y + h - 3, w - 2, 2, dark)
end

-- Filled triangle via scanlines (solid arrowheads at any angle).
function U.tri(im, x1, y1, x2, y2, x3, y3, c)
  local ys = { y1, y2, y3 }
  for y = math.floor(math.min(y1, y2, y3)), math.ceil(math.max(y1, y2, y3)) do
    local xs = {}
    local pts = { { x1, y1 }, { x2, y2 }, { x3, y3 } }
    for i = 1, 3 do
      local a, b = pts[i], pts[i % 3 + 1]
      if (a[2] <= y and b[2] > y) or (b[2] <= y and a[2] > y) then
        xs[#xs + 1] = a[1] + (y - a[2]) * (b[1] - a[1]) / (b[2] - a[2])
      end
    end
    if #xs >= 2 then
      local l, r = math.min(xs[1], xs[2]), math.max(xs[1], xs[2])
      H.rect(im, math.floor(l + 0.5), y, math.floor(r + 0.5) - math.floor(l + 0.5) + 1, 1, c)
    end
  end
end

-- Charged aim arrow like H.aim but with a solid outlined head.
function U.aim(im, x, y, a, len, charge)
  local ca, sa = math.cos(a), math.sin(a)
  for i = 0, 4 do
    local t0, t1 = (i + 0.15) / 5, (i + 0.85) / 5
    local c = i < charge and ({ P.mat_g, P.mat_g, P.yellow, P.orange, P.xred })[i + 1] or P.white
    local x0, y0 = math.floor(x + ca * len * t0), math.floor(y + sa * len * t0)
    local x1, y1 = math.floor(x + ca * len * t1), math.floor(y + sa * len * t1)
    H.line(im, x0, y0, x1, y1, P.ink, 5)
    H.line(im, x0, y0, x1, y1, c, 3)
  end
  local function head(ext, back, wid, c)
    local tx, ty = x + ca * (len + ext), y + sa * (len + ext)
    local bx, by = tx - ca * back, ty - sa * back
    U.tri(im, tx, ty, bx - sa * wid, by + ca * wid, bx + sa * wid, by - ca * wid, c)
  end
  head(14, 14, 8, P.ink)
  head(11, 10, 5, P.white)
end

return U
