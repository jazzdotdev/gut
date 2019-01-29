local function stringlines(str)
	local init = 1
	return function()

		if init >= #str then
			return nil
		end
		
		local starts, ends = string.find(str, "\n", init, true)
		if not starts then
			local sub = string.sub(str, init)
			init = #str
			return sub
		else
			local sub = string.sub(str, init, ends - 1)
			init = ends + 1
			return sub
		end
	end
end

--[[
diffsplit function splits multiple concatenated diff messages
and returns iterator over them.
--]]

local function diffsplit(data)

	local lines
	if type(data) == "string" then
		lines = stringlines(data)
	else
		lines = data:lines("l")
	end
	
	local savedline = nil
	return function()
		local filename = nil
		local old = nil
		local new = nil
		local inserted = 0
		local removed = 0
		local comments = {}
		local body = {}
		
		local state = "oldfile"
		local line = savedline or lines()
		
		if not line then
			return
		end
		
		savedline = nil
		while line do
			if state == "oldfile" then
				old = string.match(line, "^--- (%S+)")
				if old then
					state = "newfile"
				else
					table.insert(comments, line)
				end
			elseif state == "newfile" then
				new = string.match(line, "^+++ (%S+)")
				if not new then
					die("error")
				end
				state = "body"
			elseif state == "body" then
				local c = string.sub(line, 1, 1)
				if c == "@" or c == "-" or c == "+" or c == " " then
					if c == "+" then
						inserted = inserted + 1
						table.insert(body, line)
					end
					if c == "-" then
						removed = removed + 1
						table.insert(body, line)
					end
				else
					savedline = line
					break
				end
			end

			line = lines()
		end
		
		if state ~= "body" then
			die("error")
		end

		if new ~= '/dev/null' then
			filename = new
		else
			filename = old
		end
		
		return {
			filename = filename,
			old = old,
			new = new,
			inserted = inserted,
			removed = removed,
			comments = comments,
			body = body
		}
	end
end

return diffsplit
