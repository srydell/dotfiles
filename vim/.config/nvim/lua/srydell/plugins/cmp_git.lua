return {
  'petertriho/cmp-git',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('cmp_git').setup({
      gitlab = {
        -- Requires GITLAB_TOKEN and GITLAB_URL environment variable
        hosts = { os.getenv('GITLAB_URL') or '' },
      },
    })
  end,
}
