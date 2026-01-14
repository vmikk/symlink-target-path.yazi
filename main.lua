--- @since 26.1.4

-- Function to normalize file path
local function normalize_path(path)
	if not path or path == "" then
		return path
	end

	local is_abs = path:sub(1, 1) == "/"
	local parts = {}

	for part in path:gmatch("[^/]+") do
		if part == "." or part == "" then
			-- skip
		elseif part == ".." then
			if #parts > 0 and parts[#parts] ~= ".." then
				table.remove(parts)
			elseif not is_abs then
				table.insert(parts, "..")
			end
			-- Absolute paths clamp at root when ".." would go above it.
		else
			table.insert(parts, part)
		end
	end

	local normalized = table.concat(parts, "/")
	if is_abs then
		normalized = "/" .. normalized
	end

	if normalized == "" then
		return is_abs and "/" or "."
	end

	return normalized
end

local collect_paths = ya.sync(function()
	local selected = cx.active.selected
	local current = cx.active.current
	local paths = {}

	if not current then
		return paths
	end

	local files = current.files
	local by_url = {}
	for i = 1, #files do
		local f = files[i]
		if f then
			by_url[tostring(f.url)] = f
		end
	end

	for _, url in pairs(selected) do
		-- Local-only for now (skip archives, search results, and VFSs)
		if url.is_archive or url.domain ~= nil then
			goto continue
		end

		local file = by_url[tostring(url)]
		if not file then
			goto continue
		end

		-- Get the path to copy
		local target_path
		if file.link_to then
			-- This is a symlink - get the target path
			target_path = file.link_to

			-- Resolve relative targets against the symlink's parent directory
			-- TODO: Allow users to keep relative paths in the future
			if not target_path.is_absolute then
				local parent = file.url.path.parent
				if parent then
					target_path = parent:join(target_path)
				end
			end
		else
			-- This is a regular file - just get the path
			target_path = file.url.path
		end

		local normalized = normalize_path(tostring(target_path))
		table.insert(paths, normalized)

		::continue::
	end

	return paths
end)

return {
	entry = function()
		local paths = collect_paths()
		if #paths > 0 then
			ya.clipboard(table.concat(paths, "\n"))
			return
		end

		ya.notify {
			title = "Copy Path",
			content = "No valid files selected",
			level = "warn",
			timeout = 3,
		}
	end,
}
