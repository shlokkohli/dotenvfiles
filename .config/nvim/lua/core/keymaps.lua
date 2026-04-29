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
vim.keymap.set('i', '∆', '<Esc>:m .+1<CR>==gi', { silent = true }) -- macOS Option+J (move line down)
vim.keymap.set('i', '˚', '<Esc>:m .-2<CR>==gi', { silent = true }) -- macOS Option+K (move line up)

-- normal mode
vim.keymap.set('n', '<A-Up>', ':m .-2<CR>==', { silent = true })
vim.keymap.set('n', '<A-Down>', ':m .+1<CR>==', { silent = true })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { silent = true })
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { silent = true })
vim.keymap.set('n', '˚', ':m .-2<CR>==', { silent = true }) -- macOS Option+K
vim.keymap.set('n', '∆', ':m .+1<CR>==', { silent = true }) -- macOS Option+J

local function open_line_with_same_indent(direction)
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  local indent = line:match '^%s*' or ''
  local count = vim.v.count1
  local lines = {}

  for _ = 1, count do
    table.insert(lines, indent)
  end

  local insert_at = direction == 'below' and line_number or line_number - 1
  vim.api.nvim_buf_set_lines(0, insert_at, insert_at, true, lines)
  vim.api.nvim_win_set_cursor(0, { insert_at + 1, #indent })
  vim.cmd 'startinsert!'
end

vim.keymap.set('n', 'o', function()
  open_line_with_same_indent 'below'
end, { desc = 'Open line below with same indent', silent = true })

vim.keymap.set('n', 'O', function()
  open_line_with_same_indent 'above'
end, { desc = 'Open line above with same indent', silent = true })


vim.keymap.set('n', '<leader>n', ':enew<CR>', { noremap = true, silent = true })

-- visual mode
vim.keymap.set('v', '<A-Up>', ":m '<-2<CR>gv=gv", { silent = true })
vim.keymap.set('v', '<A-Down>', ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { silent = true })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set('v', '˚', ":m '<-2<CR>gv=gv", { silent = true })  -- macOS Option+K
vim.keymap.set('v', '∆', ":m '>+1<CR>gv=gv", { silent = true }) -- macOS Option+J

-- insert mode
vim.keymap.set('i', '<A-Up>', '<Esc>:m .-2<CR>==gi', { silent = true })
vim.keymap.set('i', '<A-Down>', '<Esc>:m .+1<CR>==gi', { silent = true })
vim.keymap.set('i', '<A-k>', '<Esc>:m .-2<CR>==gi', { silent = true })
vim.keymap.set('i', '<A-j>', '<Esc>:m .+1<CR>==gi', { silent = true })

-- Switch to insert mode
vim.keymap.set('i', 'jk', '<Esc>', { noremap = true, silent = true })

-- Disable the spacebar key's default behavior in Normal and Visual modes
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set({ 'n', 'i', 'v', 'x', 's', 'o', 'c', 't' }, '<C-z>', '<Nop>', { silent = true, desc = 'Disable suspend' })

vim.keymap.set('n', '<leader>cc', '<cmd>cclose<CR>', { desc = 'Close quickfix' })

-- normal and visual mode: d = delete (no yank)
vim.keymap.set({ 'n', 'v' }, 'd', '"_d', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, 'D', '"_D', { noremap = true, silent = true })

-- normal and visual mode: _d = cut (yank + delete)
vim.keymap.set({ 'n', 'v' }, '_d', 'd', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, '_D', 'D', { noremap = true, silent = true })

-- normal and visual mode: c = change (no yank)
vim.keymap.set({ 'n', 'v' }, 'c', '"_c', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, 'C', '"_C', { noremap = true, silent = true })

-- normal and visual mode: _c = cut to clipboard + change
vim.keymap.set({ 'n', 'v' }, '_c', '"+c', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, '_C', '"+C', { noremap = true, silent = true })

-- visual mode: y = yank without moving cursor
vim.keymap.set({ 'v', 'x' }, 'y', 'ygv<Esc>', { noremap = true, silent = true, desc = 'Yank without moving cursor' })

local function flash_copied_filename()
  local bufferline_groups = {
    'BufferCurrent',
    'BufferCurrentIndex',
    'BufferCurrentMod',
    'BufferCurrentSign',
    'BufferCurrentIcon',
  }
  local original_highlights = {}

  for _, group in ipairs(bufferline_groups) do
    local ok, highlight = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    original_highlights[group] = ok and highlight or nil
    pcall(vim.api.nvim_set_hl, 0, group, { link = 'IncSearch' })
  end

  vim.g.copied_filename_flash = true
  pcall(function()
    require('lualine').refresh()
  end)
  vim.cmd.redrawtabline()

  vim.defer_fn(function()
    for _, group in ipairs(bufferline_groups) do
      pcall(vim.api.nvim_set_hl, 0, group, original_highlights[group] or {})
    end

    vim.g.copied_filename_flash = false
    pcall(function()
      require('lualine').refresh()
    end)
    vim.cmd.redrawtabline()
  end, 180)
end

vim.keymap.set('n', '<leader>yf', function()
  local filename = vim.fn.expand '%:t'
  vim.fn.setreg('+', filename)
  flash_copied_filename()
  vim.notify('Copied file name: ' .. filename)
end, { desc = 'Copy current file name' })

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

local function go_to_line_percent(percent)
  local first_code_column = math.max(1, vim.fn.indent('.') + 1)
  local line_width = math.max(first_code_column, vim.fn.virtcol('$') - 1)
  local code_width = math.max(1, line_width - first_code_column + 1)
  local column = first_code_column + math.floor(code_width * percent)
  vim.cmd('normal! ' .. column .. '|')
end

vim.keymap.set({ 'n', 'x' }, 'gm', function()
  go_to_line_percent(0.5)
end, { desc = 'Go to middle of text line', noremap = true })

vim.keymap.set({ 'n', 'x' }, 'gq', function()
  go_to_line_percent(0.25)
end, { desc = 'Go to 25% of text line', noremap = true })

vim.keymap.set({ 'n', 'x' }, 'gqq', function()
  go_to_line_percent(0.75)
end, { desc = 'Go to 75% of text line', noremap = true })

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
local function buffer_goto_maybe_restore_visual(index)
  return function()
    mark_restore_visual_if_needed()
    vim.cmd.BufferGoto(index)
  end
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
vim.keymap.set('v', '<Tab>', buffer_next_maybe_restore_visual, opts)
vim.keymap.set('v', '<S-Tab>', buffer_prev_maybe_restore_visual, opts)
vim.keymap.set('n', '<leader>b', '<cmd> enew <CR>', opts) -- new buffer
vim.keymap.set('n', '<leader>x', '<Cmd>BufferClose<CR>', opts)

-- Window management
vim.keymap.set('n', '<leader>v', '<C-w>v', opts) -- split window vertically
vim.keymap.set('n', '<leader>h', '<C-w>s', opts) -- split window horizontally
vim.keymap.set('n', '<leader>se', '<C-w>=', opts) -- make split windows equal width & height
vim.keymap.set('n', '<leader>xs', '<cmd>close<CR>', opts) -- close current split window

-- Navigate between splits
vim.keymap.set('n', '<C-k>', ':wincmd k<CR>', opts)
vim.keymap.set('n', '<C-j>', ':wincmd j<CR>', opts)
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
-- Ghostty custom sequences from ~/.config/ghostty/config
vim.keymap.set('n', '\x1b[27;5;9~', '<Cmd>BufferNext<CR>', opts)
vim.keymap.set('n', '\x1b[27;6;9~', '<Cmd>BufferPrevious<CR>', opts)
vim.keymap.set('v', '\x1b[27;5;9~', buffer_next_maybe_restore_visual, opts)
vim.keymap.set('v', '\x1b[27;6;9~', buffer_prev_maybe_restore_visual, opts)
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
vim.keymap.set('v', '\x1b[49;5u', buffer_goto_maybe_restore_visual(1), opts)
vim.keymap.set('v', '\x1b[50;5u', buffer_goto_maybe_restore_visual(2), opts)
vim.keymap.set('v', '\x1b[51;5u', buffer_goto_maybe_restore_visual(3), opts)
vim.keymap.set('v', '\x1b[52;5u', buffer_goto_maybe_restore_visual(4), opts)
vim.keymap.set('v', '\x1b[53;5u', buffer_goto_maybe_restore_visual(5), opts)
vim.keymap.set('v', '\x1b[54;5u', buffer_goto_maybe_restore_visual(6), opts)
vim.keymap.set('v', '\x1b[55;5u', buffer_goto_maybe_restore_visual(7), opts)
vim.keymap.set('v', '\x1b[56;5u', buffer_goto_maybe_restore_visual(8), opts)
vim.keymap.set('v', '\x1b[57;5u', buffer_goto_maybe_restore_visual(9), opts)

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
vim.keymap.set('v', '<A-,>', buffer_prev_maybe_restore_visual, { silent = true })
vim.keymap.set('v', '<A-.>', buffer_next_maybe_restore_visual, { silent = true })
vim.keymap.set('n', '<C-1>', '<Cmd>BufferGoto 1<CR>', { silent = true })
vim.keymap.set('n', '<C-2>', '<Cmd>BufferGoto 2<CR>', { silent = true })
vim.keymap.set('n', '<C-3>', '<Cmd>BufferGoto 3<CR>', { silent = true })
vim.keymap.set('n', '<C-4>', '<Cmd>BufferGoto 4<CR>', { silent = true })
vim.keymap.set('n', '<C-5>', '<Cmd>BufferGoto 5<CR>', { silent = true })
vim.keymap.set('n', '<C-6>', '<Cmd>BufferGoto 6<CR>', { silent = true })
vim.keymap.set('n', '<C-7>', '<Cmd>BufferGoto 7<CR>', { silent = true })
vim.keymap.set('n', '<C-8>', '<Cmd>BufferGoto 8<CR>', { silent = true })
vim.keymap.set('n', '<C-9>', '<Cmd>BufferGoto 9<CR>', { silent = true })
vim.keymap.set('v', '<C-1>', buffer_goto_maybe_restore_visual(1), { silent = true })
vim.keymap.set('v', '<C-2>', buffer_goto_maybe_restore_visual(2), { silent = true })
vim.keymap.set('v', '<C-3>', buffer_goto_maybe_restore_visual(3), { silent = true })
vim.keymap.set('v', '<C-4>', buffer_goto_maybe_restore_visual(4), { silent = true })
vim.keymap.set('v', '<C-5>', buffer_goto_maybe_restore_visual(5), { silent = true })
vim.keymap.set('v', '<C-6>', buffer_goto_maybe_restore_visual(6), { silent = true })
vim.keymap.set('v', '<C-7>', buffer_goto_maybe_restore_visual(7), { silent = true })
vim.keymap.set('v', '<C-8>', buffer_goto_maybe_restore_visual(8), { silent = true })
vim.keymap.set('v', '<C-9>', buffer_goto_maybe_restore_visual(9), { silent = true })
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

local function node_type_matches_function(node)
  local node_type = node:type()
  return node_type:find('function', 1, true) ~= nil
    or node_type:find('method', 1, true) ~= nil
    or node_type == 'arrow_function'
    or node_type == 'lambda'
    or node_type == 'closure_expression'
end

local function get_function_node()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok then
    node = nil
  end

  if not node then
    local parser_ok, parser = pcall(vim.treesitter.get_parser, 0)
    if not parser_ok or not parser then
      return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local col = cursor[2]
    local tree = parser:parse()[1]
    node = tree and tree:root():named_descendant_for_range(row, col, row, col)
  end

  while node do
    if node_type_matches_function(node) then
      return node
    end
    node = node:parent()
  end

  return nil
end

local function trim_range(start_row, start_col, end_row, end_col)
  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
  if #lines == 0 then
    return start_row, start_col, end_row, end_col
  end

  while #lines > 0 and lines[1]:match('^%s*$') do
    start_row = start_row + 1
    table.remove(lines, 1)
    start_col = 0
  end

  while #lines > 0 and lines[#lines]:match('^%s*$') do
    end_row = end_row - 1
    table.remove(lines)
    end_col = #(lines[#lines] or '')
  end

  if #lines == 0 then
    return start_row, start_col, end_row, end_col
  end

  local first_indent = lines[1]:sub(start_col + 1):match('^%s*') or ''
  start_col = start_col + #first_indent

  local last_content_end = lines[#lines]:match('^.*%S()')
  if last_content_end then
    end_col = last_content_end - 1
  end

  return start_row, start_col, end_row, end_col
end

local function inclusive_end_position(row, col)
  if col > 0 then
    return row, col
  end

  if row == 0 then
    return row, col
  end

  local previous_line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
  return row - 1, #previous_line
end

local function select_range(start_row, start_col, end_row, end_col)
  end_row, end_col = inclusive_end_position(end_row, end_col)

  if end_row < start_row or (end_row == start_row and end_col < start_col) then
    return
  end

  vim.fn.setpos('.', { 0, start_row + 1, start_col + 1, 0 })
  vim.cmd('normal! v')
  vim.fn.setpos('.', { 0, end_row + 1, end_col, 0 })
end

local function python_def_indent(line)
  return line:match('^(%s*)async%s+def%s+') or line:match('^(%s*)def%s+')
end

local function leading_whitespace(line)
  return line:match('^%s*') or ''
end

local function select_python_function(inner)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor[1] - 1
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local start_row = nil
  local def_indent = nil

  for row = cursor_row, 0, -1 do
    local indent = python_def_indent(lines[row + 1] or '')
    if indent then
      start_row = row
      def_indent = indent
      break
    end
  end

  if not start_row then
    return false
  end

  local end_row = #lines - 1
  local last_content_row = start_row

  for row = start_row + 1, #lines - 1 do
    local line = lines[row + 1] or ''
    if line:match('%S') then
      local indent = leading_whitespace(line)
      if #indent <= #def_indent then
        end_row = math.max(start_row, row - 1)
        break
      end
      last_content_row = row
    end
  end

  if inner then
    start_row = start_row + 1
    while start_row <= end_row and not (lines[start_row + 1] or ''):match('%S') do
      start_row = start_row + 1
    end

    end_row = last_content_row
    while end_row >= start_row and not (lines[end_row + 1] or ''):match('%S') do
      end_row = end_row - 1
    end
  end

  if end_row < start_row then
    return false
  end

  local start_col = inner and #leading_whitespace(lines[start_row + 1] or '') or 0
  local end_col = #(lines[end_row + 1] or '')
  select_range(start_row, start_col, end_row, end_col)
  return true
end

local function function_body_node(function_node)
  local ok, body = pcall(function()
    return function_node:field('body')[1]
  end)

  if ok and body then
    return body
  end

  for child in function_node:iter_children() do
    local node_type = child:type()
    if node_type:find('block', 1, true) or node_type == 'body' then
      return child
    end
  end

  return nil
end

local function select_function(inner)
  local function_node = get_function_node()
  if not function_node then
    if vim.bo.filetype == 'python' and select_python_function(inner) then
      return
    end

    vim.notify('No Treesitter function found under cursor', vim.log.levels.INFO)
    return
  end

  local start_row, start_col, end_row, end_col = function_node:range()

  if inner then
    local body = function_body_node(function_node)
    if body then
      start_row, start_col, end_row, end_col = body:range()

      local first_line = vim.api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1] or ''
      local last_line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1] or ''

      if first_line:sub(start_col + 1, start_col + 1) == '{' then
        start_col = start_col + 1
      end

      if end_col > 0 and last_line:sub(end_col, end_col) == '}' then
        end_col = end_col - 1
      end

      start_row, start_col, end_row, end_col = trim_range(start_row, start_col, end_row, end_col)
    end
  end

  select_range(start_row, start_col, end_row, end_col)
end

vim.keymap.set({ 'x', 'o' }, 'af', function()
  select_function(false)
end, { desc = 'Around function', silent = true })

vim.keymap.set({ 'x', 'o' }, 'if', function()
  select_function(true)
end, { desc = 'Inside function', silent = true })

vim.keymap.set('n', 'vaf', function()
  select_function(false)
end, { desc = 'Select around function', silent = true })

vim.keymap.set('n', 'vif', function()
  select_function(true)
end, { desc = 'Select inside function', silent = true })
