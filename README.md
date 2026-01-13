# symlink-target-path.yazi
Plugin for yazi to copy target path of symlinked file
## Usage

After installing the plugin, add a keybinding to your `keymap.toml` configuration (e.g., to the "Copy" section of `~/.config/yazi/keymap.toml`):

```toml
	{ on = [ "c", "t" ], run = "plugin symlink-target-path", desc = "Copy symlink target paths" },
```
