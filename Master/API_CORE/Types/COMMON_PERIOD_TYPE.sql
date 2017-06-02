CREATE OR REPLACE TYPE api_core."COMMON_PERIOD_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.COMMON_PERIOD_TYPE
--  DESCRIPTION : Description des attributs des PERIODES PDA reçu par WEB SERVICES.
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.21 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
-- ***************************************************************************
(
  BO_PERIOD_ID          NUMBER                       -- MASTER.PERIOD.PERIOD_ID
, PDA_PERIOD_ID         NUMBER                       -- MASTER.PERIOD.PDA_PERIOD_ID%TYPE
, START_DTM             DATE                         -- MASTER.PERIOD.DATE_FROM
, END_DTM               DATE                         -- MASTER.PERIOD.DATE_TO
, PERIOD_TYPE_ID        NUMBER(1)                    -- MASTER.PERIOD.PERIOD_TYPE_ID   ( 1:VACATION / 4:USUAL_VACATION_PLAN ) (cf. CONFIG.PERIOD_TYPE) -- ATTENTION A CETTE ATTRIBUT CAR NOM PRESQUE IDENTIQUE AU NOM DU TYPE
, LAST_UPDATE_DTM       TIMESTAMP(6) WITH TIME ZONE  -- MASTER.PERIOD.LAST_UPDATE_DTM   --TIMESTAMP(6) WITH TIME ZONE
, DELETED_DTM           TIMESTAMP(6) WITH TIME ZONE  -- MASTER.PERIOD.DELETED           --TIMESTAMP(6) WITH TIME ZONE ?? actuellement si date rensigné alors a supprimer (NULL ou 0: NOT DELETED / 1:DELETED )
, CONSTRUCTOR FUNCTION COMMON_PERIOD_TYPE(SELF IN OUT NOCOPY COMMON_PERIOD_TYPE) RETURN SELF AS RESULT
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."COMMON_PERIOD_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.COMMON_PERIOD_TYPE
--  DESCRIPTION : Description ....
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.15 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
--
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION COMMON_PERIOD_TYPE(SELF IN OUT NOCOPY COMMON_PERIOD_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := COMMON_PERIOD_TYPE
      (  BO_PERIOD_ID         => NULL
      ,  PDA_PERIOD_ID        => NULL
      ,  START_DTM            => NULL
      ,  END_DTM              => NULL
      ,  PERIOD_TYPE_ID       => NULL
      ,  LAST_UPDATE_DTM      => NULL
      ,  DELETED_DTM          => NULL
      );

   RETURN;
END;

END;

/