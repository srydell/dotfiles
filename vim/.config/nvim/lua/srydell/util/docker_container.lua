-- Shared "find a running Docker container to talk to" helper.
--
-- NVIM_DEV_CONTAINER (despite the name, used by any caller here) still lets
-- you pin a container by name/ID and skip the picker.
local M = {}

local selected_container

-- Shared with both the async and sync discovery paths below.
local DOCKER_PS_ARGS = { 'docker', 'ps', '--format', '{{.ID}}\\t{{.Names}}\\t{{.Image}}' }

function M.format_problem(problem, remedy, detail)
  local message = problem
  if detail and detail ~= '' then
    message = message .. '\n\nDetails:\n' .. detail
  end
  if remedy and remedy ~= '' then
    message = message .. '\n\nHow to fix it:\n' .. remedy
  end
  return message
end

local function notify_error(title, problem, remedy, detail)
  vim.schedule(function()
    vim.notify(M.format_problem(problem, remedy, detail), vim.log.levels.ERROR, { title = title })
  end)
end

function M.parse_containers(output)
  local containers = {}
  for line in output:gmatch('[^\r\n]+') do
    local id, name, image = line:match('^([^\t]+)\t([^\t]+)\t(.+)$')
    if id then
      containers[#containers + 1] = {
        id = id,
        name = name,
        image = image,
      }
    end
  end
  return containers
end

local function choose_container(containers, title, callback)
  local configured = vim.env.NVIM_DEV_CONTAINER
  if configured and configured ~= '' then
    for _, container in ipairs(containers) do
      if container.id == configured or container.name == configured then
        selected_container = configured
        callback(configured)
        return
      end
    end
    local names = vim.tbl_map(function(container)
      return '  ' .. container.name
    end, containers)
    notify_error(
      title,
      ("NVIM_DEV_CONTAINER is set to '%s', but that container is not running."):format(configured),
      table.concat({
        'Start that container, or change/unset NVIM_DEV_CONTAINER.',
        'Running containers:',
        table.concat(names, '\n'),
        'Verify with: docker ps',
      }, '\n')
    )
    callback(nil)
    return
  end

  if selected_container then
    for _, container in ipairs(containers) do
      if container.id == selected_container or container.name == selected_container then
        callback(selected_container)
        return
      end
    end
    selected_container = nil
  end

  if #containers == 1 then
    selected_container = containers[1].name
    callback(selected_container)
    return
  end

  vim.schedule(function()
    vim.ui.select(containers, {
      prompt = 'Container: ',
      format_item = function(container)
        return ('%s  [%s]'):format(container.name, container.image)
      end,
    }, function(container)
      selected_container = container and container.name or nil
      callback(selected_container)
    end)
  end)
end

-- Find a running Docker container and hand its name/ID to `callback`.
-- `callback(nil)` on any failure (Docker missing, no containers, user
-- cancelled the picker); problems are reported via vim.notify with a title
-- of `opts.title` (defaults to 'Docker').
function M.with_container(callback, opts)
  opts = opts or {}
  local title = opts.title or 'Docker'

  if vim.fn.executable('docker') ~= 1 then
    notify_error(
      title,
      'The Docker CLI is not available in Neovim PATH.',
      table.concat({
        'macOS: install and start Docker Desktop, then restart Neovim.',
        'Arch Linux: install docker (or docker-cli for a remote daemon).',
        'Verify in the same shell with: docker version',
      }, '\n')
    )
    vim.schedule(function()
      callback(nil)
    end)
    return
  end

  vim.system(DOCKER_PS_ARGS, { text = true }, function(result)
    if result.code ~= 0 then
      notify_error(
        title,
        'Docker is installed, but the active Docker context cannot list containers.',
        table.concat({
          'Start Docker or select a working context:',
          '  docker context ls',
          '  docker context use <context>',
          'Then verify access with:',
          '  docker ps',
          'On Linux, also check your Docker socket permissions.',
        }, '\n'),
        vim.trim(result.stderr or 'unknown error')
      )
      vim.schedule(function()
        callback(nil)
      end)
      return
    end

    local containers = M.parse_containers(result.stdout or '')
    if #containers == 0 then
      notify_error(
        title,
        'The active Docker context has no running containers.',
        table.concat({
          'Start the intended container, then verify it appears with:',
          '  docker ps',
          'Stopped containers can be inspected with:',
          '  docker ps -a',
        }, '\n')
      )
      vim.schedule(function()
        callback(nil)
      end)
      return
    end
    vim.schedule(function()
      choose_container(containers, title, callback)
    end)
  end)
end

-- Synchronous counterpart of `with_container`, for callers that can't take a
-- callback (e.g. overseer template builders, which must return a task
-- definition immediately). Same NVIM_DEV_CONTAINER override and `docker ps`
-- discovery, but no interactive picker for multiple containers -- there's no
-- UI to prompt synchronously here, so that case is just reported as an error
-- like every other failure: returns `nil, problem` instead of notifying.
function M.find_container()
  if vim.fn.executable('docker') ~= 1 then
    return nil, 'The Docker CLI is not available in Neovim PATH.'
  end

  local result = vim.system(DOCKER_PS_ARGS, { text = true }):wait()
  if result.code ~= 0 then
    return nil,
      'Docker is installed, but the active Docker context cannot list containers.\n' .. vim.trim(
        result.stderr or 'unknown error'
      )
  end

  local containers = M.parse_containers(result.stdout or '')
  if #containers == 0 then
    return nil, 'The active Docker context has no running containers. Start it, then verify with: docker ps'
  end

  local configured = vim.env.NVIM_DEV_CONTAINER
  if configured and configured ~= '' then
    for _, container in ipairs(containers) do
      if container.id == configured or container.name == configured then
        return configured
      end
    end
    return nil, ("NVIM_DEV_CONTAINER is set to '%s', but that container is not running."):format(configured)
  end

  if #containers == 1 then
    return containers[1].name
  end

  local names = vim.tbl_map(function(container)
    return container.name
  end, containers)
  return nil, 'Multiple containers are running -- set NVIM_DEV_CONTAINER to pick one:\n' .. table.concat(names, '\n')
end

function M.reset()
  selected_container = nil
end

return M
