-- luajit-object
-- Original author: icyselec
-- License: LGPL-2.1-only
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

local function inherit (this, that) if not getmetatable(this) then setmetatable(this, that); that.__index = that end end

---@param o? table
---@return table
---@nodiscard
function Object:new (o)
	o = o or {}

	inherit(o, self)

	-- copy metamethod from base object
	o.__gc   = o.__gc
	o.__call = o.__call

	o[debug.setmetatable(newproxy(false), o)] = not nil

	return o
end

---@param o? table
---@return table
---@nodiscard
function Object:super (o)
	local base = assert(getmetatable(self))

	o = o or {}

	inherit(o, self)

	return base:new(o)
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
