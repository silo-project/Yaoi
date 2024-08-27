# luajit-object
Automatic Garbage-collectable, Object-oriented programming(OOP) library for Lua.

In LuaJIT, many libraries exist to assist OOP, but i didn't like any of them. So, I created it by myself. For LuaJIT, An OOP class module that can GC automatically!

## Table of Contents
- [Compatibility](#compatibility)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Compatibility
luajit-object is well compatible with Lua 5.2 and later versions. It may behave slightly differently, but it also works well with LuaJIT.

## Installation
Just download the Object.lua file and put it in the top-level directory of the project. Alternatively, put it in the directory you want and set the appropriate path.

After that, you can enter the following in the source code to use it.
```lua
local Object = require 'Object'
```

## Usage
Let me show you a simple example.
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

function DerivedClass:final ()
  print(tostring(self) .. " is terminated")
end

local obj = DerivedClass:new() -- 'Hello, world!'
obj = nil
collectgarbage() -- 'table: ? is terminated'
```

## Contributing
Anyone can contribute to this library, but please read the license below first.

## License
> Automatic Garbage-collectable, Object-oriented programming(OOP) library for Lua.
> 
> Copyright (C) 2024  SILO Project
>
> This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.
>
> This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
>
> You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

