local jdtls = require('jdtls')
local map = vim.keymap.set

local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }
local root_dir = require('jdtls.setup').find_root(root_markers)
if root_dir == '' then
  return
end

local jdtls_path = vim.fn.stdpath 'data' .. '/mason/packages/jdtls'
local java_debug_path = vim.fn.stdpath 'data' .. '/mason/packages/java-debug-adapter'

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = os.getenv "HOME" .. "/.local/share/eclipse/" .. project_name

-- keymap
map("n", "<M-C-V>", jdtls.extract_variable, { noremap = true, silent = true , desc = "Extract variable" })
map("v", "<M-C-V>", [[<ESC><CMD>lua require('jdtls').extract_variable(true)<CR>]], { noremap = true, silent = true , desc = "Extract variable" })
map("n", "<M-C-C>", jdtls.extract_constant, { noremap = true, silent = true, buffer = bufnr , desc = "Extract constant" })
map("v", "<M-C-C>", [[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]], { noremap = true, silent = true, buffer = bufnr , desc = "Extract constant" })
map("v", "<M-C-N>", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], bufopts, "Extract method")

local bundles = {
  vim.fn.glob(java_debug_path .. '/extensions/server/com.microsoft.java.debug.plugin-*.jar'),
}
-- vim.list_extend(bundles, vim.split(vim.fn.glob(home .. '/Projects/vscode-java-test/server/*.jar'), "\n"))

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local extendedClientCapabilities = jdtls.extendedClientCapabilities
extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

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
    '-XX:+ShowCodeDetailsInExceptionMessages',
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '-javaagent:' .. jdtls_path .. '/lombok.jar',
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
    -- extendedClientCapabilities = extendedClientCapabilities,
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
      filteredTypes = {
        "com.sun.*",
        "io.micrometer.shaded.*",
        "java.awt.*",
        "jdk.*",
        "sun.*",
      },
    },
    contentProvider = { preferred = 'fernflower' },
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
jdtls.start_or_attach(config)

require("jdtls.setup").add_commands()

-- java convention is 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = vim.o.tabstop

