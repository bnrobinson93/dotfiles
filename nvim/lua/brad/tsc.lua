return {
  'dmmulroy/tsc.nvim',
  ft = { 'typescript', 'typescriptreact', 'react', 'typescriptreact', 'javascript', 'javascriptreact' },
  cond = function()
    return not vim.g.vscode
  end,
  cmd = 'TSC',
  opts = {
    use_trouble_qflist = true,
    auto_start_watch_mode = true,
    use_diagnostics = false, -- not using a tree plugin
    hide_progress_notifications_from_history = true,
    pretty_errors = true,
    run_as_monorepo = true,
    flags = '-b --noEmit',
    err_buffered = true,
    on_stderr = function(_, data)
      vim.notify(vim.inspect(data))
    end,
  },
}
