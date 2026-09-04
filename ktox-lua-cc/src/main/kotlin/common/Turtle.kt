package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// Bindings to CC:Tweaked's `turtle` API, which already exists as a global
// at runtime — these declarations generate no Lua code themselves (see
// AGENTS.md); they only give call sites a typed, dot-call-syntax reference.
//
// Core essentials only. Not modeled yet: functions that return multiple
// values in Lua (inspect*, getItemDetail) — Kotlin can't express a Lua
// multi-return directly, so these are left out until that's solved.

// -- Movement --

@NativeName("turtle.forward")
fun turtleForward(): Boolean = externalSource()

@NativeName("turtle.back")
fun turtleBack(): Boolean = externalSource()

@NativeName("turtle.up")
fun turtleUp(): Boolean = externalSource()

@NativeName("turtle.down")
fun turtleDown(): Boolean = externalSource()

@NativeName("turtle.turnLeft")
fun turtleTurnLeft(): Boolean = externalSource()

@NativeName("turtle.turnRight")
fun turtleTurnRight(): Boolean = externalSource()

// -- Digging --

@NativeName("turtle.dig")
fun turtleDig(): Boolean = externalSource()

@NativeName("turtle.digUp")
fun turtleDigUp(): Boolean = externalSource()

@NativeName("turtle.digDown")
fun turtleDigDown(): Boolean = externalSource()

// -- Placing --

@NativeName("turtle.place")
fun turtlePlace(): Boolean = externalSource()

@NativeName("turtle.placeUp")
fun turtlePlaceUp(): Boolean = externalSource()

@NativeName("turtle.placeDown")
fun turtlePlaceDown(): Boolean = externalSource()

// -- Attacking --

@NativeName("turtle.attack")
fun turtleAttack(): Boolean = externalSource()

@NativeName("turtle.attackUp")
fun turtleAttackUp(): Boolean = externalSource()

@NativeName("turtle.attackDown")
fun turtleAttackDown(): Boolean = externalSource()

// -- Detecting / comparing --

@NativeName("turtle.detect")
fun turtleDetect(): Boolean = externalSource()

@NativeName("turtle.detectUp")
fun turtleDetectUp(): Boolean = externalSource()

@NativeName("turtle.detectDown")
fun turtleDetectDown(): Boolean = externalSource()

@NativeName("turtle.compare")
fun turtleCompare(): Boolean = externalSource()

@NativeName("turtle.compareUp")
fun turtleCompareUp(): Boolean = externalSource()

@NativeName("turtle.compareDown")
fun turtleCompareDown(): Boolean = externalSource()

// -- Inventory --

@NativeName("turtle.select")
fun turtleSelect(slot: Int): Boolean = externalSource()

@NativeName("turtle.getSelectedSlot")
fun turtleGetSelectedSlot(): Int = externalSource()

@NativeName("turtle.getItemCount")
fun turtleGetItemCount(slot: Int): Int = externalSource()

@NativeName("turtle.getItemSpace")
fun turtleGetItemSpace(slot: Int): Int = externalSource()

@NativeName("turtle.transferTo")
fun turtleTransferTo(slot: Int, count: Int): Boolean = externalSource()

@NativeName("turtle.drop")
fun turtleDrop(count: Int): Boolean = externalSource()

@NativeName("turtle.dropUp")
fun turtleDropUp(count: Int): Boolean = externalSource()

@NativeName("turtle.dropDown")
fun turtleDropDown(count: Int): Boolean = externalSource()

@NativeName("turtle.suck")
fun turtleSuck(count: Int): Boolean = externalSource()

@NativeName("turtle.suckUp")
fun turtleSuckUp(count: Int): Boolean = externalSource()

@NativeName("turtle.suckDown")
fun turtleSuckDown(count: Int): Boolean = externalSource()

// -- Fuel --

@NativeName("turtle.getFuelLevel")
fun turtleGetFuelLevel(): Int = externalSource()

@NativeName("turtle.getFuelLimit")
fun turtleGetFuelLimit(): Int = externalSource()

@NativeName("turtle.refuel")
fun turtleRefuel(count: Int): Boolean = externalSource()

// -- Block inspection --
//
// turtle.inspect()/inspectUp()/inspectDown() return (success, blockData) —
// another multi-return case. These bind to ktoxInspect*Name
// (src/main/lua/ktox-cc-shim.lua), which narrows the result down to just
// the block name, or nil if there's no block / the call failed.

@NativeName("ktoxInspectName")
fun turtleInspectName(): String? = externalSource()

@NativeName("ktoxInspectUpName")
fun turtleInspectUpName(): String? = externalSource()

@NativeName("ktoxInspectDownName")
fun turtleInspectDownName(): String? = externalSource()

// -- Inventory item identification --
//
// turtle.getItemDetail() returns a whole Lua table (name, count, ...) —
// Kotlin has nowhere to put an arbitrary table, so this binds to a shim
// that narrows it down to just the item name, or nil if the slot is empty.

@NativeName("ktoxGetItemName")
fun turtleGetItemName(slot: Int): String? = externalSource()
