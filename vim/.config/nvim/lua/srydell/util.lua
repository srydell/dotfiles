M = {}
M.split = function(str, delimiter)
  local result = {};
  for match in (str..delimiter):gmatch("(.-)"..delimiter) do
    if match ~= '' then
      table.insert(result, match);
    end
  end

  return result;
end

return M
