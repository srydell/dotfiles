-- Find which container to exec into: reuses srydell.util.docker_container's
-- NVIM_DEV_CONTAINER override / single-container auto-detection (same
-- `docker ps` discovery the LLDB adapter and struct_layout use), just via
-- its synchronous variant since a template builder must return immediately.
-- Caches the result into NVIM_DEV_CONTAINER so later steps in the same
-- build (e.g. patch_compile_commands.py) see the same container without
-- re-running `docker ps`.
local function resolve_container()
  local container, problem = require('srydell.util.docker_container').find_container()
  if container then
    vim.env.NVIM_DEV_CONTAINER = container
  end
  return container, problem
end

return {
  name = 'docker run',
  desc = 'Run a command within a running docker container.',
  params = {
    command = {
      type = 'list',
      optional = false,
      subtype = { type = 'string' },
    },
  },
  builder = function(params)
    local container, problem = resolve_container()
    if not container then
      return {
        cmd = { 'sh', '-c', 'echo "docker run: ' .. problem:gsub('"', '\\"') .. '" >&2; exit 1' },
      }
    end

    return {
      cmd = { 'docker' },
      args = {
        'exec',
        '--workdir',
        vim.fn.getcwd(),
        '-t',
        container,
        'bash',
        unpack(params.command),
      },
      components = {
        { 'srydell.on_start_save_all' },
        -- Pure-Lua diagnostic parsing (see cpp_parser.lua) instead of vim
        -- errorformat; results are only surfaced once, from the fully
        -- buffered output at task completion. This also sidesteps the false
        -- positives `tail = true` errorformat parsing used to hit here: this
        -- task runs under a pty (`docker exec -t`), and waf/ninja's live
        -- progress bar can leave stray partial lines mid-stream that used to
        -- spuriously satisfy the errorformat and open the quickfix window
        -- even for a fully successful build.
        { 'on_output_parse', parser = require('srydell.compiler.helpers.cpp_parser').new_parser() },
        { 'on_result_diagnostics_quickfix', open = true },
        { 'open_output', on_start = 'never', on_complete = 'success', direction = 'horizontal', focus = false },
        'default',
      },
    }
  end,
}
