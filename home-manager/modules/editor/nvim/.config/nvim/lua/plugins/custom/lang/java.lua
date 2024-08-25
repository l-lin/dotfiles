local root_markers = { ".git", "mvnw", "gradlew" }

local home = os.getenv("HOME")

local function create_cmd()
  -- points to $HOME/.local/share/nvim/mason/packages/jdtls/
  local jdtls_path = require("mason-registry").get_package("jdtls"):get_install_path()
  local lombok_path = require("mason-registry").get_package("lombok-nightly"):get_install_path() .. "/lombok.jar"

  -- use root folder name as the project name
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
  local jdtls_cache_dir = vim.fn.stdpath("cache") .. "/jdtls/" .. project_name

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
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
    "-javaagent:" .. lombok_path,
    "-jar",
    vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
    "-configuration",
    jdtls_path .. "/config_linux",
    "-data",
    jdtls_cache_dir,
  }
end

-- Here you can configure eclipse.jdt.ls specific settings
-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
-- for a list of options
local function create_settings()
  return {
    java = {
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        useBlocks = true,
      },
      completion = {
        favoriteStaticMembers = {
          "org.junit.jupiter.api.Assertions.*",
          "org.assertj.core.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*",
          "org.mockito.BDDMockito.*",
          "io.gatling.javaapi.core.*",
          "io.gatling.javaapi.core.CoreDsl.*",
          "io.gatling.javaapi.http.*",
          "io.gatling.javaapi.http.HttpDsl.*",
          "org.awaitility.Awaitility",
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*",
          "sun.*",
          "org.junit.*",
          "io.gatling.core.*",
          "net.sourceforge.*",
        },
      },
      configuration = {
        updateBuildConfiguration = "interactive",
      },
      contentProvider = {
        preferred = "fernflower",
      },
      eclipse = {
        downloadSources = true,
      },
      format = {
        enabled = true,
        settings = {
          url = home .. "/.local/share/eclipse/java-code-style.xml",
          profile = "l-lin",
        },
      },
      implementationsCodeLens = {
        enabled = true,
      },
      maven = {
        downloadSources = true,
      },
      maxConcurrentBuilds = 12,
      references = {
        includeDecompiledSources = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      signatureHelp = {
        enabled = true,
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
    },
  }
end

-- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
local function create_init_options()
  -- lookup paths for java test and debugger package
  local mason_registry = require("mason-registry")
  local bundles = {}
  if mason_registry.has_package("java-test") and mason_registry.has_package("java-debug-adapter") then
    -- jdtls tools configuration for debugging support
    local java_debug_adapter_pkg = mason_registry.get_package("java-debug-adapter")
    local java_debug_adapter_path = java_debug_adapter_pkg:get_install_path()
    local java_test_pkg = mason_registry.get_package("java-test")
    local java_test_path = java_test_pkg:get_install_path()
    local jar_patterns = {
      java_debug_adapter_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
      java_test_path .. "/extension/server/*.jar",
    }
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
  end
  return {
    bundles = bundles,
  }
end

---@return string root_dir The path to the root directory.
local function get_root_dir()
  return require("jdtls.setup").find_root(root_markers)
end

-- Attach jdtls for the proper filetypes (i.e. java).
-- Existing server will be reused if the root_dir matches.
local function start_or_attach_jdtls()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "java" },
    callback = function()
      local jdtls_base_config = {
        cmd = create_cmd(),
        root_dir = get_root_dir(),
        init_options = create_init_options(),
        -- enable CMP capabilities
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
        settings = create_settings(),
      }
      local jdtls_opts = require("lazyvim.util").opts("nvim-jdtls")
      require("jdtls").start_or_attach(vim.tbl_deep_extend("force", jdtls_base_config, jdtls_opts or {}))
    end,
  })
end

