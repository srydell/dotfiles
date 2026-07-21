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

function M.url_for(filetype, word)
  local encoded_word = url_encode(word)

  if filetype == 'cpp' then
    return 'https://en.cppreference.com/index.php?search=' .. encoded_word .. '&title=Special%3ASearch&go='
  end

  if filetype == 'cmake' then
    return 'https://cmake.org/cmake/help/v'
      .. cmake_version()
      .. '/search.html?q='
      .. encoded_word
      .. '&check_keywords=yes&area=default'
  end

  if filetype == 'elixir' then
    return 'https://hexdocs.pm/elixir/search.html?q=' .. encoded_word
  end

  return 'https://duckduckgo.com/?q=' .. url_encode(filetype) .. '+' .. encoded_word .. '&ia=qa'
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
  local word = vim.fn.expand('<cword>')

  if filetype == 'vim' then
    vim.cmd.help(word)
    return
  end

  local url = M.url_for(filetype, word)

  -- Passing arguments as a list avoids Vim command-line expansion of strings like "%3A".
  vim.fn.jobstart(browser_command(url), { detach = true })
end

return M
