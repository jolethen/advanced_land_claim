local function has_claimer_priv(name)
    return (minetest.get_player_privs(name) or {}).claimer
end

minetest.register_on_protect(function(pos, name)
    if has_claimer_priv(name) then return true end
    local claim = get_claim_at(pos)
    if not claim then return false end
    if claim.owner == name then return true end
    if claim.shared and claim.shared[name] then return true end
    return false
end)

minetest.register_on_protection_violation(function(pos, name)
    local claim = get_claim_at(pos)
    if claim then
        minetest.chat_send_player(name, "⚠ This land is owned by " .. claim.owner .. " (Claim #" .. claim.id .. ")")
    end
end)
