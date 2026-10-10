dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P
dofile(H.SRC .. "arrows_local.lua")

-- segmented charge arrow with a solid triangle head
local function aim(im, x, y, a, len, charge)
  local cols = { P.mat_g, P.mat_g, P.yellow, P.orange, P.xred }
  local ca, sa = math.cos(a), math.sin(a)
  for pass = 1, 2 do
    for i = 0, 4 do
      local t0, t1 = (i + 0.1) / 5, (i + 0.9) / 5
      local x0, y0 = math.floor(x + ca * len * t0 + 0.5), math.floor(y + sa * len * t0 + 0.5)
      local x1, y1 = math.floor(x + ca * len * t1 + 0.5), math.floor(y + sa * len * t1 + 0.5)
      if pass == 1 then H.line(im, x0, y0, x1, y1, P.ink, 6)
      else H.line(im, x0, y0, x1, y1, i < charge and cols[i + 1] or P.white, 4) end
    end
  end
  local tx, ty = x + ca * (len + 12), y + sa * (len + 12)
  A_head(im, tx + ca * 2, ty + sa * 2, ca, sa, 12, 8, P.ink)
  A_head(im, tx, ty, ca, sa, 9, 5.5, P.white)
end

local im = H.img(240, 135)
local F = 118
H.hallway(im, F)
H.door(im, 196, F, 108)
H.mat(im, 180, F, "none", 40)

-- predicted flight path from the package to the mat
H.arc(im, 86, 98, 204, 116, 36, P.white, 7, 2)

H.player(im, 22, F, 13, 3)
H.package(im, 68, F, 0)

-- aim arrow toward the cursor, 3 of 5 charge
local a = math.atan(-1.12)
aim(im, 88, 92, a, 40, 3)
H.cursor(im, 126, 40)

H.tag(im, "HOLD LMB TO CHARGE", 4, 4)
H.tag(im, "RELEASE TO KICK", 4, 17)
H.tag(im, "RMB CANCEL", 4, 30)
H.tag(im, "POWER 3/5", 136, 38)

H.save(im, "03_kick", 8)
