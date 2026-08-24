local _, SmartLFG = ...
local GameTooltip = _G.GameTooltip

SmartLFG.FrameHook = {}
local FH = SmartLFG.FrameHook

local lastSignUpTime  = 0
local SIGN_UP_COOLDOWN = 0.5

local hookedFrames    = {}
local onShowHooked    = {}
local scrollBoxHooked = {}
local tooltipHooked   = {}
local creationHooked  = false  -- one-shot guard for the GroupCreation function hooks
local TOOLTIP_OWNER_MAX_DEPTH = 6

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

local function IsPremadeSignUpAvailable(resultID)
    if resultID and C_LFGList and C_LFGList.GetSearchResultInfo then
        local info = C_LFGList.GetSearchResultInfo(resultID)
        return info and not info.isDelisted and not info.delisted
    end
    local panel = LFGListFrame and LFGListFrame.SearchPanel
    local signUpBtn = panel and panel.SignUpButton
    return signUpBtn and signUpBtn.IsEnabled and signUpBtn:IsEnabled()
end

local function CanShowTooltipHint(frame, mode, resultID)
    if not SmartLFG.DB.Get("enabled")
        or not SmartLFG.IsPlayerSoloOrLeader()
    then
        return false
    end
    if mode == "LFD" and GetLFGMode(LE_LFG_CATEGORY_LFD) then
        return false
    end
    if mode == "PREMADE" then
        if not SmartLFG.DB.Get("quickSignUp") then return false end
        if not IsPremadeSignUpAvailable(resultID) then return false end
    end
    if frame and frame.IsEnabled and not frame:IsEnabled() then return false end
    return true
end

local function HookTooltip(frame, mode)
    if not frame or tooltipHooked[frame] then return end
    tooltipHooked[frame] = true
    frame:HookScript("OnEnter", function(self)
        local resultID = (mode == "PREMADE") and GetPremadeResultIDFromChain(self) or nil
        if not CanShowTooltipHint(self, mode, resultID) then return end
        if GameTooltip:GetOwner() ~= self then return end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(SmartLFG.L.TOOLTIP_QUICK_SIGNUP, 0, 1, 1, true)
        GameTooltip:AddLine(SmartLFG.L.TOOLTIP_SHIFT_NOTE, 0, 1, 1, true)
        GameTooltip:Show()
    end)
end


local function OnDoubleClickLFD(_, button)
    if button ~= "LeftButton" then return end
    if not SmartLFG.DB.Get("enabled") then return end
    if not SmartLFG.IsPlayerSoloOrLeader() then return end
    local now = GetTime()
    if (now - lastSignUpTime) < SIGN_UP_COOLDOWN then return end
    lastSignUpTime = now
    SmartLFG.RoleManager.SignUp()
end

local function OnDoubleClickPremade(_, button)
    if button ~= "LeftButton" then return end
    if not SmartLFG.DB.Get("enabled") then return end
    if not SmartLFG.DB.Get("quickSignUp") then return end
    if not SmartLFG.IsPlayerSoloOrLeader() then return end
    SmartLFG.RoleManager.ApplyToGroup(IsShiftKeyDown())
end

local function HookFrameLFD(frame)
    if not frame then return end
    if not hookedFrames[frame] then
        frame:RegisterForClicks("AnyUp")
        frame:HookScript("OnDoubleClick", OnDoubleClickLFD)
        hookedFrames[frame] = true
    end
    HookTooltip(frame, "LFD")
end

local function HookFramePremade(frame)
    if not frame then return end
    if not hookedFrames[frame] then
        frame:RegisterForClicks("AnyUp")
        frame:HookScript("OnDoubleClick", OnDoubleClickPremade)
        hookedFrames[frame] = true
    end
    HookTooltip(frame, "PREMADE")
end

local function HookScrollButtons(scrollFrame)
    if not scrollFrame or not scrollFrame.buttons then return end
    for _, btn in ipairs(scrollFrame.buttons) do HookFramePremade(btn) end
end

local function HookScrollBoxChildren(scrollBox)
    if scrollBox.ForEachFrame then
        scrollBox:ForEachFrame(HookFramePremade)
    end
    if scrollBox.GetScrollTarget then
        local target = scrollBox:GetScrollTarget()
        if target and target.GetChildren then
            for _, child in ipairs({ target:GetChildren() }) do
                if child and child.GetObjectType and child:GetObjectType() == "Button" then
                    HookFramePremade(child)
                end
            end
        end
    end
end

