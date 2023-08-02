local wanted_parsers = {
  "bash",
  "c",
  "dockerfile",
  "html",
  "htmldjango",
  "javascript",
  "gdscript",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "regex",
  "tsx",
  "typescript",
  "vim",
  "yaml",
}

if jit.os == "Linux" then
  table.insert(wanted_parsers, "eex")
  table.insert(wanted_parsers, "elixir")
  table.insert(wanted_parsers, "erlang")
  table.insert(wanted_parsers, "heex")
  table.insert(wanted_parsers, "zig")
end

return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = wanted_parsers,
  },
}
