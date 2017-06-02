CREATE OR REPLACE PACKAGE BODY api_core.PCK_MESSAGE
-- ***************************************************************************
--  PACKAGE     : PCK_OPENING_HOURS
--  DESCRIPTION : Package to deal with Message coming from BO
--
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.12.02 | Hocine HAMMOU
--          | Init
--          |
--  V01.002 | 2017.01.24 | Hocine HAMMOU
--          | Projet [10237] Réception des données dates dans le fuseau horaire du pudo cible
-- ***************************************************************************
IS

-- -----------------------------------------------------------------------------------------
--  UNIT         : GetSiteMessages
--  DESCRIPTION  : Recupère la liste des 10 derniers messages (lus ou non lus)
--  IN           : p_INTERNATIONAL_SITE_ID
--  OUT          : p_tab_message sera une table TAB_MESSAGE_TYPE avec la liste des messages
-- -----------------------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.12.02 | Hocine HAMMOU
--          | version initiale
-- ---------------------------------------------------------------------------
PROCEDURE GetSiteMessages(p_international_site_id IN VARCHAR2, p_tab_message OUT NOCOPY api_core.TAB_MESSAGE_TYPE ) IS
  l_unit           MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetSiteMessages';
  l_start_date     MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_requiredparams VARCHAR2(4000);
  l_site_id        MASTER.SITE.SITE_ID%TYPE;
