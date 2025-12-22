---@meta
---
--- This file provides type definitions for custom Lua library extensions
--- used by the DRL engine. It is only for Lua Language Server (luarc)
--- and is not executed by the game.
---

---@class tablelib
local table

---Convert array to set (keys become values set to true)
---@param t table
---@return table
function table.toset(t) end

---Pick random element from array
---@param t table
---@return any
function table.random_pick(t) end

---Merge source table into destination table
---@param dest table
---@param source table
---@return table
function table.merge(dest, source) end

---@class mathlib
local math

---Clamp value between min and max
---@param value number
---@param min number
---@param max number
---@return number
function math.clamp(value, min, max) end
