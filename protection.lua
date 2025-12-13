-- ===============================
-- PROTECTION SYSTEM (CRASH-PROOF)
-- ===============================

-- SAFETY: ensure DATA exists
DATA = DATA or {}
DATA.claims = DATA.claims or {}
DATA.allowed_em = DATA.allowed_em or {}
DATA.empires = DATA.empires or {}

-- -------------------------------
-- Helper: claimer priv check
-- -------------------------------
local function has_claimer_priv(name)
    return (minetest.get_player_privs(name) or {}).claimer == true
end

-- ---------------------------------------
-- Get claim at position (SAFE & GLOBAL)
-- ---------------------------------------
function get_claim_at(pos)
    if not pos then return nil end
    if not DATA or not DATA.claims then return nil end

    for owner, list in pairs(DATA.claims) do
        if type(list) == "table" then
            for _, claim in ipairs(list) do
                if claim
                and claim.pos1
                and claim.pos2
                and pos.x >= claim.pos1.x and pos.x <= claim.pos2.x
                and pos.y >= claim.pos1.y and pos.y <= claim.pos2.y
                and pos.z >= claim.pos1.z and pos.z <= claim.pos2.z then
                    return claim
                end
            end
        end
    end

    return nil
end

-- ---------------------------------------
-- Protection check (dig/place)
-- ---------------------------------------
minetest.register_on_protect(function(pos, name)
    -- Admin bypass
    if has_claimer_priv(name) then
        return true
    end

    local claim = get_claim_at(pos)
    if not claim then
        return false -- not protected
    end

    -- Owner always allowed
    if claim.owner == name then
        return true
    end

    -- Personal shared access
    if claim.shared and claim.shared[name] then
        return true
    end

    -- Empire claim logic
    if claim.type == "empire" and claim.empire then
        local empire = DATA.empires[claim.empire]
        if not empire then
            return false
        end

        -- Empire owner or staff
        if empire.owner == name then
            return true
        end
        if empire.staff and empire.staff[name] then
            return true
        end

        -- /allow_em permissions
        local allowed = DATA.allowed_em[claim.empire]
        if allowed then
            -- everyone allowed everywhere
            if allowed.all and allowed.all == true then
                return true
            end

            -- specific player rules
            local p = allowed[name]
            if p then
                if p == true or p == "all" then
                    return true
                end
                if type(p) == "table" then
                    for _, cid in ipairs(p) do
                        if cid == claim.id then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end)

-- ---------------------------------------
-- Protection violation message
-- ---------------------------------------
minetest.register_on_protection_violation(function(pos, name)
    local claim = get_claim_at(pos)
    if not claim then return end

    if claim.type == "empire" and claim.empire then
        minetest.chat_send_player(
            name,
            "⚠ You are inside Empire land: " ..
            claim.empire .. " (Claim #" .. tostring(claim.id) .. ")"
        )
    else
        minetest.chat_send_player(
            name,
            "⚠ This land is owned by " ..
            claim.owner .. " (Claim #" .. tostring(claim.id) .. ")"
        )
    end
end)
