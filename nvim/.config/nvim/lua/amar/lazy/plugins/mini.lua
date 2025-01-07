return {
  'echasnovski/mini.nvim',
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [']quote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup()

    require('mini.operators').setup()
    require('mini.pairs').setup()

    --require('mini.tabline').setup()

    -- Simple and easy statusline.
    --  You could remove this setup call if you don't like it,
    --  and try some other statusline plugin
    local statusline = require 'mini.statusline'
    -- set use_icons to true if you have a Nerd Font
    statusline.setup { use_icons = vim.g.have_nerd_font }

    -- You can configure sections in the statusline by overriding their
    -- default behavior. For example, here we set the section for
    -- cursor location to LINE:COLUMN
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end

    require('mini.trailspace').setup()

    vim.api.nvim_create_autocmd('BufWritePre', {
      desc = 'Trim trailing whitespace on save using mini.trailspace plugin',
      group = vim.api.nvim_create_augroup('mini-trailspace-trim', { clear = true }),
      callback = function()
        MiniTrailspace.trim()
        MiniTrailspace.trim_last_lines()
      end,
    })

    indentscope = require 'mini.indentscope'
    require('mini.indentscope').setup {
      draw = {
        delay = 0,
        animation = indentscope.gen_animation.none(),
      },
      symbol = '│',
    }
    require('mini.bracketed').setup()
    require('mini.files').setup()
    require('mini.starter').setup()
    require('mini.sessions').setup()
    require('mini.icons').setup()
    require('mini.comment').setup()
  end,
}
