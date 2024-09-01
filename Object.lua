--- SPDX-License-Identifier: LGPL-2.1-only

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
--- This section only describes the fields; the description of the methods is in the beginning of each definition.
------
---## function Object.final (self)
--- This field may not exist, `self` must have been derived from `Object`.
---
--- Defines the behavior when an instance is destroyed.
--- This function shall work equally on any platform.
--- This function does not necessarily need to be defined.
------
---## function Object.__gc (self)
--- `self` can be `Object` or `userdata`.
---
--- For each instance, this metamethod will be invoked automatically upon destruction;
--- therefore, it shall not be overriden or called arbitrarily.
---@class Object
---@field final? fun(self: self)
local Object = {}

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

--[[
To quickly access fields in the base class, copy them.
--]]
---@param this Object
function Object:cache (this)
	if this then
		cache(self, this, next(self, nil))
	end

	if getmetatable(self) then
		getmetatable(self):cache(this or self)
	end
end

--- Propagate the finalization.
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
--- It is used internally, it shall not be redefined, so it is not documented.
---@private
---@param self Object | userdata
function Object:__gc ()
	self = (type(self) == 'userdata') and getmetatable(self) or self ---@cast self Object

	-- Finalizer only invokes on an instance.
	if not self:typeof(self) then
		return propagateFinalization(self, getmetatable(self))
	end
end

local function sealed (_, _) error("Attempt to instantiate a sealed object.") end

--- Called when there is no value in the hash table. If the type is cyclic, it can also cause an infinite recursive.
--- It is used internally, it shall not be redefined, so it is not documented.
---@private
---@param index any
---@return any
function Object:__index (index)
	if self then
		local value = rawget(self, index)
		if value then
			return value
		end

		return Object.__index(getmetatable(self), index)
	end
end


--- Instantiate the object or create an inherited type.
------
--- When an instance overrides a constructor, it becomes a type.
--- You can create an instance as a datatype by writing it as follows.
--- ---@class Object
--- local Object = require 'Object'
---
--- ---@class Type: Object
--- ---@field name string
--- local Type = Object:new()
---
--- --- You must override the constructor for each data type.
--- function Type:new (o)
--- 	o = self:super(o)
---
--- 	if not o:typeof(o) then
--- 		-- your custom constructor here, this is example.
--- 		print(string.format("Hello, %s!", o.name))
--- 	end
---
--- 	return o
--- end
---
--- If you want to create an instance of `Type`, you just need to change the inheritance grammar a little bit as follows.
--- local Instance = Type:new() -- `Instance` is class, does not invoke constructor.
--- local instance = Type:new{ name = "instance", } -- `instance` is instance, does invoke constructor.
---
--- If the LSP(lua-language-server) is installed, it issues a warning when an invalid field is passed to the instance constructor.
--- local nothing = Type:new{} -- Lua Diagnostics. : missing-fields
--- local invalid = Type:new{ name = 0xDEADBEEF, } -- Lua Diagnostics. : assign-type-mismatch
---
--- However, it only checks if the data types match; ignore additional fields passed.
--- local something = Type:new{ name = "something", some_invalid_field = "money", }
---
--- If you want to receive any parameters optional, do as follows.
--- ---@class Type: Object
--- ---@field nullable_value? number
---
--- Now, the warning does not appear without passing the parameters to the instance constructor.
--- local nullable = Type:new{}
---
--- Remember, luajit-object always focuses on stability rather that speed.
--- Each datatype(class) must have a constructor, except for a constructor inherited from the base type.
--- Therefore, datatypes and instances can be distinguished by the whether they have a constructor.
function Object:new (o)
	o = self:super(o, true)

	if not o:typeof(o) then
		--- Your custom constructor here, this is example.
		_ = _
	end

	return o
end

local function cons (self, o, gc)
	if not o then
		o = {
			__gc = gc and Object.__gc,
			new = Object.new,
			__index = Object.__index,
		}
		return setmetatable(o, self)
	end

	return o
end

local function tails (self, o)
	if self then
		return rawget(self, 'new')(self, tails(getmetatable(self), o))
	end

	return o
end

local function inherit (self, o)
 	if self.final and not isSupportedGc then
 		o = rawset(rawset(o, debug.setmetatable(newproxy(false), o), not nil), '__gc', Object.__gc)
 	end

	return setmetatable(cons(self, o), self)
end


--[[
Automatically invokes the constructor defined in the inheritance chain and creates a new datatype or instance.

Note this method is designed for IDE using LSPs. Without LSPs, you cannot get rich type information.

The constructor of the Object will define the default constructor for the derived datatypes; However, these default constructors will not provide information about the type.

To obtain type information, you must newly define a constructor instead of the default one.

--- 1. In our framework, it is recommended to assign that module `Object` to local variables first.
local Object = require 'Object'

--- 2. It is recommended that the path end of the datatype matches the name of the local variable, but it is not required.
---@class SomeType: Object
---@field name string
local SomeType = Object:new()

function SomeType:new (o)
	--- 3. Only the next line available type inference. Never let the value of the method be returned immediately. (return self:super(o))
	o = self:super(o)

	--- 4. This is an instance constructor, define everything you need to create an instance in it.
	if not o:typeof(o) then
		assert(o.name)
	end

	return o
end

--- 5. At the end of the file, you must return the datatype.
return SomeType

--- other files...
--- 6. If done correctly, the following variables will be inferred as SomeType.
local SomeType = require 'SomeType'

--- 7. The following code displays a warning on the LSP.
local derivedType = SomeType:new{}

--]]
---@generic T: Object
---@param self T
---@param o any
---@param ignore? boolean
---@return T
---@nodiscard
function Object:super (o, ignore)
	-- If Datatype
	if not o then
		return setmetatable(cons(self, nil, true), self)
	-- If Instance
	elseif not getmetatable(o) then
		assert(rawget(self, 'new'), "Attempt to instantiate an instance.")
		o = inherit(self, o)

		if not ignore then
			return tails(getmetatable(self), o)
		end
	end

	return o
end

function Object:base () end

--- Seal the instance.
------
--- so that it is no longer derived.
---@return self
---@nodiscard
function Object:sealed () return rawset(self, 'new', sealed) end

--- Find out which type the object belongs to.
------
--- It can be used as follows.
---* Examine which type inherits a particular type: SomeType:typeof(Object) -- is SomeType inherit Object?
---* Instance check: print(Type:typeof(Type), Instance:typeof(Instance)) -- it prints "true, false"
--- Distinguish which objects are datatypes(classes) or instances.
--- local Object = require 'Object'
---
--- local objA = Object:new() -- is datatype
--- local objB = Object:new{} -- is instance
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
function Object:typeof (that)
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

return Object
