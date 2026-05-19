local ABS = ActionBarStorage

-- ── Layout constants ──────────────────────────────────────────────────────────
local FRAME_W    = 720
local FRAME_H    = 520
local LIST_W     = 210
local PAD        = 10
local HDR_H      = 24
local SLOT_H     = 20
local BAR_GAP    =  5
local DLG_TITLE_H = 28
local DLG_W       = 350
local ROW_H       = 26

-- ── Widget helpers ────────────────────────────────────────────────────────────
local function Bg(f, r, g, b, a)
    local t = f:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints()
    t:SetColorTexture(r, g, b, a or 1)
    return t
end

-- Flat dark button; accent=true gives a gold-tinted variant
local function MakeBtn(parent, w, h, text, accent)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if accent then
        bg:SetColorTexture(0.20, 0.17, 0.07, 1)
    else
        bg:SetColorTexture(0.14, 0.15, 0.21, 1)
    end
    b.bg = bg

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 0.82, 0, 0.13)

    local pushed = b:CreateTexture(nil, "ARTWORK")
    pushed:SetAllPoints()
    pushed:SetColorTexture(0, 0, 0, 0.18)
    b:SetPushedTexture(pushed)

    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetAllPoints()
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
    if accent then
        fs:SetTextColor(1.0, 0.86, 0.28, 1)
    else
        fs:SetTextColor(0.80, 0.82, 0.92, 1)
    end
    fs:SetText(text)
    b:SetFontString(fs)
    b.fs = fs

    if accent then
        b:SetScript("OnEnable",  function() fs:SetTextColor(1.0,  0.86, 0.28, 1) end)
    else
        b:SetScript("OnEnable",  function() fs:SetTextColor(0.80, 0.82, 0.92, 1) end)
    end
    b:SetScript("OnDisable", function() fs:SetTextColor(0.28, 0.28, 0.36, 1) end)

    return b
end

-- Dark popup frame: border + title bar + close btn + body content area.
-- Returns the frame; frame.titleText and frame.body are exposed.
local function BuildDarkFrame(name, w, h)
    local d = CreateFrame("Frame", name, UIParent)
    d:SetSize(w, h)
    d:SetMovable(true)
    d:EnableMouse(true)
    d:SetClampedToScreen(true)
    d:SetFrameStrata("FULLSCREEN_DIALOG")
    d:Hide()
    if name then table.insert(UISpecialFrames, name) end
    Bg(d, 0.20, 0.22, 0.30, 1)

    local tb = CreateFrame("Frame", nil, d)
    tb:SetPoint("TOPLEFT",  d, "TOPLEFT",  1, -1)
    tb:SetPoint("TOPRIGHT", d, "TOPRIGHT", -1, -1)
    tb:SetHeight(DLG_TITLE_H)
    Bg(tb, 0.13, 0.14, 0.20, 1)
    tb:EnableMouse(true)
    tb:RegisterForDrag("LeftButton")
    tb:SetScript("OnDragStart", function() d:StartMoving() end)
    tb:SetScript("OnDragStop",  function() d:StopMovingOrSizing() end)

    local tbLine = tb:CreateTexture(nil, "ARTWORK")
    tbLine:SetHeight(1)
    tbLine:SetPoint("BOTTOMLEFT",  tb, "BOTTOMLEFT")
    tbLine:SetPoint("BOTTOMRIGHT", tb, "BOTTOMRIGHT")
    tbLine:SetColorTexture(1, 0.82, 0, 0.45)

    d.titleText = tb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    d.titleText:SetPoint("LEFT", tb, "LEFT", PAD, 0)
    d.titleText:SetTextColor(0.88, 0.86, 0.80, 1)

    local xBtn = CreateFrame("Button", nil, tb)
    xBtn:SetSize(DLG_TITLE_H, DLG_TITLE_H)
    xBtn:SetPoint("RIGHT", tb, "RIGHT", 0, 0)
    local xHl = xBtn:CreateTexture(nil, "HIGHLIGHT"); xHl:SetAllPoints()
    xHl:SetColorTexture(0.75, 0.08, 0.08, 0.55)
    local xFs = xBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xFs:SetAllPoints(); xFs:SetJustifyH("CENTER"); xFs:SetJustifyV("MIDDLE")
    xFs:SetTextColor(0.50, 0.50, 0.58, 1); xFs:SetText("x")
    xBtn:SetFontString(xFs)
    xBtn:SetScript("OnEnter", function() xFs:SetTextColor(1, 0.30, 0.30, 1) end)
    xBtn:SetScript("OnLeave", function() xFs:SetTextColor(0.50, 0.50, 0.58, 1) end)
    xBtn:SetScript("OnClick", function() d:Hide() end)

    d.body = CreateFrame("Frame", nil, d)
    d.body:SetPoint("TOPLEFT",     d, "TOPLEFT",     1, -(DLG_TITLE_H + 1))
    d.body:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -1,  1)
    Bg(d.body, 0.08, 0.09, 0.11, 1)

    return d
end

-- Styled EditBox inside a border container. Returns (container, editBox).
local function MakeInputBox(parent)
    local wrap = CreateFrame("Frame", nil, parent)
    wrap:SetHeight(28)
    Bg(wrap, 0.26, 0.28, 0.38, 1)
    local fill = wrap:CreateTexture(nil, "BACKGROUND", nil, 1)
    fill:SetPoint("TOPLEFT",     wrap, "TOPLEFT",      1, -1)
    fill:SetPoint("BOTTOMRIGHT", wrap, "BOTTOMRIGHT", -1,  1)
    fill:SetColorTexture(0.07, 0.08, 0.12, 1)
    local eb = CreateFrame("EditBox", nil, wrap)
    eb:SetPoint("TOPLEFT",     wrap, "TOPLEFT",      4, -2)
    eb:SetPoint("BOTTOMRIGHT", wrap, "BOTTOMRIGHT", -4,  2)
    eb:SetFontObject("GameFontNormal")
    eb:SetTextColor(0.90, 0.90, 0.96, 1)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(64)
    wrap.editBox = eb
    return wrap, eb
end

-- ── Main window ───────────────────────────────────────────────────────────────
local TITLE_H = 30
local main = CreateFrame("Frame", "ABS_Main", UIParent)
main:SetSize(FRAME_W, FRAME_H)
main:SetPoint("CENTER")
main:SetMovable(true)
main:EnableMouse(true)
main:SetClampedToScreen(true)
main:SetFrameStrata("DIALOG")
main:Hide()
table.insert(UISpecialFrames, "ABS_Main")

-- 1px border via outer bg peeking behind title bar and content area
Bg(main, 0.20, 0.22, 0.30, 1)

-- Title bar
local titleBar = CreateFrame("Frame", nil, main)
titleBar:SetPoint("TOPLEFT",  main, "TOPLEFT",  1, -1)
titleBar:SetPoint("TOPRIGHT", main, "TOPRIGHT", -1, -1)
titleBar:SetHeight(TITLE_H)
Bg(titleBar, 0.13, 0.14, 0.20, 1)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function() main:StartMoving() end)
titleBar:SetScript("OnDragStop",  function() main:StopMovingOrSizing() end)

