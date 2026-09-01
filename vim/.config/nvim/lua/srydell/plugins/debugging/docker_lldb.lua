-- Docker LLDB adapter for nvim-dap.
--
-- This module is part of the C/C++ DAP configuration; it is not a standalone
-- plugin and does not need to be loaded manually. lazy.nvim loads
-- `srydell.plugins.debugging` with nvim-dap on VeryLazy. That configuration
-- calls `srydell.plugins.debugging.cpp.setup()`, which requires this module and
-- registers:
--
--   * the `docker_lldb` DAP adapter;
--   * the `Docker: Launch file` C/C++ launch configuration; and
--   * `:DapDockerResetContainer`.
--
-- A launch runs lldb-dap inside the selected container using
-- `docker exec -i`. The Docker CLI may point at a local or remote Docker
-- context; Neovim itself does not need an LLDB installation for this launch.
-- The launch flow:
--
--   1. Verify Docker can list running containers and select one.
--   2. Find lldb-dap (or the older lldb-vscode) inside that container.
--   3. Ask for the project root as seen inside the container. It is mapped to
--      Neovim's current working directory for source lookup.
--   4. Find executable files below that root and select one with Telescope.
--   5. Run ldd on the selected executable and reject unresolved libraries.
--   6. Prompt for shell-style program arguments and start the DAP session.
--
-- Optional environment variables:
--
--   NVIM_DEV_CONTAINER   Container name or ID. Avoids the container picker.
--   NVIM_DAP_REMOTE_ROOT Project root inside the container. Becomes the prompt
--                        default; it does not need to equal the local path.
--
-- Problems are reported when the relevant step is reached, together with
-- concrete remediation. `:DapDockerResetContainer` forgets the selected
-- container and cached adapter path after a container is recreated.
local docker_container = require('srydell.util.docker_container')

local M = {}

local launch_context
local last_argument_string = ''
local verified_lldb = {}

M.format_problem = docker_container.format_problem
M.parse_containers = docker_container.parse_containers

local function notify_error(problem, remedy, detail)
  vim.schedule(function()
    vim.notify(M.format_problem(problem, remedy, detail), vim.log.levels.ERROR, { title = 'Docker LLDB' })
  end)
end

