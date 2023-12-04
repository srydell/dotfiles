local M = {}

-- Errorformat for perl
M.get_errorformat = function()
  return [[%-G%.%#had compilation errors.,]]
    .. [[%-G%.%#syntax OK,%m at %f line %l.,]]
    .. [[%+A%.%# at %f line %l\,%.%#,%+C%.%#]]
end

return M
