-- Scrollbar: shows only errors and uncommitted git changes
return {
  {
    'lewis6991/satellite.nvim',
    event = 'BufReadPost',
    config = function()
      require('satellite').setup {
        current_only = false,
        winblend = 0,
        zindex = 40,
        excluded_filetypes = {
          'neo-tree',
          'alpha',
          'lazy',
          'mason',
          'TelescopePrompt',
          'notify',
        },
        width = 2,
        handlers = {
          cursor = { enable = false },   -- no cursor position marker
          search = { enable = false },   -- no search highlights
          marks  = { enable = false },   -- no marks
          diagnostic = {
            enable = true,
            signs = { '!', '!', '!' },
            min_severity = vim.diagnostic.severity.ERROR, -- errors ONLY
          },
          gitsigns = {
            enable = true,               -- show uncommitted changes
            signs = {
              add    = '│',
              change = '│',
              delete = '│',
            },
          },
        },
      }

      -- Bar background: nearly invisible dark strip
      vim.api.nvim_set_hl(0, 'SatelliteBar', { bg = '#3b4261' })
      -- Errors: vivid red, impossible to miss
      vim.api.nvim_set_hl(0, 'SatelliteDiagnosticError', { fg = '#f7768e', bg = '#1e1e2e' })
      -- Uncommitted git changes: soft blue (distinct from error red)
      vim.api.nvim_set_hl(0, 'SatelliteGitSignsAdd',    { fg = '#7aa2f7', bg = '#1e1e2e' })
      vim.api.nvim_set_hl(0, 'SatelliteGitSignsChange', { fg = '#7aa2f7', bg = '#1e1e2e' })
      vim.api.nvim_set_hl(0, 'SatelliteGitSignsDelete', { fg = '#7aa2f7', bg = '#1e1e2e' })
    end,
  },
}
