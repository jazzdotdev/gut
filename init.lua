local Series = require("series")


local pwd = os.getenv("GUT_PWD")
local cmd = os.getenv("GUT_CMD")
local arg = os.getenv("GUT_ARG")


local series = Series:new(pwd)

local actions = {

	init = function() end,

	status = function() end,

	series = function()
		local series, err = series:series()
		if err ~= nil then
			return err
		end

		for i, filename in ipairs(series) do
			print(filename)
		end
	end,
	
	push = function(arg)
		return series:push(arg)
	end,
	
	pop = function(arg)
		return series:pop(arg)
	end
}

if type(actions[cmd]) ~= "function" then
	error("unknown command " .. tostring(cmd))
end

local err = actions[cmd](arg)
if err ~= nil then
	error(err)
end
