CREATE OR REPLACE TYPE api_core."OPENING_HOURS_TIME_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.OPENING_HOURS_TIME_TYPE
--  DESCRIPTION : Objet type représentant uniquement les heures
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.11.25 | Hocine HAMMOU
--          | Init
-- ***************************************************************************
(
OPEN_TIME    VARCHAR2(5)    -- IMPORT_PDA.T_OPENING_HOURS_IMPORTED.OPEN_TM%TYPE
,CLOSE_TIME   VARCHAR2(5)    -- IMPORT_PDA.T_OPENING_HOURS_IMPORTED.CLOSE_TM%TYPE
, CONSTRUCTOR FUNCTION OPENING_HOURS_TIME_TYPE(SELF IN OUT NOCOPY OPENING_HOURS_TIME_TYPE) RETURN SELF AS RESULT
)
INSTANTIABLE
FINAL

/
CREATE OR REPLACE TYPE BODY api_core."OPENING_HOURS_TIME_TYPE" IS
-- ***************************************************************************
--  TYPE BODY   : API_CORE.OPENING_HOURS_TIME_TYPE
--  DESCRIPTION : Méthodes de l'objet type représentant uniquement les heures
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.11.24 | Hocine HAMMOU
--          | Init
-- ***************************************************************************

CONSTRUCTOR FUNCTION OPENING_HOURS_TIME_TYPE(SELF IN OUT NOCOPY OPENING_HOURS_TIME_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := OPENING_HOURS_TIME_TYPE
          ( OPEN_TIME         => NULL
           ,CLOSE_TIME        => NULL
         );
   RETURN;
END;

END;

/