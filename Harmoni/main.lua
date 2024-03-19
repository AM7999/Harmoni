 
versionNumber = "Harmoni Beta 2.0"

local utf8 = require("utf8")
moonshine = require("Libraries.moonshine")
Inits = require("inits")
require("Libraries.lovefs.lovefs")

local function error_printer(msg, layer)
	print((debug.traceback("Looks like Harmoni crashed \n(not very surprising)\nPlease send a screenshot of this in the Harmoni Discord Server\ndiscord.gg/bBcjrRAeh4" .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end
    Modifiers = {
        false,
        1, -- speed
        false,  -- sudden death
        false, -- lane swap
        false, -- no scroll velocities
        false, -- no fail
        false, -- botplay
        false, -- randomize
        false, -- no hold notes
    }


ModifiersLabels = {
    {"Modifiers Menu", "this string will never be seen lmao", "this string will also never be seen lmao"},
    {"Song Speed", "How fast the song plays", "SS"},
    {"Sudden Death", "You die if you miss a single note", "SD"},
    {"Lane Swap", "Left becomes right, up becomes down", "LS"},
    {"No Scroll Velocities", "Disables Scroll Velocities", "NSV"},
    {"No Fail", "Don't die when you run out of health", "NF"},
    {"Bot Play", "Watch a perfect playthourgh of the song", "BP"},
    {"Randomize", "Randomize the lanes - NOT ADDED YET", "R"},
    {"No Hold Notes", "Remove all the icky disgusting awful fucking hold notes I HATE HOLD NOTES!!!!!!!!!!!!!!!!!", "NHN"}
}

disablePrint = false


--[[
function ❓(num)
    return "This Number is " .. num
end
--]]




function recursivelyDelete( item )
    if love.filesystem.getInfo( item , "directory" ) then
        for _, child in ipairs( love.filesystem.getDirectoryItems( item )) do
            recursivelyDelete( item .. '/' .. child )
            love.filesystem.remove( item .. '/' .. child )
        end
    elseif love.filesystem.getInfo( item ) then
        love.filesystem.remove( item )
    end
    love.filesystem.remove( item )
end

function love.errorhandler(msg)
	msg = tostring(msg)

	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end

	love.graphics.reset()
	local font = love.graphics.setNewFont(14)

	love.graphics.setColor(1, 1, 1)

	local trace = debug.traceback()

	love.graphics.origin()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}

	table.insert(err, "Looks like Harmoni crashed \n\n(not very surprising)\n\nPlease send a screenshot of this in the Harmoni Discord Server\n\ndiscord.gg/bBcjrRAeh4\n\n\n\n\n\n\n\n\n\n")
	table.insert(err, sanitizedmsg)

	if #sanitizedmsg ~= #msg then
		table.insert(err, "\nInvalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 70
		love.graphics.clear(89/255, 157/255, 220/255)
		love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
		love.graphics.present()
	end

	local fullErrorText = p
	local function copyToClipboard()
		if not love.system then return end
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
	end

	if love.system then
		p = p .. "\n\nPress Ctrl+C or tap to copy this error"
	end

	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				copyToClipboard()
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel"}
				if love.system then
					buttons[3] = "Copy to clipboard"
				end
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					copyToClipboard()
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.1)
		end
	end

end



if love.filesystem.isFused() then
    function print() return end
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
love.filesystem.createDirectory("Screenshots")


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
            MenuLeft = { "key:left", },
            MenuRight = { "key:right", },
            MenuConfirm = { "key:return" },

            setFullscreen = { "key:f11" },
            MenuBack = { "key:escape", "key:backspace" },
            menuToggle = { "key:tab"},
            subMenuToggle = { "key:rshift", "key:lshift", },
            importSongs = { "key:f1" },
            openSongFolder = { "key:f2" },
            randomSongKey = { "key:r" },
            introSkip = { "key:space" },
            takeScreenshot = { "key:f3" },
        }
    })
    Class = require("Libraries.Class")
    State = require("Libraries.State")
    Ini = require("Libraries.ini")
    tinyyaml = require("Libraries.tinyyaml")

    Timer = require("Libraries.Timer")

    GameScreen = love.graphics.newCanvas(Inits.GameWidth, Inits.GameHeight)

    -- Initialize Game
    States = require("Modules.States")
    --loadSettings()
    Objects = require("Modules.Objects")
    String = require("Modules.String")
    Table = require("Modules.Table")
    ChartParse = require("Modules.ChartParse")
    Settings = require("Modules.Settings")
    Settings.loadSettings()

    notificationsTable = {}
 


    require("Modules.Debug")

    volumeOpacity = {0}
    volumeVelocity = 0
    printableVolume = {love.audio.getVolume()}
    maxVolVelocity = 25
    MusicTime = 0


    testTipImage = love.graphics.newImage("Images/unused/testImage.png")
    kofiImage = love.graphics.newImage("Images/TITLE/kofi.png")
    discordImage = love.graphics.newImage("Images/TITLE/discord.png")
    hengImage = love.graphics.newImage("Images/TITLE/heng.png")





    --notificationImages 
    notifErrorIcon = love.graphics.newImage("Images/SHARED/Error Icon.png")
    notifInfoIcon = love.graphics.newImage("Images/SHARED/Info Icon.png")
    notifGeneralIcon = love.graphics.newImage("Images/unused/Note.png")



    --[[


    ]]
    Tips = {
        "Press F11 to Fullscreen",
        "Please report any bugs you find by opening a Github issue or reporting it in the Harmoni Discord server",
        "Press R in the Song Select menu to pick a random song", 
        "Request features by opening a Github issue or asking about it in the Harmoni Discord server",
        "Don't miss",
        "Wishlist Rit on Steam!",
        "Hold ALT and scroll to change the volume",
        "More Song Packs will be available in the future",
        "To import your own songs from Quaver, just export the song in Quaver, extract it, and place it in Harmoni's Music Folder.",
        "Press F2 in the Song Select menu to visit the song packs Google Drive",
        "Press F3 to take a screenshot",
        {"Please consider donating to help development", kofiImage},
        {"Harmoni Discord Server\ndiscord.gg/bBcjrRAeh4", discordImage},

    }
    
    extremeRareTips = {
        "you should just delete the game honestly",
        "still better than osu",
        "\"did you know that in heat colors change to another color dont believe me stick your fingers up your ass\"\n-Sapple",
        "just play quaver lmao",
        "pickles",
        "\"The best part of fucking Yoshi is that you have a ride home in the morning\"\n-President Barack Obama",
        {"Is an interesting game  ◦ \nAm just play it\nWow\n\n-Heng", hengImage},
        "Do it jiggle?",
        "\"Is good game, would give it a try\"\n\n-Sapple",
        "When she doin' acrobatics on the peenor, so you gotta lock in",
        "We harmomize the entire house without a single drop of cheese falling\n\ncry about it guglio",
        "\"not gonna lie this game is just trying to copy osu!mania, don't deserve my time\"\n-The guy on Steam", 
    }


    ExtraBigFont = love.graphics.newFont("Fonts/Dosis-Medium.ttf", 60)
    ReallyFuckingBigFont = love.graphics.newFont("Fonts/PolandCanIntoGlassMakingsItalic-Mmae.otf", 400)

    BigFont = love.graphics.newFont("Fonts/PolandCanIntoGlassMakingsItalic-Mmae.otf", 50)
    MediumFont = love.graphics.newFont("Fonts/PolandCanIntoGlassMakingsItalic-Mmae.otf", 50)
    MediumFontSolid = love.graphics.newFont("Fonts/PolandCanIntoBigWritings-18wL.otf", 25)
    MediumFontBacking = love.graphics.newFont("Fonts/PolandCanIntoBigWritingsItalic-ReVM.otf", 50)
    MenuFontBig = love.graphics.newFont("Fonts/Dosis-Medium.ttf", 30)
    MenuFontSmall = love.graphics.newFont("Fonts/Dosis-Medium.ttf", 20)
    MenuFontExtraSmall = love.graphics.newFont("Fonts/Dosis-Medium.ttf", 16)
    NotificationFont = love.graphics.newFont("Fonts/Dosis-Medium.ttf", 14)
    MenuFontExtraBig = love.graphics.newFont("Fonts/Dosis-Medium.ttf", 50)



    DefaultFont = love.graphics.newFont(12)
    State.switch(States.PreLaunchState)


    clearNotifs()

