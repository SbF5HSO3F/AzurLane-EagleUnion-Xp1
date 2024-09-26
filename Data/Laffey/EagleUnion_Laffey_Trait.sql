-- EagleUnion_Laffey_NoBoost
-- Author: jjj
-- DateCreated: 2023/11/20 18:07:09
--------------------------------------------------------------
CREATE TABLE Laffey_NoBoost (
	NoBoostType TEXT
);

INSERT INTO Laffey_NoBoost
		(NoBoostType)
SELECT	TechnologyType
FROM Technologies WHERE TechnologyType NOT IN (SELECT TechnologyType FROM Boosts WHERE TechnologyType IS NOT NULL);

INSERT INTO Laffey_NoBoost
		(NoBoostType)
SELECT	CivicType
FROM Civics WHERE CivicType NOT IN (SELECT CivicType FROM Boosts WHERE CivicType IS NOT NULL);