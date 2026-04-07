return {
  -- Main LSP Configuration
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Useful status updates for LSP.
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    { 'j-hui/fidget.nvim', opts = {} },

    -- Allows extra capabilities provided by nvim-cmp
    'hrsh7th/cmp-nvim-lsp',
  },
  config = function()
    -- Brief aside: **What is LSP?**
    --
    -- LSP is an initialism you've probably heard, but might not understand what it is.
    --
    -- LSP stands for Language Server Protocol. It's a protocol that helps editors
    -- and language tooling communicate in a standardized fashion.
    --
    -- In general, you have a "server" which is some tool built to understand a particular
    -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
    -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
    -- processes that communicate with some "client" - in this case, Neovim!
    --
    -- LSP provides Neovim with features like:
    --  - Go to definition
    --  - Find references
    --  - Autocompletion
    --  - Symbol Search
    --  - and more!
    --
    -- Thus, Language Servers are external tools that must be installed separately from
    -- Neovim. This is where `mason` and related plugins come into play.
    --
    -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
    -- and elegantly composed help section, `:help lsp-vs-treesitter`

    -- disable LSP logging to avoid performance and freeze issues
    vim.lsp.set_log_level 'OFF'

    -- Toggle context float: second K closes the float.
    -- Prefer diagnostics at the cursor (like VS Code hover on squiggles),
    -- then fall back to normal LSP hover documentation.
    local info_winid = nil
    local function toggle_lsp_hover()
      if info_winid and vim.api.nvim_win_is_valid(info_winid) then
        vim.api.nvim_win_close(info_winid, true)
        info_winid = nil
        return
      end

      info_winid = nil

      local cursor = vim.api.nvim_win_get_cursor(0)
      local line = cursor[1] - 1
      local line_diags = vim.diagnostic.get(0, { lnum = line })
      local has_line_diag = #line_diags > 0

      if has_line_diag then
        local _, winid = vim.diagnostic.open_float(0, {
          scope = 'line',
          focus = false,
          max_width = 80,
          wrap = true,
          border = 'rounded',
          source = 'always',
        })
        if winid and vim.api.nvim_win_is_valid(winid) then
          info_winid = winid
        end
        return
      end

      vim.lsp.buf.hover {
        focus = false,
        max_width = 80,
        max_height = 20,
        wrap = true,
      }

      -- Capture the hover window after it opens.
      vim.schedule(function()
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.api.nvim_win_is_valid(winid) then
            local cfg = vim.api.nvim_win_get_config(winid)
            if cfg.relative ~= '' then
              local buf = vim.api.nvim_win_get_buf(winid)
              if buf ~= vim.api.nvim_get_current_buf() then
                local ft = vim.bo[buf].filetype
                if ft == 'markdown' or vim.startswith(ft, 'markdown') then
                  info_winid = winid
                  return
                end
              end
            end
          end
        end
      end)
    end

    --  This function gets run when an LSP attaches to a particular buffer.
    --    That is to say, every time a new file is opened that is associated with
    --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
    --    function will be executed to configure the current buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local format_augroup = vim.api.nvim_create_augroup('kickstart-lsp-format', { clear = false })
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- Jump to the definition of the word under your cursor.
        --  This is where a variable was first declared, or where a function is defined, etc.
        --  To jump back, press <C-t>.
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        vim.api.nvim_clear_autocmds { group = format_augroup, buffer = event.buf }
        local formatting_clients = vim.lsp.get_clients {
          bufnr = event.buf,
          method = vim.lsp.protocol.Methods.textDocument_formatting,
        }
        if not vim.tbl_isempty(formatting_clients) then
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = format_augroup,
            buffer = event.buf,
            callback = function()
              local bufnr = event.buf
              local clients = vim.lsp.get_clients {
                bufnr = bufnr,
                method = vim.lsp.protocol.Methods.textDocument_formatting,
              }

              if vim.tbl_isempty(clients) then
                return
              end

              local use_null_ls = vim.iter(clients):any(function(attached_client)
                return attached_client.name == 'null-ls'
              end)

              vim.lsp.buf.format {
                bufnr = bufnr,
                async = false,
                timeout_ms = 3000,
                filter = use_null_ls and function(attached_client)
                  return attached_client.name == 'null-ls'
                end or nil,
              }
            end,
          })
        end

        local function get_ts_client(bufnr)
          for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
            if c.name == 'ts_ls' then
              return c
            end
          end
          return nil
        end

        local function has_definition_client(bufnr)
          local definition_method = vim.lsp.protocol.Methods.textDocument_definition
          return not vim.tbl_isempty(vim.lsp.get_clients({
            bufnr = bufnr,
            method = definition_method,
          }))
        end

        local function push_tagstack(tagname)
          local from = { vim.fn.bufnr('%'), vim.fn.line('.'), vim.fn.col('.'), 0 }
          local items = { { tagname = tagname, from = from } }
          vim.fn.settagstack(vim.fn.win_getid(), { items = items }, 't')
        end

        local function grep_definition_fallback(symbol, root)
          local current_file = vim.api.nvim_buf_get_name(0)
          local current_line = vim.api.nvim_win_get_cursor(0)[1]
          local output = vim.fn.systemlist({
            'rg',
            '--vimgrep',
            '--smart-case',
            '--glob',
            '!**/node_modules/**',
            '--glob',
            '!**/dist/**',
            symbol,
            root,
          })
          if vim.v.shell_error ~= 0 and #output == 0 then
            vim.notify('No definition found for ' .. symbol, vim.log.levels.INFO)
            return
          end

          local items = {}
          for _, line in ipairs(output) do
            local filename, lnum, col, text = line:match '^(.-):(%d+):(%d+):(.*)$'
            local is_current_line = filename == current_file and tonumber(lnum) == current_line
            local is_method_call = text and text:find('.' .. symbol, 1, true)
            if filename and not is_current_line and not is_method_call then
              table.insert(items, {
                filename = filename,
                lnum = tonumber(lnum),
                col = tonumber(col),
                text = text,
              })
            end
          end

          if #items == 0 then
            vim.notify('No definition found for ' .. symbol, vim.log.levels.INFO)
            return
          end

          if #items == 1 then
            push_tagstack(symbol)
            if items[1].filename ~= current_file then
              vim.cmd('edit ' .. vim.fn.fnameescape(items[1].filename))
            end
            vim.api.nvim_win_set_cursor(0, { items[1].lnum, math.max(items[1].col - 1, 0) })
            vim.cmd 'normal! zz'
            return
          end

          vim.fn.setqflist({}, ' ', {
            title = 'Definition search: ' .. symbol,
            items = items,
          })
          vim.cmd 'copen'
        end

        local function jump_to_location(loc, offset_encoding)
          local uri = loc.uri or loc.targetUri
          local range = loc.range or loc.targetSelectionRange or loc.targetRange
          if not uri or not range then
            return false
          end
          push_tagstack(vim.fn.expand '<cword>')
          vim.lsp.util.show_document({
            uri = uri,
            range = range,
          }, offset_encoding, { focus = true })
          return true
        end

        map('gd', function()
          local ts = get_ts_client(event.buf)
          if not ts then
            if has_definition_client(event.buf) then
              vim.lsp.buf.definition()
            else
              vim.notify('No LSP client with definition support is attached to this buffer', vim.log.levels.WARN)
            end
            return
          end

          local win = vim.api.nvim_get_current_win()
          local params = vim.lsp.util.make_position_params(win, ts.offset_encoding)
          local symbol = vim.fn.expand '<cword>'
          local root = ts.config.root_dir or vim.fn.getcwd()
          local line = vim.api.nvim_get_current_line()
          local is_member_access = line:find('.' .. symbol, 1, true) ~= nil

          local function fallback_to_search()
            grep_definition_fallback(symbol, root)
          end

          -- Imported instance methods and `this.method()` calls are the cases
          -- where ts_ls is currently returning `any` after initialization.
          -- For those, search the package root directly.
          if is_member_access then
            fallback_to_search()
            return
          end

          local function try_source_definition()
            ts:exec_cmd({
              command = '_typescript.goToSourceDefinition',
              title = 'Go to source definition',
              arguments = { params.textDocument.uri, params.position },
            }, { bufnr = event.buf }, function(err, result)
              if err or not result or vim.tbl_isempty(result) or not jump_to_location(result[1], ts.offset_encoding) then
                fallback_to_search()
              end
            end)
          end

          ts:request('textDocument/definition', params, function(err, result)
            if err or not result or vim.tbl_isempty(result) then
              try_source_definition()
              return
            end

            if not jump_to_location(result[1], ts.offset_encoding) then
              try_source_definition()
            end
          end, event.buf)
        end, '[G]oto [D]efinition')

        -- For TypeScript, keep source-definition on a separate key so we can still
        -- jump through re-exports or .d.ts shims without breaking local definitions.
        if client and client.name == 'ts_ls' then
          map('gS', function()
            local win = vim.api.nvim_get_current_win()
            local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
            client:exec_cmd({
              command = '_typescript.goToSourceDefinition',
              title = 'Go to source definition',
              arguments = { params.textDocument.uri, params.position },
            }, { bufnr = event.buf }, function(err, result)
              if err then
                vim.notify('Go to source definition failed: ' .. err.message, vim.log.levels.ERROR)
                return
              end

              if not result or vim.tbl_isempty(result) then
                vim.notify('No source definition found', vim.log.levels.INFO)
                return
              end

              vim.lsp.util.show_document(result[1], client.offset_encoding, { focus = true })
            end)
          end, '[G]oto [S]ource Definition')
        end

        -- Find references for the word under your cursor.
        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

        -- Jump to the implementation of the word under your cursor.
        --  Useful when your language has ways of declaring types without an actual implementation.
        map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

        -- Jump to the type of the word under your cursor.
        --  Useful when you're not sure what type a variable is and you want to see
        --  the definition of its *type*, not where it was *defined*.
        map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

        -- Fuzzy find all the symbols in your current document.
        --  Symbols are things like variables, functions, types, etc.
        map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

        -- Fuzzy find all the symbols in your current workspace.
        --  Similar to document symbols, except searches over your entire project.
        map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header.
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        map('K', toggle_lsp_hover, 'Hover Documentation')

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- The following code creates a keymap to toggle inlay hints in your
        -- code, if the language server you are using supports them
        --
        -- This may be unwanted, since they displace some of your code
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    local vue_language_server_path = vim.fn.stdpath 'data'
      .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'
    local vue_plugin = vim.uv.fs_stat(vue_language_server_path) and {
      name = '@vue/typescript-plugin',
      location = vue_language_server_path,
      languages = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' },
    } or nil
    local function disable_formatting(client)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end

    local servers = {
      clangd = {
        cmd = { 'clangd', '--offset-encoding=utf-8' },
        capabilities = {
          offsetEncoding = { 'utf-8' },
        },
      }, -- gopls = {},
      -- pyright = {},
      -- rust_analyzer = {},
      -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
      --
      -- Some languages (like typescript) have entire language plugins that can be useful:
      --    https://github.com/pmizio/typescript-tools.nvim
      --
      -- But for many setups, the LSP (`tsserver`) will work just fine
      ts_ls = { -- tsserver
        -- In monorepos, anchor ts_ls to the nearest tsconfig.json (sub-package)
        -- so it uses the correct project scope for type resolution.
        root_dir = function(bufnr, on_dir)
          local util = require('lspconfig.util')
          local fname = vim.api.nvim_buf_get_name(bufnr)
          -- Prefer nearest tsconfig.json (sub-package), then package.json, then .git
          local root = util.root_pattern('tsconfig.json')(fname)
            or util.root_pattern('package.json', '.git')(fname)
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
        -- ts_ls config to ensure ts_ls sever does not format code
        capabilities = {
          documentFormattingProvider = false,
          documentRangeFormattingProvider = false,
          -- Disable semantic tokens — Tree-sitter handles highlighting instantly,
          -- LSP semantic tokens cause a visible "flash" when the server attaches
          semanticTokensProvider = vim.NIL,
        },
        on_attach = function(client)
          disable_formatting(client)
          client.server_capabilities.semanticTokensProvider = nil
        end,
      }, -- tsserver is deprecated
      vue_ls = {
        on_attach = disable_formatting,
      },
      biome = {
        -- Only attach in projects that explicitly opt in to Biome
        root_dir = function(bufnr, on_dir)
          local util = require 'lspconfig.util'
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local root = util.root_pattern('biome.json', 'biome.jsonc')(fname)
          on_dir(root)
        end,
      },
      ruff = {},
      pylsp = {
        settings = {
          pylsp = {
            plugins = {
              pyflakes = { enabled = false },
              pycodestyle = { enabled = false },
              autopep8 = { enabled = false },
              yapf = { enabled = false },
              mccabe = { enabled = false },
              pylsp_mypy = { enabled = false },
              pylsp_black = { enabled = false },
              pylsp_isort = { enabled = false },
            },
          },
        },
      },
      html = {
        filetypes = { 'html', 'twig', 'hbs' },
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
        filetypes = { 'html', 'css', 'less', 'sass', 'scss' },
      },

      lua_ls = {
        -- cmd = {...},
        -- filetypes = { ...},
        -- capabilities = {},
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

    -- Ensure the servers and tools above are installed
    --  To check the current status of installed tools and/or manually install
    --  other tools, you can run
    --    :Mason
    --
    --  You can press `g?` for help in this menu.
    require('mason').setup()

    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua', -- Used to format Lua code
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    -- mason-lspconfig v2 can auto-enable installed servers with their default
    -- configs. Disable that so our explicit per-server settings actually win.
    require('mason-lspconfig').setup {
      automatic_enable = false,
    }

    for server_name, server in pairs(servers) do
      -- This handles overriding only values explicitly passed
      -- by the server configuration above. Useful when disabling
      -- certain features of an LSP (for example, turning off formatting for tsserver)
      server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      vim.lsp.config(server_name, server)
      vim.lsp.enable(server_name)
    end

    -- The built-in nvim-lspconfig :LspRestart command only understands clients
    -- that were registered through vim.lsp.config(). That excludes null-ls,
    -- which causes "Invalid server name 'null-ls'" when restarting a buffer
    -- that has both ts_ls and null-ls attached.
    pcall(vim.api.nvim_del_user_command, 'LspRestart')
    vim.api.nvim_create_user_command('LspRestart', function(info)
      local bufnr = vim.api.nvim_get_current_buf()
      local targets = {}
      local wanted = {}

      for _, name in ipairs(info.fargs or {}) do
        wanted[name] = true
      end

      for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if vim.tbl_isempty(wanted) or wanted[client.name] then
          table.insert(targets, client)
        end
      end

      if #targets == 0 then
        vim.notify('No LSP clients attached to this buffer', vim.log.levels.INFO)
        return
      end

      local managed = {}
      for _, client in ipairs(targets) do
        if vim.lsp.config[client.name] ~= nil then
          managed[client.name] = true
        end
        client:stop(info.bang or false)
      end

      vim.defer_fn(function()
        for name, _ in pairs(managed) do
          vim.lsp.enable(name)
        end

        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.schedule(function()
            vim.cmd 'edit'
          end)
        end
      end, 300)
    end, {
      desc = 'Restart LSP clients for the current buffer',
      nargs = '*',
      bang = true,
      complete = function()
        return vim
          .iter(vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() }))
          :map(function(client)
            return client.name
          end)
          :totable()
      end,
    })

    vim.diagnostic.config {
      -- Show inline text for real errors so syntax issues are obvious even when
      -- terminal undercurls are subtle or the colorscheme is transparent.
      virtual_text = {
        severity = { min = vim.diagnostic.severity.ERROR },
        spacing = 2,
        source = 'if_many',
        prefix = '●',
      },
      virtual_lines = false,
      underline = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = 'E',
          [vim.diagnostic.severity.WARN] = 'W',
          [vim.diagnostic.severity.INFO] = 'I',
          [vim.diagnostic.severity.HINT] = 'H',
        },
      },
      update_in_insert = true,
      severity_sort = true,
      float = {
        focusable = true,
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
      },
    }

    -- Fade unused variables/functions like VS Code does
    vim.api.nvim_set_hl(0, 'DiagnosticUnnecessary', { fg = '#6b7280', italic = true })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineError', { undercurl = true, sp = '#e06c75' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineWarn', { undercurl = true, sp = '#e5c07b' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineInfo', { undercurl = true, sp = '#61afef' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineHint', { undercurl = true, sp = '#56b6c2' })

    -- Override float to enforce wrapping and max_width
    local orig_util_open_float = vim.diagnostic.open_float
    vim.diagnostic.open_float = function(bufnr, opts)
      opts = opts or {}
      opts.max_width = 80
      opts.wrap = true
      opts.border = 'rounded'
      return orig_util_open_float(bufnr, opts)
    end
    vim.keymap.set('n', '<leader>d', function()
      vim.diagnostic.open_float(0, {
        scope = 'line',
        max_width = 80,
        wrap = true,
        border = 'rounded',
      })
    end, { desc = 'Show diagnostic (wrapped)' })
  end,
}
