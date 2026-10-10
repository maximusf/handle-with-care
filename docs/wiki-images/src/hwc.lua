-- Shared drawing helpers for the Handle With Care wiki art.
-- Scenes draw into a low-res Image in memory, then H.save writes the
-- .aseprite source next to this file and a nearest-neighbor PNG to ../

H = {}
H.ROOT = "G:/System2/Documents/Game Dev Projects/parcel-runner/"
H.SPR = H.ROOT .. "assets/sprites/"
H.SRC = H.ROOT .. "docs/wiki-images/src/"
H.OUT = H.ROOT .. "docs/wiki-images/"

local pc = app.pixelColor

function H.c(hex, a)
  hex = hex:gsub("#", "")
  return pc.rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16),
    tonumber(hex:sub(5, 6), 16), a or 255)
end

-- Palette pulled from the shipped sprites, plus scene colors.
H.P = {
  ink = H.c("080808"), box_ink = H.c("170d07"), white = H.c("fafafa"),
  red = H.c("ff3538"), red_d = H.c("bc292c"), blue = H.c("00acf0"),
  cap = H.c("af806b"), cap_d = H.c("89624f"), gray = H.c("787b7e"),
  card = H.c("ecaf56"), card_m = H.c("c18440"), card_d = H.c("a96b32"),
  card_dd = H.c("71431e"), tape = H.c("e1d3b6"), cream = H.c("fff1d8"),
  wall = H.c("dcc08f"), wall_d = H.c("c9a877"), wall_l = H.c("e8d0a4"),
  base = H.c("6b3f2c"), base_d = H.c("4a2a1d"),
  carpet = H.c("8c1a2b"), carpet_d = H.c("6e1220"), carpet_l = H.c("a3263a"),
  door = H.c("a8202c"), door_d = H.c("7a1520"), door_l = H.c("c33a43"),
  frame = H.c("5a3324"), gold = H.c("f2c14e"), gold_d = H.c("b8862b"),
  mat_g = H.c("3ddc4b"), mat_gd = H.c("1f9a2e"), mat_y = H.c("f5d547"),
  mat_yd = H.c("c9a51c"), mat_n = H.c("8a8f96"), mat_nd = H.c("5d6168"),
  sky = H.c("8fd3ff"), sky_l = H.c("c4ebff"), grass = H.c("4caf3a"),
  grass_d = H.c("2e7d24"), dirt = H.c("8a5a36"), dirt_d = H.c("5e3b22"),
  concrete = H.c("a7a7a2"), concrete_d = H.c("84847f"), concrete_l = H.c("c3c3bd"),
  asphalt = H.c("4b4d52"), asphalt_d = H.c("3a3c40"), stripe = H.c("f2e14a"),
  water = H.c("4aa8e8"), water_l = H.c("9ad8ff"), water_d = H.c("2f78b8"),
  tile = H.c("e6e0d2"), tile_d = H.c("c9c1ae"), marble = H.c("f1ece2"),
  green = H.c("2ecc40"), green_d = H.c("1a8a28"), xred = H.c("e8323a"),
  ui = H.c("1c1a24"), ui_l = H.c("2e2a3a"), ui_ll = H.c("4a4560"),
  yellow = H.c("ffd23f"), orange = H.c("f08a24"), purple = H.c("7b4bc4"),
  none = pc.rgba(0, 0, 0, 0),
}
local P = H.P

function H.img(w, h, col)
  local im = Image(w, h, ColorMode.RGB)
  if col then im:clear(Rectangle(0, 0, w, h), col) end
  return im
end

local function inb(im, x, y) return x >= 0 and y >= 0 and x < im.width and y < im.height end

function H.px(im, x, y, c)
  if inb(im, x, y) then im:drawPixel(x, y, c) end
end

