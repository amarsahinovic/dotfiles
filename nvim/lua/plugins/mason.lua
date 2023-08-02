local wanted_lsp = {
  "elixir-ls",
  "erlang-ls",
  "eslint-lsp",
  "html-lsp",
  "jedi-language-server",
  "json-lsp",
  "lua-language-server",
  "shfmt",
  "stylua",
  "zls",
}

return {
  "williamboman/mason.nvim",
  opts = function(_, opts)
    vim.list_extend(opts.ensure_installed, wanted_lsp)
  end,
}
