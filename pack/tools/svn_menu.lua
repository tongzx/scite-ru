--[[
Eng: Creating SVN commands submenu in tab context menu
Rus: —оздает в контекстном меню таба (закладки) подменю дл€ команд SVN
Version: 1.0
Author: VladVRO

Using:
Add next line to lua startup file (SciTEStartup.lua):
	dofile ("svn_menu.lua")
]]
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- SVN menu
local SVNContectMenu =
  "||"..
	"SVN|POPUPBEGIN|"..
	"Update|9181|"..
	"CommitЕ|9182|"..
	"RevertЕ|9183|"..
	"Show log|9184|"..
	"$(BranchMenuCommands)"..
	"||"..
	"Update All|9188|"..
	"Commit AllЕ|9189|"..
	"Show log for All|9190|"..
	"SVN|POPUPEND|"
local BranchMenuCommands =
	"||"..
	"Update 'trunk'|9185|"..
	"Commit 'trunk'Е|9186|"..
	"Show log for 'trunk'|9187|"

local function svn_menu(file)
	local menu = props["user.tabcontext.menu"]
	local filedir = props["FileDir"]
	local svnroot = ""
	local svnbranch = ""
	-- test SVN context
	if os.getfileattr(filedir.."\\.svn") or os.getfileattr(filedir.."\\_svn") then
		-- file in SVN context
		svnroot = filedir
		local branchmenu = ""
		local child = ""
		-- find SVN branch/trunk and root
		repeat
			local _,_,parent,name = string.find(svnroot, "(.*)\\([^\\]+)")
			if name == "trunk" then
				svnbranch = svnroot
				branchmenu = BranchMenuCommands
			elseif name == "branches" then
				svnbranch = child
				local _,_,branchname = string.find(svnbranch, ".*\\([^\\]+)")
				branchmenu = string.gsub(BranchMenuCommands, "trunk", branchname)
			end
			if parent then
				if os.getfileattr(parent.."\\.svn") or os.getfileattr(parent.."\\_svn") then
					child = svnroot
					svnroot = parent
				else
					break
				end
			end
		until not parent
		-- set menu
		if not string.find(menu,"|||SVN|") then
			menu = menu.."||SVN||"
		end
		props["user.tabcontext.menu"] =
			string.gsub(menu, "||SVN|.*", string.gsub(SVNContectMenu, "$%(BranchMenuCommands%)", branchmenu))
	else
		-- no SVN context
		if string.find(menu,"|||SVN|") then
			props["user.tabcontext.menu"] = string.gsub(menu, "||SVN|.*", "")
		end
	end
	-- set variables for SVN menu
	props["SVNRoot"] = svnroot
	props["SVNCurrentBranch"] = svnbranch
end

-- ƒобавл€ем свой обработчик событи€ OnOpen
local old_OnOpen = OnOpen
function OnOpen(file)
	local result
	if old_OnOpen then result = old_OnOpen(file) end
	svn_menu(file)
	return result
end

-- ƒобавл€ем свой обработчик событи€ OnSwitchFile
local old_OnSwitchFile = OnSwitchFile
function OnSwitchFile(file)
	local result
	if old_OnSwitchFile then result = old_OnSwitchFile(file) end
	svn_menu(file)
	return result
end
