local Object = require 'Object'

---@class test.First: Object
local First = Object:new()

function First:new (o)
	o = self:super(o)

	return o
end

function First:final ()
	io.stderr:write("First's finalizer is called.\n")
end

---@class test.Second: test.First
local Second = First:new()

function Second:new (o)
	o = self:super(o)

	return o
end

function Second:final ()
	io.stderr:write("Second's finalizer is called.\n")
end

---@class test.Third: test.Second
local Third = Second:new()

function Third:new (o)
	o = self:super(o)

	return o
end

function Third:final ()
	io.stderr:write("Third's finalizer is called.\n")
end

local third = Third:new{}
third = nil
collectgarbage()



