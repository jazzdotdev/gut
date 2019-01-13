require 'third-party/path_separator'
require 'third-party/sanitize'
require 'third-party/join'
require 'third-party/mklink'
require 'third-party/abs'

local execute = require"execute"
local escape = require"escape"

local Gut = {}
local gutdir = ".gut"
local omitfile = ".gutomit"

function Gut:new(dir)
	local dir, err = fs.abs(dir)
	if err then
		return err
	end
	
	local obj = {
		dir = dir,
		gutdir = fs.join(dir, gutdir)
	}
	
	self.__index = self
	return setmetatable(obj, self)
end

function Gut:isrepo()
	return fs.exists(self.gutdir)
end

function Gut:start()
	fs.create_dir(self.gutdir)
	fs.create_dir(fs.join(self.gutdir, "current"))
	fs.create_dir(fs.join(self.gutdir, "patches"))
	fs.touch(fs.join(self.gutdir, "series"))
	fs.touch(fs.join(self.gutdir, "index"))
	-- todo: check errors
end

function Gut:entries()
	local err = nil
	local entries = fs.entries(self.dir)
	if entries == nil then
		return nil, "failed to get directory entries"
	end

	return function()
		for filename in entries do
			if filename ~= gutdir then
				return filename
			end
		end
	end
end

function Gut:execute(cmd)
	return execute(escape{"cd", self.gutdir} .. " && " .. escape(cmd))
end

function Gut:executerepo(cmd)
	return execute(escape{"cd", self.dir} .. " && " .. escape(cmd))
end

function Gut:savecurrent()
	
	local current, err = fs.join(self.gutdir, "current")
	if err then
		return err
	end

	local currentnew = current .. ".new"
	local currentold = current .. ".old"

	fs.create_dir(currentnew, true)
	-- todo: check error

	local entries, err = self:entries()
	if err then
		return err
	end
	
	for filename in entries do
		local err = execute{
			"cp",
			"-R",
			fs.join(self.dir, filename),
			fs.join(currentnew, filename)
		}:run()
		if err then
			return err
		end
	end

	if fs.exists(current) then
		-- todo: racy code
		local ok, err = os.rename(current, currentold)
		if err then
			return err
		end
	end

	ok, err = os.rename(currentnew, current)
	if err then
		return err
	end
	
	return fs.remove_recursive(currentold)
end

function Gut:diff(file)
	local err = nil
	local adir = fs.join(self.gutdir, "a")
	local bdir = fs.join(self.gutdir, "b")

	if fs.exists(bdir) then
		-- todo: racy code
		err = fs.remove_recursive(bdir)
		if err then
			return err
		end
	end

	fs.create_dir(bdir)
	-- todo: check error

	local entries, err = self:entries()
	if err then
		return err
	end

	for filename in entries do
		err = fs.mklink(
			fs.join("../../", filename),
			fs.join(bdir, filename)
		)
		if err then
			return err
		end
	end

	if not fs.exists(adir) then
		err = fs.mklink("current", adir)
		if err then
			return err
		end
	end

	local cmd
	if fs.exists(fs.join(self.dir, omitfile)) then
		cmd = self:execute{"diff", "--text", "--color=auto", "-X", fs.join("..", omitfile), "-Nur", "a", "b"}
	else
		cmd = self:execute{"diff", "--text", "--color=auto", "-Nur", "a", "b"}
	end

	if file then
		return cmd:output(file)
	else
		cmd:run()
	end
end

function Gut:apply(filename)
	return self:executerepo{"patch", "-p1", "-i", filename}:run()
end

function Gut:series()
	local f, err = io.open(fs.join(self.gutdir, "series"), "r")
	if err then return nil, err end
	local series = {}
	for line in f:lines("l") do
		if line ~= "" then
			table.insert(series, line)
		end
	end
	f:close()
	return series
end

function Gut:saveseries(series)
	local f, err = io.open(fs.join(self.gutdir, "series"), "w")
	if err then return err end
	f, err = f:write(table.concat(series, "\n"))
	if err then return err end
	f:close()
end

function Gut:index()
	local f, err = io.open(fs.join(self.gutdir, "index"), "r")
	if err then return nil, err end
	local index, err = f:read("l")
	f:close()
	return index, err
end

function Gut:saveindex(index)
	local f, err = io.open(fs.join(self.gutdir, "index"), "w")
	if err then return err end
	local ok, err = f:write(index)
	f:close()
	return err
end

function Gut:pushseries()
	local series, err = self:series()
end

function Gut:patches()
	local entries = fs.entries(fs.join(self.gutdir, "patches"))
	if entries == nil then
		return nil, "failed to get directory entries"
	end
	return entries
end

function Gut:savepatch(filename)

	if not filename or filename == "" then
		return "empty filename"
	end
	
	local patches = fs.join(self.gutdir, "patches")
	local fullname = fs.join(patches, filename)
	
	if fs.exists(fullname) then
		return "patch with this name already exists"
	end
	
	local file, err = io.open(fullname, "w")
	if err then
		return err
	end
	
	local err = self:diff(file)
	if err then
		return err
	end

	file:close()

	local series, err = self:series(filename)
	if err then return err end

	local index, err = self:index(filename)
	if err then return err end

	local pos = 1
	for i, name in ipairs(series) do
		if name == index then
			pos = i + 1
			break
		end
	end

	table.insert(series, pos, filename)

	local seriesnew = {}
	for i = 1, pos do
		table.insert(seriesnew, series[i])
	end
	
	err = self:saveseries(seriesnew)
	if err then return err end

	err = self:saveindex(filename)
	if err then return err end
	
	err = self:savecurrent()
	if err then return err end
end

function Gut:revert(filename)
	return self:executerepo{"patch", "-R", "-p1", "-i", filename}:run()
end

function Gut:backward()

	local series, err = self:series(filename)
	if err then return err end
	
	local index, err = self:index(filename)
	if err then return err end

	local pos = 0
	for i, name in ipairs(series) do
		if name == index then
			pos = i
			break
		end
	end

	local filename = series[pos]
	index = series[pos - 1]
	if not index then
		index = ""
	end
	
	if not filename then
		return "nowhere to move"
	end

	filename = fs.join(self.gutdir, "patches", filename)
	err = self:revert(filename)
	if err then return err end

	err = self:saveindex(index)
	if err then return err end

	err = self:savecurrent()
	if err then return err end
end

function Gut:forward()
	local series, err = self:series(filename)
	if err then return err end
	
	local index, err = self:index(filename)
	if err then return err end

	local pos = 0
	for i, name in ipairs(series) do
		if name == index then
			pos = i
			break
		end
	end

	local filename = series[pos + 1]
	
	if not filename then
		return "nowhere to move"
	end
	
	index = filename

	filename = fs.join(self.gutdir, "patches", filename)
	err = self:apply(filename)
	if err then return err end

	err = self:saveindex(index)
	if err then return err end

	err = self:savecurrent()
	if err then return err end
end

return Gut
