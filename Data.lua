local ABS = ActionBarStorage

-- Bar definitions: each bar maps to 12 consecutive action slots
ABS.BARS = {
    { id = 1, label = "Main Bar (1)",           startSlot = 1  },
    { id = 2, label = "Bar 2",                  startSlot = 13 },
    { id = 3, label = "Bar 3",                  startSlot = 25 },
    { id = 4, label = "Bar 4",                  startSlot = 37 },
    { id = 5, label = "Multi-Bar Bottom Left",  startSlot = 49 },
    { id = 6, label = "Multi-Bar Bottom Right", startSlot = 61 },
    { id = 7, label = "Multi-Bar Right",        startSlot = 73 },
    { id = 8, label = "Multi-Bar Left",         startSlot = 85 },
}

-- Candidate frame names per bar. Blizzard names first, then ElvUI, Bartender4, Dominos.
ABS.BAR_FRAME_CANDIDATES = {
    [1] = { "MainMenuBar", "MainActionBarFrame", "ActionBar1",
            "ElvUI_Bar1",  "BT4Bar1",  "DominosActionBar1" },
    [2] = { "MultiBarBottomLeft",  "ActionBar2",
            "ElvUI_Bar2",  "BT4Bar2",  "DominosActionBar2" },
    [3] = { "MultiBarBottomRight", "ActionBar3",
            "ElvUI_Bar3",  "BT4Bar3",  "DominosActionBar3" },
    [4] = { "MultiBarRight",       "ActionBar4",
            "ElvUI_Bar4",  "BT4Bar4",  "DominosActionBar4" },
    [5] = { "MultiBarLeft",        "ActionBar5",
            "ElvUI_Bar5",  "BT4Bar5",  "DominosActionBar5" },
    [6] = { "ActionBar6",  "MultiBar5",
            "ElvUI_Bar6",  "BT4Bar6",  "DominosActionBar6" },
    [7] = { "ActionBar7",  "MultiBar6",
            "ElvUI_Bar7",  "BT4Bar7",  "DominosActionBar7" },
    [8] = { "ActionBar8",  "MultiBar7",
            "ElvUI_Bar8",  "BT4Bar8",  "DominosActionBar8" },
}

-- Returns the first visible frame found for a bar, or nil.
-- Used for saving slot data; does not need to be exact for hover detection.
function ABS:GetBarFrame(barId)
    for _, name in ipairs(self.BAR_FRAME_CANDIDATES[barId] or {}) do
        local f = _G[name]
        if f and f.IsShown and f:IsShown() then
            return f
        end
    end
    return nil
end

-- Detect visible action bar frames by scanning child button .action slot numbers.
-- This works with any action bar addon (ElvUI, Bartender4, Dominos, Blizzard)
-- because all WoW action buttons store their slot number in the .action field.
-- We require at least 2 action-button children before accepting a frame as a bar,
-- to avoid false positives from stray buttons.
function ABS:GetVisibleBarFrames()
    local found = {}

    -- pcall wrappers: some UIParent children are Lua proxy tables whose C-level
    -- frame methods reject the self argument even though the method field exists.
    local function safeIsShown(f)
        if not f then return false end
        local ok, shown = pcall(function() return f:IsShown() end)
        return ok and shown == true
    end

    local function safeGetChildren(f)
        if not f then return {} end
        local children
        local ok = pcall(function() children = {f:GetChildren()} end)
        return (ok and children) or {}
    end

    local function GetFrameBarId(frame)
        if not frame then return nil end
        local children = safeGetChildren(frame)
        local count, barId = 0, nil
        for _, child in ipairs(children) do
            local slot = child and child.action
            if type(slot) == "number" and slot >= 1 and slot <= 96 then
                count = count + 1
                if not barId then barId = math.ceil(slot / 12) end
                if count >= 2 then return barId end
            end
        end
        return nil
    end

    -- Recursively walk visible frames up to maxDepth levels below root.
    -- ElvUI and some other addons nest bars 3-4 levels deep inside containers.
    local function scanFrame(frame, depth)
        if depth <= 0 or not safeIsShown(frame) then return end
        local bid = GetFrameBarId(frame)
        if bid and bid >= 1 and bid <= 8 and not found[bid] then
            found[bid] = frame
        else
            for _, child in ipairs(safeGetChildren(frame)) do
                scanFrame(child, depth - 1)
            end
        end
    end

    for _, topFrame in ipairs({UIParent:GetChildren()}) do
        scanFrame(topFrame, 4)
    end

    return found
end

