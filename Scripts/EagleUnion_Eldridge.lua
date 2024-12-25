-- EagleUnion_Eldridge
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/24 22:55:24
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnion_Core.lua')

--||====================ExposedMembers====================||--

--ExposedMembers
ExposedMembers.Eldridge = ExposedMembers.Eldridge or {}

--||===================local variables====================||--

local key = 'EldridgeVoltage'

--||=================GameEvents functions=================||--

--transmission unit
function EldridgePlaceUnit(playerID, param)
    local pPlayer = Players[playerID]
    if pPlayer then
        local pUnit = UnitManager.GetUnit(playerID, param.unitID)
        if pUnit then
            UnitManager.PlaceUnit(pUnit, param.x, param.y)
        end
    end
end

--max voltage!
function EldridgeMaxVoltage(playerID, param)
    local pPlayer = Players[playerID]
    local pUnit = UnitManager.GetUnit(playerID, param.UnitID)
    --if the unit and player exist, then proceed
    if pPlayer and pUnit then
        --get the diplomacy
        local diplomacy = pPlayer:GetDiplomacy()
        --get the unit x and y
        local x, y = pUnit:GetX(), pUnit:GetY()
        --get the adjacent plots
        for _, plot in ipairs(Map.GetAdjacentPlots(x, y)) do
            --play the effect?
            local hasEffect = false
            --get the plot units
            for _, unit in pairs(Units.GetUnitsInPlot(plot)) do
                --if the unit is enemy
                if unit ~= nil and diplomacy:IsAtWarWith(unit:GetOwner()) then
                    if not hasEffect then
                        --play the effect
                        ExposedMembers.Eldridge.PlayEffect(plot:GetX(), plot:GetY())
                        --set the plot effect
                        hasEffect = true
                    end
                    --damage the unit
                    EagleCore.DamageUnit(unit, 20)
                end
            end
        end
        --set the unit property
        pUnit:SetProperty(key, Game.GetCurrentGameTurn())
        --report the activation
        UnitManager.ReportActivation(pUnit, "ELDRIDGE_VOLTAGE")
    end
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------------Events-----------------------

    ---------------------GameEvents---------------------
    GameEvents.EldridgeRePlaceUnit.Add(EldridgePlaceUnit)
    GameEvents.EldridgeVoltage.Add(EldridgeMaxVoltage)
    ----------------------------------------------------
    ----------------------------------------------------
    print('Initial success!')
end

include('EagleUnion_Eldridge_', true)

Initialize()
