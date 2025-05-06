local function guess_scene()
  -- Looking for [DefaultTemplate] in:
  -- class DefaultTemplate(Scene):
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local scene = string.match(line, '%s*class (%a+)%(Scene%):$')
    if scene then
      return scene
    end
  end
  return 'SomeScene'
end

local function edit_manim_options(current_compiler)
  vim.ui.input(
    { prompt = 'Enter new arguments: ', default = table.concat(current_compiler.tasks[1].args, ' ') },
    function(input)
      local args = require('srydell.util').split(input, ' ')
      current_compiler.name = 'manim ' .. table.concat(args, ' ')
      current_compiler.tasks[1].args = args
      local common = require('srydell.compiler.common')
      common.replace_current_compiler(current_compiler)
    end
  )
end

local function get_compilers()
  if vim.fn.filereadable(vim.fn.expand('%:p:h') .. '/manim.cfg') == 1 then
    local scene = guess_scene()
    local args = { '-pqm', vim.fn.expand('%'), scene }
    -- media/videos/filename_without_ext/720p30/MyScene.mp4
    -- local mpv_args = { 'media/videos/' .. vim.fn.expand('%:t:r') .. '/720p30/' .. scene .. '.mp4' }
    return {
      {
        name = 'manim ' .. table.concat(args, ' '),
        edit_compiler_option = edit_manim_options,
        tasks = {
          {
            task = 'manim',
            args = args,
          },
          -- {
          --   task = 'mpv',
          --   args = mpv_args,
          -- },
        },
      },
    }
  end

  return {
    { name = 'python run', tasks = { task = 'python' } },
  }
end

return get_compilers()
