--[[--------------------------------------------------
SideBar.lua
Authors: Frank Wunderlich, mozers™, VladVRO, frs, BioInfo
version 1.5
------------------------------------------------------
  Needed gui.dll by Steve Donovan
  Connection:
   In file SciTEStartup.lua add a line:
      dofile (props["SciteDefaultHome"].."\\tools\\SideBar.lua")
   Set in a file .properties:
      command.checked.17.*=$(sidebar.show)
      command.name.17.*=SideBar
      command.17.*=SideBar_ShowHide
      command.mode.17.*=subsystem:lua,savebefore:no

    # Set show(1) or hide(0) to SciTE start
    sidebar.show=1
--]]--------------------------------------------------

-- you can choose to make it a stand-alone window; just uncomment this line:
-- local win = true

local tab_index = 0
local panel_width = 200
local win_height = props['position.height']
if win_height == '' then win_height = 600 end

----------------------------------------------------------
-- Create panels
----------------------------------------------------------
local tab0 = gui.panel(panel_width + 18)

local memo_path = gui.memo()
tab0:add(memo_path, "top", 22)

local list_dir = gui.list()
local list_dir_height = win_height/2 - 80
tab0:add(list_dir, "top", list_dir_height)

local list_favorites = gui.list(true)
list_favorites:add_column("Favorites", 600)
tab0:client(list_favorites)

tab0:context_menu {
	'FileMan: Show All|FileMan_MaskAllFiles',
	'FileMan: Only current ext|FileMan_MaskOnlyCurrentExt',
	'', -- separator
	'FileMan: Copy to...|FileMan_FileCopy',
	'FileMan: Move to...|FileMan_FileMove',
	'FileMan: Rename|FileMan_FileRename',
	'FileMan: Delete\tDel|FileMan_FileDelete',
	'FileMan: Execute|FileMan_FileExec',
	'FileMan: Exec with Params|FileMan_FileExecWithParams',
	'FileMan: Add to Favorites\tIns|Favorites_AddFile',
	'', -- separator
	'Favorites: Add active buffer|Favorites_AddCurrentBuffer',
	'Favorites: Delete item\tDel|Favorites_DeleteItem',
}
-------------------------
local tab1 = gui.panel(panel_width + 18)

local list_func = gui.list(true)
list_func:add_column("Functions/Procedures", 600)
local list_func_height = win_height/2 - 80
tab1:add(list_func, "top", list_func_height)

local list_bookmarks = gui.list(true)
list_bookmarks:add_column("@", 24)
list_bookmarks:add_column("Bookmarks", 600)
tab1:client(list_bookmarks)

tab1:context_menu {
	'Functions: Sort by Order|Functions_SortByOrder',
	'Functions: Sort by Name|Functions_SortByName',
}
-------------------------
local tab2 = gui.panel(panel_width + 18)

local list_abbrev = gui.list(true)
list_abbrev:add_column("Abbrev", 60)
list_abbrev:add_column("Expansion", 600)
tab2:client(list_abbrev)

-------------------------
local win_parent
if win then
	win_parent = gui.window "Side Bar"
else
	win_parent = gui.panel(panel_width)
end

local tabs = gui.tabbar(win_parent)
tabs:add_tab("FileMan", tab0)
tabs:add_tab("Func/Bmk", tab1)
tabs:add_tab("Abbrev", tab2)
win_parent:client(tab2)
win_parent:client(tab1)
win_parent:client(tab0)

if tonumber(props['sidebar.show'])==1 then
	if win then
		win_parent:size(panel_width + 24, 600)
		win_parent:show()
	else
		gui.set_panel(win_parent,"right")
	end
end

----------------------------------------------------------
-- tab0:memo_path   Path and Mask
----------------------------------------------------------
local current_path = ''
local file_mask = '*.*'

local function FileMan_ShowPath()
	local rtf = '{\\rtf\\ansi\\ansicpg1251{\\fonttbl{\\f0\\fcharset204 Helv;}}{\\colortbl ;\\red0\\green0\\blue255;  \\red255\\green0\\blue0;}\\f0\\fs16'
	local path = '\\cf1'..current_path:gsub('\\', '\\\\')
	local mask = '\\cf2'..file_mask..'}'
	memo_path:set_text(rtf..path..mask)
end

