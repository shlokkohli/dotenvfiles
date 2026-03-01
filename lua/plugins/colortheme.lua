return {
  {
    'EdenEast/nightfox.nvim',
    priority = 1000,
    config = function()
      require('nightfox').setup {}
      vim.cmd.colorscheme 'carbonfox'

      -- ================================================================
      -- One Dark Pro Night Flat — exact colors from the VS Code theme
      -- Source: zhuangtongfa.material-theme / OneDark-Pro-night-flat.json
      -- ================================================================
      local hi = vim.api.nvim_set_hl

      -- Palette reference:
      --   purple  #c678dd  → keywords (const, let, if, return, async, await…)
      --   blue    #61afef  → functions, methods
      --   red     #e06c75  → variables, object keys, parameters
      --   yellow  #e5c07b  → const-declared names, classes, types, modules
      --   green   #98c379  → strings
      --   orange  #d19a66  → numbers, template literals
      --   cyan    #56b6c2  → operators, built-in support functions
      --   white   #abb2bf  → plain text, punctuation, operators

      -- ── Keywords ────────────────────────────────────────────────────
      -- const, let, var, function, class, if, else, for, while,
      -- return, import, export, async, await, throw, try, catch, typeof, new, delete…
      hi(0, '@keyword',                    { fg = '#c678dd' })
      hi(0, '@keyword.return',             { fg = '#c678dd' })
      hi(0, '@keyword.conditional',        { fg = '#c678dd' })
      hi(0, '@keyword.repeat',             { fg = '#c678dd' })
      hi(0, '@keyword.import',             { fg = '#c678dd' })
      hi(0, '@keyword.function',           { fg = '#c678dd' }) -- 'function' keyword
      hi(0, '@keyword.operator',           { fg = '#c678dd' }) -- typeof, instanceof, in, of
      hi(0, '@keyword.coroutine',          { fg = '#c678dd' }) -- async / await
      hi(0, '@keyword.exception',          { fg = '#c678dd' }) -- throw, try, catch, finally
      hi(0, 'Keyword',                     { fg = '#c678dd' }) -- fallback
      hi(0, 'Statement',                   { fg = '#c678dd' }) -- fallback
      hi(0, 'StorageClass',                { fg = '#c678dd' }) -- const, let, var

      -- ── Functions & Methods ─────────────────────────────────────────
      -- function names, method names, calls — blue in One Dark Pro
      hi(0, '@function',                   { fg = '#61afef' })
      hi(0, '@function.builtin',           { fg = '#56b6c2' }) -- built-ins like require()
      hi(0, '@function.call',              { fg = '#61afef' })
      hi(0, '@function.method',            { fg = '#61afef' })
      hi(0, '@function.method.call',       { fg = '#61afef' })
      hi(0, '@constructor',                { fg = '#e5c07b' }) -- new ClassName()
      hi(0, 'Function',                    { fg = '#61afef' }) -- fallback

      -- ── Variables ───────────────────────────────────────────────────
      -- Regular variables and references are red/pink in One Dark Pro
      hi(0, '@variable',                   { fg = '#e06c75' })
      hi(0, '@variable.builtin',           { fg = '#e5c07b' }) -- this, self, arguments
      hi(0, '@variable.parameter',         { fg = '#e06c75' }) -- function params (orange in some langs)
      hi(0, '@variable.member',            { fg = '#e06c75' }) -- object.property access
      hi(0, 'Identifier',                  { fg = '#e06c75' }) -- fallback

      -- const-declared names get yellow-gold (variable.other.constant in VS Code)
      hi(0, '@constant',                   { fg = '#e5c07b' }) -- const FOO = …
      hi(0, '@constant.builtin',           { fg = '#56b6c2' }) -- true, false, null, undefined

      -- ── Object keys & Properties ────────────────────────────────────
      -- In One Dark Pro, object literal keys (meta.object-literal.key) are red/pink
      hi(0, '@property',                   { fg = '#e06c75' }) -- obj.key access
      -- Note: the colon separator is plain white (#abb2bf), handled by punctuation

      -- ── Types & Classes ─────────────────────────────────────────────
      hi(0, '@type',                       { fg = '#e5c07b' })
      hi(0, '@type.builtin',               { fg = '#e5c07b' })
      hi(0, '@namespace',                  { fg = '#e5c07b' })

      -- ── Strings ─────────────────────────────────────────────────────
      -- Green in One Dark Pro (not orange like VS Code default)
      hi(0, '@string',                     { fg = '#98c379' })
      hi(0, '@string.regex',               { fg = '#e06c75' })
      hi(0, '@string.escape',              { fg = '#56b6c2' })
      hi(0, 'String',                      { fg = '#98c379' }) -- fallback

      -- ── Numbers ─────────────────────────────────────────────────────
      hi(0, '@number',                     { fg = '#d19a66' })
      hi(0, '@number.float',               { fg = '#d19a66' })
      hi(0, '@boolean',                    { fg = '#d19a66' })

      -- ── Comments ────────────────────────────────────────────────────
      hi(0, '@comment',                    { fg = '#5c6370', italic = true })
      hi(0, 'Comment',                     { fg = '#5c6370', italic = true })

      -- ── Operators & Punctuation ─────────────────────────────────────
      hi(0, '@operator',                   { fg = '#abb2bf' })
      hi(0, '@punctuation.bracket',        { fg = '#abb2bf' })
      hi(0, '@punctuation.delimiter',      { fg = '#abb2bf' })
      hi(0, '@punctuation.special',        { fg = '#56b6c2' }) -- template literal ${}

      -- ── LSP Semantic Tokens ─────────────────────────────────────────
      -- These override treesitter when semantic highlighting is active
      hi(0, '@lsp.type.variable',          { fg = '#e06c75' })
      hi(0, '@lsp.type.parameter',         { fg = '#e06c75' })
      hi(0, '@lsp.type.property',          { fg = '#e06c75' })
      hi(0, '@lsp.type.function',          { fg = '#61afef' })
      hi(0, '@lsp.type.method',            { fg = '#61afef' })
      hi(0, '@lsp.type.class',             { fg = '#e5c07b' })
      hi(0, '@lsp.type.interface',         { fg = '#e5c07b' })
      hi(0, '@lsp.type.type',              { fg = '#e5c07b' })
      hi(0, '@lsp.type.keyword',           { fg = '#c678dd' })
      hi(0, '@lsp.type.string',            { fg = '#98c379' })
      hi(0, '@lsp.type.number',            { fg = '#d19a66' })
      hi(0, '@lsp.type.namespace',         { fg = '#e5c07b' })
      hi(0, '@lsp.type.enumMember',        { fg = '#56b6c2' })
    end,
  },
}