local titleLine = titleBar:CreateTexture(nil, "ARTWORK")
titleLine:SetHeight(1)
titleLine:SetPoint("BOTTOMLEFT",  titleBar, "BOTTOMLEFT")
titleLine:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT")
titleLine:SetColorTexture(1, 0.82, 0, 0.45)

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", titleBar, "LEFT", PAD, 0)
titleText:SetTextColor(0.88, 0.86, 0.80, 1)
titleText:SetText("Action Bar Storage")

-- Close button
local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetSize(TITLE_H, TITLE_H)
closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", 0, 0)
local closeHl = closeBtn:CreateTexture(nil, "HIGHLIGHT")
closeHl:SetAllPoints()
closeHl:SetColorTexture(0.75, 0.08, 0.08, 0.55)
local closeFs = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
closeFs:SetAllPoints()
closeFs:SetJustifyH("CENTER")
closeFs:SetJustifyV("MIDDLE")
closeFs:SetTextColor(0.50, 0.50, 0.58, 1)
closeFs:SetText("x")
closeBtn:SetFontString(closeFs)
closeBtn:SetScript("OnEnter",     function() closeFs:SetTextColor(1, 0.30, 0.30, 1) end)
closeBtn:SetScript("OnLeave",     function() closeFs:SetTextColor(0.50, 0.50, 0.58, 1) end)
closeBtn:SetScript("OnMouseDown", function() closeFs:SetTextColor(0.65, 0.15, 0.15, 1) end)
closeBtn:SetScript("OnMouseUp",   function() closeFs:SetTextColor(1, 0.30, 0.30, 1) end)
closeBtn:SetScript("OnClick",     function() main:Hide() end)

-- Content area below title bar
local ins = CreateFrame("Frame", nil, main)
ins:SetPoint("TOPLEFT",     main, "TOPLEFT",     1, -(TITLE_H + 1))
ins:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -1,  1)
Bg(ins, 0.08, 0.09, 0.11, 1)

-- ── Left panel ────────────────────────────────────────────────────────────────
local lp = CreateFrame("Frame", nil, ins)
lp:SetPoint("TOPLEFT",    ins, "TOPLEFT",    0, 0)
lp:SetPoint("BOTTOMLEFT", ins, "BOTTOMLEFT", 0, 0)
lp:SetWidth(LIST_W)
Bg(lp, 0.11, 0.12, 0.17, 1)

local lpTitle = lp:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
lpTitle:SetPoint("TOPLEFT", lp, "TOPLEFT", PAD, -PAD)
lpTitle:SetTextColor(1, 0.82, 0, 1)
lpTitle:SetText("Profiles")

local lpCount = lp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
lpCount:SetPoint("LEFT", lpTitle, "RIGHT", 6, 1)
lpCount:SetTextColor(0.5, 0.5, 0.6, 1)

-- Gold separator under left header
local lpSep = lp:CreateTexture(nil, "ARTWORK")
lpSep:SetColorTexture(1, 0.82, 0, 0.35)
lpSep:SetHeight(1)
lpSep:SetPoint("TOPLEFT",  lp, "TOPLEFT",  PAD, -PAD - 22)
lpSep:SetPoint("TOPRIGHT", lp, "TOPRIGHT", -PAD, -PAD - 22)

-- Profile list scroll
local listScroll = CreateFrame("ScrollFrame", nil, lp, "UIPanelScrollFrameTemplate")
listScroll:SetPoint("TOPLEFT",    lp, "TOPLEFT",    PAD, -PAD - 28)
listScroll:SetPoint("BOTTOMLEFT", lp, "BOTTOMLEFT", PAD, 44)
listScroll:SetWidth(LIST_W - PAD * 2 - 16)

local listChild = CreateFrame("Frame", nil, listScroll)
listChild:SetWidth(LIST_W - PAD * 2 - 16)
listChild:SetHeight(10)
listScroll:SetScrollChild(listChild)

local BTN2_W  = math.floor((LIST_W - PAD * 2 - 4) / 2)
local newBtn   = MakeBtn(lp, BTN2_W, 26, "+ New")
local importBtn = MakeBtn(lp, BTN2_W, 26, "Import")
newBtn:SetPoint(   "BOTTOMLEFT",  lp, "BOTTOMLEFT",  PAD,  PAD)
importBtn:SetPoint("BOTTOMRIGHT", lp, "BOTTOMRIGHT", -PAD, PAD)

-- Vertical divider
local div = ins:CreateTexture(nil, "ARTWORK")
div:SetColorTexture(0.22, 0.22, 0.30, 1)
div:SetWidth(1)
div:SetPoint("TOPLEFT",    ins, "TOPLEFT",    LIST_W, 0)
div:SetPoint("BOTTOMLEFT", ins, "BOTTOMLEFT", LIST_W, 0)

-- ── Right panel ───────────────────────────────────────────────────────────────
local detailX     = LIST_W + PAD
local detContentW = FRAME_W - LIST_W - PAD * 2 - 20 - 6

local detTitle = ins:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
detTitle:SetPoint("TOPLEFT", ins, "TOPLEFT", detailX, -PAD)
detTitle:SetTextColor(1, 1, 1, 1)
detTitle:SetJustifyH("LEFT")

local detMeta = ins:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
detMeta:SetPoint("TOPLEFT", detTitle, "BOTTOMLEFT", 0, -3)
detMeta:SetTextColor(0.5, 0.5, 0.62, 1)

-- Collapse / Expand all — real buttons with hover/click feedback
local function MakeTextBtn(parent, text)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(80, 16)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetAllPoints()
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
    fs:SetText(text)
    fs:SetTextColor(0.55, 0.58, 0.70, 1)
    b:SetFontString(fs)
    b.fs = fs
    b:SetScript("OnEnter",     function() fs:SetTextColor(1, 0.82, 0, 1) end)
    b:SetScript("OnLeave",     function() fs:SetTextColor(0.55, 0.58, 0.70, 1) end)
    b:SetScript("OnMouseDown", function() fs:SetTextColor(0.75, 0.62, 0, 1) end)
    b:SetScript("OnMouseUp",   function() fs:SetTextColor(1, 0.82, 0, 1) end)
    b:Hide()
    return b
end

local collapseAllHit = MakeTextBtn(ins, "Collapse All")
collapseAllHit:SetPoint("TOPRIGHT", ins, "TOPRIGHT", -PAD - 16, -PAD - 2)

local expandAllHit = MakeTextBtn(ins, "Expand All")
expandAllHit:SetPoint("RIGHT", collapseAllHit, "LEFT", -8, 0)

-- Keep these aliases so the rest of the code (SetText / Show / Hide) still works
local collapseAllBtn = collapseAllHit
local expandAllBtn   = expandAllHit

-- Thin separator under title
local detSep = ins:CreateTexture(nil, "ARTWORK")
detSep:SetColorTexture(0.22, 0.22, 0.30, 1)
detSep:SetHeight(1)
detSep:SetPoint("TOPLEFT",  ins, "TOPLEFT",  detailX, -PAD - 40)
detSep:SetPoint("TOPRIGHT", ins, "TOPRIGHT", -PAD,    -PAD - 40)

