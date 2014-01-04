local level = require 'tetrisGrid'
local visu = require 'visu'
local score = require 'score'
local lg = love.graphics
local Tetro = require 'Tetromino'

-- ui elements
-- ui panels sizes (in blocks)
local uiLeftWidth = 0 
local uiRightWidth = 8
local canvas
local rightCanvas
local leftCanvas
local gameEnded

-- well shape
local width, height

-- drop rate
local maxDropRate = 20
local minDropRate = 2

-- delays
local lockDelay = 0.5
local lineClearDelay = 0.6
local spawnDelay = 0.4

-- active tetromino state
local currentTetro
local nextTetro
local hardDrop = false
local landed = false
local spawned = false
local lineCleared = false
local fastDrop = false

-- time tracking
local timeLanded = 0
local timeSpawned = 0
local timeLineCleared = 0

local function randomBag( initialPool )
  local pool = initialPool
  local n = #initialPool
  -- current remaining bags
  local bag = {}
  -- initialize a full bag of indices
  local function fillBag()
    for i = 1,n do
      table.insert(bag, i)
    end
  end
  -- get a random element
  local function getNext()
    if next(bag) == nil then
      fillBag()
    end
    local index = math.random(#bag)
    local value = initialPool[bag[index]]
    table.remove(bag, index)
    return value
  end
  return getNext
end

local tetroNames = { 'I', 'O', 'T', 'L', 'J', 'Z', 'S' } 
local randomTetro = randomBag(tetroNames) 

-- spawn a new tetromino
local function spawnTetro()
  currentTetro = nextTetro
  local tetro = randomTetro()
  nextTetro = Tetro.new( tetro, { x = math.floor(width / 2), y = 1 } )
end

local function reset()
  -- reset well
  level.init(width, height)
  gameEnded = false
  lineCleared = false

  -- current tetro state
  currentTetro = nil
  nextTetro = nil
  timeLastTick = 0
  hardDrop = false
  landed = false
  spawned = false
  spawnTetro()

  -- reset timers
  timeLanded = 0
  timeSpawned = 0
  timeLineCleared = 0

  -- reset score
  score.init()
  
  -- random stuf
  tetroBag = {}
end 

function love.load()
  squareSize = 32 -- square size
  width = 10 -- well width
  height = 20 -- well height
  
  -- render canvas
  canvas = lg.newCanvas((width + 2) * squareSize, (height + 1) * squareSize)
  if uiRightWidth > 0 then
    rightCanvas = lg.newCanvas(uiRightWidth * squareSize, (height + 1) * squareSize)
  end
  if uiLeftWidth > 0 then
    leftCanvas = lg.newCanvas(uiLeftWidth * squareSize, (height + 1) * squareSize)
  end

  -- set window size
  love.window.setMode((width + 2 + uiRightWidth + uiLeftWidth) * squareSize, (height + 1) * squareSize, {})
  
  -- init renderer
  visu.init(width, height, squareSize, uiLeftWidth, uiRightWidth)

  -- enable key repeat
  love.keyboard.setKeyRepeat( true )

  -- reset game state
  reset() 
end

-- ends the game
local function endGame()
  gameEnded = true
end

-- move the current tetro to the left if possible
local function moveTetro(dx)
  -- try to move
  currentTetro:move(dx)
  -- if collisions
  if level.checkCollisions(currentTetro) then
    -- undo move
    currentTetro:move(-dx)
  -- reset timer if landed
  elseif landed then 
    timeLanded = 0
  end
end


local function wallKick(dir)
  local sign = ((dir == 'CW') and 1 or -1)
  -- try right
  currentTetro:move(sign * 1)
  if not level.checkCollisions(currentTetro) then return true end
  -- then left
  currentTetro:move(sign * -2)
  if not level.checkCollisions(currentTetro) then return true end
  -- try farther if tetro is I and horizontal
  if currentTetro.name == 'I' and (currentTetro.state == 1 or currentTetro.state == 3) then
    currentTetro:move(sign * 3)
    if not level.checkCollisions(currentTetro) then return true end
    currentTetro:move(sign * -4)
    if not level.checkCollisions(currentTetro) then return true end
    currentTetro:move(sign * 1)
  end
  -- then down
  currentTetro:move(sign * 1, 1)
  if not level.checkCollisions(currentTetro) then return true end
  -- then down-right
  currentTetro:move(sign * 1)
  if not level.checkCollisions(currentTetro) then return true end
  -- then down-left
  currentTetro:move(sign * -2)
  if not level.checkCollisions(currentTetro) then return true end
  -- finally give up
  currentTetro:move(sign * 1,-1)
  return false
end

local function rotateTetroLeft()
  currentTetro:rotate('CCW')
  if level.checkCollisions(currentTetro) and not wallKick('CCW') then
    -- undo rotation
    currentTetro:rotate('CW')
  elseif landed then 
    -- reset timer if landed
    timeLanded = 0
  end
end

local function rotateTetroRight()
  currentTetro:rotate('CW')
  if level.checkCollisions(currentTetro) and not wallKick('CW') then
    currentTetro:rotate('CCW')
  elseif landed then 
    timeLanded = 0
  end
end
local function lerp(a, b, t)
        return a + (b - a) * t
end
 
local function getDropRate()
  local level, maxLevel = score.getLevel(), score.getMaxLevel()
  return (maxLevel == 1) and maxDropRate or lerp(minDropRate, maxDropRate, (level - 1) / (maxLevel - 1))
end

local function lockTetro()
  -- adds tetro to static level 
  level.fixeTetro(currentTetro)
  -- get spanned lines by tetro
  local lines = currentTetro:spannedLines()
  if lines and lines[#lines] < 1 then 
    -- tetro locked outside well
    endGame()
    return
  end
  -- check lines cleared
  local linesCleared = 0
  for _, l in ipairs(lines) do
    if level.checkLineFull(l) then
      -- remove line
      level.removeLine(l)
      linesCleared = linesCleared + 1
    end
  end
  -- increase score if lines cleared
  if linesCleared > 0 then 
    score.linesScore(linesCleared) 
    lineCleared = true
    timeLineCleared = 0
  end
  -- reset current tetro
  currentTetro = nil
end

local function checkLanded()
  -- try to move down
  currentTetro:move(0, 1)
  -- check collisions
  local isLanded = level.checkCollisions(currentTetro)
  -- revert to initial position
  currentTetro:move(0, -1)
  -- set game state
  if landed and not isLanded then
    -- landed tetro has been moved and can fall 
    timeLastTick = 0
  end
  if not landed and isLanded then
    -- tetro just landed
    timeLanded = 0
  end
  landed = isLanded
  return landed
end

function love.update( dt )
  if not gameEnded then
    if currentTetro then
      local tick = 1 / (fastDrop and maxDropRate or getDropRate())
      checkLanded()
      timeLastTick = timeLastTick + dt
      if landed then timeLanded = timeLanded + dt end
      if spawned then 
	timeSpawned = timeSpawned + dt
	if timeSpawned >= spawnDelay then
	  spawned = false
	  timeSpawned = 0
	end
      elseif hardDrop then
	while not level.checkCollisions(currentTetro) do
	  currentTetro:move(0, 1)
	end
	-- locks tetro
	currentTetro:move(0, -1)
	lockTetro()
	hardDrop = false
	landed = false
      elseif not landed and timeLastTick >= tick then
	-- time to apply gravity
	timeLastTick = 0
	currentTetro:move(0, 1)
      elseif landed and timeLanded >= lockDelay then
        -- locks tetro
	lockTetro()
	landed = false
	timeLanded = 0
      end
    elseif lineCleared then
      timeLineCleared = timeLineCleared + dt
      if timeLineCleared >= lineClearDelay then
	lineCleared = false
	timeLineCleared = 0
      end
    else
      -- pops new tetro
      spawnTetro()
      timeLastTick = 0
      timeSpawned = 0
      spawned = true
      if level.checkCollisions(currentTetro) then
	endGame()
      end
    end
  end
end

function love.keypressed( key, isrepeat )
  if currentTetro and not gameEnded then
    if key == 'left' then
      moveTetro(-1)
    elseif key == 'right' then
      moveTetro(1)
    elseif not isrepeat then
      if key == 'down' then
	fastDrop = true
      elseif key == 'up' and currentTetro then
	hardDrop = true
      elseif key == 'a' then
	rotateTetroLeft()
      elseif key == 'z' then
	rotateTetroRight()
      end
    end
  end
  if key == 'r' then
    reset()
  end
end

function love.keyreleased( key )
  if key == 'down' then
    fastDrop = false
  elseif key == 'escape' then
    love.event.quit()
  end
end

function love.draw()
  lg.setCanvas(canvas)
  visu.renderLevel(level)
  if currentTetro then 
    visu.renderTetro( currentTetro ) 
    visu.renderTetro( currentTetro, level.landPosition(currentTetro), true )
  end

  -- if leftCanvas then
  --  lg.setCanvas(leftCanvas)
  --  visu.renderLeftPanel(level, currentTetro, score)
  --end
  if rightCanvas then
    lg.setCanvas( rightCanvas )
    lg.clear()
    if nextTetro then  visu.renderNextTetro( nextTetro, { x = 0, y = 0 } ) end
    visu.renderScore( score, { x = 0, y = 5, w = uiRightWidth, 0 } )
  end

  lg.setCanvas()
  if gameEnded then
    lg.setColor(150, 150, 150)
  else
    lg.setColor(255, 255, 255)
  end
  if leftCanvas then
    lg.draw(leftCanvas, 0, 0)
  end
  lg.draw(canvas, uiLeftWidth * squareSize, 0)
  if rightCanvas then
    lg.draw(rightCanvas, (uiLeftWidth + width + 2) * squareSize, 0)
  end
  if gameEnded then
    visu.renderGameOver()
  end
end
