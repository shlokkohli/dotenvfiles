vim.wo.number = true -- Make line numbers default (default: false)
vim.o.relativenumber = true -- Set relative numbered lines (default: false)
vim.o.clipboard = 'unnamedplus' -- Sync clipboard between OS and Neovim. (default: '')
vim.o.wrap = false -- Display lines as one long line (default: true)
vim.o.linebreak = true -- Companion to wrap, don't split words (default: false)
vim.o.breakindent = true -- Enable break indent (default: false)
vim.o.mouse = 'a' -- Enable mouse mode (default: '')
vim.o.autoindent = true -- Copy indent from current line when starting new one (default: true)
vim.o.ignorecase = true -- Case-insensitive searching UNLESS \C or capital in search (default: false)
vim.o.smartcase = true -- Smart case (default: false)
vim.o.shiftwidth = 4 -- The number of spaces inserted for each indentation (default: 8)
vim.o.tabstop = 4 -- Insert n spaces for a tab (default: 8)
vim.o.softtabstop = 4 -- Number of spaces that a tab counts for while performing editing operations (default: 0)
vim.o.expandtab = true -- Convert tabs to spaces (default: false)
vim.o.scrolloff = 4 -- Minimal number of screen lines to keep above and below the cursor (default: 0)
vim.o.sidescrolloff = 8 -- Minimal number of screen columns either side of cursor if wrap is `false` (default: 0)
vim.o.cursorline = true -- Highlight the current line (default: false)
vim.o.cursorlineopt = 'both' -- Highlight both the current line number and line
vim.o.splitbelow = true -- Force all horizontal splits to go below current window (default: false)
vim.o.splitright = true -- Force all vertical splits to go to the right of current window (default: false)
vim.o.hlsearch = false -- Set highlight on search (default: true)
vim.o.showmode = false -- We don't need to see things like -- INSERT -- anymore (default: true)
vim.opt.termguicolors = true -- Set termguicolors to enable highlight groups (default: false)
vim.o.whichwrap = 'bs<>[]hl' -- Which "horizontal" keys are allowed to travel to prev/next line (default: 'b,s')
vim.o.numberwidth = 4 -- Set number column width to 2 {default 4} (default: 4)
vim.o.swapfile = false -- Creates a swapfile (default: true)
vim.o.smartindent = true -- Make indenting smarter again (default: false)
vim.o.showtabline = 2 -- Always show tabs (default: 1)
vim.o.backspace = 'indent,eol,start' -- Allow backspace on (default: 'indent,eol,start')
vim.o.pumheight = 10 -- Pop up menu height (default: 0)
vim.o.conceallevel = 0 -- So that `` is visible in markdown files (default: 1)
vim.opt.signcolumn = 'yes' -- Keep signcolumn on by default (default: 'auto')
vim.o.fileencoding = 'utf-8' -- The encoding written to a file (default: 'utf-8')
vim.o.cmdheight = 0 -- No command line area, statusline sticks to the bottom
vim.o.updatetime = 250 -- Decrease update time (default: 4000)
vim.o.timeoutlen = 300 -- Time to wait for a mapped sequence to complete (in milliseconds) (default: 1000)
vim.o.backup = false -- Creates a backup file (default: false)
vim.o.writebackup = false -- If a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited (default: true)
vim.o.autoread = true -- Reload files changed outside Neovim when safe
vim.o.undofile = false -- Save undo history (default: false)
vim.o.completeopt = 'menuone,noselect' -- Set completeopt to have a better completion experience (default: 'menu,preview')
vim.opt.shortmess:append 'c' -- Don't give |ins-completion-menu| messages (default: does not include 'c')
vim.opt.iskeyword:append '-' -- Hyphenated words recognized by searches (default: does not include '-')
vim.opt.formatoptions:remove { 'c', 'r', 'o' } -- Don't insert the current comment leader automatically for auto-wrapping comments using 'textwidth', hitting <Enter> in insert mode, or hitting 'o' or 'O' in normal mode. (default: 'croql')
vim.opt.runtimepath:remove '/usr/share/vim/vimfiles' -- Separate Vim plugins from Neovim in case Vim still in use (default: includes this path if Vim is installed)

