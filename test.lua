local Origin = require 'Origin'

---@class test.First: Origin
---@field needed string
local First = Origin:def()

function First:new (o)
	o = self:super(o)

	print("First's constructor is called.")

	return o
end

function First:final ()
	io.stderr:write("First's finalizer is called.\n")
end

---@class test.Second: test.First
local Second = First:def()

function Second:new (o)
	o = self:super(o)

	print("Second's constructor is called.")

	return o
end

function Second:final ()
	io.stderr:write("Second's finalizer is called.\n")
end

---@class test.Third: test.Second
local Third = Second:def()

function Third:new (o)
	o = self:super(o)

	print("Third's constructor is called.")

	return o
end

function Third:final ()
	io.stderr:write("Third's finalizer is called.\n")
end

local third = Third:new()

assert(not rawget(third, 'new'))
_ = third
---@diagnostic disable-next-line
third = nil
collectgarbage()

