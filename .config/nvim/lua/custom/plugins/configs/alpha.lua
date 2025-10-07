local present, alpha = pcall(require, 'alpha')

if not present then
  return
end

local dashboard = require 'alpha.themes.dashboard'
local ascii = require 'ascii'

local header = {
  type = 'text',
  val = ascii.irohTea,
  opts = {
    position = 'center',
    hl = 'comment',
  },
}

local function getGreeting(name)
  local tableTime = os.date '*t'
  local hour = tableTime.hour
  local greetingsTable = {
    [1] = '  Sleep well',
    [2] = '  Good morning',
    [3] = '  Good afternoon',
    [4] = '  Good evening',
    [5] = '望 Good night',
  }
  local greetingIndex = 0
  if hour == 23 or hour < 7 then
    greetingIndex = 1
  elseif hour < 12 then
    greetingIndex = 2
  elseif hour >= 12 and hour < 18 then
    greetingIndex = 3
  elseif hour >= 18 and hour < 21 then
    greetingIndex = 4
  elseif hour >= 21 then
    greetingIndex = 5
  end
  return greetingsTable[greetingIndex] .. ', ' .. name
end

local userName = 'Hoops'
local greeting = getGreeting(userName)

local greetHeading = {
  type = 'text',
  val = greeting,
  opts = {
    position = 'center',
    hl = 'String',
  },
}

dashboard.section.buttons.val = {
  dashboard.button('s', '  > Find file', ':Telescope find_files<CR>'),
  dashboard.button('o', '  > Old files', ':Telescope oldfiles<CR>'),
  dashboard.button('m', '⇀ > Harpoon Marks', '<leader>hm'),
  dashboard.button('q', '  > Quit NVIM', ':qa<CR>'),
}

dashboard.opts.layout = {
  { type = 'padding', val = 3 },
  header,
  { type = 'padding', val = 3 },
  greetHeading,
  { type = 'padding', val = 2 },
  dashboard.section.buttons,
}

alpha.setup(dashboard.opts)
