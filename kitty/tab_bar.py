# Custom kitty tab bar: tmux-style session name label at the left, then the
# normal powerline tabs. active_session_name is provided per-tab by kitty.
# Loaded only when `tab_bar_style custom` is set in kitty.conf.

import re

from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_tab_with_powerline,
)
from kitty.fast_data_types import Screen
from kitty.rgb import color_as_int

# Catppuccin Mocha
MAUVE = 0xCBA6F7
BASE = 0x1E1E2E

# Trailing -<6hexhash> appended by kitty-session-gen for path dedup; hide it.
HASH_RE = re.compile(r"-[0-9a-f]{6}$")

# Rounded powerline caps -> "pill" shape (like tmux), so the label nests inside
# the window's rounded corner instead of a sharp rect clipping at it.
LEFT_CAP = ""  # U+E0B6 left half-circle
RIGHT_CAP = ""  # U+E0B4 right half-circle


def draw_session_label(draw_data: DrawData, screen: Screen, session: str) -> None:
    name = HASH_RE.sub("", session) if session else "~"
    default_bg = as_rgb(color_as_int(draw_data.default_bg))
    mauve = as_rgb(MAUVE)
    # small left margin on default bg so the pill doesn't sit in the very corner
    screen.cursor.fg = 0
    screen.cursor.bg = 0
    screen.draw(" ")
    # left rounded cap
    screen.cursor.fg = mauve
    screen.cursor.bg = default_bg
    screen.draw(LEFT_CAP)
    # pill body
    screen.cursor.fg = as_rgb(BASE)
    screen.cursor.bg = mauve
    screen.draw(f"󰆍 {name}")
    # right rounded cap
    screen.cursor.fg = mauve
    screen.cursor.bg = default_bg
    screen.draw(RIGHT_CAP)
    # reset to tab bar defaults, then a gap before the first tab
    screen.cursor.fg = 0
    screen.cursor.bg = 0
    screen.draw(" ")


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    if index == 1:
        draw_session_label(draw_data, screen, tab.active_session_name)
    return draw_tab_with_powerline(
        draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
    )
