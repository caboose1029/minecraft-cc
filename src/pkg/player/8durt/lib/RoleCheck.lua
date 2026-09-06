-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/RoleCheck.kt", {["1-16"]=1,["17"]=24,["18-19"]=25,["20"]=27,["21"]=28,["22"]=29,["23-24"]=30,["25"]=32,["26-27"]=33,["28-30"]=35}, "lib")

VAULT_ROLE_QUERY_PROTOCOL = "vault-role-query"

VAULT_ROLE_REPLY_PROTOCOL = "vault-role-reply"

VAULT_CMD_PROTOCOL = "vault-cmd"

VAULT_RESULT_PROTOCOL = "vault-result"

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

