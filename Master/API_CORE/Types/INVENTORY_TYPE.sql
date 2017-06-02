CREATE OR REPLACE TYPE api_core."INVENTORY_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.INVENTORY_TYPE
--  DESCRIPTION : Description de l'objet type INVENTORY
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2016.11.28 | Hocine HAMMOU
--          | [10472] Mise en place de l'inventaire matériel ( sacoches...)
--          |
-- ***************************************************************************
(
INTERNATIONAL_SITE_ID  VARCHAR2(35)                 -- MASTER.SITE.SITE_INTERNATIONAL_ID
,TAB_INVENTORY api_core.TAB_COMMON_INVENTORY_TYPE

, CONSTRUCTOR FUNCTION INVENTORY_TYPE(SELF IN OUT NOCOPY INVENTORY_TYPE) RETURN SELF AS RESULT

, MEMBER FUNCTION MissingMandatoryAttributes(p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."INVENTORY_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.INVENTORY_TYPE
--  DESCRIPTION : Méthodes de l'objet type période
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2016.11.28 | Hocine HAMMOU
--          | [10472] Mise en place de l'inventaire matériel ( sacoches...)
--          |
-- ***************************************************************************
IS
  CONSTRUCTOR FUNCTION INVENTORY_TYPE(SELF IN OUT NOCOPY INVENTORY_TYPE) RETURN SELF AS RESULT
  IS
  BEGIN
     SELF := INVENTORY_TYPE
        (
          INTERNATIONAL_SITE_ID => NULL
         ,TAB_INVENTORY         => NULL
        );
     RETURN;
  END;

  -- -------------------------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 -- fonction qui check la validité du message
 -- retourne la liste des attributes en erreur parce qu'obligatoires et/ou non informés
  -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION MissingMandatoryAttributes (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   IF TRIM(INTERNATIONAL_SITE_ID) IS NULL THEN
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