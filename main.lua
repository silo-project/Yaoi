-- execute this file with "love ."

-- basic definition
local Object = require("Object")

-- Test 1. Automatic garbage-collect
do
	local function File_gc (self)
		print(self)
		print("Thril is gone.")
	end

	local File = Object:new{}

	function File:new (o)
		o = self:super(o)
		assert(o.filename)
		o.handle = io.open(o.filename, "rb")

		return o
	end

	File.final = File_gc


	local f = File:new{
		filename = "main.lua",
	}
	f = nil
	collectgarbage()
end
collectgarbage()

-- Test 2. Constructor chaining and run isInstanceOf
do
	local ClassA = Object:new()
	local ClassB = ClassA:new()
	local ClassC = ClassB:new()
	local ClassX = ClassA:new()

	local function kindTest (a, b)
		if a:instanceof(b) then
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

-- Test 3. GC chaining
do
	local ClassA = Object:new()
	local ClassB = ClassA:new()
	local ClassC = ClassB:new()

	function ClassA:final ()
		print("ClassA is gone.")
	end

	function ClassB:final ()
		print("ClassB is gone.")
	end

	function ClassC:final ()
		print("ClassC is gone.")
	end

	local class = ClassC:new()

	class = nil
	collectgarbage()
end
collectgarbage()

os.exit(0)
