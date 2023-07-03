-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.1',
    -- or                            , branch = '0.1.x',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'make'
  }


  use { 'doums/darcula' }

  use { 'nvim-tree/nvim-tree.lua' }
  use { 'nvim-tree/nvim-web-devicons' }

  use('nvim-treesitter/nvim-treesitter',{run = ':TSUpdate'})
  use 'mbbill/undotree'
  use 'tpope/vim-fugitive'
  use 'airblade/vim-gitgutter'
  use {'akinsho/bufferline.nvim', tag = '*', requires = 'nvim-tree/nvim-web-devicons'}

  use("windwp/nvim-autopairs")

  use { 'saadparwaiz1/cmp_luasnip' }

  use({
    "L3MON4D3/LuaSnip",
    after="nvim-cmp",
    -- follow latest release.
    tag = "v1.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
    -- install jsregexp (optional!:).
    run = "make install_jsregexp"
  })

  use({
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v2.x',
    requires = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},             -- Required
      ---@diagnostic disable-next-line: param-type-mismatch
      {'williamboman/mason.nvim', run = function() pcall(vim.cmd, 'MasonUpdate') end},
      {'williamboman/mason-lspconfig.nvim'}, -- Optional
      -- Autocompletion
      {'hrsh7th/nvim-cmp'},     -- Required
      {'hrsh7th/cmp-nvim-lsp'}, -- Required
      {'L3MON4D3/LuaSnip'},     -- Required
    }
  })
end)
