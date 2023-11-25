local M = {}

-- Errorformat for python
M.get_errorformat = function()
  return [[%*\sFile "%f"\, line %l\, %m,]] .. [[%*\sFile "%f"\, line %l,]]
end

return M
