CREATE OR REPLACE TYPE api_core."LOG_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.LOG_TYPE
--  DESCRIPTION : Description des attributs du message de type LOG
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.07.05 | Hocine HAMMOU
--          | Init
--          |
-- ***************************************************************************
(
  INTERNATIONAL_SITE_ID          VARCHAR2(35)
, LOCAL_DTM                      TIMESTAMP(6) WITH TIME ZONE        -- L'API ENVOIE AU BO LA DATE/HEURE UTC
, TAB_LINES_LOG                  api_core.TAB_ELEMENT_VARCHAR_TYPE
, CONSTRUCTOR FUNCTION LOG_TYPE(SELF IN OUT NOCOPY LOG_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION MissingMandatoryAttributes (SELF in LOG_TYPE) RETURN VARCHAR2

)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."LOG_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.LOG_TYPE
--  DESCRIPTION : Description des attributs du message de type LOG
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.07.05 | Hocine HAMMOU
--          | Init
--          |
-- ***************************************************************************
IS

   CONSTRUCTOR FUNCTION LOG_TYPE(SELF IN OUT NOCOPY LOG_TYPE) RETURN SELF AS RESULT
   IS
   BEGIN
      SELF := LOG_TYPE
         (
           INTERNATIONAL_SITE_ID => NULL
         , LOCAL_DTM             => NULL
         , TAB_LINES_LOG         => NULL
         );
      RETURN;
   END;

   -- -----------------------------------------------------------------------------
   -- Fonction MissingMandatoryAttributes :
   --    Renvoie la liste d'attributs en erreur parce qu'obligatoires et non informés
   --    (donc si tout est ok ça retourne une liste vide, sinon ça retourne une liste renseigné avec les champs en défaut )
   -- -----------------------------------------------------------------------------
   MEMBER FUNCTION MissingMandatoryAttributes ( SELF IN LOG_TYPE ) RETURN VARCHAR2
   IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
      l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
      l_result VARCHAR2(4000);
   BEGIN

      IF TRIM(self.INTERNATIONAL_SITE_ID) IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'INTERNATIONAL_SITE_ID');
      END IF;

      IF TRIM(self.LOCAL_DTM) IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'LOCAL_DTM');
      END IF;

      IF self.TAB_LINES_LOG IS NULL THEN
         l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'TAB_LINES_LOG');
      END IF;

      RETURN l_result;
   EXCEPTION
      WHEN OTHERS THEN
         MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
         RAISE;
   END;


END;

/