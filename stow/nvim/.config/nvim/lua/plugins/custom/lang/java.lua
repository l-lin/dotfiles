local root_markers = { ".git", "mvnw", "gradlew" }

local home = os.getenv("HOME")

-- Path to java binary to use when starting up the LS server.
local java_path = home .. "/.nix-profile/bin/java"

-- List of Java runtimes, which can be useful if you're starting jdtls with a
-- Java version that's different from the one the project uses.
-- The field `name` must be a valid `ExecutionEnvironment`,
-- you can find the list here:
-- https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
local function create_runtimes()
  return {
    {
      name = "JavaSE-23",
      path = java_path,
    },
  }
end

local function create_cmd()
  -- Points to $HOME/.local/share/nvim/mason/packages/jdtls/.
  local jdtls_path = require("mason-registry").get_package("jdtls"):get_install_path()

  -- Path to config depending on the platform.
  local platform_config = ""
  if vim.fn.has("mac") == 1 then
    platform_config = jdtls_path .. "/config_mac"
  elseif vim.fn.has("unix") == 1 then
    platform_config = jdtls_path .. "/config_linux"
  elseif vim.fn.has("win32") == 1 then
    platform_config = jdtls_path .. "/config_win"
  end

  -- Path to Lombok JAR.
  local lombok_path = require("mason-registry").get_package("lombok-nightly"):get_install_path() .. "/lombok.jar"

  -- Path to launcher JAR.
  local launcher_path = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher.jar")

  -- Use root folder name as the project name.
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
  local jdtls_cache_dir = vim.fn.stdpath("cache") .. "/jdtls/workspaces/" .. project_name

  return {
    java_path,
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
    launcher_path,
    "-configuration",
    platform_config,
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
          "org.springframework.test.web.servlet.request.*",
          "org.springframework.test.web.servlet.result.*",
          "org.springframework.test.web.servlet.setup.*",
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
        runtimes = create_runtimes(),
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
      project = {
        referencedLibraries = {
          -- add any library jars here for the lsp to pick them up
        },
      },
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
  local bundles = {}
  vim.list_extend(bundles, require("plugins.custom.lang.java-dap").create_bundles() or {})
  vim.list_extend(bundles, require("plugins.custom.lang.java-test").create_bundles() or {})
  return { bundles = bundles }
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
        capabilities = require("blink.cmp").get_lsp_capabilities(),
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
      -- only after the jdtls client is attached
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      -- check client is not nil
      if not client or not client.name == "jdtls" then
        return
      end

      local jdtls = require("jdtls")
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
    end,
  })
end

---Configure JDTLS server by starting the LSP server and attaching keymaps.
local function jdtls_config()
  if get_root_dir() == nil then
    return
  end
  start_or_attach_jdtls()
  require("plugins.custom.lang.java-dap").setup()
  attach_keymaps()
  require("plugins.custom.lang.java-test").attach_keymaps()
end

local M = {}
M.root_markers = root_markers
M.jdtls_config = jdtls_config
return M
