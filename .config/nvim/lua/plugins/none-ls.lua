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
    local prettier_config_root = util.root_pattern(
      '.prettierrc',
      '.prettierrc.json',
      '.prettierrc.yml',
      '.prettierrc.yaml',
      '.prettierrc.json5',
      '.prettierrc.js',
      '.prettierrc.cjs',
      '.prettierrc.mjs',
      'prettier.config.js',
      'prettier.config.cjs',
      'prettier.config.mjs'
    )

    local function read_json_file(path)
      if not path or not util.path.exists(path) then
        return nil
      end

      local ok, lines = pcall(vim.fn.readfile, path)
      if not ok then
        return nil
      end

      local ok_decode, decoded = pcall(vim.json.decode, table.concat(lines, '\n'))
      if not ok_decode or type(decoded) ~= 'table' then
        return nil
      end

      return decoded
    end

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

    local function package_uses(dir, name)
      local package_json = read_json_file(util.path.join(dir, 'package.json'))
      if not package_json then
        return false
      end

      for _, section in ipairs { 'dependencies', 'devDependencies', 'peerDependencies', 'optionalDependencies' } do
        local deps = package_json[section]
        if type(deps) == 'table' and deps[name] ~= nil then
          return true
        end
      end

      return false
    end

    local function package_has_prettier_field(dir)
      local package_json = read_json_file(util.path.join(dir, 'package.json'))
      return package_json ~= nil and package_json.prettier ~= nil
    end

    local function find_ancestor_dir(bufname, predicate)
      local dir = vim.fn.isdirectory(bufname) == 1 and bufname or util.path.dirname(bufname)

      while dir and dir ~= '' do
        if predicate(dir) then
          return dir
        end

        local parent = util.path.dirname(dir)
        if not parent or parent == dir then
          break
        end
        dir = parent
      end

      return nil
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

    local function has_prettier(bufname)
      local config_root = prettier_config_root(bufname)
      if config_root then
        return true
      end

      return find_ancestor_dir(bufname, function(dir)
        return util.path.exists(util.path.join(dir, 'package.json'))
          and (package_has_prettier_field(dir) or package_uses(dir, 'prettier') or has_local_bin(dir, 'prettier'))
      end) ~= nil
    end

    local function prettier_cwd(bufname)
      return prettier_config_root(bufname) or find_ancestor_dir(bufname, function(dir)
        return util.path.exists(util.path.join(dir, 'package.json'))
          and (package_has_prettier_field(dir) or package_uses(dir, 'prettier') or has_local_bin(dir, 'prettier'))
      end)
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
          'javascript',
          'javascriptreact',
          'typescript',
          'typescriptreact',
          'json',
          'jsonc',
          'css',
          'graphql',
        },
        condition = function(utils)
          return has_prettier(utils.bufname) and not has_biome(utils.bufname)
        end,
        cwd = function(params)
          return prettier_cwd(params.bufname)
        end,
      },
      formatting.prettier.with {
        filetypes = {
          'yaml',
          'markdown',
          'html',
          'htmldjango',
          'vue',
          'scss',
          'less',
        },
        condition = function(utils)
          return has_prettier(utils.bufname)
        end,
        cwd = function(params)
          return prettier_cwd(params.bufname)
        end,
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
