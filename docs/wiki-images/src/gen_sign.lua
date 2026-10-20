-- Tutorial sign prop and the "E" key prompt.
-- Run from the project root:
--   aseprite -b --script-param root="$PWD/" --script docs/wiki-images/src/gen_sign.lua
-- Writes .aseprite sources and .png files next to the other props / HUD keys.

local root = app.params["root"] or ""
local pc = app.pixelColor

local function c(hex)
  return pc.rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255)
end

-- Same colours as hwc.lua
local INK = c("080808")
local WHITE = c("fafafa")
local KEY_SHADE = c("a7a7a2")
local CREAM = c("fff1d8")
local WOOD = c("6b3f2c")
local WOOD_DARK = c("4a2a1d")
local FRAME = c("5a3324")
local GOLD = c("f2c14e")
local TEXT_LINE = c("787b7e")

-- Draws a picture written as rows of characters. Each character maps to a colour, "." is transparent.
local function draw_map(image, rows, colours)
  for y, row in ipairs(rows) do
    for x = 1, #row do
      local colour = colours[row:sub(x, x)]
      if colour then image:drawPixel(x - 1, y - 1, colour) end
    end
  end
end

local function save(image, path_without_extension)
  local sprite = Sprite(image.width, image.height, ColorMode.RGB)
  sprite.cels[1].image = image
  sprite:saveAs(path_without_extension .. ".aseprite")
  sprite:saveCopyAs(path_without_extension .. ".png")
  sprite:close()
  print("saved " .. path_without_extension .. " " .. image.width .. "x" .. image.height)
end

------------------------------------------------------------------ sign (24x30)
-- A lobby placard on a wooden stand: framed cream board, gold rivets, grey "writing".
local sign_rows = {
  "########################",
  "#ffffffffffffffffffffff#",
  "#fg..................gf#",
  "#f....................f#",
  "#f..llllllllllllllll..f#",
  "#f....................f#",
  "#f..llllllllllll......f#",
  "#f....................f#",
  "#f..llllllllllllllll..f#",
  "#f....................f#",
  "#f..llllllll..........f#",
  "#f....................f#",
  "#fg..................gf#",
  "#ffffffffffffffffffffff#",
  "#ffffffffffffffffffffff#",
  "########################",
  "..........#ww#..........",
  "..........#wd#..........",
  "..........#wd#..........",
  "..........#wd#..........",
  "..........#wd#..........",
  "..........#wd#..........",
  "..........#wd#..........",
  "..........#wd#..........",
  "..........#wd#..........",
  "..........#wd#..........",
  "......############......",
  "......#wwwwwwwwww#......",
  "......#dddddddddd#......",
  "......############......",
}
local sign = Image(24, #sign_rows, ColorMode.RGB)
draw_map(sign, sign_rows, {
  ["#"] = INK, f = FRAME, g = GOLD, l = TEXT_LINE, w = WOOD, d = WOOD_DARK,
})
-- Fill the board's cream background (the "." inside the frame).
for y = 2, 12 do
  for x = 2, 21 do
    if sign:getPixel(x, y) == 0 then sign:drawPixel(x, y, CREAM) end
  end
end
save(sign, root .. "assets/sprites/props/tutorial_sign")

------------------------------------------------------------------ E key prompt (12x12)
-- Matches hud_key_r: white keycap, grey bottom edge, ink outline and letter.
local key_rows = {
  ".##########.",
  "#wwwwwwwwww#",
  "#www####www#",
  "#www#wwwwww#",
  "#www#wwwwww#",
  "#www###wwww#",
  "#www#wwwwww#",
  "#www#wwwwww#",
  "#www####www#",
  "#ssssssssss#",
  "#ssssssssss#",
  ".##########.",
}
local key = Image(12, 12, ColorMode.RGB)
draw_map(key, key_rows, { ["#"] = INK, w = WHITE, s = KEY_SHADE })
save(key, root .. "assets/ui/screens/hud_key_e")
