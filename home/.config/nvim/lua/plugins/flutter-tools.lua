return {
  "akinsho/flutter-tools.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim", -- Optional: for UI improvements
  },
  config = function()
    require("flutter-tools").setup({
      lsp = {
        on_attach = function(_, _)
          -- add your keymaps here if needed
        end,
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      },
      dev_log = {
        enabled = true,
        open_cmd = "tabedit", -- or "vsplit"
      },
    })
  end,
}
