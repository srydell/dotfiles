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

M.contains = function(table, val)
   for i=1,#table do
      if table[i] == val then
         return true
      end
   end
   return false
end

return M