----------------------------------------------------------
-- tab0:list_dir   File Manager
----------------------------------------------------------
local function FileMan_ListFILL()
	if current_path == '' then return end
	list_dir:clear()
	local folders = gui.files(current_path..'*', true)
	list_dir:add_item ('[..]', {'..','d'})
	for i, d in ipairs(folders) do
		list_dir:add_item('['..d..']', {d,'d'})
	end
	local files = gui.files(current_path..file_mask)
	if files then
		for i, filename in ipairs(files) do
			list_dir:add_item(filename, {filename})
		end
	end
	list_dir:set_selected_item(0)
	FileMan_ShowPath()
end

local function FileMan_GetSelectedItem()
	local idx = list_dir:get_selected_item()
	if idx == -1 then return '' end
	local data = list_dir:get_item_data(idx)
	local dir_or_file = data[1]
	local attr = data[2]
	return dir_or_file, attr
end

function FileMan_MaskAllFiles()
	file_mask = '*.*'
	FileMan_ListFILL()
end

function FileMan_MaskOnlyCurrentExt()
	local filename, attr = FileMan_GetSelectedItem()
	if filename == '' then return end
	if attr == 'd' then return end
	file_mask = '*.'..filename:gsub('.+%.','')
	FileMan_ListFILL()
end

function FileMan_FileCopy()
	local filename = FileMan_GetSelectedItem()
	if filename == '' or filename == '..' then return end
	local path_destantion = gui.select_dir_dlg("Copy to...")
	if path_destantion == nil then return end
	os_copy(current_path..filename, path_destantion..'\\'..filename)
	FileMan_ListFILL()
end

function FileMan_FileMove()
	local filename = FileMan_GetSelectedItem()
	if filename == '' or filename == '..' then return end
	local path_destantion = gui.select_dir_dlg("Move to...")
	if path_destantion == nil then return end
	os.rename(current_path..filename, path_destantion..'\\'..filename)
	FileMan_ListFILL()
end

function FileMan_FileRename()
	function CheckFilename(char)
		return not char:match('[\/:|*?"<>]')
	end
	local filename = FileMan_GetSelectedItem()
	if filename == '' or filename == '..' then return end
	local filename_new = shell.inputbox("Rename", "Enter new filename:", filename, "CheckFilename")
	if filename_new == nil then return end
	if filename_new.len ~= 0 and filename_new ~= filename then
		os.rename(current_path..filename, current_path..filename_new)
		FileMan_ListFILL()
	end
end

function FileMan_FileDelete()
	local filename, attr = FileMan_GetSelectedItem()
	if filename == '' then return end
	if attr == 'd' then return end
	if shell.msgbox("Are you sure DELETE file?\n"..filename, "DELETE", 4+256) == 6 then
	-- if gui.message("Are you sure DELETE file?\n"..filename, "query") then
		os.remove(current_path..filename)
		FileMan_ListFILL()
	end
end

local function FileMan_FileExecWithSciTE(cmd, mode)
	local p0 = props["command.0.*"]
	local p1 = props["command.mode.0.*"]
	props["command.name.0.*"] = 'tmp'
	props["command.0.*"] = cmd
	if mode == nil then mode = 'console' end
	props["command.mode.0.*"] = 'subsystem:'..mode..',savebefore:no'
	scite.MenuCommand(9000)
	props["command.0.*"] = p0
	props["command.mode.0.*"] = p1
end

function FileMan_FileExec(params)
	if params == nil then params = '' end
	local filename = FileMan_GetSelectedItem()
	if filename == '' then return end
	local file_ext = filename:match("[^.]+$")
	if file_ext == nil then return end
	file_ext = '%*%.'..string.lower(file_ext)
	local cmd = ''
	local function command_build(lng)
		local cmd = props['command.build.$(file.patterns.'..lng..')']
		cmd = cmd:gsub(props["FilePath"], current_path..filename)
		return cmd
	end
	-- Lua
	if string.match(props['file.patterns.lua'], file_ext) ~= nil then
		dostring(params)
		dofile(current_path..filename)
	-- Batch
	elseif string.match(props['file.patterns.batch'], file_ext) ~= nil then
		FileMan_FileExecWithSciTE(command_build('batch'))
		return
	-- WSH
	elseif string.match(props['file.patterns.wscript']..props['file.patterns.wsh'], file_ext) ~= nil then
		FileMan_FileExecWithSciTE(command_build('wscript'))
	-- Other
	else
		local ret, descr = shell.exec(current_path..filename..params)
		if not ret then
			print (">Exec: "..filename)
			print ("Error: "..descr)
		end
	end
