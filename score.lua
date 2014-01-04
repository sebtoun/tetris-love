local score = 0
local tetrisGains = { 1, 3, 5, 8 }
local totalLines = 0
local level = 1
local nextLevels = { 10, 20, 30, 40, 50, 60, 70, 80, 90 }

local function init()
  score = 0
  totalLines = 0
  level = 1
end

local function getLevel()
  return level
end

local function getMaxLevel()
  return #nextLevels + 1
end

local function linesScore(n)
  score = score + tetrisGains[n] * 100
  totalLines = totalLines + n
  if level < getMaxLevel() and totalLines >= nextLevels[level] then
    level = level + 1
  end
end

local function getScore()
  return score
end

local function getLines()
  return totalLines
end

local function getGoal()
  return nextLevels[level] - totalLines
end

local M = {}
M.init = init
M.linesScore = linesScore
M.getLevel = getLevel
M.getMaxLevel = getMaxLevel
M.getScore = getScore
M.getLines = getLines
M.getGoal = getGoal
return M
