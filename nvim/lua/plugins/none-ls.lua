return {
  'nvimtools/none-ls.nvim',
  dependencies = {
    'nvimtools/none-ls-extras.nvim',
    'jayp0521/mason-null-ls.nvim',
  },
  config = function()
    local null_ls = require 'null-ls'
    local formatting = null_ls.builtins.formatting
    local diagnostics = null_ls.builtins.diagnostics
    local util = require 'lspconfig.util'
    local biome_root = util.root_pattern('rome.json', 'biome.json', 'biome.jsonc')

    local function has_eslint_config(dir)
      local config_files = {
        '.eslintrc.js',
        '.eslintrc.cjs',
        '.eslintrc.json',
        '.eslintrc',
      }
      for _, file in ipairs(config_files) do
        if util.path.exists(util.path.join(dir, file)) then
          return true
        end
      end
      return false
    end

    local function has_local_bin(dir, name)
      if not dir then
        return false
      end
      return util.path.exists(util.path.join(dir, 'node_modules', '.bin', name))
    end

    local function has_biome(bufname)
      -- Require a biome config file in the project root — just having the
      -- binary installed globally (via Mason) is not enough to opt in.
      local root = biome_root(bufname)
      if not root then
        return false
      end
      return vim.fn.executable 'biome' == 1 or has_local_bin(root, 'biome')
    end

    local biome_filetypes = {
      'javascript',
      'typescript',
      'javascriptreact',
      'typescriptreact',
      'json',
      'jsonc',
      'css',
      'graphql',
    }

    local eslint_root = util.root_pattern('.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', '.eslintrc')

    local eslint_d = require('none-ls.diagnostics.eslint_d').with {
      cwd = function(params)
        return eslint_root(params.bufname)
      end,
      condition = function(utils)
        local root = eslint_root(utils.bufname)
        return root ~= nil and has_eslint_config(root)
      end,
    }

    require('mason-null-ls').setup {
      ensure_installed = {
        'biome',
        'prettier',
        'stylua',
        'eslint_d',
        'shfmt',
        'checkmake',
        'ruff',
        'clang_format',
      },
      automatic_installation = true,
    }

    local sources = {
      diagnostics.checkmake,
      eslint_d,
      formatting.biome.with {
        filetypes = biome_filetypes,
        condition = function(utils)
          return has_biome(utils.bufname)
        end,
        cwd = function(params)
          return biome_root(params.bufname)
        end,
      },
      formatting.clang_format.with { filetypes = { 'c', 'cpp' } },
      formatting.prettier.with {
        filetypes = {
          'yaml',
          'markdown',
          'html',
        },
      },
      formatting.stylua,
      formatting.shfmt.with { args = { '-i', '4' } },
      formatting.terraform_fmt,
      require('none-ls.formatting.ruff').with { extra_args = { '--extend-select', 'I' } },
      require 'none-ls.formatting.ruff_format',
    }

    null_ls.setup {
      sources = sources,
      on_attach = function(client, bufnr)
        if client.name == 'null-ls' then
          -- null-ls never provides hover — always let the real LSP handle it
          client.server_capabilities.hoverProvider = false
          if vim.bo[bufnr].filetype == 'c' or vim.bo[bufnr].filetype == 'cpp' then
            client.server_capabilities.definitionProvider = false
            client.server_capabilities.referencesProvider = false
            client.server_capabilities.renameProvider = false
          end
        end
      end,
    }
  end,
}
