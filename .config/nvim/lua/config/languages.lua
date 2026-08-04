-- Central language-tooling registry.
-- Add or change language support here; plugin adapters consume the values below.
local M = {}

M.filetype_detection = {
  extension = {
    prisma = 'prisma',
  },
  filename = {
    ['.env'] = 'sh',
    ['yarn.lock'] = 'yarnlock',
  },
  pattern = {
    ['.*%.env%..*'] = 'sh', -- .env.local, .env.staging, etc.
  },
}

M.treesitter_parsers = {
  'lua',
  'python',
  'javascript',
  'jsx',
  'typescript',
  'tsx',
  'vimdoc',
  'vim',
  'regex',
  'terraform',
  'sql',
  'dockerfile',
  'toml',
  'json',
  'java',
  'groovy',
  'go',
  'gomod',
  'gosum',
  'gitignore',
  'graphql',
  'yaml',
  'make',
  'cmake',
  'markdown',
  'markdown_inline',
  'bash',
  'rust',
  'vue',
  'css',
  'scss',
  'html',
  'prisma',
  'xml',
}

M.conform_formatters = {
  javascript = { 'prettier' },
  javascriptreact = { 'prettier' },
  typescript = { 'prettier' },
  typescriptreact = { 'prettier' },
  json = { 'prettier' },
  jsonc = { 'prettier' },
  css = { 'prettier' },
  scss = { 'prettier' },
  html = { 'prettier' },
  markdown = { 'prettier' },
  yaml = { 'prettier' },
  toml = { 'taplo' },
}

M.none_ls = {
  ensure_installed = {
    'biome',
    'prettier',
    'stylua',
    'eslint_d',
    'shfmt',
    'checkmake',
    'ruff',
    'clang_format',
    'goimports',
  },
  biome_filetypes = {
    'javascript',
    'typescript',
    'javascriptreact',
    'typescriptreact',
    'json',
    'jsonc',
    'css',
    'graphql',
  },
  prettier_code_filetypes = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'json',
    'jsonc',
    'css',
    'graphql',
  },
  prettier_markup_filetypes = {
    'yaml',
    'markdown',
    'html',
    'htmldjango',
    'vue',
    'scss',
    'less',
  },
  clang_filetypes = { 'c', 'cpp' },
}

M.tailwind_colorizer_filetypes = { 'css', 'scss', 'sass', 'less' }

function M.lsp_servers()
  local vue_language_server_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'
  local vue_plugin = vim.uv.fs_stat(vue_language_server_path)
      and {
        name = '@vue/typescript-plugin',
        location = vue_language_server_path,
        languages = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' },
      }
    or nil

  local function disable_formatting(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end

  -- JDTLS requires Java 21+, while projects may still intentionally use an
  -- older JDK. On macOS, run only the language server with the newest JDK.
  local jdtls_config = {}
  if vim.fn.has 'mac' == 1 and vim.fn.executable '/usr/libexec/java_home' == 1 then
    local java_home = vim.system({ '/usr/libexec/java_home' }, { text = true }):wait()
    if java_home.code == 0 then
      jdtls_config.cmd_env = { JAVA_HOME = vim.trim(java_home.stdout) }
    end
  end

  return {
    clangd = {
      cmd = { 'clangd', '--offset-encoding=utf-8' },
      capabilities = {
        offsetEncoding = { 'utf-8' },
      },
    },
    gopls = {
      on_attach = disable_formatting,
      settings = {
        gopls = {
          analyses = {
            unusedparams = true,
            shadow = true,
          },
          staticcheck = true,
        },
      },
    },
    jdtls = jdtls_config,
    rust_analyzer = {
      settings = {
        ['rust-analyzer'] = {
          checkOnSave = { command = 'clippy' },
          cargo = { allFeatures = true },
        },
      },
    },
    ts_ls = {
      root_dir = function(bufnr, on_dir)
        local util = require 'lspconfig.util'
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local root = util.root_pattern 'tsconfig.json'(fname) or util.root_pattern('package.json', '.git')(fname)
        on_dir(root)
      end,
      init_options = vim.tbl_deep_extend('force', {
        hostInfo = 'neovim',
      }, vue_plugin and {
        plugins = { vue_plugin },
      } or {}),
      filetypes = {
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
        'vue',
      },
      capabilities = {
        documentFormattingProvider = false,
        documentRangeFormattingProvider = false,
        semanticTokensProvider = vim.NIL,
      },
      on_attach = function(client)
        disable_formatting(client)
        client.server_capabilities.semanticTokensProvider = nil
      end,
    },
    vue_ls = {
      on_attach = disable_formatting,
    },
    biome = {
      root_dir = function(bufnr, on_dir)
        local util = require 'lspconfig.util'
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local root = util.root_pattern('biome.json', 'biome.jsonc')(fname)
        on_dir(root)
      end,
    },
    bashls = {},
    basedpyright = {
      settings = {
        basedpyright = {
          analysis = {
            typeCheckingMode = 'basic',
            diagnosticSeverityOverrides = {
              -- Match VS Code/Pylance: unresolved imports are warnings, not errors.
              reportMissingImports = 'warning',
            },
          },
        },
      },
    },
    ruff = {
      init_options = {
        settings = {
          lint = {
            extendSelect = { 'E101' },
          },
        },
      },
    },
    graphql = {},
    marksman = {},
    vimls = {},
    autotools_ls = {},
    lemminx = {},
    taplo = {},
    groovyls = {},
    neocmake = {},
    html = {
      filetypes = { 'html', 'twig', 'hbs', 'htmldjango' },
      on_attach = disable_formatting,
    },
    cssls = {
      on_attach = disable_formatting,
    },
    tailwindcss = {
      root_dir = function(bufnr, on_dir)
        local util = require 'lspconfig.util'
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local root = util.root_pattern(
          'tailwind.config.js',
          'tailwind.config.cjs',
          'tailwind.config.ts',
          'postcss.config.js',
          'postcss.config.cjs',
          'package.json',
          '.git'
        )(fname)
        on_dir(root)
      end,
    },
    dockerls = {},
    sqlls = {},
    terraformls = {},
    jsonls = {},
    yamlls = {},
    prismals = {},
    emmet_ls = {
      filetypes = { 'html', 'htmldjango', 'css', 'less', 'sass', 'scss' },
    },
    lua_ls = {
      settings = {
        Lua = {
          completion = {
            callSnippet = 'Replace',
          },
          runtime = { version = 'LuaJIT' },
          workspace = {
            checkThirdParty = false,
            library = {
              '${3rd}/luv/library',
              unpack(vim.api.nvim_get_runtime_file('', true)),
            },
          },
          diagnostics = { disable = { 'missing-fields' } },
          format = {
            enable = false,
          },
        },
      },
    },
  }
end

M.mason_extra_tools = { 'stylua' }

return M
