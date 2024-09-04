# Yaoi
Yet Another Object Implementation (Yaoi) is a framework that provides an object-oriented paradigm for Lua.

In LuaJIT, many libraries exist to assist OOP, but i didn't like any of them. So, I created it by myself. For LuaJIT, An OOP class module that can GC automatically!

## Table of Contents
- [Feature](#feature)
- [History](#history)
- [Compatibility](#compatibility)
- [Installation](#installation)
- [Usage](#usage)
- [Performance](#performance)
- [Contributing](#contributing)
- [License](#license)

## Feature
1. Intuitive architecture and design make maintenance easier.
2. compatibility across different Lua versions easy.

## History
I first designed this module for a long-delayed digital logic circuit simulator in July 2024, when the basic concepts were established. However, the project was interrupted again shortly after, leaving the module again.

Since then, I've been using this a lot for a number of internal projects that haven't even been public, and it's getting more and more functional, and it's starting to take on the burden of performance.

So my attempt was completely different and improved the performance, which successful and effective. And to celebrate the 2nd month, i named this repository 'Yaoi'. (The previous repo was named 'luajit-object'.)

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
local Object = require 'Yaoi'

local DerivedClass = Object:def()

function DerivedClass:new (o)
  o = self:base(o)

  -- your source codes here
  -- this is example
  print("Hello, world!")

  return o
end

function DerivedClass:final ()
  print("Goodbye, world!")
end

local obj = DerivedClass:new() -- 'Hello, world!'
obj = nil
collectgarbage() -- 'Goodbye, world!'
```

## Performance
In LuaJIT, Compared to kikito's middleclass, class inheritance is up to 200 times faster and instance construction is about 30-40% slower. However, it varies depending on the user's programming skills.

## Contributing
Anyone can contribute to this library, but please read the license below first.

## License
> Yet Another Object Implementation, for Lua.
> 
> Copyright (C) 2024  icyselec (SILO Project)
>
> This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.
>
> This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
>
> You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

