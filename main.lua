require"extras"
local repo = require"repo"

_G.die = function(str)
	io.stderr:write(str, "\n")
	os.exit(1)
end

-- todo: fs: add `basename` function
local argv0 = string.match(table.remove(arg, 1), "[^/\\]+$")

local function usage(f)
	f = f or io.stderr
	f:write(
		string.format('usage: %s help\n', argv0)
	)
	os.exit(f ~= io.stderr)
end

local cmd = table.remove(arg, 1) or "usage"
if #arg ~= 0 then
	usage()
end

local err = (({
	start = function()
		if repo:isrepo() then
			die("already in a gut repo")
		end

		return repo:create()
	end,

	status = function()
		local err = repo:init()
		if err then
			return err
		end
		
		local diffs = repo:diff(repo.root, repo.snapshot, ".")
		repo:shortdiff(diffs)
	end,

	diff = function()
		local err = repo:init()
		if err then
			return err
		end

		repo:diff(repo.root, repo.snapshot, ".")
	end,
	
	help  = function() usage(io.stdout) end
	
})[cmd] or usage)()

if err then
	die(err)
end