local detEmpty = ins:CreateFontString(nil, "OVERLAY", "GameFontNormal")
detEmpty:SetText("Select a profile to view its contents,\nor click  + New Profile  to create one.")
detEmpty:SetTextColor(0.38, 0.38, 0.48, 1)
detEmpty:SetPoint("CENTER", ins, "CENTER", LIST_W / 2, 10)
detEmpty:SetJustifyH("CENTER")

-- Detail scroll
local detScroll = CreateFrame("ScrollFrame", nil, ins, "UIPanelScrollFrameTemplate")
detScroll:SetPoint("TOPLEFT",     ins, "TOPLEFT",     detailX, -PAD - 46)
detScroll:SetPoint("BOTTOMRIGHT", ins, "BOTTOMRIGHT", -PAD - 16, 46)

local detChild = CreateFrame("Frame", nil, detScroll)
detChild:SetWidth(detContentW)
detChild:SetHeight(10)
detScroll:SetScrollChild(detChild)

-- ── Bottom buttons ────────────────────────────────────────────────────────────
local applyBtn  = MakeBtn(ins, 116, 26, "Apply Profile", true)
local renameBtn = MakeBtn(ins,  76, 26, "Rename")
local deleteBtn = MakeBtn(ins,  76, 26, "Delete")
local copyBtn   = MakeBtn(ins,  90, 26, "Export")

applyBtn:SetPoint( "BOTTOMLEFT",  ins, "BOTTOMLEFT",  detailX, PAD)
renameBtn:SetPoint("LEFT", applyBtn,  "RIGHT", 6, 0)
deleteBtn:SetPoint("LEFT", renameBtn, "RIGHT", 6, 0)
copyBtn:SetPoint(  "BOTTOMRIGHT", ins, "BOTTOMRIGHT", -PAD, PAD)

applyBtn:SetEnabled(false)
renameBtn:SetEnabled(false)
deleteBtn:SetEnabled(false)
copyBtn:SetEnabled(false)

-- ── State ─────────────────────────────────────────────────────────────────────
local selectedProfile = nil
local listButtons     = {}
local barCollapsed    = {}   -- barId -> true = collapsed

-- ── Row pool (accordion rows) ─────────────────────────────────────────────────
local rowPool    = {}
local activeRows = {}

local function GetRow()
    local r = table.remove(rowPool)
    if not r then
        r = CreateFrame("Button", nil, detChild)
        r.bgTex  = r:CreateTexture(nil, "BACKGROUND")
        r.bgTex:SetAllPoints()
        r.accent = r:CreateTexture(nil, "BORDER")
        r.accent:SetWidth(3)
        r.accent:SetPoint("TOPLEFT")
        r.accent:SetPoint("BOTTOMLEFT")
        r.fs = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.fs:SetPoint("LEFT",  r.accent, "RIGHT", 6, 0)
        r.fs:SetPoint("RIGHT", r,        "RIGHT", -6, 0)
        r.fs:SetJustifyH("LEFT")
        r:SetFontString(r.fs)
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.04)
    end
    r:Show()
    table.insert(activeRows, r)
    return r
end

local function ReleaseRows()
    for _, r in ipairs(activeRows) do
        r:Hide()
        r:SetScript("OnClick", nil)
        r:EnableMouse(false)
        table.insert(rowPool, r)
    end
    activeRows = {}
end

-- ── Action type color ─────────────────────────────────────────────────────────
local function SlotColor(t)
    if     t == "macro"                         then return "ffaaaaff"
    elseif t == "item"                          then return "ffffcc55"
    elseif t == "flyout"                        then return "ffcc88ff"
    elseif t == "summonmount" or t == "companion" then return "ff88ddff"
    else                                             return "ffe8e8e8"
    end
end

-- ── Accordion detail renderer ─────────────────────────────────────────────────
local function RenderDetail(profileName)
    local p = ABS.db.profiles[profileName]
    if not p then return end

    ReleaseRows()
    detEmpty:Hide()
    detTitle:SetText(p.name)
    detMeta:SetText(string.format("Saved by %s  |  %s", p.savedBy or "?", p.savedOn or "?"))
    collapseAllBtn:SetText("Collapse All")
    expandAllBtn:SetText("Expand All")
    collapseAllHit:Show()
    expandAllHit:Show()

    local yOff = 0

    for barId = 1, #ABS.BARS do
        local bd = p.bars[barId]
        if bd then
            local filled = 0
            for _, sd in ipairs(bd.slots) do
                if sd.actionType ~= "" and sd.id then filled = filled + 1 end
            end
            local collapsed = barCollapsed[barId]

            -- Bar header row
            local hdr = GetRow()
            hdr:SetPoint("TOPLEFT", detChild, "TOPLEFT", 0, -yOff)
            hdr:SetWidth(detContentW)
            hdr:SetHeight(HDR_H)
            hdr.bgTex:SetColorTexture(0.16, 0.17, 0.23, 1)
            hdr.accent:SetColorTexture(1, 0.82, 0, 1)
            hdr.accent:Show()
            hdr.fs:SetTextColor(1, 0.88, 0.2, 1)
            local toggle = collapsed and "[+]" or "[-]"
            local badge  = string.format("|cff555566%d/12|r", filled)
            hdr:SetText(string.format("%s  %s   %s", toggle, bd.label or ("Bar " .. barId), badge))
            hdr:EnableMouse(true)
            local capId, capName = barId, profileName
            hdr:SetScript("OnClick", function()
                barCollapsed[capId] = not barCollapsed[capId]
                RenderDetail(capName)
            end)

            yOff = yOff + HDR_H + 1

            if not collapsed then
                for slotIdx, sd in ipairs(bd.slots) do
                    local row = GetRow()
                    row:SetPoint("TOPLEFT", detChild, "TOPLEFT", 0, -yOff)
                    row:SetWidth(detContentW)
                    row:SetHeight(SLOT_H)
                    row.accent:Hide()
                    row:EnableMouse(false)
                    if slotIdx % 2 == 0 then
                        row.bgTex:SetColorTexture(0.11, 0.11, 0.15, 1)
                    else
                        row.bgTex:SetColorTexture(0.09, 0.09, 0.12, 1)
                    end
                    if sd.actionType ~= "" and sd.id then
                        local col   = SlotColor(sd.actionType)
                        local dname = (sd.name and sd.name ~= "") and sd.name
                                      or (sd.actionType .. " #" .. tostring(sd.id))
                        row:SetText(string.format("|cff444455%2d.|r  |c%s%s|r", slotIdx, col, dname))
                    else
                        row:SetText(string.format("|cff444455%2d.|r  |cff252535(empty)|r", slotIdx))
                    end
                    row.fs:SetTextColor(1, 1, 1, 1)
                    yOff = yOff + SLOT_H
                end
                yOff = yOff + BAR_GAP
            end
        end
    end

    detChild:SetHeight(math.max(yOff + 4, 10))
end

-- Collapse All / Expand All handlers
collapseAllHit:SetScript("OnClick", function()
    if not selectedProfile then return end
    local p = ABS.db.profiles[selectedProfile]
    if not p then return end
    for barId in pairs(p.bars) do barCollapsed[barId] = true end
    RenderDetail(selectedProfile)
end)

