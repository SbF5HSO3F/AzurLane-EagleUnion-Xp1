-- EagleUnionEnterpriseUnitPanel
-- Author: HSbF6HSO3F
-- DateCreated: 2025/2/16 21:29:35
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')

--||==================global variables====================||--

KeyRecover = 'EnterpriseRecoverTurns'
Reason_1 = DB.MakeHash('ENTERPRISE_RECOVER')

--||======================MetaTable=======================||--

EnterpriseUnitPanel = {
    --refresh all
    Refresh = function(self)
        --get the unit
        local pUnit = UI.GetHeadSelectedUnit()
        --check the leader is Eldridge
        if pUnit and EagleCore.CheckLeaderMatched(
                Game.GetLocalPlayer(), 'LEADER_ENTERPRISE_CV6'
            ) and EagleCore.IsMilitary(pUnit)
        then
            Controls.EnterpriseGrid:SetHide(false)
            --reset the buttons
            self.Recover:Refresh(pUnit)
        else
            --hide the grid
            Controls.EnterpriseGrid:SetHide(true)
        end
        --reset the Unit Panel
        ContextPtr:LookUpControl("/InGame/UnitPanel"):RequestRefresh()
    end,
    --init
    Init = function(self)
        local context = ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack")
        if context then
            --change the parent
            Controls.EnterpriseGrid:ChangeParent(context)
            --Register Callback
            self.Recover:Register()
            --reset the button
            self:Refresh()
        end
    end,
    --buttons
    --recover
    Recover = {
        --get the detail
        GetDetail = function(pUnit)
            --the detail
            local detail = { Disable = true, Reason = '' }
            --get the unit property
            local turns = pUnit:GetProperty(KeyRecover) or 0
            --check the turns
            if turns >= Game.GetCurrentGameTurn() then
                detail.Reason = Locale.Lookup('LOC_ENTERPRISE_REASON_HAS_USED')
                return detail
            end
            --check the unit Hp
            if pUnit:GetDamage() > 0 then
                detail.Disable = false
            else
                detail.Reason = Locale.Lookup('LOC_ENTERPRISE_REASON_NO_DAMAGE')
            end
            return detail
        end,
        --refresh the button
        Refresh = function(self, pUnit)
            --check the leader
            if pUnit and EagleCore.CheckLeaderMatched(
                    pUnit:GetOwner(), 'LEADER_ENTERPRISE_CV6'
                ) and EagleCore.IsMilitary(pUnit) then
                --show the button
                Controls.Recover:SetHide(false)
                --get the detail
                local detail = self.GetDetail(pUnit)
                local disable = detail.Disable
                --set the button
                Controls.Recover:SetDisabled(disable)
                Controls.Recover:SetAlpha((disable and 0.7) or 1)
                --the tooltip
                local tooltip = Locale.Lookup('LOC_ENTERPRISE_TITLE') ..
                    '[NEWLINE][NEWLINE]' .. Locale.Lookup('LOC_ENTERPRISE_RECOVER_DESC')
                if disable then
                    tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. detail.Reason
                end
                --set the tooltip
                Controls.Recover:SetToolTipString(tooltip)
                return true
            else
                --hide the button
                Controls.Recover:SetHide(true)
                return false
            end
        end,
        --handle the button click
        Callback = function(self)
            --get the unit
            local pUnit = UI.GetHeadSelectedUnit()
            --check the unit
            if not pUnit then return end
            local detail = self.GetDetail(pUnit)
            --check the detail
            if detail.Disable then return end
            UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                PlayerOperations.EXECUTE_SCRIPT, {
                    UnitID = pUnit:GetID(),
                    OnStart = 'EnterpriseRecover',
                }
            ); Network.BroadcastPlayerInfo()
        end,
        --register
        Register = function(self)
            Controls.Recover:RegisterCallback(Mouse.eLClick, function() self:Callback() end)
            Controls.Recover:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
        end
    }
}

--||===================Events functions===================||--

--refresh the panel
function EnterpriseRefresh()
    EnterpriseUnitPanel:Refresh()
end

--When the unit is selected
function EnterpriseUnitSelectChanged(playerId, unitId, locationX, locationY, locationZ, isSelected, isEditable)
    if isSelected and playerId == Game.GetLocalPlayer() then
        EnterpriseUnitPanel:Refresh()
    end
end

--On Unit Active
function EnterpriseUnitActive(owner, unitID, x, y, eReason)
    local pUnit = UnitManager.GetUnit(owner, unitID)
    if eReason == Reason_1 then
        SimUnitSystem.SetAnimationState(pUnit, "SPAWN", "IDLE")
        --get the unit x and y
        local uX, uY = pUnit:GetX(), pUnit:GetY()
        --play the effect
        WorldView.PlayEffectAtXY("ENTERPRISE_RECOVER", uX, uY)
        --refersh the panel
        EnterpriseUnitPanel:Refresh()
    end
end

--Add a button to Unit Panel
function EnterpriseAddButton()
    EnterpriseUnitPanel:Init()
end

--||======================initialize======================||--

--Initialize
function Initialize()
    Events.LoadGameViewStateDone.Add(EnterpriseAddButton)
    Events.UnitSelectionChanged.Add(EnterpriseUnitSelectChanged)
    Events.UnitActivate.Add(EnterpriseUnitActive)
    ------------------------------------------
    Events.UnitAddedToMap.Add(EnterpriseRefresh)
    Events.UnitOperationSegmentComplete.Add(EnterpriseRefresh)
    Events.UnitCommandStarted.Add(EnterpriseRefresh)
    Events.UnitDamageChanged.Add(EnterpriseRefresh)
    Events.UnitMoveComplete.Add(EnterpriseRefresh)
    Events.UnitChargesChanged.Add(EnterpriseRefresh)
    Events.UnitPromoted.Add(EnterpriseRefresh)
    Events.UnitOperationsCleared.Add(EnterpriseRefresh)
    Events.UnitOperationAdded.Add(EnterpriseRefresh)
    Events.UnitOperationDeactivated.Add(EnterpriseRefresh)
    Events.UnitMovementPointsChanged.Add(EnterpriseRefresh)
    Events.UnitMovementPointsCleared.Add(EnterpriseRefresh)
    Events.UnitMovementPointsRestored.Add(EnterpriseRefresh)
    Events.UnitAbilityLost.Add(EnterpriseRefresh)
    Events.UnitRemovedFromMap.Add(EnterpriseRefresh)
    ------------------------------------------
    Events.PhaseBegin.Add(EnterpriseRefresh)
    ------------------------------------------
    print('Initial success!')
end

include('EagleUnionEnterpriseUnitPanel_', true)

Initialize()
