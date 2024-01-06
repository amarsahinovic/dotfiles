return {
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = function()
      return {
        extensions = {
          fzf = {
            fuzzy = true,                   -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true,    -- override the file sorter
            case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
          }
        }
      }
    end,
    config = function()
      require('telescope').load_extension('fzf')
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<C-p>", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
    end,
  },
  --  {
  --    "nvim-telescope/telescope-ui-select.nvim",
  --    config = function()
  --      -- for some reason when I set the table below to opts telescope crashes
  --      require("telescope").setup {
  --        extensions = {
  --          ["ui-select"] = {
  --            require("telescope.themes").get_dropdown {
  --              -- even more opts
  --            }
  --          }
  --        }
  --      }
  --      require("telescope").load_extension("ui-select")
  --    end
  --  }
}
