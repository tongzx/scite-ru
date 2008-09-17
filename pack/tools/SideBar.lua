--[[--------------------------------------------------
SideBar.lua
Authors: Frank Wunderlich, mozers™, VladVRO, frs
version 0.92
------------------------------------------------------
  Needed gui.dll by Steve Donovan
  Connection:
   In file SciTEStartup.lua add a line:
      dofile (props["SciteDefaultHome"].."\\tools\\SideBar.lua")
   Set in a file .properties:
      command.checked.17.*=$(sidebar.show)
      command.name.17.*=SideBar
      command.17.*=show_hide
      command.mode.17.*=subsystem:lua,savebefore:no
--]]--------------------------------------------------

local current_path = props['FileDir']
local file_path = props['FilePath']
local file_mask = '*.*'
local panel_width = 200
local tab_index = 0
local line_count = 0
local list_fav_table = {}
local file_ext = '*.*'
local fav_select_index = 0
props['sidebar.show'] = 1
-- you can choose to make it a stand-alone window; just uncomment this line:
-- local win = true

local win_height = props['position.height']
if win_height == '' then win_height = 600 end

----------------------------------------------------------
-- Create panels
----------------------------------------------------------
local tab0 = gui.panel(panel_width + 18)

local text_path = gui.memo()
tab0:add(text_path, "top", 22)

local list_dir = gui.list()
local list_dir_height = win_height/2 - 80
tab0:add(list_dir, "top", list_dir_height)

local list_favorites = gui.list(true)
list_favorites:add_column("Favorites", 600)
tab0:client(list_favorites)
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

if win then
	win_parent:size(panel_width + 24, 600)
	win_parent:show()
else
	gui.set_panel(win_parent,"right")
end

tabs:on_select(function(ind)
	tab_index=ind
	on_switch()
end)

-- Скрытие / показ панели
function show_hide()
	if tonumber(props['sidebar.show']) == 1 then
		if win then
			win_parent:hide()
		else
			win_parent:size(0, 0)
		end
		props['sidebar.show'] = 0
	else
		if win then
			win_parent:show()
		else
			win_parent:size(panel_width, 0)
		end
		props['sidebar.show'] = 1
	end
end

----------------------------------------------------------
-- Tab0: FileManager
----------------------------------------------------------
function all_files()
	file_mask = '*.*'
	fill_list_dir()
end

function only_current_ext()
	file_mask = file_ext
	fill_list_dir()
end

function f_nil() end -- заглушка для разделителя списка в контекстном меню

function file_copy()
	if string.len(dir_or_file) < 2 then return end
	local path_destantion = gui.open_dir_dlg -- Note: There is no. This - the wish.
	-- Будет реализовано, когда появится функция выбора каталога
end

function file_move()
	if string.len(dir_or_file) < 2 then return end
	local path_destantion = gui.open_dir_dlg -- Note: There is no. This - the wish.
	-- Будет реализовано, когда появится функция выбора каталога
end

function file_ren()
	-- "Порнографический" диалог будет появлятся до той поры, пока не будет реализовано
	-- Issue 103: shell.inputbox http://code.google.com/p/scite-ru/issues/detail?id=103
	if string.len(dir_or_file) < 2 then return end
	local filename_new = gui.prompt_value("Enter new filename:", dir_or_file)
	if filename_new.len ~= 0 and filename_new ~= dir_or_file then
		os.rename(current_path..'\\'..dir_or_file, current_path..'\\'..filename_new)
		fill_list_dir()
	end
end

function file_del()
	if string.len(dir_or_file) < 2 then return end
	if shell.msgbox("Are you sure DELETE file?\n"..dir_or_file, "DELETE", 4+256) == 6 then
	-- if gui.message("Are you sure DELETE file?\n"..dir_or_file, "query") then
		os.remove(current_path..'\\'..dir_or_file)
		fill_list_dir()
	end
end

function file_exec()
	local filename = current_path..'\\'..dir_or_file
	local ret, descr = shell.exec(filename)
	if not ret then
		print (">Exec: "..filename)
		print ("Error: "..descr)
	end
end

function add_fav()
	if attr ~= 'd' then
		list_favorites:add_item(dir_or_file, current_path..'\\'..dir_or_file)
		table.insert(list_fav_table, current_path..'\\'..dir_or_file)
	end
