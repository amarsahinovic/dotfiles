return {
  "stevearc/conform.nvim",
  opts = {
    -- Define your formatters
    formatters_by_ft = {
      lua = { "stylua" },
      -- python = { "isort", "ruff" },
      javascript = { { "prettierd", "prettier" } },
      python = { 'isort' }
    },
    -- Set up format-on-save
    format_on_save = { timeout_ms = 500, lsp_fallback = true },
  },
  keys = {
    {
      -- Customize or remove this keymap to your liking
      "<leader>fb",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "[F]ormat [B]uffer",
    },
  },
}
