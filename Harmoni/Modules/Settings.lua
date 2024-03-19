local Settings = {}          --ty guglio i am basing this very heavily on rit

Settings.SettingTable = {
    ["General"] = {
        description = "These settings affect basic features of Harmoni",
        language = "English",
        displayMode = "Windowed",
    },
    ["Input"] = {
        description = "Set your keybinds",
        LeftKeybind = "d",
        DownKeybing = "f",
        UpKeybind = "j",
        RightKeybind = "k",
    },
    ["Gameplay"] = {
        description = "These settings affect the game during Gameplay",
        scrollDirection = {"Scroll Direction", "Down"},
        noteLaneHeight = {"Note Lane Height", 25},
        noteLaneWidth = {"Note Lane Width", 5},
        backgroundDimSetting = {"Background Dim", 0.7},
        backgroundBlurSetting = {"Background Blur", 20},
        instantPause = {"Instant Pause", false},
        backgroundBumping = {"Background Bumping", false},
        noteSplash = {"Note Splash", true},
        breakAlerts = {"Break Alerts", true},
    },
    ["Audio"] = {
        description = "These settings affect the way Audio is played",
        masterVolume = {"Master Volume", 100},
        windowInactiveVolumePercent = {"Window Inactive Volume", 25},
        effectVolume = {"Sound Effect Volume", 100},
        musicVolume = {"Music Volume", 100},
        audioOffset = {"Audio Offset", 0},
    },
    ["Advanced"] = {
        description = "These settings affect advanced features of Harmoni",
        showFps = {"Show FPS", false},
        showDebugOverlay = {"Show Debug Overlay", false},
        openGameFolder = "Open Game Folder",
    },
    ["metadata"] = {
        settingsVersion = 2,
    }
}

function Settings.saveSettings()
    Json.encode(Settings.options, "settings")
end

function Settings.loadSettings()
    if not love.filesystem.getInfo("settings") then
        Settings.saveSettings()
    end

    --Settings.options = ini.parse("settings")
    local savedSettings = Json.decode("settings")
    for i, type in pairs(savedSettings) do
        for j, setting in pairs(type) do
            Settings.SettingTable[i][j] = savedSettings[i][j]
        end
    end
end

return Settings