-- EagleUnion_EldridgeUnitUI
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/24 20:39:42
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnion_Core')

--||===================local variables====================||--

local COLOR = UILens.CreateLensLayerHash("Hex_Coloring_Movement")
local m_EldridgeSelected, m_EldridgePlot = false, nil

--||======================MetaTable=======================||--

EldridgeUnitPanel = {
    --重置
    Reset = function(self)
        --get the unit
        local pUnit = UI.GetHeadSelectedUnit()
        --check the leader is Eldridge
        if EagleCore.CheckLeaderMatched(
                Game.GetLocalPlayer(), 'LEADER_ELDRIDGE_DE173'
            ) and pUnit
        then
            Controls.EldridgeGrid:SetHide(false)
            --reset the buttons
            self.Rainbow:Reset(pUnit)
        else
            --hide the grid
            Controls.EldridgeGrid:SetHide(true)
        end
        --reset the Unit Panel
        ContextPtr:LookUpControl("/InGame/UnitPanel"):RequestRefresh()
    end,
    --初始化
    Init = function(self)
        local context = ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack")
        if context then
            --change the parent
            Controls.EldridgeGrid:ChangeParent(context)
            --Register Callback
            self.Rainbow:Register()
            --reset the button
            self:Reset()
        end
    end,
    --彩虹计划：传送
    Rainbow = {
        GetPlots = function(pUnit)
            --the plots
            local plots, hash = {}, {}
            --get the unitdef
            local unitdef = GameInfo.Units[pUnit:GetType()]
            if unitdef then
                local domain = unitdef.Domain
                --get the player
                local pPlayer = Players[pUnit:GetOwner()]
                --get cities
                local cities = pPlayer:GetCities()
                for _, city in cities:Members() do
                    --get the city plot
                    local plot = Map.GetPlot(city:GetX(), city:GetY())
                    if EagleCore.CanHaveUnit(plot, unitdef) then
                        --check if the unit is Sea
                        if domain == 'DOMAIN_SEA' then
                            if plot:IsAdjacentToShallowWater() then
                                table.insert(plots, plot:GetIndex())
                                hash[plot:GetIndex()] = 1
                            end
                        else
                            table.insert(plots, plot:GetIndex())
                            hash[plot:GetIndex()] = 1
                        end
                    end
                end
            end
            --return the plots
            return plots, hash
        end,
        --退出
        Quit = function(quit)
            if quit then
                UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
            end
            --清除颜色
            UILens.ClearLayerHexes(COLOR)
            UILens.ToggleLayerOff(COLOR)
            m_EldridgeSelected = false
            Controls.Rainbow:SetSelected(false)
        end,
        --设置状态
        SetState = function(self, state, pUnit)
            --set ui state
            if state then
                UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
                UI.SetInterfaceMode(InterfaceModeTypes.WB_SELECT_PLOT)
                local plots, hash = self.GetPlots(pUnit)
                m_EldridgePlot = hash
                if #plots > 0 then
                    UILens.SetLayerHexesArea(COLOR, Game.GetLocalPlayer(), plots)
                    UILens.ToggleLayerOn(COLOR)
                end
            else
                self.Quit(true)
            end
            --set the button selected state
            Controls.Rainbow:SetSelected(state)
        end,
        --获取细节
        GetDetail = function(self, pUnit)
            local detail = { Disable = true, Reason = 'NONE' }
            if pUnit:GetMovesRemaining() == 0 then
                --no movement, disabled
                detail.Reason = Locale.Lookup('LOC_UNITCOMMAND_RAINBOW_NOMOVEMENT')
            else
                local plots = self.GetPlots(pUnit)
                if plots and #plots > 0 then
                    detail.Disable = false
                else
                    --no plot, disabled
                    detail.Reason = Locale.Lookup('LOC_UNITCOMMAND_RAINBOW_NOPLOT')
                end
            end
            --return the button detail
            return detail
        end,
        --设置按钮
        Reset = function(self, pUnit)
            --get the button details
            local detail = self:GetDetail(pUnit)
            --get the disable
            local disable = detail.Disable
            --set the button
            Controls.Rainbow:SetDisabled(disable)
            Controls.Rainbow:SetAlpha((disable and 0.7) or 1)
            --the tooltip
            local tooltip = Locale.Lookup('LOC_RAINBOW_TITLE') ..
                '[NEWLINE][NEWLINE]' .. Locale.Lookup('LOC_RAINBOW_DESC')
            if disable then
                tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. detail.Reason
                --quit the mode
                self.Quit(false)
            end
            --set the tooltip
            Controls.Rainbow:SetToolTipString(tooltip)
        end,
        --回调函数
        Callback = function(self)
            --Get the unit and set param
            local pUnit = UI.GetHeadSelectedUnit()
            if pUnit then
                --Switched Selected State
                m_EldridgeSelected = not m_EldridgeSelected
                --set the button state
                self:SetState(m_EldridgeSelected, pUnit)
            end
        end,
        --注册函数
        Register = function(self)
            Controls.Rainbow:RegisterCallback(Mouse.eLClick, function() self:Callback() end)
            Controls.Rainbow:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter())
        end
    },
    --电气功率：电击
    Voltage = {

    }
}