expandAllHit:SetScript("OnClick", function()
    if not selectedProfile then return end
    local p = ABS.db.profiles[selectedProfile]
    if not p then return end
    for barId in pairs(p.bars) do barCollapsed[barId] = false end
    RenderDetail(selectedProfile)
end)

-- ── Profile list rendering ────────────────────────────────────────────────────
local function RefreshList()
    for _, b in ipairs(listButtons) do b:Hide() end

    local names = ABS:GetSortedProfiles()
    lpCount:SetText("(" .. #names .. ")")

    local yOff = 0
    for i, name in ipairs(names) do
        local b = listButtons[i]
        if not b then
            b = CreateFrame("Button", nil, listChild)
            b:SetHeight(28)
            b.bgTex  = b:CreateTexture(nil, "BACKGROUND")
            b.bgTex:SetAllPoints()
            b.selBar = b:CreateTexture(nil, "ARTWORK")
            b.selBar:SetWidth(3)
            b.selBar:SetPoint("TOPLEFT")
            b.selBar:SetPoint("BOTTOMLEFT")
            b.selBar:SetColorTexture(1, 0.82, 0, 1)
            b.selBar:Hide()
            local hl = b:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.06)
            b.fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            b.fs:SetPoint("LEFT",  b, "LEFT",  10, 0)
            b.fs:SetPoint("RIGHT", b, "RIGHT", -4, 0)
            b.fs:SetJustifyH("LEFT")
            b:SetFontString(b.fs)
            listButtons[i] = b
        end

        b:SetWidth(listChild:GetWidth())
        b:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -yOff)
        b:SetText(name)
        b:Show()

        local sel = (name == selectedProfile)
        b.selBar:SetShown(sel)
        b.bgTex:SetColorTexture(1, 0.82, 0, sel and 0.08 or 0)
        b.fs:SetTextColor(sel and 1 or 0.82, sel and 0.88 or 0.82, sel and 0.2 or 0.82, 1)

        local capName = name
        b:SetScript("OnClick", function()
            selectedProfile = capName
            RenderDetail(capName)
            applyBtn:SetEnabled(true)
            renameBtn:SetEnabled(true)
            deleteBtn:SetEnabled(true)
            copyBtn:SetEnabled(true)
            for _, lb in ipairs(listButtons) do
                if lb.selBar then
                    local s = (lb:GetText() == selectedProfile)
                    lb.selBar:SetShown(s)
                    lb.bgTex:SetColorTexture(1, 0.82, 0, s and 0.08 or 0)
                    lb.fs:SetTextColor(s and 1 or 0.82, s and 0.88 or 0.82, s and 0.2 or 0.82, 1)
                end
            end
        end)

        yOff = yOff + 28
    end
    listChild:SetHeight(math.max(yOff, 10))
end

-- ── Checkbox widget ──────────────────────────────────────────────────────────
local function MakeCheckbox(parent)
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(14, 14)

    local bdr = f:CreateTexture(nil, "BACKGROUND", nil, -1)
    bdr:SetAllPoints()
    bdr:SetColorTexture(0.28, 0.30, 0.42, 1)

    local fill = f:CreateTexture(nil, "BACKGROUND")
    fill:SetPoint("TOPLEFT",     f, "TOPLEFT",      1, -1)
    fill:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1,  1)
    fill:SetColorTexture(0.12, 0.13, 0.18, 1)
    f.fill = fill

    local hl = f:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.10)

    f.checked = false

    local function Refresh()
        if f.checked then
            fill:SetColorTexture(1, 0.82, 0, 0.88)
        else
            fill:SetColorTexture(0.12, 0.13, 0.18, 1)
        end
    end

    f:SetScript("OnClick", function()
        f.checked = not f.checked
        Refresh()
    end)

    function f:SetChecked(v) self.checked = v; Refresh() end
    function f:IsChecked()  return self.checked end

    return f
end

-- ── Apply-bar dialog ──────────────────────────────────────────────────────────
-- (DLG_W, DLG_TITLE_H, ROW_H defined in layout constants above)

local applyDialog       = nil
local applyDialogRows   = {}   -- pool
local applyActiveRows2  = {}
local applyDialogProfile = nil

local function ReleaseApplyRows()
    for _, r in ipairs(applyActiveRows2) do
        r:Hide()
        r.check:SetChecked(false)
        table.insert(applyDialogRows, r)
    end
    applyActiveRows2 = {}
end

local function GetApplyRow(parent)
    local r = table.remove(applyDialogRows)
    if not r then
        r = CreateFrame("Frame", nil, parent)
        r:SetHeight(ROW_H)
        r.bgTex = r:CreateTexture(nil, "BACKGROUND")
        r.bgTex:SetAllPoints()
        r.check = MakeCheckbox(r)
        r.check:SetPoint("LEFT", r, "LEFT", 8, 0)
        r.label = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r.label:SetPoint("LEFT",  r.check, "RIGHT", 8, 0)
        r.label:SetPoint("RIGHT", r,       "RIGHT", -60, 0)
        r.label:SetJustifyH("LEFT")
        r.label:SetTextColor(0.82, 0.84, 0.92, 1)
        r.badge = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.badge:SetPoint("RIGHT", r, "RIGHT", -8, 0)
        r.badge:SetJustifyH("RIGHT")
        r.badge:SetTextColor(0.45, 0.45, 0.55, 1)
        -- clicking anywhere on the row toggles the checkbox
        local hit = CreateFrame("Button", nil, r)
        hit:SetPoint("LEFT", r.check, "RIGHT", 0, 0)
        hit:SetPoint("RIGHT",  r, "RIGHT",  0, 0)
        hit:SetPoint("TOP",    r, "TOP",    0, 0)
        hit:SetPoint("BOTTOM", r, "BOTTOM", 0, 0)
        local rowHl = hit:CreateTexture(nil, "HIGHLIGHT")
        rowHl:SetAllPoints()
        rowHl:SetColorTexture(1, 1, 1, 0.04)
        hit:SetScript("OnClick", function() r.check:Click() end)
    end
    r:Show()
    table.insert(applyActiveRows2, r)
    return r
end

