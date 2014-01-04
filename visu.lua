local tetroNames = { 'I', 'O', 'T', 'L', 'J', 'Z', 'S' } 
local colors = {
  I = {   0, 255, 255 }, 
  O = { 255, 255,   0 }, 
  T = { 139,   0, 139 }, 
  L = { 255, 165,   0 }, 
  J = {   0,   0, 255 }, 
  Z = { 255,   0,   0 }, 
  S = {   0, 255,   0 },
}
local squareSize
local square 
local ratio
local gameOver 
local borders 
local width, height
local font
local lg = love.graphics

local function makeBorders()
  local sb = lg.newSpriteBatch(square, (height + 1) * 2 + width + 1, 'static')  -- + 1 why ?
  for x = 0, (width + 2) * squareSize, squareSize do
    sb:add(x, height * squareSize, 0, ratio)
  end
  for y = 0, height * squareSize, squareSize do
    sb:add(0, y, 0, ratio)
    sb:add((width + 1) * squareSize, y, 0, ratio)
  end
  return sb
end

local function init(w, h, size, leftUI, rightUI)
  width, height = w, h
  squareSize = size
  square = lg.newImage('square.png')
  ratio = size / square:getWidth()
  gameOver = lg.newImage('game over.png')
  borders = makeBorders()
  font = lg.newFont('04B_03__.ttf', squareSize)
end

local function drawGrid()
  lg.setBackgroundColor(10, 10, 10)
  lg.clear()
  lg.setColor(20, 20, 20)
  lg.setLineWidth(2)
  lg.setLineStyle('smooth')
  for x = 0, (width + 2) * squareSize, squareSize do
    lg.line(x, 0, x, (height + 1) * squareSize)
  end
  for y = 0, (height + 1) * squareSize, squareSize do
    lg.line(0, y, (width + 2) * squareSize, y)
  end
end

local function drawTetrominos(grid)
  for i = 1, width do
    for j = 1, height do
      local tetro = grid[i][j]
      if not (tetro == ' ') then
	lg.setColor(colors[tetro])
	lg.draw(square, (i - 1 + 1) * squareSize, (j - 1) * squareSize, 0, ratio)
      end
    end
  end 
end

local function renderTetro(tetro, pos, ghost)
  local t = tetro
  local pos = pos or t.pos
  local shape = t:shape()
  local drawer
  if ghost then
    drawer = function(x,y)
      lg.setColor(110, 110, 110, 110)
      lg.rectangle('fill', x, y, squareSize, squareSize)
      lg.setColor(20, 20, 20, 110)
      lg.rectangle('line', x, y, squareSize, squareSize)
    end
  else
    lg.setColor(colors[t.name])
    drawer = function(x,y)
      lg.draw(square, x, y, 0, ratio)
    end
  end
  for i = 1, t.size.w do 
    for j = 1, t.size.h do
      if not (shape[j][i] == ' ') then 
	drawer((pos.x - 1 + i - 1 + 1) * squareSize, (pos.y - 1 + j - 1) * squareSize)
      end
    end
  end
end

local function renderNextTetro( tetro, pos)
  lg.setColor(colors[tetro.name])
  lg.setFont(font)
  local paddingX = 10
  local paddingY = 10
  lg.print ( "next:", pos.x * squareSize + paddingX, pos.y * squareSize + paddingY)
  renderTetro( tetro, { x = pos.x + 2, y = pos.y + 3 } ) 
end

local function renderLevel(level)
  drawGrid()
  lg.setColor( 100, 100, 100 )
  lg.draw( borders )
  drawTetrominos( level.getGrid() )
end

local function renderLeftPanel(level, tetro, score)
end

local function renderScore(score, rect)
  lg.setFont(font)
  local paddingY = 10
  local paddingX = 10
  local y = paddingY + rect.y * squareSize
  local x = paddingX + rect.x * squareSize
  local width = rect.w
  lg.print ( "level:", x, y)
  lg.printf ( string.format ( "%d", score.getLevel() ), x, y, width * squareSize - 2 * paddingX, 'right' )
  y = y + squareSize + paddingY
  lg.print ( "score:", x, y)
  lg.printf ( string.format ( "%d", score.getScore() ), x, y, width * squareSize - 2 * paddingX, 'right' )
  y = y + squareSize + paddingY
  lg.print ( "goal:", x, y)
  lg.printf ( string.format ( "%d", score.getGoal() ), x, y, width * squareSize - 2 * paddingX, 'right' )
  y = y + squareSize + paddingY
  lg.print ( "lines:", x, y)
  lg.printf ( string.format ( "%d", score.getLines() ), x, y, width * squareSize - 2 * paddingX, 'right' )
end

local function renderGameOver()
  local lg = love.graphics
  --lg.setColor(255, 255, 255)
  lg.setColor(colors[tetroNames[math.random(7)]])
  lg.draw(gameOver, 1.25 * squareSize, squareSize * 8, 0, 0.5)
end

local M = {}
M.init = init
M.renderLevel = renderLevel
M.renderTetro = renderTetro
M.renderGameOver = renderGameOver
M.renderScore = renderScore
M.renderNextTetro = renderNextTetro
return M
