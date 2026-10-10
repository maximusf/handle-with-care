dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/hwc.lua")
local P = H.P

local W, RH, F = 320, 88, 68
local im = H.img(W, RH * 3 + 2, P.ink)

local function row()
  local r = H.img(W, RH)
  H.hallway(r, F)
  return r
end
local function label(r, str, cx) H.tag(r, str, cx, F + 7, P.white, P.ui, "center") end

-- row 1: floor hazards
local r1 = row()
H.puddle(r1, 20, F, 40)
H.wetsign(r1, 104, F)
H.puddle(r1, 116, F, 30)
H.vacuum(r1, 186, F)
H.cactus(r1, 272, F)
label(r1, "PUDDLE", 40); label(r1, "WET FLOOR", 122); label(r1, "ROBOT VACUUM", 200); label(r1, "CACTUS", 280)

-- row 2: big set pieces
local r2 = row()
H.fountain(r2, 25, F)
H.cart(r2, 140, F)
H.window(r2, 248, 14, true)
label(r2, "FOUNTAIN", 55); label(r2, "HOUSEKEEPING CART", 164); label(r2, "WINDOW", 265)

-- row 3: spikes and the security laser
local r3 = row()
H.blit(r3, H.load("hazards/spikes_floor_32x16.png"), 24, F - 16)
H.blit(r3, H.load("hazards/spikes_floor_32x16.png"), 56, F - 16)
H.rect(r3, 132, 10, 6, F - 10, P.base_d)
H.blit(r3, H.load("hazards/spikes_wall_16x32.png"), 138, 24)
local L = "interactables/laser/"
H.blit(r3, H.load(L .. "laser_emitter.png"), 190, 30, 32, 0, 16, 16)
for i = 0, 2 do H.blit(r3, H.load(L .. "laser_beam.png"), 206 + i * 32, 30, 0, 0, 32, 16) end
H.blit(r3, H.load(L .. "laser_receiver.png"), 302, 30, 16, 0, 16, 16)
label(r3, "FLOOR SPIKES", 56); label(r3, "WALL SPIKES", 146); label(r3, "LASER", 254)

H.blit(im, r1, 0, 0)
H.blit(im, r2, 0, RH + 1)
H.blit(im, r3, 0, RH * 2 + 2)

H.save(im, "05_hazards", 6)
