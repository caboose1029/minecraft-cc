package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// Bindings to CC:Tweaked's `rednet` API — works over a wired OR wireless
// modem identically (see PLAN.md). `rednet.send`/`rednet.broadcast` are
// fixed globals with simple scalar args/return, so they bind directly
// with no shim needed, same idiom as Turtle.kt/Term.kt. `rednet.receive`
// genuinely returns 3 values, which Kotlin can't express — see
// ktox-cc-shim.lua's ktoxRednetReceiveAny/ReceiveProtocol for that side.

@NativeName("rednet.send")
fun rednetSend(recipientId: Int, message: String, protocol: String): Boolean = externalSource()

@NativeName("rednet.broadcast")
fun rednetBroadcast(message: String, protocol: String): Unit = externalSource()

// Finds and opens the first modem present (wired or wireless) for
// rednet. Returns false if none is attached.
@NativeName("ktoxRednetOpenAny")
fun rednetOpenAny(): Boolean = externalSource()

@NativeName("ktoxRednetReceiveAny")
fun ktoxRednetReceiveAny(timeoutSeconds: Double): Boolean = externalSource()

@NativeName("ktoxRednetReceiveProtocol")
fun ktoxRednetReceiveProtocol(protocol: String, timeoutSeconds: Double): Boolean = externalSource()

@NativeName("ktoxRednetLastSenderId")
fun ktoxRednetLastSenderId(): Int = externalSource()

@NativeName("ktoxRednetLastMessage")
fun ktoxRednetLastMessage(): String = externalSource()

@NativeName("ktoxRednetLastProtocol")
fun ktoxRednetLastProtocol(): String = externalSource()
