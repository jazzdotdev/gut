local repo =      require 'repo'
local diffsplit = require 'diffsplit'

return function (arg)
	local err = repo:init()
	if err then
		return err
	end
	
	local diffs = repo:diff(repo.root, repo.snapshot, ".")
	
	local parsed = {}
	for i, d in ipairs(diffs) do
		for p in diffsplit(d) do
			table.insert(parsed, p)
		end
	end
	
	local max = 0
	for i, d in ipairs(parsed) do
		if d.inserted + d.removed > max then
			max = d.inserted + d.removed
		end
	end

	for i, d in ipairs(parsed) do
		if d.inserted > 0 or d.removed > 0 then
			local removed = math.ceil((d.removed / max) * 20)
			local inserted = math.ceil((d.inserted / max) * 20)
			print(string.format("%s: %s%s", d.filename, string.rep("-", removed), string.rep("+", inserted)))
		end
	end
end