local function extend_match_highlight(matches)
  for _, match in ipairs(matches) do
    if match.pos[1] == match.end_pos[1] then
      local buf = vim.api.nvim_win_get_buf(match.win)
      local line = vim.api.nvim_buf_get_lines(buf, match.end_pos[1] - 1, match.end_pos[1], false)[1] or ''

      if match.end_pos[2] < #line - 1 then
        match.end_pos[2] = match.end_pos[2] + 1
      end
    end
  end

  return matches
end

local function set_flash_highlights()
  vim.api.nvim_set_hl(0, 'FlashFMatch', { fg = '#cad3f5', bg = '#363a4f', bold = true })
  vim.api.nvim_set_hl(0, 'FlashFCurrent', { fg = '#181926', bg = '#8aadf4', bold = true })
end

return {
  'folke/flash.nvim',
  lazy = false,
  config = function(_, opts)
    require('flash').setup(opts)
    set_flash_highlights()

    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('flash-f-highlight', { clear = true }),
      callback = set_flash_highlights,
    })
  end,
  opts = {
    search = {
      multi_window = false,
    },
    jump = {
      history = true,
      nohlsearch = true,
      register = true,
    },
    label = {
      after = false,
      before = false,
    },
    modes = {
      char = {
        enabled = false,
      },
    },
  },
  keys = {
    {
      's',
      mode = { 'n', 'x', 'o' },
      function()
        require('flash').jump({
          filter = extend_match_highlight,
          highlight = {
            groups = {
              match = 'FlashFMatch',
              current = 'FlashFCurrent',
            },
          },
        })
      end,
      desc = 'Flash',
    },
    {
      'S',
      mode = { 'n', 'x', 'o' },
      function()
        require('flash').treesitter()
      end,
      desc = 'Flash Treesitter',
    },
    {
      'r',
      mode = 'o',
      function()
        require('flash').remote()
      end,
      desc = 'Remote Flash',
    },
    {
      'R',
      mode = { 'o', 'x' },
      function()
        require('flash').treesitter_search()
      end,
      desc = 'Treesitter Search',
    },
    {
      '<C-s>',
      mode = 'c',
      function()
        require('flash').toggle()
      end,
      desc = 'Toggle Flash Search',
    },
  },
}
