dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local MOCK = H.ROOT .. "docs/art-options/screens/"

-- Win and lose screens side by side, from the approved mocks.
local im = H.img(960, 270)
H.blit(im, Image { fromFile = MOCK .. "mock_win_a2.png" }, 0, 0)
H.blit(im, Image { fromFile = MOCK .. "mock_lose_a2.png" }, 480, 0)
H.save(im, "11_win_lose", 2)
