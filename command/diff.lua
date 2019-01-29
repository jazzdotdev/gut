local repo = require 'repo'

return function (arg)
	local err = repo:init()
	if err then
		return err
	end

	local diffs = repo:diff(repo.root, repo.snapshot, ".")
	io.stdout:write(table.unpack(diffs))
end