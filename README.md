# symlink-target-path.yazi
Plugin for yazi to copy target path of symlinked file

## Installation

Install the plugin using the `ya` package manager:

```bash
ya pkg add vmikk/symlink-target-path
```

## Usage

After installing the plugin, add a keybinding to your `keymap.toml` configuration (e.g., to the "Copy" section of `~/.config/yazi/keymap.toml`):

```toml
	{ on = [ "c", "t" ], run = "plugin symlink-target-path", desc = "Copy symlink target paths" },
```

## Configuration

For extra plugin configuration, you may add the following to `~/.config/yazi/init.lua`:

```lua
require("symlink-target-path"):setup {
	-- Normalize paths by removing "." and ".." segments.
	-- Set to false to keep the raw resolved path.
	normalize = true,

	-- Skip broken symlinks (those whose targets do not exist).
	-- Default is false.
	skip_broken = false,
}
```

