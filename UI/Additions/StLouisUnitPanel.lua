-- StLouisUnitPanel
-- Author: HSbF6HSO3F
-- DateCreated: 2025/3/2 19:21:10
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')
include('EagleResources')

include('InstanceManager');

--||===================local variables====================||--

local luxuries = EagleResources:new({ ["RESOURCECLASS_LUXURY"] = true })
local resources = EagleResources:new(true)

local m_ResourceIM = InstanceManager:new("ResourceColumnInstance", "Top", Controls.ResourcesStack);

local explorer = GameInfo.Units['UNIT_ST_EXPLORER'].Index
local Reason_1 = DB.MakeHash("STLOUIS_CREATED")
local Reason_2 = DB.MakeHash("STLOUIS_REMOVED")
local Reason_3 = DB.MakeHash("STLOUIS_IMPROVE")

--||======================MetaTable=======================||--

StLouisUnitPanel = {
    Refresh = function(self)
        local unit = UI.GetHeadSelectedUnit()
        if unit ~= nil and unit:GetType() == explorer then
            Controls.ResourcePanel:SetHide(false)
            self.Create:Refresh(unit)
            Controls.StLouisGrid:SetHide(false)
            self.Remove:Refresh(unit)
            self.Improv:Refresh(unit)
        else
            Controls.ResourcePanel:SetHide(true)
            Controls.StLouisGrid:SetHide(true)
        end
        --reset the Unit Panel
        ContextPtr:LookUpControl("/InGame/UnitPanel"):RequestRefresh()
    end,
    Init = function(self)
        local PanelSlide = ContextPtr:LookUpControl("/InGame/UnitPanel/UnitPanelSlide")
        if PanelSlide then
            --change the parent
            Controls.ResourcePanel:ChangeParent(PanelSlide)
        end
        local ActionStack = ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack")
        if ActionStack then
            --change the parent
            Controls.StLouisGrid:ChangeParent(ActionStack)
            --Register Callback
            self.Remove:Register()
            self.Improv:Register()
        end
        --reset the button
        self:Refresh()
    end,
    Create = {
        --Get the detail
        GetDetail = function(unit)
            local detail = { Disable = true, Recource = {}, Reason = '' }
            --get the unit remain movenment
            if unit:GetMovesRemaining() == 0 then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NO_MOVES')
                return detail
            end
            --the unit plot can place resource
            local plot = Map.GetPlot(unit:GetX(), unit:GetY())
            if plot:GetOwner() ~= -1 then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NOT_NO_OWNER')
                return detail
            end
            --the plot has resource
            local index = plot:GetResourceType()
            local resourceHash = plot:GetResourceTypeHash()
            local resourceData = Players[unit:GetOwner()]:GetResources()
            if index ~= -1 and resourceData:IsResourceVisible(resourceHash) then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_HAS_RESOURCES')
                return detail
            end
            --get the placeable luxuries
            detail.Recource = luxuries:GetPlaceableResources(plot)
            if #detail.Recource == 0 then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NO_PLACEABLE_RESOURCES')
                return detail
            end
            detail.Disable = false
            return detail
        end,
        --refresh the button
        Refresh = function(self, unit)
            m_ResourceIM:DestroyInstances()
            m_ResourceIM:ResetInstances()
            if unit:GetActionCharges() > 0 then
                Controls.ResourcePanel:SetHide(false)
                --get the detail
                local detail = self.GetDetail(unit)
                local count = #detail.Recource
                if count == 0 then
                    Controls.ResourcePanel:SetHide(true)
                    return
                end
                for i = 1, count, 3 do
                    local columnInstance = m_ResourceIM:GetInstance()
                    for iRow = 1, 3, 1 do
                        if (i + iRow) - 1 <= count then
                            local resource = detail.Recource[i + iRow - 1]
                            local slotName = "Row" .. tostring(iRow)
                            local instance = {}
                            ContextPtr:BuildInstanceForControl("ResourceInstance", instance, columnInstance[slotName])
                            -- the resource icon
                            instance.ResourceIcon:SetIcon('ICON_' .. resource.Type)
                            -- callback
                            instance.ResourceButton:RegisterCallback(Mouse.eLClick,
                                function()
                                    local pUnit = UI.GetHeadSelectedUnit()
                                    if pUnit == nil then return end
                                    local x, y = pUnit:GetX(), pUnit:GetY()
                                    UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                                        PlayerOperations.EXECUTE_SCRIPT, {
                                            UnitID = pUnit:GetID(),
                                            X = x,
                                            Y = y,
                                            Index = resource.Index,
                                            OnStart = 'StLouisCreated',
                                        }
                                    ); Network.BroadcastPlayerInfo()
                                end
                            )
                            -- tooltip
                            local tooltip = Locale.Lookup('LOC_STLOUIS_CREATE_RESOURCE', resource.Icon, resource.Name)
                            tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. resource:GetChangeYieldsTooltip()
                            instance.ResourceButton:SetToolTipString(tooltip)
                        end
                    end
                end
                local RES_PANEL_ART_PADDING_X = 24;
                local RES_PANEL_ART_PADDING_Y = 20;
                Controls.ResourcesStack:CalculateSize();
                local stackWidth  = Controls.ResourcesStack:GetSizeX();
                local stackHeight = Controls.ResourcesStack:GetSizeY();
                Controls.ResourcePanel:SetSizeX(stackWidth + RES_PANEL_ART_PADDING_X)
                Controls.ResourcePanel:SetSizeY(stackHeight + RES_PANEL_ART_PADDING_Y)
            else
                Controls.ResourcePanel:SetHide(true)
            end
        end
    },
    Remove = {
        GetDetail = function(self, unit)
            local detail = { Disable = true, Recource = {}, Harvest = '', Reason = '' }
            --get the unit remain movenment
            if unit:GetMovesRemaining() == 0 then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NO_MOVES')
                return detail
            end
            --get the plot
            local plot = Map.GetPlot(unit:GetX(), unit:GetY())
            local resource = plot:GetResourceType()
            local resourceHash = plot:GetResourceTypeHash()
            local resourceData = Players[unit:GetOwner()]:GetResources()
            --the plot has resource?
            if resource == -1 or resourceData:IsResourceVisible(resourceHash) == false then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NO_PLACEABLE_RESOURCES')
                return detail
            end
            local resourceDef = GameInfo.Resources[resourceHash]
            detail.Recource.Name = resourceDef.Name
            detail.Recource.Type = resourceDef.ResourceType
            detail.Recource.Icon = '[ICON_' .. resourceDef.ResourceType .. ']'
            local resourceStru = resources:GetResource(resourceDef.ResourceType)
            detail.Harvest = resourceStru:GetHarvestYieldsTooltip(unit:GetOwner())
            detail.Disable = false
            return detail
        end,
        Refresh = function(self, unit)
            local detail = self:GetDetail(unit)
            local disable = detail.Disable
            --set the button disable
            Controls.Remove:SetDisabled(disable)
            Controls.Remove:SetAlpha((disable and 0.7) or 1)
            --the tooltip
            local tooltip = Locale.Lookup('LOC_STLOUIS_REMOVE_TITLE')
                .. '[NEWLINE][NEWLINE]' .. Locale.Lookup('LOC_STLOUIS_REMOVE_DESC')
            if disable then
                tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. detail.Reason
            else
                local resource = detail.Recource
                tooltip = tooltip .. '[NEWLINE][NEWLINE]' ..
                    Locale.Lookup('LOC_STLOUIS_REMOVE_DETAIL', resource.Icon, resource.Name) ..
                    detail.Harvest
            end
            --set the tooltip
            Controls.Remove:SetToolTipString(tooltip)
        end,
        Callback = function(self)
            local unit = UI.GetHeadSelectedUnit()
            if unit == nil then return end
            local detail = self:GetDetail(unit)
            if detail.Disable then return end
            local x, y = unit:GetX(), unit:GetY()
            UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                PlayerOperations.EXECUTE_SCRIPT, {
                    UnitID   = unit:GetID(),
                    Recource = detail.Recource.Type,
                    X        = x,
                    Y        = y,
                    OnStart  = 'StLouisRemoved',
                }
            ); Network.BroadcastPlayerInfo()
        end,
        Register = function(self)
            Controls.Remove:RegisterCallback(Mouse.eLClick, function() self:Callback() end)
            Controls.Remove:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
        end
    },
    Improv = {
        GetDetail = function(unit)
            local detail = { Disable = true, Improvement = {}, Reason = '' }
            --get the unit remain movenment
            if unit:GetMovesRemaining() == 0 then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NO_MOVES')
                return detail
            end
            local x, y = unit:GetX(), unit:GetY()
            --get the plot
            local plot = Map.GetPlot(x, y)
            --the plot is no owner
            if plot:GetOwner() ~= -1 then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NOT_NO_OWNER')
                return detail
            end
            --the plot has resource
            local resourceType = plot:GetResourceType()
            local resourceHash = plot:GetResourceTypeHash()
            local resourceData = Players[unit:GetOwner()]:GetResources()
            if resourceType == -1 or resourceData:IsResourceVisible(resourceHash) == false then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NO_PLACEABLE_RESOURCES')
                return detail
            end
            --get the next owner plot
            local adjacentOwner = false
            for _, tplot in ipairs(Map.GetAdjacentPlots(x, y)) do
                if tplot:GetOwner() == unit:GetOwner() then
                    adjacentOwner = true
                    break
                end
            end
            if adjacentOwner == false then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NO_ADJACENT_OWNER')
                return detail
            end
            --get the improvement
            local resDef = GameInfo.Resources[resourceHash]
            local resource = resources:GetResource(resDef.ResourceType)
            local improvement = resource:GetImprovement(plot)
            if not improvement or not next(improvement) then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NO_IMPROVEMENT')
                return detail
            end
            detail.Improvement = improvement
            detail.Disable = false
            return detail
        end,
        Refresh = function(self, unit)
            --get the detail
            local detail = self.GetDetail(unit)
            --set the button disable
            local disable = detail.Disable
            Controls.Improv:SetDisabled(disable)
            Controls.Improv:SetAlpha((disable and 0.7) or 1)
            --set the button icon
            local imTooltip, improvement = '', detail.Improvement
            if improvement and improvement.Icon then
                Controls.ImprovIcon:SetIcon(improvement.Icon)
                imTooltip = Locale.Lookup('LOC_STLOUIS_IMPROVEMENT', improvement.Name)
            else
                Controls.ImprovIcon:SetIcon('ICON_STLOUIS_IMPROV')
            end
            --the tooltip
            local tooltip = Locale.Lookup('LOC_STLOUIS_IMPROV_TITLE')
                .. '[NEWLINE][NEWLINE]' .. Locale.Lookup('LOC_STLOUIS_IMPROV_DESC')
            if imTooltip ~= '' then
                tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. imTooltip
            end
            if disable then
                tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. detail.Reason
            end
            --set the tooltip
            Controls.Improv:SetToolTipString(tooltip)
        end,
        Callback = function(self)
            local unit = UI.GetHeadSelectedUnit()
            if unit == nil then return end
            local detail = self.GetDetail(unit)
            if detail.Disable then return end
            local x, y = unit:GetX(), unit:GetY()
            UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                PlayerOperations.EXECUTE_SCRIPT, {
                    UnitID  = unit:GetID(),
                    X       = x,
                    Y       = y,
                    Index   = detail.Improvement.Index,
                    OnStart = 'StLouisImprove',
                }
            ); Network.BroadcastPlayerInfo()
        end,
        Register = function(self)
            Controls.Improv:RegisterCallback(Mouse.eLClick, function() self:Callback() end)
            Controls.Improv:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
        end
    }
}