end

function add_fav_buffer()
	list_favorites:add_item(props['FileNameExt'], props['FilePath'])
	table.insert(list_fav_table, props['FilePath'])
end

function del_fav()
	list_favorites:delete_item(fav_select_index)
	table.remove (list_fav_table, fav_select_index+1)
end

tab0:context_menu {
	'Files: Show All|all_files',
	'Files: Only current ext|only_current_ext',
	'-----------------------|f_nil', -- типа разделитель. другого, увы, нет :(
	'Files: Copy to...|file_copy',
	'Files: Move to...|file_move',
	'Files: Rename|file_ren',
	'Files: Delete|file_del',
	'Files: Execute|file_exec',
	'Files: Add to Favorites|add_fav',
	'-----------------------|f_nil', -- типа разделитель. другого, увы, нет :(
	'Favorites: Add active buffer|add_fav_buffer',
	'Favorites: Delete item|del_fav',
}

----------------------------------------------------------
-- Memo: Path and Mask
----------------------------------------------------------
local function show_path()
	local rtf = '{\\rtf{\\fonttbl{\\f0\\fcharset1 Helv;}}{\\colortbl ;\\red0\\green0\\blue255;  \\red255\\green0\\blue0;}\\f0\\fs16'
	local path = '\\cf1'..string.gsub(current_path, '\\', '\\\\')..'\\\\'
	local mask = '\\cf2'..file_mask..'}'
	text_path:set_text(rtf..path..mask)
end

----------------------------------------------------------
-- List: Folders and Files
----------------------------------------------------------
local function open_file(filename)
	if filename:match(".session$") ~= nil then
		filename = filename:gsub('\\','\\\\')
		scite.Perform ("loadsession:"..filename)
	else
		scite.Open(filename)
	end
	editor.Focus = true
end

function fill_list_dir()
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
	show_path()
end

list_dir:on_double_click(function(idx)
	if idx 	~= -1 then
		if attr == 'd' then
			gui.chdir(dir_or_file)
			if dir_or_file == '..' then
				current_path = string.gsub(current_path,"(.*)\\.*$", "%1")
			else
				current_path = current_path..'\\'..dir_or_file
			end
			fill_list_dir()
		else
			open_file(current_path..'\\'..dir_or_file)
		end
	end
end)

list_dir:on_select(function(idx)
	if idx 	~= -1 then
		local data = list_dir:get_item_data(idx)
		dir_or_file = data[1]
		attr = data[2]
		file_ext = '*.'..dir_or_file:gsub('.+%.','')
	end
end)

----------------------------------------------------------
-- List: Favorites
----------------------------------------------------------
local favorites_filename = props['SciteUserHome']..'\\favorites.lst'

list_favorites:on_select(function(idx)
	if idx 	~= -1 then
		fav_select_index = idx
	end
end)

list_favorites:on_double_click(function(idx)
	if idx 	~= -1 then
		open_file(list_favorites:get_item_data(idx))
	end
end)

local function fill_list_favorites()
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

fill_list_favorites()

local function save_list_favorites()
	io.output(favorites_filename)
	local list_string = table.concat(list_fav_table,'\n')
	io.write(list_string)
	io.close()
end

---------------------------------------------------------
-- List: Functions/Procedures
----------------------------------------------------------
list_func:on_double_click(function(idx)
	local pos = list_func:get_item_data(idx)
	if pos then
		editor:GotoLine(pos)
		editor.Focus = true
	end
end)

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

function fill_list_func()
	list_func:clear()
	local findPattern = Lang2RegEx[Ext2Lang[props["FileExt"]]]
	if not findPattern then
		findPattern = Lang2RegEx[Lexer2Lang[editor.LexerLanguage]]
		if not findPattern then
			findPattern = Lang2RegEx['*']
		end
	end
	local textAll = editor:GetText()
	local startPos, endPos, findString
	startPos = 1
	while true do
		startPos, endPos, findString = string.find(textAll, findPattern, startPos)
		if startPos == nil then break end
		findString = findString:gsub("[\r\n]", ""):gsub("%s+", " ")
		local line_number = editor:LineFromPosition(startPos)
		list_func:add_item(findString, line_number)
		startPos = endPos + 1
	end
end

----------------------------------------------------------
-- List: Bookmarks
----------------------------------------------------------
function list_bookmark_add(line_number)
	local line_text = editor:GetLine(line_number):gsub('%s+', ' ')
	list_bookmarks:add_item({props['BufferNumber'], line_text}, {file_path, line_number})
end

local function list_bookmark_delete(line_number)
	for i = 0, list_bookmarks:count() - 1 do
		local bookmark = list_bookmarks:get_item_data(i)
		if bookmark[1] == file_path and bookmark[2] == line_number then
			list_bookmarks:delete_item(i)
			break
		end
	end
end

local function list_bookmark_delete_all()
	for i = list_bookmarks:count()-1, 0, -1 do
		local bookmark = list_bookmarks:get_item_data(i)
		if bookmark[1] == file_path then
			list_bookmarks:delete_item(i)
		end
	end
end

list_bookmarks:on_double_click(function(idx)
	if idx 	~= -1 then
		local pos = list_bookmarks:get_item_data(idx)
		if pos then
			scite.Open(pos[1])
			editor:GotoLine(pos[2])
			editor.Focus = true
		end
	end
end)

----------------------------------------------------------
-- List: Abbreviations
----------------------------------------------------------
function fill_list_abbrev()
	function read_abbrev(file)
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
							read_abbrev(string.match(file, '.+\\')..import_file)
						end
					end
				end
			end
			abbrev_file:close() 
		end
	end

	list_abbrev:clear()
	local abbrev_filename = props['AbbrevPath']
	read_abbrev(abbrev_filename)
end

list_abbrev:on_double_click(function(idx)
	if idx~=-1 then
		local abbrev = list_abbrev:get_item_text(idx)
		local ss,se = editor.SelectionStart,editor.SelectionEnd
		local len = abbrev:len()
		editor:InsertText(ss, abbrev)
		editor:SetSel(se+len, ss+len)
		scite.MenuCommand(IDM_ABBREV)
		editor.Focus = true
	end
end)

----------------------------------------------------------
-- Events
----------------------------------------------------------
function on_switch()
	if tab_index == 0 then
		local path = props['FileDir']
		file_path = props['FilePath']
		if path == '' then return end
		if path ~= current_path then
			current_path = path
			fill_list_dir()
		end
	elseif tab_index == 1 then
		fill_list_func()
	elseif tab_index == 2 then
		fill_list_abbrev()
	end
end

-- Add user event handler OnSwitchFile
local old_OnSwitchFile = OnSwitchFile
function OnSwitchFile(file)
	local result
	if old_OnSwitchFile then result = old_OnSwitchFile(file) end
	on_switch()
	return result
end

-- Add user event handler OnOpen
local old_OnOpen = OnOpen
function OnOpen(file)
	local result
	if old_OnOpen then result = old_OnOpen(file) end
	on_switch()
	return result
end

-- Add user event handler OnUpdateUI (Call function fill_list_func)
local old_OnUpdateUI = OnUpdateUI
function OnUpdateUI()
	local result
	if old_OnUpdateUI then result = old_OnUpdateUI() end
	if tab_index == 1 then
		local line_count_new = editor.LineCount
		if line_count_new ~= line_count then
			fill_list_func()
			line_count = line_count_new
		end
	end
	return result
end

-- Add user event handler OnSendEditor
local old_OnSendEditor = OnSendEditor
function OnSendEditor(id_msg, wp, lp)
	local result
	if old_OnSendEditor then result = old_OnSendEditor(id_msg, wp, lp) end
	if id_msg == SCI_MARKERADD then
		if lp == 1 then list_bookmark_add(wp) end
	elseif id_msg == SCI_MARKERDELETE then
		if lp == 1 then list_bookmark_delete(wp) end
	elseif id_msg == SCI_MARKERDELETEALL then
		if wp == 1 then list_bookmark_delete_all() end
	end
	return result
end

-- Add user event handler OnFinalise
local old_OnFinalise = OnFinalise
function OnFinalise()
	local result
	if old_OnFinalise then result = old_OnFinalise() end
	save_list_favorites()
	return result
end