BEGIN
   -- --------------------------------------------------------------------------------
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   -- --------------------------------------------------------------------------------
   IF TRIM(p_international_site_id) IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'P_INTERNATIONAL_SITE_ID');
   END IF;

   -- --------------------------------------------------------------------------------
   -- RAISE EXCEPTION EN CAS DE DONNEES OBLIGATOIRES NON RENSEIGNEES
   -- --------------------------------------------------------------------------------
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- -----------------------------------------------------------------------------
   -- A PARTIR DE INTERNATIONAL_SITE_ID, CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   l_site_id := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => p_international_site_id );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || p_international_site_id);
   END IF;

   -- instanciation d'un tableau Message
   p_tab_message := api_core.TAB_MESSAGE_TYPE();

   ------------------------------------------------------------------------
   -- requete pour récuperer les 10 derniers messages
   ------------------------------------------------------------------------
   WITH message AS (
   SELECT p_international_site_id as international_site_id
   ,sm.SENT_MESSAGE_ID  as MESSAGE_ID
   ,sm.CREATION_DTM  as CREATION_DTM
   ,sm.SENDER as SENDER
   ,sm.SUBJECT   as   SUBJECT
   ,sm.MESSAGE_CONTENT as MESSAGE_CONTENT
   ,NVL(pt.POPUP_TYPE_NAME, PCK_API_CONSTANTS.c_POPUP_TYPE_AUCUN) AS POPUP  -- pour renvoyer 'AUCUN' lorsque la donnee est NULL car il semble parfois qu'elle soit soit NULL
   ,NVL(ft.FORM_TYPE_NAME, PCK_API_CONSTANTS.c_FORM_TYPE_AUCUN) AS FORM     -- pour renvoyer 'AUCUN' lorsque la donnee est NULL car il semble parfois qu'elle soit soit NULL
   ,sm.WITHRECEIPT AS WITHRECEIPT
   ,(rel.WITHRECEIPT_DTM AT TIME ZONE 'UTC' ) AS WITHRECEIPT_DTM -- 2017.01.03 Projet [10237] Restitution de la date en UTC pour WEBAPP/Android
   FROM master.sent_message sm
   INNER JOIN MASTER.SENT_MESSAGE_SITE_REL rel on sm.SENT_MESSAGE_ID = rel.SENT_MESSAGE_ID
   LEFT OUTER JOIN CONFIG.POPUP_TYPE pt on sm.POPUP_TYPE_ID =  pt.POPUP_TYPE_ID
   LEFT OUTER JOIN CONFIG.FORM_TYPE ft on sm.FORM_TYPE_ID =  ft.FORM_TYPE_ID
   WHERE rel.site_id = l_site_id
   ORDER BY sm.SENT_MESSAGE_ID DESC
   )
   SELECT MESSAGE_TYPE(m.international_site_id ,m.MESSAGE_ID ,m.CREATION_DTM ,m.SENDER ,m.SUBJECT ,m.MESSAGE_CONTENT ,m.POPUP ,m.FORM ,m.WITHRECEIPT ,m.WITHRECEIPT_DTM)
   BULK COLLECT INTO p_tab_message
   FROM message m
   WHERE ROWNUM <= 10
   ;

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] MESSAGES RETRIEVED (INTERNATIONAL_SITE_ID:' || p_international_site_id || '-ELAPSED TIME:'||api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSiteMessages;



-- ---------------------------------------------------------------------------
--  UNIT         : GetSiteMessages
--  DESCRIPTION  : Voir procedure homonyme
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.12.02 | Hocine HAMMOU
--          | version initiale
-- ---------------------------------------------------------------------------
FUNCTION  GetSiteMessages(p_international_site_id IN VARCHAR2) RETURN api_core.TAB_MESSAGE_TYPE IS
  l_unit        MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetSiteMessages';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_tab_message api_core.TAB_MESSAGE_TYPE;
BEGIN
  GetSiteMessages(p_international_site_id => p_international_site_id, p_tab_message => l_tab_message);
  RETURN l_tab_message;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSiteMessages;


-- ----------------------------------------------------------------------------------------------
--  UNIT         : SetSiteMessageRead
--  DESCRIPTION  : Retourne au BO la date/heure de lecture des messages
--  IN           : p_message de type API_CORE.MESSAGE_TYPE
--  OUT          :
-- ----------------------------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ----------------------------------------------------------------------------------------------
--  V01.000 | 2015.12.07 | Hocine HAMMOU
--          | version initiale
--          |
--  V01.001 | 2017.01.03 | Hocine HAMMOU
--          | Projet [10237] Intégration de la date d'accusé/réception dans la time zone du pudo
-- ----------------------------------------------------------------------------------------------
PROCEDURE SetSiteMessageRead(p_message IN OUT NOCOPY api_core.MESSAGE_TYPE )
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'SetSiteMessageRead';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams  VARCHAR2(4000);
   l_site_id         MASTER.SITE.SITE_ID%TYPE;
   l_timezone        SITE.TIMEZONE%TYPE; -- 2017.01.20 [10237]

BEGIN

   -- -----------------------------------------------------------------------------------------------------
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE : INTERNATIONAL_SITE_ID,  MESSAGE_ID, WITHRECEIPT_DTM
   -- -----------------------------------------------------------------------------------------------------
   IF TRIM(p_message.INTERNATIONAL_SITE_ID) IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'INTERNATIONAL_SITE_ID');
   END IF;
   IF p_message.MESSAGE_ID IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'MESSAGE_ID');
   END IF;
   IF p_message.WITHRECEIPT_DTM IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'WITHRECEIPT_DTM');
   END IF;

   -- --------------------------------------------------------------------------------
   -- RAISE EXCEPTION EN CAS DE DONNEES OBLIGATOIRES NON RENSEIGNEES
   -- --------------------------------------------------------------------------------
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- -----------------------------------------------------------------------------
   -- A PARTIR DE INTERNATIONAL_SITE_ID => CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   l_site_id := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => p_message.INTERNATIONAL_SITE_ID );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || p_message.INTERNATIONAL_SITE_ID);
   END IF;

   -- -----------------------------------------------------------------------------
   -- RECUPERATION DE LA TIMEZONE DU PUDO
   -- -----------------------------------------------------------------------------
   l_timezone := MASTER_PROC.PCK_SITE.GetSiteTimezone(p_siteid => l_site_id);

   -- APPEL A MarkMessageAsRead
   -- ----------------------------
   MASTER_PROC.PCK_MESSAGE.MarkMessageAsRead (p_message_id            => p_message.MESSAGE_ID
                                             ,p_site_id               => l_site_id
                                             ,p_message_event_dtm     =>( FROM_TZ(CAST(p_message.WITHRECEIPT_DTM AS DATE ) , 'UTC' ) ) AT TIME ZONE l_timezone -- 2017.01.03 [10237] INTEGRATION DANS LA TIMEZONE DU PUDO
                                             ,p_message_event_type_id => 'READ'
                                             );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] MESSAGE MARK AS READ (MESSAGE:' || p_message.MESSAGE_ID || '-ELAPSED TIME:'||api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms.' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END SetSiteMessageRead;

END PCK_MESSAGE;

/