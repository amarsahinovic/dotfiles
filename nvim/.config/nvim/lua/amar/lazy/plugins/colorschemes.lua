return {
  {
    'folke/tokyonight.nvim',
  },
  {
    'tiagovla/tokyodark.nvim',
  },
  {
    'wuelnerdotexe/vim-enfocado',
  },
  {
    'EdenEast/nightfox.nvim',
  },

  {
    'gantoreno/nvim-gabriel',
  },
  {
    'marko-cerovac/material.nvim',
  },
  {
    'ramojus/mellifluous.nvim',
  },
  {
    'rose-pine/neovim',
    as = 'rose-pine',
  },
  {
    'morhetz/gruvbox',
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
  },
  {
    'rmehri01/onenord.nvim',
  },
  {
    'cpea2506/one_monokai.nvim',
  },
  {
    'Mofiqul/vscode.nvim',
  },
  {
    'Mofiqul/dracula.nvim',
  },
  {
    'olimorris/onedarkpro.nvim',
  },
  {
    'shaunsingh/nord.nvim',
  },
  {
    'rebelot/kanagawa.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'kanagawa'
    end,
  },
  {
    'navarasu/onedark.nvim',
  },
  {
    'maxmx03/solarized.nvim',
  },
  {
    'xiantang/darcula-dark.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
  },
}
