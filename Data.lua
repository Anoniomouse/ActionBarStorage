local ABS = ActionBarStorage

-- Bar definitions: each bar maps to 12 consecutive action slots.
-- Extended to 18 bars so ElvUI / Bartender4 extra bars (slots 97-216) are covered.
ABS.BARS = {
    { id = 1,  label = "Main Bar (1)",           startSlot = 1   },
    { id = 2,  label = "Bar 2",                  startSlot = 13  },
    { id = 3,  label = "Bar 3",                  startSlot = 25  },
    { id = 4,  label = "Bar 4",                  startSlot = 37  },
    { id = 5,  label = "Multi-Bar Bottom Left",  startSlot = 49  },
    { id = 6,  label = "Multi-Bar Bottom Right", startSlot = 61  },
    { id = 7,  label = "Multi-Bar Right",        startSlot = 73  },
    { id = 8,  label = "Multi-Bar Left",         startSlot = 85  },
    { id = 9,  label = "Bar 9",                  startSlot = 97  },
    { id = 10, label = "Bar 10",                 startSlot = 109 },
    { id = 11, label = "Bar 11",                 startSlot = 121 },
    { id = 12, label = "Bar 12",                 startSlot = 133 },
    { id = 13, label = "Bar 13",                 startSlot = 145 },
    { id = 14, label = "Bar 14",                 startSlot = 157 },
    { id = 15, label = "Bar 15",                 startSlot = 169 },
    { id = 16, label = "Bar 16",                 startSlot = 181 },
    { id = 17, label = "Bar 17",                 startSlot = 193 },
    { id = 18, label = "Bar 18",                 startSlot = 205 },
}
local MAX_BAR  = #ABS.BARS          -- 18
local MAX_SLOT = MAX_BAR * 12       -- 216

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
-- Returns true if a frame belongs to an override/vehicle/possess bar system
-- that temporarily replaces regular bar content.
local function IsOverrideFrame(f)
    local function nameIsOverride(n)
        return n:find("Override") or n:find("Vehicle")
            or n:find("Possess")  or n:find("PetBattle") or n:find("MultiCast")
    end
    local ok, n = pcall(function() return f:GetName() end)
    if ok and n and nameIsOverride(n) then return true end
    local ok2, parent = pcall(function() return f:GetParent() end)
    if ok2 and parent then
        local ok3, pn = pcall(function() return parent:GetName() end)
        if ok3 and pn and nameIsOverride(pn) then return true end
    end
    return false
end

function ABS:GetVisibleBarFrames()
    local found = {}
    if not EnumerateFrames then return found end

    -- When the override/vehicle action bar is active, bar 1's slot data reflects
    -- the temporary override actions, not the character's stored spells. Exclude
    -- bar 1 from the selectable set so users can't accidentally capture it.
    local overrideActive = (HasOverrideActionBar and HasOverrideActionBar())
                        or (HasVehicleActionBar  and HasVehicleActionBar())
                        or (HasPetBattleActionBar and HasPetBattleActionBar())

    -- Instead of looking for frames that CONTAIN action buttons, scan every frame
    -- to find frames that ARE action buttons (.action slot field present).
    -- Grouping buttons by bar ID then taking GetParent() gives us the bar frame
    -- without any depth limit or container-visibility assumptions.
    local barButtons = {}   -- barId -> list of button frames

    local f = EnumerateFrames()
    while f do
        local slot
        -- Field access on userdata frames can error on some proxy types.
        pcall(function() slot = f.action end)
        if type(slot) == "number" and slot >= 1 and slot <= MAX_SLOT then
            local ok, shown = pcall(function() return f:IsShown() end)
            if ok and shown and not IsOverrideFrame(f) then
                local barId = math.ceil(slot / 12)
                if not barButtons[barId] then barButtons[barId] = {} end
                table.insert(barButtons[barId], f)
            end
        end
        f = EnumerateFrames(f)
    end

    -- Require ≥2 visible buttons so we don't pick up stray buttons.
    -- Use the first button's parent as the representative bar frame.
    for barId, buttons in pairs(barButtons) do
        local skip = (barId == 1 and overrideActive)
        if not skip and barId >= 1 and barId <= MAX_BAR and #buttons >= 2 then
            local ok, parent = pcall(function() return buttons[1]:GetParent() end)
            if ok and parent then
                found[barId] = parent
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
            -- GetActionText reads the macro name straight from the action slot.
            -- This works even when GetMacroInfo's expected index ≠ the id returned
            -- by GetActionInfo (a Midnight 12.0 API discrepancy).
            local slotText = GetActionText and GetActionText(slot)
            local mname, micon = GetMacroInfo(id)
            if slotText and slotText ~= "" then mname = slotText end
            if not micon then micon = GetActionTexture and GetActionTexture(slot) end
            name    = mname or ("Macro " .. id)
            texture = micon
        elseif actionType == "item" and id then
            -- C_Item.GetItemInfo may return nil for uncached items; name will show on next load
            local iname, _, _, _, _, _, _, _, _, itex = C_Item.GetItemInfo(id)
            name    = iname or ("Item #" .. id)
            texture = itex
        elseif actionType == "flyout" and id then
            -- GetFlyoutInfo returns name, description, numSlots, isKnown
            local ok, fname = pcall(GetFlyoutInfo, id)
            if ok and fname and fname ~= "" then
                name = fname
            else
                -- Midnight may have moved this into C_SpellBook
                if C_SpellBook and C_SpellBook.GetFlyoutInfo then
                    local ok2, finfo = pcall(C_SpellBook.GetFlyoutInfo, id)
                    if ok2 and finfo then
                        name = (type(finfo) == "table" and finfo.name) or tostring(finfo)
                    end
                end
                if name == "" then name = "Flyout #" .. id end
            end
        elseif (actionType == "companion" and subType == "MOUNT" and id)
            or (actionType == "summonmount" and id) then
            -- "companion"/"MOUNT" is the pre-Midnight type; "summonmount" is Midnight 12.0+.
            -- id may be a mountID or a spellID depending on the version; try both.
            local resolved = false
            if C_MountJournal and C_MountJournal.GetMountInfoByID then
                local ok, a, _, c = pcall(C_MountJournal.GetMountInfoByID, id)
                if ok and a and a ~= "" then
                    if type(a) == "table" then
                        name    = a.name or ""
                        texture = a.icon
                    else
                        name    = tostring(a)
                        texture = c
                    end
                    resolved = (name ~= "")
                end
            end
            if not resolved then
                -- Fallback: treat id as a spellID (e.g. mount summon spell)
                if C_Spell and C_Spell.GetSpellInfo then
                    local info = C_Spell.GetSpellInfo(id)
                    if info and info.name then
                        name    = info.name
                        texture = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
                        resolved = true
                    end
                end
            end
            if not resolved or name == "" then name = "Mount #" .. id end
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

