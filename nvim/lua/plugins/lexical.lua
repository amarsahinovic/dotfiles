local lspconfig = require("lspconfig")
local configs = require("lspconfig.configs")
--
local lexical = {
  cmd = { "/home/amar/dev/elixir/lexical/_build/dev/package/lexical/bin/start_lexical.sh" },
  filetypes = { "elixir", "eelixir", "heex", "surface" },
  settings = {},
}

local custom_attach = function(client)
  print("Lexical has started.")
end

if not configs.lexical then
  configs.lexical = {
    default_config = {
      cmd = lexical.cmd,
      filetypes = lexical.filetypes,
      settings = lexical.settings,
    },
  }
end

lspconfig.lexical.setup({
  --[[ capabilities = require("user.lsp.handlers").capabilities, ]]
  on_attach = custom_attach,
  root_dir = lspconfig.util.root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
})

-- log config
-- require("vim.lsp.log").set_format_func(vim.inspect)
-- vim.lsp.set_log_level("debug")

return {}

-- return {
--   {
--     "neovim/nvim-lspconfig",
--     opts = function(_, opts)
--       local lspconfig = require("lspconfig")
--       return vim.tbl_deep_extend("keep", opts, {
--         servers = {
--           lexical = {
--             cmd = { "/home/amar/dev/elixir/lexical/_build/dev/package/lexical/bin/start_lexical.sh" },
--             filetypes = { "elixir", "eelixir", "heex", "surface" },
--             settings = {},
--           },
--         },
--         root_dir = lspconfig.util.root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
--       })
--     end,
--   },
-- }
