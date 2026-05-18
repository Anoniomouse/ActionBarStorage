local ABS = ActionBarStorage

-- ── Layout constants ─────────────────────────────────────────────────────────
local FRAME_W  = 640
local FRAME_H  = 480
local LIST_W   = 196
local PAD      = 8

-- ── Widget helpers ────────────────────────────────────────────────────────────
local function Btn(parent, w, h, text)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h)
    b:SetText(text)
    return b
end

local function Label(parent, fontObj, text, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", fontObj or "GameFontNormal")
    if text       then fs:SetText(text) end
    if r          then fs:SetTextColor(r, g, b, 1) end
    return fs
end

-- ── Main window ───────────────────────────────────────────────────────────────
local main = CreateFrame("Frame", "ABS_Main", UIParent, "BasicFrameTemplate")
main:SetSize(FRAME_W, FRAME_H)
main:SetPoint("CENTER")
main:SetMovable(true)
main:EnableMouse(true)
main:RegisterForDrag("LeftButton")
main:SetScript("OnDragStart", main.StartMoving)
main:SetScript("OnDragStop",  main.StopMovingOrSizing)
main:SetClampedToScreen(true)
main:Hide()
main.TitleText:SetText("Action Bar Storage")
table.insert(UISpecialFrames, "ABS_Main")

-- Create our own content area below the title bar and inside the borders
local ins = CreateFrame("Frame", nil, main)
ins:SetPoint("TOPLEFT",     main, "TOPLEFT",     6, -26)
ins:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -6,   6)

-- ── Left panel: profile list ──────────────────────────────────────────────────
local listHeader = Label(ins, "GameFontNormalLarge", "Profiles", 1, 0.82, 0)
listHeader:SetPoint("TOPLEFT", ins, "TOPLEFT", PAD, -PAD)

local listScroll = CreateFrame("ScrollFrame", nil, ins, "UIPanelScrollFrameTemplate")
listScroll:SetPoint("TOPLEFT",    listHeader, "BOTTOMLEFT", 0, -4)
listScroll:SetPoint("BOTTOMLEFT", ins, "BOTTOMLEFT", PAD, 44)
listScroll:SetWidth(LIST_W - 22)

local listChild = CreateFrame("Frame", nil, listScroll)
listChild:SetWidth(LIST_W - 22)
listChild:SetHeight(10)
listScroll:SetScrollChild(listChild)

local newBtn = Btn(ins, LIST_W, 26, "New Profile")
newBtn:SetPoint("BOTTOMLEFT", ins, "BOTTOMLEFT", PAD, 10)

-- Vertical divider between panels
local divider = ins:CreateTexture(nil, "BACKGROUND")
divider:SetColorTexture(0.3, 0.3, 0.3, 1)
divider:SetWidth(1)
divider:SetPoint("TOPLEFT",    ins, "TOPLEFT",    LIST_W + PAD * 2, -PAD)
divider:SetPoint("BOTTOMLEFT", ins, "BOTTOMLEFT", LIST_W + PAD * 2,  PAD)

-- ── Right panel: detail view ──────────────────────────────────────────────────
local detailX = LIST_W + PAD * 3

local detTitle = Label(ins, "GameFontNormalLarge")
detTitle:SetPoint("TOPLEFT", ins, "TOPLEFT", detailX, -PAD)
detTitle:SetJustifyH("LEFT")

local detMeta = Label(ins, "GameFontNormalSmall", nil, 0.6, 0.6, 0.6)
detMeta:SetPoint("TOPLEFT", detTitle, "BOTTOMLEFT", 0, -2)

-- Placeholder shown when no profile is selected
local detEmpty = Label(ins, "GameFontNormal",
    "Select a profile to view its details,\nor click New Profile to create one.",
    0.5, 0.5, 0.5)
detEmpty:SetPoint("CENTER", ins, "CENTER", LIST_W / 2, 10)
detEmpty:SetJustifyH("CENTER")

local detScroll = CreateFrame("ScrollFrame", nil, ins, "UIPanelScrollFrameTemplate")
detScroll:SetPoint("TOPLEFT",    detMeta, "BOTTOMLEFT", 0, -6)
detScroll:SetPoint("BOTTOMRIGHT", ins, "BOTTOMRIGHT", -26, 44)

