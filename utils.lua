-- =========================
-- CLAIM UTILITY FUNCTIONS
-- =========================

-- Position inside claim check
function pos_in_claim(pos, claim)
    if not pos or not claim or not claim.pos1 or not claim.pos2 then
        return false
    end

    return pos.x >= claim.pos1.x and pos.x <= claim.pos2.x
       and pos.y >= claim.pos1.y and pos.y <= claim.pos2.y
       and pos.z >= claim.pos1.z and pos.z <= claim.pos2.z
end

-- Get claim at position
function get_claim_at(pos)
    if not pos then return nil end

    for _, list in pairs(DATA.claims or {}) do
        if type(list) == "table" then
            for _, claim in ipairs(list) do
                if pos_in_claim(pos, claim) then
                    return claim
                end
            end
        end
    end

    return nil
end

-- Get claim by numeric ID
function get_claim_by_id(id)
    if not id then return nil end
    id = tonumber(id)
    if not id then return nil end

    for _, list in pairs(DATA.claims or {}) do
        if type(list) == "table" then
            for _, claim in ipairs(list) do
                if claim and claim.id == id then
                    return claim
                end
            end
        end
    end

    return nil
end

-- Find price item definition
function find_price_item(itemname)
    if not itemname then return nil end

    for _, v in ipairs(PRICE_ITEMS or {}) do
        if v and v.item == itemname then
            return v
        end
    end

    return nil
end

-- Generate next claim ID
function next_claim_id()
    DATA.last_id = tonumber(DATA.last_id) or 0
    DATA.last_id = DATA.last_id + 1
    return DATA.last_id
end

-- Save claims safely
function save_claims()
    DATA.claims = DATA.claims or {}
    save_all()
end
