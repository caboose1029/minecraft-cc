-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/RoleCheck.kt", {["1-24"]=1,["25"]=44,["26-27"]=45,["28"]=47,["29"]=48,["30"]=49,["31-32"]=50,["33"]=52,["34-35"]=53,["36-42"]=55,["43"]=65,["44-45"]=66,["46"]=68,["47"]=69,["48"]=70,["49-50"]=71,["51"]=73,["52-53"]=74,["54-56"]=76}, "lib")

VAULT_ROLE_QUERY_PROTOCOL = "vault-role-query"

VAULT_ROLE_REPLY_PROTOCOL = "vault-role-reply"

VAULT_CMD_PROTOCOL = "vault-cmd"

VAULT_RESULT_PROTOCOL = "vault-result"

VAULT_CRAFTER_QUERY_PROTOCOL = "vault-crafter-query"

VAULT_CRAFTER_REPLY_PROTOCOL = "vault-crafter-reply"

VAULT_CRAFTER_CMD_PROTOCOL = "vault-crafter-cmd"

VAULT_CRAFTER_SUCK_PROTOCOL = "vault-crafter-suck"

---@param listenSeconds number
---@return number
function queryForHead(listenSeconds)
    if not ktoxRednetOpenAny() then
        return -1
    end
    rednet.broadcast("?", VAULT_ROLE_QUERY_PROTOCOL)
    local got = ktoxRednetReceiveProtocol(VAULT_ROLE_REPLY_PROTOCOL, listenSeconds)
    if not got then
        return -1
    end
    if ktoxRednetLastMessage() ~= "head" then
        return -1
    end
    return ktoxRednetLastSenderId()
end

---@param jobType string
---@param listenSeconds number
---@return number
function queryForCrafter(jobType, listenSeconds)
    if not ktoxRednetOpenAny() then
        return -1
    end
    rednet.broadcast(jobType, VAULT_CRAFTER_QUERY_PROTOCOL)
    local got = ktoxRednetReceiveProtocol(VAULT_CRAFTER_REPLY_PROTOCOL, listenSeconds)
    if not got then
        return -1
    end
    if ktoxRednetLastMessage() ~= jobType then
        return -1
    end
    return ktoxRednetLastSenderId()
end

