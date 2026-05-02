-- Easily comment visual regions/lines
return {
  'numToStr/Comment.nvim',
  dependencies = {
    'JoosepAlviste/nvim-ts-context-commentstring',
  },
  config = function()
    require('ts_context_commentstring').setup {
      enable_autocmd = false,
    }

    local context_pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()

    local function region_text(ctx)
      return table.concat(vim.api.nvim_buf_get_lines(0, ctx.range.srow - 1, ctx.range.erow, false), '\n')
    end

    local function vue_block_at(ctx)
      local lines = vim.api.nvim_buf_get_lines(0, 0, ctx.range.srow, false)
      local block = nil

      for _, line in ipairs(lines) do
        if line:find('<template[%s>]', 1) then
          block = 'template'
        elseif line:find('</template>', 1, true) then
          block = nil
        elseif line:find('<script[%s>]', 1) or line:find('<style[%s>]', 1) then
          block = line:find('<script[%s>]', 1) and 'script' or 'style'
        elseif line:find('</script>', 1, true) or line:find('</style>', 1, true) then
          block = nil
        end
      end

      return block
    end

    local function jsx_commentstring(ctx)
      if vim.bo.filetype ~= 'javascriptreact' and vim.bo.filetype ~= 'typescriptreact' then
        return nil
      end

      local text = region_text(ctx)
      local has_jsx_tag = text:find('</?[%w_.:-]+') or text:find('<>') or text:find('</>')
      local is_inside_jsx = _G.ReactJsxEnclosingFoldStart and _G.ReactJsxEnclosingFoldStart() ~= nil

      if has_jsx_tag or is_inside_jsx then
        return '{/* %s */}'
      end

      return nil
    end

    local function vue_commentstring(ctx)
      if vim.bo.filetype ~= 'vue' then
        return nil
      end

      local text = region_text(ctx)
      local block = vue_block_at(ctx)
      if block == 'template' or text:find('</?[%w_.:-]+') then
        return '<!-- %s -->'
      elseif block == 'script' then
        return '// %s'
      elseif block == 'style' then
        return '/* %s */'
      end

      return nil
    end

    require('Comment').setup {
      pre_hook = function(ctx)
        local fallback = jsx_commentstring(ctx) or vue_commentstring(ctx)
        local commentstring = context_pre_hook(ctx)

        if fallback and (not commentstring or commentstring == '// %s' or vim.bo.filetype == 'vue') then
          return fallback
        end

        return commentstring or fallback
      end,
    }

    local opts = { noremap = true, silent = true }
    vim.keymap.set('n', '<C-_>', require('Comment.api').toggle.linewise.current, opts)
    vim.keymap.set('n', '<C-c>', require('Comment.api').toggle.linewise.current, opts)
    vim.keymap.set('n', '<C-/>', require('Comment.api').toggle.linewise.current, opts)
    vim.keymap.set('v', '<C-_>', "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", opts)
    vim.keymap.set('v', '<C-c>', "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", opts)
    vim.keymap.set('v', '<C-/>', "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", opts)
  end,
}
