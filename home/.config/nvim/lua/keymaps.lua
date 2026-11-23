local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

map("n", "<leader>fr", ":FlutterRun<CR>", opts) -- Run Flutter app
map("n", "<leader>fq", ":FlutterQuit<CR>", opts) -- Quit Flutter
map("n", "<leader>fh", ":FlutterHotReload<CR>", opts) -- Hot Reload
map("n", "<leader>fR", ":FlutterHotRestart<CR>", opts) -- Hot Restart

