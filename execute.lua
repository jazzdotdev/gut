local escape = require"escape"

local Command = {}

function Command:new(cmd)
	if type(cmd) ~= "string" then
		cmd = escape(cmd)
	end
	
	local obj = {
		cmd = cmd
	}
	
	self.__index = self
	return setmetatable(obj, self)
end

function Command:run()
	local err = nil
	local ok, reason, rc = os.execute(self.cmd)
	if not ok then
		err = reason .. " " .. rc
	end
	return err, reason, rc
end

function Command:output(file)
	local err = nil
	local cmd, reason, rc = io.popen(self.cmd, "r")
	if not cmd then
		err = reason .. " " .. rc
	end

	repeat
		local str = cmd:read(1024)
		if str ~= nil then
			local ok, err = file:write(str)
			if err then
				return err
			end
		end
	until str == nil
	
	return err, reason, rc
end

return function(cmd)
	return Command:new(cmd)
end