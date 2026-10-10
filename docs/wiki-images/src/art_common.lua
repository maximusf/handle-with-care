-- Shared bits for the Art List cards (tiles, sprites, hazards).
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P

A = {}
A.SPRITES = H.OUT .. "sprites/"

-- Wrapped pixel write so tile patterns stay seamless.
function A.tp(t, x, y, c)
  t:drawPixel(x % t.width, y % t.height, c)
end

function A.tile(fn)
  local t = H.img(32, 32)
  fn(t)
  return t
end

function A.tiled(im, t, x, y, nx, ny, s)
  s = s or 1
  for j = 0, ny - 1 do
    for i = 0, nx - 1 do
      H.blit(im, t, x + i * t.width * s, y + j * t.height * s, 0, 0, t.width, t.height, false, s)
    end
  end
end

-- Bare block of tiles for the Art List: 4 across, one tile image per row, no label or frame.
function A.tilecard(name, rows)
  local im = H.img(128, #rows * 32)
  for r, t in ipairs(rows) do A.tiled(im, t, 0, (r - 1) * 32, 4, 1) end
  H.save(im, name, 8)
  return im
end

-- Raw game-ready sprite: .aseprite + .png at 1x with transparency.
function A.raw(im, name)
  local spr = Sprite(im.width, im.height, ColorMode.RGB)
  spr.cels[1].image = im
  spr.layers[1].name = "Art"
  spr:saveAs(A.SPRITES .. name .. ".aseprite")
  spr:saveCopyAs(A.SPRITES .. name .. ".png")
  spr:close()
  print("raw " .. name .. " " .. im.width .. "x" .. im.height)
end

-- Ink outline around every opaque pixel (4-neighbour, or 8 with diag).
function A.outline(t, c, diag)
  local pc = app.pixelColor
  local add = {}
  for y = 0, t.height - 1 do
    for x = 0, t.width - 1 do
      if pc.rgbaA(t:getPixel(x, y)) == 0 then
        local hit = false
        for dy = -1, 1 do
          for dx = -1, 1 do
            if (dx ~= 0 or dy ~= 0) and (diag or dx == 0 or dy == 0) then
              local nx, ny = x + dx, y + dy
              if nx >= 0 and ny >= 0 and nx < t.width and ny < t.height and
                pc.rgbaA(t:getPixel(nx, ny)) > 0 then hit = true end
            end
          end
        end
        if hit then add[#add + 1] = { x, y } end
      end
    end
  end
  for _, p in ipairs(add) do t:drawPixel(p[1], p[2], c) end
end

return A
