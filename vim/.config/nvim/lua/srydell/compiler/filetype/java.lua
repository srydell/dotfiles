local constants = require('srydell.constants')

local function get_compilers()
  return {
    { name = 'maven ' .. constants.icons.building, tasks = { 'maven' } },
    {
      name = 'test ' .. constants.icons.debugging,
      tasks = {
        {
          'lua function',
          f = function()
            require('jdtls').pick_test()
            return true
          end,
        },
      },
    },
  }
end

return get_compilers()