-- Alpha-blend c over the existing pixel with strength a (0..1).
function H.blendpx(im, x, y, c, a)
  if not inb(im, x, y) then return end
  local d = im:getPixel(x, y)
  local function m(s, t) return math.floor(s * a + t * (1 - a) + 0.5) end
  im:drawPixel(x, y, pc.rgba(m(pc.rgbaR(c), pc.rgbaR(d)), m(pc.rgbaG(c), pc.rgbaG(d)),
    m(pc.rgbaB(c), pc.rgbaB(d)), 255))
end

function H.rect(im, x, y, w, h, c)
  if w <= 0 or h <= 0 then return end
  local x0, y0 = math.max(0, x), math.max(0, y)
  local x1, y1 = math.min(im.width, x + w), math.min(im.height, y + h)
  if x1 > x0 and y1 > y0 then im:clear(Rectangle(x0, y0, x1 - x0, y1 - y0), c) end
end

function H.shade(im, x, y, w, h, c, a)
  for j = y, y + h - 1 do for i = x, x + w - 1 do H.blendpx(im, i, j, c, a) end end
end

function H.box(im, x, y, w, h, fill, line, t)
  t = t or 1
  H.rect(im, x, y, w, h, line)
  H.rect(im, x + t, y + t, w - 2 * t, h - 2 * t, fill)
end

