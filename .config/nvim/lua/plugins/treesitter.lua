return { -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  -- NOTE: The new nvim-treesitter dropped ensure_installed and auto_install.
  -- Parsers are installed via :TSInstall. The build function below installs
  -- all required parsers when the plugin is first installed or rebuilt.
  build = function()
    require('nvim-treesitter.install').install(require('config.languages').treesitter_parsers)
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
  end,
}
