-- Построение дерева документа на базе function или|и sub
-- Автор: gansA <gans_a@newmail.ru>
-----------------------------------------------
--~ output.split.vertical = 1
--~ props["split.vertical"] = 1
--~ print(props["split.vertical"])

local sSub = 'sub'
local sFun = 'function'
trace('> DocTree ('..sSub..'|'..sFun..')\n')

--~ sub aaa()
--~ function ccc()
--~ local function zzz()

--// step 0 [get name] //--
local findText = '[sfSF][uU][bnBN].*'
local flag = SCFIND_REGEXP + SCFIND_POSIX
local s,e = editor:findtext(findText,flag,0)

local tFind = {}

if s ~= nil then
	local m = editor:LineFromPosition(s) - 1
	while s do
		local l = editor:LineFromPosition(s)

		if l ~= m then
			local str = editor:GetLine(l)

			local iSub = string.find(str,sSub..'%s+')
			local iFun = string.find(str,sFun..'%s+')

			if (iSub ~= nil or iFun ~= nil) and string.find(str,'end%s') == nil then
				str = string.gsub(' '..str,'%s+',' ') --// drop space

				--// get name //--
				if iSub ~= nil then
					str = string.gsub(str,'.+('..sSub..')%s+(%w+).+','%2')
				end
				if iFun ~= nil then
					str = string.gsub(str,'.+('..sFun..')%s+(%w+).+','%2')
				end

				--// result //--
				--// trace(add..str..'\n') --// debug
				table.insert(tFind,str)
			end

			m = l
		end

		s,e = editor:findtext(findText,flag,e+1)
	end
end

--// step 1 [get all call] //--
local tTree = {}
local tAdd = {}

for key,value in tFind do
	--// print(value) --// debug

	local findText = value
	local flag = SCFIND_REGEXP + SCFIND_POSIX
	local s,e = editor:findtext(findText,flag,0)

	if s ~= nil then
		local m = editor:LineFromPosition(s) - 1
		while s do
			local l = editor:LineFromPosition(s)

			if l ~= m then
				local str = editor:GetLine(l)

				local iSub = string.find(str,sSub..'%s+')
				local iFun = string.find(str,sFun..'%s+')

				if string.find(str,'end%s') == nil and string.find(str,value..'%s*=') == nil then
					str = string.gsub(' '..str,'%s+',' ') --// drop space

					--// get name //--
					if iSub == nil and iFun == nil then
						--// str = '  '..str
						str = ' |  +-'..str
					else
						--// str = ''..str
						str = ' +-'..str
					end

					--// result //--
					--// trace(add..str..'\n') --// debug
					table.insert(tAdd,(l + 1))
					tTree[l + 1] = str
				end

				m = l
			end

			s,e = editor:findtext(findText,flag,e+1)
		end
	end
end

--// step 2 [print tree] //--
table.sort(tAdd,function(a,b) return a<b end)
for key,value in tAdd do

	--// indention //--
	local add = ':'..value..':'
	local i = 8 - string.len(add)
	local ind = ' '
	while (string.len(ind) < i) do
		ind = ind..' '
	end

	print(add..ind..tTree[value]) --// debug
end