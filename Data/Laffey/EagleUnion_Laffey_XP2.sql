-- EagleUnion_Laffey_XP2
-- Author: HSbF6HSO3F
-- DateCreated: 2023/11/21 17:07:56
--------------------------------------------------------------
--Units_XP2
INSERT INTO Units_XP2
		(UnitType,				ResourceCost,	ResourceMaintenanceType,ResourceMaintenanceAmount)
VALUES	('UNIT_BENSON_CLASS',	1,				'RESOURCE_OIL',			1);

--Agendas
INSERT INTO TraitModifiers
		(TraitType,							ModifierId)
VALUES	('TRAIT_AGENDA_SOLOMON_S_NIGHT',	'SOLOMON_S_NIGHT_GRIEVANCE_DECAY');

INSERT INTO Modifiers
		(ModifierId,						ModifierType)
VALUES	('SOLOMON_S_NIGHT_GRIEVANCE_DECAY',	'MODIFIER_PLAYER_ADJUST_GRIEVANCE_DECAY');

INSERT INTO ModifierArguments
		(ModifierId,						Name,		Value)
VALUES	('SOLOMON_S_NIGHT_GRIEVANCE_DECAY',	'Amount',	'100');

--Update
UPDATE Agendas
SET Description = 'LOC_AGENDA_SOLOMON_S_NIGHT_DESCRIPTION_XP2'
WHERE AgendaType = 'AGENDA_SOLOMON_S_NIGHT';