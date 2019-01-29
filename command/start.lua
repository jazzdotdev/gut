local repo = require 'repo'

return function (arg)
	if repo:isrepo() then
		return 'already in a repo'
	end
	return repo:create()
end