local detChild = CreateFrame("Frame", nil, detScroll)
local detContentW = FRAME_W - LIST_W - PAD * 4 - 30
detChild:SetWidth(detContentW)
detChild:SetHeight(10)
detScroll:SetScrollChild(detChild)

local detText = detChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
detText:SetPoint("TOPLEFT")
detText:SetWidth(detContentW)
detText:SetJustifyH("LEFT")
detText:SetSpacing(2)

-- Action buttons at the bottom of the detail panel
local applyBtn  = Btn(ins, 110, 26, "Apply Profile")
local renameBtn = Btn(ins, 80,  26, "Rename")
local deleteBtn = Btn(ins, 80,  26, "Delete")
applyBtn:SetPoint( "BOTTOMLEFT",  ins, "BOTTOMLEFT",  detailX, 10)
renameBtn:SetPoint("LEFT", applyBtn, "RIGHT", 6, 0)
deleteBtn:SetPoint("BOTTOMRIGHT", ins, "BOTTOMRIGHT", -4, 10)
applyBtn:SetEnabled(false)
renameBtn:SetEnabled(false)
deleteBtn:SetEnabled(false)

-- ── State ─────────────────────────────────────────────────────────────────────
local selectedProfile = nil
local listButtons     = {}   -- reusable button pool for the profile list

-- ── Detail panel rendering ────────────────────────────────────────────────────
local function RenderDetail(profileName)
    local p = ABS.db.profiles[profileName]
    if not p then return end

    detEmpty:Hide()
    detTitle:SetText(p.name)
    detMeta:SetText(string.format("Saved by %s  |  %s", p.savedBy or "?", p.savedOn or "?"))

    local lines = {}
    for barId = 1, #ABS.BARS do
        local bd = p.bars[barId]
        if bd then
            table.insert(lines, "|cffFFD100▸ " .. (bd.label or ("Bar " .. barId)) .. "|r")
            local hasContent = false
            for slotIdx, sd in ipairs(bd.slots) do
                if sd.actionType ~= "" and sd.id then
                    hasContent = true
                    local colorCode = "|cffffffff"
                    if sd.actionType == "macro" then colorCode = "|cffaaaaff" end
                    if sd.actionType == "item"  then colorCode = "|cffffcc55" end
                    table.insert(lines, string.format("   %2d: %s%s|r", slotIdx, colorCode, sd.name or ""))
                end
            end
            if not hasContent then
                table.insert(lines, "   |cff666666(no actions saved)|r")
            end
            table.insert(lines, "")
        end
    end

    detText:SetText(table.concat(lines, "\n"))
    detChild:SetHeight(math.max(detText:GetStringHeight() + 10, 10))
end

-- ── Profile list rendering ────────────────────────────────────────────────────
local function RefreshList()
    for _, b in ipairs(listButtons) do b:Hide() end

    local names = ABS:GetSortedProfiles()
    local yOff  = 0

    for i, name in ipairs(names) do
        local b = listButtons[i]
        if not b then
            b = CreateFrame("Button", nil, listChild)
            b:SetSize(LIST_W - 22, 24)
            b:SetNormalFontObject("GameFontNormal")
            b:GetFontString():SetJustifyH("LEFT")
            b:GetFontString():SetPoint("LEFT", b, "LEFT", 6, 0)
            b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            b.selTex = b:CreateTexture(nil, "BACKGROUND")
            b.selTex:SetAllPoints()
            b.selTex:SetColorTexture(1, 0.82, 0, 0.12)
            listButtons[i] = b
        end

        b:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -yOff)
        b:SetText(name)
        b.selTex:SetShown(name == selectedProfile)
        b:Show()

        local capName = name
        b:SetScript("OnClick", function()
            selectedProfile = capName
            RenderDetail(capName)
            applyBtn:SetEnabled(true)
            renameBtn:SetEnabled(true)
            deleteBtn:SetEnabled(true)
            for _, lb in ipairs(listButtons) do
                if lb.selTex then lb.selTex:SetShown(lb:GetText() == selectedProfile) end
            end
        end)

        yOff = yOff + 26
    end

    listChild:SetHeight(math.max(yOff, 10))
end

-- ── Apply ─────────────────────────────────────────────────────────────────────
applyBtn:SetScript("OnClick", function()
    if selectedProfile then
        ABS:ApplyProfile(selectedProfile, nil)
    end
end)

