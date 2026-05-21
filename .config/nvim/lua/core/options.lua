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
vim.opt.formatoptions:remove { 'c', 'r', 'o' } -- Don't insert the current comment leader automatically for auto-wrapping comments using 'textwidth', hitting <Enter> in insert mode, or hitting 'o' or 'O' in normal mode. (default: 'croql')
vim.opt.runtimepath:remove '/usr/share/vim/vimfiles' -- Separate Vim plugins from Neovim in case Vim still in use (default: includes this path if Vim is installed)

-- Treesitter-based folding (set per-buffer so Treesitter is attached first)
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.opt.fillchars:append { fold = ' ' }

local function get_fold_summary_text(fold_start, fold_end)
  local hidden_lines = fold_end - fold_start
  local line_word = hidden_lines == 1 and 'line' or 'lines'

  return string.format('  +-- %d %s of code minimized', hidden_lines, line_word)
end

function _G.VSCodeFoldText()
  return {
    { vim.fn.getline(vim.v.foldstart), 'Normal' },
    { get_fold_summary_text(vim.v.foldstart, vim.v.foldend), 'Folded' },
    { string.rep(' ', vim.o.columns), 'Normal' },
  }
end

vim.o.foldtext = 'v:lua.VSCodeFoldText()'

local old_fold_virtual_lines_ns = vim.api.nvim_create_namespace 'vscode-fold-virtual-lines'
for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, old_fold_virtual_lines_ns, 0, -1)
  end
end

local smart_fold_cache = {}

local ignored_fold_node_types = {
  chunk = true,
  document = true,
  module = true,
  program = true,
  source_file = true,
  translation_unit = true,
}

local semantic_fold_node_types = {
  argument_list = true,
  arguments = true,
  arrow_function = true,
  array = true,
  block = true,
  call = true,
  call_expression = true,
  case_statement = true,
  catch_clause = true,
  class_body = true,
  class_declaration = true,
  class_definition = true,
  compound_statement = true,
  constructor = true,
  declaration_list = true,
  dictionary = true,
  do_statement = true,
  else_clause = true,
  enum_declaration = true,
  element = true,
  field_declaration_list = true,
  for_in_statement = true,
  for_statement = true,
  function_call = true,
  function_declaration = true,
  function_definition = true,
  function_expression = true,
  function_item = true,
  if_statement = true,
  impl_item = true,
  interface_declaration = true,
  lambda = true,
  lambda_expression = true,
  list = true,
  match_statement = true,
  method_declaration = true,
  method_definition = true,
  object = true,
  repeat_statement = true,
  set = true,
  script_element = true,
  statement_block = true,
  struct_declaration = true,
  style_element = true,
  switch_statement = true,
  table_constructor = true,
  template_element = true,
  trait_item = true,
  try_statement = true,
  tuple = true,
  while_statement = true,
}

local function is_semantic_fold_node(node_type)
  if ignored_fold_node_types[node_type] then
    return false
  end

  if semantic_fold_node_types[node_type] then
    return true
  end

  return node_type:match('block$') ~= nil
    or node_type:match('body$') ~= nil
    or node_type:match('function') ~= nil
    or node_type:match('method') ~= nil
    or node_type:match('class') ~= nil
    or node_type:match('interface') ~= nil
end

local function collect_semantic_fold_ranges(node, ranges, seen, line_count, line_offset)
  line_offset = line_offset or 0
  local node_type = node:type()
  local start_row, _, end_row = node:range()
  local start_line = start_row + line_offset + 1
  local end_line = math.min(end_row + line_offset + 1, line_count)

  if end_line > start_line and is_semantic_fold_node(node_type) then
    local key = start_line .. ':' .. end_line
    if not seen[key] then
      seen[key] = true
      table.insert(ranges, { start_line = start_line, end_line = end_line })
    end
  end

  for child in node:iter_children() do
    collect_semantic_fold_ranges(child, ranges, seen, line_count, line_offset)
  end
end

local function get_vue_script_parser_lang(script_text)
  local lang = script_text:match('<script[^>]-lang%s*=%s*["\']?([%w_-]+)')
  lang = lang and lang:lower() or nil

  if lang == 'ts' or lang == 'typescript' then
    return 'typescript'
  end

  if lang == 'tsx' then
    return 'tsx'
  end

  if lang == 'jsx' then
    return 'jsx'
  end

  return 'javascript'
end

local function collect_vue_embedded_script_fold_ranges(node, bufnr, ranges, seen, line_count)
  if node:type() == 'script_element' then
    local raw_text_node = nil

    for child in node:iter_children() do
      if child:type() == 'raw_text' then
        raw_text_node = child
        break
      end
    end

    if raw_text_node then
      local script_text = vim.treesitter.get_node_text(node, bufnr)
      local raw_text = vim.treesitter.get_node_text(raw_text_node, bufnr)
      local parser_lang = get_vue_script_parser_lang(script_text)
      local ok, parser = pcall(vim.treesitter.get_string_parser, raw_text, parser_lang)

      if ok and parser then
        local parse_ok, trees = pcall(parser.parse, parser)
        if parse_ok and trees and trees[1] then
          local raw_start_row = raw_text_node:range()
          collect_semantic_fold_ranges(trees[1]:root(), ranges, seen, line_count, raw_start_row)
        end
      end
    end
  end

  for child in node:iter_children() do
    collect_vue_embedded_script_fold_ranges(child, bufnr, ranges, seen, line_count)
  end
end

local function get_smart_fold_levels(bufnr)
  local changedtick = vim.b[bufnr].changedtick
  local cached = smart_fold_cache[bufnr]

  if cached and cached.changedtick == changedtick and cached.filetype == vim.bo[bufnr].filetype then
    return cached.levels
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local levels = {}
  for line = 1, line_count do
    levels[line] = 0
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    smart_fold_cache[bufnr] = {
      changedtick = changedtick,
      filetype = vim.bo[bufnr].filetype,
      levels = levels,
    }
    return levels
  end

  local parse_ok, trees = pcall(parser.parse, parser)
  if not parse_ok or not trees or not trees[1] then
    return levels
  end

  local ranges = {}
  local seen = {}
  local root = trees[1]:root()
  collect_semantic_fold_ranges(root, ranges, seen, line_count)

  if vim.bo[bufnr].filetype == 'vue' then
    collect_vue_embedded_script_fold_ranges(root, bufnr, ranges, seen, line_count)
  end

  for _, range in ipairs(ranges) do
    for line = range.start_line, range.end_line do
      levels[line] = levels[line] + 1
    end
  end

  smart_fold_cache[bufnr] = {
    changedtick = changedtick,
    filetype = vim.bo[bufnr].filetype,
    levels = levels,
  }

  return levels
end

function _G.SmartTreesitterFoldexpr(lnum)
  local levels = get_smart_fold_levels(vim.api.nvim_get_current_buf())
  return levels[lnum] or 0
end

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
  local ts_level = _G.SmartTreesitterFoldexpr(lnum)

  return math.max(jsx_level, ts_level)
end

function _G.ReactJsxEnclosingFoldStart()
  if vim.bo.filetype ~= 'javascriptreact' and vim.bo.filetype ~= 'typescriptreact' then
    return nil
  end

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
      vim.opt_local.foldexpr = 'v:lua.SmartTreesitterFoldexpr(v:lnum)'
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
