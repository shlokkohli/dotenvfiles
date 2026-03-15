return {
  'akinsho/toggleterm.nvim',
  version = '*',
  opts = {
    size = function(term)
      if term.direction == 'horizontal' then
        return 15
      elseif term.direction == 'vertical' then
        return vim.o.columns * 0.4
      end
    end,
    -- open_mapping removed: it gets shadowed by buffer-local plugin keymaps
    direction = 'float',
    float_opts = {
      border = 'curved',
    },
  },
  config = function(_, opts)
    require('toggleterm').setup(opts)
    -- Explicit global keymap that can't be shadowed by buffer-local maps
    vim.keymap.set({ 'n', 'i', 't' }, '<C-j>', '<cmd>ToggleTerm<CR>', {
      noremap = true,
      silent = true,
      desc = 'Toggle terminal',
    })
  end,
}
