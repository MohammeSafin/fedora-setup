return {
  "akinsho/flutter-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    widget_guides = {
      enabled = true,
    },
    lsp = {
      color = { enabled = true },
      settings = {
        showTodos = true,
        completeFunctionCalls = true,
      },
    },
  },
}

