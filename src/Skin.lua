local _, SmartLFG = ...

SmartLFG.Skin = {}
local Skin = SmartLFG.Skin

-- ── Optional skinning-addon support ─────────────────────────────────────────
-- Soft integration with the common UI-skinning addons. There is no dependency
-- on any of them: nothing here runs unless the addon is actually present, every
-- call into foreign code is pcall-guarded, and a failure leaves the widget on
-- Blizzard's stock look. Three things are handed over — the dialog's own frame
-- (backdrop + border), its close button, and the option checkboxes. The role
-- icons and the branded header are deliberately left alone; they are custom art,
-- not Blizzard widgets, and a skinner would only mangle them.
--
-- Two integration models are supported, and they differ in who controls timing:
--
--   push (EllesmereUI) — we register a callback and EUI invokes it when it is
--     ready, only if the user enabled skinning for SmartLFG in EUI's options.
--   pull (ElvUI, AddOnSkins, Aurora) — we call their functions ourselves, so we
--     are responsible for not calling before they are initialized.

-- Widgets handed over by Options.lua as it builds the dialog. They are skinned
-- later: the panel is built during ADDON_LOADED, long before any skinning addon
-- has finished initializing.
local closeButtons = {}
local checkBoxes   = {}
local panels       = {}

local claimed  = false  -- a provider took the job and finished applying
local provider = nil    -- which one; surfaced by Skin.GetProvider for diagnosis
local pushMode = false  -- EllesmereUI accepted our registration; it drives timing

