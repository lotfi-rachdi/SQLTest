CREATE OR REPLACE TYPE api_core."PDA_CONFIG_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.PDA_CONFIG_TYPE
--  DESCRIPTION : Description de l'objet type CONFIG
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.21 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
--          |
-- ***************************************************************************
(
  FILE_PDA_ID          VARCHAR2(30)                        --> actuellement dans le filename, 3ème position
, FILE_PDA_BUILD       VARCHAR2(50)                        --> actuellement dans le filename, 4ème position
, FILE_VERSION         VARCHAR2(35)                        --> actuellement dans le filename, 5ème position
, FILE_DTM             DATE                                --> actuellement dans le filename, 6ème position
, TAB_PDA_CONFIG       api_core.TAB_PROPERTY_TYPE
, CONSTRUCTOR FUNCTION PDA_CONFIG_TYPE(SELF IN OUT NOCOPY PDA_CONFIG_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION MissingMandatoryAttributes (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."PDA_CONFIG_TYPE" 
-- ***************************************************************************
--  TYPE        : API_CORE.PDA_CONFIG_TYPE
--  DESCRIPTION : Description de l'objet type CONFIG
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.22 | Hocine HAMMOU
--          | Init  Projet [10326] Migration PDA vers WebAPI
--          |
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION PDA_CONFIG_TYPE(SELF IN OUT NOCOPY PDA_CONFIG_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := PDA_CONFIG_TYPE
         ( FILE_PDA_ID      => NULL
         , FILE_PDA_BUILD   => NULL
         , FILE_VERSION     => NULL
         , FILE_DTM         => NULL
         , TAB_PDA_CONFIG   => NULL
         );

   RETURN;
END;


 -- -------------------------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 -- fonction qui check la validité du message
 -- retourne la liste des attributes en erreur parce qu'obligatoires et non informés
 -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION MissingMandatoryAttributes (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   IF TRIM(FILE_VERSION) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_VERSION');
   END IF;

   IF TRIM(FILE_PDA_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_PDA_ID');
   END IF;

   IF TRIM(FILE_DTM) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_DTM');
   END IF;

   IF TRIM(FILE_PDA_BUILD) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'FILE_PDA_BUILD');
   END IF;

   IF (TAB_PDA_CONFIG) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'TAB_PDA_CONFIG');
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


END;

/