--||===================Events functions===================||--

--refresh the panel
function StLouisRefresh()
    StLouisUnitPanel:Refresh()
end

--When the unit is selected
function StLouisUnitSelectChanged(playerId, unitId, locationX, locationY, locationZ, isSelected, isEditable)
    if isSelected and playerId == Game.GetLocalPlayer() then
        StLouisUnitPanel:Refresh()
    end
end

--On Unit Active
function StLouisUnitActive(owner, unitID, x, y, eReason)
    local pUnit = UnitManager.GetUnit(owner, unitID)
    if pUnit == nil then return end
    --get the unit x and y
    local uX, uY = pUnit:GetX(), pUnit:GetY()
    if eReason == Reason_1 then
        SimUnitSystem.SetAnimationState(pUnit, "ACTION_1", "IDLE")
        --play the effect
        WorldView.PlayEffectAtXY("IMPROVEMENT_CREATED", uX, uY)
        WorldView.PlayEffectAtXY("EAGLE_CREATED", uX, uY)
    elseif eReason == Reason_2 then
        SimUnitSystem.SetAnimationState(pUnit, "ACTION_2", "IDLE")
        --play the effect
        WorldView.PlayEffectAtXY("IMPROVEMENT_CREATED", uX, uY)
        WorldView.PlayEffectAtXY("EAGLE_DESTROY", uX, uY)
    elseif eReason == Reason_3 then
        SimUnitSystem.SetAnimationState(pUnit, "ACTION_1", "IDLE")
    end
    --refersh the panel
    StLouisUnitPanel:Refresh()
