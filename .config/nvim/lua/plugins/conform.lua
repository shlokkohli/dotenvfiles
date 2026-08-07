return {
  'stevearc/conform.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    formatters_by_ft = require('config.languages').conform_formatters,
    format_after_save = {
      lsp_format = 'fallback',
    },
  },
}
