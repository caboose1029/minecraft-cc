-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/RoleCheck.kt", {["1-22"]=1,["23"]=32,["24-25"]=33,["26"]=35,["27"]=36,["28"]=37,["29-30"]=38,["31"]=40,["32-33"]=41,["34-40"]=43,["41"]=53,["42-43"]=54,["44"]=56,["45"]=57,["46"]=58,["47-48"]=59,["49"]=61,["50-51"]=62,["52-54"]=64}, "lib")

VAULT_ROLE_QUERY_PROTOCOL = "vault-role-query"

VAULT_ROLE_REPLY_PROTOCOL = "vault-role-reply"

VAULT_CMD_PROTOCOL = "vault-cmd"

VAULT_RESULT_PROTOCOL = "vault-result"

VAULT_CRAFTER_QUERY_PROTOCOL = "vault-crafter-query"

VAULT_CRAFTER_REPLY_PROTOCOL = "vault-crafter-reply"

VAULT_CRAFTER_CMD_PROTOCOL = "vault-crafter-cmd"

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

