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

    local function pattern_escape(text)
      return text:gsub('([^%w])', '%%%1')
    end

    local function commentstring_delimiters(commentstring)
      if not commentstring or commentstring == '' then
        return nil
      end

      local left, right = commentstring:match '^(.*)%%s(.*)$'
      if not left or not right then
        return nil
      end

      left = vim.trim(left)
      right = vim.trim(right)

      if left == '' or right == '' or left:find '\n' or right:find '\n' then
        return nil
      end

      return left, right
    end

    local function visual_range(line1, line2)
      local cursor_line = line1 or vim.fn.line '.'
      local anchor_line = line2 or vim.fn.line 'v'
      local start_line = math.min(cursor_line, anchor_line)
      local end_line = math.max(cursor_line, anchor_line)
      local last_line = vim.api.nvim_buf_get_lines(0, end_line - 1, end_line, false)[1] or ''

      return {
        srow = start_line,
        scol = 0,
        erow = end_line,
        ecol = #last_line,
      }
    end

    local function block_comment_delimiters(range)
      local delimiters = {}
      local comment_ctx = { range = range }

      local function add(commentstring)
        local left, right = commentstring_delimiters(commentstring)
        if left and right then
          table.insert(delimiters, { left, right })
        end
      end

      add(jsx_commentstring(comment_ctx))

      if vim.bo.filetype == 'vue' then
        local block = vue_block_at(comment_ctx)
        local text = region_text(comment_ctx)
        if block == 'template' or text:find('</?[%w_.:-]+') then
          add '<!-- %s -->'
          add '/* %s */'
        elseif block == 'script' or block == 'style' then
          add '/* %s */'
          add '<!-- %s -->'
        else
          add '<!-- %s -->'
          add '/* %s */'
        end
      elseif vim.bo.filetype == 'javascriptreact' or vim.bo.filetype == 'typescriptreact' then
        add '{/* %s */}'
      else
        local ok_utils, utils = pcall(require, 'Comment.utils')
        local ok_ft, ft = pcall(require, 'Comment.ft')
        if ok_utils and ok_ft then
          add(ft.get(vim.bo.filetype, utils.ctype.blockwise))
        end
      end
      add(vim.bo.commentstring)

      return delimiters
    end

    local function selected_lines(range)
      local start_line = range.srow
      local end_line = range.erow
      local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

      if #lines == 0 then
        return nil
      end

      local first_text_line, last_text_line
      for index, line in ipairs(lines) do
        if line:find '%S' then
          first_text_line = first_text_line or index
          last_text_line = index
        end
      end

      if not first_text_line or not last_text_line then
        return nil
      end

      return lines, first_text_line, last_text_line
    end

    local function line_comment_prefix()
      local commentstring = vim.bo.commentstring
      local left, right = commentstring and commentstring:match '^(.*)%%s(.*)$'

      if not left then
        return nil
      end

      left = vim.trim(left)
      right = vim.trim(right or '')

      if left == '' or right ~= '' then
        return nil
      end

      return left
    end

    local function uncomment_visual_block(range)
      local lines, first_text_line, last_text_line = selected_lines(range)

      if not lines then
        return false
      end

      if
        (vim.bo.filetype == 'javascriptreact' or vim.bo.filetype == 'typescriptreact')
        and first_text_line + 1 < last_text_line
        and lines[first_text_line]:find '^%s*{%s*$'
        and lines[first_text_line + 1]:find '^%s*/%*'
        and lines[last_text_line - 1]:find '%*/%s*$'
        and lines[last_text_line]:find '^%s*}%s*$'
      then
        table.remove(lines, last_text_line)
        table.remove(lines, first_text_line)
        lines[first_text_line] = lines[first_text_line]:gsub('^%s*/%*%s?', '', 1)
        lines[last_text_line - 2] = lines[last_text_line - 2]:gsub('%s?%*/%s*$', '', 1)

        vim.api.nvim_buf_set_lines(0, range.srow - 1, range.erow, false, lines)
        return true
      end

      for _, delimiter in ipairs(block_comment_delimiters(range)) do
        local left, right = delimiter[1], delimiter[2]
        local left_pattern = pattern_escape(left)
        local right_pattern = pattern_escape(right)

        if
          lines[first_text_line]:find('^%s*' .. left_pattern)
          and lines[last_text_line]:find(right_pattern .. '%s*$')
        then
          lines[first_text_line] = lines[first_text_line]:gsub('^(%s*)' .. left_pattern .. '%s?', '%1', 1)
          lines[last_text_line] = lines[last_text_line]:gsub('%s?' .. right_pattern .. '%s*$', '', 1)

          vim.api.nvim_buf_set_lines(0, range.srow - 1, range.erow, false, lines)
          return true
        end
      end

      return false
    end

    local function comment_visual_block(range)
      local lines, first_text_line, last_text_line = selected_lines(range)
      local delimiter = block_comment_delimiters(range)[1]

      if not lines or not delimiter then
        return false
      end

      local left, right = delimiter[1], delimiter[2]
      lines[first_text_line] = lines[first_text_line]:gsub('^(%s*)', '%1' .. left .. ' ', 1)
      lines[last_text_line] = lines[last_text_line]:gsub('%s*$', ' ' .. right, 1)

      vim.api.nvim_buf_set_lines(0, range.srow - 1, range.erow, false, lines)
      return true
    end

    local function toggle_visual_linewise(range)
      local lines, first_text_line = selected_lines(range)
      local prefix = line_comment_prefix()

      if not lines or not prefix then
        return false
      end

      local prefix_pattern = pattern_escape(prefix)
      local should_uncomment = true
      for index, line in ipairs(lines) do
        if line:find '%S' and not line:find('^%s*' .. prefix_pattern) then
          should_uncomment = false
          break
        end
      end

      for index, line in ipairs(lines) do
        if line:find '%S' then
          if should_uncomment then
            lines[index] = line:gsub('^(%s*)' .. prefix_pattern .. '%s?', '%1', 1)
          else
            lines[index] = line:gsub('^(%s*)', '%1' .. prefix .. ' ', 1)
          end
        end
      end

      vim.api.nvim_buf_set_lines(0, range.srow - 1, range.erow, false, lines)
      return first_text_line ~= nil
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

    _G.DotfilesToggleVisualComment = function(line1, line2)
      local range = visual_range(line1, line2)

      if uncomment_visual_block(range) then
        return
      end

      if comment_visual_block(range) then
        return
      end

      toggle_visual_linewise(range)
    end

    vim.api.nvim_create_user_command('DotfilesToggleVisualComment', function(command)
      _G.DotfilesToggleVisualComment(command.line1, command.line2)
    end, { range = true })

    local opts = { noremap = true, silent = true }
    vim.keymap.set('n', '<C-_>', require('Comment.api').toggle.linewise.current, opts)
    vim.keymap.set('n', '<C-c>', require('Comment.api').toggle.linewise.current, opts)
    vim.keymap.set('n', '<C-/>', require('Comment.api').toggle.linewise.current, opts)
    vim.keymap.set('v', '<C-_>', "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", opts)
    vim.keymap.set('v', '<C-c>', "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", opts)
    vim.keymap.set('v', '<C-/>', "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", opts)
    vim.keymap.set('x', 'gc', ':DotfilesToggleVisualComment<cr>', opts)
  end,
}
