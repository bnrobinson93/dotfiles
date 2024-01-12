local status_ok, comment = pcall(require, 'Comment')
if not status_ok then
  vim.notify 'Unable to load nvim autopairs'
  return
end

local status_ok, utils = pcall(require, 'ts_context_commentstring.utils')
if not status_ok then
  vim.notify 'Unable to load nvim commentstring'
  return
end
local status_ok, internal = pcall(require, 'ts_context_commentstring.internal')
if not status_ok then
  vim.notify 'Unable to load nvim commentstring'
  return
end

comment.setup {
  pre_hook = function(ctx)
    local U = require 'Comment.utils'

    local location = nil
    if ctx.ctype == U.ctype.block then
      location = utils.get_cursor_location()
    elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
      location = utils.get_visual_start_location()
    end

    return internal.calculate_commentstring {
      key = ctx.ctype == U.ctype.line and '__default' or '__multiline',
      location = location,
    }
  end,
}