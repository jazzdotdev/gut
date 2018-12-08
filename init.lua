#!/usr/bin/env lua

local Series = require("series")
local series = Series:new("test")

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

local cmd = os.getenv("GUT_CMD")
local arg = os.getenv("GUT_ARG")

if type(actions[cmd]) ~= "function" then
	error("unknown command " .. tostring(cmd))
end

local err = actions[cmd](arg)
if err ~= nil then
	error(err)
end