function M.parse_arguments(input)
  local arguments = {}
  local current = {}
  local quote
  local escaped = false
  local started = false

  for index = 1, #input do
    local char = input:sub(index, index)
    if escaped then
      current[#current + 1] = char
      escaped = false
      started = true
    elseif char == '\\' and quote ~= "'" then
      escaped = true
      started = true
    elseif quote then
      if char == quote then
        quote = nil
      else
        current[#current + 1] = char
      end
      started = true
    elseif char == "'" or char == '"' then
      quote = char
      started = true
    elseif char:match('%s') then
      if started then
        arguments[#arguments + 1] = table.concat(current)
        current = {}
        started = false
      end
    else
      current[#current + 1] = char
      started = true
    end
  end

  if escaped then
    return nil, 'arguments end with an unfinished escape'
  end
  if quote then
    return nil, 'arguments contain an unterminated quote'
  end
  if started then
    arguments[#arguments + 1] = table.concat(current)
  end
  return arguments
end

function M.missing_shared_libraries(output)
  local missing = {}
  local seen = {}
  for line in output:gmatch('[^\r\n]+') do
    local library = line:match('^%s*(%S+)%s+=>%s+not found%s*$')
    if library and not seen[library] then
      seen[library] = true
      missing[#missing + 1] = library
    end
  end
  return missing
end

function M.executable_adapter(container, lldb_dap)
  return {
    type = 'executable',
    id = 'lldb',
    command = 'docker',
    args = { 'exec', '-i', container, lldb_dap },
    options = {
      detached = false,
      initialize_timeout_sec = 15,
      disconnect_timeout_sec = 5,
    },
    enrich_config = function(config, on_config)
      local final = vim.deepcopy(config)
      if launch_context then
        final.cwd = launch_context.remote_root
        if launch_context.remote_root ~= launch_context.local_root then
          final.sourceMap = {
            { launch_context.remote_root, launch_context.local_root },
          }
        end
      end
      on_config(final)
    end,
  }
end

local function with_container(callback)
  docker_container.with_container(callback, { title = 'Docker LLDB' })
end

local function find_lldb_dap(container, callback)
  vim.system({
    'docker',
    'exec',
    container,
    'sh',
    '-lc',
    [[
command -v lldb-dap && exit 0
command -v lldb-vscode && exit 0
for executable in /usr/bin/lldb-dap-* /usr/bin/lldb-vscode-*; do
  if [ -x "$executable" ]; then
    printf '%s\n' "$executable"
    exit 0
  fi
done
exit 1
]],
  }, { text = true }, function(result)
    local executable = vim.trim(result.stdout or '')
    if result.code ~= 0 or executable == '' then
      local detail = vim.trim(result.stderr or '')
      if detail ~= '' then
        notify_error(
          ("Could not run debugger discovery inside container '%s'."):format(container),
          table.concat({
            'Confirm that the container is still running and contains a POSIX shell:',
            ('  docker exec %s sh -lc "echo ok"'):format(container),
          }, '\n'),
          detail
        )
      else
        notify_error(
          ("Container '%s' has no LLDB DAP executable."):format(container),
          table.concat({
            'Install LLDB in the image/container, or ask its owner to include it.',
            'Common package commands:',
            '  Debian/Ubuntu: apt-get install lldb',
            '  Arch:          pacman -S lldb',
            '  Fedora:        dnf install lldb',
            '  Alpine:        apk add lldb',
            'Then verify:',
            ('  docker exec %s sh -lc "command -v lldb-dap || command -v lldb-vscode"'):format(container),
          }, '\n')
        )
      end
      vim.schedule(function()
        callback(nil)
      end)
      return
    end
    vim.schedule(function()
      verified_lldb[container] = executable
      callback(executable)
    end)
  end)
end

function M.adapter(callback)
  with_container(function(container)
    if container then
      local executable = verified_lldb[container]
      if executable then
        callback(M.executable_adapter(container, executable))
      else
        find_lldb_dap(container, function(lldb_dap)
          if lldb_dap then
            callback(M.executable_adapter(container, lldb_dap))
          end
        end)
      end
    end
  end)
end

local function find_remote_executables(container, root, callback)
  local script = [[
root=$1
if [ ! -d "$root" ]; then
  printf 'Directory does not exist in container: %s\n' "$root" >&2
  exit 2
fi
if command -v fd >/dev/null 2>&1; then
  exec fd --absolute-path --no-ignore --type x . "$root"
fi
exec find "$root" -type f -perm -111
]]
  vim.system({ 'docker', 'exec', container, 'sh', '-lc', script, 'docker-lldb', root }, { text = true }, callback)
end

local function check_shared_libraries(container, program, callback)
  local script = [[
if ! command -v ldd >/dev/null 2>&1; then
  exit 127
fi
exec ldd "$1"
]]
  vim.system(
    { 'docker', 'exec', container, 'sh', '-lc', script, 'docker-lldb', program },
    { text = true },
    function(result)
      vim.schedule(function()
        local output = table.concat({ result.stdout or '', result.stderr or '' }, '\n')
        local missing = M.missing_shared_libraries(output)
        if #missing > 0 then
          notify_error(
            ('The selected executable has unresolved shared libraries:\n  %s'):format(table.concat(missing, '\n  ')),
            table.concat({
              'Make the libraries visible inside the container before debugging.',
              'For Conan 2 projects, use the same runtime environment as a successful command-line launch.',
              'Depending on the project, that may mean setting an RPATH/RUNPATH, LD_LIBRARY_PATH,',
              'or activating the generated Conan environment.',
              ('Recheck with: docker exec %s ldd %s'):format(container, vim.fn.shellescape(program)),
            }, '\n')
          )
          callback(false)
          return
        end

        if result.code == 127 then
          vim.notify(
            M.format_problem(
              'The executable was selected, but its shared libraries could not be checked because ldd is absent.',
              table.concat({
                'Install the libc tooling provided by the container distribution if you want this check.',
                'Common packages include libc-bin on Debian/Ubuntu and glibc on Arch/Fedora.',
                'Debugging will continue because ldd is not required by LLDB.',
              }, '\n')
            ),
            vim.log.levels.WARN,
            { title = 'Docker LLDB' }
          )
        elseif result.code ~= 0 then
          vim.notify(
            M.format_problem(
              'ldd could not inspect the selected executable; debugging will continue.',
              'This is normally safe for a static binary or a script. Run ldd manually inside the container for details.',
              vim.trim(output)
            ),
            vim.log.levels.WARN,
            { title = 'Docker LLDB' }
          )
        end
        callback(true)
      end)
    end
  )
end

local function pick_with_telescope(items, title, callback)
  vim.schedule(function()
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local finders = require('telescope.finders')
    local pickers = require('telescope.pickers')
    local conf = require('telescope.config').values
    local opts = {}

    pickers
      .new(opts, {
        prompt_title = title,
        finder = finders.new_table({ results = items }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_buffer)
          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_buffer)
            callback(entry and entry[1] or nil)
          end)
          return true
        end,
      })
      :find()
  end)
end

function M.pick_program()
  local dap = require('dap')
  return coroutine.create(function(dap_run_co)
    with_container(function(container)
      if not container then
        coroutine.resume(dap_run_co, dap.ABORT)
        return
      end

      find_lldb_dap(container, function(lldb_dap)
        if not lldb_dap then
          coroutine.resume(dap_run_co, dap.ABORT)
          return
        end

        vim.schedule(function()
          local local_root = vim.fn.getcwd()
          vim.ui.input({
            prompt = ('Project directory in container (maps to %s): '):format(local_root),
            default = vim.env.NVIM_DAP_REMOTE_ROOT or local_root,
          }, function(remote_root)
            if not remote_root or remote_root == '' then
              coroutine.resume(dap_run_co, dap.ABORT)
              return
            end

            find_remote_executables(container, remote_root, function(result)
              vim.schedule(function()
                if result.code ~= 0 then
                  notify_error(
                    ('Cannot search project directory %s in container %s.'):format(remote_root, container),
                    table.concat({
                      'Enter an absolute directory path that exists inside the container.',
                      ('Inspect mounts with: docker inspect %s'):format(container),
                      'To save the correct default, set NVIM_DAP_REMOTE_ROOT.',
                    }, '\n'),
                    vim.trim(result.stderr or '')
                  )
                  coroutine.resume(dap_run_co, dap.ABORT)
                  return
                end

                local executables = vim.split(result.stdout or '', '\n', { trimempty = true })
                if #executables == 0 then
                  notify_error(
                    ('No executable files were found below %s in container %s.'):format(remote_root, container),
                    table.concat({
                      'Build the program with debug information before starting DAP.',
                      'Confirm the result has its executable bit set:',
                      ('  docker exec %s find %s -type f -perm -111'):format(container, remote_root),
                      'If the binary lives elsewhere, enter a broader project directory.',
                    }, '\n')
                  )
                  coroutine.resume(dap_run_co, dap.ABORT)
                  return
                end

                pick_with_telescope(executables, ('Executable in %s'):format(container), function(program)
                  if not program then
                    coroutine.resume(dap_run_co, dap.ABORT)
                    return
                  end
                  launch_context = {
                    container = container,
                    remote_root = remote_root,
                    local_root = local_root,
                  }
                  check_shared_libraries(container, program, function(ok)
                    coroutine.resume(dap_run_co, ok and program or dap.ABORT)
                  end)
                end)
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

function M.prompt_arguments()
  local dap = require('dap')
  return coroutine.create(function(dap_run_co)
    vim.ui.input({
      prompt = 'Program arguments: ',
      default = last_argument_string,
    }, function(input)
      if input == nil then
        coroutine.resume(dap_run_co, dap.ABORT)
        return
      end

      local arguments, err = M.parse_arguments(input)
      if not arguments then
        notify_error(
          'Program arguments are not valid.',
          [[Close quotes and complete trailing escapes. Example: --name "two words" --output escaped\ path]],
          err
        )
        coroutine.resume(dap_run_co, dap.ABORT)
        return
      end
      last_argument_string = input
      coroutine.resume(dap_run_co, arguments)
    end)
  end)
end

function M.reset_container()
  docker_container.reset()
  launch_context = nil
  verified_lldb = {}
  vim.notify(
    'Docker debugger selection and cached adapter paths were reset.',
    vim.log.levels.INFO,
    { title = 'Docker LLDB' }
  )
end

return M
