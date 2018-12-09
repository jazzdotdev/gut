local escape = require"escape"

return function(cmd)
	local err = nil
	if type(cmd) ~= "string" then
		cmd = escape(cmd)
	end

	local ok, reason, rc = os.execute(cmd)
	if not ok then
		err = reason .. " " .. rc
	end
	return err, reason, rc
end