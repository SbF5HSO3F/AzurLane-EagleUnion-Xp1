-- EagleUnionStLouis
-- Author: HSbF6HSO3F
-- DateCreated: 2025/3/2 19:54:51
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')
include('EagleUnionPoint')

--||===================local variables====================||--

local goldKey = 'StLouisGold'

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
            --grant the point
            EaglePointManager:ChangeEaglePoint(playerID, change)
        end
        --set the last faith balance
        pPlayer:SetProperty(goldKey, balance)
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

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------------Events-----------------------
    Events.TreasuryChanged.Add(StLouisTreasuryChanged)
    ---------------------GameEvents---------------------
    GameEvents.StLouisCreated.Add(StLouisCreated)
    GameEvents.StLouisRemoved.Add(StLouisRemoved)
    ----------------------------------------------------
    ----------------------------------------------------
    print('Initial success!')
end

include('EagleUnionStLouis_', true)

Initialize()
