-- Full Git workflow: gutter signs, merge conflicts, and VS Code–style diffs
return {
  -- Gutter signs + blame
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '▎' },
        change = { text = '▎' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      signs_staged = {
        add = { text = '▎' },
        change = { text = '▎' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      current_line_blame = true,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        map('n', ']c', gs.next_hunk, { desc = 'Next Git Hunk' })
        map('n', '[c', gs.prev_hunk, { desc = 'Prev Git Hunk' })
        
        -- VS Code style: peek at the original code before it was changed
        map('n', '<leader>hp', gs.preview_hunk, { desc = 'Preview git hunk (like VS Code)' })
        map('n', '<leader>hr', gs.reset_hunk, { desc = 'Revert (reset) this git change' })
      end,
    },
    config = function(_, opts)
      require('gitsigns').setup(opts)

      -- Define a function to set dimmer/lighter shades for staged changes
      local function set_staged_hls()
        -- You can tweak these hex colors to be as light or dim as you prefer
        vim.api.nvim_set_hl(0, 'GitSignsStagedAdd', { fg = '#4a6a4a' })           -- Dimmed green
        vim.api.nvim_set_hl(0, 'GitSignsStagedChange', { fg = '#3a5a7a' })        -- Dimmed blue
        vim.api.nvim_set_hl(0, 'GitSignsStagedDelete', { fg = '#7a3a3a' })        -- Dimmed red
        vim.api.nvim_set_hl(0, 'GitSignsStagedTopdelete', { fg = '#7a3a3a' })
        vim.api.nvim_set_hl(0, 'GitSignsStagedChangedelete', { fg = '#7a3a3a' })
      end

      -- Apply immediately
      set_staged_hls()

      -- Ensure the colors persist even if the colorscheme is changed/reloaded
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = '*',
        callback = set_staged_hls,
      })
    end,
  },

  -- Merge conflict resolver
  {
    'akinsho/git-conflict.nvim',
    version = '*',
    config = function()
      local ok, git_conflict = pcall(require, 'git-conflict')
      if not ok then
        vim.notify('git-conflict.nvim failed to load', vim.log.levels.ERROR)
        return
      end

      git_conflict.setup {
        default_mappings = false,
        default_commands = true,
        disable_diagnostics = false,
      }

      vim.keymap.set('n', '<leader>go', ':GitConflictChooseOurs<CR>', { desc = 'Choose ours' })
      vim.keymap.set('n', '<leader>gt', ':GitConflictChooseTheirs<CR>', { desc = 'Choose theirs' })
      vim.keymap.set('n', '<leader>gb', ':GitConflictChooseBoth<CR>', { desc = 'Choose both' })
      vim.keymap.set('n', '<leader>gn', ':GitConflictChooseNone<CR>', { desc = 'Choose none' })
    end,
  },

  -- Main Git interface
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      local neogit = require 'neogit'
      neogit.setup {
        integrations = {
          diffview = true,
        },
        kind = 'tab',
        disable_commit_confirmation = true,
      }

      vim.keymap.set('n', '<leader>gs', function()
        neogit.open { kind = 'tab' }
      end, { desc = 'Open Neogit (tab)' })

      -- Track buffers open before entering Diffview
      local pre_diffview_bufs = {}

      local function toggle_diffview()
        local lib_ok, lib = pcall(require, 'diffview.lib')
        if lib_ok and lib.get_current_view() then
          vim.cmd('DiffviewClose')
          -- Close any buffers that were opened during the Diffview session
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf)
              and vim.bo[buf].buflisted
              and not pre_diffview_bufs[buf]
            then
              vim.cmd('bwipeout! ' .. buf)
            end
          end
          pre_diffview_bufs = {}
        else
          -- Snapshot current buffer list before opening Diffview
          pre_diffview_bufs = {}
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
              pre_diffview_bufs[buf] = true
            end
          end
          vim.cmd('DiffviewOpen --no-ignore-whitespace')
        end
      end

      -- show whitespace changes also, toggle
      vim.keymap.set('n', '<leader>gd', toggle_diffview, { desc = 'Toggle Diffview' })
      vim.keymap.set('n', '<leader>gD', toggle_diffview, { desc = 'Toggle Diffview' })
    end,
  },

  -- Better diff viewing
  {
    'sindrets/diffview.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    config = function()
      require('diffview').setup {
        enhanced_diff_hl = true,
        view = {
          default = {
            layout = 'diff2_horizontal',
          },
        },
        file_panel = {
          win_config = { position = 'left', width = 35 },
        },
      }
    end,
  },
}