-- Pick up a spell onto the cursor by spellID.
-- Mounts use actionType "summonmount" (Midnight 12.0+) or "companion" and are handled separately.
-- spellName is used as a last-resort fallback for spec-switched spells whose ID changed.
local function PickupSpellByID(spellID, spellName)
    -- Preferred path: direct pickup by ID (Midnight 12.0+).
    local directFn = (C_Spell and C_Spell.PickupSpell) or PickupSpell
    if directFn then
        directFn(spellID)
        if GetCursorInfo() then return true end
        ClearCursor()
    end

    local pickupFn = (C_SpellBook and C_SpellBook.PickupSpellBookItem) or PickupSpellBookItem
    if not pickupFn then return false end

    -- Pass 1: match by spellID (exact).
    -- Pass 2: match by spell name (handles spec variants with different IDs).
    local nameLo = spellName and spellName ~= "" and spellName:lower() or nil
    for pass = 1, (nameLo and 2 or 1) do
        local i = 1
        while true do
            local info = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
            if not info then break end
            local match = false
            if pass == 1 then
                match = (info.spellID == spellID)
            else
                local si = info.spellID and C_Spell.GetSpellInfo(info.spellID)
                match = si and si.name and si.name:lower() == nameLo
            end
            if match then
                pickupFn(i, Enum.SpellBookSpellBank.Player)
                if GetCursorInfo() then return true end
                ClearCursor()
            end
            i = i + 1
        end
    end
    return false
end

