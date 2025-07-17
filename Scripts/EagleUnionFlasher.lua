-- EagleUnion_Flasher
-- Author: HSbF6HSO3F
-- DateCreated: 2024/3/2 16:51:50
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')

--||===================local variables====================||--

local searchRange = 'FlasherSearchRange'
local turnKey     = 'FlasherTurns'
local killCounter = 'FlasherKills'
local goldBaseNum = 100
local goldAddNum  = 50

--||====================base functions====================||--

--Search the emeny
function FlasherSearchEmeny(playerID, unitID, range)
    --get the unit
    local pUnit = UnitManager.GetUnit(playerID, unitID)
    --get the player
    local pPlayer = Players[playerID]
    if pUnit == nil or pPlayer == nil then return false end
    --get player Diplomacy
    local playerDiplomacy = pPlayer:GetDiplomacy()
    --get the x, y and boolean
    local x, y, result = pUnit:GetX(), pUnit:GetY(), false
    --get the plots
    local tPlots = Map.GetNeighborPlots(x, y, range and range or 1)
    --begin loop
    for _, plot in ipairs(tPlots) do
        for _, unit in ipairs(Units.GetUnitsInPlot(plot)) do
            if unit ~= nil and unit:GetOwner() ~= playerID and playerDiplomacy:IsAtWarWith(unit:GetOwner()) then
                result = true
                break
            end
        end
    end
    return result
end

--||===================Events functions===================||--

--When Unit Move Complete
function FlasherMoveComplete(playerID, unitID, iX, iY)
    --check leader is Flasher
    if not EagleCore.CheckLeaderMatched(playerID, 'LEADER_FLASHER_SS249') then return end
    --get the unit
    local pUnit = UnitManager.GetUnit(playerID, unitID)
    if pUnit == nil then return end
    --get the current turns
    local currentTurn = Game.GetCurrentGameTurn()
    --check the unit
    local lastTurn = pUnit:GetProperty(turnKey) or 0
    if lastTurn >= currentTurn then return end
    --get the range
    local range = pUnit:GetProperty(searchRange) or 0
    --is combat unit?
    if range > 0 then
        if FlasherSearchEmeny(playerID, unitID, range) then
            --get the buff
            UnitManager.RestoreUnitAttacks(pUnit)
            UnitManager.RestoreMovementToFormation(pUnit)
            --reset the property
            pUnit:SetProperty(turnKey, currentTurn)
            --add message
            local message     = Locale.Lookup('LOC_FLASHER_HUNTRESS')
            local messageData = {
                MessageType = 0,
                MessageText = message,
                PlotX       = pUnit:GetX(),
                PlotY       = pUnit:GetY(),
                Visibility  = RevealedState.VISIBLE,
            }
            Game.AddWorldViewText(messageData)
        end
    end
end

--Flasher Kill Unit
function FlasherKillUnit(killedPlayerID, killedUnitID, playerID, unitID)
    --check leader is Flasher
    if EagleCore.CheckLeaderMatched(playerID, 'LEADER_FLASHER_SS249') then
        --get the player
        local pPlayer = Players[playerID]
        --get the kill num
        local killNum = pPlayer:GetProperty(killCounter) or 0
        --get the gold gain
        local goldGain = EagleCore:ModifyBySpeed(goldBaseNum + goldAddNum * killNum)
        --grant the gold and set the property
        pPlayer:GetTreasury():ChangeGoldBalance(goldGain)
        killNum = (killNum or 0) + 1
        pPlayer:SetProperty(killCounter, killNum)
        ExposedMembers.Flasher.Reset(killNum)
        --get the unit
        local pUnit = UnitManager.GetUnit(playerID, unitID)
        --set the message
        local message = Locale.Lookup('LOC_FLASHER_HUNTRESS_GOLD', goldGain)
        --add the message to the game
        local messageData = {
            MessageType = 0,
            MessageText = message,
            PlotX       = pUnit:GetX(),
            PlotY       = pUnit:GetY(),
            Visibility  = RevealedState.VISIBLE,
        }
        Game.AddWorldViewText(messageData)
    end
end

--When unit movement change
function FlasherMovementChange(playerID, unitID, MovementPoints)
    --check the leader
    if EagleCore.CheckLeaderMatched(playerID, 'LEADER_FLASHER_SS249') then
        --get the unit
        local pUnit = UnitManager.GetUnit(playerID, unitID)
        --get the strength
        local strength = 3 * math.floor(MovementPoints)
        --set the property
        pUnit:SetProperty('FlasherPerMovement', strength)
    end
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------------Events-----------------------
    Events.UnitMoveComplete.Add(FlasherMoveComplete)
    Events.UnitKilledInCombat.Add(FlasherKillUnit)
    Events.UnitMovementPointsChanged.Add(FlasherMovementChange)
    ---------------------GameEvents---------------------
    ----------------------------------------------------
    print('Initial success!')
end

include('EagleUnionFlasher_', true)

Initialize()
