-- SPDX-License-Identifier: LGPL-2.1-only
-- luajit-object
-- Original author: icyselec
-- Part of SILO Project

local isSupportedGc = not newproxy
local debug = (not isSupportedGc) and require 'debug'

---@class Object
local Object = {}

local function default (self, o) return self:super(o or {}) end

local function inherit (this, that)
	if not getmetatable(this) then
		that.__gc = that.__gc
		this.__gc = that.__gc

		if not isSupportedGc then
			this[debug.setmetatable(newproxy(false), this)] = not nil
		end

		setmetatable(this, that)
		that.__index = that
	end

	return this
end

---@param o? table
---@return table
---@nodiscard
function Object:new (o)
	return inherit(o or {}, self)
end

function Object:extend (o)
	assert(not getmetatable(o), "table expected.")
	o = o or {}

	o.new = o.new or default

	setmetatable(o, self)
	self.__index = self

	return o
end

---@param o? table
---@return table
---@nodiscard
function Object:super (o)
	return assert(getmetatable(self)):new(inherit(o or {}, self))
end

---@param that table
---@return boolean
function Object:instanceof (that)
	repeat
		if self == that then return true end

		self = getmetatable(self)
	until not self

	return false
end

---@private
function Object:__gc ()
	self = (type(self) == 'userdata') and getmetatable(self) or self

	-- If not a instance, then return immediately.
	if rawget(self, 'new') then return end

	local base = getmetatable(self)

	while base do
		if base.final then base.final(self) end

		base = getmetatable(base)
	end
end

return Object
