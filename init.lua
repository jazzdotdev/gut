local Gut = require("gut")

local pwd = os.getenv("GUT_PWD")
local cmd = os.getenv("GUT_CMD")
local arg = os.getenv("GUT_ARG")

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

	save = function()
		return gut:savecurrent()
	end,

	diff = function()
		return gut:diff()
	end,

	apply = function()
		return gut:apply()
	end
}

if type(commands[cmd]) ~= "function" then
	die([[usage:
  gut start
  gut diff]])
end

if cmd ~= "start" and not gut:isrepo() then
	die("not a gut repo")
end

local err = commands[cmd](arg)
if err ~= nil then
	die(err)
end