function H.line(im, x0, y0, x1, y1, c, t)
  t = t or 1
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    H.rect(im, x0 - (t - 1) // 2, y0 - (t - 1) // 2, t, t, c)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end

function H.ellipse(im, cx, cy, rx, ry, fill, line)
  for y = -ry, ry do
    for x = -rx, rx do
      local v = (x * x) / (rx * rx + 0.3) + (y * y) / (ry * ry + 0.3)
      if v <= 1 then
        local edge = line and ((x - 1) ^ 2 / (rx * rx + 0.3) + y * y / (ry * ry + 0.3) > 1 or
          (x + 1) ^ 2 / (rx * rx + 0.3) + y * y / (ry * ry + 0.3) > 1 or
          x * x / (rx * rx + 0.3) + (y - 1) ^ 2 / (ry * ry + 0.3) > 1 or
          x * x / (rx * rx + 0.3) + (y + 1) ^ 2 / (ry * ry + 0.3) > 1)
        H.px(im, cx + x, cy + y, edge and line or fill)
      end
    end
  end
end

-- Dotted trajectory: parabola from (x0,y0) to (x1,y1) peaking `lift` px above.
function H.arc(im, x0, y0, x1, y1, lift, c, step, sz)
  step, sz = step or 8, sz or 2
  local n = math.floor(math.abs(x1 - x0) / step)
  for i = 0, n do
    local t = i / n
    local x = x0 + (x1 - x0) * t
    local y = y0 + (y1 - y0) * t - 4 * lift * t * (1 - t)
    H.rect(im, math.floor(x), math.floor(y), sz, sz, c)
  end
end

function H.arrowhead(im, x, y, dx, dy, c, s)
  s = s or 4
  local l = math.sqrt(dx * dx + dy * dy); dx, dy = dx / l, dy / l
  for i = 0, s do
    local w = s - i
    local bx, by = x - dx * i, y - dy * i
    H.line(im, math.floor(bx - dy * w + 0.5), math.floor(by + dx * w + 0.5),
      math.floor(bx + dy * w + 0.5), math.floor(by - dx * w + 0.5), c)
  end
end

function H.arrow(im, x0, y0, x1, y1, c, t, head)
  H.line(im, x0, y0, x1, y1, c, t or 1)
  H.arrowhead(im, x1, y1, x1 - x0, y1 - y0, c, head or 4)
end

------------------------------------------------------------------ sprites

H.cache = {}
function H.load(rel)
  if not H.cache[rel] then H.cache[rel] = Image { fromFile = H.SPR .. rel } end
  return H.cache[rel]
end

-- Copy opaque pixels of a sub-rect of src onto im at (x,y), optional flip/scale.
function H.blit(im, src, x, y, sx, sy, sw, sh, flip, s)
  sx, sy, sw, sh, s = sx or 0, sy or 0, sw or src.width, sh or src.height, s or 1
  for j = 0, sh - 1 do
    for i = 0, sw - 1 do
      local p = src:getPixel(sx + i, sy + j)
      local a = pc.rgbaA(p)
      if a > 0 then
        local di = flip and (sw - 1 - i) or i
        if s == 1 then H.px(im, x + di, y + j, p)
        else H.rect(im, x + di * s, y + j * s, s, s, p) end
      end
    end
  end
end

-- Silhouette of a sprite region in one color (for outlines/shadows).
function H.silhouette(im, src, x, y, sx, sy, sw, sh, flip, c)
  for j = 0, sh - 1 do
    for i = 0, sw - 1 do
      if pc.rgbaA(src:getPixel(sx + i, sy + j)) > 0 then
        H.px(im, x + (flip and (sw - 1 - i) or i), y + j, c)
      end
    end
  end
end

local NECK = { [0] = 26, 26, 27, 26, 27, 26, 26, 27, 26, 26, 28, 26, 27, 26, 27, 27, 26, 26, 26, 27, 26 }

-- Courier with feet on floorY, left edge at x. body = body frame 0..20,
-- head = head frame 0..9 (2 = aim_forward). s = integer scale.
function H.player(im, x, floorY, body, head, flip, s)
  s = s or 1
  body, head = body or 0, head or 2
  local top = floorY - 64 * s
  local B, Hd = H.load("player/player_body.png"), H.load("player/player_head.png")
  H.blit(im, B, x, top, body * 48, 0, 48, 64, flip, s)
  local oy = (NECK[body] - 26) * s
  H.blit(im, Hd, x, top + oy, head * 48, 0, 48, 64, flip, s)
end

-- Package state 0 intact, 1 damaged, 2 destroyed; bottom at floorY.
function H.package(im, x, floorY, state, s)
  s = s or 1
  local names = { [0] = "package/package_intact.png", "package/package_damaged.png", "package/package_destroyed.png" }
  local src = H.load(names[state or 0])
  -- find lowest opaque row so boxes sit on the floor
  local low = 0
  for j = src.height - 1, 0, -1 do
    for i = 0, src.width - 1 do
      if pc.rgbaA(src:getPixel(i, j)) > 0 then low = j; break end
    end
    if low > 0 then break end
  end
  H.blit(im, src, x, floorY - (low + 1) * s, 0, 0, src.width, src.height, false, s)
end

------------------------------------------------------------------ pixel font

local G = {}
local function g(ch, rows) G[ch] = rows end
g("A", { " ### ", "#   #", "#   #", "#####", "#   #", "#   #", "#   #" })
g("B", { "#### ", "#   #", "#   #", "#### ", "#   #", "#   #", "#### " })
g("C", { " ####", "#    ", "#    ", "#    ", "#    ", "#    ", " ####" })
g("D", { "#### ", "#   #", "#   #", "#   #", "#   #", "#   #", "#### " })
g("E", { "#####", "#    ", "#    ", "#### ", "#    ", "#    ", "#####" })
g("F", { "#####", "#    ", "#    ", "#### ", "#    ", "#    ", "#    " })
g("G", { " ####", "#    ", "#    ", "#  ##", "#   #", "#   #", " ####" })
g("H", { "#   #", "#   #", "#   #", "#####", "#   #", "#   #", "#   #" })
g("I", { "###", " # ", " # ", " # ", " # ", " # ", "###" })
g("J", { "  ###", "   # ", "   # ", "   # ", "#  # ", "#  # ", " ##  " })
g("K", { "#   #", "#  # ", "# #  ", "##   ", "# #  ", "#  # ", "#   #" })
g("L", { "#    ", "#    ", "#    ", "#    ", "#    ", "#    ", "#####" })
g("M", { "#   #", "## ##", "# # #", "# # #", "#   #", "#   #", "#   #" })
g("N", { "#   #", "##  #", "# # #", "#  ##", "#   #", "#   #", "#   #" })
g("O", { " ### ", "#   #", "#   #", "#   #", "#   #", "#   #", " ### " })
g("P", { "#### ", "#   #", "#   #", "#### ", "#    ", "#    ", "#    " })
g("Q", { " ### ", "#   #", "#   #", "#   #", "# # #", "#  # ", " ## #" })
g("R", { "#### ", "#   #", "#   #", "#### ", "# #  ", "#  # ", "#   #" })
g("S", { " ####", "#    ", "#    ", " ### ", "    #", "    #", "#### " })
g("T", { "#####", "  #  ", "  #  ", "  #  ", "  #  ", "  #  ", "  #  " })
g("U", { "#   #", "#   #", "#   #", "#   #", "#   #", "#   #", " ### " })
g("V", { "#   #", "#   #", "#   #", "#   #", "#   #", " # # ", "  #  " })
g("W", { "#   #", "#   #", "#   #", "# # #", "# # #", "## ##", "#   #" })
g("X", { "#   #", "#   #", " # # ", "  #  ", " # # ", "#   #", "#   #" })
g("Y", { "#   #", "#   #", " # # ", "  #  ", "  #  ", "  #  ", "  #  " })
g("Z", { "#####", "    #", "   # ", "  #  ", " #   ", "#    ", "#####" })
g("0", { " ### ", "#   #", "#  ##", "# # #", "##  #", "#   #", " ### " })
g("1", { " # ", "## ", " # ", " # ", " # ", " # ", "###" })
g("2", { " ### ", "#   #", "    #", "   # ", "  #  ", " #   ", "#####" })
g("3", { "#### ", "    #", "    #", " ### ", "    #", "    #", "#### " })
g("4", { "#   #", "#   #", "#   #", "#####", "    #", "    #", "    #" })
g("5", { "#####", "#    ", "#### ", "    #", "    #", "#   #", " ### " })
g("6", { " ### ", "#    ", "#    ", "#### ", "#   #", "#   #", " ### " })
g("7", { "#####", "    #", "   # ", "  #  ", "  #  ", "  #  ", "  #  " })
g("8", { " ### ", "#   #", "#   #", " ### ", "#   #", "#   #", " ### " })
g("9", { " ### ", "#   #", "#   #", " ####", "    #", "    #", " ### " })
g(" ", { "  ", "  ", "  ", "  ", "  ", "  ", "  " })
g(".", { " ", " ", " ", " ", " ", " ", "#" })
g(",", { " ", " ", " ", " ", " ", "#", "#" })
g("!", { "#", "#", "#", "#", "#", " ", "#" })
g("?", { " ### ", "#   #", "    #", "   # ", "  #  ", "     ", "  #  " })
g(":", { " ", " ", "#", " ", " ", "#", " " })
g("-", { "   ", "   ", "   ", "###", "   ", "   ", "   " })
g("+", { "   ", "   ", " # ", "###", " # ", "   ", "   " })
g("=", { "   ", "   ", "###", "   ", "###", "   ", "   " })
g("/", { "    #", "   # ", "   # ", "  #  ", " #   ", " #   ", "#    " })
g("'", { "#", "#", " ", " ", " ", " ", " " })
g('"', { "# #", "# #", "   ", "   ", "   ", "   ", "   " })
g("(", { " #", "# ", "# ", "# ", "# ", "# ", " #" })
g(")", { "# ", " #", " #", " #", " #", " #", "# " })
g(">", { "   ", "#  ", " # ", "  #", " # ", "#  ", "   " })
g("<", { "   ", "  #", " # ", "#  ", " # ", "  #", "   " })
g("%", { "##  #", "##  #", "   # ", "  #  ", " #   ", "#  ##", "#  ##" })
g("#", { " # # ", "#####", " # # ", " # # ", " # # ", "#####", " # # " })

function H.textw(str, s)
  s = s or 1
  local w = 0
  str = str:upper()
  for i = 1, #str do
    local gl = G[str:sub(i, i)] or G["?"]
    w = w + (#gl[1] + 1) * s
  end
  return w - s
end

local function rawtext(im, str, x, y, c, s)
  str = str:upper()
  for i = 1, #str do
    local gl = G[str:sub(i, i)] or G["?"]
    for r = 1, 7 do
      local row = gl[r]
      for k = 1, #row do
        if row:sub(k, k) == "#" then H.rect(im, x + (k - 1) * s, y + (r - 1) * s, s, s, c) end
      end
    end
    x = x + (#gl[1] + 1) * s
  end
end

-- opts: s (scale), outline (color), ot (outline px), shadow (color), sd (shadow depth), align ("left"/"center")
function H.text(im, str, x, y, c, o)
  o = o or {}
  local s = o.s or 1
  if o.align == "center" then x = x - H.textw(str, s) // 2 end
  local sd = o.shadow and (o.sd or s) or 0
  local t = o.outline and (o.ot or 1) or 0
  -- outline wraps the whole extruded shape, then extrusion, then face
  if o.outline then
    for d = 0, sd do
      for dy = -t, t do for dx = -t, t do rawtext(im, str, x + dx + d, y + dy + d, o.outline, s) end end
    end
  end
  for d = sd, 1, -1 do rawtext(im, str, x + d, y + d, o.shadow, s) end
  rawtext(im, str, x, y, c, s)
  return H.textw(str, s)
end

-- Small caption tag: dark rounded label box with text.
function H.tag(im, str, x, y, fg, bg, align)
  local w = H.textw(str, 1) + 6
  if align == "center" then x = x - w // 2 end
  H.rect(im, x + 1, y, w - 2, 11, bg or P.ui)
  H.rect(im, x, y + 1, w, 9, bg or P.ui)
  H.text(im, str, x + 3, y + 2, fg or P.white)
  return w
end

------------------------------------------------------------------ props

-- Hotel hallway backdrop: wall, wainscot, baseboard, carpet from floorY down.
function H.hallway(im, floorY, x0, x1)
  x0, x1 = x0 or 0, x1 or im.width
  local w = x1 - x0
  H.rect(im, x0, 0, w, floorY, P.wall)
  for x = x0, x1 - 1, 24 do H.rect(im, x, 0, 12, floorY - 40, P.wall_l) end
  H.rect(im, x0, floorY - 40, w, 2, P.wall_d)
  H.rect(im, x0, floorY - 38, w, 30, P.wall_d)
  for x = x0 + 4, x1 - 1, 20 do H.box(im, x, floorY - 34, 14, 22, P.wall_d, P.base, 1) end
  H.rect(im, x0, floorY - 8, w, 8, P.base)
  H.rect(im, x0, floorY - 8, w, 1, P.base_d)
  H.rect(im, x0, floorY, w, im.height - floorY, P.carpet)
  for y = floorY + 3, im.height - 1, 6 do
    for x = x0 + ((y // 6) % 2) * 6, x1 - 1, 12 do H.rect(im, x, y, 3, 1, P.carpet_d) end
  end
  H.rect(im, x0, floorY, w, 1, P.carpet_l)
end

function H.lamp(im, x, y)
  H.rect(im, x + 3, y, 2, 8, P.gold_d)
  H.box(im, x, y + 8, 8, 6, P.cream, P.gold_d)
  H.shade(im, x - 6, y + 14, 20, 10, P.cream, 0.25)
end

function H.door(im, x, floorY, num, open)
  local w, h = 36, 70
  local y = floorY - h
  H.rect(im, x - 3, y - 3, w + 6, h + 3, P.frame)
  if open then
    H.rect(im, x, y, w, h, P.ink)
    H.box(im, x, y, 8, h, P.door_d, P.ink)
  else
    H.box(im, x, y, w, h, P.door, P.ink)
    H.box(im, x + 5, y + 6, w - 10, 24, P.door, P.door_d)
    H.box(im, x + 5, y + 36, w - 10, 28, P.door, P.door_d)
    H.rect(im, x + 1, y + 1, w - 2, 1, P.door_l)
    H.box(im, x + w - 8, y + 36, 4, 6, P.gold, P.gold_d)
  end
  if num then
    H.box(im, x + w // 2 - 9, y - 12, 18, 9, P.gold, P.gold_d)
    H.text(im, tostring(num), x + w // 2, y - 11, P.base_d, { align = "center" })
  end
end

-- state: "none", "wait" (yellow), "done" (green)
function H.mat(im, x, floorY, state, w)
  -- flat doormat seen at a slight angle: a 7px parallelogram lying on the floor
  w = w or 34
  local c, d = P.mat_n, P.mat_nd
  if state == "wait" then c, d = P.mat_y, P.mat_yd elseif state == "done" then c, d = P.mat_g, P.mat_gd end
  for j = 0, 6 do
    local off = 6 - j
    H.rect(im, x + off, floorY + j, w, 1, (j == 0 or j == 6) and P.ink or c)
    H.px(im, x + off, floorY + j, P.ink)
    H.px(im, x + off + w - 1, floorY + j, P.ink)
  end
  for j = 2, 4 do
    local off = 6 - j
    H.rect(im, x + off + 3, floorY + j, w - 6, 1, d)
  end
  H.rect(im, x + 5, floorY + 3, w - 8, 1, c)
end

-- Five-second photo timer bubble centered on cx, bottom at y.
function H.timer(im, cx, y, n, col)
  col = col or P.mat_y
  H.ellipse(im, cx, y - 7, 7, 7, P.white, P.ink)
  H.line(im, cx, y - 7, cx, y - 12, P.ink)
  H.line(im, cx, y - 7, cx + 3, y - 7, P.ink)
  H.box(im, cx + 8, y - 12, H.textw(tostring(n), 1) + 6, 11, col, P.ink)
  H.text(im, tostring(n), cx + 11, y - 10, P.ink)
end

function H.camera_flash(im, cx, cy)
  for i = 0, 7 do
    local a = i * math.pi / 4
    H.line(im, cx + math.floor(math.cos(a) * 6), cy + math.floor(math.sin(a) * 6),
      cx + math.floor(math.cos(a) * 11), cy + math.floor(math.sin(a) * 11), P.white)
  end
end

function H.puddle(im, x, floorY, w)
  w = w or 40
  H.ellipse(im, x + w // 2, floorY + 2, w // 2, 3, P.water, P.water_d)
  H.rect(im, x + w // 4, floorY + 1, w // 4, 1, P.water_l)
  H.rect(im, x + w // 2 + 3, floorY + 3, w // 6, 1, P.water_l)
end

-- Props below are blitted from the shipped sprites so concept art matches the game.
local function prop(im, rel, x, floorY, fw)
  local src = H.load(rel)
  H.blit(im, src, x, floorY - src.height, 0, 0, fw or src.width, src.height)
end

function H.wetsign(im, x, floorY) prop(im, "props/wet_floor_sign_a.png", x - 4, floorY) end
function H.vacuum(im, x, floorY) prop(im, "props/robot_vacuum_a.png", x - 6, floorY, 40) end
function H.cactus(im, x, floorY) prop(im, "props/cactus_a.png", x - 4, floorY) end
function H.cart(im, x, floorY) prop(im, "props/housekeeping_cart_a.png", x - 8, floorY, 64) end

function H.window(im, x, y, broken)
  H.box(im, x, y, 34, 40, P.sky, P.frame, 2)
  H.rect(im, x + 16, y + 2, 2, 36, P.frame)
  H.rect(im, x + 2, y + 19, 30, 2, P.frame)
  H.line(im, x + 5, y + 14, x + 12, y + 5, P.sky_l)
  H.line(im, x + 21, y + 34, x + 29, y + 25, P.sky_l)
  if broken then
    H.line(im, x + 8, y + 8, x + 26, y + 30, P.white)
    H.line(im, x + 26, y + 6, x + 10, y + 32, P.white)
    H.line(im, x + 4, y + 20, x + 30, y + 18, P.white)
  end
end

function H.fountain(im, x, floorY) prop(im, "props/fountain_a.png", x - 18, floorY, 96) end

function H.lever(im, x, y, on)
  H.blit(im, H.load("interactables/lever.png"), x - 10, y - 8, on and 64 or 0, 0, 32, 32)
end

function H.plate(im, x, floorY)
  H.blit(im, H.load("interactables/pressure_plate.png"), x - 3, floorY - 16, 0, 0, 32, 16)
end

function H.dolly(im, x, floorY, n)
  n = n or 3
  H.blit(im, H.load("vehicles/dolly.png"), x, floorY - 64, 0, 0, 40, 64)
  for i = 0, n - 1 do
    local src = H.load("package/package_intact.png")
    H.blit(im, src, x + 8, floorY - 2 - (i + 1) * 20 - 6, 0, 0, 32, 32)
  end
end

function H.truck(im, x, floorY)
  -- YEET step van facing left, 192x96, rear toward the right
  H.blit(im, H.load("vehicles/delivery_truck.png"), x - 40, floorY - 96)
end

------------------------------------------------------------------ UI

-- Stretch a sub-rect of src like a Godot StyleBoxTexture: fixed margin m, stretched centre.
function H.nine(im, src, sx, sy, sw, sh, x, y, w, h, m)
  local function map(d, n, sn)
    if d < m then return d end
    if d >= n - m then return sn - (n - d) end
    return m + ((d - m) * (sn - 2 * m)) // (n - 2 * m)
  end
  for j = 0, h - 1 do
    for i = 0, w - 1 do
      local p = src:getPixel(sx + map(i, w, sw), sy + map(j, h, sh))
      if pc.rgbaA(p) > 0 then H.px(im, x + i, y + j, p) end
    end
  end
end

-- UI pieces come from the cardboard kit in assets/ui.
function H.panel(im, x, y, w, h)
  H.nine(im, H.load("../ui/panel.png"), 0, 0, 24, 24, x, y, w, h, 4)
end

function H.button(im, cx, y, label, w, hot)
  w = w or 80
  H.nine(im, H.load("../ui/button.png"), hot and 48 or 0, 0, 48, 20, cx - w // 2, y, w, 20, 4)
  H.text(im, label, cx, y + 6, P.box_ink, { align = "center" })
end

function H.slider(im, x, y, w, v)
  H.nine(im, H.load("../ui/slider_track.png"), 0, 0, 32, 8, x, y, w, 8, 2)
  local k = math.floor((w - 8) * v)
  H.nine(im, H.load("../ui/slider_fill.png"), 0, 0, 32, 8, x, y, k + 4, 8, 2)
  H.blit(im, H.load("../ui/slider_grabber.png"), x + k, y - 2, 0, 0, 8, 12)
end

-- Title logo, centred on cx.
function H.title(im, cx, y)
  local src = H.load("../ui/title_logo.png")
  H.blit(im, src, cx - src.width // 2, y)
end

function H.check(im, x, y, s)
  s = s or 1
  local pts = { { 0, 5 }, { 3, 8 }, { 10, 1 } }
  for i = 1, 2 do
    H.line(im, x + pts[i][1] * s, y + pts[i][2] * s, x + pts[i + 1][1] * s, y + pts[i + 1][2] * s, P.ink, 4 * s)
  end
  for i = 1, 2 do
    H.line(im, x + pts[i][1] * s, y + pts[i][2] * s, x + pts[i + 1][1] * s, y + pts[i + 1][2] * s, P.green, 2 * s)
  end
end

function H.xmark(im, x, y, s)
  s = s or 1
  H.line(im, x, y, x + 9 * s, y + 9 * s, P.ink, 4 * s)
  H.line(im, x + 9 * s, y, x, y + 9 * s, P.ink, 4 * s)
  H.line(im, x, y, x + 9 * s, y + 9 * s, P.xred, 2 * s)
  H.line(im, x + 9 * s, y, x, y + 9 * s, P.xred, 2 * s)
end

-- Mini package icon for the HUD. state: "active", "done", "lost", "wait"
function H.pkgicon(im, x, y, state)
  local src = H.load("package/package_intact.png")
  if state == "lost" then src = H.load("package/package_destroyed.png") end
  if state == "active" then
    H.silhouette(im, src, x - 1, y, 0, 0, 32, 32, false, P.white)
    H.silhouette(im, src, x + 1, y, 0, 0, 32, 32, false, P.white)
    H.silhouette(im, src, x, y - 1, 0, 0, 32, 32, false, P.white)
    H.silhouette(im, src, x, y + 1, 0, 0, 32, 32, false, P.white)
  end
  H.blit(im, src, x, y, 0, 0, 32, 32)
  if state == "done" then H.check(im, x + 16, y + 16) end
  if state == "lost" then H.xmark(im, x + 18, y + 14) end
end

-- Aim arrow with charge segments from (x,y) at angle a (radians, 0 = right, up negative).
function H.aim(im, x, y, a, len, charge)
  local segs = 5
  for i = 0, segs - 1 do
    local t0, t1 = (i + 0.15) / segs, (i + 0.85) / segs
    local c = P.white
    if i < charge then
      c = ({ P.mat_g, P.mat_g, P.yellow, P.orange, P.xred })[i + 1]
    end
    local x0, y0 = x + math.cos(a) * len * t0, y + math.sin(a) * len * t0
    local x1, y1 = x + math.cos(a) * len * t1, y + math.sin(a) * len * t1
    H.line(im, math.floor(x0), math.floor(y0), math.floor(x1), math.floor(y1), P.ink, 5)
    H.line(im, math.floor(x0), math.floor(y0), math.floor(x1), math.floor(y1), c, 3)
  end
  local ex, ey = x + math.cos(a) * (len + 7), y + math.sin(a) * (len + 7)
  H.arrowhead(im, math.floor(ex + math.cos(a) * 2), math.floor(ey + math.sin(a) * 2), math.cos(a), math.sin(a), P.ink, 7)
  H.arrowhead(im, math.floor(ex), math.floor(ey), math.cos(a), math.sin(a), P.white, 5)
end

function H.cursor(im, x, y)
  local rows = { "#", "##", "#.#", "#..#", "#...#", "#....#", "#.....#", "#..####", "#.#", "##" }
  for j, r in ipairs(rows) do
    for i = 1, #r do
      local ch = r:sub(i, i)
      if ch == "#" then H.px(im, x + i - 1, y + j - 1, P.ink) elseif ch == "." then H.px(im, x + i - 1, y + j - 1, P.white) end
    end
  end
end

function H.confetti(im, x0, y0, w, h, n, seed)
  math.randomseed(seed or 7)
  local cols = { P.red, P.yellow, P.mat_g, P.blue, P.purple, P.orange, P.white }
  for i = 1, n do
    local x, y = x0 + math.random(0, w), y0 + math.random(0, h)
    local c = cols[math.random(1, #cols)]
    if math.random() < 0.5 then H.rect(im, x, y, 3, 2, c) else H.rect(im, x, y, 2, 3, c) end
  end
end

------------------------------------------------------------------ save

function H.save(im, name, s)
  s = s or 4
  local spr = Sprite(im.width, im.height, ColorMode.RGB)
  spr.cels[1].image = im
  spr.layers[1].name = "Art"
  spr:saveAs(H.SRC .. name .. ".aseprite")
  local big = Image(im.width * s, im.height * s, ColorMode.RGB)
  for y = 0, im.height - 1 do
    for x = 0, im.width - 1 do
      local p = im:getPixel(x, y)
      if pc.rgbaA(p) > 0 then big:clear(Rectangle(x * s, y * s, s, s), p) end
    end
  end
  big:saveAs(H.OUT .. name .. ".png")
  spr:close()
  print("saved " .. name .. " " .. im.width * s .. "x" .. im.height * s)
end

return H
