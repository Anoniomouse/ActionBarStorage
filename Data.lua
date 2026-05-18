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

-- Returns barId -> frame table for all bars that are currently visible.
-- Used by the selector overlay; tries IsShown first, falls back to any frame
-- with non-zero width so third-party bars with unusual show/hide logic are found.
function ABS:GetVisibleBarFrames()
    local found = {}
    for barId = 1, #self.BARS do
        local candidates = self.BAR_FRAME_CANDIDATES[barId] or {}
        -- Pass 1: prefer frames that report IsShown
        for _, name in ipairs(candidates) do
            local f = _G[name]
            if f and f.IsShown and f:IsShown() then
                found[barId] = f
                break
            end
        end
        -- Pass 2: accept any frame with a non-zero rendered width
        if not found[barId] then
            for _, name in ipairs(candidates) do
                local f = _G[name]
                if f and f.GetWidth and f:GetWidth() > 0 then
                    found[barId] = f
                    break
                end
            end
        end
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
            -- GetItemInfo may return nil for uncached items; name will show on next load
            local iname, _, _, _, _, _, _, _, _, itex = GetItemInfo(id)
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

-- Find a spell in the player spellbook by spellID and pick it up onto the cursor
local function PickupSpellByID(spellID)
    local i = 1
    while true do
        local info = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
        if not info then break end
        if info.spellID == spellID then
            PickupSpellBookItem(i, Enum.SpellBookSpellBank.Player)
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
