--[[--------------------------------------------------
text.lua
Authors: Tymur Gubayev
Version: 1.0
------------------------------------------------------
Description:	text-"lexer": colors latin chars, 
	national chars and highlights links. There's
	also possibility to 

------------------------------------------------------
Connection:
 In file SciTEStartup.lua add a line:
    dofile (props["SciteDefaultHome"].."\\languages\\text.lua")
 Set in a file .properties:
    lexer.*.txt=script_text
	style.script_text.default=
	style.script_text.identifier=fore:#8F6600
	style.script_text.link=fore:#5555BB,hotspot
	style.script_text.national_chars=fore:#B22222
--]]--------------------------------------------------


-- initialize
local IsURI = dofile (props["SciteDefaultHome"].."\\tools\\URL_detect.lua")

local styles = {[0]='DEFAULT', 'IDENTIFIER', 'LINK', 'NATIONAL_CHARS'}
-- invert table, set props
for i=0,#styles do
	local v = styles[i]
	styles[v]=i
	props['style.script_text.'..i]=props['style.script_text.'..v:lower()]
end

local function TextLexer(styler)
	-- this cycle is here, because there's no "OnPropsChanged" event
	for i=0,#styles do
		props['style.script_text.'..i]=props['style.script_text.'..styles[i]:lower()]
	end

	local IsIdentifier = function (c)
		return c:find('^%a+$') ~= nil
	end

	local IsLink = IsURI or function (c)
		return c:find('[:%w_&%?.%%-@%$%+=%*~%/]')-- ~= nil
	end

	local national_chars=props['chars.accented']
	local IsNational_Char = function (c)
		return c:find('['..national_chars..']') ~= nil --@todo: this wont work well for UTF
	end

	-- print("Styling: ", styler.startPos, styler.lengthDoc, styler.initStyle)
	styler:StartStyling(styler.startPos, styler.lengthDoc, styler.initStyle)
	local styler_endPos = styler.startPos + styler.lengthDoc

	while styler:More() do
		local stst = styler:State()
		local c = styler:Current()
		-- Exit state if needed
		if stst == styles.IDENTIFIER then
			if not IsIdentifier(c) then -- End of identifier
				-- local identifier = styler:Token()
				styler:SetState(styles.DEFAULT)
			end
		elseif stst == styles.NATIONAL_CHARS and not IsNational_Char(c) then
			styler:SetState(styles.DEFAULT)
		--[[--links are processed at once, so the state cannot be LINK
			elseif stst == styles.LINK and not IsLink(c) then
			styler:SetState(styles.DEFAULT)]]
		end

		local n -- link special var
		-- Enter state if needed
		if styler:State() == styles.DEFAULT then
			local s = editor:textrange(styler.Position(), styler_endPos) --@todo: optimize: only current line
			n = IsLink(s)
			if n then
				-- print(n,s:sub(1,n),'\n\t',s)
				styler:SetState(styles.LINK)
				for i = 1,n do styler:Forward() end
				styler:SetState(styles.DEFAULT)
			elseif IsNational_Char(c) then
				styler:SetState(styles.NATIONAL_CHARS)
			elseif IsIdentifier(c) then
				styler:SetState(styles.IDENTIFIER)
			end
		end

		-- if current text is a link, styler:Forward() is already called
		if not n then styler:Forward() end
	end
	styler:EndStyling()
end

AddEventHandler("OnStyle", function(styler)
	if styler.language == "script_text" then
		TextLexer(styler)
	end
end)

AddEventHandler("OnHotSpotReleaseClick", function(ctrl)
	if --editor.Lexer == 0 and 
	props['Language'] == "script_text" then
		local URL = GetCurrentHotspot()
		-- check if URL is like "a@b.c"
		if URL:find('^%w+@') then
			URL = "mailto:"..URL
		end
		shell.exec(URL)
	end
end)

