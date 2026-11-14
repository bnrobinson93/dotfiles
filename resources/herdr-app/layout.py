"""Write layouts/main-jj.json: Herdr's shipped main layout with the jj-aware mods swapped in.

Built from main each run, so it follows Herdr's updates to main. A theme picked on main-jj
(the theme menu writes the shown layout's root) is carried over.
"""

import json
import sys

home = sys.argv[1]
src, dest = f"{home}/layouts/main.json", f"{home}/layouts/main-jj.json"

# Block content by the shipped mod it replaces. The spaces block shows spaces and agents
# under two tabs, so the separate agents block goes.
SWAP = {
    "spaces": {"mod": "better-sidebar", "props": {"view": "lists"}},
    "files": {"mod": "better-files"},
    "changes": {"mod": "better-changes"},
    "workspace-status": {"mod": "jj-status"},
}


def rewrite(node):
    mod = node.get("content", {}).get("mod")
    if node.get("type") == "block" and mod in SWAP:
        node["content"] = SWAP[mod]
    children = node.get("children")
    if children:
        node["children"] = [
            rewrite(c) for c in children if c.get("content", {}).get("mod") != "agents"
        ]
    return node


layout = rewrite(json.load(open(src)))
try:
    theme = json.load(open(dest)).get("theme")
    if theme:
        layout["theme"] = theme
except FileNotFoundError:
    pass
json.dump(layout, open(dest, "w"), indent=2)
print(f"wrote {dest}")
