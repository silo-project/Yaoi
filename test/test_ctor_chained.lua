local Object = require 'Object'

local YearX = Object:extend()
function YearX:new (o)
	o = self:super(o)

	o.x = o.x or 78

	return o
end

local YearY = YearX:extend()
function YearY:new (o)
	o = self:super(o)

	o.y = o.y or 6

	return o
end

local YearZ = YearY:extend()
function YearZ:new (o)
	o = self:super(o)

	o.z = o.z or 4

	return o
end

local year = YearZ:new{}
print(year.x, year.y, year.z)
