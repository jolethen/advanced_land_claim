function pos_in_claim(pos, claim)
    return pos.x >= claim.pos1.x and pos.x <= claim.pos2.x
       and pos.y >= claim.pos1.y and pos.y <= claim.pos2.y
       and pos.z >= claim.pos1.z and pos.z <= claim.pos2.z
end

function get_claim_at(pos)
    for owner, list in pairs(CLAIMS) do
        for _, claim in ipairs(list) do
            if pos_in_claim(pos, claim) then return claim, owner end
        end
    end
end

function find_price_item(itemname)
    for _, v in ipairs(PRICE_ITEMS) do if v.item == itemname then return v end end
end

function get_claim_by_id(id)
    for owner, list in pairs(CLAIMS) do
        for _, claim in ipairs(list) do if claim.id == id then return claim, owner end
        end
    end
end

function next_claim_id()
    LAST_ID = LAST_ID + 1
    return LAST_ID
end

function player_is_admin(name)
    return minetest.get_player_privs(name).server == true
end
