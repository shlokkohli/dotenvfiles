return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    local hooks = require 'ibl.hooks'
    local scope = require 'ibl.scope'

    scope.get_cursor_range = function(win)
      local pos = vim.api.nvim_win_get_cursor(win)
      local row, col = pos[1] - 1, pos[2]
      local line = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), row, row + 1, false)[1] or ''
      local first_nonblank = (line:find '%S' or 1) - 1

      return { row, first_nonblank, row, math.max(col, first_nonblank + 1) }
    end

    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, 'IblIndent', { fg = '#363a4f', nocombine = true })
      vim.api.nvim_set_hl(0, 'IblScope', { fg = '#7c8098', nocombine = true })
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
