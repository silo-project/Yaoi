local Object = require 'Object'

local ClassA = Object:extend()
local ClassB = ClassA:extend()
local ClassC = ClassB:extend()

function ClassA:final ()
	print "ClassA is gone."
end

function ClassB:final ()
	print "ClassB is gone."
end

function ClassC:final ()
	print "ClassC is gone."
end

local class = ClassC:new()
