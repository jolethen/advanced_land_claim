function pos_in_claim(pos, claim)
    if not pos or not claim or not claim.pos1 or not claim.pos2 then return false end
    return pos.x >= claim.pos1.x and pos.x <= claim.pos2.x
       and pos.y >= claim.pos1.y and pos.y <= claim.pos2.y
       and pos.z >= claim.pos1.z and pos.z <= claim.pos2.z
end

function get_claim_at(pos)
    if not pos then return nil end
    for owner, list in pairs(CLAIMS) do
        for _, claim in ipairs(list) do
            if pos_in_claim(pos, claim) then return claim, owner end
        end
    end
    return nil
end

function find_price_item(itemname)
    for _, v in ipairs(PRICE_ITEMS or {}) do
        if v.item == itemname then return v end
    end
    return nil
end

function next_claim_id()
    DATA.last_id = (DATA.last_id or 0) + 1
    return DATA.last_id
end

function save_claims()
    CLAIMS = DATA.claims
    save_all()
end
