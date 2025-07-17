-- EagleUnionStLouis
-- Author: HSbF6HSO3F
-- DateCreated: 2025/3/2 19:54:51
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')
include('EagleUnionPoint')

--||===================local variables====================||--

local goldKey = 'StLouisGold'
local percent = 25
local ability = 'ABILITY_ST_IMPROVED'
local modifier_1 = 'ST_LOUIS_GRANT_GOLD_BASED_ON_EXCESS_LUXURIES'
local modifier_2 = 'ST_LOUIS_GRANT_TOURISM_BASED_ON_EXCESS_LUXURIES'

--||====================base functions====================||--

--结束单位回合
function StLouisEndTurn(unit)
    local curMoves = unit:GetMovesRemaining()
    UnitManager.ChangeMovesRemaining(unit, -curMoves)
end

--||===================Events functions===================||--

function StLouisTreasuryChanged(playerID, yield, balance)
    if EagleCore.CheckLeaderMatched(playerID, 'LEADER_ST_LOUIS_CL49') then
        --get the player
        local pPlayer = Players[playerID]
        --get the player last faith balance
        local lastGold = pPlayer:GetProperty(goldKey) or 0
        --get faith balance change
        local change = lastGold - balance
        --if the change is positive, grant the yield
        if change > 0 then
            change = EagleCore.Round(change * percent / 100)
            --grant the point
            EaglePointManager:ChangeEaglePoint(playerID, change)
        end
        --set the last faith balance
        pPlayer:SetProperty(goldKey, balance)
    end
end

function StLouisCreateTradeRoute(playerID, oPlayerID, oCityID, tPlayerID)
    if EagleCore.CheckLeaderMatched(
            playerID, 'LEADER_ST_LOUIS_CL49'
        ) and oPlayerID ~= tPlayerID then
        --get the city
        local city = CityManager.GetCity(oPlayerID, oCityID)
        if not city then return end
        --attach the modifier
        city:AttachModifierByID(modifier_1)
        city:AttachModifierByID(modifier_2)
    end
end

--||=================GameEvents functions=================||--

--创建随机资源
function StLouisCreated(playerID, param)
    local plot, list = Map.GetPlot(param.X, param.Y), param.List
    --get the random resource index
    local index = list[EagleCore.tableRandom(#list)]
    --create deer resource
    ResourceBuilder.SetResourceType(plot, index, 1)
    --get the unit
    local unit = UnitManager.GetUnit(playerID, param.UnitID)
    unit:ChangeActionCharges(-1)
    --end the unit turn
    StLouisEndTurn(unit)
    --report the unit active
    UnitManager.ReportActivation(unit, "STLOUIS_CREATED")
end

--移除资源
function StLouisRemoved(playerID, param)
    local plot = Map.GetPlot(param.X, param.Y)
    --remove the resource
    ResourceBuilder.SetResourceType(plot, -1)
    --remove the imporvement
    ImprovementBuilder.SetImprovementType(plot, -1)
    --the reward
    local gold, player = param.Gold, Players[playerID]
    player:GetTreasury():ChangeGoldBalance(gold)
    --set the message
    local message = Locale.Lookup('LOC_STLOUIS_REMOVE_TEXT', gold)
    --add the message to the game
    local messageData = {
        MessageType = 0,
        MessageText = message,
        PlotX       = param.X,
        PlotY       = param.Y,
        Visibility  = RevealedState.VISIBLE,
    }; Game.AddWorldViewText(messageData)
    --get the unit
    local unit = UnitManager.GetUnit(playerID, param.UnitID)
    --end the unit turn
    StLouisEndTurn(unit)
    --report the unit active
    UnitManager.ReportActivation(unit, "STLOUIS_REMOVED")
end

--改良单元格
function StLouisImprove(playerID, param)
    --get the unit
    local unit = UnitManager.GetUnit(playerID, param.UnitID)
    --add the plot into your city
    local unitAbility = unit:GetAbility()
    unitAbility:ChangeAbilityCount(ability, 1)
    unitAbility:ChangeAbilityCount(ability, -unitAbility:GetAbilityCount(ability))
    --get the plot
    local plot = Map.GetPlot(param.X, param.Y)
    --set the improvement
    ImprovementBuilder.SetImprovementType(plot, param.Index, playerID)
    --end the unit turn
    StLouisEndTurn(unit)
    --report the unit active
    UnitManager.ReportActivation(unit, "STLOUIS_IMPROVE")
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------------Events-----------------------
    Events.TreasuryChanged.Add(StLouisTreasuryChanged)
    Events.TradeRouteActivityChanged.Add(StLouisCreateTradeRoute)
    ---------------------GameEvents---------------------
    GameEvents.StLouisCreated.Add(StLouisCreated)
    GameEvents.StLouisRemoved.Add(StLouisRemoved)
    GameEvents.StLouisImprove.Add(StLouisImprove)
    ----------------------------------------------------
    ----------------------------------------------------
    print('Initial success!')
end

include('EagleUnionStLouis_', true)

Initialize()
