dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P

-- Just the courier on the wallpaper backdrop.
local im = H.img(160, 135, P.wall_l)
for y = 0, 134, 6 do
  for x = (y // 6 % 2) * 6, 159, 12 do H.px(im, x, y, P.wall) end
end
H.rect(im, 0, 128, 160, 7, P.wall_d)
H.rect(im, 0, 128, 160, 1, P.base)

H.player(im, 32, 132, 0, 2, false, 2)

H.save(im, "12_courier", 8)
