# Palette

Blackshield, mapped onto Omarchy's `colors.toml` keys.

| Role | Hex | Source |
|---|---|---|
| background | `#101014` | iron |
| darker_background | `#070709` | void |
| lighter_background | `#1A1A20` | window alternate |
| foreground | `#D8D3C8` | parchment |
| bright_foreground | `#F5F1E8` | bright white |
| muted / dark_foreground | `#8A8F98` | inactive text |
| accent / red | `#C1121F` | blood, decoration focus |
| bright_red / orange | `#E5383B` | ember |
| yellow | `#C9A227` | brass |
| green | `#6A994E` | olive |
| cyan | `#4E8F8B` | verdigris |
| blue | `#5B7FA6` | steel blue |
| magenta | `#A4508B` | plum (visited link). Dark blood reads as a second red; plum does not |

`selection` is `#3A1518`, a blood-tinted iron, not full blood. Omarchy paints selected text in `bright_foreground` on `selection`. Full blood as the selection stop is loud in menus.

Active border is solid `rgba(c1121fee)`. Inactive is steel at low alpha. No gradient.

Lock surface (`shell.lock.toml`) is a full `[lock]` replacement: iron plate, parchment text, steel placeholder, blood active border. A partial lock file strips `background` and `border-active`. `shell.toml` is hand-authored chrome (bar, menus, notifications). Theme apply copies it as-is. Do not put those colors in `~/.config/omarchy/shell.toml` — that file is the machine override and survives theme switches.
