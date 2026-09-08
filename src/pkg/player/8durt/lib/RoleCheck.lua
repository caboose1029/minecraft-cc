-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/RoleCheck.kt", {["1-24"]=1,["25"]=49,["26-27"]=50,["28"]=52,["29"]=53,["30"]=54,["31-32"]=55,["33"]=57,["34-35"]=58,["36-42"]=60,["43"]=70,["44-45"]=71,["46"]=73,["47"]=74,["48"]=75,["49-50"]=76,["51"]=78,["52-53"]=79,["54-56"]=81}, "lib")

VAULT_ROLE_QUERY_PROTOCOL = "vault-role-query"

VAULT_ROLE_REPLY_PROTOCOL = "vault-role-reply"

VAULT_CMD_PROTOCOL = "vault-cmd"

VAULT_RESULT_PROTOCOL = "vault-result"

VAULT_CRAFTER_QUERY_PROTOCOL = "vault-crafter-query"

VAULT_CRAFTER_REPLY_PROTOCOL = "vault-crafter-reply"

VAULT_CRAFTER_CMD_PROTOCOL = "vault-crafter-cmd"

VAULT_CRAFTER_FAILURE_PROTOCOL = "vault-crafter-failure"

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

