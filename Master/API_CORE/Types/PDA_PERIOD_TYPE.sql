CREATE OR REPLACE TYPE api_core."PDA_PERIOD_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.PDA_PERIOD_TYPE
--  DESCRIPTION : Description de l'objet type période
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.21 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
--          |
-- ***************************************************************************
(
  FILE_PDA_ID         VARCHAR2(30)                    -- IMPORT_PDA.T_XMLFILES.FILE_PDA_ID
, FILE_PDA_BUILD      VARCHAR2(50)                    --
, FILE_VERSION        VARCHAR2(35)                    -- IMPORT_PDA.T_XMLFILES.FILE_VERSION
, FILE_DTM            DATE                            -- IMPORT_PDA.T_XMLFILES.FILE_DTM
, TAB_PDA_PERIOD      api_core.TAB_COMMON_PERIOD_TYPE

, CONSTRUCTOR FUNCTION PDA_PERIOD_TYPE(SELF IN OUT NOCOPY PDA_PERIOD_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION MissingMandatoryAttributes(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."PDA_PERIOD_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.PDA_PERIOD_TYPE
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
CONSTRUCTOR FUNCTION PDA_PERIOD_TYPE(SELF IN OUT NOCOPY PDA_PERIOD_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := PDA_PERIOD_TYPE
      (  FILE_PDA_ID         => NULL
      ,  FILE_PDA_BUILD      => NULL
	  ,  FILE_VERSION        => NULL
	  ,  FILE_DTM            => NULL
	  ,  TAB_PDA_PERIOD      => NULL
      );

   RETURN;
END;

-- -----------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ea va renvoyer une liste vide) pour un traitement de Periode
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION MissingMandatoryAttributes ( p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   IF TRIM(self.FILE_VERSION) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_VERSION');
   END IF;
   IF TRIM(self.FILE_PDA_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_PDA_ID');
   END IF;
   IF TRIM(self.FILE_DTM) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_DTM');
   END IF;
   IF TRIM(self.FILE_PDA_BUILD) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_PDA_BUILD');
   END IF;
   IF (self.TAB_PDA_PERIOD) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'TAB_PDA_PERIOD');
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


END;

/