-- Read all 12 slots from a bar and return an array of slot data
function ABS:ReadBar(barId)
    local barDef = self.BARS[barId]
    if not barDef then return nil end

    local slots = {}
    for i = 0, 11 do
        local slot = barDef.startSlot + i
        local actionType, id, subType = GetActionInfo(slot)
        local name, texture = "", nil

        if actionType == "spell" and id then
            local info = C_Spell.GetSpellInfo(id)
            name    = info and info.name or ("Spell " .. id)
            texture = C_Spell.GetSpellTexture(id)
        elseif actionType == "macro" and id then
            local mname, micon = GetMacroInfo(id)
            name    = mname or ("Macro " .. id)
            texture = micon
        elseif actionType == "item" and id then
            -- C_Item.GetItemInfo may return nil for uncached items; name will show on next load
            local iname, _, _, _, _, _, _, _, _, itex = C_Item.GetItemInfo(id)
            name    = iname or ("Item #" .. id)
            texture = itex
        end

        slots[i + 1] = {
            actionType = actionType or "",
            id         = id,
            subType    = subType,
            name       = name,
            texture    = texture,
        }
    end
    return slots
end

-- Find a spell in the player spellbook by spellID and pick it up onto the cursor.
-- PickupSpellBookItem was removed in Midnight 12.0; use C_SpellBook variant or
-- the direct PickupSpell(spellID) global when available.
local function PickupSpellByID(spellID)
    -- C_Spell.PickupSpell is the preferred 12.0 API; PickupSpell is the legacy fallback.
    local directFn = (C_Spell and C_Spell.PickupSpell) or PickupSpell
    if directFn then
        directFn(spellID)
        if GetCursorInfo() then return true end
        ClearCursor()
    end
    -- Last resort: iterate spellbook and use C_SpellBook.PickupSpellBookItem.
    local pickupFn = (C_SpellBook and C_SpellBook.PickupSpellBookItem) or PickupSpellBookItem
    if not pickupFn then return false end
    local i = 1
    while true do
        local info = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
        if not info then break end
        if info.spellID == spellID then
            pickupFn(i, Enum.SpellBookSpellBank.Player)
            return true
        end
        i = i + 1
    end
    return false
end

-- Write saved slot data to a target bar (out-of-combat only)
function ABS:WriteBar(targetBarId, slots)
    if InCombatLockdown() then
        print("|cffFF4444[Action Bar Storage]|r Cannot apply while in combat.")
        return false
    end

    local barDef = self.BARS[targetBarId]
    if not barDef then return false end

    for i, sd in ipairs(slots) do
        local targetSlot = barDef.startSlot + i - 1
        local picked = false

        if sd.actionType == "spell" and sd.id then
            picked = PickupSpellByID(sd.id)
        elseif sd.actionType == "macro" then
            -- Try by name first so it works across characters
            local lookupKey = (sd.name and sd.name ~= "") and sd.name or sd.id
            if lookupKey then
                PickupMacro(lookupKey)
                picked = GetCursorInfo() ~= nil
            end
        elseif sd.actionType == "item" and sd.id then
            PickupItem(sd.id)
            picked = GetCursorInfo() ~= nil
        end

        if picked then
            PlaceAction(targetSlot)
        end
        ClearCursor()
    end
    return true
end

-- Save a named profile containing data from the given bar IDs
function ABS:SaveProfile(profileName, barIds)
    local profile = {
        name    = profileName,
        savedBy = UnitName("player"),
        savedOn = date("%Y-%m-%d"),
        bars    = {},
    }
    for _, barId in ipairs(barIds) do
        local def = self.BARS[barId]
        if def then
            profile.bars[barId] = {
                label = def.label,
                slots = self:ReadBar(barId),
            }
        end
    end
    self.db.profiles[profileName] = profile
    return profile
end

-- Apply a profile; targetMap optionally remaps {[savedBarId] = destinationBarId}
function ABS:ApplyProfile(profileName, targetMap)
    if InCombatLockdown() then
        print("|cffFF4444[Action Bar Storage]|r Cannot apply while in combat.")
        return false
    end
    local profile = self.db.profiles[profileName]
    if not profile then return false end

    local count = 0
    for barId, barData in pairs(profile.bars) do
        local dest = (targetMap and targetMap[barId]) or barId
        if self:WriteBar(dest, barData.slots) then
            count = count + 1
        end
    end
    print("|cff00ccff[Action Bar Storage]|r Applied \"" .. profileName .. "\" (" .. count .. " bar(s)).")
    return true
end

function ABS:DeleteProfile(profileName)
    self.db.profiles[profileName] = nil
end

function ABS:RenameProfile(oldName, newName)
    if not newName or newName == "" then return false end
    if self.db.profiles[newName] then return false end
    local p = self.db.profiles[oldName]
    if not p then return false end
    p.name = newName
    self.db.profiles[newName] = p
    self.db.profiles[oldName] = nil
    return true
end

function ABS:GetSortedProfiles()
    local list = {}
    for name in pairs(self.db.profiles) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end
