# symlink-target-path.yazi

A [Yazi](https://github.com/sxyazi/yazihttps://yazi-rs.github.io/) plugin that copies the resolved target path of symlinks.


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


## Current limitations

- **Virtual filesystems**: The plugin currently works only with local files. SFTP and other virtual filesystems are not supported yet  
- **Relative path option**: Currently, the plugin always resolves relative paths to absolute. A future version could allow copying relative paths as-is  

## Test data

To test the plugin, you can create the following dummy files:

```bash
mkdir -p /tmp/yazi-copy-test
cd /tmp/yazi-copy-test

echo "Hello World"    > regular_file.txt
echo "Target content" > target_file.txt
mkdir target_dir
echo "Dir content" > target_dir/file_in_dir.txt

## Create different symlink types
ln -s /tmp/yazi-copy-test/target_file.txt abs_symlink.txt
ln -s target_file.txt rel_symlink.txt
ln -s nonexistent.txt broken_symlink.txt
ln -s target_dir dir_symlink
ln -s /very/long/path/to/a/non/exisiting/file/with/long/long/path/to/check/if/it/fits/in/the/info/line/of/yazi/non_existing_file.txt non_existing_symlink.txt

ls -la
```

Then, select multiple files using the spacebar and press the configured keybinding (e.g., `c` then `t`) to copy the resolved target paths to the clipboard.


