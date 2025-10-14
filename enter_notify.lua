-- enter_notify.lua
local last_checked = {}
local interval = PLAYER_ENTER_CHECK_INTERVAL or 2.0
local timer = 0.0

minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < interval then return end
    timer = 0

    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local pos = vector.round(player:get_pos())
        if not pos then goto cont end

        local claim = get_claim_at(pos)
        local last = last_checked[name]

        if claim then
            if not last or last.id ~= claim.id then
                -- entered new claim
                if claim.type == "empire" and claim.empire and EMPIRES[claim.empire] then
                    local ename = claim.empire
                    minetest.chat_send_player(name, ("⚠ You entered the territory of Empire %s (Owner: %s) — Claim #%s"):format(ename, tostring(EMPIRES[ename] and EMPIRES[ename].owner or "Unknown"), tostring(claim.id)))
                else
                    minetest.chat_send_player(name, ("⚠ You entered the protected area of %s (Claim #%s)"):format(tostring(claim.owner or "Unknown"), tostring(claim.id)))
                end
            end
            last_checked[name] = claim
        else
            if last then
                -- left previous claim
                if last.type == "empire" and last.empire and EMPIRES[last.empire] then
                    minetest.chat_send_player(name, ("✅ You left the territory of Empire %s (Claim #%s)"):format(last.empire, tostring(last.id)))
                else
                    minetest.chat_send_player(name, ("✅ You left the protected area of %s (Claim #%s)"):format(tostring(last.owner or "Unknown"), tostring(last.id)))
                end
            end
            last_checked[name] = nil
        end
        ::cont::
    end
end)
