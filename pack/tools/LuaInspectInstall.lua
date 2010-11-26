--[[--------------------------------------------------
LuaInspectInstall.lua
Authors: mozers
Version: 1.0
------------------------------------------------------
Служит для подключения LuaInspect <http://lua-users.org/wiki/LuaInspect>
Срабатывает при наличии параметра luainspect.path в .properties файле
В каталог, указанный этим параметром следует распаковать LuaInspect.
Реально испольуется только содержимое подкаталогов luainspectlib и metalualib
остальное можно спокойно удалять.
--]]--------------------------------------------------

function scite_GetProp(key,default)
	local val = props[key]
	if val and val ~= '' then return val
	else return default end
end

function scite_Command(tbl)
	function get_num(pat)
		for num = 0, 19 do
			if props['command.name.'..num..'.'..pat] == '' then return num end
		end
	end
	local name, cmd, pattern, shortcut = tbl:match('([^|]*)|([^|]*)|([^|]*)|([^|]*)')
	local num = get_num(pattern)
	props['command.name.'..num..'.'..pattern] = name
	props['command.'..num..'.'..pattern] = cmd
	props['command.mode.'..num..'.'..pattern] = 'subsystem:lua,savebefore:no'
	props['command.shortcut.'..num..'.'..pattern] = shortcut
end

local LUAINSPECT_PATH = props["luainspect.path"]
package.path = package.path .. ";" .. LUAINSPECT_PATH .. "\\metalualib\\?.lua"
package.path = package.path .. ";" .. LUAINSPECT_PATH .. "\\luainspectlib\\?.lua"
require "luainspect.scite" : install()