end

function love.update(dt)

    deltaTime = dt
    MusicTime = MusicTime + (love.timer.getTime() * 1000) - (previousFrameTime or (love.timer.getTime()*1000))
    previousFrameTime = love.timer.getTime() * 1000

    Input:update()
    State.update(dt)
    Timer.update(dt)

    if Input:pressed("setFullscreen") then
        isFullscreen = not isFullscreen
        love.window.setFullscreen(isFullscreen)
    end

    if Input:pressed("takeScreenshot") then
        takeScreenshot()
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

function takeScreenshot()
    love.graphics.captureScreenshot(function(q)
        screenshot = love.graphics.newImage(q)
        q:encode('png','Screenshots/' .. os.time() .. '.png')
        screenshotSize = {1}
        screenshotTranslate = {0}
        screenshotSizeTween = Timer.tween(0.5, screenshotSize, {0.2}, "out-quad", function()
            Timer.tween(0.7, screenshotTranslate, {screenshot:getWidth()*(screenshotSize[1]+10)}, "in-expo", function()
                notification("Screenshot Saved", notifInfoIcon)
            end)
        end)

    end)

end

function love.textinput(t)
    if songSelectSearch then
        search = search .. t
    end
end

function love.keypressed(key)
    if key == "backspace" then

        --notification(tostring(Tips[love.math.random(1,#Tips)]), notifGeneralIcon)
        --[[
        -- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(search, -1)

        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            search = string.sub(search, 1, byteoffset - 1)
        end

        --]]

    end
end

function tweenVolumeDisplay()
    if volumeTween then
        Timer.cancel(volumeTween)
    end
    volumeTween = Timer.tween(0.2, printableVolume, {love.audio.getVolume()}, "out-back")  --using out-back makes it feel snappier
end


function notification(contents, icon)
    notifContents = (contents or "Error- No Notification Text")
    notifIcon = (icon or notifGeneralIcon)
    table.insert(notificationsTable, 1, {notifContents, notifIcon, 1})
    if #notificationsTable == 1 then
        clearNotifs(true)
    end
end

function clearNotifs(restart)
    if restart then
        if notifTimer then
            Timer.cancel(notifTimer)
        end
    end
    notifTimer = Timer.after(3, function()
        table.remove(notificationsTable, #notificationsTable)
        clearNotifs()
    end)
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
    if screenshot then
        love.graphics.push()
        love.graphics.scale(screenshotSize[1], screenshotSize[1])
        love.graphics.translate(0 - screenshotTranslate[1], 0)
        love.graphics.draw(screenshot, ratio, ratio)
        love.graphics.pop()
    end

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
    if printableVolume[1] < 0.99 then
        love.graphics.arc("line",200,300,100,0, printableVolume[1]*math.pi*2)
    else
        love.graphics.circle("line",200,300,100)
    end
    love.graphics.setColor(0,0.8,0.8,volumeOpacity[1])
    love.graphics.pop()



    love.graphics.print(math.ceil(love.audio.getVolume()*100) .. "%",Inits.WindowWidth-200+71,Inits.WindowHeight-250+136)
    love.graphics.setColor(1,1,1)
    love.graphics.push()
    love.graphics.translate(0, -50)
    love.graphics.setFont(NotificationFont)

    for i = 1,#notificationsTable do
        love.graphics.setColor(0,0,0,0.6)
        love.graphics.rectangle("fill", Inits.WindowWidth-405, i*55, 400, 50)
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(notificationsTable[i][2], Inits.WindowWidth-(notificationsTable[i][2]:getWidth()-70), i*55, nil, 50/notificationsTable[i][2]:getWidth(), 50/notificationsTable[i][2]:getHeight())
        love.graphics.print(notificationsTable[i][1], Inits.WindowWidth-405+25/2, (i*55+28/2))
        love.graphics.setColor(0,1,1,1)

        love.graphics.rectangle("line", Inits.WindowWidth-405, i*55, 400, 50)
    end
    love.graphics.setColor(1,1,1,1)

    love.graphics.pop()


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
