-- src/FrameHook.lua
-- Hooks LFG UI row frames for double-click sign-up.
--
-- WoW lazy-loads LFG sub-addons on first panel open; Core.lua calls
-- HookLFD / HookLFGList from ADDON_LOADED so frames are guaranteed to exist.
--
-- ⚠ OnMouseDown propagates up the frame tree. Hook ONLY ScrollBox row frames,
--   never their parent frames, or a single click fires two handlers.
--   Row frames are also composites, so MakeOnClick deduplicates fires within
--   50ms as the same physical click.

local _, SmartLFG = ...
local GameTooltip = _G.GameTooltip

SmartLFG.FrameHook = {}
local FH = SmartLFG.FrameHook

local lastClickTime     = 0
local lastFireTime      = 0
local SAME_CLICK_WINDOW = 0.05   -- 50 ms guard against propagated duplicate fires

local hookedFrames    = {}
local onShowHooked    = {}
local scrollBoxHooked = {}
local tooltipHooked   = {}
local tooltipResetHooked = false
local TOOLTIP_OWNER_MAX_DEPTH = 6

--- Returns true when `owner` is `frame` or one of its parents (bounded walk).
--- @param owner table|nil
--- @param frame table|nil
--- @return boolean
local function IsOwnedByFrame(owner, frame)
    local current = owner
    for _ = 0, TOOLTIP_OWNER_MAX_DEPTH do
        if current == frame then return true end
        if not (current and current.GetParent) then break end
        current = current:GetParent()
    end
    return false
end

--- Attempts to read a Premade result ID from a frame or its element data.
--- @param frame table|nil
--- @return number|nil
local function GetPremadeResultID(frame)
    if not frame then return nil end
    if frame.resultID then return frame.resultID end
    if frame.GetElementData then
        local data = frame:GetElementData()
        if data then
            return data.resultID or data.searchResultID
        end
    end
    return nil
end

--- Walks up a frame chain and returns the first Premade result ID found.
--- @param frame table|nil
--- @return number|nil
local function GetPremadeResultIDFromChain(frame)
    local current = frame
    for _ = 0, TOOLTIP_OWNER_MAX_DEPTH do
        local resultID = GetPremadeResultID(current)
        if resultID then return resultID end
        if not (current and current.GetParent) then break end
        current = current:GetParent()
    end
    return nil
end

--- Returns whether a Premade entry is currently sign-up eligible.
--- Prefers SearchResultInfo when a result ID is known; otherwise falls back
--- to the panel Sign Up button enabled state.
--- @param resultID number|nil
--- @return boolean
local function IsPremadeSignUpAvailable(resultID)
    if resultID and C_LFGList and C_LFGList.GetSearchResultInfo then
        local info = C_LFGList.GetSearchResultInfo(resultID)
        return info and not info.isDelisted and not info.delisted
    end

    -- Fallback: if resultID is not readable on this client/frame variant,
    -- use the current panel Sign Up enablement as an availability signal.
    local panel = LFGListFrame and LFGListFrame.SearchPanel
    local signUpBtn = panel and panel.SignUpButton
    return signUpBtn and signUpBtn.IsEnabled and signUpBtn:IsEnabled()
end

--- Shared tooltip visibility gate for LFD and Premade row hints.
--- @param frame table|nil
--- @param mode string "LFD"|"PREMADE"
--- @param resultID number|nil
--- @return boolean
local function CanShowTooltipHint(frame, mode, resultID)
    if not SmartLFG.DB.Get("enabled")
        or not SmartLFG.DB.Get("tooltipHint")
        or not SmartLFG.HasLFDRoleSelected()
        or not SmartLFG.IsPlayerSoloOrLeader()
    then
        return false
    end

    if mode == "LFD" and GetLFGMode(LE_LFG_CATEGORY_LFD) then
        return false
    end

    if mode == "PREMADE" then
        if not IsPremadeSignUpAvailable(resultID) then
            return false
        end
    end

    if frame and frame.IsEnabled and not frame:IsEnabled() then return false end
    return true
end

