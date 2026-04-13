return {
  {
    'LazyVim/LazyVim',
    enabled = false,
  },
  {
    'folke/tokyonight.nvim',
    enabled = false,
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'macchiato', -- latte, frappe, macchiato, mocha
        background = {
          light = 'latte',
          dark = 'macchiato',
        },
        transparent_background = true, -- keep your glass/blur effect
        show_end_of_buffer = false,
        term_colors = false,
        dim_inactive = {
          enabled = false,
        },
        styles = {
          comments = { 'italic' },
          conditionals = { 'italic' },
          functions = {},
          keywords = {},
          strings = {},
          variables = {},
          numbers = {},
          booleans = {},
          properties = {},
          types = {},
          operators = {},
        },
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          telescope = {
            enabled = true,
          },
          barbar = true,
          indent_blankline = {
            enabled = true,
            scope_color = '',
            colored_indent_levels = false,
          },
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { 'italic' },
              hints = { 'italic' },
              warnings = { 'italic' },
              information = { 'italic' },
            },
            underlines = {
              errors = { 'underline' },
              hints = { 'underline' },
              warnings = { 'underline' },
              information = { 'underline' },
            },
            inlay_hints = {
              background = true,
            },
          },
          which_key = false,
          lualine = {},
          neotree = true,
          alpha = true,
          scrollbar = true,
        },
        -- Make Telescope transparent so it matches the rest of the editor.
        -- Without this, Telescope floats get explicit bg colors from the
        -- integration and appear as a darker opaque box against your glass effect.
        highlight_overrides = {
          all = function(colors)
            return {
              -- Make gutter line numbers slightly darker for better contrast
              -- against the transparent background without making them too loud.
              LineNr = { fg = colors.surface2 },
              CursorLineNr = { fg = colors.blue, bold = true },
              -- To change the color of the highlighted line, change `surface0` to another color
              -- from the catppuccin palette like `surface1`, `surface2`, `mantle`, or a hex `#444444`
              CursorLine = { bg = colors.mantle },
              TelescopeNormal = { bg = 'NONE' },
              TelescopePreviewNormal = { bg = 'NONE' },
              TelescopePromptNormal = { bg = 'NONE' },
              TelescopeResultsNormal = { bg = 'NONE' },
              TelescopeBorder = { bg = 'NONE', fg = colors.blue },
              TelescopePreviewBorder = { bg = 'NONE', fg = colors.blue },
              TelescopePromptBorder = { bg = 'NONE', fg = colors.blue },
              TelescopeResultsBorder = { bg = 'NONE', fg = colors.blue },
              TelescopePromptPrefix = { fg = colors.mauve },
              TelescopeSelectionCaret = { fg = colors.mauve },
              TelescopeSelection = { bg = colors.surface0, bold = true },
            }
          end,
        },
      }

      vim.cmd.colorscheme 'catppuccin'
    end,
  },
}