-- Treesitter-based folding (set per-buffer so Treesitter is attached first)
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

local jsx_fold_cache = {}

local function line_for_offset(line_starts, offset)
  local low = 1
  local high = #line_starts

  while low <= high do
    local mid = math.floor((low + high) / 2)
    local next_start = line_starts[mid + 1] or math.huge

    if offset < line_starts[mid] then
      high = mid - 1
    elseif offset >= next_start then
      low = mid + 1
    else
      return mid
    end
  end

  return #line_starts
end

local function parse_jsx_folds(bufnr)
  local changedtick = vim.b[bufnr].changedtick
  local cached = jsx_fold_cache[bufnr]
  if cached and cached.changedtick == changedtick then
    return cached
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(lines, '\n')
  local line_starts = {}
  local offset = 1

  for _, line in ipairs(lines) do
    table.insert(line_starts, offset)
    offset = offset + #line + 1
  end

  local stack = {}
  local ranges = {}
  local pos = 1

  while pos <= #text do
    local start_pos, end_pos, tag = text:find('<(.-)>', pos)
    if not start_pos then
      break
    end

    local start_line = line_for_offset(line_starts, start_pos)
    local end_line = line_for_offset(line_starts, end_pos)
    local trimmed = tag:match('^%s*(.-)%s*$') or ''
    local is_special = trimmed:match('^[!?]') ~= nil
    local is_closing = trimmed:match('^/') ~= nil
    local is_self_closing = trimmed:match('/%s*$') ~= nil
    local name = nil

    if trimmed == '' then
      name = ''
    elseif is_closing then
      name = trimmed:match('^/%s*([%w_.:-]+)') or ''
    elseif not is_special then
      name = trimmed:match('^([%w_.:-]+)')
    end

    if name then
      if is_closing then
        for i = #stack, 1, -1 do
          if stack[i].name == name then
            local open = table.remove(stack, i)
            if open.line < end_line then
              table.insert(ranges, { start_line = open.line, end_line = end_line })
            end
            break
          end
        end
      elseif not is_self_closing then
        table.insert(stack, { name = name, line = start_line })
      end
    end

    pos = end_pos + 1
  end

  local levels = {}
  for i = 1, #lines do
    levels[i] = 0
  end

  for _, range in ipairs(ranges) do
    for line = range.start_line, range.end_line do
      levels[line] = levels[line] + 1
    end
  end

  cached = {
    changedtick = changedtick,
    levels = levels,
    ranges = ranges,
  }
  jsx_fold_cache[bufnr] = cached
  return cached
end

function _G.ReactJsxFoldexpr(lnum)
  local folds = parse_jsx_folds(vim.api.nvim_get_current_buf())
  local jsx_level = folds.levels[lnum] or 0
  local ts_level = 0

  local ok, value = pcall(vim.treesitter.foldexpr)
  if ok then
    ts_level = tonumber(value) or tonumber(tostring(value):match('%d+')) or 0
  end

  return math.max(jsx_level, ts_level)
end

function _G.ReactJsxEnclosingFoldStart()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local folds = parse_jsx_folds(bufnr)
  local best = nil

  for _, range in ipairs(folds.ranges) do
    if range.start_line <= cursor_line and cursor_line <= range.end_line then
      if not best or (range.end_line - range.start_line) < (best.end_line - best.start_line) then
        best = range
      end
    end
  end

  return best and best.start_line or nil
end

vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile', 'FileType' }, {
  group = vim.api.nvim_create_augroup('ts-folding', { clear = true }),
  callback = function()
    if vim.bo.filetype == 'javascriptreact' or vim.bo.filetype == 'typescriptreact' then
      vim.opt_local.foldmethod = 'expr'
      vim.opt_local.foldexpr = 'v:lua.ReactJsxFoldexpr(v:lnum)'
      return
    end

    -- Only enable if Treesitter can parse this buffer
    local ok = pcall(vim.treesitter.get_parser, 0)
    if ok then
      vim.opt_local.foldmethod = 'expr'
      vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    else
      vim.opt_local.foldmethod = 'indent' -- fallback for unsupported filetypes
    end
  end,
})

