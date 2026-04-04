local opts = { noremap = true, silent = true }
-- Set leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Insert mode: Option+B = move back 1 word, Option+W = move forward 1 word
vim.keymap.set('i', '<M-b>', '<C-o>b', opts)
vim.keymap.set('i', '<M-w>', '<C-o>w', opts)
vim.keymap.set('i', '∫', '<C-o>b', opts) -- macOS Option+B
vim.keymap.set('i', '∑', '<C-o>w', opts) -- macOS Option+W

-- Insert mode: Option+J = move down 1 line, Option+K = move up 1 line
-- vim.keymap.set('i', '<M-j>', '<C-o>j', opts)
vim.keymap.set('i', '<M-k>', '<C-o>k', opts)
-- vim.keymap.set('i', '∆', '<Esc>:m .+1<CR>==gi', { silent = true }) -- macOS Option+J (move line down)
vim.keymap.set('i', '˚', '<Esc>:m .-2<CR>==gi', { silent = true }) -- macOS Option+K (move line up)

-- normal mode
vim.keymap.set('n', '<A-Up>', ':m .-2<CR>==', { silent = true })
vim.keymap.set('n', '<A-Down>', ':m .+1<CR>==', { silent = true })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { silent = true })
-- vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { silent = true })
vim.keymap.set('n', '˚', ':m .-2<CR>==', { silent = true }) -- macOS Option+K
-- vim.keymap.set('n', '∆', ':m .+1<CR>==', { silent = true }) -- macOS Option+J


vim.keymap.set('n', '<leader>n', ':enew<CR>', { noremap = true, silent = true })

-- visual mode
local function visual_move_up()
  vim.cmd("'<,'>move '<-2")
  vim.cmd('normal! gv=gv')
end
local function visual_move_down()
  vim.cmd("'<,'>move '>+1")
  vim.cmd('normal! gv=gv')
end
vim.keymap.set('v', '<A-Up>', visual_move_up, { silent = true })
vim.keymap.set('v', '<A-Down>', visual_move_down, { silent = true })
vim.keymap.set('v', '<A-k>', visual_move_up, { silent = true })
-- vim.keymap.set('v', '<A-j>', visual_move_down, { silent = true })
vim.keymap.set('v', '˚', visual_move_up, { silent = true })  -- macOS Option+K
-- vim.keymap.set('v', '∆', visual_move_down, { silent = true }) -- macOS Option+J

-- insert mode
vim.keymap.set('i', '<A-Up>', '<Esc>:m .-2<CR>==gi', { silent = true })
vim.keymap.set('i', '<A-Down>', '<Esc>:m .+1<CR>==gi', { silent = true })
vim.keymap.set('i', '<A-k>', '<Esc>:m .-2<CR>==gi', { silent = true })
-- vim.keymap.set('i', '<A-j>', '<Esc>:m .+1<CR>==gi', { silent = true })

-- Switch to insert mode
vim.keymap.set('i', 'jk', '<Esc>', { noremap = true, silent = true })

-- Disable the spacebar key's default behavior in Normal and Visual modes
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set({ 'n', 'i', 'v', 'x', 's', 'o', 'c', 't' }, '<C-z>', '<Nop>', { silent = true, desc = 'Disable suspend' })

vim.keymap.set('n', '<leader>cc', '<cmd>cclose<CR>', { desc = 'Close quickfix' })

-- visual mode: d = delete (no yank)
vim.keymap.set('v', 'd', '"_d', { noremap = true, silent = true })

-- visual mode: _d = cut (yank + delete)
vim.keymap.set('v', '_d', 'd', { noremap = true, silent = true })

-- visual mode: y = yank without moving cursor
vim.keymap.set({ 'v', 'x' }, 'y', 'ygv<Esc>', { noremap = true, silent = true, desc = 'Yank without moving cursor' })

-- save file

-- save file without auto-formatting
vim.keymap.set('n', '<leader>sn', '<cmd>noautocmd w <CR>', opts)

-- quit file
vim.keymap.set('n', '<C-q>', '<cmd> q <CR>', opts)

-- Select all
vim.keymap.set('n', '<leader>a', 'ggVG', opts)

-- delete single character without copying into register
vim.keymap.set('n', 'x', '"_x', opts)

-- Vertical scroll and center
vim.keymap.set('n', '<C-d>', '<C-d>zz', opts)
vim.keymap.set('n', '<C-u>', '<C-u>zz', opts)

