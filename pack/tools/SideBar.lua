--[[--------------------------------------------------
SideBar.lua
Authors: Frank Wunderlich, mozers™, VladVRO, frs, BioInfo
version 1.0
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

local panel_width = 200
local tab_index = 0
local current_path = props['FileDir']
local file_mask = '*.*'
local list_fav_table = {}
local line_count = 0

-- you can choose to make it a stand-alone window; just uncomment this line:
-- local win = true

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
local function FileMan_ShowPath()
	local rtf = '{\\rtf{\\fonttbl{\\f0\\fcharset1 Helv;}}{\\colortbl ;\\red0\\green0\\blue255;  \\red255\\green0\\blue0;}\\f0\\fs16'
	local path = '\\cf1'..string.gsub(current_path, '\\', '\\\\')..'\\\\'
	local mask = '\\cf2'..file_mask..'}'
	memo_path:set_text(rtf..path..mask)
end

----------------------------------------------------------
-- tab0:list_dir   File Manager
----------------------------------------------------------
local function FileMan_Fill()
	list_dir:clear()
	local folders = gui.files(current_path..'\\*', true)
	list_dir:add_item ('[..]', {'..','d'})
	for i, d in ipairs(folders) do
		list_dir:add_item('['..d..']', {d,'d'})
	end
	local files = gui.files(current_path..'\\'..file_mask)
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
	FileMan_Fill()
end

function FileMan_MaskOnlyCurrentExt()
	local filename, attr = FileMan_GetSelectedItem()
	if filename == '' then return end
	if attr == 'd' then return end
	file_mask = '*.'..filename:gsub('.+%.','')
	FileMan_Fill()
end

function FileMan_FileCopy()
	local filename = FileMan_GetSelectedItem()
	if filename == '' or filename == '..' then return end
	local path_destantion = gui.open_dir_dlg -- Note: There is no. This - the wish.
	-- Будет реализовано, когда появится функция выбора каталога
end

function FileMan_FileMove()
	local filename = FileMan_GetSelectedItem()
	if filename == '' or filename == '..' then return end
	local path_destantion = gui.open_dir_dlg -- Note: There is no. This - the wish.
	-- Будет реализовано, когда появится функция выбора каталога
end

function FileMan_FileRename()
	local filename = FileMan_GetSelectedItem()
	-- "Порнографический" диалог будет появлятся до той поры, пока не будет реализовано
	-- Issue 103: shell.inputbox http://code.google.com/p/scite-ru/issues/detail?id=103
	if filename == '' or filename == '..' then return end
	local filename_new = gui.prompt_value("Enter new filename:", filename)
	if filename_new.len ~= 0 and filename_new ~= filename then
		os.rename(current_path..'\\'..filename, current_path..'\\'..filename_new)
		FileMan_Fill()
	end
end

function FileMan_FileDelete()
	local filename, attr = FileMan_GetSelectedItem()
	if filename == '' then return end
	if attr == 'd' then return end
	if shell.msgbox("Are you sure DELETE file?\n"..filename, "DELETE", 4+256) == 6 then
	-- if gui.message("Are you sure DELETE file?\n"..filename, "query") then
		os.remove(current_path..'\\'..filename)
		FileMan_Fill()
	end
end

function FileMan_FileExec()
	local filename = FileMan_GetSelectedItem()
	if filename == '' then return end
	local ret, descr = shell.exec(current_path..'\\'..filename)
	if not ret then
		print (">Exec: "..filename)
		print ("Error: "..descr)
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
	if attr == 'd' then
		gui.chdir(dir_or_file)
		if dir_or_file == '..' then
			current_path = string.gsub(current_path,"(.*)\\.*$", "%1")
		else
			current_path = current_path..'\\'..dir_or_file
		end
		FileMan_Fill()
	else
		OpenFile(current_path..'\\'..dir_or_file)
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

local function Favorites_Fill()
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
Favorites_Fill()

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
	list_favorites:add_item(filename, current_path..'\\'..filename)
	table.insert(list_fav_table, current_path..'\\'..filename)
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
local Lang2RegEx = {
	['C++']="([^.,<>=\n]-[ :][^.,<>=\n%s]+[(][^.<>=)]-[)])[%s\/}]-%b{}",
	['JScript']="(\n[^,<>\n]-function[^(]-%b())[^{]-%b{}",
	['VBScript']="(\n[SsFf][Uu][BbNn][^\r]-)\r",
	['VisualBasic']="(\n[Public ]*[Private ]*[SsFfP][Uur][BbNno][^\r]-)\r",
	['CSS']="([%w.#-_]+)[%s}]-%b{}",
	['Pascal']="\n[pPfF][rRuU][oOnN][cC][eEtT][dDiI][uUoO][rRnN].(.-%b().-)\n",
	['Python']="\n%s-([dc][el][fa]%s-.-):",
	['*']="\n[local ]*[SsFf][Uu][BbNn][^ .]* ([^(]*%b())",
}
local Lexer2Lang = {
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

local function Functions_Fill()
	list_func:clear()
	local findPattern = Lang2RegEx[Ext2Lang[props["FileExt"]]]
	if not findPattern then
		findPattern = Lang2RegEx[Lexer2Lang[editor.LexerLanguage]]
		if not findPattern then
			findPattern = Lang2RegEx['*']
		end
	end
	local textAll = editor:GetText()
	local pos_start, pos_end, findString
	pos_start = 1
	while true do
		pos_start, pos_end, findString = string.find(textAll, findPattern, pos_start)
		if pos_start == nil then break end
		findString = findString:gsub("[\r\n]", ""):gsub("%s+", " ")
		local line_number = editor:LineFromPosition(pos_start)
		list_func:add_item(findString, line_number)
		pos_start = pos_end + 1
	end
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
local function Bookmarks_Add(line_number)
	local line_text = editor:GetLine(line_number):gsub('%s+', ' ')
	local buffer_number = props['BufferNumber']
	if buffer_number == '' then buffer_number = 1 end
	list_bookmarks:add_item({buffer_number, line_text}, {props['FilePath'], line_number})
end

local function Bookmarks_Delete(line_number)
	for i = 0, list_bookmarks:count() - 1 do
		local bookmark = list_bookmarks:get_item_data(i)
		if bookmark[1] == props['FilePath'] and bookmark[2] == line_number then
			list_bookmarks:delete_item(i)
			break
		end
	end
end

local function Bookmarks_DeleteAll()
	for i = list_bookmarks:count()-1, 0, -1 do
		local bookmark = list_bookmarks:get_item_data(i)
		if bookmark[1] == props['FilePath'] then
			list_bookmarks:delete_item(i)
		end
	end
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
local function Abbreviations_Fill()
	local function ReadAbbrev(file)
		local abbrev_file = io.open(file) 
		if abbrev_file then 
			for line in abbrev_file:lines() do 
				if string.len(line) ~= 0 then
					local _abr, _exp = string.match(line, '(.-)=(.+)')
					if _abr ~= nil then
						list_abbrev:add_item {_abr, _exp}
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
	local ss,se = editor.SelectionStart,editor.SelectionEnd
	local len = abbrev:len()
	editor:InsertText(ss, abbrev)
	editor:SetSel(se+len, ss+len)
	scite.MenuCommand(IDM_ABBREV)
	editor.Focus = true
end

list_abbrev:on_double_click(function()
	Abbreviations_InsertExpansion()
end)

list_abbrev:on_key(function(key)
	if key == 13 then -- Enter
		Abbreviations_InsertExpansion()
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
		if path ~= current_path then
			current_path = path
			FileMan_Fill()
		end
	elseif tab_index == 1 then
		Functions_Fill()
	elseif tab_index == 2 then
		Abbreviations_Fill()
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
	if tab_index == 0 then
		Functions_Fill()
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
		if lp == 1 then Bookmarks_Add(wp) end
	elseif id_msg == SCI_MARKERDELETE then
		if lp == 1 then Bookmarks_Delete(wp) end
	elseif id_msg == SCI_MARKERDELETEALL then
		if wp == 1 then Bookmarks_DeleteAll() end
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
