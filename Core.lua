ActionBarStorage = {}
local ABS = ActionBarStorage
ABS.VERSION = "1.0.7"

local function InitDB()
    if not ActionBarStorageDB then
        ActionBarStorageDB = { profiles = {} }
    end
    if not ActionBarStorageDB.profiles then
        ActionBarStorageDB.profiles = {}
    end
    ABS.db = ActionBarStorageDB
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ActionBarStorage" then
        InitDB()
    elseif event == "PLAYER_LOGIN" then
        local count = 0
        for _ in pairs(ABS.db and ABS.db.profiles or {}) do count = count + 1 end
        print("|cff00ccff[Action Bar Storage]|r v" .. ABS.VERSION .. " loaded. "
              .. count .. " profile(s). |cffFFD100/abs|r to open.")
    end
end)

SLASH_ABS1 = "/abs"
SLASH_ABS2 = "/actionbarstorage"
SlashCmdList["ABS"] = function(msg)
    local cmd = msg and msg:match("^%s*(.-)%s*$"):lower() or ""
    if cmd == "debug" then
        print("|cffFFD100[ABS Debug]|r Scanning bar frames...")
        local frames = ABS:GetVisibleBarFrames()
        local count = 0
        for barId, f in pairs(frames) do
            local name = (f.GetName and f:GetName()) or "(unnamed)"
            local w    = (f.GetWidth  and math.floor(f:GetWidth()  + 0.5)) or "?"
            local h    = (f.GetHeight and math.floor(f:GetHeight() + 0.5)) or "?"
            print(string.format("  Bar %d -> %s  %sx%s", barId, name, w, h))
            count = count + 1
        end
        if count == 0 then
            print("  |cffFF4444No bar frames found!|r")
            -- Check known Blizzard globals
            local probes = {"ActionButton1","MultiBarBottomLeftButton1","MultiBarBottomRightButton1","MultiBarRightButton1","MultiBarLeftButton1"}
            for _, n in ipairs(probes) do
                local btn = _G[n]
                local exists = btn ~= nil
                local shown  = exists and pcall(function() return btn:IsShown() end) and btn:IsShown()
                print(string.format("    %s: exists=%s shown=%s", n, tostring(exists), tostring(shown)))
            end
        end
        print(string.format("  Total: %d frame(s) found.", count))
    else
        ABS:ToggleUI()
    end
end