-- Write saved slot data to a target bar (out-of-combat only).
-- failures: optional table; skipped non-empty slots are appended as
--   { barLabel, slot, name, actionType, reason }
function ABS:WriteBar(targetBarId, slots, failures)
    if InCombatLockdown() then
        print("|cffFF4444[Action Bar Storage]|r Cannot apply while in combat.")
        return false
    end

    local barDef = self.BARS[targetBarId]
    if not barDef then return false end

    for i, sd in ipairs(slots) do
        local targetSlot = barDef.startSlot + i - 1

        -- Always clear the target slot first. PickupAction on an empty slot is a
        -- no-op; on a filled slot it moves the action to the cursor so ClearCursor
        -- discards it — leaving the slot empty before we place the new action.
        -- This also handles the "replace existing" and "make empty" cases.
        PickupAction(targetSlot)
        ClearCursor()

        local picked = false

        if sd.actionType == "spell" and sd.id then
            picked = PickupSpellByID(sd.id, sd.name)
        elseif sd.actionType == "flyout" and sd.id then
            -- Search spellbook for the flyout entry matching this flyoutID.
            -- itemType may be the string "FLYOUT" or Enum.SpellBookItemType.Flyout (a number).
            -- The flyout ID may be in info.flyoutID or info.actionID depending on the version.
            local pickupFn = (C_SpellBook and C_SpellBook.PickupSpellBookItem) or PickupSpellBookItem
            if pickupFn and C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
                local enumFlyout = Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout
                local i = 1
                while true do
                    local info = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
                    if not info then break end
                    local isFlyout = info.itemType == "FLYOUT"
                                  or (enumFlyout and info.itemType == enumFlyout)
                    local matchId  = info.flyoutID == sd.id or info.actionID == sd.id
                    if isFlyout and matchId then
                        pcall(pickupFn, i, Enum.SpellBookSpellBank.Player)
                        picked = GetCursorInfo() ~= nil
                        break
                    end
                    i = i + 1
                end
            end
        elseif sd.actionType == "macro" then
            local mname = (sd.name and sd.name ~= "") and sd.name or nil
            -- 1. Direct name lookup
            if mname then
                PickupMacro(mname)
                picked = GetCursorInfo() ~= nil
                if not picked then ClearCursor() end
            end
            -- 2. Case-insensitive full scan (general macros then character macros)
            if not picked and mname then
                local numG, numC = GetNumMacros()
                local charBase = MAX_ACCOUNT_MACROS or 120
                local lo = mname:lower()
                for pass = 1, 2 do
                    local iStart = (pass == 1) and 1           or (charBase + 1)
                    local iEnd   = (pass == 1) and (numG or 0) or (charBase + (numC or 0))
                    for idx = iStart, iEnd do
                        local n = GetMacroInfo(idx)
                        if n and n:lower() == lo then
                            PickupMacro(idx)
                            picked = GetCursorInfo() ~= nil
                            if picked then break end
                            ClearCursor()
                        end
                    end
                    if picked then break end
                end
            end
            -- 3. Index fallback: try the saved index directly.
            -- This handles macros where the name wasn't resolved at save time ("Macro N").
            -- PickupMacro silently no-ops if the index is empty, so no wrong-macro risk.
            if not picked and sd.id then
                PickupMacro(sd.id)
                picked = GetCursorInfo() ~= nil
                if not picked then ClearCursor() end
            end
        elseif sd.actionType == "item" and sd.id then
            PickupItem(sd.id)
            picked = GetCursorInfo() ~= nil
        elseif (sd.actionType == "companion" or sd.actionType == "summonmount") and sd.id then
            -- Try direct spell pickup first (works when id is a spellID in Midnight 12.0+).
            local directFn = (C_Spell and C_Spell.PickupSpell) or PickupSpell
            if directFn then
                pcall(directFn, sd.id)
                picked = GetCursorInfo() ~= nil
                if not picked then ClearCursor() end
            end
            -- Fallback: search mount journal by display index (works when id is a mountID).
            if not picked and C_MountJournal and C_MountJournal.Pickup then
                local getNum = C_MountJournal.GetNumDisplayedMounts
                local getID  = C_MountJournal.GetDisplayedMountID
                if getNum and getID then
                    local ok, n = pcall(getNum)
                    if ok and n then
                        for displayIdx = 1, n do
                            local ok2, mountID = pcall(getID, displayIdx)
                            if ok2 and mountID == sd.id then
                                pcall(C_MountJournal.Pickup, displayIdx)
                                picked = GetCursorInfo() ~= nil
                                break
                            end
                        end
                    end
                end
                -- Last resort: Summon Random Favorite Mount uses display index 0.
                -- This runs when the id doesn't match any regular mount in the journal.
                if not picked then
                    pcall(C_MountJournal.Pickup, 0)
                    picked = GetCursorInfo() ~= nil
                end
            end
        end

        if picked then
            PlaceAction(targetSlot)
        elseif failures and sd.actionType ~= "" and sd.id then
            local reason
            if     sd.actionType == "spell"  then reason = "spell not learned / wrong class"
            elseif sd.actionType == "macro"  then reason = "macro not found on this character"
            elseif sd.actionType == "item"   then reason = "item not in bags"
            elseif sd.actionType == "flyout" then reason = "flyout not available"
            else                                  reason = "not available"
            end
            local dname = (sd.name and sd.name ~= "") and sd.name
                          or (sd.actionType .. " #" .. tostring(sd.id))
            table.insert(failures, {
                barLabel   = barDef.label,
                slot       = i,
                name       = dname,
                actionType = sd.actionType,
                reason     = reason,
            })
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

