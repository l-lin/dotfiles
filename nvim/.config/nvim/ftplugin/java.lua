local jdtls = require("jdtls")

local home = os.getenv("HOME")
local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }
local root_dir = require("jdtls.setup").find_root(root_markers)
if root_dir == "" then
  return
end

local create_cmd = function()
  -- points to $HOME/.local/share/nvim/mason/packages/jdtls/
  local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"

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
local create_init_options = function()
  local java_debug_adapter_path = vim.fn.stdpath("data") .. "/mason/packages/java-debug-adapter"
  local vscode_java_test_path = home .. "/.local/share/vscode-java-test"
  local vscode_java_decompiler_path = vim.fn.stdpath("data") .. "/mason/packages/vscode-java-decompiler"

  local jar_patterns = {
    java_debug_adapter_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
    vscode_java_decompiler_path .. "/server/*.jar",
    vscode_java_test_path .. "/java-extension/com.microsoft.java.test.plugin/target/*.jar",
    vscode_java_test_path .. "/java-extension/com.microsoft.java.test.runner/target/*.jar",
  }
  local plugin_path = vscode_java_test_path ..
      "/java-extension/com.microsoft.java.test.plugin.site/target/repository/plugins/"
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
      if
          not vim.endswith(bundle, "com.microsoft.java.test.runner-jar-with-dependencies.jar")
          and not vim.endswith(bundle, "com.microsoft.java.test.runner.jar")
      then
        table.insert(bundles, bundle)
      end
    end
  end

  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  return {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities
  }
end

local create_capabilities = function()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
  return capabilities
end

local on_attach = function(client, bufnr)
  -- With `hotcodereplace = 'auto' the debug adapter will try to apply code changes
  -- you make during a debug session immediately.
  -- Remove the option if you do not want that.
  require('jdtls').setup_dap({ hotcodereplace = 'auto' })
  require("jdtls.dap").setup_dap_main_class_configs()
  jdtls.setup.add_commands()
end

-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local config = {}
config.cmd = create_cmd()
config.init_options = create_init_options()
config.capabilities = create_capabilities()
config.on_attach = on_attach
config.root_dir = root_dir
config.flags = {
  allow_incremental_sync = true,
  debounce_text_changes = 80,
}
-- Here you can configure eclipse.jdt.ls specific settings
-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
-- for a list of options
config.settings = {
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
    -- format = {
    --   enabled = true,
    --   settings = {
    --     url = vim.fn.stdpath "config" .. "/lang-servers/intellij-java-google-style.xml",
    --     profile = "GoogleStyle",
    --   },
    -- },
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

jdtls.start_or_attach(config)

-- -------------------------------
-- GLOBAL VARIABLES
-- -------------------------------
-- java convention is 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = vim.o.tabstop

-- -------------------------------
-- KEYMAPS
-- -------------------------------
local map = vim.keymap.set

map("n", "<M-C-V>", jdtls.extract_variable,
  { noremap = true, silent = true, desc = "Extract variable" })
map("v", "<M-C-V>", [[<ESC><CMD>lua require("jdtls").extract_variable(true)<CR>]],
  { noremap = true, silent = true, desc = "Extract variable" })

map("n", "<M-C-C>", jdtls.extract_constant,
  { noremap = true, silent = true, desc = "Extract constant" })
map("v", "<M-C-C>", [[<ESC><CMD>lua require("jdtls").extract_constant(true)<CR>]],
  { noremap = true, silent = true, desc = "Extract constant" })

map("v", "<M-C-N>", [[<ESC><CMD>lua require("jdtls").extract_method(true)<CR>]],
  { noremap = true, silent = true, desc = "Extract method" })

map("n", "<F33>", jdtls.compile,
  { noremap = true, silent = true, desc = "Compile (Ctrl+F9)" })
map("n", "<M-C-O>", jdtls.organize_imports,
  { noremap = true, silent = true, desc = "Organize imports (Ctrl+Alt+o)" })

-- custom keymaps for Java test runner (not yet compatible with neotest)
map("n", "<M-S-F9>", jdtls.pick_test,
  { noremap = true, silent = true, desc = "Run specific test (Alt+Shift+F9)" })
map("n", "<F21>", jdtls.test_nearest_method,
  { noremap = true, silent = true, desc = "Test method (Shift+F9)" })
