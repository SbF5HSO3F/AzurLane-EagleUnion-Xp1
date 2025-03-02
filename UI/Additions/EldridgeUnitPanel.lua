-- EldridgeUnitPanel
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/24 20:39:42
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')

--||===================local variables====================||--

local COLOR = UILens.CreateLensLayerHash("Hex_Coloring_Movement")
local m_EldridgeSelected, m_EldridgePlot = false, nil

local key = 'EldridgeVoltage'
local voltageReason = DB.MakeHash("ELDRIDGE_VOLTAGE")
local voltageDamage = 20

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
            self.Voltage:Reset(pUnit)
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
            self.Voltage:Register()
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
            local unitDef = GameInfo.Units[pUnit:GetType()]
            if pUnit:GetMovesRemaining() == 0
                or unitDef.IgnoreMoves == true then
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
            Controls.Rainbow:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
        end
    },
    --电气功率：电击
    Voltage = {
        --damage manager
        VoltManager = {
            --来源
            Sources = {
                --来自战斗力
                Combat = {
                    Tooltip = 'LOC_VOLTAGE_BUFF_FROM_COMBAT',
                    GetModifier = function(playerID, unitID)
                        --get the unit
                        local pUnit = UnitManager.GetUnit(playerID, unitID)
                        --get the combat
                        return pUnit:GetCombat()
                    end,
                    GetTooltip = function(self, playerID, unitID)
                        local modifier = self.GetModifier(playerID, unitID)
                        return modifier ~= 0 and Locale.Lookup(self.Tooltip, modifier) or ''
                    end
                }
            },
            GetModifier = function(self, playerID, unitID)
                local modifier = 0
                --get the owner and player
                for _, source in pairs(self.Sources) do
                    modifier = modifier + source.GetModifier(playerID, unitID)
                end
                return modifier
            end,
            GetTooltip = function(self, playerID, unitID)
                local tooltip, tooltips = '', ''
                for _, source in pairs(self.Sources) do
                    tooltips = tooltips .. source:GetTooltip(playerID, unitID)
                end
                if tooltips ~= '' then
                    local modifier = self:GetModifier(playerID, unitID)
                    tooltip = Locale.Lookup('LOC_VOLTAGE_BUFF', modifier) .. tooltips
                end
                return tooltip
            end,
            GetVoltDamage = function(self, pUnit)
                local modifier = self:GetModifier(pUnit:GetOwner(), pUnit:GetID())
                return math.ceil(modifier * voltageDamage / 100 + voltageDamage)
            end
        },
        GetDetail = function(pUnit)
            local detail = { Disable = true, Reason = 'NONE' }
            --get the turns
            local turn = pUnit:GetProperty(key) or 0
            --check the turns
            if turn >= Game.GetCurrentGameTurn() then
                detail.Reason = Locale.Lookup('LOC_UNITCOMMAND_VOLTAGE_LIMIT')
            else
                --has target?
                local hasTarget = false
                --the player diplomacy
                local pPlayer = Players[pUnit:GetOwner()]
                local diplomacy = pPlayer:GetDiplomacy()
                --get the x and y
                local x, y = pUnit:GetX(), pUnit:GetY()
                --begin the loop
                for _, plot in ipairs(Map.GetAdjacentPlots(x, y)) do
                    --about the unit on the plot
                    for _, unit in pairs(Units.GetUnitsInPlot(plot)) do
                        if unit ~= nil and diplomacy:IsAtWarWith(unit:GetOwner()) then
                            hasTarget = true
                            break
                        end
                    end
                end
                --check the target
                if hasTarget then
                    detail.Disable = false
                else
                    detail.Reason = Locale.Lookup('LOC_UNITCOMMAND_VOLTAGE_NOTARGET')
                end
            end
            --return the button detail
            return detail
        end,
        --设置按钮
        Reset = function(self, pUnit)
            --get the button details
            local detail = self.GetDetail(pUnit)
            --get the disable
            local disable = detail.Disable
            --set the button
            Controls.Voltage:SetDisabled(disable)
            Controls.Voltage:SetAlpha((disable and 0.7) or 1)
            --get the volt damage
            local damage = self.VoltManager:GetVoltDamage(pUnit)
            --the tooltip
            local tooltip = Locale.Lookup('LOC_VOLTAGE_TITLE') .. '[NEWLINE][NEWLINE]'
                .. Locale.Lookup('LOC_VOLTAGE_DESC', damage)
            --get the damage tooltip
            local damageTooltip = self.VoltManager:GetTooltip(pUnit:GetOwner(), pUnit:GetID())
            if damageTooltip ~= '' then
                tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. damageTooltip
            end
            if disable then
                tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. detail.Reason
            end
            --set the tooltip
            Controls.Voltage:SetToolTipString(tooltip)
        end,
        --回调函数
        Callback = function(self)
            --get the unit
            local pUnit = UI.GetHeadSelectedUnit()
            if not pUnit then return end
            --for beauty
            local VoltManager = self.VoltManager
            local damage = VoltManager:GetVoltDamage(pUnit)
            --get the detail
            UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                PlayerOperations.EXECUTE_SCRIPT, {
                    UnitID = pUnit:GetID(),
                    Damage = damage,
                    OnStart = 'EldridgeVoltage',
                }
            ); UI.PlaySound("Unit_CondemnHeretic_2D")
            Network.BroadcastPlayerInfo()
        end,
        --注册函数
        Register = function(self)
            Controls.Voltage:RegisterCallback(Mouse.eLClick, function() self:Callback() end)
            Controls.Voltage:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
        end
    }
}

