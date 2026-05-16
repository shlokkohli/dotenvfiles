return {
  'nvim-pack/nvim-spectre',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  keys = {
    {
      '<leader>S',
      function()
        require('spectre').toggle()
      end,
      desc = 'Toggle project search and replace',
    },
    {
      '<leader>S',
      function()
        local spectre = require 'spectre'
        if vim.bo.filetype == 'spectre_panel' then
          spectre.close()
        else
          spectre.open_visual()
        end
      end,
      mode = 'x',
      desc = 'Search and replace selection in project',
    },
  },
  opts = {},
}
