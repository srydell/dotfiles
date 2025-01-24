local M = {}

M.setup = function()
  local dap = require('dap')
  local registry = require('mason-registry')

  local BASHDB_DIR = ''
  if registry.has_package('bash-debug-adapter') and registry.get_package('bash-debug-adapter'):is_installed() then
    BASHDB_DIR = registry.get_package('bash-debug-adapter'):get_install_path() .. '/extension/bashdb_dir'
  end

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