--||====================base functions====================||--

--play voltage effect
function EldridgePlayVoltageEffect(x, y)
    WorldView.PlayEffectAtXY("ELDRIDGE_VOLTAGE", x, y)
end

--||===================Events functions===================||--

--When the unit is selected
function EldridgeOnUnitSelectChanged(playerId, unitId, locationX, locationY, locationZ, isSelected, isEditable)
    if isSelected and playerId == Game.GetLocalPlayer() then
        EldridgeUnitPanel:Reset()
    end
end

--On Unit Active
function EldridgeUnitActive(owner, unitID, x, y, eReason)
    local pUnit = UnitManager.GetUnit(owner, unitID)
    if eReason == voltageReason then
        EldridgeUnitPanel:Reset()
        SimUnitSystem.SetAnimationState(pUnit, "SPAWN", "IDLE")
        --get the unit x and y
        local uX, uY = pUnit:GetX(), pUnit:GetY()
        --play the effect
        WorldView.PlayEffectAtXY("ELDRIDGE_VOLTAGE_USER", uX, uY)
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
            Network.BroadcastPlayerInfo()
        end
    end
end

--||======================initialize======================||--

--Initialize
function Initialize()
    Events.LoadGameViewStateDone.Add(EldridgeOnLoadGameViewStateDone)
    Events.UnitSelectionChanged.Add(EldridgeOnUnitSelectChanged)
    Events.UnitActivate.Add(EldridgeUnitActive)
    ------------------------------------------
    Events.UnitAddedToMap.Add(EldridgeGridReset)
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
    Events.UnitRemovedFromMap.Add(EldridgeGridReset)

    Events.CityAddedToMap.Add(EldridgeGridReset)
    Events.CityRemovedFromMap.Add(EldridgeGridReset)
    ------------------------------------------
    Events.PhaseBegin.Add(EldridgeGridReset)
    Events.InterfaceModeChanged.Add(EldridgeUIModeChange)
    ------------------------------------------
    LuaEvents.WorldInput_WBSelectPlot.Add(EldridgeSelectPlot)
    ------------------------------------------
    ExposedMembers.Eldridge.PlayEffect = EldridgePlayVoltageEffect
    ------------------------------------------
    print('Initial success!')
end

include('EldridgeUnitPanel_', true)

Initialize()
