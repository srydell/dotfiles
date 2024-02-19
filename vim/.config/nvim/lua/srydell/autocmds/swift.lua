local srydell_swift = vim.api.nvim_create_augroup('srydell_swift', { clear = false })

-- Stolen from xcodebuild to run it's internal xcodeproj ruby file
local function run(action, params)
  local projectConfig = require('xcodebuild.project_config')
  local util = require('xcodebuild.util')
  local appdata = require('xcodebuild.appdata')
  local helper = "ruby '" .. appdata.tool_path('project_helper.rb') .. "'"
  local allParams = ''
  local project = projectConfig.settings.xcodeproj
  params = params or {}
  table.insert(params, 1, project)

  for _, param in ipairs(params) do
    allParams = allParams .. " '" .. param .. "'"
  end

  local errorFile = '/tmp/xcodebuild_nvimtree'
  local output = util.shell(helper .. ' ' .. action .. allParams .. ' 2> ' .. errorFile)

  if output[#output] == '' then
    table.remove(output, #output)
  end

  if output[1] and vim.startswith(output[1], 'WARN:') then
    vim.notify(table.concat(output, '\n'):sub(7), vim.log.levels.WARN)
    return {}
  end

  local stderr_file = io.open(errorFile, 'r')
  if stderr_file then
    if stderr_file:read('*all') ~= '' then
      vim.notify(
        'Could not update Xcode project file.\n'
          .. 'To see more details please check /tmp/xcodebuild_nvimtree.\n'
          .. 'If you are trying to add files to SPM packages, you may want to filter them out in the config using: integrations.nvim_tree.should_update_project.\n'
          .. 'If the error is unexpected, please open an issue on GitHub.',
        vim.log.levels.ERROR
      )
      return {}
    end
  end

  return output
end

local function run_add_file_to_targets(filepath, targets)
  local targetsJoined = table.concat(targets, ',')
  run('add_file', { targetsJoined, filepath })
end

local function is_xcode_project(filepath)
  local lsp_util = require('lspconfig.util')
  return lsp_util.root_pattern('buildServer.json')(filepath)
    or lsp_util.root_pattern('*.xcodeproj', '*.xcworkspace')(filepath)
    or lsp_util.root_pattern('Package.swift')(filepath)
end

-- Automatically adds the file and group to XCode if it's an xcode project
vim.api.nvim_create_autocmd({ 'BufNewFile' }, {
  pattern = '*.swift',
  group = srydell_swift,
  callback = function()
    local filepath = vim.fn.expand('%:p')
    local notifications = require('xcodebuild.notifications')
    if is_xcode_project(filepath) then
      local targets = run('list_targets')
      local dir = vim.fs.dirname(filepath)
      run('add_group', { dir })
      run_add_file_to_targets(filepath, targets)
      notifications.send('File has been added to targets')
    end
  end,
})
