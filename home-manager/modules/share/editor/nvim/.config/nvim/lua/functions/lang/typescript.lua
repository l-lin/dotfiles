local function setup_dap()
  vim.schedule(function()
    local ok, dap = pcall(require, "dap")
    if not ok then
      return
    end

    for _, adapter_type in ipairs({ "node", "chrome", "msedge" }) do
      local pwa_type = "pwa-" .. adapter_type
      if not dap.adapters[pwa_type] then
        dap.adapters[pwa_type] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "js-debug-adapter",
            args = { "${port}" },
          },
        }
      end

      if not dap.adapters[adapter_type] then
        dap.adapters[adapter_type] = function(callback, config)
          local native_adapter = dap.adapters[pwa_type]
          config.type = pwa_type
          if type(native_adapter) == "function" then
            native_adapter(callback, config)
          else
            callback(native_adapter)
          end
        end
      end
    end

    local javascript_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }
    local vscode = require("dap.ext.vscode")
    vscode.type_to_filetypes.node = javascript_filetypes
    vscode.type_to_filetypes["pwa-node"] = javascript_filetypes

    for _, language in ipairs(javascript_filetypes) do
      if not dap.configurations[language] then
        local runtime_executable = nil
        if language:find("typescript") then
          runtime_executable = vim.fn.executable("tsx") == 1 and "tsx" or "ts-node"
        end
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            runtimeExecutable = runtime_executable,
            skipFiles = {
              "<node_internals>/**",
              "node_modules/**",
            },
            resolveSourceMapLocations = {
              "${workspaceFolder}/**",
              "!**/node_modules/**",
            },
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            runtimeExecutable = runtime_executable,
            skipFiles = {
              "<node_internals>/**",
              "node_modules/**",
            },
            resolveSourceMapLocations = {
              "${workspaceFolder}/**",
              "!**/node_modules/**",
            },
          },
        }
      end
    end
  end)
end

local M = {}
M.setup_dap = setup_dap
return M