-- Find and center
vim.keymap.set('n', 'n', 'nzzzv', opts)
vim.keymap.set('n', 'N', 'Nzzzv', opts)

-- Go to middle of text line
vim.keymap.set({ 'n', 'x' }, 'gm', 'gM', { desc = 'Go to middle of text line', noremap = true })

-- Swap zero and caret (0 goes to first word, ^ goes to column 0)
vim.keymap.set({ 'n', 'v', 'o' }, '0', '^', { desc = 'Go to first non-blank character', noremap = true })
vim.keymap.set({ 'n', 'v', 'o' }, '^', '0', { desc = 'Go to absolute start of line', noremap = true })

-- Resize with arrows
vim.keymap.set('n', '<Up>', ':resize -2<CR>', opts)
vim.keymap.set('n', '<Down>', ':resize +2<CR>', opts)
vim.keymap.set('n', '<Left>', ':vertical resize -2<CR>', opts)
vim.keymap.set('n', '<Right>', ':vertical resize +2<CR>', opts)

-- Buffers: after switching away in Visual mode, `gv` restores selection when re-entering the buffer
local restore_visual_on_enter = {}
local function mark_restore_visual_if_needed()
  local m = vim.fn.mode()
  local b = string.byte(m, 1) or 0
  if m == 'v' or m == 'V' or m == 's' or m == 'S' or b == 22 then
    restore_visual_on_enter[vim.api.nvim_get_current_buf()] = true
  end
end
local function buffer_next_maybe_restore_visual()
  mark_restore_visual_if_needed()
  vim.cmd.BufferNext()
end
local function buffer_prev_maybe_restore_visual()
  mark_restore_visual_if_needed()
  vim.cmd.BufferPrevious()
end
local restore_visual_au = vim.api.nvim_create_augroup('buffer-restore-visual', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
  group = restore_visual_au,
  callback = function(args)
    local buf = args.buf
    if not restore_visual_on_enter[buf] then
      return
    end
    restore_visual_on_enter[buf] = nil
    vim.schedule(function()
      if vim.api.nvim_get_current_buf() ~= buf then
        return
      end
      pcall(vim.cmd, 'normal! gv')
    end)
  end,
})
vim.api.nvim_create_autocmd('BufDelete', {
  group = restore_visual_au,
  callback = function(args)
    restore_visual_on_enter[args.buf] = nil
  end,
})

-- Buffers
vim.keymap.set('n', '<Tab>', '<Cmd>BufferNext<CR>', opts)
vim.keymap.set('n', '<S-Tab>', '<Cmd>BufferPrevious<CR>', opts)
vim.keymap.set('n', '<leader>b', '<cmd> enew <CR>', opts) -- new buffer
vim.keymap.set('n', '<leader>x', '<Cmd>BufferClose<CR>', opts)

-- Window management
vim.keymap.set('n', '<leader>v', '<C-w>v', opts) -- split window vertically
vim.keymap.set('n', '<leader>h', '<C-w>s', opts) -- split window horizontally
vim.keymap.set('n', '<leader>se', '<C-w>=', opts) -- make split windows equal width & height
vim.keymap.set('n', '<leader>xs', '<cmd>close<CR>', opts) -- close current split window

-- Navigate between splits
vim.keymap.set('n', '<C-k>', ':wincmd k<CR>', opts)
-- C-j reserved for toggleterm; use vim-tmux-navigator or :wincmd j manually
-- vim.keymap.set('n', '<C-j>', ':wincmd j<CR>', opts)
vim.keymap.set('n', '<C-h>', ':wincmd h<CR>', opts)
vim.keymap.set('n', '<C-l>', ':wincmd l<CR>', opts)

