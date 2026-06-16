-- Rotmire (Sporefall) fixate debuffs:
local SHROOMLING = 1221639
local FUNGLING   = 1299508

-- Defaults; overwritten by saved settings on load.
local defaults = {
    fontSize = 36,
    point    = "CENTER",
    relPoint = "CENTER",
    x        = 0,
    y        = 200,
    locked   = false,
}

-- ============================================================
-- Display frame
-- ============================================================
local f = CreateFrame("Frame", "LYSMushroomIdiotsFrame", UIParent)
f:SetSize(300, 50)
f:SetMovable(true)
f:EnableMouse(false)            -- only clickable while unlocked
f:RegisterForDrag("LeftButton")

f.text = f:CreateFontString(nil, "OVERLAY")
f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
f.text:SetFont(STANDARD_TEXT_FONT, 36, "OUTLINE")  -- initial font; resized later via ApplyFont
f.text:SetText("")

-- A faint backdrop only shown while unlocked, so there's something to grab.
f.bg = f:CreateTexture(nil, "BACKGROUND")
f.bg:SetAllPoints(f)
f.bg:SetColorTexture(0.1, 0.6, 0.1, 0.25)
f.bg:Hide()

-- Size the frame (drag hitbox + backdrop) to fit the current text, with padding.
local function ResizeToText()
    local w = f.text:GetStringWidth()
    local h = f.text:GetStringHeight()
    -- keep a sane minimum so the unlocked grab area is never tiny
    f:SetSize(math.max(w + 20, 80), math.max(h + 10, 30))
end

local function ApplyFont()
    local size = LYSMushroomIdiotsDB.fontSize
    f.text:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
    ResizeToText()
end

local function ApplyPosition()
    f:ClearAllPoints()
    f:SetPoint(LYSMushroomIdiotsDB.point, UIParent, LYSMushroomIdiotsDB.relPoint,
               LYSMushroomIdiotsDB.x, LYSMushroomIdiotsDB.y)
end

local function ApplyLock()
    if LYSMushroomIdiotsDB.locked then
        f:EnableMouse(false)
        f.bg:Hide()
        if f.text:GetText() == "" then f.text:SetText("") end
    else
        f:EnableMouse(true)
        f.bg:Show()
        -- show placeholder so there's something visible to drag
        if f.text:GetText() == "" then
            f.text:SetText("LYS - Mushroom Idiots")
            f.text:SetTextColor(1, 1, 1)
        end
    end
end

f:SetScript("OnDragStart", function(self) if not LYSMushroomIdiotsDB.locked then self:StartMoving() end end)
f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    LYSMushroomIdiotsDB.point, LYSMushroomIdiotsDB.relPoint = point, relPoint
    LYSMushroomIdiotsDB.x, LYSMushroomIdiotsDB.y = x, y
end)

-- ============================================================
-- Display logic (single source of truth)
-- ============================================================
local function Show(state)
    if state == "SHROOMLING" then
        f.text:SetText("Shroomling |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t")
        f.text:SetTextColor(0.6, 1, 0.6)
    elseif state == "FUNGLING" then
        f.text:SetText("Fungling |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t")
        f.text:SetTextColor(0.7, 0.5, 1)
    else
        -- when unlocked, keep the placeholder so the frame stays grabbable
        if not LYSMushroomIdiotsDB.locked then
            f.text:SetText("LYS - Mushroom Idiots")
            f.text:SetTextColor(1, 1, 1)
        else
            f.text:SetText("")
        end
    end
    ResizeToText()
end

local function UpdateText()
    if C_UnitAuras.GetPlayerAuraBySpellID(SHROOMLING) then
        Show("SHROOMLING")
    elseif C_UnitAuras.GetPlayerAuraBySpellID(FUNGLING) then
        Show("FUNGLING")
    else
        Show(nil)
    end
end

f:RegisterUnitEvent("UNIT_AURA", "player")
f:SetScript("OnEvent", function(_, event)
    if event == "UNIT_AURA" then UpdateText() end
end)

