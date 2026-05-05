return {
  'windwp/nvim-ts-autotag',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    require('nvim-ts-autotag').setup({
      opts = {
        enable_close = true,           -- Auto close tags
        enable_rename = true,          -- Auto rename pairs of tags
        enable_close_on_slash = false, -- Auto close on trailing </
      },
    })

    local html_tags = {
      div=true, span=true, p=true, h1=true, h2=true, h3=true, h4=true, h5=true, h6=true,
      a=true, abbr=true, address=true, article=true, aside=true, audio=true,
      b=true, blockquote=true, button=true, canvas=true, caption=true,
      cite=true, code=true, colgroup=true, dd=true, del=true, details=true,
      dfn=true, dialog=true, dl=true, dt=true, em=true, fieldset=true,
      figcaption=true, figure=true, footer=true, form=true, header=true,
      i=true, ins=true, kbd=true, label=true, legend=true, li=true,
      main=true, mark=true, menu=true, meter=true, nav=true, noscript=true,
      object=true, ol=true, optgroup=true, option=true, output=true,
      picture=true, pre=true, progress=true, q=true, ruby=true, s=true,
      samp=true, section=true, select=true, small=true, strong=true,
      sub=true, summary=true, sup=true, table=true, tbody=true, td=true,
      template=true, textarea=true, tfoot=true, th=true, thead=true,
      time=true, tr=true, u=true, ul=true, video=true, svg=true,
    }

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'html', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'svelte', 'vue', 'xml' },
      callback = function()
        vim.keymap.set('i', '<CR>', function()
          local cmp_ok, cmp = pcall(require, 'cmp')
          if cmp_ok and cmp.visible() and cmp.get_selected_entry() then
            cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
            return
          end

          local line = vim.api.nvim_get_current_line()
          local row = vim.api.nvim_win_get_cursor(0)[1]
          local col = vim.api.nvim_win_get_cursor(0)[2]
          local before = line:sub(1, col)
          local after = line:sub(col + 1)
          local indent = line:match('^(%s*)')
          local sw = vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or 2
          local extra = vim.bo.expandtab and string.rep(' ', sw) or '\t'
          local inner_indent = indent .. extra

          -- Expand bare tag name: div| → <div>\n  |\n</div>
          local tag = before:match('(%a[%w%-]*)$')
          local pre_char = tag and before:sub(#before - #tag, #before - #tag) or ''
          if tag and html_tags[tag] and pre_char ~= '<' then
            local prefix = before:sub(1, #before - #tag)
            local new_lines = {
              prefix .. '<' .. tag .. '>',
              inner_indent,
              indent .. '</' .. tag .. '>',
            }
            vim.cmd('stopinsert')
            vim.api.nvim_buf_set_lines(0, row - 1, row, false, new_lines)
            vim.api.nvim_win_set_cursor(0, { row + 1, #inner_indent })
            vim.schedule(function() vim.cmd('startinsert!') end)
            return
          end

          -- Expand between existing tags: <div>|</div>
          if before:match('>$') and after:match('^</') then
            local new_lines = { before, inner_indent, indent .. after }
            vim.cmd('stopinsert')
            vim.api.nvim_buf_set_lines(0, row - 1, row, false, new_lines)
            vim.api.nvim_win_set_cursor(0, { row + 1, #inner_indent })
            vim.schedule(function() vim.cmd('startinsert!') end)
            return
          end

          -- Default: feed a normal Enter (noremap to avoid recursion)
          local cr = vim.api.nvim_replace_termcodes('<CR>', true, true, true)
          vim.api.nvim_feedkeys(cr, 'n', false)
        end, { noremap = true, buffer = true })
      end,
    })
  end,
}
