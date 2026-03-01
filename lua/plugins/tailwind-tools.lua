return {
  "luckasRanarison/tailwind-tools.nvim",
  name = "tailwind-tools",
  build = ":UpdateRemotePlugins",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "neovim/nvim-lspconfig",
  },
  opts = {
    server = {
      override = false, -- LSP is configured in tailwind.lua; prevents deprecated lspconfig call
    },
    document_color = {
      enabled = true,
      kind = "background",
    },
    cmp = {
      highlight = "foreground",
    },
  },
}
