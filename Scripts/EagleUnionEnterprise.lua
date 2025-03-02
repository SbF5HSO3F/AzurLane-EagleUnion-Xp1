-- EagleUnionEnterprise
-- Author: HSbF6HSO3F
-- DateCreated: 2025/2/16 11:37:33
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')

--||==================global variables====================||--

KeyRecover = 'EnterpriseRecoverTurns'
Modifier_1 = 'SOARING_WINGS_OF_FREEDOM_ATTACH_PROPERTY'

--||===================Events functions===================||--

--at the begining of the turn
function EnterpriseTurnBegin(playerID, isFirst)
    --is the first turn of the player?
    if not isFirst then return end
    if EagleCore.CheckLeaderMatched(
            playerID, 'LEADER_ENTERPRISE_CV6'
        ) then
        --get the player diplomacy
        local pPlayer = Players[playerID]
        --get the player diplomacy
        local diplomacy = pPlayer:GetDiplomacy()
        --check the player is at war with enterprise player
        local majors = PlayerManager.GetAliveMajorIDs()
        for _, major in ipairs(majors) do
            if diplomacy:IsAtWarWith(major) then
                pPlayer:AttachModifierByID(Modifier_1)
            end
        end
    end
end

--||=================GameEvents functions=================||--

--recover
function EnterpriseRecover(playerID, param)
    --get the unit
    local pUnit = UnitManager.GetUnit(playerID, param.UnitID)
    if pUnit then
        --recover
        pUnit:SetDamage(0)
        --set the recover turns
        pUnit:SetProperty(KeyRecover, Game.GetCurrentGameTurn())
        --report the active
        --report the activation
        UnitManager.ReportActivation(pUnit, "ENTERPRISE_RECOVER")
    end
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------------Events-----------------------
    Events.PlayerTurnActivated.Add(EnterpriseTurnBegin)
    ---------------------GameEvents---------------------
    GameEvents.EnterpriseRecover.Add(EnterpriseRecover)
    ----------------------------------------------------
    ----------------------------------------------------
    print('Initial success!')
end

include('EagleUnionEnterprise_', true)

Initialize()
