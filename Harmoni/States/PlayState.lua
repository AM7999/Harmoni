local PlayState = State()

local allInputs = {
    "GameLeft",
    "GameDown",
    "GameUp",
    "GameRight",
}
local AllDirections = {
    "Left",
    "Down",
    "Up",
    "Right",
}

function PlayState:enter()
    --load assets     why did you even put this comment you literally just set random variabls here lmfao not assets loading
    hitTimes = {}
    curScreen = "play"

    lanes = {}
    for i = 1, 4 do
        table.insert(lanes, {})
    end
    scrollVelocities = {}
    trackRounding = 100
    velocityPositionMakers = {}
    currentTrackPosition = 0
    currentSvIndex = 1
    initialScrollVelocity = 1

    MusicTime = -2000

    if MenuMusic then
        MenuMusic:stop()
    end

    local ok = quaverParse("Music/" .. songList[selectedSong] .. "/" .. diffList[selectedDifficulty])
    if not ok then State.switch(States.SongSelectState) return end

    self:initializePositionMarkers()
    self:updateCurrentTrackPosition()
    self:initPositions()
    self:updateNotePosition(currentTrackPosition, MusicTime)

    bpmIsInit = false

    
    ReceptorLeft = ReceptorLeftImage
    ReceptorDown = ReceptorDownImage
    ReceptorUp = ReceptorUpImage
    ReceptorRight = ReceptorRightImage
    ReceptorLeftPressed = ReceptorPressedLeftImage
    ReceptorDownPressed = ReceptorPressedDownImage
    ReceptorUpPressed = ReceptorPressedUpImage
    ReceptorRightPressed = ReceptorPressedRightImage
    NoteLeft = NoteLeftImage
    NoteDown = NoteDownImage
    NoteUp = NoteUpImage
    NoteRight = NoteRightImage
    NoteLeftTrail = NoteLeftTrailImage
    NoteDownTrail = NoteDownTrailImage
    NoteUpTrail = NoteUpTrailImage
    NoteRightTrail = NoteRightTrailImage
    Marvelous = MarvelousImage
    Perfect = PerfectImage
    Great = GreatImage
    Good = GoodImage
    Okay = OkayImage
    Miss = MissImage

    
    marvTiming = 26
    perfTiming = 56
    greatTiming = 86
    goodTiming = 106
    okayTiming = 126
    missTiming = 146

    marvCount = 0
    perfCount = 0
    greatCount = 0
    goodCount = 0
    okayCount = 0
    missCount = 0
    judgeCounterXPos = {0,0,0,0,0,0}

    --set variables
    MusicTime = -10000

    beatBump = {0}
    health = 1
    comboAlertPosition = {Inits.GameWidth,Inits.GameHeight/2,1}
    paused = false
    judgeColors = {0,0,0,0,0,0}
    judgePos = {0}
    gameOverNotePush = {1}
    gameOver = false
    gameOverSongSlowdown = {1}
    backgroundDim = {0}
    backgroundBlur = {0}
    comboSize = {1}
    score = 0
    accuracy = 0
    currentScrollVelocity = 1
    currentBestPossibleScore = 0
    combo = 0
    printableScore = {score}
    printableHealth = {health}
    convertedAccuracy = 0
    songInfoAlpha = 1
    printableAccuracy = {accuracy}
    noteScale = 1
    grade = ""
    hitsPerSecond = {0}
    notesPerSecond = {0}
    hitErrorTable = {}
    dimBackground()

    if skinLoad then
        skinLoad()
    end


        BotPlay = Modifiers[7]
    

    if Gameplay[5][2] then
        BotPlay = true
    end
    blurEffect = moonshine(moonshine.effects.boxblur)
    blurEffect.boxblur.radius = 0

    
    song:setPitch(Modifiers[2])

    for i = 1,#lanes do
        for q = 1,#lanes[i] do
            lanes[i][q].time = lanes[i][q].time / Modifiers[2]
        end
    end

end

function PlayState:initializePositionMarkers()
    if #scrollVelocities == 0 then return end

    local position = scrollVelocities[1].startTime * initialScrollVelocity * trackRounding
    table.insert(velocityPositionMakers, position)

    for i = 2, #scrollVelocities do
        position = position + ((scrollVelocities[i].startTime - scrollVelocities[i - 1].startTime) * (scrollVelocities[i - 1].multiplier or 0) * trackRounding)
        table.insert(velocityPositionMakers, position)
    end
end

function PlayState:updateCurrentTrackPosition()
    while currentSvIndex <= #scrollVelocities and MusicTime >= scrollVelocities[currentSvIndex].startTime do
        currentSvIndex = currentSvIndex + 1
    end

    currentTrackPosition = self:GetPositionFromTime(MusicTime, currentSvIndex)
end

function PlayState:GetPositionFromTime(time, index)
    if Modifiers[5] then return time * trackRounding end
    if index == 1 then return time * initialScrollVelocity * trackRounding end
    local index = index - 1
    local curPos = velocityPositionMakers[index]
    curPos = curPos + ((time - scrollVelocities[index].startTime) * (scrollVelocities[index].multiplier or 0) * trackRounding)

    return curPos
end