end

--Add a button to Unit Panel
function StLouisAddButton()
    StLouisUnitPanel:Init()
end

--||======================initialize======================||--

--Initialize
function Initialize()
    Events.LoadGameViewStateDone.Add(StLouisAddButton)
    Events.UnitSelectionChanged.Add(StLouisUnitSelectChanged)
    Events.UnitActivate.Add(StLouisUnitActive)
    ------------------------------------------
    Events.UnitAddedToMap.Add(StLouisRefresh)
    Events.UnitOperationSegmentComplete.Add(StLouisRefresh)
    Events.UnitCommandStarted.Add(StLouisRefresh)
    Events.UnitDamageChanged.Add(StLouisRefresh)
    Events.UnitMoveComplete.Add(StLouisRefresh)
    Events.UnitChargesChanged.Add(StLouisRefresh)
    Events.UnitPromoted.Add(StLouisRefresh)
    Events.UnitOperationsCleared.Add(StLouisRefresh)
    Events.UnitOperationAdded.Add(StLouisRefresh)
    Events.UnitOperationDeactivated.Add(StLouisRefresh)
    Events.UnitMovementPointsChanged.Add(StLouisRefresh)
    Events.UnitMovementPointsCleared.Add(StLouisRefresh)
    Events.UnitMovementPointsRestored.Add(StLouisRefresh)
    Events.UnitAbilityLost.Add(StLouisRefresh)
    Events.UnitRemovedFromMap.Add(StLouisRefresh)
    ------------------------------------------
    Events.ResourceAddedToMap.Add(StLouisRefresh)
    Events.PlayerResourceChanged.Add(StLouisRefresh)
    Events.ResourceRemovedFromMap.Add(StLouisRefresh)
    ------------------------------------------
    Events.PhaseBegin.Add(StLouisRefresh)
    ------------------------------------------
    print('Initial success!')
end

include('StLouisUnitPanel_', true)

Initialize()
