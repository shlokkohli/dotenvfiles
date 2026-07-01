return {
  'stevearc/conform.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    formatters_by_ft = require('config.languages').conform_formatters,
    format_on_save = {
      timeout_ms = 3000,
      lsp_format = 'fallback',
    },
  },
}