function PlayState:getPositionFromTime(time)
    local _i = 1
    for i = 1, #scrollVelocities do
        if time < scrollVelocities[i].startTime then
            _i = i
            break
        end
    end

    return self:GetPositionFromTime(time, _i)
end

function PlayState:initPositions()
    for i = 1, #lanes do
        for q = 1, #lanes[i] do
            lanes[i][q].initialPosition = self:getPositionFromTime(lanes[i][q].time)
            if lanes[i][q].endTime then
                lanes[i][q].endTrackPosition = self:getPositionFromTime(lanes[i][q].endTime)
            end
        end
    end
end

function PlayState:getNotePositions(offset, initialPos, lane)
    return 0 + (((initialPos or 0) - offset) * _G["speed" .. lane] / trackRounding)
end

function PlayState:updateNotePosition(offset, curTime)
    local spritePosition = 0

    for i, lane in ipairs(lanes) do
        for k, note in ipairs(lane) do
            spritePosition = self:getNotePositions(offset, note.initialPosition, i)
            if not note.moveWithScroll then spritePosition = 0 end
            note.y = spritePosition

            if #note.children > 0 then
                note.children[1].y = spritePosition
                note.endY = self:getNotePositions(offset, note.endTrackPosition, i)
                local pixelDistance = note.endY - note.y
                note.children[1].scaleY = pixelDistance
                if note.children[2] then
                    note.children[2].y = spritePosition
                end
            end
        end
    end
end

function PlayState:doNoteHit(note)
    if not note.wasGoodHit then
        note.wasGoodHit = true
        judge(MusicTime - note.time)
        table.insert(notesPerSecond, 1)
        if #note.children > 0 then
            note.moveWithScroll = false
        else
            note.visible = false
            table.remove(lanes[note.lane], 1)
        end
    end
end

function PlayState:keyPressed(key) -- key is the lane
    if paused then return end

    local lane = lanes[key]

    for i, note in ipairs(lane) do
        if MusicTime - note.time < missTiming and MusicTime - note.time > -missTiming and not note.wasGoodHit then
            self:doNoteHit(note)
            break
        end
    end
end

function PlayState:keyDown(key) 
    if paused then return end

    local lane = lanes[key]

    for i, note in ipairs(lane) do
        if note.endTime - MusicTime <= -15 and not note.moveWithScroll then -- hold note that is currently being pressed
            table.remove(lane, i)
            break
        end
    end
end

function PlayState:keyReleased(key) 
    if paused then return end

    local lane = lanes[key]

    for i, note in ipairs(lane) do
        if not note.moveWithScroll then -- hold was unpressed
            if note.endTime - MusicTime > greatTiming then
                missCount = missCount + 1
                combo = 0
                print("Trail released")
                judge(note.endTime - MusicTime)
            end
            table.remove(lane, i)
        end
    end
end

