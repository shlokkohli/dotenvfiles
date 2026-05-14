return { -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  -- NOTE: The new nvim-treesitter dropped ensure_installed and auto_install.
  -- Parsers are installed via :TSInstall. The build function below installs
  -- all required parsers when the plugin is first installed or rebuilt.
  build = function()
    require('nvim-treesitter.install').install {
      'lua', 'python', 'javascript', 'jsx', 'typescript', 'tsx',
      'vimdoc', 'vim', 'regex', 'terraform', 'sql', 'dockerfile',
      'toml', 'json', 'java', 'groovy', 'go', 'gomod', 'gosum',
      'gitignore', 'graphql', 'yaml', 'make', 'cmake',
      'markdown', 'markdown_inline', 'bash',
      'vue', 'css', 'scss', 'html', 'prisma',
    }
  end,
  main = 'nvim-treesitter.config',
  opts = {
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = { 'ruby' },
    },
    indent = { enable = true, disable = { 'ruby' } },
  },
  config = function(_, opts)
    require('nvim-treesitter.config').setup(opts)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'go', 'gomod', 'gosum' },
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
  -- There are additional nvim-treesitter modules that you can use to interact
  -- with nvim-treesitter. You should go explore a few and see what interests you:
  --
  --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
  --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
  --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
}
