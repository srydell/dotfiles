return {
  'stevearc/quicker.nvim',
  event = 'FileType qf',
  config = function()
    require('quicker').setup({
      highlight = {
        -- Do not automatically load all the buffers
        -- I create long lists : )
        load_buffers = false,
      },
    })
  end,
}
