local languages = {
  'c',
  'cmake',
  'cpp',
  'dockerfile',
  'eex',
  'elixir',
  'git_config',
  'git_rebase',
  'gitattributes',
  'gitignore',
  'heex',
  'helm',
  'html',
  'java',
  'javascript',
  'json',
  'json5',
  'kotlin',
  'lua',
  'markdown',
  'markdown_inline',
  'objc',
  'python',
  'query',
  'rst',
  'scheme',
  'swift',
  'terraform',
  'tmux',
  'toml',
  'vim',
  'vimdoc',
  'yaml',
}

local max_filesize = 512 * 1024

local function should_enable_treesitter(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then
    return true
  end

  local stat = vim.uv.fs_stat(name)
  return not stat or stat.size <= max_filesize
end

return {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  build = function()
    require('nvim-treesitter').install(languages, { summary = true }):wait(300000)
  end,
  config = function()
    local parsers = require('nvim-treesitter.parsers')

    if parsers.ft_to_lang == nil then
      parsers.ft_to_lang = function(ft)
        return vim.treesitter.language.get_lang(ft) or ft
      end
    end

    if parsers.get_parser == nil then
      parsers.get_parser = function(bufnr, lang)
        local parser = vim.treesitter.get_parser(bufnr, lang, { error = false })
        return parser
      end
    end

    local ts_group = vim.api.nvim_create_augroup('srydell_treesitter', { clear = true })

    vim.api.nvim_create_autocmd('FileType', {
      group = ts_group,
      pattern = languages,
      callback = function(args)
        if not should_enable_treesitter(args.buf) then
          return
        end

        pcall(vim.treesitter.start, args.buf)
      end,
    })

    require('nvim-treesitter-textobjects').setup({
      move = {
        set_jumps = true,
      },
      select = {
        lookahead = true,
      },
    })

    local select = require('nvim-treesitter-textobjects.select')
    local move = require('nvim-treesitter-textobjects.move')
    local swap = require('nvim-treesitter-textobjects.swap')
    local ts_repeat_move = require('nvim-treesitter-textobjects.repeatable_move')

    vim.keymap.set({ 'x', 'o' }, 'af', function()
      select.select_textobject('@function.outer', 'textobjects')
    end)
    vim.keymap.set({ 'x', 'o' }, 'if', function()
      select.select_textobject('@function.inner', 'textobjects')
    end)
    vim.keymap.set({ 'x', 'o' }, 'ac', function()
      select.select_textobject('@class.outer', 'textobjects')
    end)
    vim.keymap.set({ 'x', 'o' }, 'ic', function()
      select.select_textobject('@class.inner', 'textobjects')
    end, { desc = 'Select inner part of a class region' })

    vim.keymap.set('n', '<leader>aa', function()
      swap.swap_next('@parameter.inner')
    end)
    vim.keymap.set('n', '<leader>aA', function()
      swap.swap_previous('@parameter.inner')
    end)

    vim.keymap.set({ 'n', 'x', 'o' }, ']m', function()
      move.goto_next_start('@function.outer', 'textobjects')
    end)
    vim.keymap.set({ 'n', 'x', 'o' }, ']M', function()
      move.goto_next_end('@function.outer', 'textobjects')
    end)
    vim.keymap.set({ 'n', 'x', 'o' }, '[m', function()
      move.goto_previous_start('@function.outer', 'textobjects')
    end)
    vim.keymap.set({ 'n', 'x', 'o' }, '[M', function()
      move.goto_previous_end('@function.outer', 'textobjects')
    end)

    vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move)
    vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_opposite)
    vim.keymap.set({ 'n', 'x', 'o' }, 'f', ts_repeat_move.builtin_f_expr, { expr = true })
    vim.keymap.set({ 'n', 'x', 'o' }, 'F', ts_repeat_move.builtin_F_expr, { expr = true })
    vim.keymap.set({ 'n', 'x', 'o' }, 't', ts_repeat_move.builtin_t_expr, { expr = true })
    vim.keymap.set({ 'n', 'x', 'o' }, 'T', ts_repeat_move.builtin_T_expr, { expr = true })
  end,
}
