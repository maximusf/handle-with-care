dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P

local function scene(with_title)
  local im = H.img(240, 135)
  local F = 118
  H.hallway(im, F)
  H.lamp(im, 118, 8)
  H.door(im, 196, F, 214)
  H.mat(im, 176, F, "done", 44)

  -- kick motion lines ahead of the foot
  H.line(im, 50, 99, 56, 96, P.white)
  H.line(im, 51, 104, 58, 104, P.white)
  H.line(im, 50, 109, 56, 112, P.white)
  H.player(im, 2, F, 17, 3)

  -- flight path from the foot, over the package, down onto the mat
  H.arc(im, 58, 100, 196, 116, 46, P.white, 7, 2)
  H.package(im, 106, 84, 1)

  if with_title then
    H.title(im, 124, 4)
  end
  return im
end

H.save(scene(true), "01_capsule_art", 8)
H.save(scene(false), "art_main_menu_bg", 8)
