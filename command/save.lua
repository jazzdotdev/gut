local repo = require 'repo'

return function (arg)
	local err = repo:init()
	if err then
		return err
	end

	return repo:save()
end