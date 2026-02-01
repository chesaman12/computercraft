--- Turtle Actions Module (Legacy Compatibility)
-- This module provides backwards compatibility with basicTurtleCommands.lua
-- New scripts should use the common/ modules instead
-- @module turtle_actions

local M = {}

-- Re-export common modules for convenience
M.movement = require("common.movement")
M.inventory = require("common.inventory")
M.mining = require("common.mining")
M.fuel = require("common.fuel")

-- Legacy function mappings

-- Movement (use M.movement instead)
M.moveForward = function() return M.movement.forward(false) end
M.moveBackward = function() return M.movement.back() end
M.moveUp = function() return M.movement.up(false) end
M.moveDown = function() return M.movement.down(false) end
M.turnLeft = function() return M.movement.turnLeft() end
M.turnRight = function() return M.movement.turnRight() end

-- Digging (use M.mining instead)
M.digBlock = function() return M.mining.digForward() end
M.digBlockAbove = function() return M.mining.digUp() end
M.digBlockBelow = function() return M.mining.digDown() end

-- Placing (direct turtle calls)
M.placeBlock = turtle.place
M.placeBlockAbove = turtle.placeUp
M.placeBlockBelow = turtle.placeDown

-- Inspection (use M.mining instead)
M.inspectBlock = function() return M.mining.inspectForward() end
M.inspectBlockAbove = function() return M.mining.inspectUp() end
M.inspectBlockBelow = function() return M.mining.inspectDown() end

-- Inventory (use M.inventory instead)
M.selectSlot = turtle.select
M.selectItem = function(name) return M.inventory.selectItem(name) end
M.getItemCount = turtle.getItemCount
M.getItemSpace = turtle.getItemSpace
M.transferTo = turtle.transferTo

-- Attacking (direct turtle calls)
M.attack = turtle.attack
M.attackUp = turtle.attackUp
M.attackDown = turtle.attackDown

-- Item pickup/drop (direct turtle calls)
M.suck = turtle.suck
M.suckUp = turtle.suckUp
M.suckDown = turtle.suckDown
M.drop = turtle.drop
M.dropUp = turtle.dropUp
M.dropDown = turtle.dropDown

-- Fuel (use M.fuel instead)
M.refuel = turtle.refuel
M.getFuelLevel = turtle.getFuelLevel
M.getFuelLimit = turtle.getFuelLimit

-- Crafting
M.craft = turtle.craft

return M
