local SongSelectState = State()
local AllDirections = {
    "Left",
    "Down",
    "Up",
    "Right",
}
function SongSelectState:enter()
    curScreen = "songSelect" 
    --selectedSong = randomSong
    menuState = 1
    hangerTilt = {0}
    subMenuYPos = {512}
    subMenuActive = false


    PressToggleString = "Press Tab to Open Mods Menu"

    selectedMod = 2


    printableSelectedSong = {selectedSong} -- used for scrolling song list
    CurPlayingSong = selectedSong
    selectedDifficulty = 1
    printableSelectedDifficulty = {selectedDifficulty} -- used for scrolling diff list 
    SongListXPositions = {}
    SongListXPositions2 = {} -- used for the selectedSong to be slightly further out from the list
    diffListXPositions = {}
    DiffNameList = {}
    subMenuState = "mods"
    subMenuActive = false
    diffList = {}
    diffListAndOtherShitIdfk = love.filesystem.getDirectoryItems("Music/" .. songList[selectedSong] .. "/")
    for i = 1,#diffListAndOtherShitIdfk do 
        local file = diffListAndOtherShitIdfk[i]
        if file:endsWith("qua") then
            table.insert(diffList, file)
        end
    end
    lanes = {}
    for i = 1,4 do
        table.insert(lanes, {})
    end
    search = ""

--[]
    NoteLeft = NoteLeftImage
    NoteDown = NoteDownImage
    NoteUp = NoteUpImage
    NoteRight = NoteRightImage

    ReceptorLeft = ReceptorLeftImage
    ReceptorDown = ReceptorDownImage
    ReceptorUp = ReceptorUpImage
    ReceptorRight = ReceptorRightImage

    disc = love.graphics.newImage("Images/SONGSELECT/disc.png")
    loading = love.graphics.newImage("Images/SONGSELECT/loading.png")
    hanger = love.graphics.newImage("Images/SONGSELECT/clothing hanger.png")
    shift = love.graphics.newImage("Images/SONGSELECT/shift.png")
    tab = love.graphics.newImage("Images/SONGSELECT/tab.png")

    discRotation = 0

    for i = 1,#songList do
        table.insert(SongListXPositions, 900)
        table.insert(SongListXPositions2, 0)
    end

    for i = 1,#diffList do
        table.insert(diffListXPositions, 900)
    end
    if State.last() ~= States.TitleState then
        SongSelectState:loadSong(true)
    else
        SongSelectState:loadSong(false)
        backgroundFade[1] = 1
    end

    for i = 1,#SongListXPositions do
        Timer.tween(0.5, SongListXPositions, {[i] = i*40}, "out-expo")
    end
    
end

