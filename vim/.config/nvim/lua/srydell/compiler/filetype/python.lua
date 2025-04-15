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
      local common = require('srydell.compiler.common')
      common.replace_current_compiler({
        name = 'manim ' .. table.concat(args, ' '),
        edit_compiler_option = edit_manim_options,
        tasks = {
          {
            task = 'manim',
            args = args,
          },
        },
      })
    end
  )
end

local function get_compilers()
  local current_dir = vim.fn.expand('%:p:h')

  if vim.fn.filereadable(current_dir .. '/manim.cfg') then
    local args = { '-pql', vim.fn.expand('%'), guess_scene() }
    return {
      {
        name = 'manim ' .. table.concat(args, ' '),
        edit_compiler_option = edit_manim_options,
        tasks = {
          {
            task = 'manim',
            args = args,
          },
        },
      },
    }
  end

  return {
    { name = 'python run', tasks = { task = 'python' } },
  }
end

return get_compilers()
