-- StLouisUnitPanel
-- Author: HSbF6HSO3F
-- DateCreated: 2025/3/2 19:21:10
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')
include('EagleResources')

--||===================local variables====================||--

local resources = EagleResources:new({ ['RESOURCECLASS_LUXURY'] = true })

local Reason_1 = DB.MakeHash("STLOUIS_CREATED")
local Reason_2 = DB.MakeHash("STLOUIS_REMOVED")

--||======================MetaTable=======================||--

StLouisUnitPanel = {
    Refresh = function(self)
        local unit = UI.GetHeadSelectedUnit()
        if EagleCore.CheckLeaderMatched(
                Game.GetLocalPlayer(), 'LEADER_ST_LOUIS_CL49'
            ) and unit ~= nil then
            Controls.StLouisGrid:SetHide(false)
            self.Create:Refresh(unit)
            self.Remove:Refresh(unit)
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
            --reset the button
            self:Refresh()
        end
    end,
    Create = {
        --Get the detail
        GetDetail = function(unit)
            local detail = { Disable = true, Rescource = {}, Reason = '' }
            --the unit plot can place resource
            local plot = Map.GetPlot(unit:GetX(), unit:GetY())
            if plot:GetOwner() ~= -1 then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NOT_NO_OWNER')
                return detail
            end
            detail.Rescource = resources:GetPlaceableResources(plot)
            if #detail.Rescource == 0 then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NO_PLACEABLE_RESOURCES')
                return detail
            end
            detail.Disable = false
            return detail
        end,
        --refresh the button
        Refresh = function(self, unit)
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
        GetDetail = function(unit)
            local detail = { Disable = true, Reason = '' }
            local plot = Map.GetPlot(unit:GetX(), unit:GetY())
            if plot:GetResourceType() == -1 then
                detail.Reason = Locale.Lookup('LOC_STLOUIS_NO_PLACEABLE_RESOURCES')
                return detail
            end
            detail.Disable = false
            return detail
        end,
        Refresh = function(self, unit)
            local detail = self.GetDetail(unit)
            local disable = detail.Disable
            --set the button disable
            Controls.Remove:SetDisabled(disable)
            Controls.Remove:SetAlpha((disable and 0.7) or 1)
            --the tooltip
            local tooltip = Locale.Lookup('LOC_STLOUIS_REMOVE_TITLE')
                .. '[NEWLINE][NEWLINE]' .. Locale.Lookup('LOC_STLOUIS_REMOVE_DESC')
            if disable then
                tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. detail.Reason
            end
            --set the tooltip
            Controls.Remove:SetToolTipString(tooltip)
        end,
        Callback = function(self)
            local unit = UI.GetHeadSelectedUnit()
            if unit == nil then return end
            local detail = self.GetDetail(unit)
            if detail.Disable then return end
            local x, y = unit:GetX(), unit:GetY()
            UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                PlayerOperations.EXECUTE_SCRIPT, {
                    UnitID = unit:GetID(),
                    X = x,
                    Y = y,
                    OnStart = 'StLouisRemoved',
                }
            ); Network.BroadcastPlayerInfo()
        end,
        Register = function(self)
            Controls.Remove:RegisterCallback(Mouse.eLClick, function() self:Callback() end)
            Controls.Remove:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
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
        SimUnitSystem.SetAnimationState(pUnit, "SPAWN", "IDLE")
        --play the effect
        WorldView.PlayEffectAtXY("IMPROVEMENT_CREATED", uX, uY)
        WorldView.PlayEffectAtXY("EAGLE_CREATED", uX, uY)
    elseif eReason == Reason_2 then
        SimUnitSystem.SetAnimationState(pUnit, "SPAWN", "IDLE")
        --play the effect
        WorldView.PlayEffectAtXY("EAGLE_DESTROY", uX, uY)
        --play the sound
        UI.PlaySound("Unit_CondemnHeretic_2D")
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
