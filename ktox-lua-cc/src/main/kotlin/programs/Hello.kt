package programs

import common.osGetComputerID
import common.termWrite
import common.turtleForward
import common.turtleGetFuelLevel
import common.turtleSelect

fun main() {
    println("Hello from ktox!")
    termWrite("Computer #${osGetComputerID()}")
    turtleSelect(1)
    turtleForward()
    println("Fuel: ${turtleGetFuelLevel()}")
}
