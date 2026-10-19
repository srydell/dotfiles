local M = {}

local DEFAULT_BROWSER = {
  Darwin = 'Safari',
  Linux = 'firefox-developer-edition',
}

-- Encode query values before putting editor text into a URL.
local function url_encode(value)
  return tostring(value):gsub('[^%w%-_%.~]', function(char)
    return string.format('%%%02X', string.byte(char))
  end)
end

local function cmake_version()
  if vim.g.has_cmake_version_string then
    return vim.g.has_cmake_version_string
  end

  local output = vim.fn.systemlist({ 'cmake', '--version' })
  local first_line = output[1] or ''
  vim.g.has_cmake_version_string = first_line:match('(%d+%.%d+)') or ''

  return vim.g.has_cmake_version_string
end

local function system_name()
  return (vim.uv or vim.loop).os_uname().sysname
end

local function current_filetype()
  return vim.bo.filetype:match('^[^.]+') or ''
end

-- Returns the currently (charwise/linewise/blockwise) visually selected text,
-- joining multiple lines with a space so it can be used as a search query.
local function visual_selection()
  -- Leave visual mode so the '< and '> marks reflect the active selection.
  local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'nx', false)

  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])

  if #lines == 0 then
    return ''
  end

  lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  lines[1] = string.sub(lines[1], start_pos[3])

  return table.concat(lines, ' ')
end

-- Map of filetype -> function(encoded_word) returning the docs search URL to open.
local URL_FOR_FILETYPE = {
  cpp = function(encoded_word)
    return 'https://en.cppreference.com/index.php?search=' .. encoded_word .. '&title=Special%3ASearch&go='
  end,

  cmake = function(encoded_word)
    return 'https://cmake.org/cmake/help/v'
      .. cmake_version()
      .. '/search.html?q='
      .. encoded_word
      .. '&check_keywords=yes&area=default'
  end,

  elixir = function(encoded_word)
    return 'https://hexdocs.pm/elixir/search.html?q=' .. encoded_word
  end,

  markdown = function(encoded_word)
    return 'https://duckduckgo.com/?q=meaning+' .. encoded_word .. '&ia=qa'
  end,
}

local function default_url(encoded_word, filetype)
  return 'https://duckduckgo.com/?q=' .. url_encode(filetype) .. '+' .. encoded_word .. '&ia=qa'
end

function M.url_for(filetype, word)
  local encoded_word = url_encode(word)
  local url_builder = URL_FOR_FILETYPE[filetype]

  if url_builder then
    return url_builder(encoded_word)
  end

  return default_url(encoded_word, filetype)
end

local function browser_command(url)
  local os = system_name()
  local browser = vim.g.browser or DEFAULT_BROWSER[os] or DEFAULT_BROWSER.Linux

  if os == 'Darwin' then
    return { 'open', '-a', browser, url }
  end

  return { browser, url }
end

function M.open()
  local filetype = current_filetype()
  local mode = vim.fn.mode()
  local word

  if mode == 'v' or mode == 'V' or mode == '\22' then
    word = visual_selection()
  else
    word = vim.fn.expand('<cword>')
  end

  if filetype == 'vim' then
    vim.cmd.help(word)
    return
  end

  local url = M.url_for(filetype, word)

  -- Passing arguments as a list avoids Vim command-line expansion of strings like "%3A".
  vim.fn.jobstart(browser_command(url), { detach = true })
end

return M
