local java_cmds = vim.api.nvim_create_augroup('java_cmds', { clear = true })

local root_markers = { ".git", "mvnw", "gradlew" }

local home = os.getenv("HOME")

-- Path to java binary to use when starting up the LS server.
local java_path = home .. "/.nix-profile/bin/java"

---List of Java runtimes, which can be useful if you're starting jdtls with a
---Java version that's different from the one the project uses.
---The field `name` must be a valid `ExecutionEnvironment`,
---you can find the list here:
---https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
---@return table runtimes table of Java runtimes to use
local function create_runtimes()
  return {
    {
      name = "JavaSE-21",
      path = java_path,
    },
  }
end

---@return table cmd command to execute JDTLS
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

---Create settings to configure eclipse.jdt.ls specific settings.
---src: https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
---@return table settings Eclipse JDT LS settings
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
      inlayHints = {
          enabled = true,
          parameterNames = {
             enabled = 'all' -- literals, all, none
          }
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

---See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
---@return table init_options initial options used to configure JDTLS
local function create_init_options()
  local bundles = {}
  vim.list_extend(bundles, require("plugins.custom.lang.java-dap").create_bundles() or {})
  vim.list_extend(bundles, require("plugins.custom.lang.java-test").create_bundles() or {})

  local extendedClientCapabilities = require("jdtls").extendedClientCapabilities
  extendedClientCapabilities.onCompletionItemSelectedCommand = "editor.action.triggerParameterHints"

  return {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities
  }
end

---Create the capabilities used in JDTLS.
---@return lsp.ClientCapabilities lsp_capabilities LSP capabilities, e.g. auto-completion
local function create_capabilities()
  require("jdtls").extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
  local has_blink, blink = pcall(require, "blink.cmp")
  return vim.tbl_deep_extend(
      'force',
      vim.lsp.protocol.make_client_capabilities(),
      has_blink and blink.get_lsp_capabilities() or {}
  )
end

---@return string root_dir path to the root directory.
local function get_root_dir()
  return require("jdtls.setup").find_root(root_markers)
end

---Setup keymap after the JDTLS is fully attached.
---src:
---- https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
---- https://neovim.io/doc/user/lsp.html#LspAttach
---@param bufnr number current buffer to attach the keymaps
local function attach_keymaps(bufnr)
  local jdtls = require("jdtls")

  vim.keymap.set("n", "<M-C-V>", jdtls.extract_variable_all, { buffer = bufnr, noremap = true, silent = true, desc = "Extract variable" })
  vim.keymap.set("v", "<M-C-V>", [[<ESC><CMD>lua require("jdtls").extract_variable_all(true)<CR>]], { buffer = bufnr, noremap = true, silent = true, desc = "Extract variable" })
  vim.keymap.set("i", "<M-C-V>", [[<ESC><CMD>lua require("jdtls").extract_variable_all()<CR>]], { buffer = bufnr, noremap = true, silent = true, desc = "Extract variable" })

  vim.keymap.set("n", "<M-C-C>", jdtls.extract_constant, { buffer = bufnr, noremap = true, silent = true, desc = "Extract constant" })
  vim.keymap.set("v", "<M-C-C>", [[<ESC><CMD>lua require("jdtls").extract_constant(true)<CR>]], { buffer = bufnr, noremap = true, silent = true, desc = "Extract constant" })
  vim.keymap.set("i", "<M-C-C>", [[<ESC><CMD>lua require("jdtls").extract_constant()<CR>]], { buffer = bufnr, noremap = true, silent = true, desc = "Extract constant" })

  vim.keymap.set("v", "<M-C-N>", [[<ESC><CMD>lua require("jdtls").extract_method(true)<CR>]], { buffer = bufnr, noremap = true, silent = true, desc = "Extract method" })

  vim.keymap.set("n", "<F33>", jdtls.compile, { buffer = bufnr, noremap = true, silent = true, desc = "Compile (Ctrl+F9)" })
  vim.keymap.set("n", "<M-C-O>", jdtls.organize_imports, { buffer = bufnr, noremap = true, silent = true, desc = "Organize imports (Ctrl+Alt+o)" })

  vim.keymap.set("n", "]E", function() vim.fn.search('^Caused by:', 'W') end, { noremap = true, silent = true, desc = "Find next Java exception" })
  vim.keymap.set("n", "[E", function() vim.fn.search('^Caused by:', 'bW') end, { noremap = true, silent = true, desc = "Find previous Java exception" })

  local wk = require("which-key")
  wk.add({
    {
      mode = "n",
      buffer = bufnr,
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
      buffer = bufnr,
      { "<leader>cx", group = "extract" },
      { "<leader>cxm", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], desc = "Extract Method", },
      { "<leader>cxv", [[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]], desc = "Extract Variable", },
      { "<leader>cxc", [[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]], desc = "Extract Constant", },
    },
  })
end

---Enable codelens to display the number of references.
---Can be useful to find dead code.
---@param bufnr number current buffer
local function enable_codelens(bufnr)
  pcall(vim.lsp.codelens.refresh)

  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = bufnr,
    group = java_cmds,
    desc = "Refresh codelens",
    callback = function()
      pcall(vim.lsp.codelens.refresh)
    end,
  })
end

---Perform some action when JDTLS is fully attached, like adding some keymaps.
---@param client any
---@param bufnr number current buffer
local function on_attach(client, bufnr)
  attach_keymaps(bufnr)

  -- Disabling codelens as it slows down the editor after all...
  -- enable_codelens(bufnr)

  -- Attach DAP and java-test only after JDTLS is fully started.
  require("plugins.custom.lang.java-dap").setup()
  require("plugins.custom.lang.java-test").attach_keymaps(bufnr)
end

---Attach jdtls for the proper filetypes (i.e. java).
local function start_or_attach_jdtls()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "java" },
    group = java_cmds,
    desc = "Setup JDTLS",
    callback = function()
      require("jdtls").start_or_attach({
        capabilities = create_capabilities(),
        cmd = create_cmd(),
        flags = { allow_incremental_sync = true },
        init_options = create_init_options(),
        on_attach = on_attach,
        root_dir = get_root_dir(),
        settings = create_settings(),
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
end

local M = {}
M.root_markers = root_markers
M.jdtls_config = jdtls_config
return M
