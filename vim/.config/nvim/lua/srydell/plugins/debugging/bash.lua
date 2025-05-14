local M = {}

M.setup = function()
  local dap = require('dap')
  local BASHDB_DIR = vim.fn.expand('$MASON') .. '/opt/bashdb/'

  dap.adapters.bashdb = {
    type = 'executable',
    command = vim.fn.exepath('bash-debug-adapter'),
  }
  dap.configurations.sh = {
    {
      type = 'bashdb',
      request = 'launch',
      name = 'Bash: Launch file',
      program = '${file}',
      cwd = '${fileDirname}',
      pathBashdb = BASHDB_DIR .. '/bashdb',
      pathBashdbLib = BASHDB_DIR,
      pathBash = 'bash',
      pathCat = 'cat',
      pathMkfifo = 'mkfifo',
      pathPkill = 'pkill',
      env = {},
      args = {},
    },
  }
end

return M
