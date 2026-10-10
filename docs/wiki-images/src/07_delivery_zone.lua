dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P
dofile(H.SRC .. "arrows_local.lua")

local im = H.img(320, 135)
local F = 118
H.hallway(im, F)

local nums = { 301, 302, 303 }
local mats = { "none", "wait", "done" }
for i = 1, 3 do
  local cx = 53 + (i - 1) * 106
  H.door(im, cx - 18, F, nums[i])
  H.mat(im, cx - 29, F, mats[i], 52)
end

-- stage 1: package flying in toward the mat
H.arc(im, 2, 70, 44, 104, 18, P.white, 6, 2)
H.package(im, 34, 112, 0)

-- stage 2: landed on yellow mat, timer counting down
H.package(im, 159 - 16, F + 3, 1)
H.timer(im, 155, 92, 3)

-- stage 3: photo taken, mat green
H.package(im, 265 - 16, F + 3, 1)
H.camera_flash(im, 290, 72)
H.check(im, 254, 72, 2)

-- chevrons between stages
for _, x in ipairs({ 100, 206 }) do
  A_arrow(im, x, 96, x + 14, 96)
end

H.tag(im, "LAND ON MAT", 53, 123, P.white, P.ui, "center")
H.tag(im, "HOLD 5 SEC", 159, 123, P.white, P.ui, "center")
H.tag(im, "DELIVERED!", 265, 123, P.white, P.ui, "center")

H.save(im, "07_delivery_zone", 6)
