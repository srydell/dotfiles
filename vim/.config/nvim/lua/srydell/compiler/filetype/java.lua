local constants = require('srydell.constants')

local function get_compilers()
  return {
    { name = 'maven ' .. constants.icons.building, tasks = { 'maven' }, type = 'overseer' },
    {
      name = 'test ' .. constants.icons.debugging,
      tasks = function()
        require('jdtls').pick_test()
      end,
      type = 'function',
    },
  }
end

return get_compilers()
