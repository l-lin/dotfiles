local jdtls = require('jdtls')

local jdtls_path = vim.fn.stdpath 'data' .. '/mason/packages/jdtls'
local java_debug_path = vim.fn.stdpath 'data' .. '/mason/packages/java-debug-adapter'

-- Data directory - change it to your liking
local workspace_path = os.getenv 'HOME' .. '/work/'

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = workspace_path .. project_name

local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }
local root_dir = require('jdtls.setup').find_root(root_markers)
if root_dir == '' then
  return
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  jdtls.setup_dap({ hotcodereplace = 'auto' })
  jdtls.setup.add_commands()

  -- -- Default keymaps
  -- local bufopts = { noremap=true, silent=true, buffer=bufnr }
  -- require("lsp.defaults").on_attach(client, bufnr)
  --
  -- -- Java extensions
  -- remap("n", "<C-o>", jdtls.organize_imports, bufopts, "Organize imports")
  -- remap("n", "<leader>vc", jdtls.test_class, bufopts, "Test class (DAP)")
  -- remap("n", "<leader>vm", jdtls.test_nearest_method, bufopts, "Test method (DAP)")
  -- remap("n", "<space>ev", jdtls.extract_variable, bufopts, "Extract variable")
  -- remap("n", "<space>ec", jdtls.extract_constant, bufopts, "Extract constant")
  -- remap("v", "<space>em", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], bufopts, "Extract method")
end

local bundles = {
  vim.fn.glob(java_debug_path .. '/extensions/server/com.microsoft.java.debug.plugin-*.jar'),
}
-- vim.list_extend(bundles, vim.split(vim.fn.glob(home .. '/Projects/vscode-java-test/server/*.jar'), "\n"))

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- local extendedClientCapabilities = jdtls.extendedClientCapabilities
-- extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local config = {
  cmd = {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xms1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '-javaagent:', jdtls_path .. '/lombok.jar',
    '-jar', vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar'),
    '-configuration', jdtls_path .. '/config_linux',
    '-data', workspace_dir,
  },
  root_dir = root_dir,
  capabilities = capabilities,
  on_attach = on_attach,
  flags = {
    allow_incremental_sync = true,
    debounce_text_changes = 80,
  },
  -- Language server `initializationOptions`
  -- You need to extend the `bundles` with paths to jar files
  -- if you want to use additional eclipse.jdt.ls plugins.
  --
  -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
  --
  -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
  init_options = {
    bundles = bundles,
  },
  -- Here you can configure eclipse.jdt.ls specific settings
  -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  -- for a list of options
  settings = {
    java = {
      eclipse = {
        downloadSources = true,
      },
      configuration = {
        updateBuildConfiguration = 'interactive',
      },
      maven = {
        downloadSources = true,
      },
      implementationsCodeLens = {
        enabled = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      -- format = {
      --   enabled = true,
      --   settings = {
      --     url = vim.fn.stdpath 'config' .. '/lang-servers/intellij-java-google-style.xml',
      --     profile = 'GoogleStyle',
      --   },
      -- },
    },
    signatureHelp = { enabled = true },
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
    },
    contentProvider = { preferred = 'fernflower' },
    -- extendedClientCapabilities = extendedClientCapabilities,
    sources = {
      organizeImports = {
        starThreshold = 9999,
        staticStarThreshold = 9999,
      },
    },
    codeGeneration = {
      toString = {
        template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
      },
      useBlocks = true,
    },
  },
}
local M = {}
function M.make_jdtls_config()
  return config
end

return M
