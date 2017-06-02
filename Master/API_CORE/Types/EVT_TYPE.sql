CREATE OR REPLACE TYPE api_core."EVT_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.EVT_TYPE
--  DESCRIPTION : Description des attibuts d'évenèment reçu par WEB SERVICES
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.23 | Maria CASALS
--          | Init
--          |
--  V01.100 | 2015.06.24 | Maria CASALS
--          | Les colonnes EVENT_ID et PARCEL_KNOWN disparaissent
--          | LOCAL_DTM devient DATE (donc datetime jusqu'à la seconde)
--          |
--  V01.200 | 2015.07.10 | Hocine HAMMOU
--          | Ajout de la donnée INTERNATIONAL_SITE_ID en remplacement de SITE_ID
--          |
--  V01.200 | 2015.12.31 | Hocine HAMMOU
--          | LOCAL_DTM changement format DATE en TIMESTAMP(6) WITH TIME ZONE
-- ***************************************************************************

(
--2015.06.24 EVENT_ID disparait
--EVENT_ID                       INTEGER                     -- used as INPUT column, it is the local id for the event -> IMPORT_PDA.T_EVENT_IMPORTED.PDA_EVENT_ID
  FIRM_PARCEL_ID                 VARCHAR2(50)                -- used as INPUT column -> IMPORT_PDA.T_EVENT_IMPORTED.FIRM_PARCEL_ID
, BO_PARCEL_ID                   NUMBER                      -- used as INPUT column -> IMPORT_PDA.T_EVENT_IMPORTED.BO_PARCEL_ID
, FIRM_ID                        VARCHAR2(50)                -- used as INPUT column -> IMPORT_PDA.T_EVENT_IMPORTED.FIRM_ID
--2015.06.24 PARCEL_KNOWN disparait
--PARCEL_KNOWN                   NUMBER(1)                   -- used as INPUT column - Flag 1/0 --> IMPORT_PDA.T_EVENT_IMPORTED.PARCEL_KNOWN
--2015.12.31 changement format DATE en TIMESTAMP(6) WITH TIME ZONE
--LOCAL_DTM                      DATE
, LOCAL_DTM                      TIMESTAMP(6) WITH TIME ZONE -- used as INPUT column; local date -> IMPORT_PDA.T_EVENT_IMPORTED.DTM / IMPORT_PDA.T_XMLFILES.FILE_DTM
--2015-07-10 remplacé
-- SITE_ID                       INTEGER                     -- used as INPUT column, it is the SITE_ID where the event comes from -> IMPORT_PDA.T_XMLFILES.FILE_PDA_ID
, INTERNATIONAL_SITE_ID          VARCHAR2(35)                -- used as INPUT column, instead of SITE_ID where the event comes from -> IMPORT_PDA.T_XMLFILES.FILE_PDA_ID

, CONSTRUCTOR FUNCTION EVT_TYPE(SELF IN OUT NOCOPY EVT_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION MissingMandatoryEvtAttributes (self in EVT_TYPE) RETURN VARCHAR2

)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."EVT_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.EVT_TYPE
--  DESCRIPTION : Description des attibuts d'évenèment du fichier reçu
--                par WEB SERVICES.
-- 				  API_CORE.EVT_TYPE est un sous-type de API_CORE.ENTRY_FILE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.06.11 | Maria CASALS
--          | Init
--          |
--  V01.100 | 2015.06.24 | Maria CASALS
--          | Les colonnes EVENT_ID et PARCEL_KNOWN disparaissent
--          |
--  V01.200 | 2015.07.10 | Hocine HAMMOU
--          | Ajout de la donnée INTERNATIONAL_SITE_ID en remplacement de SITE_ID
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION EVT_TYPE(SELF IN OUT NOCOPY EVT_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := EVT_TYPE
      (  -- 2015.06.24 disparait -- EVENT_ID           => NULL
        FIRM_PARCEL_ID     => NULL
      , BO_PARCEL_ID       => NULL
      , FIRM_ID            => NULL
      -- 2015.06.24 disparait -- , PARCEL_KNOWN       => NULL
      , LOCAL_DTM          => NULL
      -- 2015-07-10 remplacé , SITE_ID            => NULL
      , INTERNATIONAL_SITE_ID            => NULL
      );
   RETURN;
END;



 -- -----------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ça va renvoyer une liste vide) pour un PICKUP STANDARD
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION MissingMandatoryEvtAttributes (self in EVT_TYPE) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN
   IF TRIM(self.FIRM_PARCEL_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FIRM_PARCEL_ID');
   END IF;

   IF TRIM(self.FIRM_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FIRM_ID');
   END IF;

   IF LOCAL_DTM IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'LOCAL_DTM');
   END IF;

   IF INTERNATIONAL_SITE_ID IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'INTERNATIONAL_SITE_ID');
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;
END;

/