local function HookScrollBox(scrollBox)
    if not scrollBox then return false end
    HookScrollBoxChildren(scrollBox)
    if not scrollBoxHooked[scrollBox] and scrollBox.RegisterCallback and BaseScrollBoxEvents then
        scrollBox:RegisterCallback(BaseScrollBoxEvents.OnLayout, function()
            HookScrollBoxChildren(scrollBox)
        end, scrollBox)
        scrollBoxHooked[scrollBox] = true
    end
    return true
end

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

-- Restore the remembered note into the dialog's note box, deferred to the next
-- frame so we're outside the secure popup-show (where a write is blocked). The
-- write is pcall-guarded: if security still forbids it, we degrade silently to
-- "type it yourself" with no error spam.
local function RestoreNote(dialog)
    local note = SmartLFG.RoleManager.GetNote()
    if note == "" then return end
    C_Timer.After(0, function()
        local eb = dialog.Description and dialog.Description.EditBox
        if not (eb and eb.GetText and eb.SetText) then return end
        if eb:GetText() ~= "" then return end  -- don't clobber existing text
        pcall(eb.SetText, eb, note)
    end)
end

function FH.HookLFGList()
    local frame = LFGListFrame
    if not frame then return false end

    -- Hook the result rows FIRST so double-click + tooltip are always installed,
    -- even if the application-dialog hooking below ever hits a snag.
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

    -- Application dialog: auto-submit on plain double-click, or hold open for a
    -- note on Shift+double-click. We never touch the dialog's secure widgets
    -- (note box / role checks) — that taints the flow and blocks the sign-up.
    local appDialog = LFGListApplicationDialog
    if appDialog and not onShowHooked[appDialog] then
        appDialog:HookScript("OnShow", function()
            -- The dialog opened: stamp the live sign-up token so the conflict
            -- self-check knows our pipeline reached this point. Done before the
            -- gates so it records regardless of mode/settings.
            SmartLFG.RoleManager.NotifyDialogShown()
            if not SmartLFG.DB.Get("enabled") then return end
            if not SmartLFG.DB.Get("quickSignUp") then return end
            if not SmartLFG.IsPlayerSoloOrLeader() then return end

            -- Shift+double-click: hold the dialog open and try to restore the
            -- remembered note so the player can edit/submit it themselves.
            if SmartLFG.RoleManager.IsNoteMode() then
                SmartLFG.RoleManager.SetNoteMode(false)
                RestoreNote(appDialog)
                return
            end

            -- Plain double-click: submit immediately.
            local btn = appDialog.SignUpButton
            if btn and btn:IsEnabled() then btn:Click() end
        end)

        -- Remember whatever note is submitted (reading the box is safe), so it
        -- can be restored on the next Shift+double-click.
        local signUp = appDialog.SignUpButton
        if signUp and signUp.HookScript then
            signUp:HookScript("OnClick", function()
                local eb = appDialog.Description and appDialog.Description.EditBox
                local text = eb and eb.GetText and eb:GetText()
                if text and text ~= "" then
                    SmartLFG.RoleManager.SetNote(text)
                end
            end)
        end

        onShowHooked[appDialog] = true
    end

    -- Group creation (Dungeons): "Enhanced listing" pre-selects Mythic+ and a
    -- Competitive playstyle on "Start a Group". See GroupCreation.
    local entryCreation = frame.EntryCreation
    if entryCreation and not onShowHooked[entryCreation] then
        entryCreation:HookScript("OnShow", SmartLFG.GroupCreation.OnEntryCreationShow)
        onShowHooked[entryCreation] = true
    end

    -- Two global-function hooks for the creation form. These are separate from
    -- the frame hooks above because Blizzard re-runs both on its own schedule
    -- (dropdown rebuilds, every selection change), so hooking the functions is
    -- the only way to stay applied:
    --   Select            → re-assert Mythic+ when the player switches dungeon
    --   SetupGroupDropdown → trim the dungeon list to the current M+ season
    -- Guarded by a one-shot flag since hooksecurefunc stacks on every call, and
    -- by an existence check on both globals — hooksecurefunc raises an error on
    -- a name that isn't a function, so a Blizzard rename must degrade to "these
    -- two behaviors are off", never to a Lua error on login.
    if not creationHooked and hooksecurefunc
        and LFGListEntryCreation_Select and LFGListEntryCreation_SetupGroupDropdown
    then
        hooksecurefunc("LFGListEntryCreation_Select", function(...)
            SmartLFG.GroupCreation.OnSelect(...)
        end)
        hooksecurefunc("LFGListEntryCreation_SetupGroupDropdown", function(...)
            SmartLFG.GroupCreation.OnSetupGroupDropdown(...)
        end)
        creationHooked = true
    end

    return true
end
