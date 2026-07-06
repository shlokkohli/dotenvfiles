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
    ft = require('config.languages').tailwind_colorizer_filetypes,
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
