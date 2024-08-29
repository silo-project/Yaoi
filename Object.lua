---	SPDX-License-Identifier: LGPL-2.1-only

local newproxy = newproxy
local getmetatable, setmetatable = getmetatable, setmetatable
local type = type
local rawget, rawset = rawget, rawset
local assert = assert

local isSupportedGc = not newproxy
local debug = (not isSupportedGc) and require 'debug'

---	Origin of all objects.
------
---	This section only describes the fields; the description of the methods is in the beginning of each definition.
------
---## function Object.final (self)
---	This field may not exist, `self` must have been derived from `Object`.
---
---	Defines the behavior when an instance is destroyed.
---	This function shall work equally on any platform.
---	This function does not necessarily need to be defined.
------
---## function Object.__gc (self)
---	`self` can be `Object` or `userdata`.
---
---	For each instance, this metamethod will be invoked automatically upon destruction;
---	therefore, it shall not be overriden or called arbitrarily.
---@class Object
---@field final? fun(self: self)
local Object = {}

local function finalize (base, self)
	if base then
		base(self)
	end
end

local function getFinalizer (self, base)
	if base then
		return getFinalizer(self, getmetatable(base), finalize(rawget(base, 'final'), self))
	end
end

---@param self Object | userdata
local function gc (self)
	self = (type(self) == 'userdata') and getmetatable(self) or self ---@cast self Object

	-- Finalizer only invokes on an instance.
	if not rawget(self, 'new') then
		return getFinalizer(self, getmetatable(self))
	end
end

local function sealed (_, _) error("Attempt to instantiate a sealed object.") end

local function getfield (t, k)
	if not rawget(t, k) then
		return getfield(getmetatable(t), k)
	end

	return rawget(t, k)
end

function Object.__index (t, k)
	if t then
		if rawget(t, k) then
			return rawget(t, k)
		end

		if not rawget(t, '__index') then
			print(t)
		end

		return rawget(t, '__index')(getmetatable(t), k)
	end
end

Object.__gc = gc

---	Instantiate the object or create an inherited type.
------
---	When an instance overrides a constructor, it becomes a type.
---	You can create an instance as a datatype by writing it as follows.
---	---@class Object
---	local Object = require 'Object'
---
---	---@class Type: Object
---	---@field name string
---	local Type = Object:new()
---
---	--- You must override the constructor for each data type.
---	function Type:new (o)
---		o = self:super(o)
---
---		if o:typeof(o) then
---			-- your custom constructor here, this is example.
---			print(string.format("Hello, %s!", o.name))
---		end
---
---		return o
---	end
---
---	If you want to create an instance of `Type`, you just need to change the inheritance grammar a little bit as follows.
---	local Instance = Type:new() -- `Instance` is class, does not invoke constructor.
---	local instance = Type:new{ name = "instance", } -- `instance` is instance, does invoke constructor.
---
---	If the LSP(lua-language-server) is installed, it issues a warning when an invalid field is passed to the instance constructor.
---	local nothing = Type:new{} -- Lua Diagnostics. : missing-fields
---	local invalid = Type:new{ name = 0xDEADBEEF, } -- Lua Diagnostics. : assign-type-mismatch
---
---	However, it only checks if the data types match; ignore additional fields passed.
--- local something = Type:new{ name = "something", some_invalid_field = "money", }
---
---	If you want to receive any parameters optional, do as follows.
---	---@class Type: Object
---	---@field nullable_value? number
---
---	Now, the warning does not appear without passing the parameters to the instance constructor.
---	local nullable = Type:new{}
---
---	Remember, luajit-object always focuses on stability rather that speed.
function Object:new (o)
	o = self:super(o)

	return o
end

local function cons (o)
	if not o then
		return {
			__index = Object.__index,
			__gc = Object.__gc,
			new = Object.new,
		}
	end

	rawset(o, '__index', Object.__index)
	rawset(o, '__gc', Object.__gc)

	return o
end

local function tails (self, o)
	if self then
		return rawget(self, 'new')(self, tails(getmetatable(self), o))
	else
		return o
	end
end

local function inherit (self, o)
	if not isSupportedGc then
		o[debug.setmetatable(newproxy(false), o)] = not nil
	end

	return setmetatable(cons(o), self)
end

---@generic T: Object
---@param self T
---@param o any
---@return T
---@nodiscard
function Object:super (o)
	-- If Datatype
	if not o then
		return setmetatable(cons(), self)
	-- If Instance
	else
		assert(rawget(self, 'new'), "Attempt to instantiate an instance.")
		if not getmetatable(o) then
			return tails(getmetatable(self), inherit(self, o))
		else
			return o
		end
	end
end

---	Seal the instance.
------
---	so that it is no longer derived.
---@return self
---@nodiscard
function Object:sealed () return rawset(self, 'new', sealed) end

---	Find out which type the object belongs to.
------
---	It can be used as follows.
---* Examine which type inherits a particular type: SomeType:typeof(Object) -- is SomeType inherit Object?
---* Instance check: print(Type:typeof(Type), Instance:typeof(Instance)) -- it prints "true, false"
---@param that any
---@return boolean
function Object:typeof (that)
	that = that or Object

	if rawget(self, 'new') then
		repeat
			if self == that and rawget(that, 'new') then return true end

			self = getmetatable(self)
		until not self

		error("Type is unreachable.")
	end

	return false
end

function Object:typeOf (that)
	if self then
		if rawget(self, 'new') then
			if self == that and rawget(that, 'new') then
				return true
			else
				return Object.typeOf(getmetatable(self), that)
			end
		end

		return false
	end

	return nil
end

return Object
