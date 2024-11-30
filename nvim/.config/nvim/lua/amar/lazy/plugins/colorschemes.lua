return {
  {
    'folke/tokyonight.nvim',
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
  },
  {
    'Mofiqul/dracula.nvim',
  },
  {
    'rebelot/kanagawa.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'dracula'
    end,
  },
  {
    'maxmx03/solarized.nvim',
  },
}