--- Appends the SmartLFG tooltip hint to the currently visible row tooltip.
--- @param frame table
--- @param mode string "LFD"|"PREMADE"
local function AddTooltipHint(frame, mode)
    local tooltip = GameTooltip
    if not (tooltip and tooltip:IsShown()) then return end

    local owner = tooltip.GetOwner and tooltip:GetOwner() or nil
    if not owner then return end

    if not IsOwnedByFrame(owner, frame) then return end

    local resultID
    if mode == "PREMADE" then
        resultID = GetPremadeResultIDFromChain(frame) or GetPremadeResultIDFromChain(owner)
    end

    if not CanShowTooltipHint(frame, mode, resultID) then return end

    if tooltip.__SmartLFGHintOwner == owner then return end
    tooltip.__SmartLFGHintOwner = owner

    tooltip:AddLine(" ")
    tooltip:AddLine(SmartLFG.L.TOOLTIP_QUICK_SIGNUP, 0, 1, 1, true)
    tooltip:Show()
end

--- Hooks a row frame to inject the tooltip hint on hover.
--- @param frame table|nil
--- @param mode string "LFD"|"PREMADE"
local function HookTooltip(frame, mode)
    if not frame or tooltipHooked[frame] then return end
    frame:HookScript("OnEnter", function(self)
        AddTooltipHint(self, mode)
    end)
    tooltipHooked[frame] = true

    if not tooltipResetHooked and GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnHide", function(tt)
            tt.__SmartLFGHintOwner = nil
        end)
        tooltipResetHooked = true
    end
end

--- Reads the activity name shown on a Premade Groups result row frame.
--- Blizzard's row template stores the dropdown-selected activity (e.g. "Maisara
--- Caverns") in a FontString named ActivityName. This is read at click time so
--- the value is always available even when C_LFGList activity APIs have changed.
--- Walks the frame chain up to TOOLTIP_OWNER_MAX_DEPTH levels to handle composite
--- frames where the FontString may live on a parent rather than the leaf frame.
--- @param frame table|nil
--- @return string|nil
local function GetActivityNameFromFrame(frame)
    local current = frame
    for _ = 0, TOOLTIP_OWNER_MAX_DEPTH do
        if not current then break end

        -- DataProvider element data (WoW 10.x+) may expose activityName directly.
        if current.GetElementData then
            local data = current:GetElementData()
            if data and type(data.activityName) == "string" and data.activityName ~= "" then
                return data.activityName
            end
        end

        -- Named FontString children present in Blizzard's row templates.
        for _, field in ipairs({ "ActivityName", "activityName", "CategoryName", "Activity" }) do
            local fs = current[field]
            if fs and type(fs.GetText) == "function" then
                local text = fs:GetText()
                if text and text ~= "" then return text end
            end
        end

        if not current.GetParent then break end
        current = current:GetParent()
    end
    return nil
end

--- Returns a click handler that calls signUpFn(frame) on confirmed double-click.
--- Silently does nothing when the player is in a group but is not the leader.
local function MakeOnClick(signUpFn)
    return function(self, button)
        if button ~= "LeftButton" then return end
        if not SmartLFG.IsPlayerSoloOrLeader() then return end
        local now = GetTime()
        -- Discard propagated duplicate fires from the same physical click.
        if (now - lastFireTime) < SAME_CLICK_WINDOW then
            lastFireTime = now
            return
        end
        lastFireTime = now
        if (now - lastClickTime) <= SmartLFG.DOUBLE_CLICK_THRESHOLD then
            lastClickTime = 0
            signUpFn(self)
        else
            lastClickTime = now
        end
    end
end

local OnClickLFD = MakeOnClick(function(_)
    SmartLFG.RoleManager.SignUp()
end)

--- Premade click: capture result ID and activity name from the row frame so
--- RoleManager can show the correct dungeon/raid/PvP name in the join message,
--- independent of which C_LFGList activity APIs exist in the current WoW version.
local OnClickPremade = MakeOnClick(function(frame)
    local resultID = GetPremadeResultIDFromChain(frame)
    local actName  = GetActivityNameFromFrame(frame)
    SmartLFG.RoleManager.ApplyToGroup(resultID, actName)
end)

