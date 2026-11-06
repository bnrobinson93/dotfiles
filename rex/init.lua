local home = os.getenv("HOME")
local rex_cli = "/Users/brad.robinson/Library/Application Support/com.superlogical.rex/RexServer/Versions/1829/Rex Server.app/Contents/MacOS/rex"
local search_paths = home .. "/.config/search-paths.txt"
local legacy_labels = {
  [home .. "/.dotfiles"] = "dotfiles",
  [home .. "/Documents/code"] = "code",
  [home .. "/Documents/Vault"] = "vault",
}

local function open_search_path(path)
  local sessions, err = rex.call("session.attach_all", { event_scope = "session" })
  if err ~= nil then error(err, 0) end

  local short_path = path:gsub("^" .. home, "~")
  local session_id
  for _, session in ipairs(sessions.sessions or {}) do
    local blocks = rex.call("session.list_blocks", { session_id = session.session_id })
    for _, block in ipairs((blocks and blocks.blocks) or {}) do
      local process = rex.call("block.method", {
        session_id = session.session_id,
        block_id = block.block_id,
        method = "process",
      })
      if process and process.foreground and process.foreground.cwd == path then
        session_id = session.session_id
        break
      end
    end
    if session_id ~= nil then break end

    if session.label == path or session.label == short_path or session.label == legacy_labels[path] then
      session_id = session.session_id
      break
    end
  end

  if session_id == nil then
    local created
    created, err = rex.call("session.create", {
      label = path,
      initial_windows = {
        {
          window_label = "shell",
          layout = rex.layout.block{
            flavor = "com.superlogical.terminal.shell",
            options = { cwd = path },
          },
        },
      },
    })
    if err ~= nil then error(err, 0) end
    session_id = created.session_id
  end

  rex.client.queue("session.select", { session_id = session_id })
  return { session_id = session_id, path = path }
end

rex.action{
  name = "open_search_path",
  title = "Open Folder Session",
  args = { path = "string" },
  run = function(_, args)
    return open_search_path(args.path)
  end,
}

local picker_script = [[
set -e
selected="$({
  while IFS= read -r root || [ -n "$root" ]; do
    case "$root" in
      ""|\#*) continue ;;
      "~") root="$HOME" ;;
      "~/"*) root="$HOME/${root#\~/}" ;;
    esac
    [ -d "$root" ] || continue
    printf '%s\n' "$root"
    /usr/bin/find "$root" -mindepth 1 -maxdepth 1 -type d \
      ! -name .git ! -name .jj ! -name node_modules -print
  done < "]] .. search_paths .. [["
} | sort -u | sed "s#^$HOME#~#" | fzf \
  --height=100% --layout=reverse --border --prompt='Open folder> ')" || exit 0
[ -n "$selected" ] || exit 0
selected="${selected/#\~/$HOME}"
exec "]] .. rex_cli .. [[" do open_search_path "path=$selected"
]]

rex.action{
  name = "search_sessions",
  title = "Find or Open Folder Session",
  description = "Fuzzy-find folders from ~/.config/search-paths.txt and reuse or create a Rex session.",
  keywords = "folder directory project session fuzzy search",
  run = function(ctx)
    local _, err = rex.session.new_layer{
      session_id = ctx.session_id,
      bounds = { 0.1, 0.1, 0.8, 0.8 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        options = {
          command = { "/bin/zsh", "-lc", picker_script },
          shell = "none",
        },
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}

rex.action{
  name = "preferred_dotfiles",
  title = "Open Dotfiles Session",
  run = function()
    return open_search_path(home .. "/.dotfiles")
  end,
}

rex.action{
  name = "preferred_code",
  title = "Open Code Session",
  run = function()
    return open_search_path(home .. "/Documents/code")
  end,
}

rex.action{
  name = "preferred_vault",
  title = "Open Vault Session",
  run = function()
    return open_search_path(home .. "/Documents/Vault")
  end,
}

rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })
rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+a>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+a>shift+'", "pane.split", { direction = "down" })
rex.bind("ctrl+a>shift+\\", "pane.split", { direction = "right" })
rex.bind("ctrl+a>-", "pane.split", { direction = "down" })
rex.bind("ctrl+a>r", "client.config.reload")
rex.bind("ctrl+a>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+a>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+a>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+a>l", "pane.focus", { direction = "right" })
rex.bind("ctrl+a>m", "session.switch")
rex.bind("ctrl+a>shift+m", "session.switch")

rex.bind("ctrl+f", "search_sessions")

rex.mode("repeat", { exclusive = true })
rex.bind("ctrl+a>ctrl+r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")

rex.bind("ctrl+a>shift+d", "preferred_dotfiles")
rex.bind("repeat/shift+d", "preferred_dotfiles")
rex.bind("ctrl+a>shift+c", "preferred_code")
rex.bind("repeat/shift+c", "preferred_code")
rex.bind("ctrl+a>shift+v", "preferred_vault")
rex.bind("repeat/shift+v", "preferred_vault")
rex.bind("ctrl+a>shift+l", "session.previous")

rex.bind("ctrl+b>ctrl+d", "preferred_dotfiles")
rex.bind("ctrl+b>ctrl+c", "preferred_code")
rex.bind("ctrl+b>ctrl+v", "preferred_vault")
rex.bind("ctrl+b>shift+l", "session.previous")
rex.bind("ctrl+b>shift+\\", "pane.split", { direction = "right" })
rex.bind("ctrl+b>-", "pane.split", { direction = "down" })
rex.bind("ctrl+b>ctrl+n", "session.next")
rex.bind("ctrl+b>ctrl+p", "session.previous")

rex.bind("shift+insert", "pane.paste")
rex.bind("ctrl+insert", "pane.copy")
rex.bind("ctrl+shift+w", "pane.close")

rex.bind("cmd+k", "com.superlogical.terminal.clear")
rex.bind("cmd+p", "session.switch")
