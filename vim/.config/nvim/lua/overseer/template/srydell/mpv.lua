return {
  name = 'mpv',
  desc = 'Watch a file with mpv',
  params = {
    args = {
      type = 'list',
      optional = false,
      subtype = { type = 'string' },
    },
  },
  builder = function(params)
    return {
      cmd = { 'mpv' },
      args = {
        unpack(params.args),
      },
      components = {
        { 'srydell.on_start_save_all' },
        'default',
      },
    }
  end,
}
