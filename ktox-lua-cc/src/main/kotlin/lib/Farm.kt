package lib

import common.ktoxConfigAllFarms
import lib.setJobPower
import lib.storagePoolCount

// A farm (job-types.json entries with kind "farm" — see PLAN.md). This
// system doesn't know or care HOW a farm works internally (chance-based
// crushing/washing, mob farming, crop farming, whatever) — it's just a
// relay toggle plus a list of outputs to watch in the storage pool. Same
// packed-string idiom as Recipe (see lib/Config.kt) and for the same
// reason: ktox has no working MutableList/growable collection to hold a
// variable number of parsed watermark entries, so watermarksRaw stays
// packed and is re-split per access.
data class Farm(
    val jobType: String,
    val watermarksRaw: String,
)

fun farmWatermarkCount(farm: Farm): Int {
    return farm.watermarksRaw.split(";").size
}

// 1-indexed, matching every other list access in this codebase.
fun farmWatermarkItem(farm: Farm, index: Int): String {
    return farm.watermarksRaw.split(";")[index].split(",")[1]
}

fun farmWatermarkLow(farm: Farm, index: Int): Int {
    return farm.watermarksRaw.split(";")[index].split(",")[2].toDouble().toInt()
}

fun farmWatermarkHigh(farm: Farm, index: Int): Int {
    return farm.watermarksRaw.split(";")[index].split(",")[3].toDouble().toInt()
}

// Turns every configured farm on or off based on its own output(s) in
// the storage pool — ON if ANY tracked output is below its low
// watermark (something's actually short), OFF only once ALL tracked
// outputs are above their high watermark (fully saturated). Left alone
// otherwise — this hysteresis band between low and high is deliberate,
// same reasoning as passive feeders: avoids flapping a farm on/off
// constantly near a threshold. A multi-output farm (iron_andesite_farm
// tracks both iron ingots and andesite) only turns off once BOTH are
// oversupplied, since turning it off while either is still short would
// starve whichever one isn't yet saturated.
//
// Called opportunistically after each head interaction (see HeadTerminal.kt),
// not on an independent timer — same reasoning as topUpPassiveFeeders:
// a real timer risks being cancelled and restarted before its sleep
// elapses under steady CLI traffic.
fun manageFarms() {
    val raw = ktoxConfigAllFarms()
    if (raw == "") {
        return
    }
    val rows = raw.split("\n")
    var i = 1
    while (i <= rows.size) {
        val parts = rows[i].split("|")
        val farm = Farm(parts[1], parts[2])
        val watermarkCount = farmWatermarkCount(farm)

        var anyBelowLow = false
        var allAboveHigh = true
        var j = 1
        while (j <= watermarkCount) {
            val item = farmWatermarkItem(farm, j)
            val low = farmWatermarkLow(farm, j)
            val high = farmWatermarkHigh(farm, j)
            val current = storagePoolCount(item)
            if (current < low) {
                anyBelowLow = true
            }
            if (current <= high) {
                allAboveHigh = false
            }
            j += 1
        }

        if (anyBelowLow) {
            setJobPower(farm.jobType, true)
        } else if (allAboveHigh) {
            setJobPower(farm.jobType, false)
        }
        i += 1
    }
}
