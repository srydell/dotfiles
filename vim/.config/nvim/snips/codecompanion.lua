local ls = require('luasnip')
local f = ls.function_node

local function get_all_open_buffers(_, _)
  -- Get all listed buffers
  local bufs = vim.api.nvim_list_bufs()
  local buffers_to_include = ''
  for _, buf in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value('buflisted', { buf = buf }) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= '' then
        -- Extract only the filename
        local filename = vim.fn.fnamemodify(name, ':t')
        buffers_to_include = buffers_to_include .. string.format('#{buffer:%s} ', filename)
      end
    end
  end
  if #buffers_to_include == 0 then
    return 'No open buffers.'
  end
  return buffers_to_include
end

return {
  s({ trig = 'buffers', wordTrig = true, dscr = 'Include all buffers' }, {
    f(get_all_open_buffers, {}),
  }),
}
