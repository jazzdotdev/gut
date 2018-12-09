local escape = require"escape"

return function(cmd)
	local err = nil
	local ok, reason, rc = os.execute(escape(cmd))
	if not ok then
		err = reason .. " " .. rc
	end
	return err, reason, rc
end