-- One source of truth for project-search exclusions.
-- `exclude('dist')` applies a new path to every Telescope project-search mode.
-- Existing scope exceptions are explicit so current behavior remains unchanged.
local M = {}

local function exclude(path, scopes)
  scopes = scopes or {}
  if next(scopes) == nil then
    scopes = { defaults = true, files = true, picker = true, literal = true, multiline = true }
  end
  return { path = path, scopes = scopes }
end

M.exclusions = {
  exclude('node_modules', { files = true, picker = true, literal = true, multiline = true }),
  exclude('generated', { files = true, picker = true, literal = true, multiline = true }),
  exclude('.git', {
    files = true,
    picker = true,
    literal = true,
    multiline = true,
    picker_pattern = '%.git',
    literal_glob = '!.git/**',
    multiline_glob = '!.git/**',
  }),
  exclude '.next',
  exclude '.cache',
  exclude('.nitro', { defaults = true, files = true, picker = true, literal = true }),
  exclude('.venv', {
    files = true,
    picker = true,
    literal = true,
    multiline = true,
    literal_glob = '!.venv/**',
    multiline_glob = '!.venv/**',
  }),
  exclude('.turbo', { files = true, picker = true }),
  exclude('.husky', { files = true, picker = true }),
  exclude('__pycache__', { files = true, picker = true, literal = true, multiline = true }),
  exclude('_pycache', { files = true, picker = true, literal = true, multiline = true }),
  exclude('package-lock.json', {
    files = true,
    picker = true,
    picker_pattern = 'package%-lock%.json$',
  }),
  exclude('.DS_Store', { files = true }),
  exclude('Thumbs.db', { files = true }),
  exclude('.Spotlight-V100', { files = true }),
  exclude('.Trashes', { files = true }),
}

local function enabled(entry, scope)
  return entry.scopes[scope] == true
end

function M.find_command()
  local args = { 'fd', '--type', 'f', '--hidden', '--no-ignore' }
  for _, entry in ipairs(M.exclusions) do
    if enabled(entry, 'files') then
      vim.list_extend(args, { '--exclude', entry.path })
    end
  end
  return args
end

function M.picker_ignore_patterns()
  local patterns = {}
  for _, entry in ipairs(M.exclusions) do
    if enabled(entry, 'picker') then
      table.insert(patterns, entry.scopes.picker_pattern or vim.pesc(entry.path))
    end
  end
  return patterns
end

local function glob_args(scope, override_key)
  local args = {}
  for _, entry in ipairs(M.exclusions) do
    if enabled(entry, scope) then
      local glob = entry.scopes[override_key] or ('!**/' .. entry.path .. '/**')
      vim.list_extend(args, { '--glob', glob })
    end
  end
  return args
end

function M.default_vimgrep_globs()
  return glob_args('defaults', 'default_glob')
end

function M.literal_grep_globs()
  return glob_args('literal', 'literal_glob')
end

function M.multiline_grep_globs()
  return glob_args('multiline', 'multiline_glob')
end

return M
