ActionBarStorage = {}
local ABS = ActionBarStorage
ABS.VERSION = "1.0.0"

local function InitDB()
    if not ActionBarStorageDB then
        ActionBarStorageDB = { profiles = {} }
    end
    -- Ensure profiles key exists (guards against partially-written SavedVariables)
    if not ActionBarStorageDB.profiles then
        ActionBarStorageDB.profiles = {}
    end
    ABS.db = ActionBarStorageDB
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("VARIABLES_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ActionBarStorage" then
        InitDB()
    elseif event == "VARIABLES_LOADED" then
        -- VARIABLES_LOADED fires after all SavedVariables are guaranteed restored.
        -- Re-point ABS.db in case the variable was reassigned after ADDON_LOADED.
        InitDB()
    elseif event == "PLAYER_LOGIN" then
        print("|cff00ccff[Action Bar Storage]|r v" .. ABS.VERSION .. " loaded. |cffFFD100/abs|r to open.")
    end
end)

SLASH_ABS1 = "/abs"
SLASH_ABS2 = "/actionbarstorage"
SlashCmdList["ABS"] = function()
    ABS:ToggleUI()
end
