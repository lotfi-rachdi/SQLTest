CREATE OR REPLACE TYPE api_core."COMMON_MESSAGE_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.COMMON_MESSAGE_TYPE
--  DESCRIPTION : Description des attributs des MESSAGEs PDA reçu par WEB SERVICES.
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.21 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
-- ***************************************************************************
(

  PDA_MESSAGE_EVENT_ID   NUMBER                      -- exeple : 1017                                    -- IMPORT_PDA.T_MESSAGE_EVENT_IMPORTED.PDA_MESSAGE_EVENT_ID
, MESSAGE_ID             NUMBER                      -- exeple : 2670795                                 -- IMPORT_PDA.T_MESSAGE_EVENT_IMPORTED.MESSAGE_ID
, MESSAGE_EVENT_DTM      TIMESTAMP(6) WITH TIME ZONE -- exeple : 2016-04-20 16:09:13</MESSAGE_EVENT_DTM> -- IMPORT_PDA.T_MESSAGE_EVENT_IMPORTED.MESSAGE_EVENT_DTM
, MESSAGE_EVENT_TYPE_ID  VARCHAR2(50)                -- exeple : READ</MESSAGE_EVENT_TYPE_ID>            -- IMPORT_PDA.T_MESSAGE_EVENT_IMPORTED.MESSAGE_EVENT_TYPE_ID
, CONSTRUCTOR FUNCTION COMMON_MESSAGE_TYPE(SELF IN OUT NOCOPY COMMON_MESSAGE_TYPE) RETURN SELF AS RESULT
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."COMMON_MESSAGE_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.COMMON_MESSAGE_TYPE
--  DESCRIPTION : Description des attributs des MESSAGEs PDA reçu par WEB SERVICES.
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.22| Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION COMMON_MESSAGE_TYPE(SELF IN OUT NOCOPY COMMON_MESSAGE_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := COMMON_MESSAGE_TYPE
      (  PDA_MESSAGE_EVENT_ID    => NULL
      ,  MESSAGE_ID              => NULL
      ,  MESSAGE_EVENT_DTM       => NULL
      ,  MESSAGE_EVENT_TYPE_ID   => NULL
      );

   RETURN;
END;

END;

/