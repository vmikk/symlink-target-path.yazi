--- symlink-target-path plugin for yazi
--- @since 26.1.4
--- @description Copies the resolved target path of symlinks


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

local function readlink_target(path)
	if not path or path == "" then
		return nil
	end

	local output = Command("readlink"):arg({ "--", path }):output()
	if not output or not output.status or not output.status.success then
		return nil
	end

	local raw = tostring(output.stdout or "")
	raw = raw:gsub("[\r\n]+$", "")
	if raw == "" then
		return nil
	end

	return Path.os(raw)
end

local collect_entries = ya.sync(function(state)
	local selected = cx.active.selected
	local current = cx.active.current
	local normalize = state.normalize ~= false
	local skip_broken = state.skip_broken == true
	local entries = {}

	if not current then
		return {
			normalize = normalize,
			skip_broken = skip_broken,
			entries = entries,
		}
	end

	local files = current.files
	local by_url = {}
	for i = 1, #files do
		local f = files[i]
		if f then
			by_url[tostring(f.url)] = f
		end
	end

	local urls = {}
	-- If files are selected, use them
	for _, url in pairs(selected) do
		urls[#urls + 1] = url
	end
	-- If no files are selected, use the hovered file
	if #urls == 0 and current.hovered then
		urls[1] = current.hovered.url
	end

	for i = 1, #urls do
		local url = urls[i]
		-- Local-only for now (skip archives, search results, and VFSs)
		if url.is_archive or url.domain ~= nil then
			goto continue
		end

		local file = by_url[tostring(url)]
		if not file then
			goto continue
		end

		local entry = {
			url = file.url,
			link_to = file.link_to,
			parent = file.url.path.parent,
			is_symlink = file.link_to ~= nil,
			is_orphan = file.cha and file.cha.is_orphan or false,
		}
		entries[#entries + 1] = entry

		::continue::
	end

	return {
		normalize = normalize,
		skip_broken = skip_broken,
		entries = entries,
	}
end)

return {
	setup = function(state, opts)
		opts = opts or {}
		if opts.normalize == nil then
			state.normalize = true
		else
			state.normalize = opts.normalize and true or false
		end
		if opts.skip_broken == nil then
			state.skip_broken = false
		else
			state.skip_broken = opts.skip_broken and true or false
		end
	end,
	entry = function()
		local data = collect_entries()
		local entries = data.entries
		local paths = {}
		for i = 1, #entries do
			local entry = entries[i]
			if data.skip_broken and entry.is_symlink and entry.url then
				if entry.is_orphan == true then
					goto continue
				end
				local _, err = fs.cha(entry.url, true)
				if err then
					goto continue
				end
			end

			local target_path = entry.link_to
			if not target_path and entry.url then
				local cha = fs.cha(entry.url)
				if cha and cha.is_link then
					target_path = readlink_target(tostring(entry.url.path))
				end
			end

			if target_path then
				-- Resolve relative targets against the symlink's parent directory
				-- TODO: Allow users to keep relative paths in the future
				if not target_path.is_absolute then
					local parent = entry.parent or (entry.url and entry.url.path.parent)
					if parent then
						target_path = parent:join(target_path)
					end
				end
			else
				target_path = entry.url and entry.url.path or nil
			end

			local path_value = target_path and tostring(target_path) or nil
			if not path_value or path_value == "" then
				goto continue
			end
			if data.normalize then
				path_value = normalize_path(path_value)
			end
			paths[#paths + 1] = path_value
			::continue::
		end

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
