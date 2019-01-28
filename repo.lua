consts = require"consts"
diffsplit = require"diffsplit"

local repo = {}

-- find repo root with a metadir
function repo:findroot(path)

	path = path or "."

	local fullpath, err = fs.abs(path)
	if err then return nil, err end

	
	if fs.exists(fs.join(fullpath, consts.metadir)) then
		return fullpath
	end

	if fullpath == "/" then
		return nil
	end
	
	return self:findroot(fs.join(fullpath, ".."))
end

-- check if provided path resides in a repo
function repo:isrepo(path)
	return self:findroot(path) ~= nil
end

function repo:isvalidrepo(path)
	local path, err = self:findroot(path)
	if err then return false, err end
	if not path then return false, "repo metadir not found" end

	return fs.exists(fs.join(path, consts.metadir)) and
	fs.exists(fs.join(path, consts.metadir, consts.snapshot))
end

function repo:isroot(root)
	local root, err = fs.abs(root)
	if err then
		-- todo: swallowed error
		return false
	end

	return root == self.root or root == self.snapshot
end

function repo:relpath(path)
	
	local path, err = fs.abs(path)
	if err then
		return nil, err
	end

	local root = self.root

	if root == path then
		return "."
	end

	local start, fin = string.find(path, root, 0, true)

	if start then
		local relpath = string.sub(path, fin + 1)
		while string.sub(relpath, 1, 1) == "/" do relpath = string.sub(relpath, 2) end
		if #relpath > 0 then
			return relpath
		end
	end
	return nil, "not relpath"
end

function repo:create(path)

	local path, err = fs.abs(path or ".")
	if err then return nil, err end

	local metadir = fs.join(path, consts.metadir)
	
	-- todo: add error handling for mkdir calls
	fs.mkdir(metadir)
	fs.mkdir(fs.join(metadir, "current"))
end

function repo:readignores()
	local ignores = {}
	-- todo: swallowed error
	local f = io.open(self.ignorefile)
	if f ~= nil then
		for line in f:lines() do
			-- todo: maybe use trim, but that will break expressions with significant spaces
			if line and #line > 0 then
				table.insert(ignores, line)
			end
		end
		f:close()
	end
	self.ignores = ignores
end

function repo:init(path)

	path, err = self:findroot(path)
	if err then return err end

	local valid, err = self:isvalidrepo(path)
	if err then return err end
	if not valid then return "not a valid repo" end

	self.root = path
	self.metadir = fs.join(self.root, consts.metadir)
	self.snapshot = fs.join(self.metadir, consts.snapshot)
	self.ignorefile = fs.join(self.root, consts.ignorefile)

	return self:readignores()
end

function repo:files(root, relpath)

	local path = root
	local isroot = relpath == "."
	if not isroot then
		path = fs.join(root, relpath)
	end

	if not fs.exists(path) then
		return {}
	end
	
	local entries = fs.entries(path)
	if entries == nil then
		return nil, "failed to get directory entries"
	end

	local files = {}
	
	for filename in entries do
		local skip = false
		if isroot then
			skip = skip or filename == consts.metadir
		end
		if not skip then
			for i, v in ipairs(self.ignores) do
				if string.match(filename, v) then
					skip = true
					break
				end
			end
		end

		if not skip then
			table.insert(files, filename)
		end
	end

	return files
end

function repo:diff(root, oldroot, relpath, diffs)

	local diffs = diffs or {}
	
	local a = fs.join(oldroot, relpath)
	local b = fs.join(root, relpath)

	local aexists = fs.exists(a)
	local bexists = fs.exists(b)
	local aisdir = aexists and fs.is_dir(a)
	local bisdir = bexists and fs.is_dir(b)
	local afiles = {}
	local bfiles = {}

	if aexists and aisdir then
		afiles = self:files(oldroot, relpath)
	else
		afiles = {}
	end

	if bexists and bisdir then
		bfiles = self:files(root, relpath)
	else
		bfiles = {}
	end

	-- compare directories
	if #afiles > 0 or #bfiles > 0 then
		local exists = {}
		local files = {}

		for i, filename in ipairs(afiles) do
			if not exists[filename] then
				table.insert(files, filename)
				exists[filename] = true
			end
		end
		for i, filename in ipairs(bfiles) do
			if not exists[filename] then
				table.insert(files, filename)
				exists[filename] = true
			end
		end

		table.sort(files)

		for i, filename in ipairs(files) do
			self:diff(root, oldroot, fs.join(relpath, filename), diffs)
		end
	end

	-- compare files
	if aexists and not aisdir or bexists and not bisdir then
		
		local acontent = ""
		local bcontent = ""
		
		if aexists and not aisdir then
			acontent = io.open(a):read("a")
		end
		
		if bexists and not bisdir then
			bcontent = io.open(b):read("a")
		end

		if #acontent > 0 or #bcontent > 0 then

			local quirks = {
				aexists = aexists,
				bexists = bexists,
				aempty = not aexists or #acontent == 0,
				bempty = not bexists or #bcontent == 0
			}
			
			diffstr = diff.compare_strings(acontent, bcontent)
			for diff in diffsplit(diffstr, quirks) do
				diff.filename = relpath
				diff.old = fs.join("a", relpath)
				diff.new = fs.join("b", relpath)
				table.insert(diffs, diff)
			end
		end
	end
	
	return diffs
end

function repo:shortdiff(diffs)
	local max = 0
	for i, diff in ipairs(diffs) do
		if diff.inserted + diff.removed > max then
			max = diff.inserted + diff.removed
		end
	end

	for i, diff in ipairs(diffs) do
		if diff.inserted > 0 or diff.removed > 0 then
			local removed = math.ceil((diff.removed / max) * 20)
			local inserted = math.ceil((diff.inserted / max) * 20)
			print(string.format("%s: %s%s", diff.filename, string.rep("-", removed), string.rep("+", inserted)))
		end
	end
end

return repo