end

function FileMan_FileExecWithParams()
	if scite.ShowParametersDialog('Exec "'..FileMan_GetSelectedItem()..'". Please set params:') then
		local params = ''
		for p = 1, 4 do
			local ps = props[tostring(p)]
			if ps ~= '' then
				params = params..' '..ps
			end
		end
		FileMan_FileExec(params)
	end
end

local function OpenFile(filename)
	if filename:match(".session$") ~= nil then
		filename = filename:gsub('\\','\\\\')
		scite.Perform ("loadsession:"..filename)
	else
		scite.Open(filename)
	end
	editor.Focus = true
end

local function FileMan_OpenItem()
	local dir_or_file, attr = FileMan_GetSelectedItem()
	if dir_or_file == '' then return end
	if attr == 'd' then
		gui.chdir(dir_or_file)
		if dir_or_file == '..' then
			local new_path = current_path:gsub('(.*\\).*\\$', '%1')
			if not gui.files(new_path..'*',true) then return end
			current_path = new_path
		else
			current_path = current_path..dir_or_file..'\\'
		end
		FileMan_ListFILL()
	else
		OpenFile(current_path..dir_or_file)
	end
end

list_dir:on_double_click(function()
	FileMan_OpenItem()
end)

list_dir:on_key(function(key)
	if key == 13 then -- Enter
		FileMan_OpenItem()
	elseif key == 8 then -- BackSpace
		list_dir:set_selected_item(0)
		FileMan_OpenItem()
	elseif key == 46 then -- Delele
		FileMan_FileDelete()
	elseif key == 45 then -- Insert
		Favorites_AddFile()
	end
end)

----------------------------------------------------------
-- tab0:list_favorites   Favorites
----------------------------------------------------------
local favorites_filename = props['SciteUserHome']..'\\favorites.lst'
local list_fav_table = {}

local function Favorites_ListFILL()
	local favorites_file = io.open(favorites_filename)
	if favorites_file then
		for line in favorites_file:lines() do
			if line.len ~= 0 then
				local caption = line:gsub('.+\\','')
				list_favorites:add_item(caption, line)
				table.insert(list_fav_table, line)
			end
		end
		favorites_file:close()
	end
end
Favorites_ListFILL()

local function Favorites_SaveList()
	io.output(favorites_filename)
	local list_string = table.concat(list_fav_table,'\n')
	io.write(list_string)
	io.close()
end

function Favorites_AddFile()
	local filename, attr = FileMan_GetSelectedItem()
	if filename == '' then return end
	if attr == 'd' then return end
	list_favorites:add_item(filename, current_path..filename)
	table.insert(list_fav_table, current_path..filename)
end

function Favorites_AddCurrentBuffer()
	list_favorites:add_item(props['FileNameExt'], props['FilePath'])
	table.insert(list_fav_table, props['FilePath'])
end

function Favorites_DeleteItem()
	local idx = list_favorites:get_selected_item()
	if idx == -1 then return end
	list_favorites:delete_item(idx)
	table.remove (list_fav_table, idx+1)
end

local function Favorites_OpenFile()
	local idx = list_favorites:get_selected_item()
	if idx == -1 then return end
	local filename = list_favorites:get_item_data(idx)
	OpenFile(filename)
end

list_favorites:on_double_click(function()
	Favorites_OpenFile()
end)

list_favorites:on_key(function(key)
	if key == 13 then -- Enter
		Favorites_OpenFile()
	elseif key == 46 then -- Delele
		Favorites_DeleteItem()
	end
end)

----------------------------------------------------------
-- tab1:list_func   Functions/Procedures
----------------------------------------------------------
local table_functions = {}
-- 1 - function names
-- 2 - line number
local _sort = 'order'

