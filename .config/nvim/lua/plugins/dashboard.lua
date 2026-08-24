return {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  cond = function()
    return vim.fn.argc(-1) == 0
  end,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },

  config = function()
    require('dashboard').setup {
      theme = 'hyper',
      config = {
        week_header = {
          enable = true,
        },
        shortcut = {
          {
            desc = '󰊳 Update',
            group = '@property',
            action = 'Lazy update',
            key = 'u',
          },
          {
            icon = ' ',
            desc = 'Dotfiles',
            group = 'DiagnosticHint',
            action = 'Telescope find_files cwd=~/dotfiles',
            key = '0',
          },
          {
            icon = ' ',
            desc = 'Documents',
            group = 'Number',
            action = 'Telescope find_files cwd=~/Documents',
            key = '1',
          },
          {
            icon = ' ',
            desc = 'Desktop',
            group = 'Label',
            action = 'Telescope find_files cwd=~/Desktop',
            key = '2',
          },
        },
        project = {
          enable = true,
          limit = 8,
          icon = ' ',
          label = 'Recent Projects:',
          action = 'Telescope find_files cwd=',
        },
        mru = {
          enable = true,
          limit = 10,
          icon = ' ',
          label = 'Most Recent Files:',
          cwd_only = false,
        },
        footer = { '', '🚀 Sharp tools make good work.' },
      },
    }
  end,
}
