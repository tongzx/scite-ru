--[[----------------------------------------------------------------------------
Select_And_Open_Filename.lua
Author: VladVRO
version 1.0

Расширение команды "Открыть выделенный файл" для случая когда выделения нет.
Скрипт выделяет подходящую область рядом с курсором в качестве искомого имени
файла и пытается открыть этот файл.

Подключение:
Добавьте в SciTEStartup.lua строку
dofile (props["SciteDefaultHome"].."\\tools\\Select_And_Open_Filename.lua")

--]]----------------------------------------------------------------------------

local function isFileExists(filename)
	if os.getfileattr(filename) then
		return true
	else
		return false
	end
end

local function isFilenameChar(ch)
	if
		ch > 32 and ch < 127
		and ch ~= 34  -- "
		and ch ~= 39  -- '
		and ch ~= 42  -- *
		and ch ~= 47  -- /
		and ch ~= 58  -- :
		and ch ~= 60  -- <
		and ch ~= 62  -- >
		and ch ~= 63  -- ?
		and ch ~= 92  -- \
		and ch ~= 124 -- |
	then
		return true
	end
	return false
end


local function Select_And_Open_File()
	local sci
	if editor.Focus then
		sci = editor
	else
		sci = output
	end 
	local filename = sci:GetSelText()
	local foropen = nil
	
	if string.len(filename) == 0 then
		-- try to select file name near current position
		local s = sci.CurrentPos
		local e = s
		while isFilenameChar(sci.CharAt[s-1]) do -- find start
			s = s - 1
		end
		while isFilenameChar(sci.CharAt[e]) do -- find end
			e = e + 1
		end
		
		if s ~= e then
			-- set selection and try to find file
			sci:SetSel(s,e)
			local dir = props["FileDir"].."\\"
			filename = string.gsub(sci:GetSelText(), '\\\\', '\\')
			foropen = dir..filename
			local isFile = isFileExists(foropen)
			
			while not isFile do
				ch = sci.CharAt[s-1]
				if ch == 92 or ch == 47 then -- \ /
					-- expand selection start
					s = s - 1
					while isFilenameChar(sci.CharAt[s-1]) do
						s = s - 1
					end
					sci:SetSel(s,e)
					filename = string.gsub(sci:GetSelText(), '\\\\', '\\')
					foropen = dir..filename
				elseif string.len(dir) > 3 then
					dir = string.gsub(dir, "(.*)\\([^\\]+)\\", "%1\\")
					foropen = dir..filename
				else
					break
				end
				isFile = isFileExists(foropen)
			end
			
			if isFile then
				scite.Open(foropen)
				return true
			end
		end
	
	end
end

-- Add user event handler OnMenuCommand
local old_OnMenuCommand = OnMenuCommand
function OnMenuCommand (msg, source)
	local result
	if old_OnMenuCommand then result = old_OnMenuCommand(msg, source) end
	if not result and msg == 103 then --IDM_OPENSELECTED
		if Select_And_Open_File() then return true end
	end
	return result
end
