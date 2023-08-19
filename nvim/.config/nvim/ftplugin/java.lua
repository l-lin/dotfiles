local jdtls = require("jdtls")

local home = os.getenv("HOME")
local root_markers = { ".git", "mvnw", "gradlew" }
local root_dir = require("jdtls.setup").find_root(root_markers)
if root_dir == "" then
  return
end

local function create_cmd()
  -- points to $HOME/.local/share/nvim/mason/packages/jdtls/
  local jdtls_path = require("mason-registry").get_package("jdtls"):get_install_path()

  -- use root folder name as the project name
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
  local workspace_dir = home .. "/.local/share/eclipse/" .. project_name

  return {
    "java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xms1g",
    "-XX:+ShowCodeDetailsInExceptionMessages",
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    "-javaagent:" .. jdtls_path .. "/lombok.jar",
    "-jar", vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
    "-configuration", jdtls_path .. "/config_linux",
    "-data", workspace_dir,
  }
end

-- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
local function create_init_options()
  local java_debug_adapter_path = require("mason-registry").get_package("java-debug-adapter"):get_install_path()
  local vscode_java_decompiler_path = require("mason-registry").get_package("vscode-java-decompiler"):get_install_path()
  local vscode_java_test_path = require("mason-registry").get_package("java-test"):get_install_path()

  local jar_patterns = {
    java_debug_adapter_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
    vscode_java_decompiler_path .. "/server/*.jar",
    vscode_java_test_path .. "/extension/server/*.jar",
  }
  local plugin_path = vscode_java_test_path .. "/extension/server/"

  local bundle_list = vim.tbl_map(function(x)
    return require("jdtls.path").join(plugin_path, x)
  end, {
    "junit-jupiter-*.jar",
    "junit-platform-*.jar",
    "junit-vintage-engine_*.jar",
    "org.opentest4j*.jar",
    "org.apiguardian.api_*.jar",
    "org.eclipse.jdt.junit4.runtime_*.jar",
    "org.eclipse.jdt.junit5.runtime_*.jar",
    "org.opentest4j_*.jar",
  })
  vim.list_extend(jar_patterns, bundle_list)

  local bundles = {}
  for _, jar_pattern in ipairs(jar_patterns) do
    for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), "\n")) do
      table.insert(bundles, bundle)
    end
  end

  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  return {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities
  }
end

local function create_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
  return capabilities
end

local function create_flags()
  return {
    allow_incremental_sync = true,
    debounce_text_changes = 80,
  }
end

local function find_associated_test_file()
  local test_filename = vim.fn.expand('%:t'):match('(.+)%..+') .. "Test.java"
  require("telescope.builtin").find_files({ default_text = test_filename })
end

local function attach_keymaps(_, bufnr)
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true, buffer = bufnr }

  map("n", "<M-C-V>", jdtls.extract_variable, bufopts, "Extract variable")
  map("v", "<M-C-V>", [[<ESC><CMD>lua require("jdtls").extract_variable(true)<CR>]], bufopts, "Extract variable")
  map("i", "<M-C-V>", [[<ESC><CMD>lua require("jdtls").extract_variable()<CR>]], bufopts, "Extract variable")

  map("n", "<M-C-C>", jdtls.extract_constant, bufopts, "Extract constant")
  map("v", "<M-C-C>", [[<ESC><CMD>lua require("jdtls").extract_constant(true)<CR>]], bufopts, "Extract constant")
  map("i", "<M-C-C>", [[<ESC><CMD>lua require("jdtls").extract_constant()<CR>]], bufopts, "Extract constant")

  map("v", "<M-C-N>", [[<ESC><CMD>lua require("jdtls").extract_method(true)<CR>]], bufopts, "Extract method")

  map("n", "<F33>", jdtls.compile, bufopts, "Compile (Ctrl+F9)")

  map("n", "<M-C-O>", jdtls.organize_imports, bufopts, "Organize imports (Ctrl+Alt+o)")

  map("n", "<leader>ca", "<cmd>JdtRestart<cr>", bufopts, "Restart jdtls server")

  -- custom keymaps for Java test runner (not yet compatible with neotest)
  map("n", "<M-S-F9>", jdtls.pick_test, bufopts, "Run specific test (Alt+Shift+F9)")
  map("n", "<F21>", jdtls.test_nearest_method, bufopts, "Test method (Shift+F9)")

  map("n", "<C-T>", find_associated_test_file, bufopts, "Find associated test file (Ctrl+Shift+t)")
end

local function on_attach(client, bufnr)
  -- With `hotcodereplace = 'auto' the debug adapter will try to apply code changes
  -- you make during a debug session immediately.
  -- Remove the option if you do not want that.
  require('jdtls').setup_dap({ hotcodereplace = 'auto' })
  require("jdtls.dap").setup_dap_main_class_configs()

  attach_keymaps(client, bufnr)
  require("plugins.lspconfig").attach(client, bufnr)
  require("plugins.lspsaga").attach_keymaps(client, bufnr)

  jdtls.setup.add_commands()
end

-- Here you can configure eclipse.jdt.ls specific settings
-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
-- for a list of options
local function create_settings()
  return {
    java = {
      eclipse = {
        downloadSources = true,
      },
      configuration = {
        updateBuildConfiguration = "interactive",
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
      format = {
        enabled = true,
        settings = {
          url = home .. "/.local/share/eclipse/java-code-style.xml",
          profile = "l-lin",
        }
      },
    },
    signatureHelp = { enabled = true },
    completion = {
      favoriteStaticMembers = {
        "org.hamcrest.MatcherAssert.assertThat",
        "org.hamcrest.Matchers.*",
        "org.hamcrest.CoreMatchers.*",
        "org.junit.jupiter.api.Assertions.*",
        "java.util.Objects.requireNonNull",
        "java.util.Objects.requireNonNullElse",
        "org.mockito.Mockito.*",
        "org.mockito.BDDMockito.*",
      },
      filteredTypes = {
        "com.sun.*",
        "io.micrometer.shaded.*",
        "java.awt.*",
        "jdk.*",
        "sun.*",
      },
    },
    contentProvider = { preferred = "fernflower" },
    sources = {
      organizeImports = {
        starThreshold = 9999,
        staticStarThreshold = 9999,
      },
    },
    codeGeneration = {
      toString = {
        template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
      },
      useBlocks = true,
    }
  }
end

-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local config = {
  cmd = create_cmd(),
  capabilities = create_capabilities(),
  flags = create_flags(),
  init_options = create_init_options(),
  on_attach = on_attach,
  root_dir = root_dir,
  settings = create_settings(),
}
jdtls.start_or_attach(config)

-- -------------------------------
-- GLOBAL VARIABLES
-- -------------------------------
-- java convention is 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = vim.o.tabstop
