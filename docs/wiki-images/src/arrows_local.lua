-- Filled-triangle arrows for the mechanics scenes (hwc.lua stays untouched).
-- Loaded after hwc.lua; defines globals A_tri, A_arrow, A_aim.
local P = H.P

local function sgn(ax, ay, bx, by, cx, cy) return (ax - cx) * (by - cy) - (bx - cx) * (ay - cy) end

function A_tri(im, x1, y1, x2, y2, x3, y3, c)
  local minx, maxx = math.floor(math.min(x1, x2, x3)), math.ceil(math.max(x1, x2, x3))
  local miny, maxy = math.floor(math.min(y1, y2, y3)), math.ceil(math.max(y1, y2, y3))
  for y = miny, maxy do
    for x = minx, maxx do
      local px, py = x + 0.5, y + 0.5
      local d1, d2, d3 = sgn(px, py, x1, y1, x2, y2), sgn(px, py, x2, y2, x3, y3), sgn(px, py, x3, y3, x1, y1)
      local neg = d1 < 0 or d2 < 0 or d3 < 0
      local pos = d1 > 0 or d2 > 0 or d3 > 0
      if not (neg and pos) then H.px(im, x, y, c) end
    end
  end
end

-- head with tip at (tx,ty) pointing along (dx,dy): length l, half width w
function A_head(im, tx, ty, dx, dy, l, w, c)
  local n = math.sqrt(dx * dx + dy * dy); dx, dy = dx / n, dy / n
  local bx, by = tx - dx * l, ty - dy * l
  A_tri(im, tx, ty, bx - dy * w, by + dx * w, bx + dy * w, by - dx * w, c)
end

-- outlined white arrow from (x0,y0) to tip (x1,y1)
function A_arrow(im, x0, y0, x1, y1, fill)
  fill = fill or P.white
  local dx, dy = x1 - x0, y1 - y0
  local n = math.sqrt(dx * dx + dy * dy)
  local ux, uy = dx / n, dy / n
  local sx, sy = math.floor(x1 - ux * 6 + 0.5), math.floor(y1 - uy * 6 + 0.5)
  H.line(im, x0, y0, sx, sy, P.ink, 4)
  A_head(im, x1 + ux * 2, y1 + uy * 2, ux, uy, 10, 7, P.ink)
  H.line(im, x0, y0, sx, sy, fill, 2)
  A_head(im, x1, y1, ux, uy, 7, 4.5, fill)
end
