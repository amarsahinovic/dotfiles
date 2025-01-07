return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = 'nvim-tree/nvim-web-devicons',
  opts = {
    options = {
      hover = {
        enabled = true,
        delay = 50,
        reveal = { 'close' },
      },
      separator_style = 'thick',
    },
  },
}