--||====================base functions====================||--

--||===================Events functions===================||--

--When the unit is selected
function EldridgeOnUnitSelectChanged(playerId, unitId, locationX, locationY, locationZ, isSelected, isEditable)
    if isSelected and playerId == Game.GetLocalPlayer() then
        EldridgeUnitPanel:Reset()
    end
end

--On ui mode change
function EldridgeUIModeChange(intPara, currentInterfaceMode)
    if m_EldridgeSelected and currentInterfaceMode ~= InterfaceModeTypes.WB_SELECT_PLOT then
        EldridgeUnitPanel.Rainbow.Quit(false)
    end
end

--Add a button to Unit Panel
function EldridgeOnLoadGameViewStateDone()
    EldridgeUnitPanel:Init()
end

--reset the grid
function EldridgeGridReset()
    EldridgeUnitPanel:Reset()
end

--||=================LuaEvents functions==================||--

--On selected plot
function EldridgeSelectPlot(plotID, edge, lbutton, rbutton)
    if lbutton then return end
    if rbutton then
        EldridgeUnitPanel.Rainbow.Quit(true)
    else
        local pUnit = UI.GetHeadSelectedUnit()
        if pUnit and m_EldridgePlot and m_EldridgePlot[plotID] == 1 then
            EldridgeUnitPanel.Rainbow.Quit(true)
            UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                PlayerOperations.EXECUTE_SCRIPT, {
                    OnStart = 'EldridgeRePlaceUnit',
                    unitID = pUnit:GetID(),
                    x = Map.GetPlotByIndex(plotID):GetX(),
                    y = Map.GetPlotByIndex(plotID):GetY(),
                }
            ); m_EldridgePlot = nil; UI.PlaySound("Unit_Relocate")
        end
    end
end

--||======================initialize======================||--

--Initialize
function Initialize()
    Events.LoadGameViewStateDone.Add(EldridgeOnLoadGameViewStateDone)
    Events.UnitSelectionChanged.Add(EldridgeOnUnitSelectChanged)
    --Events.UnitActivate.Add(SeydlitzUnitActive)
    ------------------------------------------
    Events.UnitOperationSegmentComplete.Add(EldridgeGridReset)
    Events.UnitCommandStarted.Add(EldridgeGridReset)
    Events.UnitDamageChanged.Add(EldridgeGridReset)
    Events.UnitMoveComplete.Add(EldridgeGridReset)
    Events.UnitChargesChanged.Add(EldridgeGridReset)
    Events.UnitPromoted.Add(EldridgeGridReset)
    Events.UnitOperationsCleared.Add(EldridgeGridReset)
    Events.UnitOperationAdded.Add(EldridgeGridReset)
    Events.UnitOperationDeactivated.Add(EldridgeGridReset)
    Events.UnitMovementPointsChanged.Add(EldridgeGridReset)
    Events.UnitMovementPointsCleared.Add(EldridgeGridReset)
    Events.UnitMovementPointsRestored.Add(EldridgeGridReset)
    Events.UnitAbilityLost.Add(EldridgeGridReset)

    Events.CityAddedToMap.Add(EldridgeGridReset)
    Events.CityRemovedFromMap.Add(EldridgeGridReset)
    ------------------------------------------
    Events.PhaseBegin.Add(EldridgeGridReset)
    Events.InterfaceModeChanged.Add(EldridgeUIModeChange)
    ------------------------------------------
    LuaEvents.WorldInput_WBSelectPlot.Add(EldridgeSelectPlot)
    ------------------------------------------
    print('Initial success!')
end

include('EagleUnion_EldridgeUnitUI_', true)

Initialize()