-- Setup keymap and dap after the lsp is fully attached
-- https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
-- https://neovim.io/doc/user/lsp.html#LspAttach
local function attach_keymaps()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      --  only after the jdtls client is attached
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      -- check client is not nil
      if client and client.name == "jdtls" then
        local jdtls = require("jdtls")
        local jdtls_test = require("jdtls.tests")
        local map = vim.keymap.set

        map("n", "<M-C-V>", jdtls.extract_variable_all, { noremap = true, silent = true, desc = "Extract variable" })
        map("v", "<M-C-V>", [[<ESC><CMD>lua require("jdtls").extract_variable_all(true)<CR>]], { noremap = true, silent = true, desc = "Extract variable" })
        map("i", "<M-C-V>", [[<ESC><CMD>lua require("jdtls").extract_variable_all()<CR>]], { noremap = true, silent = true, desc = "Extract variable" })

        map("n", "<M-C-C>", jdtls.extract_constant, { noremap = true, silent = true, desc = "Extract constant" })
        map("v", "<M-C-C>", [[<ESC><CMD>lua require("jdtls").extract_constant(true)<CR>]], { noremap = true, silent = true, desc = "Extract constant" })
        map("i", "<M-C-C>", [[<ESC><CMD>lua require("jdtls").extract_constant()<CR>]], { noremap = true, silent = true, desc = "Extract constant" })

        map("v", "<M-C-N>", [[<ESC><CMD>lua require("jdtls").extract_method(true)<CR>]], { noremap = true, silent = true, desc = "Extract method" })

        map("n", "<F33>", jdtls.compile, { noremap = true, silent = true, desc = "Compile (Ctrl+F9)" })
        map("n", "<M-C-O>", jdtls.organize_imports, { noremap = true, silent = true, desc = "Organize imports (Ctrl+Alt+o)" })
        map("n", "<leader>cR", "<cmd>JdtRestart<cr>", { noremap = true, silent = true, desc = "Restart jdtls server" })
        map("n", "<C-T>", jdtls_test.goto_subjects, { noremap = true, silent = true, desc = "Find associated test or class file (Ctrl+t)" })

        local wk = require("which-key")
        wk.add({
          {
            mode = "n",
            buffer = args.buf,
            { "<leader>cx", group = "extract" },
            { "<leader>cxv", require("jdtls").extract_variable_all, desc = "Extract Variable" },
            { "<leader>cxc", require("jdtls").extract_constant, desc = "Extract Constant" },
            { "gs", require("jdtls").super_implementation, desc = "Goto Super" },
            { "gS", require("jdtls.tests").goto_subjects, desc = "Goto Subjects" },
            { "<leader>co", require("jdtls").organize_imports, desc = "Organize Imports" },
          },
        })
        wk.add({
          {
            mode = "v",
            buffer = args.buf,
            { "<leader>cx", group = "extract" },
            { "<leader>cxm", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], desc = "Extract Method", },
            { "<leader>cxv", [[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]], desc = "Extract Variable", },
            { "<leader>cxc", [[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]], desc = "Extract Constant", },
          },
        })

        local mason_registry = require("mason-registry")
        if mason_registry.has_package("java-debug-adapter") then
          -- custom init for Java debugger
          jdtls.setup_dap({ hotcodereplace = "auto", config_overrides = {} })
          require("jdtls.dap").setup_dap_main_class_configs()
          -- setup dap config by VsCode launch.json file
          require("dap.ext.vscode").load_launchjs()

          -- Java Test require Java debugger to work
          if mason_registry.has_package("java-test") then
            -- custom keymaps for Java test runner (not yet compatible with neotest)
            -- enable junit extension detection to activate https://github.com/laech/java-stacksrc
            local jdtls_test_opts = {
              config_overrides = {
                vmArgs = "-Djunit.jupiter.extensions.autodetection.enabled=true --enable-preview",
              },
            }
            map("n", "<M-S-F9>", function() jdtls.pick_test(jdtls_test_opts) end, { noremap = true, silent = true, desc = "Run specific test (Alt+Shift+F9)" })
            map("n", "<F21>", function() jdtls.test_nearest_method(jdtls_test_opts) end, { noremap = true, silent = true, desc = "Test method (Shift+F9)" })

            wk.add({
              {
                mode = "n",
                buffer = args.buf,
                { "<leader>t", group = "test" },
                { "<leader>tt", function() jdtls.test_class(jdtls_test_opts) end, desc = "Run All Test", },
                { "<leader>tr", function() jdtls.test_nearest_method(jdtls_test_opts) end, desc = "Run nearest test (Shift+F9)", },
                { "<leader>tT", function() jdtls.pick_test(jdtls_test_opts) end, desc = "Run specific test (Alt+Shift+F9)" },
              },
            })
          end
        end
      end
    end,
  })
end

---Configure JDTLS server by starting the LSP server and attaching keymaps.
local function jdtls_config()
  if get_root_dir() == nil then
    return
  end
  start_or_attach_jdtls()
  attach_keymaps()
end

local M = {}
M.root_markers = root_markers
M.jdtls_config = jdtls_config
return M
