local function setup()
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(event)
      local name = event.data.spec.name
      local kind = event.data.kind
      if name == "markdown-preview.nvim" and (kind == "install" or kind == "update") then
        if not event.data.active then
          vim.cmd.packadd("markdown-preview.nvim")
        end
        pcall(vim.fn["mkdp#util#install"])
      end
    end,
  })

  vim.keymap.set("n", "<leader>oB", "<cmd>MarkdownPreviewToggle<cr>", {
    desc = "Markdown Preview",
    noremap = true,
  })
end

---@type vim.pack.Spec
return {
  src = "https://github.com/iamcco/markdown-preview.nvim",
  data = { setup = setup },
}
