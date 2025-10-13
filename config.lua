-- Configuration

-- Claim height limits
HEIGHT_MIN = -1000
HEIGHT_MAX = 2000

-- Allowed price items for claims
PRICE_ITEMS = {
    {item = "default:gold_ingot", rate = 2},
    {item = "default:diamond", rate = 1},
    {item = "default:stone", rate = 100},
}

-- Claim limits
MIN_CLAIM_SIZE = 16
MAX_CLAIM_SIZE = 1000

-- Claim tokens (alternative to items)
TOKEN_AREA = 16 * 16
TOKEN_COSTS = {
    {item = "default:diamond", amount = 1},
    {item = "default:gold_ingot", amount = 2},
}

-- Enter/Leave detection
PLAYER_ENTER_CHECK_INTERVAL = 2.0
