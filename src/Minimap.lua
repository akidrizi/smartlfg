local _, SmartLFG = ...

-- A small, hand-rolled minimap button (no external libraries). Left-click
-- toggles the options dialog; the button can be dragged around the minimap
-- ring and its angle is persisted per-character in the DB (minimapAngle).
SmartLFG.Minimap = {}
local M = SmartLFG.Minimap

local MINIMAP_ICON = "Interface\\AddOns\\SmartLFG\\media\\minimap_64.png"

local button       -- the minimap Button frame

-- Which quadrants of a given minimap shape are rounded (true) vs square
-- (false), keyed by the de-facto `GetMinimapShape()` API that square-minimap
-- addons implement. Lets the button hug a round, square or cornered minimap —
-- the same approach LibDBIcon uses, without pulling in the library.
local MINIMAP_SHAPES = {
    ["ROUND"]                = { true,  true,  true,  true  },
    ["SQUARE"]               = { false, false, false, false },
    ["CORNER-TOPLEFT"]       = { false, false, false, true  },
    ["CORNER-TOPRIGHT"]      = { false, false, true,  false },
    ["CORNER-BOTTOMLEFT"]    = { false, true,  false, false },
    ["CORNER-BOTTOMRIGHT"]   = { true,  false, false, false },
    ["SIDE-LEFT"]            = { false, true,  false, true  },
    ["SIDE-RIGHT"]           = { true,  false, true,  false },
    ["SIDE-TOP"]             = { false, false, true,  true  },
    ["SIDE-BOTTOM"]          = { true,  true,  false, false },
    ["TRICORNER-TOPLEFT"]    = { false, true,  true,  true  },
    ["TRICORNER-TOPRIGHT"]   = { true,  false, true,  true  },
    ["TRICORNER-BOTTOMLEFT"] = { true,  true,  false, true  },
    ["TRICORNER-BOTTOMRIGHT"]= { true,  true,  true,  false },
}

-- ── Place the button along the minimap edge at the stored angle ──────────────
local function UpdatePosition()
    local angle = math.rad(SmartLFG.DB.Get("minimapAngle") or 200)
    local x, y, q = math.cos(angle), math.sin(angle), 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end

    local shape    = (GetMinimapShape and GetMinimapShape()) or "ROUND"
    local rounded  = MINIMAP_SHAPES[shape] or MINIMAP_SHAPES["ROUND"]
    local w = (Minimap:GetWidth()  / 2) + 5
    local h = (Minimap:GetHeight() / 2) + 5

    if rounded[q] then
        x, y = x * w, y * h
    else
        -- Square quadrant: clamp the vector to the rectangular edge.
        x = math.max(-w, math.min(x * math.sqrt(2 * w * w) - 10, w))
        y = math.max(-h, math.min(y * math.sqrt(2 * h * h) - 10, h))
    end

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- ── Follow the cursor while dragging, storing the new angle ──────────────────
local function DragUpdate()
    local mx, my   = Minimap:GetCenter()
    local scale    = Minimap:GetEffectiveScale()
    local cx, cy   = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    SmartLFG.DB.Set("minimapAngle", math.deg(math.atan2(cy - my, cx - mx)))
    UpdatePosition()
end

-- ── Build the button once ───────────────────────────────────────────────────
function M.Create()
    if button then return end

    button = CreateFrame("Button", "SmartLFGMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetClampedToScreen(true)

    -- Round addon icon, framed by the standard minimap tracking border. The
    -- border (53px at the button's TOPLEFT) does not centre its ring on the
    -- button: it frames a 20px disc anchored at TOPLEFT (7,-5) — the slot
    -- LibDBIcon uses for its background. Anchoring the icon there centres it in
    -- the ring (centring on the button leaves it ~1.5px left of the ring).
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetTexture(MINIMAP_ICON)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)
    icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button:SetScript("OnClick", function()
        SmartLFG.Options.Toggle()
    end)

    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", DragUpdate)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(SmartLFG.COLOR.ADDON .. "SmartLFG" .. SmartLFG.COLOR.RESET)
        GameTooltip:AddLine(SmartLFG.L.MINIMAP_TOOLTIP, 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdatePosition()
end