function Skin.AddCloseButton(btn)
    if btn then closeButtons[#closeButtons + 1] = btn end
end

function Skin.AddCheckBox(cb)
    if cb then checkBoxes[#checkBoxes + 1] = cb end
end

-- `restore` re-applies our own backdrop. Skinning a whole frame is the one step
-- here that is genuinely recoverable: a provider that strips the panel and then
-- fails before painting its own template leaves an invisible window, and unlike
-- a half-stripped checkbox we know exactly what the panel looked like.
-- `redecorate` re-asserts our own artwork on the panel after a successful skin.
-- Skinners strip or fade the regions of a frame they restyle, which takes our
-- decorations with them — the tip diamond is a bare texture on the panel, so it
-- vanished under ElvUI until this existed.
function Skin.AddPanel(frame, restore, redecorate)
    if frame then
        panels[#panels + 1] = { frame = frame, restore = restore, redecorate = redecorate }
    end
end

-- Runs `skin` on every registered panel, putting our backdrop back on any that
-- it fails on. Providers pass a one-argument function; the pcall is here, so no
-- provider has to remember it.
local function SkinPanels(skin)
    for _, entry in ipairs(panels) do
        if pcall(skin, entry.frame) then
            if entry.redecorate then pcall(entry.redecorate, entry.frame) end
        elseif entry.restore then
            pcall(entry.restore, entry.frame)
        end
    end
end

-- Our checkboxes widen their hit rect across the label so clicking the text
-- toggles them (see Options.CreateCheck). A skinner is free to reset that while
-- restyling, so re-assert it afterwards rather than silently losing the
-- behavior. Guarded like everything else — a skinner may also have replaced the
-- label, in which case there is nothing to restore.
local function RestoreCheckBoxHitRect(cb)
    local label = cb and cb.label
    if not (label and label.GetStringWidth and cb.SetHitRectInsets) then return end
    pcall(cb.SetHitRectInsets, cb, 0, -(label:GetStringWidth() + 8), 0, 0)
end

-- ── EllesmereUI (push) ──────────────────────────────────────────────────────
-- EUI drives its own timing: the callback fires at PLAYER_LOGIN, or immediately
-- when registered after login, and only when the user has enabled skinning for
-- SmartLFG in EUI's options. EUI also isolates errors raised inside the
-- callback, so this needs no readiness probe — registering is enough. Every
-- primitive is documented as idempotent, so a repeat call is harmless.
-- SmartLFG.toc carries "## OptionalDeps: EllesmereUI" so EUI loads first.
local function RegisterEllesmereUI()
    local EUI = _G.EllesmereUI
    if type(EUI) ~= "table" or type(EUI.RegisterSkin) ~= "function" then return false end

    local ok = pcall(EUI.RegisterSkin, "SmartLFG", function(S)
        if type(S) ~= "table" then return end
        -- S.Shell is EUI's primary-window treatment: it fades the existing art
        -- and paints the theme backdrop plus window border. S.Panel is the
        -- flat sub-frame/popup variant and is the wrong shape for a dialog.
        if type(S.Shell) == "function" then
            SkinPanels(S.Shell)
        end
        if type(S.CloseButton) == "function" then
            for _, btn in ipairs(closeButtons) do pcall(S.CloseButton, btn) end
        end
        if type(S.Checkbox) == "function" then
            for _, cb in ipairs(checkBoxes) do
                pcall(S.Checkbox, cb)
                RestoreCheckBoxHitRect(cb)
            end
        end
    end)
    return ok
end

-- ── ElvUI (pull) ────────────────────────────────────────────────────────────
-- Returns the Skins module only once it is fully initialized. That check is the
-- whole point of this function: ElvUI's HandleCheckBox calls StripTextures() on
-- the widget *before* it reads its own saved settings, so calling too early
-- raises partway through and leaves an invisible checkbox. A pcall stops the
-- error but cannot undo the strip — "not ready" has to mean "don't touch it".
local function ElvUISkins()
    local engine = _G.ElvUI
    if type(engine) ~= "table" then return nil end

    local unpacked, E = pcall(unpack, engine)
    if not unpacked or type(E) ~= "table" or type(E.GetModule) ~= "function" then return nil end

    local got, S = pcall(E.GetModule, E, "Skins")
    if not got or type(S) ~= "table" or not S.Initialized then return nil end
    return S
end

local function ApplyElvUI()
    local S = ElvUISkins()
    if not S then return false end

    -- SetTemplate, NOT S:HandleFrame. HandleFrame calls StripTextures() first,
    -- which is meant to clear Blizzard's frame art — but our panel is our own
    -- construction, so the only things it strips are ours (it ate the tip
    -- diamond). SetTemplate applies the same ElvUI backdrop and border without
    -- touching any region. ElvUI injects it into the frame metatable, so it is
    -- present on our panel regardless of load order.
    SkinPanels(function(f)
        if type(f.SetTemplate) == "function" then f:SetTemplate("Transparent") end
    end)
    if type(S.HandleCloseButton) == "function" then
        for _, btn in ipairs(closeButtons) do pcall(S.HandleCloseButton, S, btn) end
    end
    if type(S.HandleCheckBox) == "function" then
        for _, cb in ipairs(checkBoxes) do
            pcall(S.HandleCheckBox, S, cb)
            RestoreCheckBoxHitRect(cb)
        end
    end
    return true
end

-- ── AddOnSkins (pull) ───────────────────────────────────────────────────────
-- AddOnSkins is a standalone skinner with its own Skins module and its own saved
-- profile — it does NOT route into ElvUI. Its HandleCheckBox has the same shape
-- of hazard as ElvUI's though: it strips the widget's textures and only then
-- reads AS.db via AS:CheckOption, so an uninitialized profile means an error
-- after the strip. AS.db is populated when its profile loads, so that is the
-- readiness signal.
local function ApplyAddOnSkins()
    local engine = _G.AddOnSkins
    if type(engine) ~= "table" then return false end

    local unpacked, AS = pcall(unpack, engine)
    if not unpacked or type(AS) ~= "table" then return false end
    if type(AS.db) ~= "table" or type(AS.Skins) ~= "table" then return false end

    -- AS:SetTemplate, not AS:SkinFrame — SkinFrame routes to its HandleFrame,
    -- which strips the frame's regions just as ElvUI's does.
    if type(AS.SetTemplate) == "function" then
        SkinPanels(function(f) AS:SetTemplate(f) end)
    end
    if type(AS.SkinCloseButton) == "function" then
        for _, btn in ipairs(closeButtons) do pcall(AS.SkinCloseButton, AS, btn) end
    end
    if type(AS.SkinCheckBox) == "function" then
        for _, cb in ipairs(checkBoxes) do
            pcall(AS.SkinCheckBox, AS, cb)
            RestoreCheckBoxHitRect(cb)
        end
    end
    return true
end

-- ── Aurora (pull) ───────────────────────────────────────────────────────────
-- Modern Aurora exports a HASH table — { Base, Hook, Skin, Color, Util } — not
-- the { F, C } array the old Haleth-era API used. `unpack(_G.Aurora)` therefore
-- yields nothing, and an integration written against that old shape fails
-- silently: no error, simply nothing skinned. Aurora names its widget skins
-- after the Blizzard template they restyle, which lines up exactly with the
-- templates our own widgets are built from.
--
-- Aurora also offers Base.AddSkin(addonName, fn) as a registration hook, but we
-- stay on the pull path: AddSkin prints to chat on every login and asserts when
-- a name is registered twice, neither of which earns its keep here.
-- Base.SetBackdrop only adds a backdrop, so unlike the other two providers there
-- is no stripping to route around.
local function ApplyAurora()
    local A = _G.Aurora
    if type(A) ~= "table" then return false end

    local Base, S = A.Base, A.Skin
    if type(Base) ~= "table" or type(S) ~= "table" then return false end

    -- The skin functions read their colors from Aurora's saved config, so an
    -- unloaded config means an error partway through — the same failure shape
    -- guarded against on the ElvUI and AddOnSkins paths.
    if type(A.Color) ~= "table" or _G.AuroraConfig == nil then return false end

    if type(Base.SetBackdrop) == "function" then
        SkinPanels(Base.SetBackdrop)
    end
    if type(S.UIPanelCloseButton) == "function" then
        for _, btn in ipairs(closeButtons) do pcall(S.UIPanelCloseButton, btn) end
    end
    if type(S.UICheckButtonTemplate) == "function" then
        for _, cb in ipairs(checkBoxes) do
            pcall(S.UICheckButtonTemplate, cb)
            RestoreCheckBoxHitRect(cb)
        end
    end
    return true
end

-- Ordered providers for the pull model. The first one whose global is present
-- CLAIMS the job outright — even when it turns out not to be ready yet, in which
-- case this pass does nothing and the next Options.Open retries.
--
-- Exactly one provider may ever touch a widget. They do not recognise each
-- other's work: ElvUI marks a finished widget `IsSkinned`, AddOnSkins marks it
-- `isSkinned`, and neither reads the other's flag — so letting two of them run
-- would stack a second backdrop on top of the first rather than no-op. That is
-- the conflict this ordering exists to prevent, and it is why a provider that is
-- merely *not ready yet* still blocks the ones below it instead of falling
-- through.
--
-- Nothing here is reached by the skinners on their own: they only restyle
-- Blizzard frames and addons they explicitly support, and SmartLFG is in neither
-- list. Our dialog is skinned exactly when this file asks for it.
local PROVIDERS = {
    { global = "ElvUI",      apply = ApplyElvUI },
    { global = "AddOnSkins", apply = ApplyAddOnSkins },
    { global = "Aurora",     apply = ApplyAurora },
}

-- Register with the push-model skinners. Called once at ADDON_LOADED, after the
-- dialog exists so the widget lists are already populated.
function Skin.Init()
    pushMode = RegisterEllesmereUI()
end

-- Apply the pull-model skinners. Called from Options.Open rather than from
-- BuildPanel: by the time the player first opens the dialog, any skinning addon
-- has long since initialized. Retries on a later open if its provider was not
-- ready yet, and no-ops once a provider has applied.
function Skin.Apply()
    if claimed or pushMode then return end

    for _, entry in ipairs(PROVIDERS) do
        if _G[entry.global] ~= nil then
            claimed = entry.apply()
            if claimed then provider = entry.global end
            return
        end
    end

    claimed  = true      -- no skinning addon installed; nothing to retry
    provider = "none"
end

-- Diagnostic. Prints a two-line report — addon version and author, then the
-- skinning state — and returns the provider that restyled the
-- dialog plus every skinner detected as loaded. Two values, because the
-- interesting failures all live in the gap between them — "Aurora is installed"
-- and "Aurora skinned us" are very different statements, and nothing on screen
-- distinguishes them. The printed line is localized; the RETURN values stay
-- stable English tokens ("none"/"pending"/an addon name) so they can be compared
-- in code.
--
-- It calls Skin.Apply first so the answer is true even when asked before the
-- dialog has ever been opened; without that, a query on a fresh login reports
-- nothing no matter what is installed, because Apply only runs from O.Open.
--     /run SmartLFG.Skin.GetProvider()
function Skin.GetProvider()
    Skin.Apply()

    local seen = {}
    if _G.EllesmereUI ~= nil then seen[#seen + 1] = "EllesmereUI" end
    for _, entry in ipairs(PROVIDERS) do
        if _G[entry.global] ~= nil then seen[#seen + 1] = entry.global end
    end

    local active = pushMode and "EllesmereUI" or provider or "pending"
    local loaded = #seen > 0 and table.concat(seen, ", ") or "none loaded"

    -- Identity line first: this report exists to be pasted into a bug report,
    -- and "which version, whose build, which skinner" is the whole of what a
    -- maintainer needs to reproduce a skinning problem.
    local L, C = SmartLFG.L, SmartLFG.COLOR
    SmartLFG.Print(string.format(L.ABOUT_VERSION,
        C.ADDON .. SmartLFG.GetAddonVersion() .. C.RESET,
        C.ADDON .. SmartLFG.AUTHOR_URL .. C.RESET))

    local activeText
    if active == "pending" then
        activeText = L.SKIN_PENDING
    elseif active == "none" then
        activeText = L.SKIN_NONE
    else
        activeText = C.ADDON .. active .. C.RESET
    end
    SmartLFG.Print(string.format(L.SKIN_STATUS, activeText,
        #seen > 0 and table.concat(seen, ", ") or L.SKIN_NONE))

    return active, loaded
end
