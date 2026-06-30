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
  config = function()
    require('spectre').setup {}

    -- The Spectre panel is a preview, not a writable file. In that panel only,
    -- make :w apply all enabled replacements instead of trying to write it.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'spectre_panel',
      callback = function()
        vim.cmd [[cnoreabbrev <buffer> <expr> w getcmdtype() ==# ':' && getcmdline() ==# 'w' ? "lua require('spectre.actions').run_replace()" : 'w']]
      end,
      desc = 'Use :w to apply all Spectre replacements',
    })
  end,
}
