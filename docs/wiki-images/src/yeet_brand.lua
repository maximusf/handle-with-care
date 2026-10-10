-- Shared YEET courier branding: palette, italic wordmark and Y monogram.
-- Load after hwc.lua / art_common.lua. Every generator that shows the brand
-- draws it through here so the mark stays identical across assets.

Y = {}
Y.P = {
  black = H.c("16161a"), char = H.c("26262c"), char_l = H.c("3a3a42"),
  orange = H.c("ff5a1f"), orange_d = H.c("c8410f"), orange_l = H.c("ff8a4c"),
  white = H.c("f4f1ea"), gray = H.c("9a9aa2"),
}

local GL = {
  Y = { "##  ##", "##  ##", " #### ", "  ##  ", "  ##  ", "  ##  ", "  ##  " },
  E = { "######", "##    ", "##    ", "##### ", "##    ", "##    ", "######" },
  T = { "######", "  ##  ", "  ##  ", "  ##  ", "  ##  ", "  ##  ", "  ##  " },
}

-- Italic lean: upper rows shift right.
local function shear(r, s) return ((6 - r) // 2) * s end

local function glyph(im, rows, x, y, s, c)
  for r = 1, 7 do
    local row = rows[r]
    for k = 1, #row do
      if row:sub(k, k) == "#" then
        H.rect(im, x + (k - 1) * s + shear(r - 1, s), y + (r - 1) * s, s, s, c)
      end
    end
  end
end

local function speedlines(im, x, y, s, lens, right, c)
  for i, r in ipairs({ 1, 3, 5 }) do
    H.rect(im, x + (right - lens[i]) * s + shear(r, s), y + r * s, lens[i] * s, s, c)
  end
end

-- Full wordmark: speed lines, YEET, chevron. 46*s wide, 7*s tall.
function Y.wordw(s) return 46 * (s or 1) end
function Y.wordmark(im, x, y, s, fg, accent)
  s, fg, accent = s or 1, fg or Y.P.white, accent or Y.P.orange
  speedlines(im, x, y, s, { 6, 8, 5 }, 8, accent)
  local cx = x + 9 * s
  for _, ch in ipairs({ "Y", "E", "E", "T" }) do
    glyph(im, GL[ch], cx, y, s, fg)
    cx = cx + 7 * s
  end
  for r = 0, 6 do
    local d = 3 - math.abs(3 - r)
    H.rect(im, cx + (d + 3) * s, y + r * s, 3 * s, s, accent) -- upright so the point stays sharp
  end
  return Y.wordw(s)
end

-- Y monogram with speed lines. 15*s wide, 7*s tall.
function Y.monow(s) return 15 * (s or 1) end
function Y.mono(im, x, y, s, fg, accent)
  s, fg, accent = s or 1, fg or Y.P.white, accent or Y.P.orange
  speedlines(im, x, y, s, { 4, 5, 3 }, 5, accent)
  glyph(im, GL.Y, x + 6 * s, y, s, fg)
  return Y.monow(s)
end

return Y
