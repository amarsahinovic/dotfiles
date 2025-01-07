return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    scroll = { enabled = true },
    gitbrowse = { enabled = true },
  },
  -- config = function()
  --   vim.api.nvim_create_autocmd('User', {
  --     pattern = 'MiniFilesActionRename',
  --     callback = function(event)
  --       Snacks.rename.on_rename_file(event.data.from, event.data.to)
  --     end,
  --   })
  --   vim.keymap.set('n', '<leader>gb', ':lua Snacks.gitbrowse()<CR>', { desc = '[G]it[B]rowse' })
  -- end,
}
