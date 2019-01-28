--[[

polyfills for missing bindings

--]]

local execute = require"execute"

local path_separator = "/"

function fs.remove_recursive(dir)
	return execute{"rm", "-rf", dir}:run()
end

function fs.join(...)
	local chunks = {...}
	if #chunks > 1 then
		for i = #chunks, 1, -1 do
			if chunks[i] == "." then
				table.remove(chunks, i)
			end
		end
	end
	return table.concat(chunks, path_separator)
end

function fs.abs(...)
	local err = nil
	local path = fs.join(...)
	local abspath = fs.canonicalize(path)
	if abspath == nil then
		err = "can't get absolute path of " .. path
	end
	return abspath, err
end

function fs.mklink(src, dest)
	return execute{"ln", "-s", src, dest}:run()
end

function fs.touch(filename)
	return execute{"touch", filename}:run()
end

function fs.mkdir(path, all)
	if not fs.create_dir(path, all or false) then
		return "failed to create directory"
	end
	return nil
end