--[[ Note:
	- only upper char
	- ()function name()
	Правила создания регсепов:
	- использовать только заглавные буквы
	- имя функции должно быть выделено с обеих сторон парами скобок "()function name()" . Не путать с %b()!
	- если для языка задано несколько регсепов, то функция должна находится только одним из них
]]
local Lang2RegEx = {
	['Assembler']={"\n%s*()%w+()%s+[FP][R][AO][MC][E%s].-[E][N][D][FP]"},
	['C++']={"()[^.,<>=\n%s]+()%([^.<>=)]-%)[%s\/}]-%b{}",
			"()[_%w]+::[~%w]+()%s*%b() -C?O?N?S?T?[%s:\r]*\n"},
	['JScript']={"\n%s*()FUNCTION *[^ ]-()%b()%s-%b{}"},
	['VBScript']={"\n%s*()SUB *.-()%b().-END SUB",
				"\n%s*()FUNCTION *.-()%b().-END FUNCTION"},
	['VisualBasic']={"\n%s*P?U?B?L?I?C?P?R?I?V?A?T?E? *()SUB *[%w_]-()%b().-END SUB",
					"\n%s*P?U?B?L?I?C?P?R?I?V?A?T?E? *()FUNCTION *[%w_]-()%b().-END FUNCTION",
					"\n%s*P?U?B?L?I?C?P?R?I?V?A?T?E? *()PROPERTY *[LG]ET *[%w_]-()%b().-END PROPERTY"},
	['CSS']={"()[%w.#-_]+()%s-%b{}"},
	['Pascal']={"\n%s*()PROCEDURE *[%w_]-()%b()",
				"\n%s*()FUNCTION *[%w_]-()%b()"},
	['Python']={"\n%s*()DEF *[%w_]-()%b():",
				"\n%s*()CLASS *[%w_]-()%b():"},
	['*']={"\n%s*L*O*C*A*L* *()[SF][U][BN][^ .]* [^ (]*()%b()"},
}
local Lexer2Lang = {
	['asm']='Assembler',
	['cpp']='C++',
	['js']='JScript',
	['vb']='VisualBasic',
	['vbscript']='VBScript',
	['css']='CSS',
	['pascal']='Pascal',
	['python']='Python',
}
local Ext2Lang = {}
local function Fill_Ext2Lang()
	local patterns = {
		[props['file.patterns.asm']]='Assembler',
		[props['file.patterns.cpp']]='C++',
		[props['file.patterns.wsh']]='JScript',
		[props['file.patterns.vb']]='VisualBasic',
		[props['file.patterns.wscript']]='VBScript',
		['*.css']='CSS',
		[props['file.patterns.pascal']]='Pascal',
		[props['file.patterns.py']]='Python',
	}
	for i,v in pairs(patterns) do
		for ext in (i..';'):gfind("%*%.([^;]+);") do
			Ext2Lang[ext] = v
		end
	end
end
Fill_Ext2Lang()

local function Functions_GetNames()
	table_functions = {}
	local tablePattern = Lang2RegEx[Ext2Lang[props["FileExt"]]]
	if not tablePattern then
		tablePattern = Lang2RegEx[Lexer2Lang[editor.LexerLanguage]]
		if not tablePattern then
			tablePattern = Lang2RegEx['*']
		end
	end
	local textAll = editor:GetText()
	for _, findPattern in ipairs(tablePattern) do
		for _start, _end in string.gmatch(textAll:upper(), findPattern) do
			local findString = textAll:sub(_start, _end-1)
			findString = findString:gsub("[Ss][Uu][Bb] ", "s: ") -- VB, VBS
			findString = findString:gsub("[Ff][Uu][Nn][Cc][Tt][Ii][Oo][Nn] ", "f: ") -- JS, VB,...
			findString = findString:gsub("[Pp][Rr][Oo][Cc][Ee][Dd][Uu][Rr][Ee] ", "p: ") -- Pascal
			findString = findString:gsub("[Pp][Rr][Oo][Сс] ", "p: ") -- C
			findString = findString:gsub("[Pp][Rr][Oo][Pp][Ee][Rr][Tt][Yy] [Ll][Ee][Tt] ", "pl: ") -- VB
			findString = findString:gsub("[Pp][Rr][Oo][Pp][Ee][Rr][Tt][Yy] [Gg][Ee][Tt] ", "pg: ") -- VB
			findString = findString:gsub("[Cc][Ll][Aa][Ss][Ss] ", "c: ") -- Phyton
			findString = findString:gsub("[Dd][Ee][Ff] ", "d: ") -- Phyton
			local line_number = editor:LineFromPosition(_start)
			table.insert (table_functions, {findString, line_number})
		end
	end
end

