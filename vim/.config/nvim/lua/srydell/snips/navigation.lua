local M = {}

M.forward = function()
  local ls = require('luasnip')
  if ls.expandable() then
    return ls.expand()
  end
  if ls.jumpable(1) then
    return ls.jump(1)
  end
end

M.backward = function()
  local ls = require('luasnip')
  if ls.jumpable(-1) then
    return ls.jump(-1)
  end
end

return M
