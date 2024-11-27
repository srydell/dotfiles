local M = {}

function M.setup()
  local jdtls = require('jdtls')
  local jdtls_dap = require('jdtls.dap')
  local jdtls_setup = require('jdtls.setup')
  local home = os.getenv('HOME')

  local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }
  local root_dir = jdtls_setup.find_root(root_markers)

  local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
  local workspace_dir = home .. '/.cache/jdtls/workspace' .. project_name

  -- 💀
  local path_to_mason_packages = home .. '/.local/share/nvim/mason/packages'
  -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                       ^^^^^^^^^^^^^^

  local path_to_jdtls = path_to_mason_packages .. '/jdtls'
  local path_to_jdebug = path_to_mason_packages .. '/java-debug-adapter'
  local path_to_jtest = path_to_mason_packages .. '/java-test'

  local path_to_config = ''
  if vim.fn.has('linux') == 1 then
    path_to_config = path_to_jdtls .. '/config_linux'
  elseif vim.fn.has('mac') == 1 then
    path_to_config = path_to_jdtls .. '/config_mac'
  else
    path_to_config = path_to_jdtls .. '/config_win'
  end

  local lombok_path = path_to_jdtls .. '/lombok.jar'

  -- 💀
  local path_to_jar = path_to_jdtls .. '/plugins/org.eclipse.equinox.launcher_1.6.800.v20240330-1250.jar'
  -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                          ^^^^^^^^^^^^^^^^^^^^^^

  local bundles = {
    vim.fn.glob(path_to_jdebug .. '/extension/server/com.microsoft.java.debug.plugin-*.jar', true),
  }

  vim.list_extend(bundles, vim.split(vim.fn.glob(path_to_jtest .. '/extension/server/*.jar', true), '\n'))

  -- LSP settings for Java.
  local on_attach = function(_, bufnr)
    local opts = { noremap = true, silent = true, buffer = bufnr }
    jdtls.setup_dap({ hotcodereplace = 'auto' })
    jdtls_dap.setup_dap_main_class_configs()
    jdtls_setup.add_commands()

    opts.buffer = bufnr

    opts.desc = 'Rename declarator'
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    opts.desc = 'Apply code action'
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)

    opts.desc = 'Go to definition'
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    opts.desc = 'Go to implementation'
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    opts.desc = 'Show references for declarator under cursor'
    vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, opts)
    -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    opts.desc = 'Show documentation for what is under cursor'
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

    -- Create a command `:Format` local to the LSP buffer
    -- vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    --   vim.lsp.buf.format()
    -- end, { desc = 'Format current buffer with LSP' })

    -- require('lsp_signature').on_attach({
    --   bind = true,
    --   padding = '',
    --   handler_opts = {
    --     border = 'rounded',
    --   },
    --   hint_prefix = '󱄑 ',
    -- }, bufnr)

    -- NOTE: comment out if you don't use Lspsaga
    -- require('lspsaga').init_lsp_saga()
  end

  local capabilities = {
    workspace = {
      configuration = true,
    },
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
        },
      },
    },
  }

  local config = {
    flags = {
      allow_incremental_sync = true,
    },
  }

  config.cmd = {
    --
    --      -- 💀
    'java', -- or '/path/to/java17_or_newer/bin/java'
    -- depends on if `java` is in your $PATH env variable and if it points to the right version.

    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx1g',
    '-javaagent:' .. lombok_path,
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',

    -- 💀
    '-jar',
    path_to_jar,
    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                       ^^^^^^^^^^^^^^
    -- Must point to the                                                     Change this to
    -- eclipse.jdt.ls installation                                           the actual version

    -- 💀
    '-configuration',
    path_to_config,
    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        ^^^^^^
    -- Must point to the                      Change to one of `linux`, `win` or `mac`
    -- eclipse.jdt.ls installation            Depending on your system.

    -- 💀
    -- See `data directory configuration` section in the README
    '-data',
    workspace_dir,
  }

  config.settings = {
    java = {
      references = {
        includeDecompiledSources = true,
      },
      format = {
        enabled = false,
        -- settings = {
        --   url = vim.fn.stdpath('config') .. '/lang_servers/intellij-java-google-style.xml',
        --   profile = 'GoogleStyle',
        -- },
      },
      eclipse = {
        downloadSources = true,
      },
      maven = {
        downloadSources = true,
      },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' },
      -- eclipse = {
      -- 	downloadSources = true,
      -- },
      -- implementationsCodeLens = {
      -- 	enabled = true,
      -- },
      completion = {
        favoriteStaticMembers = {
          'org.hamcrest.MatcherAssert.assertThat',
          'org.hamcrest.Matchers.*',
          'org.hamcrest.CoreMatchers.*',
          'org.junit.jupiter.api.Assertions.*',
          'java.util.Objects.requireNonNull',
          'java.util.Objects.requireNonNullElse',
          'org.mockito.Mockito.*',
        },
        filteredTypes = {
          'com.sun.*',
          'io.micrometer.shaded.*',
          'java.awt.*',
          'jdk.*',
          'sun.*',
        },
        importOrder = {
          'java',
          'javax',
          'com',
          'org',
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
          -- flags = {
          -- 	allow_incremental_sync = true,
          -- },
        },
        useBlocks = true,
      },
      -- configuration = {
      --     runtimes = {
      --         {
      --             name = "java-17-openjdk",
      --             path = "/usr/lib/jvm/default-runtime/bin/java"
      --         }
      --     }
      -- }
      project = {
        referencedLibraries = {
          '**/lib/*.jar',
        },
      },
    },
  }

  config.on_attach = on_attach
  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
  config.capabilities = capabilities
  config.on_init = function(client, _)
    client.notify('workspace/didChangeConfiguration', { settings = config.settings })
  end

  config.init_options = {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities,
  }

  -- Start Server
  require('jdtls').start_or_attach(config)

  -- Set Java Specific Keymaps
  -- require('jdtls.keymaps')
end

return M