-- Note: Telescope literal search is handled via --fixed-strings in vimgrep_arguments
-- (see telescope.lua). Do NOT set vim.o.magic = false here — it breaks Telescope's
-- internal cursor positioning when jumping to matched lines.
vim.o.title = true -- Set the terminal title (default: false)
vim.o.titlestring = '%{fnamemodify(getcwd(), ":t")}' -- Show only the folder name

-- Friendly quit commands: show clear messages instead of cryptic E37/E162
vim.api.nvim_create_user_command('Q', function(opts)
  local ok, err = pcall(vim.cmd, 'q' .. (opts.bang and '!' or ''))
  if not ok then
    if err:match 'E37' or err:match 'E162' then
      vim.notify(
        ' You have unsaved changes!\n'
          .. '  :wq  → save and quit\n'
          .. '  :q!  → discard changes and quit\n'
          .. '  :wqa → save all files and quit\n'
          .. '  :qa! → discard all and quit',
        vim.log.levels.WARN
      )
    else
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, { bang = true, desc = 'Quit with friendly messages' })

vim.api.nvim_create_user_command('Qa', function(opts)
  local ok, err = pcall(vim.cmd, 'qa' .. (opts.bang and '!' or ''))
  if not ok then
    if err:match 'E37' or err:match 'E162' then
      vim.notify(' You have unsaved files!\n' .. '  :wqa → save all and quit\n' .. '  :qa! → discard all changes and quit', vim.log.levels.WARN)
    else
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, { bang = true, desc = 'Quit all with friendly messages' })

-- Redirect :q and :qa to the friendly versions
vim.cmd [[cabbrev W w]]
vim.cmd [[cabbrev q Q]]
vim.cmd [[cabbrev qa Qa]]

-- Refresh buffers when files change outside Neovim (for example in VS Code)
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI', 'TermClose', 'TermLeave' }, {
  group = vim.api.nvim_create_augroup('auto-reload-on-focus', { clear = true }),
  callback = function()
    if vim.fn.mode() ~= 'c' then
      vim.cmd 'checktime'
    end
  end,
})

-- Auto-detect when buffer content matches the saved file and clear "modified" flag
-- This lets you :q without errors if you manually revert your changes
vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
  group = vim.api.nvim_create_augroup('auto-unmodify', { clear = true }),
  callback = function(ev)
    local buf = ev.buf
    -- Only check named files that are marked as modified
    local filename = vim.api.nvim_buf_get_name(buf)
    if filename == '' or not vim.bo[buf].modified then
      return
    end
    -- Read the file from disk and compare with buffer content
    local ok, disk_lines = pcall(vim.fn.readfile, filename)
    if not ok then
      return
    end
    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if #disk_lines ~= #buf_lines then
      return
    end
    for i = 1, #disk_lines do
      if disk_lines[i] ~= buf_lines[i] then
        return
      end
    end
    -- Content matches the saved file, clear the modified flag
    vim.bo[buf].modified = false
    -- Notify Neo-tree so the [+] indicator updates immediately
    vim.api.nvim_exec_autocmds('BufModifiedSet', { buffer = buf })
  end,
})

-- Treat .env files as shell scripts for proper syntax highlighting
vim.filetype.add {
  extension = {
    prisma = 'prisma',
  },
  filename = {
    ['.env'] = 'sh',
  },
  pattern = {
    ['.*%.env%..*'] = 'sh', -- .env.local, .env.staging, etc.
  },
}

-- .js and .ts files are always treated as plain JavaScript/TypeScript.
-- Use .jsx / .tsx extensions for React files.

-- Open image files with the system viewer instead of displaying binary garbage
vim.api.nvim_create_autocmd('BufReadCmd', {
  pattern = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.bmp', '*.webp', '*.svg', '*.ico' },
  callback = function(ev)
    vim.fn.jobstart({ 'open', ev.file }, { detach = true })
    -- Delete the empty buffer that was created
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        vim.api.nvim_buf_delete(ev.buf, { force = true })
      end
    end)
  end,
})
