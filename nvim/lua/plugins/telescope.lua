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
    require('telescope').setup {
      defaults = {
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

    -- Live grep's prompt is single-line only, so multi-line clipboard/selection cannot
    -- be the full pattern. Use grep_string + ripgrep --multiline for that case.
    local function live_grep_smart()
      local mode = vim.fn.mode()
      if mode == 'v' or mode == 'V' or mode == '\22' then
        -- Visual mode: grab the selection
        local save_v = vim.fn.getreg 'v'
        vim.cmd [[noautocmd sil norm! "vy]]
        local text = vim.fn.getreg 'v'
        vim.fn.setreg('v', save_v)

        local trimmed = text and text:gsub('[\r\n]+$', '') or ''
        local lines = vim.fn.split(trimmed, '\n', true)

        if #lines > 1 and trimmed ~= '' then
          builtin.grep_string {
            prompt_title = 'Grep multiline',
            search = trimmed,
            use_regex = false,
            additional_args = {
              '--hidden',
              '--multiline',
              '--fixed-strings',
              '--glob', '!**/node_modules/**',
              '--glob', '!**/generated/**',
              '--glob', '!.git/**',
              '--glob', '!.venv/**',
            },
          }
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
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>sw', function()
      builtin.grep_string() -- uses global default preview_width = 0.55
    end, { desc = '[S]earch current [W]ord' })
    vim.keymap.set({ 'n', 'x' }, '<leader>sg', live_grep_smart, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

    -- Slightly advanced example of overriding default behavior and theme
    vim.keymap.set('n', '<leader>/', function()
      -- winblend = 10 provides transparency, previewer = false keeps it compact
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    -- Search specifically in files currently open in buffers
    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })
  end,
}