-- Apply a profile; targetMap optionally remaps {[savedBarId] = destinationBarId}.
-- barFilter: optional set {[barId]=true} — only those bars are written.
function ABS:ApplyProfile(profileName, targetMap, barFilter)
    if InCombatLockdown() then
        print("|cffFF4444[Action Bar Storage]|r Cannot apply while in combat.")
        return false
    end
    local profile = self.db.profiles[profileName]
    if not profile then return false end

    local PRE      = "|cff00ccff[Action Bar Storage]|r"
    local failures = {}
    local count    = 0
    for barId, barData in pairs(profile.bars) do
        if not barFilter or barFilter[barId] then
            local dest = (targetMap and targetMap[barId]) or barId
            if self:WriteBar(dest, barData.slots, failures) then
                count = count + 1
            end
        end
    end

    if #failures == 0 then
        print(PRE .. " Applied \"" .. profileName .. "\" (" .. count .. " bar(s)) — all slots restored.")
    else
        print(PRE .. " Applied \"" .. profileName .. "\" (" .. count .. " bar(s)) — "
              .. #failures .. " slot(s) skipped:")
        for _, f in ipairs(failures) do
            print(string.format("  |cffFF8844%s  slot %d|r  %s  |cff666677(%s)|r",
                f.barLabel, f.slot, f.name, f.reason))
        end
    end
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

-- Serialize a profile to a shareable import string.
function ABS:ExportProfile(profileName)
    local p = self.db.profiles[profileName]
    if not p then return nil end

    -- esc: strip | to prevent WoW chat corruption; ~ is the field separator
    -- so it must also be stripped.
    local esc = function(s) return (s or ""):gsub("[|~]", " ") end
    local lines = {
        "---ABS EXPORT---",
        -- Use ~ so WoW escape sequences like |r, |c, |R never corrupt field boundaries.
        "N~" .. esc(p.name or profileName),
        "A~" .. esc(p.savedBy or ""),
        "D~" .. esc(p.savedOn  or ""),
    }
    for barId = 1, #self.BARS do
        local bd = p.bars[barId]
        if bd then
            table.insert(lines, "B~" .. barId .. "~" .. esc(bd.label))
            for si, sd in ipairs(bd.slots) do
                table.insert(lines, table.concat({
                    "S", si,
                    esc(sd.actionType),
                    tostring(sd.id or ""),
                    esc(sd.subType or ""),
                    esc(sd.name),
                }, "~"))
            end
        end
    end
    table.insert(lines, "---END---")
    return table.concat(lines, "\n")
end

-- Parse an export string and store it as a new profile.
-- Returns (profileName, nil) on success, (nil, errorMsg) on failure.
-- If a profile with the same name already exists, a numeric suffix is appended.
function ABS:ImportProfile(str)
    -- Strip Windows carriage returns so \r\n doesn't corrupt field parsing.
    if str then str = str:gsub("\r", "") end
    -- Use plain find so we don't fight Lua's "." not matching newlines.
    local s = str and str:find("---ABS EXPORT---", 1, true)
    local e = str and str:find("---END---",        1, true)
    if not s or not e or e <= s then return nil, "No valid ABS export block found." end
    local block = str:sub(s + #"---ABS EXPORT---", e - 1)

    local profile = { bars = {} }
    local curBarId = nil

    for line in (block .. "\n"):gmatch("([^\n]*)\n") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then
            -- New exports use ~ as field separator; old exports use |.
            -- Detect by whether the line contains ~ before the first |.
            local sep   = (line:find("~", 1, true) and "~") or "|"
            local pat   = sep == "~" and "([^~]*)~" or "([^|]*)|"
            local p = {}
            for f in (line .. sep):gmatch(pat) do
                table.insert(p, f)
            end
            local cmd = p[1]
            if     cmd == "N" then profile.name    = p[2] or ""
            elseif cmd == "A" then profile.savedBy = p[2] or ""
            elseif cmd == "D" then profile.savedOn = p[2] or ""
            elseif cmd == "B" then
                curBarId = tonumber(p[2])
                if curBarId then
                    local def = self.BARS[curBarId]
                    profile.bars[curBarId] = {
                        label = (p[3] and p[3] ~= "" and p[3]) or (def and def.label) or ("Bar " .. curBarId),
                        slots = {},
                    }
                end
            elseif cmd == "S" and curBarId then
                local idx = tonumber(p[2])
                if idx then
                    profile.bars[curBarId].slots[idx] = {
                        actionType = p[3] or "",
                        id         = tonumber(p[4]),
                        subType    = (p[5] and p[5] ~= "" and p[5]) or nil,
                        name       = p[6] or "",
                        texture    = nil,
                    }
                end
            end
        end
    end

    if not profile.name or profile.name == "" then
        return nil, "Export is missing the profile name."
    end

    -- Ensure unique name
    local finalName = profile.name
    if self.db.profiles[finalName] then
        local i = 2
        while self.db.profiles[finalName .. " (" .. i .. ")"] do i = i + 1 end
        finalName = finalName .. " (" .. i .. ")"
        profile.name = finalName
    end

    self.db.profiles[finalName] = profile
    return finalName, nil
end
