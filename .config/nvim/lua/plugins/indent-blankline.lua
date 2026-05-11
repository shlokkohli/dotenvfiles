return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    local hooks = require 'ibl.hooks'

    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, 'IblIndent', { fg = '#363a4f', nocombine = true })
      vim.api.nvim_set_hl(0, 'IblScope', { fg = '#5b6078', nocombine = true })
    end)

    require('ibl').setup {
      debounce = 100,
      indent = {
        char = '▏',
        highlight = 'IblIndent',
      },
      scope = {
        enabled = true,
        char = '▏',
        highlight = 'IblScope',
        show_start = false,
        show_end = false,
        show_exact_scope = false,
      },
      exclude = {
        buftypes = {
          'terminal',
          'nofile',
          'quickfix',
          'prompt',
        },
        filetypes = {
          '',
          'alpha',
          'checkhealth',
          'dashboard',
          'git',
          'help',
          'lazy',
          'lspinfo',
          'mason',
          'neo-tree',
          'neogitstatus',
          'NvimTree',
          'packer',
          'startify',
          'TelescopePrompt',
          'Trouble',
        },
      },
    }
  end,
}