-- Tabs
vim.keymap.set('n', '<leader>to', ':tabnew<CR>', opts) -- open new tab
vim.keymap.set('n', '<leader>tx', ':tabclose<CR>', opts) -- close current tab
vim.keymap.set('n', '<leader>tn', ':tabn<CR>', opts) --  go to next tab
vim.keymap.set('n', '<leader>tp', ':tabp<CR>', opts) --  go to previous tab
vim.keymap.set('n', '<C-Tab>', '<Cmd>BufferNext<CR>', opts)
vim.keymap.set('n', '<C-S-Tab>', '<Cmd>BufferPrevious<CR>', opts)
vim.keymap.set('v', '<C-Tab>', buffer_next_maybe_restore_visual, opts)
vim.keymap.set('v', '<C-S-Tab>', buffer_prev_maybe_restore_visual, opts)
-- Ghostty sends these kitty protocol sequences for Ctrl+Tab / Ctrl+Shift+Tab
vim.keymap.set('n', '\x1b[9;5u', '<Cmd>BufferNext<CR>', opts)
vim.keymap.set('n', '\x1b[9;6u', '<Cmd>BufferPrevious<CR>', opts)
vim.keymap.set('v', '\x1b[9;5u', buffer_next_maybe_restore_visual, opts)
vim.keymap.set('v', '\x1b[9;6u', buffer_prev_maybe_restore_visual, opts)
-- Ghostty Ctrl+1-9 → BufferGoto (kitty protocol: ASCII code of digit + ;5u)
vim.keymap.set('n', '\x1b[49;5u', '<Cmd>BufferGoto 1<CR>', opts)
vim.keymap.set('n', '\x1b[50;5u', '<Cmd>BufferGoto 2<CR>', opts)
vim.keymap.set('n', '\x1b[51;5u', '<Cmd>BufferGoto 3<CR>', opts)
vim.keymap.set('n', '\x1b[52;5u', '<Cmd>BufferGoto 4<CR>', opts)
vim.keymap.set('n', '\x1b[53;5u', '<Cmd>BufferGoto 5<CR>', opts)
vim.keymap.set('n', '\x1b[54;5u', '<Cmd>BufferGoto 6<CR>', opts)
vim.keymap.set('n', '\x1b[55;5u', '<Cmd>BufferGoto 7<CR>', opts)
vim.keymap.set('n', '\x1b[56;5u', '<Cmd>BufferGoto 8<CR>', opts)
vim.keymap.set('n', '\x1b[57;5u', '<Cmd>BufferGoto 9<CR>', opts)

-- Toggle line wrapping
vim.keymap.set('n', '<leader>lw', '<cmd>set wrap!<CR>', opts)

-- Stay in indent mode
vim.keymap.set('v', '<', '<gv', opts)
vim.keymap.set('v', '>', '>gv', opts)

-- Keep last yanked when pasting
vim.keymap.set('v', 'p', '"_dP', opts)

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- Select inner line (excluding indentation)
vim.keymap.set('x', 'il', ':<C-u>normal! ^vg_<CR>', { desc = 'Select inner line' })
vim.keymap.set('o', 'il', ':normal! ^vg_<CR>', { desc = 'Select inner line' })

vim.keymap.set('n', '<A-l>', '5zl', { silent = true })
vim.keymap.set('n', '<A-h>', '5zh', { silent = true })
-- Many macOS terminals send Meta instead of Alt
vim.keymap.set('n', '<M-l>', '5zl', { silent = true })
vim.keymap.set('n', '<M-h>', '5zh', { silent = true })
-- macOS specific: if Option key types special characters instead of sending Alt
vim.keymap.set('n', '¬', '5zl', { silent = true }) -- Option+L
vim.keymap.set('n', '˙', '5zh', { silent = true }) -- Option+H

-- option backspace to remove word in insert mode
vim.keymap.set('i', '<M-BS>', '<C-G>u<C-W>', { noremap = true })

-- Insert mode: csl instantly expands to console.log()
vim.keymap.set('i', 'csl', 'console.log', { noremap = true })

-- set toggle word wrap
vim.keymap.set('n', '<A-z>', ':set wrap!<CR>', { noremap = true, silent = true })

-- personal changes
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { desc = 'Exit terminal mode' })
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.cmd 'startinsert'
  end,
})

-- Smart open terminal: works even when no file is open (e.g. nvim opened on a folder)
local function open_terminal()
  local buf = vim.api.nvim_get_current_buf()
  local buftype = vim.bo[buf].buftype
  local filetype = vim.bo[buf].filetype
  local is_special = buftype ~= '' or filetype == 'neo-tree' or filetype == 'netrw'
  if is_special then
    vim.cmd 'new | terminal'
  else
    vim.cmd 'terminal'
  end
end

vim.keymap.set('n', '<leader>tt', open_terminal, { desc = 'Open terminal' })
vim.api.nvim_create_user_command('Terminal', open_terminal, { desc = 'Open terminal' })

