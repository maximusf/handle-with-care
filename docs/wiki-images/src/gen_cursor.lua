-- Mouse cursor (white arrow with ink outline, like the menu mock).
-- Run from the project root:
--   aseprite -b --script-param root="$PWD/" --script docs/wiki-images/src/gen_cursor.lua
-- Writes cursor.aseprite + cursor.png (1x source) and cursor_2x.png (what the game uses,
-- since Godot shows custom cursors at their real pixel size).

local root = app.params["root"] or ""
local pc = app.pixelColor
local INK = pc.rgba(8, 8, 8, 255)
local WHITE = pc.rgba(250, 250, 250, 255)
local SHADE = pc.rgba(167, 167, 162, 255)

local rows = {
  "#...........",
  "##..........",
  "#w#.........",
  "#ww#........",
  "#www#.......",
  "#wwww#......",
  "#wwwww#.....",
  "#wwwwww#....",
  "#wwwwwww#...",
  "#wwwwwwww#..",
  "#wwwwww####.",
  "#www#ss#....",
  "#ww#.#ss#...",
  "#w#..#ss#...",
  "##....#ss#..",
  "......####..",
}
local colours = { ["#"] = INK, w = WHITE, s = SHADE }

local image = Image(12, #rows, ColorMode.RGB)
for y, row in ipairs(rows) do
  for x = 1, #row do
    local colour = colours[row:sub(x, x)]
    if colour then image:drawPixel(x - 1, y - 1, colour) end
  end
end

local sprite = Sprite(image.width, image.height, ColorMode.RGB)
sprite.cels[1].image = image
local base = root .. "assets/ui/cursor"
sprite:saveAs(base .. ".aseprite")
sprite:saveCopyAs(base .. ".png")
sprite:resize(image.width * 2, image.height * 2)
sprite:saveCopyAs(base .. "_2x.png")
sprite:close()
print("saved " .. base .. " (1x and 2x)")
