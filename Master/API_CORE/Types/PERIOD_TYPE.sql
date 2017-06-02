CREATE OR REPLACE TYPE api_core."PERIOD_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.PERIOD_TYPE
--  DESCRIPTION : Description de l'objet type période
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.11.20 | Hocine HAMMOU
--          | Init
--          |
--  V01.000 | 2016.02.14 | Hocine HAMMOU
--          | [] RM1 LOT2 MODE DECONNECTE
--          | Ajout de l'attribut TAB_PERIOD_FILE_ID
--          |
-- ***************************************************************************
(
INTERNATIONAL_SITE_ID  VARCHAR2(35)                 -- MASTER.SITE.SITE_INTERNATIONAL_ID
,BO_PERIOD_ID          NUMBER                       -- MASTER.PERIOD.PERIOD_ID
,PDA_PERIOD_ID         NUMBER                       -- MASTER.PERIOD.PDA_PERIOD_ID%TYPE
,START_DTM             DATE                         -- MASTER.PERIOD.DATE_FROM
,END_DTM               DATE                         -- MASTER.PERIOD.DATE_TO
,PERIOD_TYPE_ID        NUMBER(1)                    -- MASTER.PERIOD.PERIOD_TYPE_ID   ( 1:VACATION / 4:USUAL_VACATION_PLAN ) (cf. CONFIG.PERIOD_TYPE) -- ATTENTION A CETTE ATTRIBUT CAR NOM PRESQUE IDENTIQUE AU NOM DU TYPE
,LAST_UPDATE_DTM       TIMESTAMP(6) WITH TIME ZONE  -- MASTER.PERIOD.LAST_UPDATE_DTM   --TIMESTAMP(6) WITH TIME ZONE
,DELETED_DTM           TIMESTAMP(6) WITH TIME ZONE  -- MASTER.PERIOD.DELETED           --TIMESTAMP(6) WITH TIME ZONE ?? actuellement si date rensigné alors à supprimer (NULL ou 0: NOT DELETED / 1:DELETED )
,TAB_PERIOD_FILE_ID    TAB_ELEMENT_NUMBER_TYPE      -- TABLEAU D'ELEMENTS NUMBER POUR REPRESENTER => IMPORT_PDA.T_XMLFILES.FILE_ID OU IMPORT_PDA.IMPORT_PDA.T_PERIOD_IMPORTED


, CONSTRUCTOR FUNCTION PERIOD_TYPE(SELF IN OUT NOCOPY PERIOD_TYPE) RETURN SELF AS RESULT

, MEMBER FUNCTION CheckMsgCreatePeriod (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION CheckMsgDeletePeriod (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
, MEMBER FUNCTION CheckMsgUpdatePeriod (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."PERIOD_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.PERIOD_TYPE
--  DESCRIPTION : Méthodes de l'objet type période
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.11.20 | Hocine HAMMOU
--          | Init
--  V01.000 | 2016.02.14 | Hocine HAMMOU
--          | [] RM1 LOT2 MODE DECONNECTE
--          | Ajout de l'attribut TAB_PERIOD_FILE_ID
-- ***************************************************************************
IS
  CONSTRUCTOR FUNCTION PERIOD_TYPE(SELF IN OUT NOCOPY PERIOD_TYPE) RETURN SELF AS RESULT
  IS
  BEGIN
     SELF := PERIOD_TYPE
        (
          INTERNATIONAL_SITE_ID => NULL
         ,BO_PERIOD_ID          => NULL
         ,PDA_PERIOD_ID         => NULL
         ,START_DTM             => NULL
         ,END_DTM               => NULL
         ,PERIOD_TYPE_ID        => NULL  -- ATTENTION A CETTE ATTRIBUT CAR NOM PRESQUE IDENTIQUE AU NOM DU TYPE
         ,LAST_UPDATE_DTM       => NULL
         ,DELETED_DTM           => NULL
		 ,TAB_PERIOD_FILE_ID    => NULL  -- 12.02.2016 ajout pour le mode déconnecté
        );
     RETURN;
  END;



 -- -------------------------------------------------------------------------------------------
 -- Fonction CheckMsgCreatePeriod :
 -- fonction qui check la validité du message de création de Period
 -- retourne la liste des attributes en erreur parce qu'obligatoires et non informés
  -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION CheckMsgCreatePeriod (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'CheckMsgCreatePeriod';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   IF TRIM(INTERNATIONAL_SITE_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'INTERNATIONAL_SITE_ID');
   END IF;

/*
   IF PDA_PERIOD_ID IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'PDA_PERIOD_ID');
   END IF;
*/
   IF START_DTM IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'START_DTM');
   END IF;

   IF END_DTM IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'END_DTM');
   END IF;

   IF PERIOD_TYPE_ID IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'PERIOD_TYPE_ID');
   END IF;

   IF LAST_UPDATE_DTM IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'LAST_UPDATE_DTM');
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;


 -- -------------------------------------------------------------------------------------------
 -- Fonction CheckMsgDeletePeriod :
 -- fonction qui check la validité du message de création de Period
 -- retourne la liste des attributes en erreur parce qu'obligatoires et non informés
  -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION CheckMsgDeletePeriod (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'CheckMsgDeletePeriod';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   IF TRIM(INTERNATIONAL_SITE_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'INTERNATIONAL_SITE_ID');
   END IF;
   -- 2016.01.13
   IF BO_PERIOD_ID IS NULL AND PDA_PERIOD_ID IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'BO_PERIOD_ID/PDA_PERIOD_ID');
   END IF;
/*
   IF BO_PERIOD_ID IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'BO_PERIOD_ID');
   END IF;

   IF PDA_PERIOD_ID IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'PDA_PERIOD_ID');
   END IF;
 */
   IF START_DTM IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'START_DTM');
   END IF;

   IF END_DTM IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'END_DTM');
   END IF;
/*
   IF PERIOD_TYPE_ID IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'PERIOD_TYPE_ID');
   END IF;
*/
   IF LAST_UPDATE_DTM IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'LAST_UPDATE_DTM');
   END IF;

   IF DELETED_DTM IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'DELETED_DTM');
   END IF;

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;

 -- -------------------------------------------------------------------------------------------
 -- Fonction CheckMsgUpdatePeriod :
 -- fonction qui check la validité du message de création de Period
 -- retourne la liste des attributes en erreur parce qu'obligatoires et non informés
  -- -------------------------------------------------------------------------------------------
MEMBER FUNCTION CheckMsgUpdatePeriod (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'CheckMsgUpdatePeriod';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   IF TRIM(INTERNATIONAL_SITE_ID) IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'INTERNATIONAL_SITE_ID');
   END IF;

   IF BO_PERIOD_ID IS NULL AND PDA_PERIOD_ID IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'BO_PERIOD_ID/PDA_PERIOD_ID');
   END IF;
 /*
   IF PDA_PERIOD_ID IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'PDA_PERIOD_ID');
   END IF;
*/
   IF START_DTM IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'START_DTM');
   END IF;

   IF END_DTM IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'END_DTM');
   END IF;

   IF PERIOD_TYPE_ID IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'PERIOD_TYPE_ID');
   END IF;

   IF LAST_UPDATE_DTM IS NULL THEN
      l_result:= PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'LAST_UPDATE_DTM');
   END IF;


   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;













END;

/