local function Functions_ListFILL()
	if tonumber(props['sidebar.show'])~=1 or tab_index~=1 then return end
	if _sort == 'order' then
		table.sort(table_functions, function(a, b) return a[2]<b[2] end)
	else
		table.sort(table_functions, function(a, b) return a[1]<b[1] end)
	end
	list_func:clear()
	for _, a in ipairs(table_functions) do
		list_func:add_item(a[1], a[2])
	end
end

function Functions_SortByOrder()
	_sort = 'order'
	Functions_ListFILL()
end

function Functions_SortByName()
	_sort = 'name'
	Functions_ListFILL()
end

local function Functions_GotoLine()
	local sel_item = list_func:get_selected_item()
	if sel_item == -1 then return end
	local pos = list_func:get_item_data(sel_item)
	if pos then
		editor:GotoLine(pos)
		editor.Focus = true
	end
end

list_func:on_double_click(function()
	Functions_GotoLine()
end)

list_func:on_key(function(key)
	if key == 13 then -- Enter
		Functions_GotoLine()
	end
end)

----------------------------------------------------------
-- tab1:list_bookmarks   Bookmarks
----------------------------------------------------------
local table_bookmarks = {}
-- 1 - file path
-- 2 - buffer number
-- 3 - line number
-- 4 - line text

local function GetBufferNumber()
	local buf = props['BufferNumber']
	if buf == '' then buf = 1 else buf = tonumber(buf) end
	return buf
end

local function Bookmark_Add(line_number)
	local line_text = editor:GetLine(line_number):gsub('^%s+', ''):gsub('%s+', ' ')
	local buffer_number = GetBufferNumber()
	table.insert (table_bookmarks, {props['FilePath'], buffer_number, line_number, line_text})
end

local function Bookmark_Delete(line_number)
	for i = #table_bookmarks, 1, -1 do
		local a = table_bookmarks[i]
		if a[1] == props['FilePath'] then
			if line_number == nil then
				table.remove(table_bookmarks, i)
			elseif a[3] == line_number then
				table.remove(table_bookmarks, i)
				break
			end
		end
	end
end

local function Bookmarks_ListFILL()
	if tonumber(props['sidebar.show'])~=1 or tab_index~=1 then return end
	table.sort(table_bookmarks, function(a, b) return a[2]<b[2] or a[2]==b[2] and a[3]<b[3] end)
	list_bookmarks:clear()
	for _, a in ipairs(table_bookmarks) do
		list_bookmarks:add_item({a[2], a[4]}, {a[1], a[3]})
	end
end

local function Bookmarks_RefreshTable()
	Bookmark_Delete()
	for i = 0, editor.LineCount do
		if editor:MarkerGet(i) == 2 then
			Bookmark_Add(i)
		end
	end
	Bookmarks_ListFILL()
end

local function Bookmarks_GotoLine()
	local sel_item = list_bookmarks:get_selected_item()
	if sel_item == -1 then return end
	local pos = list_bookmarks:get_item_data(sel_item)
	if pos then
		scite.Open(pos[1])
		editor:GotoLine(pos[2])
		editor.Focus = true
	end
end

list_bookmarks:on_double_click(function()
	Bookmarks_GotoLine()
end)

list_bookmarks:on_key(function(key)
	if key == 13 then -- Enter
		Bookmarks_GotoLine()
	end
end)

----------------------------------------------------------
-- tab2:list_abbrev   Abbreviations
----------------------------------------------------------
local function Abbreviations_ListFILL()
	local function ReadAbbrev(file)
		local abbrev_file = io.open(file)
		if abbrev_file then
			for line in abbrev_file:lines() do
				if string.len(line) ~= 0 then
					local _abr, _exp = string.match(line, '(.-)=(.+)')
					if _abr ~= nil then
						list_abbrev:add_item({_abr, _exp}, _exp)
					else
						local import_file = string.match(line, '^import%s+(.+)')
						if import_file ~= nil then
							ReadAbbrev(string.match(file, '.+\\')..import_file)
						end
					end
				end
			end
			abbrev_file:close()
		end
	end

	list_abbrev:clear()
	local abbrev_filename = props['AbbrevPath']
	ReadAbbrev(abbrev_filename)
end

