local grid 
local width, height

local function init(w,h)
  grid = {}
  width, height = w, h
  for i = 1, width do
    grid[i] = {}
    for j = 1, height do
      grid[i][j] = ' '
    end
  end
end

local function checkCollisions(tetro)
  local t = tetro
  local shape = t:shape()
  for i = 1, t.size.w do 
    for j = 1, t.size.h do
      if not (shape[j][i] == ' ') then
	local blockX = t.pos.x + i - 1
	local blockY = t.pos.y + j - 1
	if not grid[blockX] or not (grid[blockX][blockY] == ' ') then 
	  return true
	end
      end
    end
  end
  return false
end

local function fixeTetro(tetro)
  local t = tetro
  local shape = t:shape()
  for i = 1, t.size.w do 
    for j = 1, t.size.h do
      if not (shape[j][i] == ' ') then 
	grid[t.pos.x + i - 1][t.pos.y + j - 1] = t.name 
      end
    end
  end
end

local function checkLineFull(line)
  for i = 1, width do
    if grid[i][line] == ' ' then return false end
  end
  return true
end

local function removeLine(line)
  for i = 1, width do
    for j = line, 1, -1 do
      grid[i][j] = grid[i][j - 1] or ' '
    end
  end
end

local function getGrid()
  return grid
end

local function landPosition(tetro)
  local moves = 0
  while not checkCollisions(tetro) do
    tetro:move( 0, 1 )
    moves = moves + 1
  end
  tetro:move(0, -moves)
  return { x = tetro.pos.x, y = tetro.pos.y + moves - 1 }
end

local M = {}
M.init = init
M.checkCollisions = checkCollisions
M.fixeTetro = fixeTetro
M.getGrid = getGrid
M.checkLineFull = checkLineFull
M.removeLine = removeLine
M.landPosition = landPosition
return M
