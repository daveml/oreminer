-- deferHdl
local M = {_TYPE='module', _NAME='utilConfFile', _VERSION='0.1'}


function M.get(fname, conf)

	fp = io.open( fname, "r" )
	print("Trying to load parameters from ", fname,"\n")
	if not fp then
		print("File does not exist\n")
		return
	end

	for line in fp:lines() do
		line = line:match( "%s*(.+)" )
		if line and line:sub( 1, 1 ) ~= "#" and line:sub( 1, 1 ) ~= ";" then
		option = line:match( "%S+" ):lower()
		value  = line:match( "%S*%s*(.*)" )

		if not value then
			conf[option] = true
		else
			if not value:find( "," ) then
			conf[option] = value
			else
			value = value .. ","
			conf[option] = {}
			for entry in value:gmatch( "%s*(.-)," ) do
				conf[option][#conf[option]+1] = entry
			end
			end
		end

		end
	end

	fp:close()
end

function M._write_Val(fp, val)
	if(type(val) == 'table') then
		for string in val do
			local outStr = string .. " "
			fp:write(outStr)
		end
	else
		fp:write(val)
	end
	fp:write("\n")
end

function M.set(fname,params)

	fp = io.open(fname, "w")

	for k,v in pairs(params) do
		local str = k .. " "
		fp:write(str)
		M._write_Val(fp, v)
	end

--	fp.flush()
	fp:close(fp)
end



return M
