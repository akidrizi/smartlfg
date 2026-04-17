local _, SmartLFG = ...
local GameTooltip = _G.GameTooltip

SmartLFG.FrameHook = {}
local FH = SmartLFG.FrameHook

local lastClickTime     = 0
local lastFireTime      = 0
local lastClickMode     = nil
local SAME_CLICK_WINDOW = 0.05

local hookedFrames      = {}
local onShowHooked      = {}
local scrollBoxHooked   = {}
local tooltipHooked     = {}
local TOOLTIP_OWNER_MAX_DEPTH = 6


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

--- Hooks `frame`'s OnEnter to append the sign-up hint at the bottom of its
--- tooltip. Runs after the frame's own OnEnter so our lines are always last.
--- @param frame table|nil
--- @param mode string "LFD"|"PREMADE"
local function HookTooltip(frame, mode)
    if not frame or tooltipHooked[frame] then return end
    tooltipHooked[frame] = true

    frame:HookScript("OnEnter", function(self)
        local resultID = (mode == "PREMADE") and GetPremadeResultIDFromChain(self) or nil
        if not CanShowTooltipHint(self, mode, resultID) then return end
        if GameTooltip:GetOwner() ~= self then return end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(SmartLFG.L.TOOLTIP_QUICK_SIGNUP, 0, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(SmartLFG.L.TOOLTIP_SHIFT_NOTE, 0, 1, 1, true)
        GameTooltip:Show()
    end)
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

        if current.GetElementData then
            local data = current:GetElementData()
            if data and type(data.activityName) == "string" and data.activityName ~= "" then
                return data.activityName
            end
        end
        for _, field in ipairs({ "ActivityName", "activityName" }) do
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

--- Returns a click handler that calls signUpFn(frame, withNote) on confirmed double-click.
--- Silently does nothing when the addon is disabled or the player cannot lead a sign-up.
--- `mode` ("LFD"|"PREMADE") isolates click counters so a click in one panel never
--- contributes to a double-click detected in the other.
--- `withNote` is true when Shift was held on the confirming click — Premade uses it
--- to leave the application dialog open for manual note entry instead of auto-confirming.
local function MakeOnClick(signUpFn, mode)
    return function(self, button)
        if button ~= "LeftButton" then return end
        if not SmartLFG.DB.Get("enabled") then return end
        if not SmartLFG.IsPlayerSoloOrLeader() then return end
        local now = GetTime()
        if (now - lastFireTime) < SAME_CLICK_WINDOW then
            lastFireTime = now
            return
        end
        lastFireTime = now
        if mode ~= lastClickMode then lastClickTime = 0 end
        lastClickMode = mode
        if (now - lastClickTime) <= SmartLFG.DOUBLE_CLICK_THRESHOLD then
            lastClickTime = 0
            lastClickMode = nil
            signUpFn(self, IsShiftKeyDown())
        else
            lastClickTime = now
        end
    end
end

local OnClickLFD = MakeOnClick(function(_)
    SmartLFG.RoleManager.SignUp()
end, "LFD")

--- Premade click: capture result ID and activity name from the row frame.
--- withNote (Shift+double-click) arms note mode so the application dialog
--- stays open for the player to add a note instead of being auto-confirmed.
local OnClickPremade = MakeOnClick(function(frame, withNote)
    local resultID = GetPremadeResultIDFromChain(frame)
    local actName  = GetActivityNameFromFrame(frame)
    SmartLFG.RoleManager.ApplyToGroup(resultID, actName, withNote)
end, "PREMADE")

--- Hooks Group Finder row interactions (double-click + tooltip hint).
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
    local resultID = GetPremadeResultID(frame)
    local actName  = GetActivityNameFromFrame(frame)
    if resultID and actName and actName ~= "" then
        SmartLFG.RoleManager.CacheActivityName(resultID, actName)
    end
end

--- Hooks legacy Premade ScrollFrame buttons when present.
--- @param scrollFrame table|nil
local function HookScrollButtons(scrollFrame)
    if not scrollFrame or not scrollFrame.buttons then return end
    for _, btn in ipairs(scrollFrame.buttons) do HookFramePremade(btn) end
end

--- Hooks visible ScrollBox row frames and re-hooks on layout changes.
--- Returns true when found — caller must NOT also hook parent frames (dual-fire).
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

--- Hook the Group Finder. Called when Blizzard_LookingForGroup loads.
--- Only hooks LFGParentFrame as a fallback when no individual row buttons are found.
--- Hooking both the parent and its children causes dual-fire: OnMouseDown propagates
--- up the frame tree, so a single click on a child would fire two handlers.
function FH.HookLFD()
    local frame = LFGParentFrame
    if not frame then return false end

    local hookedAny = false
    for i = 1, 30 do
        local btn = _G["LFGDungeonListButton" .. i]
        if btn then
            HookFrameLFD(btn)
            hookedAny = true
        end
    end

    if not hookedAny then
        HookFrameLFD(frame)
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

    local appDialog = LFGListApplicationDialog
    if appDialog and not onShowHooked[appDialog] then
        appDialog:HookScript("OnShow", function()
            local actName = appDialog.ActivityName
                and type(appDialog.ActivityName.GetText) == "function"
                and appDialog.ActivityName:GetText()
            if actName and actName ~= "" then
                SmartLFG.RoleManager.SetPendingActivityLabel(actName)
            end

            if not SmartLFG.DB.Get("enabled") then return end
            if not SmartLFG.IsPlayerSoloOrLeader() then return end
            if SmartLFG.RoleManager.IsNoteMode() then
                SmartLFG.RoleManager.SetNoteMode(false)
                return
            end

            local btn = appDialog.SignUpButton
            if btn and btn:IsEnabled() then btn:Click() end
        end)
        onShowHooked[appDialog] = true
    end

    local panel = frame.SearchPanel
    if panel then
        local hookedViaScrollBox = HookScrollBox(panel.ScrollBox)
        if not hookedViaScrollBox then
            HookFramePremade(frame)
            HookFramePremade(panel)
            HookScrollButtons(panel.ScrollFrame)
        end
    else
        HookFramePremade(frame)
    end

    if not onShowHooked[frame] then
        frame:HookScript("OnShow", FH.HookLFGList)
        onShowHooked[frame] = true
    end
    return true
end
