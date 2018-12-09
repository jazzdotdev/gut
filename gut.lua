require"extras"
local execute = require"execute"
local escape = require"escape"

local Gut = {}
local gutdir = ".gut"

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
	-- todo: check error
	fs.create_dir(fs.join(self.gutdir, "current"))
	-- todo: check error
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
	return execute{
		"sh",
		"-c",
		escape{"cd", self.gutdir} .. " && " .. escape(cmd)
	}
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
		}
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

function Gut:diff()
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

	self:execute{"diff", "--color=auto", "-Nur", "a", "b"}
end

function Gut:apply()
	return self:execute{"patch", "-p1"}
end

return Gut