-- barbar keymaps
vim.keymap.set('n', '<A-,>', '<Cmd>BufferPrevious<CR>', { silent = true })
vim.keymap.set('n', '<A-.>', '<Cmd>BufferNext<CR>', { silent = true })
vim.keymap.set('n', '<A-<>', '<Cmd>BufferMovePrevious<CR>', { silent = true })
vim.keymap.set('n', '<A->>', '<Cmd>BufferMoveNext<CR>', { silent = true })
vim.keymap.set('n', '<C-1>', '<Cmd>BufferGoto 1<CR>', { silent = true })
vim.keymap.set('n', '<C-2>', '<Cmd>BufferGoto 2<CR>', { silent = true })
vim.keymap.set('n', '<C-3>', '<Cmd>BufferGoto 3<CR>', { silent = true })
vim.keymap.set('n', '<C-4>', '<Cmd>BufferGoto 4<CR>', { silent = true })
vim.keymap.set('n', '<C-5>', '<Cmd>BufferGoto 5<CR>', { silent = true })
vim.keymap.set('n', '<C-6>', '<Cmd>BufferGoto 6<CR>', { silent = true })
vim.keymap.set('n', '<C-7>', '<Cmd>BufferGoto 7<CR>', { silent = true })
vim.keymap.set('n', '<C-8>', '<Cmd>BufferGoto 8<CR>', { silent = true })
vim.keymap.set('n', '<C-9>', '<Cmd>BufferGoto 9<CR>', { silent = true })
vim.keymap.set('n', '<A-0>', '<Cmd>BufferLast<CR>', { silent = true })
vim.keymap.set('n', '<A-c>', '<Cmd>BufferClose<CR>', { silent = true })
vim.keymap.set('n', '<leader>u', '<Cmd>BufferRestore<CR>', { silent = true })
vim.keymap.set('n', '<', '<Cmd>BufferMovePrevious<CR>', { silent = true })
vim.keymap.set('n', '>', '<Cmd>BufferMoveNext<CR>', { silent = true })

-- Prevent neo-tree from becoming the last window
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function()
    vim.schedule(function()
      local wins = vim.api.nvim_list_wins()
      local non_tree_exists = false

      for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].filetype

        if ft ~= "neo-tree" then
          non_tree_exists = true
          break
        end
      end

      -- if only neo-tree remains, open empty buffer on the right
      if not non_tree_exists then
        vim.cmd("vsplit | enew")
      end
    end)
  end,
})

-- Smart vab: select around the nearest enclosing bracket pair (), [], or {}
local function smart_around_bracket()
  local brackets = { { '(', ')' }, { '[', ']' }, { '{', '}' } }
  local best = nil

  -- Save cursor position
  local save_cursor = vim.fn.getpos('.')

  for _, pair in ipairs(brackets) do
    -- Restore cursor before each search
    vim.fn.setpos('.', save_cursor)

    -- Search backward for the opening bracket of this type
    -- searchpairpos searches for a matching pair, skipping nested pairs
    local row, col = unpack(vim.fn.searchpairpos(
      '\\V' .. pair[1], '', '\\V' .. pair[2], 'bnW'
    ))

    if row ~= 0 then
      -- Found an enclosing bracket of this type
      -- The closer the opening bracket is to the cursor, the more "inner" it is
      local cursor_row = save_cursor[2]
      local cursor_col = save_cursor[3]

      -- Calculate distance (row distance is weighted heavily)
      local dist = (cursor_row - row) * 10000 + (cursor_col - col)

      if best == nil or dist < best.dist then
        best = { dist = dist, open = pair[1] }
      end
    end
  end

  -- Restore cursor position
  vim.fn.setpos('.', save_cursor)

  if best then
    local char = best.open
    -- Use the appropriate va( / va[ / va{ command
    if char == '(' then
      vim.cmd('normal! va(')
    elseif char == '[' then
      vim.cmd('normal! va[')
    elseif char == '{' then
      vim.cmd('normal! va{')
    end
  end
end

vim.keymap.set('n', 'vab', smart_around_bracket, { desc = 'Select around nearest bracket', silent = true })
vim.keymap.set('x', 'ab', smart_around_bracket, { desc = 'Expand selection to around nearest bracket', silent = true })
vim.keymap.set('o', 'ab', smart_around_bracket, { desc = 'Around nearest bracket (operator pending)', silent = true })
