-- EagleUnionEnterprise
-- Author: HSbF6HSO3F
-- DateCreated: 2025/2/16 11:37:33
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')

--||==================global variables====================||--

Enterprises = {}

for _, player in ipairs(Game.GetPlayers()) do
    local playerID = player:GetID()
    if EagleCore.CheckLeaderMatched(playerID,
            'LEADER_ENTERPRISE_CV6'
        ) then
        table.insert(Enterprises, playerID)
    end
end

Key_1 = 'HasEnterpriseDebuff'
Key_2 = 'EnterpriseRecoverTurns'
Modifier_1 = 'SOARING_WINGS_OF_FREEDOM_ATTACH_DEBUFF'
Modifier_2 = 'SOARING_WINGS_OF_FREEDOM_ATTACH_PROPERTY'

--||===================Events functions===================||--

--at the begining of the turn
function EnterpriseTurnBegin(playerID, isFirst)
    --is the first turn of the player?
    if not isFirst then return end
    --in the game has enterprise player?
    if #Enterprises == 0 then return end
    --get the player diplomacy
    local pPlayer = Players[playerID]
    --the player is major player?
    if not pPlayer:IsMajor() then return end
    --get the player diplomacy
    local diplomacy = pPlayer:GetDiplomacy()
    --check the player is at war with enterprise player
    for _, enterprise in ipairs(Enterprises) do
        if diplomacy:IsAtWarWith(enterprise) then
            if not pPlayer:GetProperty(Key_1) then
                pPlayer:AttachModifierByID(Modifier_1)
                pPlayer:SetProperty(Key_1, true)
            end
            pPlayer:AttachModifierByID(Modifier_2)
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
        pUnit:SetProperty(Key_2, Game.GetCurrentGameTurn())
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