function SongSelectState:initializePositionMarkers()
    if #scrollVelocities == 0 then return end

    local position = scrollVelocities[1].startTime * initialScrollVelocity * trackRounding

    table.insert(velocityPositionMakers, position)

    for i = 2, #scrollVelocities do
        local vel = scrollVelocities[i]
        position = position + (vel.startTime - scrollVelocities[i - 1].startTime) * (scrollVelocities[i - 1] and scrollVelocities[i - 1].multiplier or 0) * trackRounding
        table.insert(velocityPositionMakers, position)
    end

    print("AMOUNT OF POSITION MARKERS: " .. #velocityPositionMakers)
end

function SongSelectState:updateCurrentTrackPosition()
    while currentSvIndex <= #scrollVelocities and MusicTime >= scrollVelocities[currentSvIndex].startTime do
        currentSvIndex = currentSvIndex + 1
    end

    currentTrackPosition = self:GetPositionFromTime(MusicTime, currentSvIndex)
end

function SongSelectState:GetPositionFromTime(time, index)
    if Modifiers[5] then return time * trackRounding end
    if index == 1 then return time * initialScrollVelocity * trackRounding end
    local index = index - 1
    local curPos = velocityPositionMakers[index]
    if scrollVelocities[index] then
        curPos = (curPos or 0) + ((time - scrollVelocities[index].startTime) * (scrollVelocities[index].multiplier or 0) * trackRounding)
    else
        curPos = (curPos or 0) + (time * initialScrollVelocity * trackRounding)
    end

    return curPos
end

function SongSelectState:getPositionFromTime(time)
    local _i = 1
    for i = 1, #scrollVelocities do
        if time < scrollVelocities[i].startTime then
            _i = i
            break
        end
    end

    return self:GetPositionFromTime(time, _i)
end

function SongSelectState:initPositions()
    for i = 1, #lanes do
        for q = 1, #lanes[i] do
            lanes[i][q].initialPosition = self:getPositionFromTime(lanes[i][q].time)
        end
    end
end

function SongSelectState:getNotePositions(offset, initialPos, lane)
    return 0 + (((initialPos or 0) - offset) * _G["speed" .. lane] / trackRounding)
end

function SongSelectState:updateNotePosition(offset, curTime)
    local spritePosition = 0

    for i, lane in ipairs(lanes) do
        for k, note in ipairs(lane) do
            spritePosition = self:getNotePositions(offset, note.initialPosition, i)
            note.y = spritePosition
        end
    end
end


function SongSelectState:update(dt)
    MusicTime = MusicTime + (love.timer.getTime() * 1000) - (previousFrameTime or (love.timer.getTime()*1000))
    previousFrameTime = love.timer.getTime() * 1000

    for i = 1, #SongListXPositions2 do
        if i == selectedSong or i == CurPlayingSong then
            SongListXPositions2[i] = math.min(SongListXPositions2[i] + 1000*dt, 200)
        else
            SongListXPositions2[i] = math.max(SongListXPositions2[i] - 1000*dt, 0)
        end
    end

    if State.last() == States.PlayState and not MenuMusic:isPlaying() and not dontFuckingReloadTheSongEveryFrameDumbass then
       -- MenuMusic:stop()
       dontFuckingReloadTheSongEveryFrameDumbass = true
        SongSelectState:loadSong(true)
    end
    self:updateCurrentTrackPosition()
    self:updateNotePosition(currentTrackPosition, MusicTime)
        if not subMenuActive then
            

                if Input:pressed("MenuDown") then
                    tweenSongXPositions()
                    if menuState == 1 then
                        selectedSong = selectedSong+1
                        SongSelectState:loadSong(true)
                    elseif menuState == 2 then
                        selectedDifficulty = selectedDifficulty+1
                        SongSelectState:loadSong(false)
                    end
                --  SongSelectState:loadSong()
                elseif Input:pressed("MenuUp") then
                    tweenSongXPositions()

                    if menuState == 1 then  
                        selectedSong = selectedSong-1
                        SongSelectState:loadSong(true)
                    elseif menuState == 2 then
                        selectedDifficulty = selectedDifficulty-1
                        SongSelectState:loadSong(false)
                    end
                elseif Input:pressed("MenuConfirm") then
                    if CurPlayingSong == selectedSong then
                        if menuState == 1 then
                            menuState = 2
                            selectedDifficulty = 1
                        elseif menuState == 2 then
                            if MenuMusic:isPlaying() then
                                State.switch(States.PlayState)
                            end
                        end
                    else
                        SongSelectState:loadSong(true)
                    end
                elseif Input:pressed("MenuBack") then
                    if menuState == 2 then
                        menuState = 1
                    elseif menuState == 1 then
                        State.switch(States.TitleState)
                    end

                elseif Input:pressed("importSongs") then
                    State.switch(States.QuaverImportScreen)
                elseif Input:pressed("openSongFolder") then
                    os.execute("start " .. love.filesystem.getSaveDirectory() .. "/Music")
                elseif Input:pressed("randomSongKey") then
                    selectedDifficulty = 1
                    selectedSong = love.math.random(1,#songList)
                    SongSelectState:loadSong(true)
                end

        else


            if subMenuState == "mods" then
                if Input:pressed("MenuUp") then
                    selectedMod = selectedMod - 1
                elseif Input:pressed("MenuDown") then
                    selectedMod = selectedMod + 1
                elseif Input:pressed("MenuLeft") then
                    if selectedMod == 2 then
                        Modifiers[selectedMod] = Modifiers[selectedMod] - 0.05
                    end
                elseif Input:pressed("MenuRight") then
                    if selectedMod == 2 then
                        Modifiers[selectedMod] = Modifiers[selectedMod] + 0.05
                    end
                elseif Input:pressed("MenuConfirm") then
                    if type(Modifiers[selectedMod]) == "boolean" then
                        Modifiers[selectedMod] = not Modifiers[selectedMod]
                    elseif type(Modifiers[selectedMod]) == "number" then
                    
                
                    end
                end
            end
        
        end
    if MenuMusic:isPlaying() then
        discRotation = discRotation + 5*dt
    end

    if doDiffListTween then
        for i = 1,#diffListXPositions do
            if i == selectedDifficulty then
                diffListXPositions[i] = math.max(diffListXPositions[i]-500*dt, 800)
            else
                diffListXPositions[i] = math.min(diffListXPositions[i]+500*dt, 900)
            end
        end
    end

    if Input:pressed("menuToggle") then
        subMenuToggleFunction()
    elseif Input:pressed("subMenuToggle") then
        if subMenuActive then
            switchSubMenu()
        end
    end
    

    if songListTween then
        Timer.cancel(songListTween)
    end
    songListTween = Timer.tween(0.2, printableSelectedSong, {selectedSong}, "out-quad")
    if selectedSong < 1 then
        selectedSong = #songList
    elseif selectedSong > #songList then
        selectedSong = 1
    end
    if selectedDifficulty < 1 then
        selectedDifficulty = #diffList
    elseif selectedDifficulty > #diffList then
        selectedDifficulty = 1
    end

    if selectedMod < 2 then
        selectedMod = #Modifiers
    elseif selectedMod > #Modifiers then
        selectedMod = 2
    end

    



end

function subMenuToggleFunction()
    if subMenuActive then
        subMenuActive = not subMenuActive
        Timer.tween(0.25, subMenuYPos, {512}, "out-quad")
    else
        subMenuActive = not subMenuActive
        Timer.tween(0.25, subMenuYPos, {0}, "out-quad")
    end
end

function switchSubMenu()
    if SubMenuTween then
        Timer.cancel(SubMenuTween)
    end
    SubMenuTween = Timer.tween(0.2, subMenuYPos, {1000}, "out-quad", function()
        if subMenuState == "mods" then
        end
        SubMenuTween = Timer.tween(0.2, subMenuYPos, {0}, "out-quad")
    end)
end

function searchSongs()
    print("searchSongs()")
    local searchSongList = love.filesystem.getDirectoryItems("Music")
    songList = {}
    for word in search:gmatch("([^ ]+)") do
        for i, k in ipairs(searchSongList) do
            if k:match(word) then
                table.insert(songList, searchSongList[i])
            end
        end
    end
end

function tweenSongXPositions()

end


function bumpHanger(direction)
    print(direction)
    if hangerTiltTween then
        Timer.cancel(hangerTiltTween)
    end
    if direction then  -- left
        hangerTiltTween = Timer.tween(0.25, hangerTilt, {[1] = -0.5}, "out-back", function()
            Timer.tween(0.25, hangerTilt, {0}, "out-back")
        end)
    else
        hangerTiltTween = Timer.tween(0.25, hangerTilt, {[1] = 0.5}, "out-back", function()
            Timer.tween(0.25, hangerTilt, {0}, "out-back")
        end)
    end
end

function SongSelectState:loadSong(doSongRestart)
    trackRounding = 100
    velocityPositionMakers = {}
    currentTrackPosition = 0
    currentSvIndex = 1
    initialScrollVelocity = 1
    currentScrollVelocity = 1

    doDiffListTween = false

    if doSongRestart then
        selectedDifficulty = 1
    end
    if menuSongTimer then
        Timer.cancel(menuSongTimer)
    end

    menuSongTimer = Timer.after(menuSongDelayTime, function()       -- make a setting
        if doSongRestart then
            MenuMusic:stop()
        end
        local savedDiffPositions = {}
        for i = 1,#diffListXPositions do
            if diffListXPositions[i] ~= 900 then
                table.insert(savedDiffPositions, {diffListXPositions[i], i})
            end
        end
        diffList = {}
        diffListXPositions = {}
    
        diffListAndOtherShitIdfk = love.filesystem.getDirectoryItems("Music/" .. songList[selectedSong] .. "/")
        for i = 1,#diffListAndOtherShitIdfk do 
            local file = diffListAndOtherShitIdfk[i]
            if file:endsWith("qua") then
                table.insert(diffList, file)
            end
        end
        for i = 1,#diffList do
            table.insert(diffListXPositions, 900)
        end
        for i = 1,#savedDiffPositions do
            table.insert(diffListXPositions, savedDiffPositions[i][2], savedDiffPositions[i][1])
        end
        if selectedDifficulty < 1 then
            selectedDifficulty = #diffList
        elseif selectedDifficulty > #diffList then
            selectedDifficulty = 1
        end
        scrollVelocities = {}
        --print("SONG SELECT : " .."Music/" .. songList[selectedSong] .. "/" .. diffList[selectedDifficulty])

        if songList[selectedSong] and diffList[selectedDifficulty] and love.filesystem.getInfo("Music/" .. songList[selectedSong] .. "/" .. diffList[selectedDifficulty], "file") then
            quaverParse("Music/" .. songList[selectedSong] .. "/" .. diffList[selectedDifficulty])
        else
            notification("Chart File Not Found!", notifErrorIcon)
        end
            --[[ print(songList[selectedSong])
        print(diffList[selectedDifficulty]) ]]
        
        trackRounding = 100
        velocityPositionMakers = {}
        currentTrackPosition = 0
        currentSvIndex = 1
        initialScrollVelocity = 1
        currentScrollVelocity = 1
        self:initializePositionMarkers()
        self:updateCurrentTrackPosition()
        self:initPositions()
        self:updateNotePosition(currentTrackPosition, MusicTime)
        
        if doSongRestart then
            MusicTime = metaData.previewTime
            if love.filesystem.getInfo("Music/" .. songList[selectedSong] .. "/" .. metaData.song, "file") then
                MenuMusic = love.audio.newSource("Music/" .. songList[selectedSong] .. "/" .. metaData.song, "stream")
            else
                notification("Audio Not Loaded!", notifErrorIcon)
            end
            MenuMusic:setPitch(Modifiers[2])
            CurPlayingSong = selectedSong



            MusicTime = metaData.previewTime

            MenuMusic:play()
            if metaData.previewTime/1000 > 0 then
                MenuMusic:seek((metaData.previewTime/1000))
            end

        end
        if backgroundFadeTween then Timer.cancel(backgroundFadeTween) end

        backgroundFadeTween = Timer.tween(0.1, backgroundFade, {1}, "linear", function()
            discRotation = 0
         --   if love.filesystem.getInfo("Music/" .. songList[selectedSong] .. "/" .. metaData.background) then
             --   background = love.graphics.newImage("Music/" .. songList[selectedSong] .. "/" .. metaData.background)
          --  end
            if backgroundFadeTween then Timer.cancel(backgroundFadeTween) end
            backgroundFadeTween = Timer.tween(0.1, backgroundFade, {0})
        end)
    end)

  --  for i,diff in ipairs(diffList) do
  --      quaverParse("Music/" .. songList[selectedSong] .. "/" .. diffList[i])
    --    table.insert(DiffNameList, metaData.diffName)
   -- end
   doDiffListTween = true


end

function scrollSongs(y)

    if menuState == 1 then  
        selectedSong = selectedSong - y
        print(y)
        if y < 0 then
            bumpHanger(true)
        else
            bumpHanger(false)
        end
       -- MenuMusic:stop()
       -- SongSelectState:loadSong(true)
    elseif menuState == 2 then
        selectedDifficulty = selectedDifficulty - y
        SongSelectState:loadSong(false)
    end
end

function SongSelectState:draw()

    if background then
        love.graphics.draw(background, 0, 0, nil, Inits.GameWidth/background:getWidth(),Inits.GameHeight/background:getHeight())
    end
    love.graphics.push()
    love.graphics.translate(-565,20)
    for i = 1,4 do
        love.graphics.draw(_G["Receptor" .. AllDirections[i]], Inits.GameWidth/2-(LaneWidth*2)+(LaneWidth*(i-1)), not downScroll and 0 or 385,nil,125/_G["Receptor" .. AllDirections[i]]:getWidth(),125/_G["Receptor" .. AllDirections[i]]:getHeight())
    end

    
    for i, lane in ipairs(lanes) do
        for k, note in ipairs(lane) do
            -- not past 385 or 0
            if (not downscroll and note.y > 0) or (downscroll and note.y < Inits.GameHeight) then
                note:draw()
            end
        end
    end

    love.graphics.pop()

    love.graphics.setColor(0.5,0.5,0.5)
    if banner then
        love.graphics.draw(banner, 0, 0, nil, 500/banner:getWidth(), 97/banner:getHeight())
    end

    love.graphics.push()
    love.graphics.setColor(0.75,0.75,0.75)
    love.graphics.draw(disc, 450, 150, discRotation, 0.08, 0.08,disc:getWidth()/2,disc:getHeight()/2)
    love.graphics.pop()
    love.graphics.setColor(0,0,0,backgroundFade[1])
    love.graphics.rectangle("fill", 0,0,Inits.GameWidth,Inits.GameHeight)
    love.graphics.setColor(1,1,1, backgroundFade[1])
    love.graphics.draw(loading, Inits.GameWidth/2, Inits.GameHeight/2, -discRotation, 0.08, 0.08,loading:getWidth()/2,loading:getHeight()/2)


    love.graphics.setColor(1,1,1,1)
    love.graphics.setFont(MenuFontSmall)
    love.graphics.push()
    if menuState == 1 then
        love.graphics.push()
        love.graphics.translate(-(printableSelectedSong[1]*40)+Inits.GameWidth/2, -(printableSelectedSong[1]*60)+180)

        for i = 1,#songList do
            if i == selectedSong then
                love.graphics.setColor(0,0,0,0.9)
            elseif i ~= selectedSong then
                love.graphics.setColor(1,1,1,0.9)
            end
            if i == CurPlayingSong then
                love.graphics.setColor(1,0,0)
            end

                love.graphics.rectangle("fill", SongListXPositions[i]-SongListXPositions2[i], i*60, 1100, 50, 7, 7, 50)
                love.graphics.setColor(0,0,0,0.9)

                if i == selectedSong then
                    love.graphics.setColor(0,1,1)
                elseif i ~= selectedSong then
                    love.graphics.setColor(0,0.7,0.7)
                end
                if i == CurPlayingSong then
                    love.graphics.setColor(0,1,0)
                end

                love.graphics.rectangle("line", SongListXPositions[i]-SongListXPositions2[i], i*60, 1100, 50, 7, 7, 50)
                love.graphics.setColor(0,1,1)

                if songNamesTable[i] == "This song's data is corrupt! Open at your own risk." then
                    love.graphics.setColor(1,0,0)
                else
                    love.graphics.setColor(0,1,1)
                end
                love.graphics.print(songNamesTable[i], SongListXPositions[i]+12-SongListXPositions2[i], i*60+12)

                if i == #songList and #songList > 10 then
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.draw(hanger, SongListXPositions[i]+10-SongListXPositions2[i], i*60+50, hangerTilt[1], 1, 1, 109, 44)
                    love.graphics.setColor(0,0.2,0.2)
                    love.graphics.circle("fill",SongListXPositions[i]+10-SongListXPositions2[i], i*60+50,5)
                end
        
            love.graphics.setColor(1,1,1)

        end
        love.graphics.setColor(1,1,1)


        love.graphics.pop()
        love.graphics.setColor(0,0,0,0.9)
        love.graphics.setFont(MenuFontExtraBig)
        love.graphics.rectangle("fill", Inits.GameWidth/2-300, 0, 1500, 170, 7, 7, 50)
        love.graphics.setColor(0,1,1)
        love.graphics.rectangle("line", Inits.GameWidth/2-300, 0, 1500, 170, 7, 7, 50)
        love.graphics.print((songNamesTable[CurPlayingSong] or "ERROR- NO SONG PLAYING"), Inits.GameWidth/2-300+20, 15)
        love.graphics.setFont(MenuFontSmall)
        love.graphics.printf("Song: " .. metaData.name.."  Difficulty: " ..metaData.diffName .. "  Artist: " .. metaData.artist .. "   Charter: " .. metaData.creator, Inits.GameWidth/2-300+20, 100, 2000)


    love.graphics.push()
        love.graphics.translate(0, 0+subMenuYPos[1])
        love.graphics.setColor(0,0,0,0.9)
        love.graphics.rectangle("fill",Inits.GameWidth/2-300,370,450,500, 7, 7, 50)
        love.graphics.setColor(0,1,1)
        love.graphics.rectangle("line",Inits.GameWidth/2-300,370,450,500, 7, 7, 50)
        love.graphics.setColor(0,0,0,0.9)

        love.graphics.rectangle("fill", Inits.GameWidth/2-290 ,739, 430, 120, 7, 7, 50)
        love.graphics.setColor(0,1,1)
        love.graphics.rectangle("line", Inits.GameWidth/2-290 , 739, 430, 120, 7, 7, 50)
        love.graphics.printf(ModifiersLabels[selectedMod][2], Inits.GameWidth/2-280, 749, 410, "center")
        love.graphics.printf(PressToggleString, Inits.GameWidth/2-280, 820, 410, "center")


            if subMenuState == "mods" then
                for i = 1,#Modifiers do
                    if i == selectedMod then
                        love.graphics.setColor(0,0,0,0.9)
                        love.graphics.rectangle("fill", Inits.GameWidth/2-290 ,440+40*i-95, 430, 30, 7, 7, 50)
                        love.graphics.setColor(0,1,1)
                        love.graphics.rectangle("line", Inits.GameWidth/2-290 ,440+40*i-95, 430, 30, 7, 7, 50)
                        love.graphics.setColor(1,1,1,1)
                        love.graphics.print(ModifiersLabels[i][1] .. ": " .. tostring(Modifiers[i]), Inits.GameWidth/2-280, 440+40*i-95)
                    else



                        love.graphics.setColor(1,1,1,0.9)
                        love.graphics.rectangle("fill", Inits.GameWidth/2-290 ,440+40*i-95, 430, 30, 7, 7, 50)
                        love.graphics.setColor(0,0.8,0.8)
                        love.graphics.rectangle("line", Inits.GameWidth/2-290 ,440+40*i-95, 430, 30, 7, 7, 50)
                        love.graphics.setColor(0,0,0,1)
                        if i ~= 1 then
                            love.graphics.print(ModifiersLabels[i][1] .. ": " .. tostring(Modifiers[i]), Inits.GameWidth/2-280, 440+40*i-95)
                        else
                            love.graphics.print("Modifiers Menu", Inits.GameWidth/2-280, 440+40*i-95)

                            love.graphics.setColor(1,1,1)
                            if not subMenuActive then
                                love.graphics.draw(tab, Inits.GameWidth/2+80, 440+40*i-95)
                            else
                                love.graphics.draw(shift, Inits.GameWidth/2+80, 440+40*i-95)
                            end
                        end
                    end

                end
            end
        love.graphics.pop()




    elseif menuState == 2 then
        love.graphics.push()
        love.graphics.translate(0, -(selectedDifficulty*60)+Inits.GameHeight/2)

        for i = 1,#diffList do
            if i == selectedDifficulty then
                love.graphics.setColor(0,0,0,0.9)
                love.graphics.rectangle("fill", diffListXPositions[i], i*60, 1000, 50, 7, 7, 50)
                love.graphics.setColor(0,1,1)

                love.graphics.rectangle("line", diffListXPositions[i], i*60, 1000, 50, 7, 7, 50)
                love.graphics.print(diffList[i], diffListXPositions[i]+12, i*60+12)
            else
                love.graphics.setColor(1,1,1,0.9)
                love.graphics.rectangle("fill", diffListXPositions[i], i*60, 1000, 50, 7, 7, 50)
                love.graphics.setColor(0,0.8,0.8)

                love.graphics.rectangle("line", diffListXPositions[i], i*60, 1000, 50, 7, 7, 50)
                love.graphics.print(diffList[i], diffListXPositions[i]+12, i*60+12)
            end
        end
        love.graphics.pop()

    end
    love.graphics.pop()

    love.graphics.push()
    love.graphics.setColor(0,0,0,0.9)
    love.graphics.rectangle("fill", 0, Inits.GameHeight-140, 320, 140, 7, 7, 50)
    love.graphics.setColor(0,1,1)
    love.graphics.rectangle("line", 0, Inits.GameHeight-140, 320, 140, 7, 7, 50)
    love.graphics.setFont(MenuFontExtraSmall)
    love.graphics.printf(#songList.." Songs Found\n\nPress F1 to import songs from Quaver\n\nPress F2 to open Music Folder", 10, Inits.GameHeight-130, 310, "left")
   -- love.graphics.scale(0.5,0.5)
   love.graphics.setColor(1,1,1)
    love.graphics.pop()

end

return SongSelectState