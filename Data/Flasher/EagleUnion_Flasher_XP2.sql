-- EagleUnion_Flasher_XP2
-- Author: HSbF6HSO3F
-- DateCreated: 2024/3/8 18:36:41
--------------------------------------------------------------
--Update Units
UPDATE Units
SET StrategicResource='RESOURCE_OIL'
WHERE UnitType='UNIT_GATO_CLASS';

--Units_XP2
INSERT INTO Units_XP2
	(UnitType,			ResourceCost,	ResourceMaintenanceType,ResourceMaintenanceAmount)
VALUES
	('UNIT_GATO_CLASS',	1,				'RESOURCE_OIL',			1);