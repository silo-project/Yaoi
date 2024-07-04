# luajit-object
Garbage-collectable Object library for LuaJIT.

In LuaJIT, many modules exist to assist object-oriented programming(OOP), but i did not like any of them. So, I created it by myself. For LuaJIT, An OOP class module that can GC automatically!

# How to use?
Like this,
```lua
local Object = require("Object")

local DerivedClass = Object:new()
function DerivedClass:new (o)
  o = self:super(o)
  -- your source codes here
  -- this is example
  print("Hello, world!")
  return o
end

function DerivedClass:__gc ()
  local this = getmetatable(self)
  print(tostring(this) .. " is terminated")
end


local obj = DerivedClass:new() -- 'Hello, world!'
obj = nil
collectgarbage() -- 'table: ? is terminated'
```

# Is it Possible to use it for a personal project? (for example, I want to use this library to make a game.)
Yes, It is possible. First, read the license, and the important thing to know is that this library is part of a big project. In other words, it's basically designed for a SILO project, and we're not responsible for any side effects that come from other uses.
