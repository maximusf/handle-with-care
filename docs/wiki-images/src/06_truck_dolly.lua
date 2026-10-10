dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P

local im = H.img(240, 135, P.sky)
local F = 118

-- sky, clouds, hedge, curb, asphalt lot
H.rect(im, 0, 0, 240, 24, P.sky_l)
H.shade(im, 0, 24, 240, 8, P.sky_l, 0.5)
for _, c in ipairs({ { 30, 16, 12 }, { 44, 14, 9 }, { 150, 22, 14 }, { 166, 20, 9 } }) do
  H.ellipse(im, c[1], c[2], c[3], 5, P.white)
end
-- hotel back wall on the right
H.rect(im, 176, 30, 64, 66, P.wall)
H.rect(im, 176, 30, 64, 3, P.base)
for x = 184, 232, 18 do
  H.box(im, x, 40, 10, 12, P.sky, P.frame)
  H.box(im, x, 62, 10, 12, P.sky, P.frame)
end
H.rect(im, 0, 84, 176, 12, P.grass)
H.rect(im, 0, 84, 176, 2, P.grass_d)
H.rect(im, 0, 94, 240, 5, P.concrete_l)
H.rect(im, 0, 99, 240, 2, P.concrete_d)
H.rect(im, 0, 101, 240, 34, P.asphalt)
for x = 0, 239, 16 do H.rect(im, x, 101, 1, 34, P.asphalt_d) end
for x = 8, 239, 40 do H.rect(im, x, 126, 22, 2, P.stripe) end

H.truck(im, 18, F)
H.dolly(im, 198, F, 3)
H.player(im, 164, F + 8, 0, 2)

H.tag(im, "LOADING AREA", 4, 4)
H.tag(im, "DOLLY", 218, 24, P.white, P.ui, "center")

H.save(im, "06_truck_dolly", 8)