-- ============================================================
-- Options panel (Settings API, canvas layout)
-- ============================================================
local function BuildOptions()
    local panel = CreateFrame("Frame")
    panel.name = "LYS - Mushroom Idiots"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("LYS - Mushroom Idiots")

    -- Font size slider
    local sizeSlider = CreateFrame("Slider", "LYSMushroomIdiotsSizeSlider", panel, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", 20, -70)
    sizeSlider:SetMinMaxValues(12, 72)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetObeyStepOnDrag(true)
    sizeSlider:SetWidth(260)
    _G[sizeSlider:GetName() .. "Low"]:SetText("12")
    _G[sizeSlider:GetName() .. "High"]:SetText("72")
    _G[sizeSlider:GetName() .. "Text"]:SetText("Font Size")
    sizeSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        LYSMushroomIdiotsDB.fontSize = value
        _G[sizeSlider:GetName() .. "Text"]:SetText("Font Size: " .. value)
        ApplyFont()
    end)
    panel.sizeSlider = sizeSlider

    -- Lock checkbox
    local lock = CreateFrame("CheckButton", "LYSMushroomIdiotsLockCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    lock:SetPoint("TOPLEFT", 20, -120)
    lock.Text:SetText("Lock position (uncheck to drag the text)")
    lock:SetScript("OnClick", function(self)
        LYSMushroomIdiotsDB.locked = self:GetChecked()
        ApplyLock()
        UpdateText()
    end)
    panel.lock = lock

    -- Reset button
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(160, 24)
    reset:SetPoint("TOPLEFT", 20, -160)
    reset:SetText("Reset to defaults")
    reset:SetScript("OnClick", function()
        for k, v in pairs(defaults) do LYSMushroomIdiotsDB[k] = v end
        ApplyFont(); ApplyPosition(); ApplyLock(); UpdateText()
        sizeSlider:SetValue(LYSMushroomIdiotsDB.fontSize)
        lock:SetChecked(LYSMushroomIdiotsDB.locked)
    end)

    -- Sync widgets to current values whenever the panel is shown
    panel:SetScript("OnShow", function()
        sizeSlider:SetValue(LYSMushroomIdiotsDB.fontSize)
        lock:SetChecked(LYSMushroomIdiotsDB.locked)
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    return category
end

-- ============================================================
-- Init
-- ============================================================
local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function()
    local ok, err = pcall(function()
        LYSMushroomIdiotsDB = LYSMushroomIdiotsDB or {}
        for k, v in pairs(defaults) do
            if LYSMushroomIdiotsDB[k] == nil then LYSMushroomIdiotsDB[k] = v end
        end
        ApplyFont()
        ApplyPosition()
        ApplyLock()
        UpdateText()
        LYSMushroomIdiots_Category = BuildOptions()
    end)
    if not ok then
        print("|cffff4444LYS Mushroom Idiots init error:|r " .. tostring(err))
    else
        print("|cff66ff66LYS Mushroom Idiots:|r initialized OK. Type /mush to open options.")
    end
end)

-- ============================================================
-- Slash commands
--   /mush          -> open options
--   /mush s        -> preview Shroomling
--   /mush f        -> preview Fungling
--   /mush clear    -> re-sync to real auras
--   /mush hide     -> force the text blank right now
--   /mush lock     -> lock position (hides placeholder)
--   /mush unlock   -> unlock to drag
-- ============================================================
SLASH_MUSH1 = "/mush"
SLASH_MUSH2 = "/mushroom"
SlashCmdList["MUSH"] = function(msg)
    msg = msg:lower():gsub("%s+", "")
    if msg == "s" then
        Show("SHROOMLING")
    elseif msg == "f" then
        Show("FUNGLING")
    elseif msg == "clear" then
        UpdateText()
    elseif msg == "hide" then
        f.text:SetText("")
    elseif msg == "lock" then
        LYSMushroomIdiotsDB.locked = true
        ApplyLock()
        UpdateText()
        print("|cff66ff66LYS Mushroom Idiots:|r locked.")
    elseif msg == "unlock" then
        LYSMushroomIdiotsDB.locked = false
        ApplyLock()
        UpdateText()
        print("|cff66ff66LYS Mushroom Idiots:|r unlocked - drag the text, then /mush lock.")
    else
        Settings.OpenToCategory(LYSMushroomIdiots_Category:GetID())
    end
end
