return {
  {
    'EdenEast/nightfox.nvim',
    priority = 1000,
    config = function()
      require('nightfox').setup {}
      vim.cmd.colorscheme 'carbonfox'

      -- VS Code-like highlight overrides for Tree-sitter tokens
      local hi = vim.api.nvim_set_hl

      -- Variables & parameters (blue, like VS Code)
      hi(0, '@variable',            { fg = '#9cdcfe' })
      hi(0, '@variable.builtin',    { fg = '#569cd6', bold = true })
      hi(0, '@variable.member',     { fg = '#9cdcfe' }) -- object properties
      hi(0, '@variable.parameter',  { fg = '#9cdcfe' }) -- function params

      -- Functions (yellow, like VS Code)
      hi(0, '@function',            { fg = '#dcdcaa' })
      hi(0, '@function.builtin',    { fg = '#dcdcaa' })
      hi(0, '@function.call',       { fg = '#dcdcaa' })
      hi(0, '@function.method',     { fg = '#dcdcaa' })
      hi(0, '@function.method.call',{ fg = '#dcdcaa' })
      hi(0, '@constructor',         { fg = '#4ec9b0' }) -- teal, like VS Code

      -- Properties (light blue)
      hi(0, '@property',            { fg = '#9cdcfe' })

      -- Types (teal, like VS Code)
      hi(0, '@type',                { fg = '#4ec9b0' })
      hi(0, '@type.builtin',        { fg = '#4ec9b0' })

      -- Keywords (blue/purple, like VS Code)
      hi(0, '@keyword',             { fg = '#569cd6' })
      hi(0, '@keyword.return',      { fg = '#c586c0' })
      hi(0, '@keyword.conditional', { fg = '#c586c0' })
      hi(0, '@keyword.repeat',      { fg = '#c586c0' })
      hi(0, '@keyword.import',      { fg = '#c586c0' })

      -- Strings (orange, like VS Code)
      hi(0, '@string',              { fg = '#ce9178' })
      hi(0, '@string.regex',        { fg = '#d16969' })

      -- Numbers & booleans
      hi(0, '@number',              { fg = '#b5cea8' })
      hi(0, '@boolean',             { fg = '#569cd6' })

      -- Comments (green, like VS Code)
      hi(0, '@comment',             { fg = '#6a9955', italic = true })

      -- Operators & punctuation
      hi(0, '@operator',            { fg = '#d4d4d4' })
      hi(0, '@punctuation.bracket', { fg = '#ffd700' })
      hi(0, '@punctuation.delimiter',{ fg = '#d4d4d4' })

      -- Constants
      hi(0, '@constant',            { fg = '#4fc1ff' })
      hi(0, '@constant.builtin',    { fg = '#569cd6' })

      -- LSP semantic tokens (used by many language servers)
      hi(0, '@lsp.type.variable',   { fg = '#9cdcfe' })
      hi(0, '@lsp.type.parameter',  { fg = '#9cdcfe' })
      hi(0, '@lsp.type.property',   { fg = '#9cdcfe' })
      hi(0, '@lsp.type.function',   { fg = '#dcdcaa' })
      hi(0, '@lsp.type.method',     { fg = '#dcdcaa' })
      hi(0, '@lsp.type.class',      { fg = '#4ec9b0' })
      hi(0, '@lsp.type.interface',  { fg = '#4ec9b0' })
      hi(0, '@lsp.type.type',       { fg = '#4ec9b0' })
      hi(0, '@lsp.type.keyword',    { fg = '#569cd6' })
      hi(0, '@lsp.type.string',     { fg = '#ce9178' })
      hi(0, '@lsp.type.number',     { fg = '#b5cea8' })
      hi(0, '@lsp.type.namespace',  { fg = '#4ec9b0' })
    end,
  },
}