local function BuildApplyDialog()
    local d = CreateFrame("Frame", "ABS_ApplyDialog", UIParent)
    d:SetSize(DLG_W, 340)
    d:SetPoint("CENTER")
    d:SetMovable(true)
    d:EnableMouse(true)
    d:SetClampedToScreen(true)
    d:SetFrameStrata("FULLSCREEN_DIALOG")
    d:Hide()
    table.insert(UISpecialFrames, "ABS_ApplyDialog")
    Bg(d, 0.20, 0.22, 0.30, 1)

    -- Title bar
    local tb = CreateFrame("Frame", nil, d)
    tb:SetPoint("TOPLEFT",  d, "TOPLEFT",  1, -1)
    tb:SetPoint("TOPRIGHT", d, "TOPRIGHT", -1, -1)
    tb:SetHeight(DLG_TITLE_H)
    Bg(tb, 0.13, 0.14, 0.20, 1)
    tb:EnableMouse(true)
    tb:RegisterForDrag("LeftButton")
    tb:SetScript("OnDragStart", function() d:StartMoving() end)
    tb:SetScript("OnDragStop",  function() d:StopMovingOrSizing() end)

    local tl = tb:CreateTexture(nil, "ARTWORK")
    tl:SetHeight(1)
    tl:SetPoint("BOTTOMLEFT",  tb, "BOTTOMLEFT")
    tl:SetPoint("BOTTOMRIGHT", tb, "BOTTOMRIGHT")
    tl:SetColorTexture(1, 0.82, 0, 0.45)

    d.titleText = tb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    d.titleText:SetPoint("LEFT", tb, "LEFT", PAD, 0)
    d.titleText:SetTextColor(0.88, 0.86, 0.80, 1)

    local xBtn = CreateFrame("Button", nil, tb)
    xBtn:SetSize(DLG_TITLE_H, DLG_TITLE_H)
    xBtn:SetPoint("RIGHT", tb, "RIGHT", 0, 0)
    local xHl = xBtn:CreateTexture(nil, "HIGHLIGHT")
    xHl:SetAllPoints()
    xHl:SetColorTexture(0.75, 0.08, 0.08, 0.55)
    local xFs = xBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xFs:SetAllPoints(); xFs:SetJustifyH("CENTER"); xFs:SetJustifyV("MIDDLE")
    xFs:SetTextColor(0.50, 0.50, 0.58, 1); xFs:SetText("x")
    xBtn:SetFontString(xFs)
    xBtn:SetScript("OnEnter",     function() xFs:SetTextColor(1, 0.30, 0.30, 1) end)
    xBtn:SetScript("OnLeave",     function() xFs:SetTextColor(0.50, 0.50, 0.58, 1) end)
    xBtn:SetScript("OnClick",     function() d:Hide() end)

    -- Body
    local body = CreateFrame("Frame", nil, d)
    body:SetPoint("TOPLEFT",     d, "TOPLEFT",     1, -(DLG_TITLE_H + 1))
    body:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -1, 1)
    Bg(body, 0.08, 0.09, 0.11, 1)
    d.body = body

    local instr = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instr:SetPoint("TOPLEFT", body, "TOPLEFT", PAD, -PAD)
    instr:SetTextColor(0.55, 0.55, 0.65, 1)
    instr:SetText("Select bars to apply:")
    d.instr = instr

    -- Separator
    local sep = body:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetColorTexture(0.22, 0.22, 0.30, 1)
    sep:SetPoint("TOPLEFT",  instr, "BOTTOMLEFT",  0, -6)
    sep:SetPoint("TOPRIGHT", body,  "TOPRIGHT",   -PAD, -6)
    d.sep = sep

    -- Scroll for bars list
    local scroll = CreateFrame("ScrollFrame", nil, body, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     sep,  "BOTTOMLEFT",   0,     -4)
    scroll:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -PAD - 16, 42)
    d.scroll = scroll

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(DLG_W - 2 - PAD * 2 - 16)
    child:SetHeight(10)
    scroll:SetScrollChild(child)
    d.child = child

    -- Bottom buttons
    local allBtn    = MakeBtn(body, 50, 24, "All")
    local noneBtn   = MakeBtn(body, 50, 24, "None")
    local applyBtn2 = MakeBtn(body, 90, 24, "Apply", true)
    local cancelBtn = MakeBtn(body, 65, 24, "Cancel")

    allBtn:SetPoint(   "BOTTOMLEFT",  body, "BOTTOMLEFT",  PAD, PAD)
    noneBtn:SetPoint(  "LEFT",  allBtn,   "RIGHT", 4,  0)
    applyBtn2:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -PAD, PAD)
    cancelBtn:SetPoint("RIGHT", applyBtn2, "LEFT", -4, 0)

    allBtn:SetScript("OnClick", function()
        for _, r in ipairs(applyActiveRows2) do r.check:SetChecked(true) end
    end)
    noneBtn:SetScript("OnClick", function()
        for _, r in ipairs(applyActiveRows2) do r.check:SetChecked(false) end
    end)
    cancelBtn:SetScript("OnClick", function() d:Hide() end)
    applyBtn2:SetScript("OnClick", function()
        if not applyDialogProfile then return end
        local filter = {}
        local anySelected = false
        for _, r in ipairs(applyActiveRows2) do
            if r.check:IsChecked() then
                filter[r.barId] = true
                anySelected = true
            end
        end
        if not anySelected then
            print("|cffFF4444[Action Bar Storage]|r No bars selected.")
            return
        end
        d:Hide()
        ABS:ApplyProfile(applyDialogProfile, nil, filter)
    end)

    return d
end

