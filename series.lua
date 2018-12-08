local Series = {}

local escape = require"escape"

function Series:new(dir)
	local obj = {
		dir = dir,
		series_file = ".series"
	}
	self.__index = self
	return setmetatable(obj, self)
end

-- get series
function Series:series()
	
	-- todo: handle absolute `self.series`
	local f, err, rc = io.open(self.dir .. "/" .. self.series_file, "r")
	if rc == 2 then
		-- todo: more reliable way to determine, that file doesn't exist
		return {};
	end
	if err then
		return nil, err
	end

	local series = {}
	for line in f:lines("l") do
		if line ~= "" then
			table.insert(series, line)
		end
	end
	
	f:close()

	return series
end

-- update series file
function Series:updateseries(series)
	local f, err = io.open(self.dir .. "/" .. self.series_file, "w")
	if err then
		return err
	end
	
	f, err = f:write(table.concat(series, "\n"))
	if err then
		return err
	end
	
	f, err = f:write("\n")
	if err then
		return err
	end
	
	f:close()
end

-- apply patch
function Series:push(filename)
	
	if string.sub(filename, 1, 1) ~= "/" then
		return "path to patch file must be absolute"
	end

	local series, err = self:series()
	if err then
		return err
	end

	table.insert(series, filename)
	
	local f, err = io.popen(escape{
		"patch",
		"-d", self.dir,
		"-i", filename
	})
	if err then
		return err
	end

	local out = f:read("a")
	local ok, reason, rc = f:close()
	if not ok then
		return "patch failed: " .. reason .. " " .. tostring(rc)
	end
	
	return self:updateseries(series)
end

-- revert latest patch
function Series:pop()

	local series, err = self:series()
	if err then
		return err
	end

	local filename = table.remove(series, #series)
	
	local f, err = io.popen(escape{
		"patch",
		"-d", self.dir,
		"-i", filename,
		"-R"
	})
	if err then
		return err
	end

	local out = f:read("a")
	local ok, reason, rc = f:close()

	if not ok then
		return "patch failed: " .. reason .. " " .. tostring(rc)
	end

	return self:updateseries(series)
end

return Series
