local srydell_swift = vim.api.nvim_create_augroup('srydell_swift', { clear = false })

local function is_xcode_project(filepath)
  local has_root = require('lspconfig.util').root_pattern
  return has_root('buildServer.json')(filepath)
    or has_root('*.xcodeproj', '*.xcworkspace')(filepath)
    or has_root('Package.swift')(filepath)
end

-- Automatically adds the file and group to XCode
vim.api.nvim_create_autocmd({ 'BufNewFile' }, {
  pattern = '*.swift',
  group = srydell_swift,
  callback = function()
    local actions = require('xcodebuild.actions')
    local filepath = vim.fn.expand('%:p')
    if is_xcode_project(filepath) then
      actions.add_file_to_targets(filepath, actions.get_project_targets())
    end
  end,
})