local function ShowApplyDialog(profileName)
    local p = ABS.db.profiles[profileName]
    if not p then return end

    if not applyDialog then
        applyDialog = BuildApplyDialog()
    end

    applyDialogProfile = profileName
    applyDialog.titleText:SetText('Apply bars — "' .. profileName .. '"')

    ReleaseApplyRows()

    -- Collect sorted barIds from profile
    local barIds = {}
    for barId in pairs(p.bars) do table.insert(barIds, barId) end
    table.sort(barIds)

    local yOff = 0
    for _, barId in ipairs(barIds) do
        local bd = p.bars[barId]
        local filled = 0
        for _, sd in ipairs(bd.slots) do
            if sd.actionType ~= "" and sd.id then filled = filled + 1 end
        end

        local r = GetApplyRow(applyDialog.child)
        r.barId = barId
        r:SetWidth(applyDialog.child:GetWidth())
        r:SetPoint("TOPLEFT", applyDialog.child, "TOPLEFT", 0, -yOff)
        r.check:SetChecked(true)
        r.label:SetText(bd.label or ("Bar " .. barId))
        r.badge:SetText(filled .. " / 12")

        local alt = (#applyActiveRows2 % 2 == 1)
        r.bgTex:SetColorTexture(alt and 0.11 or 0.09, alt and 0.11 or 0.09, alt and 0.15 or 0.12, 1)

        yOff = yOff + ROW_H
    end

    applyDialog.child:SetHeight(math.max(yOff, 10))
    applyDialog:SetPoint("CENTER")
    applyDialog:Show()
end

-- ── Apply ─────────────────────────────────────────────────────────────────────
applyBtn:SetScript("OnClick", function()
    if selectedProfile then ShowApplyDialog(selectedProfile) end
end)

-- ── Copy / Export ─────────────────────────────────────────────────────────────
copyBtn:SetScript("OnClick", function()
    if not selectedProfile then return end
    local text = ABS:ExportProfile(selectedProfile)
    if not text then return end

    if C_Clipboard and C_Clipboard.SetText then
        C_Clipboard.SetText(text)
        print("|cff00ccff[Action Bar Storage]|r \"" .. selectedProfile
              .. "\" export copied — paste it into the Import dialog on another character.")
    else
        -- Fallback: show in a scrollable editbox so the user can copy manually
        if not ABS._exportFrame then
            local ef = BuildDarkFrame("ABS_ExportFrame", 460, 340)
            ef.titleText:SetText("Export Profile")
            ef:SetPoint("CENTER")
            local sf = CreateFrame("ScrollFrame", nil, ef.body, "UIPanelScrollFrameTemplate")
            sf:SetPoint("TOPLEFT",     ef.body, "TOPLEFT",      PAD,      -PAD)
            sf:SetPoint("BOTTOMRIGHT", ef.body, "BOTTOMRIGHT", -PAD - 16,  PAD)
            local eb = CreateFrame("EditBox", nil, sf)
            eb:SetMultiLine(true)
            eb:SetFontObject("GameFontNormalSmall")
            eb:SetTextColor(0.85, 0.85, 0.92, 1)
            eb:SetWidth(400)
            eb:SetAutoFocus(true)
            eb:SetScript("OnEscapePressed", function() ef:Hide() end)
            sf:SetScrollChild(eb)
            ef.eb = eb
            ABS._exportFrame = ef
        end
        ABS._exportFrame.eb:SetText(text)
        ABS._exportFrame.eb:HighlightText()
        ABS._exportFrame:Show()
        ABS._exportFrame.eb:SetFocus()
    end
end)

-- ── Import dialog ─────────────────────────────────────────────────────────────
local importDialog = BuildDarkFrame("ABS_ImportDialog", 460, 340)
importDialog.titleText:SetText("Import Profile")

local impInstr = importDialog.body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
impInstr:SetPoint("TOPLEFT", importDialog.body, "TOPLEFT", PAD, -PAD)
impInstr:SetTextColor(0.55, 0.55, 0.65, 1)
impInstr:SetText("Paste an exported profile string below and click Import:")

local impConfirm = MakeBtn(importDialog.body, 80, 24, "Import", true)
local impCancel  = MakeBtn(importDialog.body, 65, 24, "Cancel")
impConfirm:SetPoint("BOTTOMRIGHT", importDialog.body, "BOTTOMRIGHT", -PAD, PAD)
impCancel:SetPoint( "RIGHT", impConfirm, "LEFT", -4, 0)
impCancel:SetScript("OnClick", function() importDialog:Hide() end)

local impErr = importDialog.body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
impErr:SetPoint("BOTTOMLEFT", importDialog.body, "BOTTOMLEFT", PAD, PAD + 28 + 6)
impErr:SetTextColor(1, 0.35, 0.35, 1)
impErr:SetText("")
importDialog.err = impErr

-- Scroll + EditBox for paste area.
-- Background is drawn on a non-mouse-interactive Frame so clicks reach the EditBox.
local impBgFrame = CreateFrame("Frame", nil, importDialog.body)
impBgFrame:SetPoint("TOPLEFT",     impInstr,          "BOTTOMLEFT",    0,        -6)
impBgFrame:SetPoint("BOTTOMRIGHT", importDialog.body, "BOTTOMRIGHT",  -PAD,  PAD + 28 + 6 + 16)
impBgFrame:EnableMouse(false)
local impBoxBdr = impBgFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
impBoxBdr:SetAllPoints()
impBoxBdr:SetColorTexture(0.26, 0.28, 0.38, 1)
local impBoxFill = impBgFrame:CreateTexture(nil, "BACKGROUND")
impBoxFill:SetPoint("TOPLEFT",     impBgFrame, "TOPLEFT",      1, -1)
impBoxFill:SetPoint("BOTTOMRIGHT", impBgFrame, "BOTTOMRIGHT", -1,  1)
impBoxFill:SetColorTexture(0.05, 0.06, 0.09, 1)

-- ScrollFrame clips overflow; click on any part of the bg area focuses the EditBox.
local impScroll = CreateFrame("ScrollFrame", nil, importDialog.body)
impScroll:SetPoint("TOPLEFT",     impBgFrame, "TOPLEFT",      2, -2)
impScroll:SetPoint("BOTTOMRIGHT", impBgFrame, "BOTTOMRIGHT", -2,  2)
impScroll:EnableMouse(true)

local impChild = CreateFrame("EditBox", nil, impScroll)
impChild:SetMultiLine(true)
impChild:SetMaxLetters(0)
impChild:EnableMouse(true)
impChild:SetFontObject("GameFontNormalSmall")
impChild:SetTextColor(0.85, 0.87, 0.96, 1)
impChild:SetAutoFocus(false)
impChild:SetScript("OnEscapePressed", function() importDialog:Hide() end)
impScroll:SetScrollChild(impChild)

-- Keep EditBox width in sync with scroll frame so text wraps and doesn't spill.
impScroll:SetScript("OnSizeChanged", function(self)
    local w = self:GetWidth()
    if w and w > 10 then impChild:SetWidth(w) end
end)
-- Any click in the bg area (bg frame or scroll frame) focuses the EditBox.
impScroll:SetScript("OnMouseDown", function() impChild:SetFocus() end)
impBgFrame:EnableMouse(true)
impBgFrame:SetScript("OnMouseDown", function() impChild:SetFocus() end)
importDialog.editBox = impChild

importDialog:SetScript("OnShow", function()
    impErr:SetText("")
    impChild:SetText("")
    impChild:SetFocus()
end)

impConfirm:SetScript("OnClick", function()
    local str = impChild:GetText()
    local name, err = ABS:ImportProfile(str)
    if name then
        importDialog:Hide()
        selectedProfile = name
        RefreshList()
        RenderDetail(name)
        applyBtn:SetEnabled(true)
        renameBtn:SetEnabled(true)
        deleteBtn:SetEnabled(true)
        copyBtn:SetEnabled(true)
        print("|cff00ccff[Action Bar Storage]|r Imported profile \"" .. name .. "\".")
    else
        impErr:SetText(err or "Import failed.")
    end
end)

importBtn:SetScript("OnClick", function()
    importDialog:SetPoint("CENTER")
    importDialog:Show()
end)

-- ── Custom dialogs (Delete / Rename / New Profile) ───────────────────────────
-- Delete confirm dialog
local deleteDialog = BuildDarkFrame("ABS_DeleteDialog", 320, 130)
deleteDialog.titleText:SetText("Delete Profile")
local delMsg = deleteDialog.body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
delMsg:SetPoint("TOPLEFT",  deleteDialog.body, "TOPLEFT",  PAD, -PAD)
delMsg:SetPoint("TOPRIGHT", deleteDialog.body, "TOPRIGHT", -PAD, -PAD)
delMsg:SetJustifyH("LEFT")
delMsg:SetWordWrap(true)
delMsg:SetTextColor(0.82, 0.82, 0.92, 1)
deleteDialog.msg = delMsg
local delConfirm = MakeBtn(deleteDialog.body, 80, 24, "Delete")
local delCancel  = MakeBtn(deleteDialog.body, 65, 24, "Cancel")
delConfirm:SetPoint("BOTTOMRIGHT", deleteDialog.body, "BOTTOMRIGHT", -PAD, PAD)
delCancel:SetPoint( "RIGHT", delConfirm, "LEFT", -4, 0)
delCancel:SetScript("OnClick", function() deleteDialog:Hide() end)
delConfirm:SetScript("OnClick", function()
    local target = deleteDialog._target
    if not target then deleteDialog:Hide(); return end
    deleteDialog:Hide()
    ABS:DeleteProfile(target)
    selectedProfile = nil
    ReleaseRows()
    detTitle:SetText("")
    detMeta:SetText("")
    detEmpty:Show()
    collapseAllBtn:SetText("")
    expandAllBtn:SetText("")
    collapseAllHit:Hide()
    expandAllHit:Hide()
    applyBtn:SetEnabled(false)
    renameBtn:SetEnabled(false)
    deleteBtn:SetEnabled(false)
    copyBtn:SetEnabled(false)
    RefreshList()
end)

-- Rename dialog
local renameDialog  = BuildDarkFrame("ABS_RenameDialog", 320, 152)
renameDialog.titleText:SetText("Rename Profile")
local renLbl = renameDialog.body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
renLbl:SetPoint("TOPLEFT", renameDialog.body, "TOPLEFT", PAD, -PAD)
renLbl:SetTextColor(0.60, 0.60, 0.70, 1)
renLbl:SetText("Enter a new name:")
local renWrap, renEB = MakeInputBox(renameDialog.body)
renWrap:SetPoint("TOPLEFT",  renLbl,              "BOTTOMLEFT",  0,    -8)
renWrap:SetPoint("TOPRIGHT", renameDialog.body,   "TOPRIGHT",   -PAD, -8 - renLbl:GetHeight() - 8)
renWrap:SetPoint("LEFT",  renameDialog.body, "LEFT",  PAD,  0)
renWrap:SetPoint("RIGHT", renameDialog.body, "RIGHT", -PAD, 0)
renameDialog.editBox = renEB
local renErr = renameDialog.body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
renErr:SetPoint("TOPLEFT", renWrap, "BOTTOMLEFT", 0, -4)
renErr:SetTextColor(1, 0.3, 0.3, 1)
renErr:SetText("")
renameDialog.err = renErr
local renConfirm = MakeBtn(renameDialog.body, 80, 24, "Rename", true)
local renCancel  = MakeBtn(renameDialog.body, 65, 24, "Cancel")
renConfirm:SetPoint("BOTTOMRIGHT", renameDialog.body, "BOTTOMRIGHT", -PAD, PAD)
renCancel:SetPoint( "RIGHT", renConfirm, "LEFT", -4, 0)
renCancel:SetScript("OnClick",  function() renameDialog:Hide() end)
renEB:SetScript("OnEscapePressed", function() renameDialog:Hide() end)
renEB:SetScript("OnEnterPressed",  function() renConfirm:Click() end)
renameDialog:SetScript("OnShow", function()
    renErr:SetText("")
    renEB:SetFocus()
    renEB:HighlightText()
end)
renConfirm:SetScript("OnClick", function()
    local old = renameDialog._old
    local new = renEB:GetText():match("^%s*(.-)%s*$")
    if not new or new == "" then return end
    if ABS:RenameProfile(old, new) then
        selectedProfile = new
        renameDialog:Hide()
        RefreshList()
        RenderDetail(new)
    else
        renErr:SetText("That name is already in use.")
    end
end)

-- ── Delete ────────────────────────────────────────────────────────────────────
deleteBtn:SetScript("OnClick", function()
    if not selectedProfile then return end
    deleteDialog.msg:SetText('Delete "|cffFFD100' .. selectedProfile .. '|r"?\nThis cannot be undone.')
    deleteDialog._target = selectedProfile
    deleteDialog:SetPoint("CENTER")
    deleteDialog:Show()
end)

-- ── Rename ────────────────────────────────────────────────────────────────────
renameBtn:SetScript("OnClick", function()
    if not selectedProfile then return end
    renameDialog._old = selectedProfile
    renameDialog.editBox:SetText(selectedProfile)
    renameDialog:SetPoint("CENTER")
    renameDialog:Show()
end)

-- ── Bar selector ──────────────────────────────────────────────────────────────
local sel = {
    active    = false,
    chosen    = {},
    barFrames = {},
    hoveredId = nil,
    onDone    = nil,
}

local selHover = CreateFrame("Frame", nil, UIParent)
selHover:SetFrameLevel(188)
selHover:EnableMouse(false)
selHover:Hide()
do
    local t = selHover:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints()
    t:SetColorTexture(1, 0.82, 0, 0.3)
    selHover.lbl = selHover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selHover.lbl:SetPoint("CENTER")
    selHover.lbl:SetTextColor(1, 1, 0, 1)
end

local selGreen = {}
local function GetGreenOverlay(barId)
    if not selGreen[barId] then
        local f = CreateFrame("Frame", nil, UIParent)
        f:SetFrameLevel(187)
        f:EnableMouse(false)
        f:Hide()
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetAllPoints()
        t:SetColorTexture(0.1, 0.9, 0.1, 0.3)
        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("CENTER")
        lbl:SetText("|cff00ff00[Selected]|r")
        selGreen[barId] = f
    end
    return selGreen[barId]
end

local selCatcher = CreateFrame("Frame", "ABS_SelCatcher", UIParent)
selCatcher:SetAllPoints(UIParent)
selCatcher:SetFrameLevel(189)
selCatcher:EnableMouse(true)
selCatcher:Hide()
selCatcher:SetScript("OnMouseDown", function(_, button)
    if not sel.active or button ~= "LeftButton" then return end
    local barId = sel.hoveredId
    if not barId then return end
    local f = sel.barFrames[barId]
    if not f then return end
    if sel.chosen[barId] then
        sel.chosen[barId] = nil
        GetGreenOverlay(barId):Hide()
    else
        sel.chosen[barId] = true
        GetGreenOverlay(barId):SetAllPoints(f)
        GetGreenOverlay(barId):Show()
    end
end)

local selScanner = CreateFrame("Frame", nil, UIParent)
selScanner:Hide()
selScanner:SetScript("OnUpdate", function()
    if not sel.active then return end
    local found = nil
    for barId, frame in pairs(sel.barFrames) do
        if frame:IsMouseOver() then found = barId; break end
    end
    if found ~= sel.hoveredId then
        sel.hoveredId = found
        if found then
            local def = ABS.BARS[found]
            selHover:SetAllPoints(sel.barFrames[found])
            selHover.lbl:SetText(def and def.label or ("Bar " .. found))
            selHover:Show()
        else
            selHover:Hide()
        end
    end
end)

local selPanel

local function StopSelector()
    sel.active    = false
    sel.chosen    = {}
    sel.hoveredId = nil
    sel.barFrames = {}
    selHover:Hide()
    selCatcher:Hide()
    selScanner:Hide()
    for _, ov in pairs(selGreen) do ov:Hide() end
    if selPanel then selPanel:Hide() end
    main:Show()
    RefreshList()
end

local function StartSelector(onDone)
    sel.active    = true
    sel.chosen    = {}
    sel.hoveredId = nil
    sel.onDone    = onDone
    sel.barFrames = ABS:GetVisibleBarFrames()

    if not next(sel.barFrames) then
        print("|cffFF4444[Action Bar Storage]|r No action bar frames detected. Make sure your bars are visible.")
        return
    end

    selHover:Hide()
    for _, ov in pairs(selGreen) do ov:Hide() end
    selCatcher:Show()
    selScanner:Show()
    main:Hide()

    if not selPanel then
        local SP_TITLE_H = 26
        selPanel = CreateFrame("Frame", "ABS_SelPanel", UIParent)
        selPanel:SetSize(310, 104)
        selPanel:SetPoint("TOP", UIParent, "TOP", 0, -60)
        selPanel:SetMovable(true)
        selPanel:EnableMouse(true)
        selPanel:SetFrameStrata("FULLSCREEN_DIALOG")
        selPanel:SetClampedToScreen(true)
        Bg(selPanel, 0.20, 0.22, 0.30, 1)

        local spTitle = CreateFrame("Frame", nil, selPanel)
        spTitle:SetPoint("TOPLEFT",  selPanel, "TOPLEFT",  1, -1)
        spTitle:SetPoint("TOPRIGHT", selPanel, "TOPRIGHT", -1, -1)
        spTitle:SetHeight(SP_TITLE_H)
        Bg(spTitle, 0.13, 0.14, 0.20, 1)
        spTitle:EnableMouse(true)
        spTitle:RegisterForDrag("LeftButton")
        spTitle:SetScript("OnDragStart", function() selPanel:StartMoving() end)
        spTitle:SetScript("OnDragStop",  function() selPanel:StopMovingOrSizing() end)

        local spLine = spTitle:CreateTexture(nil, "ARTWORK")
        spLine:SetHeight(1)
        spLine:SetPoint("BOTTOMLEFT",  spTitle, "BOTTOMLEFT")
        spLine:SetPoint("BOTTOMRIGHT", spTitle, "BOTTOMRIGHT")
        spLine:SetColorTexture(1, 0.82, 0, 0.45)

        local spTitleText = spTitle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        spTitleText:SetPoint("LEFT", spTitle, "LEFT", 8, 0)
        spTitleText:SetTextColor(0.88, 0.86, 0.80, 1)
        spTitleText:SetText("Select Bars")

        local spBody = CreateFrame("Frame", nil, selPanel)
        spBody:SetPoint("TOPLEFT",     selPanel, "TOPLEFT",     1, -(SP_TITLE_H + 1))
        spBody:SetPoint("BOTTOMRIGHT", selPanel, "BOTTOMRIGHT", -1, 1)
        Bg(spBody, 0.10, 0.11, 0.15, 1)

        local instr = spBody:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        instr:SetPoint("TOPLEFT", spBody, "TOPLEFT", 8, -8)
        instr:SetText("Hover over a bar (turns yellow) and click\nto select it (turns green). Click again to deselect.")
        instr:SetJustifyH("LEFT")
        instr:SetTextColor(0.65, 0.65, 0.72, 1)
        selPanel.instr = instr

        local allBtn     = MakeBtn(spBody, 55, 22, "All")
        local confirmBtn = MakeBtn(spBody, 70, 22, "Confirm", true)
        local cancelBtn  = MakeBtn(spBody, 65, 22, "Cancel")
        allBtn:SetPoint(    "BOTTOMLEFT",  spBody, "BOTTOMLEFT",  8, 8)
        confirmBtn:SetPoint("LEFT", allBtn,    "RIGHT", 4, 0)
        cancelBtn:SetPoint( "LEFT", confirmBtn,"RIGHT", 4, 0)

        allBtn:SetScript("OnClick", function()
            for barId, f in pairs(sel.barFrames) do
                if not sel.chosen[barId] then
                    sel.chosen[barId] = true
                    GetGreenOverlay(barId):SetAllPoints(f)
                    GetGreenOverlay(barId):Show()
                end
            end
        end)

        confirmBtn:SetScript("OnClick", function()
            local ids = {}
            for barId in pairs(sel.chosen) do table.insert(ids, barId) end
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

    selPanel:SetFrameLevel(200)
    selPanel:Show()

    -- Warn when the override/vehicle bar is active and bar 1 was excluded.
    if selPanel.instr then
        local overrideActive = (HasOverrideActionBar and HasOverrideActionBar())
                            or (HasVehicleActionBar  and HasVehicleActionBar())
                            or (HasPetBattleActionBar and HasPetBattleActionBar())
        if overrideActive then
            selPanel.instr:SetText("Hover a bar and click to select (turns green).\n|cffFF8844Main Bar hidden — dismount to save it.|r")
        else
            selPanel.instr:SetText("Hover over a bar (turns yellow) and click\nto select it (turns green). Click again to deselect.")
        end
    end
end

-- ── New profile flow ──────────────────────────────────────────────────────────
local newDialog = BuildDarkFrame("ABS_NewDialog", 320, 152)
newDialog.titleText:SetText("New Profile")
local newLbl = newDialog.body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
newLbl:SetPoint("TOPLEFT", newDialog.body, "TOPLEFT", PAD, -PAD)
newLbl:SetTextColor(0.60, 0.60, 0.70, 1)
newLbl:SetText("Enter a name for the new profile:")
local newWrap, newEB = MakeInputBox(newDialog.body)
newWrap:SetPoint("LEFT",  newDialog.body, "LEFT",  PAD,  0)
newWrap:SetPoint("RIGHT", newDialog.body, "RIGHT", -PAD, 0)
newWrap:SetPoint("TOPLEFT", newLbl, "BOTTOMLEFT", 0, -8)
newDialog.editBox = newEB
local newErr = newDialog.body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
newErr:SetPoint("TOPLEFT", newWrap, "BOTTOMLEFT", 0, -4)
newErr:SetTextColor(1, 0.3, 0.3, 1)
newErr:SetText("")
newDialog.err = newErr
local newConfirm = MakeBtn(newDialog.body, 80, 24, "Next >>", true)
local newCancel  = MakeBtn(newDialog.body, 65, 24, "Cancel")
newConfirm:SetPoint("BOTTOMRIGHT", newDialog.body, "BOTTOMRIGHT", -PAD, PAD)
newCancel:SetPoint( "RIGHT", newConfirm, "LEFT", -4, 0)
newCancel:SetScript("OnClick",  function() newDialog:Hide() end)
newEB:SetScript("OnEscapePressed", function() newDialog:Hide() end)
newEB:SetScript("OnEnterPressed",  function() newConfirm:Click() end)
newDialog:SetScript("OnShow", function()
    newErr:SetText("")
    newEB:SetFocus()
end)
newConfirm:SetScript("OnClick", function()
    local name = newEB:GetText():match("^%s*(.-)%s*$")
    if not name or name == "" then return end
    if ABS.db.profiles[name] then
        newErr:SetText('A profile named "' .. name .. '" already exists.')
        return
    end
    newDialog:Hide()
    StartSelector(function(barIds)
        ABS:SaveProfile(name, barIds)
        selectedProfile = name
        RefreshList()
        RenderDetail(name)
        applyBtn:SetEnabled(true)
        renameBtn:SetEnabled(true)
        deleteBtn:SetEnabled(true)
        copyBtn:SetEnabled(true)
        print("|cff00ccff[Action Bar Storage]|r Profile \"" .. name .. "\" saved (" .. #barIds .. " bar(s)).")
    end)
end)

newBtn:SetScript("OnClick", function()
    newDialog.editBox:SetText("")
    newDialog:SetPoint("CENTER")
    newDialog:Show()
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
            copyBtn:SetEnabled(true)
        else
            ReleaseRows()
            detEmpty:Show()
            detTitle:SetText("")
            detMeta:SetText("")
            collapseAllBtn:SetText("")
            expandAllBtn:SetText("")
            collapseAllHit:Hide()
            expandAllHit:Hide()
            applyBtn:SetEnabled(false)
            renameBtn:SetEnabled(false)
            deleteBtn:SetEnabled(false)
            copyBtn:SetEnabled(false)
        end
        main:Show()
    end
end
