-- =========================
-- PROTECTION SYSTEM
-- =========================

-- Keep original engine protection (for other mods)
local old_is_protected = minetest.is_protected

-- Utility: check bypass
local function has_bypass(name)
    local privs = minetest.get_player_privs(name) or {}
    return privs.claimer == true
end

-- Utility: is player allowed in claim
local function is_player_allowed(claim, name)
    if not claim or not name then return false end

    -- Owner
    if claim.owner == name then
        return true
    end

    -- Shared players
    if claim.shared and claim.shared[name] then
        return true
    end

    -- Empire logic
    if claim.type == "empire" and claim.empire then
        local empires = DATA.empires or {}
        local emp = empires[claim.empire]

        if emp then
            -- Owner of empire
            if emp.owner == name then
                return true
            end

            -- Member access
            if emp.members and emp.members[name] then
                -- Claim allows all empire members
                if claim.empire_access == "all" then
                    return true
                end

                -- Claim allows specific empire players
                if claim.empire_allowed and claim.empire_allowed[name] then
                    return true
                end
            end
        end
    end

    return false
end

-- =========================
-- CORE ENGINE HOOK
-- =========================
function minetest.is_protected(pos, name)
    -- Safety
    if not pos or not name or name == "" then
        return true
    end

    -- Admin bypass
    if has_bypass(name) then
        return false
    end

    -- Get claim
    local claim = get_claim_at(pos)

    -- No claim → fallback to other mods
    if not claim then
        return old_is_protected(pos, name)
    end

    -- Allowed player
    if is_player_allowed(claim, name) then
        return false
    end

    -- Otherwise BLOCK
    return true
end

-- =========================
-- MESSAGE ON VIOLATION
-- =========================
minetest.register_on_protection_violation(function(pos, name)
    if not pos or not name then return end

    local claim = get_claim_at(pos)
    if not claim then return end

    local owner = claim.owner or "unknown"
    local cid = claim.id and tostring(claim.id) or "?"

    minetest.chat_send_player(
        name,
        "⚠ This land is owned by " .. owner .. " (Claim #" .. cid .. ")"
    )
end)
