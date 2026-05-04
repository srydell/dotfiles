local srydell_cpp = vim.api.nvim_create_augroup('srydell_cpp', { clear = true })

vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  pattern = { '*.cpp', '*.h', '*.hpp' },
  group = srydell_cpp,
  callback = function()
    local ts_cpp = require('srydell.treesitter.cpp')
    -- Include what is used
    ts_cpp.include_necessary_types({
      ['fmt::format'] = '<fmt/format.h>',
      ['fmt::print'] = '<fmt/format.h>',

      -- DSF/OAL
      ['oal::Isocket'] = '<oal_socket.h>',
      ['oal::Isocket_mux'] = '<oal_socket_mux.h>',
      ['oal::Timestamp'] = '<oal_time.h>',
      ['oal::Ref'] = '<oal_ref.h>',
      ['oal::Socket_address'] = '<oal_socket_address.h>',
      ['dsf::Sequence_range'] = '"util/sequence_range.h"',
      ['dsf::result_t'] = '"util/result.h"',
      ['util::Url'] = '"util/url.h"',
    })

    -- Sort and divide them reasonably
    ts_cpp.divide_and_sort_includes()
  end,
})

vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  pattern = { '*.h', '*.hpp' },
  group = srydell_cpp,
  callback = function()
    local ts_cpp = require('srydell.treesitter.cpp')
    ts_cpp.correct_include_guard()
  end,
})
