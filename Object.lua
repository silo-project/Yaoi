-- luajit-object
-- Original author: icyselec
-- License: LGPL-2.1-only
-- Part of SILO Project

local isSupportedGC = not jit
local debug = _G.debug or require("debug")

---@class Object
---@field new fun(self: self, o?: table): table
---@field getHashCode fun(self: self): number?
---@field final fun(self: self | userdata)
---@field __gc? (fun(self: userdata))
local Object = {}


local function inherit (self, that)
	if not getmetatable(self) then
		-- copy metamethod from base object
		self.__gc   = that.__gc
		self.__call = that.__call

		setmetatable(self, that)
		that.__index = that
	end

	return self
end

---@param o? table
---@return table
---@nodiscard
function Object:new (o)
	o = inherit(o or {}, self)

	if not isSupportedGC then
		o[debug.setmetatable(newproxy(false), o)] = not nil
	end

	return o
end

---@param o? table
---@return table
---@nodiscard
function Object:super (o) return assert(getmetatable(self)):new(inherit(o or {}, self)) end

---@param this table
---@param that table
---@return boolean
function Object.instanceof (this, that)
	repeat
		if this == that then return true end

		this = getmetatable(this)
	until not this

	return false
end

---@return number?
function Object:getHashCode ()
	return tonumber(string.match(tostring(self), "0x[%x]+"))
end

Object.__gc = nil

return Object
