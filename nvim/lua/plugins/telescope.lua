return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  -- We removed the '0.1.x' branch to ensure you get the latest fixes for Neovim 0.10+
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  config = function()
    local Path = require 'plenary.path'
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'
    local conf = require('telescope.config').values
    local finders = require 'telescope.finders'
    local from_entry = require 'telescope.from_entry'
    local make_entry = require 'telescope.make_entry'
    local pickers = require 'telescope.pickers'
    local previewers = require 'telescope.previewers'
    local sorters = require 'telescope.sorters'

    local function grep_preview_query(opts, status)
      if status and status.picker and status.picker._get_prompt then
        local prompt = status.picker:_get_prompt()
        if prompt and prompt ~= '' then
          return prompt
        end
      end

      if type(opts.search) == 'string' and opts.search ~= '' then
        return opts.search
      end

      if type(opts.default_text) == 'string' and opts.default_text ~= '' then
        return opts.default_text
      end
    end

    local function grep_preview_pattern(query)
      if not query or query == '' or query:find('\n', 1, true) then
        return nil
      end

      local case_prefix = ''
      if vim.o.ignorecase then
        case_prefix = (vim.o.smartcase and query:find('%u')) and '\\C' or '\\c'
      end

      return case_prefix .. '\\V' .. query:gsub('\\', '\\\\')
    end

    local function literal_grep_previewer(opts)
      opts = opts or {}
      local cwd = opts.cwd or vim.uv.cwd()

      local function configure_preview_window(winid)
        if not winid or not vim.api.nvim_win_is_valid(winid) then
          return
        end

        vim.wo[winid].cursorline = true
        vim.wo[winid].cursorlineopt = 'number'
        vim.wo[winid].number = true
        vim.wo[winid].relativenumber = true
        vim.wo[winid].numberwidth = vim.o.numberwidth
      end

      local function clear_match(self)
        if self.state and self.state.hl_id then
          pcall(vim.fn.matchdelete, self.state.hl_id, self.state.winid)
          self.state.hl_id = nil
        end
      end

      local function jump_to_match(self, bufnr, entry, status)
        clear_match(self)
        configure_preview_window(self.state and self.state.winid)

        if entry.lnum and entry.lnum > 0 and self.state.winid and vim.api.nvim_win_is_valid(self.state.winid) then
          local col = math.max(0, (entry.col or 1) - 1)
          pcall(vim.api.nvim_win_set_cursor, self.state.winid, { entry.lnum, col })
          vim.api.nvim_buf_call(bufnr, function()
            vim.cmd 'norm! zz'
          end)
        end

        local pattern = grep_preview_pattern(grep_preview_query(opts, status))
        if not pattern then
          return
        end

        vim.api.nvim_buf_call(bufnr, function()
          self.state.hl_id = vim.fn.matchadd('TelescopePreviewMatch', pattern)
        end)
      end

      return previewers.new_buffer_previewer {
        title = 'Grep Preview',
        dyn_title = function(_, entry)
          return Path:new(from_entry.path(entry, false, false)):normalize(cwd)
        end,
        teardown = function(self)
          clear_match(self)
        end,
        get_buffer_by_name = function(_, entry)
          return from_entry.path(entry, false, false)
        end,
        define_preview = function(self, entry, status)
          local has_buftype = entry.bufnr
            and vim.api.nvim_buf_is_valid(entry.bufnr)
            and vim.bo[entry.bufnr].buftype ~= ''
            or false
          local path

          if not has_buftype then
            path = from_entry.path(entry, true, false)
            if path == nil or path == '' then
              return
            end
          end

          if entry.bufnr and (path == '[No Name]' or has_buftype) then
            local lines = vim.api.nvim_buf_get_lines(entry.bufnr, 0, -1, false)
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
            vim.schedule(function()
              if vim.api.nvim_buf_is_valid(self.state.bufnr) then
                jump_to_match(self, self.state.bufnr, entry, status)
              end
            end)
            return
          end

          conf.buffer_previewer_maker(path, self.state.bufnr, {
            bufname = self.state.bufname,
            winid = self.state.winid,
            preview = opts.preview,
            callback = function(bufnr)
              jump_to_match(self, bufnr, entry, status)
            end,
            file_encoding = opts.file_encoding,
          })
        end,
      }
    end

    local function current_buffer_literal_find()
      local literal_substring_sorter = sorters.Sorter:new {
        discard = true,
        scoring_function = function(_, prompt, _, entry)
          if prompt == '' then
            return 1
          end

          local needle = prompt
          local haystack = entry.ordinal or ''
          if vim.o.ignorecase and not (vim.o.smartcase and prompt:find '%u') then
            needle = prompt:lower()
            haystack = haystack:lower()
          end

          local match_start = haystack:find(needle, 1, true)
          if not match_start then
            return -1
          end

          return match_start
        end,
        highlighter = function(_, prompt, display)
          if prompt == '' then
            return {}
          end

          local needle = prompt
          local haystack = display
          if vim.o.ignorecase and not (vim.o.smartcase and prompt:find '%u') then
            needle = prompt:lower()
            haystack = display:lower()
          end

          local match_start = haystack:find(needle, 1, true)
          if not match_start then
            return {}
          end

          return {
            {
              start = match_start,
              finish = match_start + #prompt - 1,
            },
          }
        end,
      }

      local bufnr = vim.api.nvim_get_current_buf()
      local filename = vim.api.nvim_buf_get_name(bufnr)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local lines_with_numbers = {}

      for lnum, line in ipairs(lines) do
        table.insert(lines_with_numbers, {
          lnum = lnum,
          bufnr = bufnr,
          filename = filename,
          text = line,
        })
      end

      local opts = require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
        prompt_title = 'Current Buffer Search',
      }

      pickers
        .new(opts, {
          finder = finders.new_table {
            results = lines_with_numbers,
            entry_maker = make_entry.gen_from_buffer_lines(opts),
          },
          sorter = literal_substring_sorter,
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              if not selection then
                return
              end

              local prompt = action_state.get_current_line()
              local line = selection.text or ''
              local needle = prompt
              local haystack = line

              if vim.o.ignorecase and not (vim.o.smartcase and prompt:find '%u') then
                needle = prompt:lower()
                haystack = line:lower()
              end

              local col = 0
              local match_start = haystack:find(needle, 1, true)
              if match_start then
                col = match_start - 1
              end

              actions.close(prompt_bufnr)
              vim.schedule(function()
                vim.cmd "normal! m'"
                vim.api.nvim_win_set_cursor(0, { selection.lnum, col })
              end)
            end)

            return true
          end,
        })
        :find()
    end

    require('telescope').setup {
      defaults = {
        grep_previewer = literal_grep_previewer,
        layout_strategy = 'horizontal',
        layout_config = {
          horizontal = {
            preview_width = 0.55,
          },
        },
        -- VS Code-style literal search: override rg defaults to include --fixed-strings
        -- so dots, brackets, etc. are matched literally and trailing spaces matter.
        vimgrep_arguments = {
          'rg',
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case',
          '--fixed-strings',
        },
        preview = {
          treesitter = false,
          wrap = true,  -- wrap long lines so matches at end of line are visible
        },
        mappings = {
          i = {
            ['<C-k>'] = require('telescope.actions').move_selection_previous, -- move to prev result
            ['<C-j>'] = require('telescope.actions').move_selection_next, -- move to next result
            -- Custom select: re-applies cursor AFTER neo-tree/barbar BufEnter callbacks settle
            ['<CR>'] = function(prompt_bufnr)
              local entry = require('telescope.actions.state').get_selected_entry()
              require('telescope.actions').select_default(prompt_bufnr)
              if entry and entry.lnum then
                vim.schedule(function()
                  pcall(vim.api.nvim_win_set_cursor, 0, { entry.lnum, math.max(0, (entry.col or 1) - 1) })
                end)
              end
            end,
            ['<C-l>'] = function(prompt_bufnr)
              local entry = require('telescope.actions.state').get_selected_entry()
              require('telescope.actions').select_default(prompt_bufnr)
              if entry and entry.lnum then
                vim.schedule(function()
                  pcall(vim.api.nvim_win_set_cursor, 0, { entry.lnum, math.max(0, (entry.col or 1) - 1) })
                end)
              end
            end,
            -- Paste multi-line clipboard into single-line prompt.
            -- Joins lines with \\n so ripgrep --multiline can match across lines.
            ['<C-v>'] = function(prompt_bufnr)
              local clipboard = vim.fn.getreg '+'
              if not clipboard or clipboard == '' then
                return
              end
              -- Strip trailing newline and collapse into one line
              clipboard = clipboard:gsub('[\r\n]+$', '')
              local lines = vim.split(clipboard, '\n', { plain = true })
              local text
              if #lines > 1 then
                -- Join with literal \n for display; the search itself will use
                -- grep_string --multiline when triggered from live_grep_smart
                text = table.concat(lines, '\\n')
              else
                text = lines[1]
              end
              local action_state = require 'telescope.actions.state'
              local picker = action_state.get_current_picker(prompt_bufnr)
              picker:set_prompt(text)
            end,
          },
          n = {
            -- Also fix <CR> in Telescope's normal mode
            ['<CR>'] = function(prompt_bufnr)
              local entry = require('telescope.actions.state').get_selected_entry()
              require('telescope.actions').select_default(prompt_bufnr)
              if entry and entry.lnum then
                vim.schedule(function()
                  pcall(vim.api.nvim_win_set_cursor, 0, { entry.lnum, math.max(0, (entry.col or 1) - 1) })
                end)
              end
            end,
          },
        },
      },
      pickers = {
        find_files = {
          find_command = {
            'fd', '--type', 'f', '--hidden', '--no-ignore',
            '--exclude', 'node_modules',
            '--exclude', 'generated',
            '--exclude', '.git',
            '--exclude', '.venv',
            '--exclude', '.turbo',
            '--exclude', '.husky',
            '--exclude', 'package-lock.json',
            '--exclude', '.DS_Store',
            '--exclude', 'Thumbs.db',
            '--exclude', '.Spotlight-V100',
            '--exclude', '.Trashes',
          },
        },
        live_grep = {
          file_ignore_patterns = { 'node_modules', 'generated', '%.git', '%.venv', '%.turbo', '%.husky', 'package%-lock%.json$' },
          additional_args = function(_)
            return { '--hidden' }
          end,
        },
      },
      extensions = {
        fzf = {
          fuzzy = false,  -- exact substring matching instead of fuzzy
        },
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
      },
    }

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    -- See `:help telescope.builtin`
    local builtin = require 'telescope.builtin'

    local function literal_grep(search, opts)
      if not search or search == '' then
        return
      end

      local additional_args = {
        '--hidden',
        '--glob', '!**/node_modules/**',
        '--glob', '!**/generated/**',
        '--glob', '!.git/**',
        '--glob', '!.venv/**',
      }

      if opts and opts.multiline then
        table.insert(additional_args, 2, '--multiline')
      end

      builtin.grep_string {
        prompt_title = opts and opts.prompt_title or 'Grep literal',
        search = search,
        use_regex = true,
        additional_args = additional_args,
      }
    end

    local function get_visual_selection()
      local save_v = vim.fn.getreg 'v'
      vim.cmd [[noautocmd sil norm! "vy]]
      local text = vim.fn.getreg 'v'
      vim.fn.setreg('v', save_v)
      return text
    end

    -- Live grep's prompt is single-line only, so multi-line clipboard/selection cannot
    -- be the full pattern. Use grep_string + ripgrep --multiline for that case.
    local function live_grep_smart()
      local mode = vim.fn.mode()
      if mode == 'v' or mode == 'V' or mode == '\22' then
        -- Visual mode: grab the selection
        local text = get_visual_selection()
        local trimmed = text and text:gsub('[\r\n]+$', '') or ''
        local lines = vim.fn.split(trimmed, '\n', true)

        if #lines > 1 and trimmed ~= '' then
          literal_grep(trimmed, {
            prompt_title = 'Grep multiline',
            multiline = true,
          })
        else
          builtin.live_grep {
            default_text = trimmed ~= '' and trimmed or nil,
          }
        end
      else
        -- Normal mode: just open a clean live grep
        builtin.live_grep()
      end
    end

    local function search_by_literal_grep()
      local mode = vim.fn.mode()
      if mode == 'v' or mode == 'V' or mode == '\22' then
        local text = get_visual_selection()
        local selected = text and text:gsub('[\r\n]+$', '') or ''
        local lines = vim.fn.split(selected, '\n', true)

        literal_grep(selected, {
          prompt_title = #lines > 1 and 'Grep multiline' or 'Grep literal',
          multiline = #lines > 1,
        })
        return
      end

      local query = vim.fn.input 'Grep literal > '
      literal_grep(query, { prompt_title = 'Grep literal' })
    end
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>sw', function()
      builtin.grep_string {
        search = vim.fn.expand '<cword>',
      } -- uses global default preview_width = 0.55
    end, { desc = '[S]earch current [W]ord' })
    vim.keymap.set({ 'n', 'x' }, '<leader>sg', live_grep_smart, { desc = '[S]earch by [G]rep' })
    vim.keymap.set({ 'n', 'x' }, '<leader>sG', search_by_literal_grep, { desc = '[S]earch by literal [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

    -- Slightly advanced example of overriding default behavior and theme
    vim.keymap.set('n', '<leader>/', function()
      current_buffer_literal_find()
    end, { desc = '[/] Search in current buffer' })

    -- Search specifically in files currently open in buffers
    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })
  end,
}
