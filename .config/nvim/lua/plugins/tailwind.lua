return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tailwindcss = {},
      },
    },
  },
  {
    "NvChad/nvim-colorizer.lua",
    opts = {
      filetypes = require('config.languages').tailwind_colorizer_filetypes,
      options = {
        parsers = {
          css = true,
        },
        display = {
          mode = "virtualtext",
          virtualtext = {
            position = "after",
          },
        },
      },
    },
  },
}
