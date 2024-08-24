-- execute this file with "love ."

-- basic definition
local Object = require("Object")

-- Test 1. Automatic garbage-collect
do
	local File = Object:new()
	function File:new (o)
		o = self:super(o)
		assert(o.filename)
		o.handle = io.open(o.filename, "rb")

		return o
	end

	function File:__gc ()
		local this = getmetatable(self)

		if this == self then
			print("equal")
			return
		end

		print("Alert: a File " .. this.filename .. " is now closed.")
	end

	local f = File:new{
		filename = "main.lua",
	}

	f = nil
	collectgarbage()
end

-- Test 2. Constructor chaining and run isInstanceOf
do
	local ClassA = Object:new()
	local ClassB = ClassA:new()
	local ClassC = ClassB:new()
	local ClassX = ClassA:new()

	local function kindTest (a, b)
		if a:isInstanceOf(b) then
			print("a is kind of b.")
		else
			print("a is not kind of b")
		end
	end

	function ClassA:new (o)
		o = self:super(o)
		print("This is ClassA!")
		return o
	end

	function ClassB:new (o)
		o = self:super(o)
		print("This is ClassB!")
		return o
	end

	function ClassC:new (o)
		o = self:super(o)
		print("This is ClassC!")
		return o
	end

	function ClassX:new (o)
		o = self:super(o)
		print("This is ClassX")
		return o
	end

	kindTest(ClassC, ClassA)
	kindTest(ClassB, Object)
	kindTest(ClassA, ClassX)
	kindTest(ClassX, ClassA)
end

_ = Object:super()

os.exit(0)
