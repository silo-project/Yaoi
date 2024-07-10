-- luajit-object
-- Original author: icyselec
-- License: see LICENSE file
-- Part of SILO Project

if not jit then
	error("Object library only supported with LuaJIT.")
end

---@version JIT
---@class Object
---@field new fun(self: Object, o?: table): table
---@field getHashCode fun(self): number?
---@field __gc? (fun(self: userdata))
local Object = {}
local debug = _G.debug or require("debug")

---@param o? table
---@nodiscard
---@return table
function Object:new (o)
	o = o or {}

	if not getmetatable(o) then
		setmetatable(o, self)
		self.__index = self
	end

	local proxy = newproxy(false)

	-- copy metamethod from base object
	o.__gc = o.__gc

	debug.setmetatable(proxy, o)
	o[proxy] = not nil

	return o
end

---@param o? table
---@nodiscard
---@return table
function Object:super (o)
	local base = assert(getmetatable(self))

	o = o or {}

	if not getmetatable(o) then
		setmetatable(o, self)
		self.__index = self
	end

	return base:new(o)
end

function Object.isInstanceOf (this, that)
	repeat
		if this == that then
			return true
		end

		this = getmetatable(this)
	until not this

	return false
end


function Object.instanceof (this, that)
	repeat
		if this == that then
			return true
		end

		this = getmetatable(this)
	until not this

	return false
end

function Object:getHashCode ()
	return tonumber(string.match(tostring(self), "0x[%x]+"))
end

Object.__gc = nil

return Object
