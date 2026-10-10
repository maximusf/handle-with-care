-- Courier uniform OPTIONS for the YEET rebrand.
-- Every option is a recolour of the shipped player sheets (same layout, same
-- alpha), so the chosen one can be dropped straight over the originals.
--
-- The hoodie is a rigid shape that only bobs up and down and gets covered by
-- hands and shoes, so trim is defined once in "garment space" (dy, dx measured
-- from the garment's own top-left pixel in each frame) and can never drift.
-- Cap details are placed the same way from the crown's own bounding box.
--
-- Run: Aseprite -b --script opt_uniforms.lua
-- Optional: --script-param debug=<dir> also writes one 4x cell per option there.
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/art_common.lua")
dofile("G:/System2/Documents/Game Dev Projects/parcel-runner/docs/wiki-images/src/yeet_brand.lua")
local pc = app.pixelColor
local P, YP = H.P, Y.P

local SRC = H.SPR .. "player/"
local OUT = H.ROOT .. "docs/art-options/uniforms/"
local REV = H.ROOT .. "docs/art-review/"
app.fs.makeAllDirectories(OUT)

local FW, FH = 48, 64
local SHEETS = { "body", "head", "head_power", "animations" }
local ORIG = {}
for _, s in ipairs(SHEETS) do ORIG[s] = Image { fromFile = SRC .. "player_" .. s .. ".png" } end

-- Colours found in the shipped sheets.
local RED, RED_D = H.c("ff3538"), H.c("bc292c")       -- hoodie fill / fold line
local CAP, CAP_D, BILL = H.c("af806b"), H.c("89624f"), H.c("2d2d2f")
local SHOE, SOLE = H.c("787b7e"), H.c("ffffff")       -- ffffff is also the eye glint

------------------------------------------------------------ garment template

local function garment(p) return p == RED or p == RED_D end

-- Top-left garment pixel of one frame, or nil when the frame has no garment.
local function anchor(im, f)
  for y = 0, FH - 1 do
    for x = 0, FW - 1 do
      if garment(im:getPixel(f * FW + x, y)) then return x, y end
    end
  end
end

-- Union of the garment over all 21 body frames, in garment space.
local T = { rows = {}, bot = {} }
do
  local b = ORIG.body
  for f = 0, b.width // FW - 1 do
    local ax, ay = anchor(b, f)
    for y = 0, FH - 1 do
      for x = 0, FW - 1 do
        local p = b:getPixel(f * FW + x, y)
        if garment(p) then
          local dx, dy = x - ax, y - ay
          local r = T.rows[dy] or { l = dx, r = dx }
          r.l, r.r = math.min(r.l, dx), math.max(r.r, dx)
          if p == RED_D then
            assert(r.sx == nil or r.sx == dx, "fold line moves inside the garment")
            r.sx = dx
          end
          T.rows[dy] = r
          T.bot[dx] = math.max(T.bot[dx] or 0, dy)
        end
      end
    end
  end
end

-- Everything a trim rule may ask about one garment pixel.
local function ginfo(dx, dy)
  local r = T.rows[dy]
  return {
    dx = dx, dy = dy,
    dl = dx - r.l, dr = r.r - dx,           -- distance from back / front edge
    fold = r.sx ~= nil and dx == r.sx,      -- the original shading line
    back = r.sx ~= nil and dx < r.sx,       -- wedge behind the fold: side panel
    below = T.bot[dx] - dy,                 -- garment pixels under this one
  }
end
local function hem(q, n) return q.dy >= 20 and q.below < n end

-- The brand monogram at 1x, sampled so big marks match yeet_brand exactly.
local MONO = H.img(15, 7)
local M_FG, M_AC = H.c("ff00ff"), H.c("00ffff")
Y.mono(MONO, 0, 0, 1, M_FG, M_AC)
local function mono(i, j)
  if i < 0 or j < 0 or i > 14 or j > 6 then return nil end
  local p = MONO:getPixel(i, j)
  if p == M_FG then return "fg" elseif p == M_AC then return "ac" end
end

------------------------------------------------------------------- options

local K, CH, CHL = YP.black, YP.char, YP.char_l
local O, OD, OL = YP.orange, YP.orange_d, YP.orange_l
local W, WD, GY = YP.white, H.c("cfcac0"), YP.gray
local HV, HVD, SILV = H.c("c8f02a"), H.c("93b81a"), H.c("d6dade")
local NV, NVD = H.c("2c3644"), H.c("1c232e")
local BR, BRD, BRK = H.c("7a4f2c"), H.c("5a371c"), H.c("3d2413")
local GOLD = P.gold
local SL, SLD = H.c("4e4e5a"), H.c("34343c")

local OPTS = {
  { code = "a", name = "yeet_black", label = "A YEET BLACK",
    note = "orange panel + collar",
    garment = function(q)
      if q.dy == 0 then return O end
      if q.back then return O end
      if q.fold then return K end
      if q.dy == 6 and q.dr == 2 then return O end
      if q.dy == 6 and q.dr == 3 then return W end
      if q.dr == 0 and q.dy >= 2 then return CHL end
      return CH
    end,
    cap = { crown = CH, seam = K, button = O, y = W, dash = O, bill = CHL },
    shoe = CHL, sole = O },

  { code = "b", name = "yeet_orange", label = "B YEET ORANGE",
    note = "black panel and hem",
    garment = function(q)
      if q.dy == 0 then return CH end
      if hem(q, 2) then return CH end
      if q.back then return CH end
      if q.fold then return K end
      if q.dy == 6 and q.dr == 2 then return W end
      if q.dy == 6 and q.dr == 3 then return CH end
      return O
    end,
    cap = { crown = CH, seam = K, y = O, bill = O, billtop = OL },
    shoe = CH, sole = W },

  { code = "c", name = "yeet_white", label = "C YEET WHITE",
    note = "orange panel, black hem",
    garment = function(q)
      if q.dy == 0 then return CH end
      if hem(q, 1) then return CH end
      if hem(q, 2) then return O end
      if q.back then return O end
      if q.fold then return OD end
      if q.dy == 6 and q.dr == 2 then return O end
      if q.dy == 6 and q.dr == 3 then return CH end
      return W
    end,
    cap = { crown = W, seam = WD, button = CH, y = O, bill = CH },
    shoe = GY, sole = O },

  { code = "d", name = "red_hoodie_yeet_cap", label = "D RED + YEET CAP",
    note = "only the cap changes",
    cap = { crown = CH, seam = K, button = O, y = W, bill = O, billtop = OL } },

  { code = "e", name = "hivis_vest", label = "E HI-VIS VEST",
    note = "vest + reflective tape",
    garment = function(q)
      if q.dy <= 15 then
        if q.dy == 11 or q.dy == 12 then return q.fold and GY or SILV end
        if q.dy >= 1 and q.dy < 11 and (q.dr == 3 or q.dr == 4) then return SILV end
        if q.fold or q.dy == 15 then return HVD end
        return HV
      end
      if q.fold then return NVD end
      return NV
    end,
    cap = { crown = HV, seam = HVD, band = SILV, bill = NV },
    shoe = CHL, sole = GY },

  { code = "f", name = "classic_brown", label = "F CLASSIC BROWN",
    note = "gold buttons and belt",
    garment = function(q)
      if q.dy == 0 then return GOLD end
      if q.dy == 16 then return q.dr == 5 and GOLD or BRK end
      if q.dy < 16 and q.dr == 5 and q.dy % 4 == 3 then return GOLD end
      if q.dy >= 20 and q.below == 1 then return GOLD end
      if q.fold then return BRD end
      return BR
    end,
    cap = { crown = BR, seam = BRD, band = GOLD, button = GOLD, bill = BRK },
    shoe = P.base_d, sole = P.tape },

  { code = "g", name = "charcoal_hoodie", label = "G CHARCOAL HOODIE",
    note = "orange hood and pocket",
    garment = function(q)
      if q.dy <= 1 then return O end
      if q.dy >= 2 and q.dy <= 5 and q.dr == 3 then return W end
      if hem(q, 2) then return SLD end
      if q.dy >= 15 and q.dy <= 19 and not q.back and not q.fold and q.dl >= 7 and q.dr >= 2 then
        return q.dy == 15 and OL or O
      end
      if q.fold then return SLD end
      return SL
    end,
    cap = { crown = O, seam = OD, button = CH, bill = SL },
    shoe = H.c("e8e6e0"), sole = O },

  { code = "h", name = "summer_shorts", label = "H SUMMER SHORTS",
    note = "white tee, orange shorts",
    garment = function(q)
      if q.dy == 0 then return O end
      if q.dy <= 13 then
        if q.fold then return WD end
        if q.dy == 6 and (q.dr == 2 or q.dr == 3) then return O end
        return W
      end
      if q.dy == 14 then return CH end
      if q.back then return W end
      if q.fold or hem(q, 1) then return OD end
      return O
    end,
    cap = { crown = W, seam = WD, button = O, y = O, bill = O, billtop = OL },
    shoe = H.c("c9a36b"), sole = P.base },

  { code = "i", name = "colour_block", label = "I COLOUR BLOCK",
    note = "orange yoke, white piping",
    garment = function(q)
      if q.dy == 0 then return CH end
      if q.dy <= 7 then return q.fold and OD or O end
      if q.dy == 8 then return W end
      if hem(q, 1) then return O end
      if q.back then return CHL end
      if q.fold then return K end
      if q.dr == 0 then return CHL end
      return CH
    end,
    cap = { crown = O, seam = OD, band = CH, y = W, bill = CH },
    shoe = O, sole = W },

  { code = "j", name = "big_y_tee", label = "J BIG Y TEE",
    note = "full Y monogram",
    garment = function(q)
      local m = mono(q.dx + 7, q.dy - 11)
      if m == "fg" then return W elseif m == "ac" then return O end
      if q.dy == 0 then return O end
      if hem(q, 2) then return O end
      if q.fold then return K end
      if q.dr == 0 and q.dy >= 2 then return CHL end
      return CH
    end,
    cap = { crown = CH, seam = K, band = O, y = W, bill = CHL },
    shoe = W, sole = O },
}

------------------------------------------------------------------ recolour

-- Mini Y for the cap front, offsets from the crown's top-left bounding corner.
local CAP_Y = { { 9, 2 }, { 11, 2 }, { 10, 3 }, { 10, 4 } }
local CAP_DASH = { { 6, 3 }, { 7, 3 } }

local function recolour_frame(src, dst, f, opt)
  local ox = f * FW
  local function get(x, y)
    if x < 0 or y < 0 or x >= FW or y >= FH then return 0 end
    return src:getPixel(ox + x, y)
  end

  if opt.garment then
    local ax, ay = anchor(src, f)
    if ax then
      for y = 0, FH - 1 do
        for x = 0, FW - 1 do
          if garment(get(x, y)) then dst:drawPixel(ox + x, y, opt.garment(ginfo(x - ax, y - ay))) end
        end
      end
    end
  end

  local cap = opt.cap
  if cap then
    local cx, cy
    for y = 0, FH - 1 do
      for x = 0, FW - 1 do
        local p = get(x, y)
        if p == CAP or p == CAP_D then cx, cy = math.min(cx or x, x), math.min(cy or y, y) end
      end
    end
    for y = 0, FH - 1 do
      for x = 0, FW - 1 do
        local p = get(x, y)
        if p == CAP or p == CAP_D then
          local below = get(x, y + 1)
          local c = (p == CAP_D) and cap.seam or cap.crown
          if cap.band and below ~= CAP and below ~= CAP_D then c = cap.band end
          if cap.button and y == cy then c = cap.button end
          dst:drawPixel(ox + x, y, c)
        elseif p == BILL then
          local c = cap.bill
          if cap.billtop and get(x, y - 1) ~= BILL then c = cap.billtop end
          dst:drawPixel(ox + x, y, c)
        end
      end
    end
    local function stamp(pts, c)
      for _, o in ipairs(pts) do
        local x, y = cx + o[1], cy + o[2]
        if get(x, y) == CAP then dst:drawPixel(ox + x, y, c) end
      end
    end
    if cx and cap.y then stamp(CAP_Y, cap.y) end
    if cx and cap.dash then stamp(CAP_DASH, cap.dash) end
  end

  if opt.shoe then
    -- shoe whites are the ffffff pixels that touch shoe grey (eye glints never do)
    local sole, grew = {}, true
    while grew do
      grew = false
      for y = 0, FH - 1 do
        for x = 0, FW - 1 do
          if get(x, y) == SOLE and not sole[y * FW + x] then
            for dy = -1, 1 do
              for dx = -1, 1 do
                if get(x + dx, y + dy) == SHOE or sole[(y + dy) * FW + x + dx] then
                  sole[y * FW + x] = true; grew = true
                end
              end
            end
          end
        end
      end
    end
    for y = 0, FH - 1 do
      for x = 0, FW - 1 do
        if get(x, y) == SHOE then dst:drawPixel(ox + x, y, opt.shoe)
        elseif sole[y * FW + x] then dst:drawPixel(ox + x, y, opt.sole) end
      end
    end
  end
end

local function recolour(src, opt)
  local dst = Image(src)
  for f = 0, src.width // FW - 1 do recolour_frame(src, dst, f, opt) end
  return dst
end

------------------------------------------------------------- build + verify

local neck, anchor_y = {}, 26
do
  local fh = io.open(SRC .. "player_body_neck.json", "r")
  local js = fh:read("a"); fh:close()
  anchor_y = tonumber(js:match('"head_neck_anchor":{"x":%d+,"y":(%d+)}'))
  for f, y in js:gmatch('{"frame":(%d+),"x":%d+,"y":(%d+)}') do neck[tonumber(f)] = tonumber(y) end
end

local function compose(dst, set, x, y, bf, hf, s, sx, sw)
  sx, sw = sx or 0, sw or FW
  H.blit(dst, set.body, x, y, bf * FW + sx, 0, sw, FH, false, s)
  H.blit(dst, set.head, x, y + (neck[bf] - anchor_y) * (s or 1), hf * FW + sx, 0, sw, FH, false, s)
end

local bad = 0
for _, opt in ipairs(OPTS) do
  opt.set = {}
  local alpha, left = 0, 0
  for _, s in ipairs(SHEETS) do
    local src = ORIG[s]
    local im = recolour(src, opt)
    opt.set[s] = im
    assert(im.width == src.width and im.height == src.height)
    for y = 0, im.height - 1 do
      for x = 0, im.width - 1 do
        local a, b = src:getPixel(x, y), im:getPixel(x, y)
        if pc.rgbaA(a) ~= pc.rgbaA(b) then alpha = alpha + 1 end
        if (opt.garment and garment(b)) or (opt.cap and (b == CAP or b == CAP_D or b == BILL)) or
          (opt.shoe and b == SHOE) then left = left + 1 end
      end
    end
    im:saveAs(OUT .. "uniform_" .. opt.code .. "_" .. opt.name .. "_" .. s .. ".png")
  end
  -- the animations sheet must still equal body + neutral head composed
  local diff, anim = 0, opt.set.animations
  local tmp = H.img(anim.width, anim.height)
  for f = 0, anim.width // FW - 1 do compose(tmp, opt.set, f * FW, 0, f, 2, 1) end
  for y = 0, anim.height - 1 do
    for x = 0, anim.width - 1 do
      if tmp:getPixel(x, y) ~= anim:getPixel(x, y) then diff = diff + 1 end
    end
  end
  bad = bad + alpha + left + diff
  print(string.format("%s %-20s 4 sheets, sizes match originals, alpha changed=%d, leftover original colours=%d, animations vs body+head diff=%d",
    opt.code:upper(), opt.name, alpha, left, diff))
end
print(bad == 0 and "CHECK OK: dimensions, alpha, leftovers and composition all clean"
  or ("CHECK FAILED: " .. bad .. " problem pixels"))

------------------------------------------------------------------ previews

local function save_scaled(im, path, s)
  local big = Image(im.width * s, im.height * s, ColorMode.RGB)
  for y = 0, im.height - 1 do
    for x = 0, im.width - 1 do
      local p = im:getPixel(x, y)
      if pc.rgbaA(p) > 0 then big:clear(Rectangle(x * s, y * s, s, s), p) end
    end
  end
  big:saveAs(path)
  print("saved " .. path .. " " .. big.width .. "x" .. big.height)
end

local function backdrop(im, x, y, w, h, floor)
  H.rect(im, x, y, w, h, P.wall)
  H.rect(im, x, floor, w, y + h - floor, P.wall_d)
  H.rect(im, x, floor, w, 1, P.base)
end

-- One option: idle, kick at full extension, a walk frame, head aiming up / down.
local CW, CHT = 166, 88
local function cell(im, x, y, opt)
  backdrop(im, x, y, CW, CHT, y + 15 + 63)
  H.tag(im, opt.label, x + 3, y + 2)
  H.text(im, opt.note, x + 3, y + CHT - 8, P.base)
  local px = x + 3
  for _, bf in ipairs({ 0, 17, 6 }) do
    compose(im, opt.set, px, y + 15, bf, 2, 1, 5, 40)
    px = px + 41
  end
  H.blit(im, opt.set.head, px + 2, y + 13, 4 * FW + 10, 0, 32, 28)
  H.blit(im, opt.set.head, px + 2, y + 43, 0 * FW + 10, 0, 32, 28)
end

do
  local cols = 2
  local rows = (#OPTS + cols - 1) // cols
  local im = H.img(cols * (CW + 2) + 2, rows * (CHT + 2) + 2, P.ui)
  for i, opt in ipairs(OPTS) do
    cell(im, 2 + ((i - 1) % cols) * (CW + 2), 2 + ((i - 1) // cols) * (CHT + 2), opt)
  end
  save_scaled(im, REV .. "options_uniforms.png", 4)
end

-- Every composed frame, to prove the trim rules hold through walk, jump and kick.
local function strip(im, x, y, opt)
  local per, fw = 7, 44
  backdrop(im, x, y, per * fw, 13, y + 13)
  H.tag(im, opt.label .. " - ALL 21 FRAMES", x + 2, y + 1)
  for f = 0, 20 do
    local cx, cy = x + (f % per) * fw, y + 13 + (f // per) * 70
    backdrop(im, cx, cy, fw, 70, cy + 3 + 63)
    compose(im, opt.set, cx + 2, cy + 3, f, 2, 1, 5, 40)
    H.text(im, tostring(f), cx + 2, cy + 2, P.base)
  end
  return 13 + 3 * 70
end

do
  local show = { OPTS[1], OPTS[3], OPTS[5], OPTS[10] }
  local im = H.img(2 * (7 * 44 + 2) + 2, 2 * (13 + 210 + 2) + 2, P.ui)
  for i, opt in ipairs(show) do
    strip(im, 2 + ((i - 1) % 2) * (7 * 44 + 2), 2 + ((i - 1) // 2) * 225, opt)
  end
  save_scaled(im, REV .. "options_uniforms_allframes.png", 3)
end

if app.params.debug then
  for _, opt in ipairs(OPTS) do
    local im = H.img(CW, CHT)
    cell(im, 0, 0, opt)
    save_scaled(im, app.params.debug .. "/cell_" .. opt.code .. ".png", 6)
    local st = H.img(7 * 44, 223)
    strip(st, 0, 0, opt)
    save_scaled(st, app.params.debug .. "/frames_" .. opt.code .. ".png", 3)
  end
end
