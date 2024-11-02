local function toggle_screencast_settings()
  if vim.opt.number:get() then
    vim.cmd('set laststatus=1')
    vim.opt.number = false
    vim.fn.system({ 'tmux', 'set', 'status', 'off' })
    vim.opt.listchars = {}
    vim.diagnostic.disable()
  else
    vim.cmd('set laststatus=2')
    vim.opt.number = true
    vim.diagnostic.show()
    vim.fn.system({ 'tmux', 'set', 'status', 'on' })
    vim.opt.listchars = { tab = '▸ ', eol = '¬', trail = '·' }
    vim.diagnostic.enable()
  end
end

local function start_screencasting()
  toggle_screencast_settings()
  -- Make sure screencasts exists
  vim.fn.system({ 'mkdir', 'screencasts' })
  local timestamp = vim.fn.systemlist({ 'date', '+%s' })
  local file = string.format('screencasts/%s_%s', vim.fn.expand('%:t:r'), timestamp[1])
  local extension = '.mkv'

  vim.g.latest_screencast = file
  vim.g.latest_screencast_type = extension

  local overseer = require('overseer')
  local task = overseer.new_task({
    name = 'Screencasting',
    cmd = 'ffmpeg',
    args = { '-f', 'avfoundation', '-i', '"1:none"', file .. extension },
    components = { { 'on_exit_set_status', success_codes = { 255 } } }, -- Sending SIGINT is intentional
  })
  task:start()
end

local function end_screencasting()
  -- Have to send sigint to kill ffmpeg softly
  vim.fn.system({ 'pkill', 'ffmpeg', '-signal', 'SIGINT' })

  toggle_screencast_settings()

  -- Convert it to a .mov and a .gif
  local previous_file = vim.g.latest_screencast .. vim.g.latest_screencast_type
  local overseer = require('overseer')
  for _, extension in ipairs({ '.mov', '.gif' }) do
    local new_file = vim.g.latest_screencast .. extension
    local task = overseer.new_task({
      name = 'Screencasting',
      cmd = 'ffmpeg',
      args = { '-i', previous_file, new_file },
    })
    task:start()
  end
end

vim.keymap.set('n', '<leader>ss', start_screencasting)
vim.keymap.set('n', '<leader>se', end_screencasting)
