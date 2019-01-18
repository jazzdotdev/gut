#!/usr/bin/env torchbear
local Gut = require("gut")

-- discarding
table.remove(arg, 1)

local pwd = fs.current_dir()
local cmd = table.remove(arg, 1)
local arg = table.remove(arg, 1) 

local function die(msg)
	io.stderr:write(msg)
	if string.sub(msg, #msg) ~= "\n" then
		io.stderr:write("\n")
	end
	os.exit(1)
end

local gut, err = Gut:new(pwd)
if err then
	die(err)
end

local commands = {
	
	start = function()
		return gut:start()
	end,

	save = function(arg)
		return gut:savepatch(arg)
	end,

	diff = function()
		return gut:diff()
	end,

	patches = function()
		-- list patches
		local patches, err = gut:patches()
		if err then return err end
		
		for filename in patches do
			print(filename)
		end
	end,

	series = function()
		-- list series of patches
		local series, err = gut:series()
		if err then return err end
		local index, err = gut:index()
		if err then return err end

		for i, filename in ipairs(series) do
			if filename == index then
				print(filename .. " (index)")
			else
				print(filename)
			end
		end
	end,

	backward = function()
		return gut:backward()
	end,

	forward = function()
		return gut:forward()
	end,

	check = function()
		return gut:check()
	end,
}

if type(commands[cmd]) ~= "function" then
	die([[usage:
  gut start
  gut save
  gut diff
  gut patches
  gut series
  gut backward
  gut forward
  gut check]])
end

if cmd ~= "start" and not gut:isrepo() then
	die("not a gut repo")
end

local err = commands[cmd](arg)
if err ~= nil then
	die(err)
end

