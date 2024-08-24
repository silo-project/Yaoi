-- luajit-object
-- Original author: icyselec
-- License: LGPL-2.1-only
-- Part of SILO Project

local isSupportedGc = not jit
local debug = (not isSupportedGc) and require 'debug'

---@class Object
local Object = {}

local function inherit (this, that)
	if not getmetatable(this) then
		this.__gc = that.__gc

		setmetatable(this, that)
		that.__index = that
	end

	return this
end

---@param o? table
---@return table
---@nodiscard
function Object:new (o)
	o = inherit(o or {}, self)

	if not isSupportedGc then
		o[debug.setmetatable(newproxy(false), o)] = not nil
	end

	return o
end

---@param o? table
---@return table
---@nodiscard
function Object:super (o)
	local base = assert(getmetatable(self))

	return base:new(inherit(o or {}, self))
end

---@param this table
---@param that table
---@return boolean
function Object.instanceof (this, that)
	while this do
		this = getmetatable(this)

		if this == that then return true end
	end

	return false
end

---@return number?
function Object:getHashCode ()
	return tonumber(string.match(tostring(self), "0x[%x]+"))
end

---@private
function Object:__gc ()
	self = (type(self) == 'userdata') and getmetatable(self) or self

	local base = getmetatable(self)

	while base do
		if base.final then base.final(self) end

		base = getmetatable(base)
	end
end

return Object
