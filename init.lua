#!/usr/bin/env torchbear

require 'third-party/path_separator'
require 'third-party/sanitize'
require 'third-party/join'
require 'third-party/mklink'
require 'third-party/abs'
require 'third-party/remove_recursive'
require 'third-party/basename'

local repo = require 'repo'

_G.die = function (msg)
	io.stderr:write(msg)
	if string.sub(msg, #msg) ~= "\n" then
		io.stderr:write("\n")
	end
	os.exit(1)
end

local function usage(f)
	f = f or io.stderr
	f:write(
		'usage:\n',
		string.format('  %s diff\n', argv0),
		string.format('  %s help\n', argv0)
		string.format('  %s patch\n', argv0),
		string.format('  %s start\n', argv0),
		string.format('  %s status\n', argv0),
	)
	os.exit(f ~= io.stderr)
end

_G.argv0 = fs.basename(table.remove(arg, 1))
local name = table.remove(arg, 1)
local command = ({

	diff =   require 'command/diff',
	save =   require 'command/patch',
	start =  require 'command/start',
	status = require 'command/status',

	help = function(arg)
		if #arg ~= 0 then
			usage(io.stderr)
		else
			usage(io.stdout)
		end
		return
	end

})[name]

if not command then
	usage()
	return
end

local err = command(arg)
if err then
	die(err)
end
