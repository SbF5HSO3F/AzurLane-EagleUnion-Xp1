-- StLouisUnitPanel
-- Author: HSbF6HSO3F
-- DateCreated: 2025/3/2 19:21:10
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')
include('EagleResources')

--||===================local variables====================||--

local luxuries = EagleResources:new({ ["RESOURCECLASS_LUXURY"] = true })
local resources = EagleResources:new(true)

local explorer = GameInfo.Units['UNIT_ST_EXPLORER'].Index
local baseGold = 40
local Reason_1 = DB.MakeHash("STLOUIS_CREATED")
local Reason_2 = DB.MakeHash("STLOUIS_REMOVED")
local Reason_3 = DB.MakeHash("STLOUIS_IMPROVE")

--||======================MetaTable=======================||--

StLouisUnitPanel = {
    Refresh = function(self)
        local unit = UI.GetHeadSelectedUnit()
        if EagleCore.CheckLeaderMatched(
                Game.GetLocalPlayer(), 'LEADER_ST_LOUIS_CL49'
            ) and unit ~= nil and unit:GetType() == explorer then
            Controls.StLouisGrid:SetHide(false)
            self.Create:Refresh(unit)
            self.Remove:Refresh(unit)
            self.Improv:Refresh(unit)
        else
            Controls.StLouisGrid:SetHide(true)
        end
        --reset the Unit Panel
        ContextPtr:LookUpControl("/InGame/UnitPanel"):RequestRefresh()
    end,
    Init = function(self)
        local context = ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack")
        if context then
            --change the parent
            Controls.StLouisGrid:ChangeParent(context)
            --Register Callback
            self.Create:Register()
            self.Remove:Register()
            self.Improv:Register()
            --reset the button
            self:Refresh()
        end
    end,
    Create = {
        --Get the detail
        GetDetail = function(unit)
            local detail = { Disable = true, Rescource = {}, Reason = '' }
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
            detail.Rescource = luxuries:GetPlaceableResources(plot)
            if #detail.Rescource == 0 then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NO_PLACEABLE_RESOURCES')
                return detail
            end
            detail.Disable = false
            return detail
        end,
        --refresh the button
        Refresh = function(self, unit)
            if unit:GetActionCharges() > 0 then
                Controls.Create:SetHide(false)
                --get the detail
                local detail = self.GetDetail(unit)
                local disable = detail.Disable
                --set the button disable
                Controls.Create:SetDisabled(disable)
                Controls.Create:SetAlpha((disable and 0.7) or 1)
                --the tooltip
                local tooltip = Locale.Lookup('LOC_STLOUIS_CREATE_TITLE')
                    .. '[NEWLINE][NEWLINE]' .. Locale.Lookup('LOC_STLOUIS_CREATE_DESC')
                if disable then
                    tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. detail.Reason
                else
                    tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. Locale.Lookup('LOC_STLOUIS_CREATE_DETAIL')
                    for _, resource in ipairs(detail.Rescource) do
                        tooltip = tooltip .. Locale.Lookup('LOC_STLOUIS_CREATE_RESOURCE', resource.Icon, resource.Name)
                    end
                end
                --set the tooltip
                Controls.Create:SetToolTipString(tooltip)
            else
                Controls.Create:SetHide(true)
            end
        end,
        Callback = function(self)
            local unit = UI.GetHeadSelectedUnit()
            if unit == nil then return end
            local detail = self.GetDetail(unit)
            if detail.Disable then return end
            local x, y, list = unit:GetX(), unit:GetY(), {}
            for _, resource in ipairs(detail.Rescource) do
                table.insert(list, resource.Index)
            end
            UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                PlayerOperations.EXECUTE_SCRIPT, {
                    UnitID = unit:GetID(),
                    X = x,
                    Y = y,
                    List = list,
                    OnStart = 'StLouisCreated',
                }
            ); Network.BroadcastPlayerInfo()
        end,
        Register = function(self)
            Controls.Create:RegisterCallback(Mouse.eLClick, function() self:Callback() end)
            Controls.Create:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
        end
    },
    Remove = {
        GetGold = function(playerId)
            local percent = EagleCore:GetPlayerProgress(playerId)
            local gold = baseGold * (1 + 9 * percent / 100)
            return math.ceil(EagleCore:ModifyBySpeed(gold))
        end,
        GetDetail = function(self, unit)
            local detail = { Disable = true, Rescource = {}, Gold = 0, Reason = '' }
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
            detail.Rescource.Name = resourceDef.Name
            detail.Rescource.Icon = '[ICON_' .. resourceDef.ResourceType .. ']'
            detail.Gold = self.GetGold(unit:GetOwner())
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
                local resource = detail.Rescource
                tooltip = tooltip .. '[NEWLINE][NEWLINE]' ..
                    Locale.Lookup('LOC_STLOUIS_REMOVE_DETAIL', resource.Icon, resource.Name) ..
                    Locale.Lookup('LOC_STLOUIS_REMOVE_REWARD', detail.Gold)
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
                    UnitID  = unit:GetID(),
                    Gold    = detail.Gold,
                    X       = x,
                    Y       = y,
                    OnStart = 'StLouisRemoved',
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