local function Abbreviations_InsertExpansion()
	local sel_item = list_abbrev:get_selected_item()
	if sel_item == -1 then return end
	local abbrev = list_abbrev:get_item_text(sel_item)
	local ss, se = editor.SelectionStart, editor.SelectionEnd
	local len = abbrev:len()
	editor:BeginUndoAction()
	editor:InsertText(ss, abbrev)
	editor:SetSel(se+len, ss+len)
	scite.MenuCommand(IDM_ABBREV)
	editor:EndUndoAction()
	editor.Focus = true
end

local function Abbreviations_ShowExpansion()
	local sel_item = list_abbrev:get_selected_item()
	if sel_item == -1 then return end
	local expansion = list_abbrev:get_item_data(sel_item)
	expansion = expansion:gsub('\\r','\r'):gsub('\\n','\n'):gsub('\\t','\t')
	editor:CallTipShow(editor.CurrentPos, expansion)
end

list_abbrev:on_double_click(function()
	Abbreviations_InsertExpansion()
end)

list_abbrev:on_select(function()
	Abbreviations_ShowExpansion()
end)

list_abbrev:on_key(function(key)
	if key == 13 then -- Enter
		Abbreviations_InsertExpansion()
	elseif (key >= 33 and key <= 40) then -- все это из за того, что выбор с помощью курсорных клавиш не порождает события on_select
		Abbreviations_ShowExpansion()
	end
end)

----------------------------------------------------------
-- Events
----------------------------------------------------------
local function OnSwitch()
	if tonumber(props['sidebar.show'])~=1 then return end
	if tab_index == 0 then
		local path = props['FileDir']
		if path == '' then return end
		path = path:gsub('\\$','')..'\\'
		if path ~= current_path then
			current_path = path
				Functions_GetNames() FileMan_ListFILL()
		end
	elseif tab_index == 1 then
		Functions_GetNames() Functions_ListFILL()
		Bookmarks_ListFILL()
	elseif tab_index == 2 then
		Abbreviations_ListFILL()
	end
end

tabs:on_select(function(ind)
	tab_index=ind
	OnSwitch()
end)

-- Скрытие / показ панели
function SideBar_ShowHide()
	if tonumber(props['sidebar.show'])==1 then
		if win then
			win_parent:hide()
		else
			gui.set_panel()
		end
		props['sidebar.show']=0
	else
		if win then
			win_parent:show()
		else
			gui.set_panel(win_parent,"right")
		end
		props['sidebar.show']=1
		OnSwitch()
	end
end

local function OnDocumentContentsChanged()
	if tonumber(props['sidebar.show'])~=1 then return end
	if tab_index == 1 then
		Functions_GetNames() Functions_ListFILL()
		Bookmarks_RefreshTable()
	end
end

-- Add user event handler OnSwitchFile
local old_OnSwitchFile = OnSwitchFile
function OnSwitchFile(file)
	local result
	if old_OnSwitchFile then result = old_OnSwitchFile(file) end
	OnSwitch()
	return result
end

-- Add user event handler OnOpen
local old_OnOpen = OnOpen
function OnOpen(file)
	local result
	if old_OnOpen then result = old_OnOpen(file) end
	OnSwitch()
	return result
end

-- Add user event handler OnUpdateUI
local line_count = 0
local old_OnUpdateUI = OnUpdateUI
function OnUpdateUI()
	local result
	if old_OnUpdateUI then result = old_OnUpdateUI() end
	local line_count_new = editor.LineCount
	if line_count_new ~= line_count then
		OnDocumentContentsChanged()
		line_count = line_count_new
	end
	return result
end

-- Add user event handler OnSendEditor
local old_OnSendEditor = OnSendEditor
function OnSendEditor(id_msg, wp, lp)
	local result
	if old_OnSendEditor then result = old_OnSendEditor(id_msg, wp, lp) end
	if id_msg == SCI_MARKERADD then
		if lp == 1 then Bookmark_Add(wp) Bookmarks_ListFILL() end
	elseif id_msg == SCI_MARKERDELETE then
		if lp == 1 then Bookmark_Delete(wp) Bookmarks_ListFILL() end
	elseif id_msg == SCI_MARKERDELETEALL then
		if wp == 1 then Bookmark_Delete() Bookmarks_ListFILL() end
	end
	return result
end

-- Add user event handler OnFinalise
local old_OnFinalise = OnFinalise
function OnFinalise()
	local result
	if old_OnFinalise then result = old_OnFinalise() end
	Favorites_SaveList()
	return result
end