function PlayState:update(dt)
    blurEffect.boxblur.radius = backgroundBlur[1]

    if paused or gameOver then
        MusicTime = PausedMusicTime
    end

    if MusicTime > -1000 then
        songInfoAlpha = songInfoAlpha - (1*dt)
    end

    if BotPlay then
        checkBotInput()
    end

    for i = 1, #allInputs do
        if Input:pressed(allInputs[i]) then
            self:keyPressed(i)
        end
        if Input:down(allInputs[i]) then
            self:keyDown(i)
        end
        if Input:released(allInputs[i]) then
            self:keyReleased(i)
        end
    end

    checkMiss()

    if MusicTime >= 0 and not song:isPlaying() and MusicTime < 1000 --[[ to make sure it doesnt restart --]] then
        song:play()
    
    end

    self:updateCurrentTrackPosition()
    self:updateNotePosition(currentTrackPosition, MusicTime)


    if printableHealth[1] < 0 then
        printableHealth[1] = 0
    end

    if (#lanes[1]+#lanes[2]+#lanes[3]+#lanes[4] == 0) or gameOver and MusicTime > 1 and not paused then
        resultsScreen = true
        if Input:pressed("MenuConfirm") then
            resultsScreen = false
            saveList = love.filesystem.getDirectoryItems("Saves/" .. songList[selectedSong] .. "/" .. diffList[selectedDifficulty] .."/")
            local saveData = "local ScoreData = {Score = ".. score .. "Accuracy = " .. accuracy .. "}"
            love.filesystem.write("Saves/" .. songList[selectedSong] .. "/" .. diffList[selectedDifficulty] .."/" .. #saveList .. ".lua", "test")
            PlayState:leave(States.SongSelectState)
        end
    end   
    
    if printableHealth[1] <= 0 and not gameOver and not Modifiers[6] then            
        PlayState:gameOver()
    end
    if Modifiers[3] and missCount > 1 and not gameOver and not Modifiers[6] then
        PlayState:gameOver()
    end
    if gameOverSongSlowdown[1] ~= 1 then

        song:setPitch(gameOverSongSlowdown[1])
        print(gameOverSongSlowdown[1])
    end
    PlayState:doGradeShitIdk()
    if skinUpdate then
        skinUpdate(dt)
    end

    if not instantPause then
        if Input:down("GameBack") and not paused and MusicTime > 1000 then
            if not songLeave then
                songLeave = 0
            end
            songLeave = songLeave + dt
            if songLeave >= 0.3 then
                pause()
                pauseSelection = 1
            end
        else
            songLeave = 0
        end
    else
        if Input:pressed("GameBack") and MusicTime > 1000 then
            pause()
            pauseSelection = 1

        end
    end

        if math.floor(MusicTime/1000) < firstNoteTime - 3 and firstNoteTime > 5 and MusicTime > 1 then
            canBeSkipped = true
            if Input:pressed("introSkip") then
                song:seek(firstNoteTime - 2)
                MusicTime = (firstNoteTime * 1000) - 2000
            end
        else
            canBeSkipped = false
        end
    


    if health > 0.90 then
        health = health - 0.3*dt
    end

    if healthTween then
        Timer.cancel(healthTween)
    end
    if not paused then
        healthTween = Timer.tween(0.5, printableHealth, {health}, "out-quad")
    end


    for i = 1,#hitTimes do
        hitTimes[i][4][4] = hitTimes[i][4][4]-(1*dt)
    end

    PlayState:doBPMshit()

end

function PlayState:doBPMshit()
    if not bpmIsInit then
        bpmIsInit = true
        BpmTimerStartTime = nil
        nextBeat = nil
    end
    for i = 1, #timingPointsTable do
        if timingPointsTable[i][1] then
            if MusicTime >= timingPointsTable[i][1] then
                currentBpm = timingPointsTable[i][2]
                --print("BPM change: " .. currentBpm)
                table.remove(timingPointsTable, i)
                break
            end
        else
            if currentBpm ~= metaData.bpm then
                currentBpm = metaData.bpm
                --notification("BPM Not Found", notifErrorIcon)
            end
        end
    end
    if not BpmTimerStartTime and MusicTime > 0 then
        BpmTimerStartTime = MusicTime
        nextBeat = BpmTimerStartTime + (60000/currentBpm)
        --print("First BpmTimerStartTime: " .. BpmTimerStartTime)
    end
    if nextBeat and MusicTime >= nextBeat then
        PlayState:beat()
        BpmTimerStartTime = MusicTime
        nextBeat = BpmTimerStartTime + (60000/currentBpm)
    end
end

function PlayState:beat()

    if combo < 500 then
        beatBump = {(combo/7500)/2}
    else
        beatBump = {(500/7500)/2} --   
    end



    if beatBumpTimer then
        Timer.cancel(beatBumpTimer)
    end
    beatBumpTimer = Timer.tween((60000/currentBpm)/1000, beatBump, {0}, "out-quad") -- lmfao why does bounce look genuinely better   yeah lmao i changed my mind about using a bounce tween
end



function PlayState:doGradeShitIdk()
    if convertedAccuracy == 100 then 
        grade = "X"
        gradeColors = {}
    elseif convertedAccuracy > 95 then
        grade = "S"
        gradeColors = {}
    elseif convertedAccuracy > 90 then
        grade = "A"
        gradeColors = {}
    elseif convertedAccuracy > 80 then
        grade = "B"
        gradeColors = {}
    elseif convertedAccuracy > 70 then
        grade = "C"
        gradeColors = {}
    else 
        grade = "D"
        gradeColors = {}
    end
end
 
function pause()
    if not resultsScreen and MusicTime > 1 then
        paused = not paused
        PausedMusicTime = MusicTime
        if paused then
            song:pause()

            if healthTween then
                Timer.cancel(healthTween)
            end
        else
            healthTween = Timer.tween(0.5, printableHealth, {health}, "out-quad")

            song:play()
        end
    end
end

function PlayState:gameOver()
    PausedMusicTime = MusicTime
    paused = true
    if gameOverSongSlowdown[1] == 1 then
        --song:setPitch(-1)
        gameOverNotePush = {0}
        gameOverTween = Timer.tween(1.5, gameOverNotePush, {Inits.GameHeight/2}, "out-elastic")
        gameOverSongTween = Timer.tween(1.5, gameOverSongSlowdown, {0.01}, "linear", function()
            song:stop()
            paused = false
            grade = "F"
            gameOver = true
        end)
    end
end

function PlayState:leave(state)
    --song = nil
    background = nil
    State.switch(state)
    resultsScreenTranslate = nil
    resultsScreenTween = nil
end


function checkMiss()
    for i, lane in ipairs(lanes) do
        for j, note in ipairs(lane) do
            if MusicTime - note.time > missTiming and not note.wasGoodHit then
                judge(MusicTime - note.time)
                table.remove(lane, j)
                health = health - 0.075
                break
            end
        end
    end
end

function incrementCombo()
    combo = combo + 1
    if combo % 100 == 0 then
        comboAlertFunction(combo)
    end
    if comboTween then
        Timer.cancel(comboTween)
    end
    comboSize = {1.5}
    comboTween = Timer.tween(0.5, comboSize, {1}, "out-quad")
end

function comboAlertFunction(comboAlertNum)
    comboAlert = tostring(comboAlertNum) .. " Combo!"
    if comboAlertNum > 500 then
        comboAlert = tostring(comboAlertNum) .. " Combo!!"
    end
    comboAlertPosition = {Inits.GameWidth,Inits.GameHeight/2,1}
    Timer.tween(0.5, comboAlertPosition, {[1] = comboAlertPosition[1]-400}, "out-quad", function()
        Timer.tween(0.2, comboAlertPosition, {[2] = comboAlertPosition[2]+35, [3] = 0}, "out-expo")
    end)
end

function judge(noteTime)
    
    if math.abs(noteTime) < marvTiming then  -- marvelous
        table.insert(hitTimes, {noteTime, MusicTime, 1, {1,1,1,1}})
        score = score + (bestScorePerNote*(6/6))
        judgeColors = {1,0,0,0,0,0}
        marvCount = marvCount + 1
        judgeCountTween(1)
        incrementCombo()
        health = math.min(health + 0.025, 1)
    elseif math.abs(noteTime) < perfTiming then  -- perfect
        table.insert(hitTimes, {noteTime, MusicTime, 1, {1,1,78/255,1}})
        score = score + (bestScorePerNote*(5/6))
        judgeColors = {0,1,0,0,0,0}
        judgeCountTween(2)
        incrementCombo()
        perfCount = perfCount + 1
        health = math.min(health + 0.02, 1)
    elseif math.abs(noteTime) < greatTiming then  -- great
        table.insert(hitTimes, {noteTime, MusicTime, 1, {92/255,1,82/255,1}})
        score = score + (bestScorePerNote*(4/6))
        greatCount = greatCount + 1
        judgeColors = {0,0,1,0,0,0}
        judgeCountTween(3)
        incrementCombo()
        health = health - 0.01
    elseif math.abs(noteTime) < goodTiming then  -- good
        table.insert(hitTimes, {noteTime, MusicTime, 1, {0,61/255,1,1}})
        score = score + (bestScorePerNote*(3/6))
        judgeColors = {0,0,0,1,0,0}
        judgeCountTween(4)
        incrementCombo()
        goodCount = goodCount + 1
        health = health - 0.02
    elseif math.abs(noteTime) < okayTiming then  -- okay
        table.insert(hitTimes, {noteTime, MusicTime, 1, {129/255,0,1,1}})
        score = score + (bestScorePerNote*(2/6))
        judgeColors = {0,0,0,0,1,0}
        judgeCountTween(5)
        incrementCombo()
        okayCount = okayCount + 1
        health = health - 0.04
    else                        -- miss lmao fuckin loser
        table.insert(hitTimes, {noteTime, MusicTime, 1, {1,65/255,65/255,1}})
        judgeColors = {0,0,0,0,0,1}
        judgeCountTween(6)
        missCount = missCount + 1
        randomMissAngle = love.math.random(-25,25)
        combo = 0
        health = health - 0.075
    end

    currentBestPossibleScore = currentBestPossibleScore + bestScorePerNote
    accuracy = score/currentBestPossibleScore
    convertedAccuracy = accuracy*100

    printableScoreTween()

    if judgeTween then
        Timer.cancel(judgeTween)
    end
    judgePos = {0.5,0.5,0, 0}
    curBPMJudgeBump = ((60000/currentBpm)/1000)/2

    judgeTween = Timer.after(0, function() 

        Timer.tween(curBPMJudgeBump, judgePos, {[1] = 1}, "out-quad")
        Timer.tween(curBPMJudgeBump, judgePos, {[2] = 1}, "out-back")
        Timer.tween(0.05, judgePos, {[4] = -15}, "out-quad", function()
            Timer.tween(0.05, judgePos, {[4] = 0}, "in-quad")
        end)

    end)


end

function judgeCountTween(index)
    if _G["judgeCountTween" .. index] then
        Timer.cancel(_G["judgeCountTween" .. index])
    end
    judgeCounterXPos[index] = 10
    _G["judgeCountTween" .. index] = Timer.tween(0.5,judgeCounterXPos,{[index] = 0},"out-quad")
end
function printableScoreTween()
    if scoreTween then
        Timer.cancel(scoreTween)
        Timer.cancel(accuracyTween)
      --  Timer.cancel(healthTween)
    end
    scoreTween = Timer.tween(0.5, printableScore, {score}, "out-quad")
    accuracyTween = Timer.tween(0.5, printableAccuracy, {convertedAccuracy}, "out-quad")
  --  healthTween = Timer.tween(0.5, printableHealth, {health}, "out-quad")
end

function dimBackground()
    Timer.tween(1.5, backgroundBlur, {backgroundBlurSetting})
    Timer.tween(1.5, backgroundDim, {backgroundDimSetting}, "linear", function()
        MusicTime = -2000
    end)
end

--[[ function checkInput()
    for i, lane in ipairs(lanes) do
        for j, note in ipairs(lane) do
            if MusicTime - note.time < missTiming and MusicTime - note.time > -missTiming then
                if Input:pressed(allInputs[i]) and not paused then
                    judge(MusicTime - note.time)
                    table.insert(notesPerSecond, 1)
                    table.remove(lane, j)
                    break
                end
            end
        end
    end
end ]]


function checkBotInput()
    for i, lane in ipairs(lanes) do
        for j, note in ipairs(lane) do
            if MusicTime - note.time > -1 then
                judge(MusicTime - note.time)
                table.remove(lane, j)
                break
            end
        end
    end
end

function PlayState:draw()
--love.graphics.setCanvas(GameScreen)

    if resultsScreen then
        love.graphics.push()




        
        if gameOver then
            grade = "F"
        end

        blurEffect(function()
        love.graphics.draw(background, 0, 0, nil, Inits.GameWidth/background:getWidth(),Inits.GameHeight/background:getHeight())
        end)
        
        love.graphics.setColor(0,0,0,backgroundDim[1])
        love.graphics.rectangle("fill", 0, 0, Inits.GameWidth, Inits.GameHeight)
        if not resultsScreenTranslate then
            resultsScreenTranslate = {-500}
            Timer.tween(0.3, resultsScreenTranslate, {0}, "out-expo")
        end
        love.graphics.translate(0,resultsScreenTranslate[1])
        love.graphics.setColor(1,1,1,1)

        love.graphics.setFont(BigFont)

        love.graphics.printf(metaData.name, 10, 10, 5000)
        love.graphics.printf(string.format("%.2f", tostring(math.min((printableAccuracy[1]))), 100).."%", 50, 500, 200, "right")
        love.graphics.setFont(MediumFont)

        love.graphics.printf(metaData.diffName, 10, 80, 5000)


    


       love.graphics.setFont(ReallyFuckingBigFont)

        love.graphics.print(grade, 45, Inits.GameHeight/2-235)




       -- love.graphics.pop()
       -- love.graphics.push()


        love.graphics.translate(Inits.GameWidth/2-250,Inits.GameHeight/2)
        love.graphics.setLineWidth(1)
        love.graphics.scale(1, 0.5)
        graphWidth = 500
        love.graphics.setFont(MenuFontExtraSmall)

        love.graphics.setColor(1,1,1)
        love.graphics.line(0, marvTiming, graphWidth, marvTiming)
        love.graphics.printf(marvTiming, -22, marvTiming, 100, "left", 0, 0.5, 1)
        love.graphics.setColor(1,1,78/255)
        love.graphics.line(0, perfTiming, graphWidth, perfTiming)
        love.graphics.printf(perfTiming, -22, perfTiming, 100, "left", 0, 0.5, 1)

        love.graphics.setColor(92/255, 1, 82/255)
        love.graphics.line(0, greatTiming, graphWidth,greatTiming)
        love.graphics.printf(greatTiming, -22, greatTiming, 100, "left", 0, 0.5, 1)

        love.graphics.setColor(0,61/255,1)
        love.graphics.line(0, goodTiming, graphWidth, goodTiming)
        love.graphics.printf(goodTiming, -22, goodTiming, 100, "left", 0, 0.5, 1)

        love.graphics.setColor(129/255,0,1)
        love.graphics.line(0, okayTiming, graphWidth, okayTiming)
        love.graphics.printf(okayTiming, -22, okayTiming, 100, "left", 0, 0.5, 1)

        love.graphics.setColor(1,65/255,65/255)
        love.graphics.line(0, missTiming, graphWidth, missTiming)
        love.graphics.printf(missTiming, -22, missTiming, 100, "left", 0, 0.5, 1)

        love.graphics.setColor(1,1,1)
        love.graphics.line(0, 0, graphWidth, 0)
        love.graphics.printf(-0, -22, 0, 100, "left", 0, 0.5, 1)

        love.graphics.setColor(1,1,1)
        love.graphics.line(0, -marvTiming, graphWidth, -marvTiming)
        love.graphics.printf(-marvTiming, -22, -marvTiming, 100, "left", 0, 0.5, 1)

        love.graphics.setColor(1,1,78/255)
        love.graphics.line(0, -perfTiming, graphWidth, -perfTiming)
        love.graphics.printf(-perfTiming, -22, -perfTiming, 100, "left", 0, 0.5, 1)

        love.graphics.setColor(92/255, 1, 82/255)
        love.graphics.line(0, -greatTiming, graphWidth, -greatTiming)
        love.graphics.printf(-greatTiming, -22, -greatTiming, 100, "left", 0, 0.5, 1)

        love.graphics.setColor(0,61/255,1)
        love.graphics.line(0, -goodTiming, graphWidth, -goodTiming)
        love.graphics.printf(-goodTiming, -22, -goodTiming, 100, "left", 0, 0.5, 1)

        love.graphics.setColor(129/255,0,1)
        love.graphics.line(0, -okayTiming, graphWidth, -okayTiming)
        love.graphics.printf(-okayTiming, -22, -okayTiming, 100, "left", 0, 0.5, 1)

        love.graphics.setColor(1,65/255,65/255)
        love.graphics.line(0, -missTiming, graphWidth, -missTiming)
        love.graphics.printf(-missTiming, -22, -missTiming, 100, "left", 0, 0.5, 1)







        for i = 1,#hitTimes do
            miss = false

            if hitTimes[i][1] > missTiming then
                miss = true
            end
            local noteHitTime = math.abs(hitTimes[i][1])
        
            if noteHitTime < marvTiming then
                love.graphics.setColor(1,1,1)
            elseif noteHitTime < perfTiming then
                love.graphics.setColor(1,1,78/255)
            elseif noteHitTime < greatTiming then
                love.graphics.setColor(92/255, 1, 82/255)
            elseif noteHitTime < goodTiming then
                love.graphics.setColor(0,61/255,1)
            elseif noteHitTime < okayTiming then
                love.graphics.setColor(129/255,0,1)
            elseif noteHitTime < missTiming then
                love.graphics.setColor(1,65/255,65/255)
                miss = true
            end
            if miss then
                love.graphics.setColor(1,65/255,65/255)
                love.graphics.line(((hitTimes[i][2])/(songLength*1000)*graphWidth), -missTiming, ((hitTimes[i][2])/(songLength*1000)*graphWidth), missTiming)
            else
                love.graphics.rectangle("fill", (hitTimes[i][2])/(songLength*1000)*graphWidth, hitTimes[i][1], 3, 6, 1.5, 3)
            end
        end
        love.graphics.setLineWidth(25)
        love.graphics.push()
        love.graphics.scale(1,1.8)
        love.graphics.translate(860, -700)

        love.graphics.rotate(math.rad(90))

        love.graphics.setColor(1,1,1)

        love.graphics.line(600, 286, 600, (-((marvCount/totalNoteCount)*300))+286)
        love.graphics.line(640, 286, 640, -((perfCount/totalNoteCount)*300)+286)
        love.graphics.setColor(92/255,1, 82/255)

        love.graphics.line(680, 286, 680, -((greatCount/totalNoteCount)*300)+286)
        love.graphics.line(720, 286, 720, -((goodCount/totalNoteCount)*300)+286)
        love.graphics.setColor(1,65/255,65/255)

        love.graphics.line(760, 286, 760, -((okayCount/totalNoteCount)*300)+286)
        love.graphics.line(800, 286, 800, -((missCount/totalNoteCount)*300)+286)
        love.graphics.setColor(1,1,1)

        love.graphics.pop()
        love.graphics.setLineWidth(1)


        love.graphics.setFont(MediumFont)
        love.graphics.scale(1,2)
        love.graphics.printf(marvCount,465,-103, 100, "right")
        love.graphics.printf(perfCount,465, -67, 100, "right")
        love.graphics.setColor(92/255,1, 82/255)
        love.graphics.printf(greatCount,465, -32, 100, "right")
        love.graphics.printf(goodCount,465,  3, 100, "right")
        love.graphics.setColor(1,65/255,65/255)
        love.graphics.printf(okayCount,465, 39, 100 ,"right")
        love.graphics.printf(missCount,465, 75, 100, "right")

        love.graphics.setLineWidth(1)

        love.graphics.pop()

    else
        blurEffect(function()
        love.graphics.draw(background, Inits.GameWidth/2, Inits.GameHeight/2, nil, Inits.GameWidth/background:getWidth()+beatBump[1],Inits.GameHeight/background:getHeight()+beatBump[1], background:getWidth()/2, background:getHeight()/2)
        end)


        love.graphics.push()
            if skinDrawUnderDim then
                skinDrawUnderDim()
            end

            love.graphics.setColor(0,0,0,backgroundDim[1])
            love.graphics.rectangle("fill", 0, 0, Inits.GameWidth, Inits.GameHeight)
            love.graphics.setColor(1,1,1,1)
            --time bar
            timeLeftPercent = (song:tell()/songLengthToLastNote)
            love.graphics.rectangle("fill", 0, Inits.GameHeight-20, Inits.GameWidth*timeLeftPercent, 20)
            
            love.graphics.pop()
            if skinDrawAboveDimUnderNotes then
                skinDrawAboveDimUnderNotes()
            end

            love.graphics.push()
                if downScroll then
                    love.graphics.translate(0, Inits.GameHeight-NoteUp:getHeight()-verticalNoteOffset)
                    downscrollOffset = -1
                else
                    downscrollOffset = 1
                    love.graphics.translate(0, verticalNoteOffset)
                end
        

                    for i = 1,4 do
                        local inp = allInputs[i]
                        local spr = _G["Receptor" .. AllDirections[i]]
                        if Input:down(inp) and not BotPlay then spr = _G["Receptor" .. AllDirections[i] .. "Pressed"] end
                        love.graphics.draw(spr, Inits.GameWidth/2-(LaneWidth*(3-i)), 0 ,nil,125/spr:getWidth(),125/spr:getHeight())
                    end



            
                love.graphics.push()
                    if gameOverNotePush[1] ~= 0 then
                        love.graphics.translate(0, gameOverNotePush[1])
                    end

                    for i, lane in ipairs(lanes) do
                        for j, note in ipairs(lane) do
                            if note.y < Inits.GameHeight then
                                --[[ local noteImg = _G["Note" .. AllDirections[i]]
                                --love.graphics.draw(noteImg, Inits.GameWidth/2-(LaneWidth*(3-i)), note[3],nil,125/noteImg:getWidth(),125/noteImg:getHeight()) ]]
                                note:draw()
                            end
                        end
                    end
                love.graphics.pop()
            love.graphics.pop()

        love.graphics.pop()
        love.graphics.push()
    
            love.graphics.setFont(BigFont)
            love.graphics.setColor(0,0.5,1)
            love.graphics.setColor(1,1,1)
    
            love.graphics.print(math.floor(printableScore[1]),0,0-(beatBump[1]*50))
    
            love.graphics.setFont(DefaultFont)
    
    
    
            love.graphics.push()
            love.graphics.translate(0,(judgePos[4] or 0))
    
        love.graphics.setColor(1,1,1,judgeColors[1])
        love.graphics.draw(Marvelous, (Inits.GameWidth/2)-(judgementWidth/Marvelous:getWidth()/2),  Inits.GameHeight/2-(JudgementPosition*downscrollOffset), nil, judgementWidth/Marvelous:getWidth() * (judgePos[2] or 0), (judgementHeight/Marvelous:getHeight() * (judgePos[1] or 0)), (Marvelous:getWidth()/2), Marvelous:getHeight()/2)
        love.graphics.setColor(1,1,1,judgeColors[2])
        love.graphics.draw(Perfect, (Inits.GameWidth/2)-(judgementWidth/Perfect:getWidth()/2), Inits.GameHeight/2-(JudgementPosition*downscrollOffset), nil, judgementWidth/Perfect:getWidth() * (judgePos[2] or 0), judgementHeight/Perfect:getHeight() * (judgePos[1] or 0), Perfect:getWidth()/2, Perfect:getHeight()/2)
        love.graphics.setColor(1,1,1,judgeColors[3])
        love.graphics.draw(Great, (Inits.GameWidth/2)-(judgementWidth/Great:getWidth()/2), Inits.GameHeight/2-(JudgementPosition*downscrollOffset), nil, judgementWidth/Great:getWidth() * (judgePos[2] or 0), judgementHeight/Great:getHeight() * (judgePos[1] or 0), Great:getWidth()/2, Great:getHeight()/2)
        love.graphics.setColor(1,1,1,judgeColors[4])
        love.graphics.draw(Good, (Inits.GameWidth/2)-(judgementWidth/Good:getWidth()/2), Inits.GameHeight/2-(JudgementPosition*downscrollOffset), nil, judgementWidth/Good:getWidth() * (judgePos[2] or 0), judgementHeight/Good:getHeight() * (judgePos[1] or 0), Good:getWidth()/2, Good:getHeight()/2)
        love.graphics.setColor(1,1,1,judgeColors[5])

        love.graphics.draw(Okay, (Inits.GameWidth/2)-(judgementWidth/Okay:getWidth()/2), Inits.GameHeight/2-(JudgementPosition*downscrollOffset), nil, judgementWidth/Okay:getWidth() * (judgePos[2] or 0), judgementHeight/Okay:getHeight() * (judgePos[1] or 0), Okay:getWidth()/2, Okay:getHeight()/2)
        love.graphics.setColor(1,1,1,judgeColors[6])
        love.graphics.draw(Miss, (Inits.GameWidth/2)-(judgementWidth/Miss:getWidth()/2), Inits.GameHeight/2-(JudgementPosition*downscrollOffset), math.rad((randomMissAngle or 0)), judgementWidth/Miss:getWidth() * (judgePos[2] or 0), judgementHeight/Miss:getHeight() * (judgePos[1] or 0), Miss:getWidth()/2, Miss:getHeight()/2)
        love.graphics.setColor(1,1,1,1)
        love.graphics.pop()
        love.graphics.rectangle("fill",Inits.GameWidth/2-1, Inits.GameHeight/2-3, 2, 26)

        for i = 1,#hitTimes do
            love.graphics.setColor(hitTimes[i][4])
            love.graphics.rectangle("fill", (((hitTimes[i][1])/2)+(Inits.GameWidth/2)-2), Inits.GameHeight/2, 4, 20)
        end
        love.graphics.setColor(1,1,1,1)
        love.graphics.setFont(MediumFontSolid)
    
        if marvCount ~= 0 then
            love.graphics.print(marvCount,judgeCounterXPos[1], (Inits.GameHeight/2)-100)
        else
            love.graphics.print("Marvelous",0, (Inits.GameHeight/2)-100)
        end
        if perfCount ~= 0 then
            love.graphics.print(perfCount,judgeCounterXPos[2], (Inits.GameHeight/2)-50)
        else
            love.graphics.print("Perfect",0, (Inits.GameHeight/2)-50)
        end
        love.graphics.setColor(92/255,1, 82/255)
    
        if greatCount ~= 0 then
            love.graphics.print(greatCount,judgeCounterXPos[3], (Inits.GameHeight/2)+0)
        else
            love.graphics.print("Great",0, (Inits.GameHeight/2)+0)
        end
        if goodCount ~= 0 then
            love.graphics.print(goodCount,judgeCounterXPos[4], (Inits.GameHeight/2)+50)
        else
            love.graphics.print("Good",0, (Inits.GameHeight/2)+50)
        end
        love.graphics.setColor(1,65/255,65/255)
        if okayCount ~= 0 then
            love.graphics.print(okayCount,judgeCounterXPos[5], (Inits.GameHeight/2)+100)
        else
            love.graphics.print("Okay",0, (Inits.GameHeight/2)+100)
        end
        if missCount ~= 0 then
           love.graphics.print(missCount,judgeCounterXPos[6], (Inits.GameHeight/2)+150)
        else
            love.graphics.print("Miss",0, (Inits.GameHeight/2)+150)
        end
    
    
    
    
    
    
        love.graphics.setColor(1,1,1,1)
        love.graphics.setFont(BigFont)
        if combo < 500 then
            love.graphics.setColor(1,1,1)
        else
            love.graphics.setColor(1,0.5,0)
        end


        if combo > 0 then
            love.graphics.printf(combo, 0, Inits.GameHeight/2-(ComboPosition * downscrollOffset) +judgePos[1]*2, Inits.GameWidth, "center", nil, 1, judgePos[2])
        end
        love.graphics.print("MusicTime: " .. math.floor(MusicTime))
        love.graphics.setColor(0,0.5,1)
      --  love.graphics.printf(string.format("%.2f", tostring(math.min((printableAccuracy[1]))), 100).."%", 3, 3-(beatBump[1]*100), Inits.GameWidth, "right")
       -- love.graphics.printf(grade, 3, 58-(beatBump[1]*100), Inits.GameWidth, "right")

        accuracyColor = printableAccuracy[1]/100
    
        love.graphics.setColor(1+accuracyColor,accuracyColor,accuracyColor)
    
    
        love.graphics.printf(string.format("%.2f", tostring(math.min((printableAccuracy[1]))), 100).."%", 0, 0-(beatBump[1]*50), Inits.GameWidth, "right")
        gradeColors = {1,1,1}
        love.graphics.setColor(gradeColors)

        love.graphics.printf(grade, 0, 55-(beatBump[1]*50), Inits.GameWidth, "right")

        love.graphics.setFont(DefaultFont)
        love.graphics.setColor(0,0,0)

    
    --    love.graphics.rectangle("fill", 896, 636, 13, -508)
    
        love.graphics.setColor(0,0.5,1)
    
    
       -- love.graphics.rectangle("fill", 900, 632, 5, -printableHealth[1]*500)
        love.graphics.setFont(MediumFontSolid)
        if BotPlay then
            love.graphics.printf("Bot Play", 0, Inits.GameHeight/2, Inits.GameWidth, "center")
        end

        love.graphics.setColor(0,1,1,songInfoAlpha)
        love.graphics.setFont(MediumFont)

        love.graphics.printf(metaData.name.."\n" ..metaData.diffName .. "\nArtist- " .. metaData.artist .. "\nCharter- " .. metaData.creator, 0, Inits.GameHeight/2-150, Inits.GameWidth, "center")
        love.graphics.setColor(1,1,1,1)
        love.graphics.setFont(BigFont)

        if canBeSkipped then
            love.graphics.printf("Press Space to Skip Intro", 0, Inits.GameHeight/2+300, Inits.GameWidth, "center")
        end
        
        if combo < 500 then
            love.graphics.setColor(1,1,1,comboAlertPosition[3])
        else
            love.graphics.setColor(1,0.5,0,comboAlertPosition[3])

        end
        love.graphics.print((comboAlert or ""), comboAlertPosition[1], comboAlertPosition[2])

      --  love.graphics.draw(HealthImage, 880, 650-HealthImage:getHeight())
    
    
    
        --love.graphics.line(0, Inits.GameHeight/2, Inits.GameWidth, Inits.GameHeight/2)
        if skinDrawAbove then
            skinDrawAbove()
        end
        if not songLeave then
            songLeave = 0
        end
        if not songRestart then
            songRestart = 0
        end
        love.graphics.setColor(0,0,0,songLeave*2)
        love.graphics.rectangle("fill", 0, 0, Inits.GameWidth, Inits.GameHeight)
        love.graphics.setColor(0,0,0,songRestart)
        love.graphics.rectangle("fill", 0, 0, Inits.GameWidth, Inits.GameHeight)

        if paused and printableHealth[1] > 0 then
            love.graphics.setColor(0,0,0,0.8)
            love.graphics.rectangle("fill", 0, 0, Inits.GameWidth, Inits.GameHeight)
            love.graphics.setColor(1,1,1,1)
            love.graphics.setFont(BigFont)
            love.graphics.print("Paused")
            local options = {"Resume", "Restart", "Exit"}
            for i = 1, #options do
                if i == pauseSelection then
                    love.graphics.setColor(0,0,0,0.9)
                    love.graphics.rectangle("fill", Inits.GameWidth/2-100, 100*i, 200, 50)
                    love.graphics.setColor(0,1,1,1)
                    love.graphics.printf(options[i], Inits.GameWidth/2-100, (100*i)-5 , 200, "center")
                    love.graphics.rectangle("line", Inits.GameWidth/2-100, 100*i, 200, 50)
                else
                    love.graphics.setColor(1,1,1,0.9)
                    love.graphics.rectangle("fill", Inits.GameWidth/2-100, 100*i, 200, 50)
                    love.graphics.setColor(0,0,0,0.9)
                    love.graphics.printf(options[i], Inits.GameWidth/2-100, (100*i)-5 , 200, "center")
                    love.graphics.rectangle("line", Inits.GameWidth/2-100, 100*i, 200, 50)
                end
            end



            if Input:pressed("GameConfirm") then
                if pauseSelection == 1 then
                    pause()
                elseif pauseSelection == 2 then
                    State.switch(States.PlayState)

                elseif pauseSelection == 3 then
                    printableHealth = {0}
                    State.switch(States.SongSelectState)
                end
            elseif Input:pressed("MenuUp") then
                pauseSelection = pauseSelection - 1
            elseif Input:pressed("MenuDown") then
                pauseSelection = pauseSelection + 1
            end
            if pauseSelection > #options then
                pauseSelection = 1
            elseif pauseSelection < 1 then
                pauseSelection = #options
            end
        end
    end

end

return PlayState