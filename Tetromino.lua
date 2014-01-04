
local Tetromino = {}
local TetrosProtos = { 
  I = { 
    name = 'I', 
    center = { x = 2.5, y = 2.5 },
    shapes = {
      { 
	{ ' ', ' ', ' ', ' ' }, 
	{ ' ', ' ', ' ', ' ' }, 
	{ 'I', 'I', 'I', 'I' },
	{ ' ', ' ', ' ', ' ' }, 
      },
      { 
	{ ' ', ' ', 'I', ' ' }, 
	{ ' ', ' ', 'I', ' ' },
	{ ' ', ' ', 'I', ' ' }, 
	{ ' ', ' ', 'I', ' ' }, 
      },
      { 
	{ ' ', ' ', ' ', ' ' }, 
	{ ' ', ' ', ' ', ' ' }, 
	{ 'I', 'I', 'I', 'I' },
	{ ' ', ' ', ' ', ' ' }, 
      },
      { 
	{ ' ', 'I', ' ', ' ' }, 
	{ ' ', 'I', ' ', ' ' },
	{ ' ', 'I', ' ', ' ' }, 
	{ ' ', 'I', ' ', ' ' }, 
      },
    },
    size = { w = 4, h = 4 }
  },
  O = { 
    name = 'O',
    center = { x = 1.5, y = 1.5 },
    shapes = {
      { 
	{ 'O', 'O' }, 
	{ 'O', 'O' }, 
      },
    },
    size = { w = 2, h = 2 }
  }, 
  T = { 
    name = 'T',
    center = { x = 2, y = 2 },
    shapes = {
      {
	{ ' ', ' ', ' ' }, 
	{ ' ', 'T', ' ' }, 
	{ 'T', 'T', 'T' },
      },
      {
	{ ' ', 'T', ' ' }, 
	{ ' ', 'T', 'T' },
	{ ' ', 'T', ' ' }, 
      },
      {
	{ ' ', ' ', ' ' }, 
	{ 'T', 'T', 'T' },
	{ ' ', 'T', ' ' }, 
      },
      {
	{ ' ', 'T', ' ' }, 
	{ 'T', 'T', ' ' },
	{ ' ', 'T', ' ' }, 
      },
    },
    size = { w = 3, h = 3 }
  }, 
  L = { 
    name = 'L',
    center = { x = 2, y = 2 },
    shapes = {
      {
	{ ' ', ' ', ' ' }, 
	{ ' ', ' ', 'L' },
	{ 'L', 'L', 'L' },
      },
      {
	{ ' ', 'L', ' ' },
	{ ' ', 'L', ' ' },
	{ ' ', 'L', 'L' }, 
      },
      {
	{ ' ', ' ', ' ' },
	{ 'L', 'L', 'L' },
	{ 'L', ' ', ' ' }, 
      },
      {
	{ 'L', 'L', ' ' },
	{ ' ', 'L', ' ' },
	{ ' ', 'L', ' ' }, 
      },
    },
    size = { w = 3, h = 3 }
  },
  J = { 
    name = 'J',
    center = { x = 2, y = 2 },
    shapes = {
      {
	{ ' ', ' ', ' ' }, 
	{ 'J', ' ', ' ' },
	{ 'J', 'J', 'J' },
      },
      {
	{ ' ', 'J', 'J' },
	{ ' ', 'J', ' ' },
	{ ' ', 'J', ' ' }, 
      },
      {
	{ ' ', ' ', ' ' },
	{ 'J', 'J', 'J' },
	{ ' ', ' ', 'J' }, 
      }, 
      {
	{ ' ', 'J', ' ' },
	{ ' ', 'J', ' ' },
	{ 'J', 'J', ' ' }, 
      },
    },
    size = { w = 3, h = 3 }
  }, 
  Z = { 
    name = 'Z',
    center = { x = 2, y = 2 },
    shapes = {
      { 
	{ ' ', ' ', ' ' }, 
	{ 'Z', 'Z', ' ' },
	{ ' ', 'Z', 'Z' },
      },
      { 
	{ ' ', ' ', 'Z' },
	{ ' ', 'Z', 'Z' },
	{ ' ', 'Z', ' ' }, 
      },
      { 
	{ ' ', ' ', ' ' },
	{ 'Z', 'Z', ' ' },
	{ ' ', 'Z', 'Z' }, 
      },
      { 
	{ ' ', 'Z', ' ' },
	{ 'Z', 'Z', ' ' },
	{ 'Z', ' ', ' ' }, 
      },
    },
    size = { w = 3, h = 3 }
  }, 
  S = { 
    name = 'S', 
    center = { x = 2, y = 2 },
    shapes = { 
      {
	{ ' ', ' ', ' ' }, 
	{ ' ', 'S', 'S' },
	{ 'S', 'S', ' ' },
      },
      {
	{ ' ', 'S', ' ' },
	{ ' ', 'S', 'S' },
	{ ' ', ' ', 'S' }, 
      },
      {
	{ ' ', ' ', ' ' }, 
	{ ' ', 'S', 'S' },
	{ 'S', 'S', ' ' },
      },
      {
	{ 'S', ' ', ' ' }, 
	{ 'S', 'S', ' ' },
	{ ' ', 'S', ' ' },
      },
    },
    size = { w = 3, h = 3 }
  }
}

local function deepcopy(t)
  if type(t) ~= 'table' then return t end
  local mt = getmetatable(t)
  local res = {}
  for k,v in pairs(t) do
    if type(v) == 'table' then
      v = deepcopy(v)
    end
    res[k] = v
  end
  setmetatable(res,mt)
  return res
end

function Tetromino.new(tetroName, center)
  local proto = TetrosProtos[tetroName]
  local tetro = deepcopy(proto)
  tetro.pos = { x = center.x - math.floor(tetro.center.x) + 1, y = center.y }
  tetro.state = 1
  setmetatable(tetro, Tetromino)
  return tetro
end

function Tetromino:rotate(dir)
  if dir == 'CW' then
    self.state = self.state % #(self.shapes) + 1
  elseif dir == 'CCW' then
    self.state = (self.state - 2 + #(self.shapes)) % #(self.shapes) + 1
  end
end

function Tetromino:move(dx, dy)
  dx = dx or 0
  dy = dy or 0
  self.pos.x = self.pos.x + dx
  self.pos.y = self.pos.y + dy
end

function Tetromino:shape()
  return self.shapes[self.state]
end

function Tetromino:spannedLines()
  local shape = self:shape()
  local lines = {}
  local offset = self.pos.y - 1
  for j = 1, self.size.h do 
    for i = 1, self.size.w do
      if not (shape[j][i] == ' ') then 
	table.insert(lines, j + offset)
	break
      end
    end
  end
  return lines
end

Tetromino.__index = Tetromino

return Tetromino
