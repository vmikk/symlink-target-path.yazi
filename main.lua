--- @since 26.1.4

local M = {}

function M:entry()
	local selected = cx.active.selected
	local paths = {}

	-- Process each selected file
	for _, url in ipairs(selected) do
		-- Find the corresponding file object in the current folder
		local file = nil
		for _, f in ipairs(cx.active.current.files) do
			if f.url == url then
				file = f
				break
			end
		end

		-- Skip if file not found in current folder
		if not file then
			goto continue
		end

		-- Get the path to copy
		local target_path
		if file.link_to then
			-- This is a symlink - get the target path
			target_path = file.link_to

			-- Resolve relative symlink targets to absolute paths
			-- TODO: In the future, allow users to choose whether to resolve to absolute or keep relative
			if not target_path.is_absolute then
				local parent = file.url.parent()
				if parent then
					target_path = parent:join(target_path)
				end
			end
		else
			-- This is a regular file - use its own path
			target_path = file.url
		end
		-- Convert to string and add to results
		table.insert(paths, tostring(target_path))

		::continue::
	end

	-- Copy to clipboard if we found any files to process
	if #paths > 0 then
		local clipboard_content = table.concat(paths, "\n")
		ya.clipboard(clipboard_content)
	else
		-- No files were processed (all selected files were virtual files)
		ya.notify {
			title = "Copy Path",
			content = "No valid files selected",
			level = "warn",
			timeout = 3
		}
	end
end

return M
