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

local function cache (self, this, index)
	if not index then
		return this
	end

	if not rawget(this, index) then
		if index ~= 'new' and index ~= 'final' then
			return cache(self, rawset(this, index, rawget(self, index)), next(self, index))
		end
	end

	return cache(self, this, next(self, index))
end

function Object:cache (this)
	if this then
		cache(self, this, next(self, nil))
	end

	if getmetatable(self) then
		getmetatable(self):cache(this or self)
	end
end

local function getFinalizer (self, base)
	if base then
		if rawget(base, 'final') then
			rawget(base, 'final')(self)
		end

		return getFinalizer(self, getmetatable(base))
	end
end

---@param self Object | userdata
function Object:__gc ()
	self = (type(self) == 'userdata') and getmetatable(self) or self ---@cast self Object

	-- Finalizer only invokes on an instance.
	if not rawget(self, 'new') then
		return getFinalizer(self, getmetatable(self))
	end
end

local function sealed (_, _) error("Attempt to instantiate a sealed object.") end

---@param name string
---@return any
function Object:__index (name)
	if self then
		if rawget(self, name) then
			return rawget(self, name)
		end

		return rawget(self, '__index')(getmetatable(self), name)
	end
end


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

	if not o:typeof(o) then
		--- Your custom constructor here, this is example.
		_ = _
	end

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
	end

	return o
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
---@param override? boolean
---@return T
---@nodiscard
function Object:super (o, override)
	-- If Datatype
	if not o then
		return setmetatable(cons(), self)
	-- If Instance
	elseif not getmetatable(o) then
		assert(rawget(self, 'new'), "Attempt to instantiate an instance.")
		if override then
			return inherit(self, o)
		end

		return tails(getmetatable(self), inherit(self, o))
	end

	return o
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
---@return boolean | nil
function Object:typeof (that)
	if self then
		if rawget(self, 'new') then
			if self == that and rawget(that, 'new') then
				return true
			else
				return Object.typeof(getmetatable(self), that)
			end
		end

		return false
	end

	return nil
end

return Object
