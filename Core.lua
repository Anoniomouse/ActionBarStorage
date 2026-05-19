ActionBarStorage = {}
local ABS = ActionBarStorage
ABS.VERSION = "1.0.0"

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
SlashCmdList["ABS"] = function()
    ABS:ToggleUI()
end
