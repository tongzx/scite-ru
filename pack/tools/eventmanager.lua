--[[-----------------------------------------------------------------
eventmanager.lua
Authors: Tymur Gubayev
version: 1.0.0
---------------------------------------------------------------------
  Description:
	simple event manager realization for SciTE.
	exported functions (self-descriptive):
	  * AddEventHandler ( EventName, Handler[, RunOnce] )
	  * RemoveEventHandler ( EventName, Handler )
	
	простейший менеджер событий для SciTE
	экспортирует две функции (см. выше)
  
  Подключение:
	не требуется (загружается из COMMON.lua).
  Если же по каким-либо причинам необходимо подключение вручную, то:
    В файл SciTEStartup.lua добавьте строку:
    dofile (props["SciteDefaultHome"].."\\tools\\eventmanager.lua")
	(перед подключением скриптов, использующих AddEventHandler)

---------------------------------------------------------------------
History:
	* 1.0 initial release

--]]-----------------------------------------------------------------


local events  = {}
local _remove = {}

--- Удаляет обработчики, намеченные для удаления
-- В конце обнуляет список "к удалению"
local function RemoveAllOutstandingEventHandlers()
	for i = 1, #_remove do
		local t_rem, h_rem = events[_remove[i].EventName], _remove[i].Handler
		for j = 1, #t_rem do
			if t_rem[j]==h_rem then
				table.remove(h_rem, j)
				break -- remove only one handler instance
			end
		end
	end -- @todo: feel free to optimize this cycle
	_remove = {} -- clear it
end

--- Запускает обработку события согласно /scite-ru/wiki/SciTE_Events
-- Возвращает всё, что вернул обработчик, а не только первый аргумент (флаг остановки)
local function Dispatch (name, ...)
	RemoveAllOutstandingEventHandlers() -- first remove all from _remove
	local event = events[name]
	local res
	for i = 1, #event do
		res = { event[i](...) } -- store whole handler return in a table
		if res[1] then -- first returned value is a interruption flag
			return unpack(res)
		end
	end
	return unpack(res) -- just for the case of error-handling
end

--- Создаёт новый обработчик для вызова ядром редактора
-- В случае, если такая функция уже имеется (т.е. была создана без использования AddEventHandler),
-- то она ставится первой в очередь
local function NewDispatcher(EventName)
	
	local dispatch = function (...) -- `shortcut`
		return Dispatch(EventName, ...)
	end
	
	-- just for the case some handler was defined in other way before
	local old_handler = _G[EventName]
	if old_handler then
		AddEventHandler(EventName, old_handler) -- @todo: can this recurse?
	end
	
	_G[EventName] = dispatch
end

--- Подключает пользовательский обработчик к событию SciTE (последним по счёту)
-- параметр `RunOnce` опционален, по-умолчанию `false`
function AddEventHandler(EventName, Handler, RunOnce)
	local event = events[EventName]
	if not event then
		-- create new event array
		events[EventName] = {}
		event = events[EventName]
		-- register base event dispatcher
		NewDispatcher(EventName)
	end
	
	if not RunOnce then
		event[#event+1] = Handler
	else
		event[#event+1] = function(...)
			RemoveEventHandler(EventName, Handler)
			return Handler(...)
		end
	end
	
end -- AddEventHandler

--- Отключает обработчик от события
-- Если один обработчик подключён к одному событию дважды, то и удалять его надо дважды
function RemoveEventHandler(EventName, Handler)
	_remove[#_remove+1]={EventName=EventName, Handler=Handler}
end