-- ── Delete ────────────────────────────────────────────────────────────────────
deleteBtn:SetScript("OnClick", function()
    if not selectedProfile then return end
    local target = selectedProfile
    StaticPopupDialogs["ABS_DELETE"] = {
        text        = 'Delete profile "|cffFFD100' .. target .. '|r"?',
        button1     = "Delete",
        button2     = "Cancel",
        OnAccept    = function()
            ABS:DeleteProfile(target)
            selectedProfile = nil
            detTitle:SetText("")
            detMeta:SetText("")
            detText:SetText("")
            detEmpty:Show()
            applyBtn:SetEnabled(false)
            renameBtn:SetEnabled(false)
            deleteBtn:SetEnabled(false)
            RefreshList()
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopup_Show("ABS_DELETE")
end)

-- ── Rename ────────────────────────────────────────────────────────────────────
renameBtn:SetScript("OnClick", function()
    if not selectedProfile then return end
    local old = selectedProfile
    StaticPopupDialogs["ABS_RENAME"] = {
        text        = "Enter a new name for the profile:",
        button1     = "Rename",
        button2     = "Cancel",
        hasEditBox  = true,
        OnShow      = function(d) d.editBox:SetText(old); d.editBox:HighlightText() end,
        OnAccept    = function(d)
            local new = d.editBox:GetText():match("^%s*(.-)%s*$")
            if not new or new == "" then return end
            if ABS:RenameProfile(old, new) then
                selectedProfile = new
                RefreshList()
                RenderDetail(new)
            else
                print("|cffFF4444[Action Bar Storage]|r That name is already in use.")
            end
        end,
        EditBoxOnEnterPressed = function(eb) eb:GetParent().button1:Click() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopup_Show("ABS_RENAME")
end)

-- ── Bar selector overlay ──────────────────────────────────────────────────────
local sel = {
    active   = false,
    chosen   = {},
    overlays = {},
    onDone   = nil,
}

local function BuildOverlay(barId)
    local ov = CreateFrame("Button", nil, UIParent)
    ov:SetFrameLevel(200)
    ov:EnableMouse(true)
    ov:Hide()

    -- Semi-transparent background so the bar is still visible underneath
    ov.bg = ov:CreateTexture(nil, "BACKGROUND")
    ov.bg:SetAllPoints()
    ov.bg:SetColorTexture(0, 0, 0, 0.3)

    -- Border glow shown on hover and when selected
    ov.glow = ov:CreateTexture(nil, "OVERLAY")
    ov.glow:SetAllPoints()
    ov.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    ov.glow:SetBlendMode("ADD")
    ov.glow:Hide()

    -- Checkmark shown when bar is selected
    ov.check = ov:CreateTexture(nil, "OVERLAY")
    ov.check:SetSize(28, 28)
    ov.check:SetPoint("TOPRIGHT", -4, -4)
    ov.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    ov.check:Hide()

    -- Bar label centered on the overlay
    ov.lbl = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ov.lbl:SetPoint("CENTER")
    ov.lbl:SetText(ABS.BARS[barId].label)
    ov.lbl:SetTextColor(1, 1, 1, 1)

    ov:SetScript("OnEnter", function(self)
        if sel.active and not sel.chosen[barId] then
            self.glow:Show()
            self.glow:SetVertexColor(1, 0.82, 0, 0.85)
        end
    end)
    ov:SetScript("OnLeave", function(self)
        if sel.active and not sel.chosen[barId] then
            self.glow:Hide()
        end
    end)
    ov:SetScript("OnClick", function(self)
        if not sel.active then return end
        if sel.chosen[barId] then
            sel.chosen[barId] = nil
            self.check:Hide()
            self.glow:Hide()
        else
            sel.chosen[barId] = true
            self.check:Show()
            self.glow:Show()
            self.glow:SetVertexColor(0.1, 0.9, 0.1, 0.85)
        end
    end)

    return ov
end

local selPanel

local function StopSelector()
    sel.active = false
    sel.chosen = {}
    for _, ov in pairs(sel.overlays) do ov:Hide() end
    if selPanel then selPanel:Hide() end
    main:Show()
    RefreshList()
end

local function StartSelector(onDone)
    sel.active = true
    sel.chosen = {}
    sel.onDone = onDone
    main:Hide()

    for barId = 1, #ABS.BARS do
        if not sel.overlays[barId] then
            sel.overlays[barId] = BuildOverlay(barId)
        end
        local ov      = sel.overlays[barId]
        local barFrame = ABS:GetBarFrame(barId)
        ov.check:Hide()
        ov.glow:Hide()
        if barFrame then
            ov:SetAllPoints(barFrame)
            ov:Show()
        else
            ov:Hide()
        end
    end

    if not selPanel then
        selPanel = CreateFrame("Frame", "ABS_SelPanel", UIParent, "BasicFrameTemplate")
        selPanel:SetSize(300, 96)
        selPanel:SetPoint("TOP", UIParent, "TOP", 0, -60)
        selPanel:SetMovable(true)
        selPanel:EnableMouse(true)
        selPanel:RegisterForDrag("LeftButton")
        selPanel:SetScript("OnDragStart", selPanel.StartMoving)
        selPanel:SetScript("OnDragStop",  selPanel.StopMovingOrSizing)
        selPanel.TitleText:SetText("Select Bars")

        local instr = selPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        instr:SetPoint("TOPLEFT", 10, -24)
        instr:SetText("Hover over an action bar and click it to\nselect it. Click again to deselect.")
        instr:SetJustifyH("LEFT")

        local allBtn     = Btn(selPanel, 60,  22, "All")
        local confirmBtn = Btn(selPanel, 70,  22, "Confirm")
        local cancelBtn  = Btn(selPanel, 65,  22, "Cancel")
        allBtn:SetPoint(    "BOTTOMLEFT",  selPanel, "BOTTOMLEFT", 8, 8)
        confirmBtn:SetPoint("LEFT", allBtn, "RIGHT", 4, 0)
        cancelBtn:SetPoint( "LEFT", confirmBtn, "RIGHT", 4, 0)

        allBtn:SetScript("OnClick", function()
            for barId = 1, #ABS.BARS do
                local ov = sel.overlays[barId]
                if ov and ov:IsShown() then
                    sel.chosen[barId] = true
                    ov.check:Show()
                    ov.glow:Show()
                    ov.glow:SetVertexColor(0.1, 0.9, 0.1, 0.85)
                end
            end
        end)

        confirmBtn:SetScript("OnClick", function()
            local ids = {}
            for barId in pairs(sel.chosen) do
                table.insert(ids, barId)
            end
            table.sort(ids)
            local cb = sel.onDone
            StopSelector()
            if cb and #ids > 0 then
                cb(ids)
            else
                print("|cffFF4444[Action Bar Storage]|r No bars selected — profile not saved.")
            end
        end)

        cancelBtn:SetScript("OnClick", StopSelector)
    end

    selPanel:Show()
end

-- ── New profile flow ──────────────────────────────────────────────────────────
newBtn:SetScript("OnClick", function()
    StaticPopupDialogs["ABS_NEW"] = {
        text        = "Enter a name for the new profile:",
        button1     = "Next \226\134\146",
        button2     = "Cancel",
        hasEditBox  = true,
        OnAccept    = function(d)
            local name = d.editBox:GetText():match("^%s*(.-)%s*$")
            if not name or name == "" then return end
            if ABS.db.profiles[name] then
                print("|cffFF4444[Action Bar Storage]|r Profile \"" .. name .. "\" already exists.")
                return
            end
            StartSelector(function(barIds)
                ABS:SaveProfile(name, barIds)
                selectedProfile = name
                RefreshList()
                RenderDetail(name)
                applyBtn:SetEnabled(true)
                renameBtn:SetEnabled(true)
                deleteBtn:SetEnabled(true)
                print("|cff00ccff[Action Bar Storage]|r Profile \"" .. name .. "\" saved (" .. #barIds .. " bar(s)).")
            end)
        end,
        EditBoxOnEnterPressed = function(eb) eb:GetParent().button1:Click() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopup_Show("ABS_NEW")
end)

-- ── Public API ────────────────────────────────────────────────────────────────
function ABS:ToggleUI()
    if main:IsShown() then
        main:Hide()
    else
        RefreshList()
        if selectedProfile and self.db.profiles[selectedProfile] then
            RenderDetail(selectedProfile)
            detEmpty:Hide()
            applyBtn:SetEnabled(true)
            renameBtn:SetEnabled(true)
            deleteBtn:SetEnabled(true)
        else
            detEmpty:Show()
            detTitle:SetText("")
            detMeta:SetText("")
            detText:SetText("")
            applyBtn:SetEnabled(false)
            renameBtn:SetEnabled(false)
            deleteBtn:SetEnabled(false)
        end
        main:Show()
    end
end
