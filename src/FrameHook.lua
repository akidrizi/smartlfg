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

local addonName, SmartLFG = ...

SmartLFG.FrameHook = {}
local FH = SmartLFG.FrameHook

local lastClickTime     = 0
local lastFireTime      = 0
local SAME_CLICK_WINDOW = 0.05   -- 50 ms guard against propagated duplicate fires

local hookedFrames    = {}
local onShowHooked    = {}
local scrollBoxHooked = {}

--- Returns a click handler that calls signUpFn on confirmed double-click.
local function MakeOnClick(signUpFn)
    return function(self, button)
        if button ~= "LeftButton" then return end
        local now = GetTime()
        -- Discard propagated duplicate fires from the same physical click.
        if (now - lastFireTime) < SAME_CLICK_WINDOW then
            lastFireTime = now
            return
        end
        lastFireTime = now
        if (now - lastClickTime) <= SmartLFG.DOUBLE_CLICK_THRESHOLD then
            lastClickTime = 0
            signUpFn()
        else
            lastClickTime = now
        end
    end
end

local OnClickLFD     = MakeOnClick(function() SmartLFG.RoleManager.SignUp()       end)
local OnClickPremade = MakeOnClick(function() SmartLFG.RoleManager.ApplyToGroup() end)

local function HookFrameLFD(frame)
    if not frame or hookedFrames[frame] then return end
    frame:HookScript("OnMouseDown", OnClickLFD)
    hookedFrames[frame] = true
end

local function HookFramePremade(frame)
    if not frame or hookedFrames[frame] then return end
    frame:HookScript("OnMouseDown", OnClickPremade)
    hookedFrames[frame] = true
end

-- Legacy fallback for old-style ScrollFrame with a .buttons table.
local function HookScrollButtons(scrollFrame)
    if not scrollFrame or not scrollFrame.buttons then return end
    for _, btn in ipairs(scrollFrame.buttons) do HookFramePremade(btn) end
end

-- Hooks visible ScrollBox row frames and re-hooks on layout changes.
-- Returns true when found — caller must NOT also hook parent frames (dual-fire).
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
