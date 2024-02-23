versionNumber = "Harmoni Beta 1.2.0"

local utf8 = require("utf8")
moonshine = require("moonshine")
Inits = require("inits")

--function print() return end
if love.filesystem.isFused() then
    discordRPC = require("Modules.discordRPC")
    usingRPC = true
    function InitializeDiscord()
        discordRPC.initialize("1200949844655755304", false, "2781170")
        presenceUpdate = 0
        presence = {
            state = "In the Menus",
            details = "Title Screen",
            largeImageKey = "rpc_icon"
        }
    end
    InitializeDiscord()
end



function mod(a, b)
    return a - (math.floor(a/b)*b)
end

love.keyboard.setKeyRepeat(true)

love.filesystem.createDirectory("Skins")
love.filesystem.createDirectory("Saves")

songListLength = love.filesystem.getDirectoryItems("Music")
if #songListLength == 0 then
    print("Install Included Songs")
    includedSongs = love.filesystem.getDirectoryItems("Included Songs")
    --print(#love.filesystem.getDirectoryItems("Included Songs"))
    for i,dir in ipairs(includedSongs) do
        local path = "Music/"..dir
       -- print(path)
        love.filesystem.createDirectory(path)
        local files = love.filesystem.getDirectoryItems("Included Songs/"..dir)
        print("Included Songs/"..dir)
        print(#files)
        for i,file in ipairs(files) do
            love.filesystem.write(path.."/"..file, love.filesystem.read("Included Songs/"..dir.."/"..file))
        end
    end
end


if disablePrint then
    function print() end
end
 
function toGameScreen(x, y)
    -- converts a position to the game screen
    local ratio = 1
    ratio = math.min(Inits.GameWidth/Inits.GameWidth, Inits.GameHeight/Inits.GameHeight)
    local x, y = x - Inits.GameWidth/2, y - Inits.GameHeight/2
    x, y = x / ratio, y / ratio
    x, y = x + Inits.GameWidth/2, y + Inits.GameHeight/2
    love.graphics.setDefaultFilter("nearest")

    return x, y
end

function love.directorydropped(file)
    love.filesystem.mount(file, "Music")
end

function love.load()
    
    -- Setup Libraries
    Input = (require("Libraries.Baton")).new({
        controls = {
            GameLeft  =  { "key:d" },
            GameDown  =  { "key:f" },
            GameUp    =  { "key:j" },
            GameRight =  { "key:k" },
            GameConfirm  =  { "key:return" },
            GameBack = { "key:escape", "key:backspace" },
            GameRestart = { "key:`" },

            MenuUp = { "key:up" },
            MenuDown = { "key:down" },
            MenuConfirm = { "key:return" },

            setFullscreen = { "key:f11" },
            MenuBack = { "key:escape", "key:backspace" },
            SearchToggle = { "key:tab"},
            openSongGoogleDrive = { "key:f1" },
            openSongFolder = { "key:f2" },
            randomSongKey = { "key:r" },
            introSkip = { "key:space" },
        }
    })
    Class = require("Libraries.Class")
    State = require("Libraries.State")
    tinyyaml = require("Libraries.tinyyaml")

    Timer = require("Libraries.Timer")

    GameScreen = love.graphics.newCanvas(Inits.GameWidth, Inits.GameHeight)

    -- Initialize Game
    States = require("Modules.States")
    Objects = require("Modules.Objects")
    String = require("Modules.String")
    ChartParse = require("Modules.ChartParse")




    require("Modules.Debug")

    volumeOpacity = {0}
    volumeVelocity = 0
    printableVolume = {love.audio.getVolume()}
    maxVolVelocity = 25
    MusicTime = 0
--[[

    Tips = {
        "Press F11 to Fullscreen.",
        "Please report any bugs you find by opening a Github issue",
        "Press R in the Song Select menu to pick a random song \n(not even added yet lmfao this is just here so i dont forget to add it)", -- this isnt even added yet lmfao
        "Request features by opening a Github issue",
        "Don't miss",
        "Settings will work correctly eventually I promise lmao",
        "Wishlist Rit on Steam!",
        "Hold ALT and scroll to change the volume",
        "More Song Packs will be available in the future",
        "Import your own songs from Quaver, just export the song in Quaver, extract it, and place it in Harmoni's Music Folder."
    }

    extremeRareTips = {
        "you should just delete the game honestly",
        "still better than osu",
        "'did you know that in heat colors change to another color dont believe me stick your fingers up your ass'\n-Sapple",
        "just play quaver lmao",
        "pickles",
        "'The best part of fucking Yoshi is that you have a ride home in the morning'\n-President Barack Obama",
        "Is an interesting game 🎯\nAm just play it\nWow\n-Heng"
    }

    --]]

    Tips = {
        "Press F11 to Fullscreen",
        "Please report any bugs you find by opening a Github issue",
        "Press R in the Song Select menu to pick a random song", -- this isnt even added yet lmfao
        "Request features by opening a Github issue",
        "Don't miss",
        "Settings will save eventually I promise lmao",
        "Wishlist Rit on Steam!",
        "Hold ALT and scroll to change the volume",
        "More Song Packs will be available in the future",
        "To import your own songs from Quaver, just export the song in Quaver, extract it, and place it in Harmoni's Music Folder.",
        "Press F2 in the Song Select menu to visit the song packs Google Drive",
    }
    extremeRareTips = {
        "you should just delete the game honestly",
        "still better than osu",
        "'did you know that in heat colors change to another color dont believe me stick your fingers up your ass'\n-Sapple",
        "just play quaver lmao",
        "pickles",
        "'The best part of fucking Yoshi is that you have a ride home in the morning'\n-President Barack Obama",
        "Is an interesting game\nAm just play it\nWow\n\n-Heng",
        "Do it jiggle?",
        "'Is good game, would give it a try'\n\n-Sapple",
        "When she doin acrobatics on the peenor, so you gotta lock in",
        "We harmomize the entire house without a single drop of cheese falling\n\ncry about it guglio",
    }




    ExtraBigFont = love.graphics.newFont("Fonts/verdana.ttf", 60)
    ReallyFuckingBigFont = love.graphics.newFont("Fonts/framdit.ttf", 400)

    BigFont = love.graphics.newFont("Fonts/framdit.ttf", 50)
    MediumFont = love.graphics.newFont("Fonts/framdit.ttf", 25)
    MenuFontBig = love.graphics.newFont("Fonts/verdana.ttf", 30)
    MenuFontSmall = love.graphics.newFont("Fonts/verdana.ttf", 20)
    MenuFontExtraSmall = love.graphics.newFont("Fonts/verdana.ttf", 16)

    DefaultFont = love.graphics.newFont(12)
    State.switch(States.TitleState)


end

function love.update(dt)
    MusicTime = MusicTime + (love.timer.getTime() * 1000) - (previousFrameTime or (love.timer.getTime()*1000))
    previousFrameTime = love.timer.getTime() * 1000

    Input:update()
    State.update(dt)
    Timer.update(dt)



    

    if Input:pressed("setFullscreen") then
        isFullscreen = not isFullscreen
        love.window.setFullscreen(isFullscreen)
    end

    volumeOpacity[1] = volumeOpacity[1] - 1*dt
    volumeVelocity = math.max(0, volumeVelocity-100*dt)
    love.audio.setVolume(volume)
    tweenVolumeDisplay()

    if songSelectSearch then
        searchSongs()
    end
    if usingRPC then
        if State.current() == States.SongSelectState then
            presence = {
                state = "In the Menus",
                details = "Selecting a Song",
                largeImageKey = "rpc_icon"
            }
        elseif State.current() == States.SettingsState then
            presence = {
                state = "In the Menus",
                details = "Editing Settings",
                largeImageKey = "rpc_icon"
            }
        elseif State.current() == States.PlayState then
            total_seconds = songLength - song:tell()
        
            time_minutes  = math.floor(mod(total_seconds, 3600) / 60)
            time_seconds  = math.floor(mod(total_seconds, 60))
            if not resultsScreen then

        
                if (time_minutes < 10) then
                    time_minutes = "0" .. time_minutes
                end
                if (time_seconds < 10) then
                    time_seconds = "0" .. time_seconds
                end
                
            
                presence = {
                    state = "Playing: ".. songList[selectedSong].." Difficulty: ".. metaData.diffName,
                    details = "Time Remaining: " .. time_minutes .. ":" .. time_seconds,
                    largeImageKey = "rpc_icon"
                }
            else

                local rpcGrade = grade

                if health <= 0 then
                    local rpcGrade = "F"
                end

                presence = {
                    state = "Results Screen: ".. songList[selectedSong].." Difficulty: ".. metaData.diffName,
                    details = "Grade: " .. grade,
                    largeImageKey = "rpc_icon"
                }
            end
        end
        --presenceUpdate = presenceUpdate + dt
      --  if presenceUpdate >= 1 then
            discordRPC.updatePresence(presence)
       --     presenceUpdate = 0
       -- end
        discordRPC.runCallbacks()

    end




end

function love.textinput(t)
    if songSelectSearch then
        search = search .. t
    end
end

function love.keypressed(key)
    if key == "backspace" then
        -- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(search, -1)

        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            search = string.sub(search, 1, byteoffset - 1)
        end
    end
end

function tweenVolumeDisplay()
    if volumeTween then
        Timer.cancel(volumeTween)
    end
    volumeTween = Timer.tween(0.2, printableVolume, {love.audio.getVolume()}, "out-back")  --using out-back makes it feel snappier
end

function love.wheelmoved(x,y)

    if love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt") then
        volumeOpacity[1] = 1
        volumeVelocity = math.min(maxVolVelocity, volumeVelocity+2.5)
        if y < 0 then  -- down
            if math.abs(volumeVelocity) < 6 then
                volume = math.max(love.audio.getVolume()+(y*0.01),0)
            else
                volume = math.max(love.audio.getVolume()+(y*0.01)*(volumeVelocity),0)
            end
        else        -- up
            if math.abs(volumeVelocity) < 6 then
                volume = math.min(love.audio.getVolume()+(y*0.01),1)
            else
                volume = math.min(love.audio.getVolume()+(y*0.01)*(volumeVelocity),1)
            end
        end
    elseif curScreen == "songSelect" then
        scrollSongs(y)
    elseif curScreen == "title" then
        scrollTitleButtons(y)
    end
end

function love.draw()
    love.graphics.push()
        love.graphics.setCanvas(GameScreen)
            love.graphics.clear(0,0,0,1)
            State.draw()



        love.graphics.setCanvas()
    love.graphics.pop()

    -- ratio
    local ratio = 1
    ratio = math.min(Inits.WindowWidth/Inits.GameWidth, Inits.WindowHeight/Inits.GameHeight)
    love.graphics.setColor(1,1,1,1)
    -- draw game screen with the calculated ratio and center it on the screen
    love.graphics.draw(GameScreen, Inits.WindowWidth/2, Inits.WindowHeight/2, 0, ratio, ratio, Inits.GameWidth/2, Inits.GameHeight/2)


    debug.printInfo()
    love.graphics.setFont(MenuFontSmall)

    love.graphics.setLineWidth(1)
    love.graphics.push()
    love.graphics.translate(Inits.WindowWidth-200, Inits.WindowHeight-250)
    love.graphics.setColor(1,1,1,volumeOpacity[1])


    love.graphics.scale(0.5,0.5)
    love.graphics.setColor(0,0,0,volumeOpacity[1])
    love.graphics.arc("fill",200,300,100,0, printableVolume[1]*math.pi*2)
    love.graphics.setColor(0,1,1,volumeOpacity[1])
    if printableVolume[1] < 0.98 then
        love.graphics.arc("line",200,300,100,0, printableVolume[1]*math.pi*2)
    else
        love.graphics.circle("line",200,300,100)
    end
    love.graphics.setColor(0,0.8,0.8,volumeOpacity[1])
    love.graphics.pop()



    love.graphics.print(math.ceil(love.audio.getVolume()*100) .. "%",Inits.WindowWidth-200+71,Inits.WindowHeight-250+136)
    love.graphics.setColor(1,1,1)


end

function love.resize(w, h)
    Inits.WindowWidth = w
    Inits.WindowHeight = h
end

function love.quit()
    if usingRPC then
        discordRPC.shutdown()
    end
end