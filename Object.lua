-- SPDX-License-Identifier: LGPL-2.1-only
-- luajit-object
-- Original author: icyselec
-- Part of SILO Project

local isSupportedGc = not newproxy
local debug = (not isSupportedGc) and require 'debug'

---@class Object
---@field final? fun(self: self)
local Object = {}

---@generic T
---@param self T
---@param o any
---@return T
---@nodiscard
function Object:new (o)
	assert(rawget(self, 'new'), "Attempt to instantiate an instance.")
	o = o or {}

	if not getmetatable(o) then
		self.__gc = self.__gc
		o.__gc = self.__gc

		if not isSupportedGc then
			o[debug.setmetatable(newproxy(false), o)] = not nil
		end

		setmetatable(o, self)
		self.__index = self
		self.__metatable = self
	end

	local base = getmetatable(self)
	return base and base:new(o) or o
end

Object.super = Object.new

---@generic T
---@param self T
---@return T
---@nodiscard
function Object:static ()
	self.new = self.new or Object.new
	return self
end

---@param that any
---@return boolean
function Object:instanceof (that)
	that = that or Object

	if not rawget(self, 'new') then
		repeat
			if self == that then return true end

			self = getmetatable(self)
		until not self
	end

	return false
end

---@private
---@param self Object | userdata
function Object:__gc ()
	self = (type(self) == 'userdata') and getmetatable(self) or self ---@cast self Object

	-- If not a instance, then return immediately.
	if rawget(self, 'new') then return end

	---@type Object
	local base = getmetatable(self)

	while base do
		if base.final then base.final(self) end

		base = getmetatable(base) --[[@as Object]]
	end
end

return Object