--- Hooks Dungeon Finder row interactions (double-click + tooltip hint).
--- @param frame table|nil
local function HookFrameLFD(frame)
    if not frame then return end
    if not hookedFrames[frame] then
        frame:HookScript("OnMouseDown", OnClickLFD)
        hookedFrames[frame] = true
    end
    HookTooltip(frame, "LFD")
end

--- Hooks Premade row interactions (double-click + tooltip hint).
--- Also refreshes the activity name cache on every call so recycled frames
--- always update the cache before any sign-up event fires.
--- @param frame table|nil
local function HookFramePremade(frame)
    if not frame then return end
    if not hookedFrames[frame] then
        frame:HookScript("OnMouseDown", OnClickPremade)
        hookedFrames[frame] = true
    end
    HookTooltip(frame, "PREMADE")

    -- Refresh the cache outside the hookedFrames guard: ScrollBox recycles frame
    -- objects, so the same frame pointer may display a different result after a
    -- layout change. Run this every time so the cache is always up to date.
    local resultID = GetPremadeResultID(frame)
    local actName  = GetActivityNameFromFrame(frame)
    if resultID and actName and actName ~= "" then
        SmartLFG.RoleManager.CacheActivityName(resultID, actName)
    end
end

-- Legacy fallback for old-style ScrollFrame with a .buttons table.
--- Hooks legacy Premade ScrollFrame buttons when present.
--- @param scrollFrame table|nil
local function HookScrollButtons(scrollFrame)
    if not scrollFrame or not scrollFrame.buttons then return end
    for _, btn in ipairs(scrollFrame.buttons) do HookFramePremade(btn) end
end

-- Hooks visible ScrollBox row frames and re-hooks on layout changes.
-- Returns true when found — caller must NOT also hook parent frames (dual-fire).
--- @param scrollBox table|nil
--- @return boolean
local function HookScrollBox(scrollBox)
    if not scrollBox then return false end
    if scrollBox.ForEachFrame then
        scrollBox:ForEachFrame(HookFramePremade)
    end
    if not scrollBoxHooked[scrollBox] and scrollBox.RegisterCallback and BaseScrollBoxEvents then
        scrollBox:RegisterCallback(BaseScrollBoxEvents.OnLayout, function()
            if scrollBox.ForEachFrame then scrollBox:ForEachFrame(HookFramePremade) end
        end, scrollBox)
        scrollBoxHooked[scrollBox] = true
    end
    return true
end

--- Hook the Dungeon Finder. Called when Blizzard_LookingForGroup loads.
function FH.HookLFD()
    local frame = LFGParentFrame
    if not frame then return false end
    HookFrameLFD(frame)
    for i = 1, 30 do
        local btn = _G["LFGDungeonListButton" .. i]
        if btn then HookFrameLFD(btn) end
    end
    if not onShowHooked[frame] then
        frame:HookScript("OnShow", FH.HookLFD)
        onShowHooked[frame] = true
    end
    return true
end

--- Hook the Premade Groups browser. Called when Blizzard_LFGList loads.
function FH.HookLFGList()
    local frame = LFGListFrame
    if not frame then return false end

    -- Auto-confirm the application dialog when it opens after Sign Up is clicked.
    local appDialog = LFGListApplicationDialog
    if appDialog and not onShowHooked[appDialog] then
        appDialog:HookScript("OnShow", function()
            if not SmartLFG.DB.Get("enabled") then return end
            local btn = appDialog.SignUpButton
            if btn and btn:IsEnabled() then btn:Click() end
        end)
        onShowHooked[appDialog] = true
    end

    local panel = frame.SearchPanel
    if panel then
        local hookedViaScrollBox = HookScrollBox(panel.ScrollBox)
        if not hookedViaScrollBox then
            -- No ScrollBox API — hook parent frames as last resort.
            HookFramePremade(frame)
            HookFramePremade(panel)
        end
        HookScrollButtons(panel.ScrollFrame)
    else
        HookFramePremade(frame)
    end

    if not onShowHooked[frame] then
        frame:HookScript("OnShow", FH.HookLFGList)
        onShowHooked[frame] = true
    end
    return true
end
