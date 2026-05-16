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
      filetypes = {
        "css",
        "scss",
        "sass",
        "less",
      },
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
