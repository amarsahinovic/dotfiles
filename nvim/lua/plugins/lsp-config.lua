local on_attach = function(client, bufnr)
  -- NOTE: Remember that lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself
  -- many times.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local nmap = function(keys, func, desc)
    if desc then
      desc = "LSP: " .. desc
    end

    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
  end

  nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
  nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

  nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
  nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
  nmap("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
  nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
  nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
  nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

  -- See `:help K` for why this keymap
  nmap("K", vim.lsp.buf.hover, "Hover Documentation")
  nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

  -- Lesser used LSP functionality
  nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
  nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
  nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
  nmap("<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, "[W]orkspace [L]ist Folders")

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
    vim.lsp.buf.format()
  end, { desc = "Format current buffer with LSP" })

  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_clear_autocmds({
      group = augroup,
      buffer = bufnr,
    })

    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ bufnr = bufnr })
      end,
    })
  end
end

return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = true,
    -- config = function()
    --  require("mason").setup()
    -- end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function()
      ensure_installed = { "lua_ls", "tsserver", "ruff_lsp", "pyright" }

      if jit.os == "Linux" then
        table.insert(ensure_installed, "elixirls")
        table.insert(ensure_installed, "erlangls")
        table.insert(ensure_installed, "zls")
      end

      return { ensure_installed = ensure_installed }
    end,
  },
  {
    "folke/neodev.nvim",
    config = true,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local configs = require("lspconfig.configs")

      if not configs.lexical then
        configs.lexical = {
          default_config = {
            filetypes = { "elixir", "eelixir", "heex", "surface" },
            cmd = { "/home/amar/dev/elixir/lexical/_build/dev/package/lexical/bin/start_lexical.sh" },
            root_dir = function(fname)
              return lspconfig.util.root_pattern("mix.exs", ".git")(fname) or vim.loop.os_homedir()
            end,
            -- optional settings
            settings = {},
          },
        }
      end

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
      local opts = {
        capabilities = capabilities,
        on_attach = on_attach,
      }
      local ruff_opts = {
        init_options = {
          settings = {
            -- Any extra CLI arguments for `ruff` go here.
            args = {
              "--config=~/.config/ruff/pyproject.toml", "--preview",
            },
          },
        },
      }

      local pyright_opts = {
        settings = {
          pyright = {
            -- Using Ruff's import organizer
            disableOrganizeImports = true,
          },
          python = {
            analysis = {
              -- Ignore all files for analysis to exclusively use Ruff for linting
              ignore = { '*' },
            },
          },
        },
      }

      lspconfig.lua_ls.setup(opts)
      lspconfig.tsserver.setup(opts)
      lspconfig.zls.setup(opts)
      lspconfig.erlangls.setup(opts)
      lspconfig.lexical.setup(opts)
      lspconfig.pyright.setup(vim.tbl_deep_extend("force", opts, pyright_opts))
      -- lspconfig.ruff_lsp.setup(vim.tbl_deep_extend("force", opts, ruff_opts))
    end,
  },
}
