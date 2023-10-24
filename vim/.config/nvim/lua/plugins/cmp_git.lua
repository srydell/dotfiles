return {
  'petertriho/cmp-git',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function ()
    require('cmp_git').setup({
        gitlab = {
          -- Requires GITLAB_TOKEN environment variable
          hosts = { 'git.nasdaq.com', }
        }
      })
  end
}
