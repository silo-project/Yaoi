--- Yet Another Object Implementation, for Lua.
--- Copyright (C) 2024  icyselec
---
--- This library is free software; you can redistribute it and/or
--- modify it under the terms of the GNU Lesser General Public
--- License as published by the Free Software Foundation; either
--- version 2.1 of the License, or (at your option) any later version.
---
--- This library is distributed in the hope that it will be useful,
--- but WITHOUT ANY WARRANTY; without even the implied warranty of
--- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--- Lesser General Public License for more details.
---
--- You should have received a copy of the GNU Lesser General Public
--- License along with this library; if not, write to the Free Software
--- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

local newproxy = newproxy
local getmetatable, setmetatable = getmetatable, setmetatable
local type = type
local rawget, rawset = rawget, rawset
local assert = assert

local isSupportedGc = not newproxy
local debug = (not isSupportedGc) and require 'debug'

local cachingIgnores = {
	new = true,
	final = true,
}

--- Origin of all objects.
------
--- The most recommended coding convention in our framework is to define only one class in one file.
--- Of course, it is not a must.
--- Here is the template file, copy and use it.
--[[
local Object = require 'Yaoi'

---@class SampleObject: Yaoi
---@field mustneed  any
---@field optional? any
local SampleObject = Object:def()

function SampleObject:new (o)
	o = self:base(o)

	assert(o.mustneed)
	o.optional = o.optional or 42

	return o
end

return SampleObject
--]]
---@class Yaoi
---@field final? fun(self: self)
local Yaoi = {}

---@generic T
---@param self T
---@param o any
---@return T
function Yaoi:def (o)
	assert(rawget(self, 'def'), "Attempt to extend a sealed object.")

	if not o then
		o = {
			__index = Yaoi.__index,
			__gc = Yaoi.__gc,
			new = Yaoi.new,
			def = Yaoi.def,
			base = Yaoi.base,
		}
	elseif not getmetatable(o) then
		o = rawset(rawset(rawset(rawset(o, '__index', Yaoi.__index), '__gc', Yaoi.__gc), 'new', Yaoi.new), 'def', Yaoi.def)
	end

	return setmetatable(o, self)
end

local function cache (self, this, index)
	if not index then
		return this
	end

	if not rawget(this, index) then
		if not cachingIgnores[index] then
			return cache(self, rawset(this, index, rawget(self, index)), next(self, index))
		end
	end

	return cache(self, this, next(self, index))
end


--- To quickly access fields in the base class, copy them.
---@param this Yaoi
function Yaoi:cache (this)
	if this then
		cache(self, this, next(self, nil))
	end

	if getmetatable(self) then
		getmetatable(self):cache(this or self)
	end
end

---@return nil
local function propagateFinalization (self, base)
	if base then
		if rawget(base, 'final') then
			rawget(base, 'final')(self)
		end

		return propagateFinalization(self, getmetatable(base))
	end
end

--- Automatically invokes the finalizer defined in the inheritance chain.
--- ## function Yaoi:final ()
--- self must be an `Yaoi`
---
--- When the inheritance chain contains finalizers, there is considerable performance degradation when an instance is finalized. (or GC-ed.)
--- Therefore, careful consideration is important when defining finalizers.
---@private
---@param self Yaoi | userdata
function Yaoi:__gc ()
	self = (type(self) == 'userdata') and getmetatable(self) or self ---@cast self Yaoi

	-- Finalizer only invokes on an instance.
	if not self:typeof(self) then
		return propagateFinalization(self, getmetatable(self))
	end
end

--- Called when there is no value in the hash table. If the type is cyclic, it can also cause an infinite recursive.
--- It is used internally, it shall not be redefined, so it is not documented.
---@private
---@param index any
---@return any
function Yaoi:__index (index)
	if self then
		local value = rawget(self, index)
		if value then
			return value
		end

		return Yaoi.__index(getmetatable(self), index)
	end
end

--- Front-end function that fires the constructor chain
--- Because defining a class using annotations is like writing the constructor's parameters, this method should not have any annotations. All information is included in the class definition.
function Yaoi:new (o)
	o = self:base(o or {})

	return o
end

local function tails (self, o)
	if self then
		return rawget(self, 'new')(self, tails(getmetatable(self), o))
	end

	return o
end

--- This method is used to define a constructor; therefore, it should not be called arbitrarily.
--- The correct way to call this method is to call directly from the newly defined constructor.
--- Invoking this method outside of the class's constructor definition is an undefined-behavior.
---
--- If the inheritance chain is too long and takes too long to initialize the object, you can try to 'Constructor chain reconstruction'.
--- Tips: To enable this feature, pass the `true` value to the second parameter of `base` method.
---
--- ***Note*** this feature allows you to use it under the condition that you know everything about all base types.
--- If there's anything you don't know at all, We recommend you not to use it because it's an unsafe feature.
---
--- The following code is an example using constructor chain reconstruction.
--[[
local Yaoi = require 'Yaoi'

---@class First: Yaoi
---@field x number
local First = Yaoi:def()

function First:new (o)
	o = self:base(o)

	assert(o.x)

	return o
end

---@class Second: First
---@field y number
local Second = First:def()

function Second:new (o)
	o = self:base(o)

	assert(o.y)

	return o
end

---@class Third: Second
---@field z number
local Third = Second:def()

function Third:new (o)
	o = self:base(o, true)

	-- You can do all the required initializations in `First` and `Second` in one place.
	assert(o.x and o.y and o.z)

	return o
end

local third = Third:new{x = 1, y = 2, z = 3,}
--]]
--- when using this feature, Dramatic performance improvements can be achieved with longer inheritance chains.
--- but it is more important not to create such a long inheritance chain in the first place.
---@protected
---@generic T: Yaoi
---@param self T
---@param o table
---@param recons? boolean
---@return T
---@nodiscard
function Yaoi:base (o, recons)
	o = o or {}

	if not getmetatable(o) then
		assert(rawget(self, 'new'), "Attempt to instantiate an instance.")

		if rawget(self, 'final') and not isSupportedGc then
			o = rawset(rawset(o, debug.setmetatable(newproxy(false), o), not nil), '__gc', Yaoi.__gc)
		end

		o = setmetatable(o, self)

		if not recons then
			return tails(getmetatable(self), o)
		end
	end

	return o
end


--- Find out which type the object belongs to.
------
--- It can be used as follows.
---* Examine which type inherits a particular type: SomeType:typeof(Yaoi) -- is SomeType inherit Yaoi?
---* Instance check: print(Type:typeof(Type), Instance:typeof(Instance)) -- it prints "true, false"
--- Distinguish which objects are datatypes(classes) or instances.
--- local Yaoi = require 'Yaoi'
---
--- local objA = Yaoi:def() -- is datatype
--- local objB = Yaoi:new() -- is instance
---
--- local function printKind (t)
---     if t:typeof(t) then
---         print("datatype")
---     else
---         print("instance")
---     end
--- end
---
--- printKind(objA) -- "datatype"
--- printKind(objB) -- "instance"
---@param that any
---@return boolean | nil
function Yaoi:typeof (that)
	that = that or self

	if self then
		if rawget(self, 'new') then
			if self == that and rawget(that, 'new') then
				return true
			else
				return self.typeof(getmetatable(self), that)
			end
		end

		return false
	end

	return nil
end

return Yaoi
