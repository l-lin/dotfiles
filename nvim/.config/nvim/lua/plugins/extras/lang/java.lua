-- code from https://github.com/LazyVim/LazyVim/pull/1300 adapted for my needs
local home = os.getenv("HOME")

local function create_cmd()
  -- points to $HOME/.local/share/nvim/mason/packages/jdtls/
  local jdtls_path = require("mason-registry").get_package("jdtls"):get_install_path()

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
    "-javaagent:" .. jdtls_path .. "/lombok.jar",
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
        },
      },
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
          "org.junit.*",
        },
      },
      signatureHelp = { enabled = true },
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
    local java_test_pkg = mason_registry.get_package("java-test")
    local java_test_path = java_test_pkg:get_install_path()
    local java_dbg_pkg = mason_registry.get_package("java-debug-adapter")
    local java_dbg_path = java_dbg_pkg:get_install_path()
    local jar_patterns = {
      java_dbg_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
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

-- local function find_associate_test_or_class_file()
--   local default_text = ""
--   local filename = vim.fn.expand("%:t"):match("(.+)%..+")
--   if filename:sub(- #"Test") == "Test" then
--     default_text = filename:gsub("Test", "") .. ".java"
--   else
--     default_text = filename .. "Test.java"
--   end
--   require("telescope.builtin").find_files({ default_text = default_text })
-- end

return {
  -- Add java to treesitter.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "java" })
      end
    end,
  },

  -- Ensure java debugger and test packages are installed
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "java-test", "java-debug-adapter" })
        end,
      },
    },
  },

  -- Set up lsp
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- make sure mason installs the server
      servers = {
        jdtls = {},
      },
      setup = {
        jdtls = function()
          return true -- avoid duplicate servers
        end,
      },
    },
  },

  -- Set up nvim-jdtls
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    config = function()
      -- The configuration for jdtls contains two useful items:
      -- 1. The list of filetypes on which to match.
      -- 2. Custom method for finding the root for a java project.
      local root_markers = { ".git", "mvnw", "gradlew" }
      local root_dir = require("jdtls.setup").find_root(root_markers)
      if root_dir == "" then
        return
      end

      -- Attach jdtls for the proper filetypes (i.e. java).
      -- Existing server will be reused if the root_dir matches.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "java" },
        callback = function()
          local jdtls_base_config = {
            cmd = create_cmd(),
            root_dir = root_dir,
            init_options = create_init_options(),
            -- enable CMP capabilities
            capabilities = require("cmp_nvim_lsp").default_capabilities(),
            settings = create_settings(),
          }
          local jdtls_opts = require("lazyvim.util").opts("nvim-jdtls")
          require("jdtls").start_or_attach(vim.tbl_deep_extend("force", jdtls_base_config, jdtls_opts or {}))
        end,
      })

      -- Setup keymap and dap after the lsp is fully attached
      -- https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
      -- https://neovim.io/doc/user/lsp.html#LspAttach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          --  only after the jdtls client is attached
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client.name == "jdtls" then
            local jdtls = require("jdtls")
            local jdtls_test = require("jdtls.tests")
            vim.keymap.set(
              "n",
              "<M-C-V>",
              jdtls.extract_variable_all,
              { noremap = true, silent = true, desc = "Extract variable" }
            )
            vim.keymap.set(
              "v",
              "<M-C-V>",
              [[<ESC><CMD>lua require("jdtls").extract_variable_all(true)<CR>]],
              { noremap = true, silent = true, desc = "Extract variable" }
            )

            vim.keymap.set(
              "i",
              "<M-C-V>",
              [[<ESC><CMD>lua require("jdtls").extract_variable_all()<CR>]],
              { noremap = true, silent = true, desc = "Extract variable" }
            )
            vim.keymap.set(
              "n",
              "<M-C-C>",
              jdtls.extract_constant,
              { noremap = true, silent = true, desc = "Extract constant" }
            )
            vim.keymap.set(
              "v",
              "<M-C-C>",
              [[<ESC><CMD>lua require("jdtls").extract_constant(true)<CR>]],
              { noremap = true, silent = true, desc = "Extract constant" }
            )
            vim.keymap.set(
              "i",
              "<M-C-C>",
              [[<ESC><CMD>lua require("jdtls").extract_constant()<CR>]],
              { noremap = true, silent = true, desc = "Extract constant" }
            )

            vim.keymap.set(
              "v",
              "<M-C-N>",
              [[<ESC><CMD>lua require("jdtls").extract_method(true)<CR>]],
              { noremap = true, silent = true, desc = "Extract method" }
            )

            vim.keymap.set("n", "<F33>", jdtls.compile, { noremap = true, silent = true, desc = "Compile (Ctrl+F9)" })

            vim.keymap.set(
              "n",
              "<M-C-O>",
              jdtls.organize_imports,
              { noremap = true, silent = true, desc = "Organize imports (Ctrl+Alt+o)" }
            )

            vim.keymap.set(
              "n",
              "<leader>cR",
              "<cmd>JdtRestart<cr>",
              { noremap = true, silent = true, desc = "Restart jdtls server" }
            )

            vim.keymap.set(
              "n",
              "<C-T>",
              jdtls_test.goto_subjects,
              -- find_associate_test_or_class_file,
              { noremap = true, silent = true, desc = "Find associated test or class file (Ctrl+t)" }
            )

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
                vim.keymap.set(
                  "n",
                  "<M-S-F9>",
                  jdtls.pick_test,
                  { noremap = true, silent = true, desc = "Run specific test (Alt+Shift+F9)" }
                )
                vim.keymap.set(
                  "n",
                  "<F21>",
                  jdtls.test_nearest_method,
                  { noremap = true, silent = true, desc = "Test method (Shift+F9)" }
                )
              end
            end
          end
        end,
      })
    end,
  },
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        progress = {
          -- too much noise in Java, especially when editing Strings
          throttle = 300,
        },
      },
    },
  },
}
