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
---@field __gc (fun(self: userdata))|nil
local Object = {}
local debug = _G.debug or require("debug")

---@param o? table
---@nodiscard
---@return table
function Object:new (o)
	o = o or {}
	self.asGC(self:extend(o), o)

	return o
end

---@private
---@param o table
---@return Object
function Object:extend (o)
	local that = getmetatable(o)

	if not that then
		setmetatable(o, self)
		self.__index = self

		return self
	end

	return that
end

---@private
---@param that Object # inheritanced from
---@param o Object # gc trigger object
function Object.asGC (that, o)
	local proxy = newproxy(false)

	-- copy metamethod from base object
	that.__gc = that.__gc

	debug.setmetatable(proxy, that)
	o[proxy] = not nil
end

---@return Object?
function Object:base ()
	return getmetatable(self)
end

---@param o? table
---@nodiscard
---@return table
function Object:super (o)
	local base = assert(self:base())

	o = o or {}
	self:extend(o)

	return base:new(o)
end

---@return string
function Object:toString ()
	return tostring(self)
end

function Object:getHashCode ()
	return tonumber(string.match(tostring(self), "0x[%x]+"))
end

Object.__gc = nil

return Object
