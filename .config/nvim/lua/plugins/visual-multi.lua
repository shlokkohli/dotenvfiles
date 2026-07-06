return {
  'mg979/vim-visual-multi',
  branch = 'master',
  keys = {
    { '<C-n>', '<Plug>(VM-Find-Under)', mode = { 'n', 'x' }, desc = 'Visual Multi find under' },
    { '<M-n>', '<Plug>(VM-Select-All)', mode = { 'n', 'x' }, desc = 'Visual Multi select all' },
    { '<C-Down>', '<Plug>(VM-Add-Cursor-Down)', mode = 'n', desc = 'Visual Multi cursor down' },
    { '<C-Up>', '<Plug>(VM-Add-Cursor-Up)', mode = 'n', desc = 'Visual Multi cursor up' },
  },
  init = function()
    -- optional: you can customize some settings here if you want
    vim.g.VM_default_mappings = 0 -- disable default mappings if you want to define your own
  end,
}
