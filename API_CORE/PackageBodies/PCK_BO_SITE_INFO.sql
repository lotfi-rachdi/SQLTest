CREATE OR REPLACE PACKAGE BODY api_core.PCK_BO_SITE_INFO
-- ***************************************************************************
--  PACKAGE BODY : API_CORE.PCK_BO_SITE_INFO
--  DESCRIPTION  : Création des procédures utilisés par les WEB API pour
--                 obtenir information du backoffice
--
--                 Rajouté pour Web API
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.11 | Hocine HAMMOU
--          | version initiale
--          |
--  V01.100 | 2015.06.24 | Maria CASALS
--          | Q_OPENNED_PARCEL renommé a Q_OPEN_PARCEL
--          | BO_PARCEL_ID et SITE_ID deviennent INTEGER
--          | MAPPED_PARCEL_STATE_DTM passe a DATE et sera converti a l'heure locale du SITE
--          |
--  V01.200 | 2015.06.26 | Maria CASALS
--          | rajout GetSiteParcels
--          |
--  V01.300 | 2015.07.08 | Hocine HAMMOU
--          | Ajout controle afin de vérifier la présence des valeurs obligatoires
--          |
--  V01.400 | 2015.07.09 | Hocine HAMMOU
--          | Suppression de la gestion des reserves comme Parcel Properties
--          | remplacé par la gestion des reserves au niveau des Parcel Step
--
--  V01.450 | 2015.07.10 | Hocine HAMMOU
--          | Ajout de la donnée INTERNATIONAL_SITE_ID en complément de SITE_ID
--          | INTERNATIONAL_SITE_ID est la donnée qui est échangée avec les WEB API
--          |
--  V01.455 | 2015.07.17 | Maria CASALS
--          | Deplacement de fonction LIST vers PCK_API_TOOLS
--          |
--  V01.456 | 2015.07.20 | Maria CASALS
--          | rajout GetParcelsToPrepare
--          |
--  V01.XXX | 2015.07.XX | A FAIRE
--          | CARRIER_NAME (AKA FIRM_ID) : pour ztre cohérent avec le comportement des PDA,
--          | s'il y a un _ ("underscore") dans le carrier_name, seulement la partie avant le 1r underscore
--          | s'affiche
--          | est-ce que c'est a la partie Oracle de faire ea??
--          | Ou alors une transformation dans l'affichage coté Web Appli?
--          | Ou dans le "passe-plat" du Web API?
--          | ou alors nous rajoutons une colonne "display FIRM_ID" en plus, comme ea nous avons les deux?
--          | serait-il en fait une autre colonne dans CARRIER (qui coincide souvent avec le CARRIER_NAME rabioté?
--          | --> attention il y a des transformations comme ea aussi en dur dans le code pour des tracings, ea a l'air du spécifique
--          | a étudier pour prendre en compte dans la paramétrization
--          |
--          | Actuellement dans les PDA ceci est fait avec le "nom d'affichage" par rapport au nom de la Base de Données
--          |
--  V01.457 | 2015.09.09 | Amadou YOUNSAH
--          | Renommage du type API_CORE.SITE_TAB_TYPE en API_CORE.TAB_SITE_TYPE
--          |
--  V01.500 | 2015.09.18 | Hocine HAMMOU
--          | Dans le cadre du découplage des Parcels et des Sites,
--          | création d'un package PCK_BO_SITE_INFO dédiés aux SITES
--          |
--  V01.510 | 2015.09.25 | Hocine HAMMOU
--          | Modification de la requete GetActiveSite : l'email est recupéré depuis
--          | depuis les infos sur le contact principal et non plus depuis le site
--          |
--  V01.515 | 2016.01.13 | Hocine HAMMOU
--          | [10163] Modification de la requete GetActiveSites : ajout dans le filtre
--          | du prédicat SITE.DEVICE_TYPE_WEBAPP = 1
--          |
--  V01.516 | 2016.04.05 | Hocine HAMMOU
--          | RM2 [10302]
--          | Ajout de la procédure GetSiteRules qui envoie au mobiles les infos
--          | sur les prestations du Pudo
--          |
--  V01.517 | 2016.06.21 | Hocine HAMMOU
--          | Projet RM2 [10093] : Récupération de données supplémentaires : LANGUAGE_CODE, OPERATOR_ID
--          | dans la query GetActiveSites
--          |
--  V01.518 | 2017.03.06 | Hocine HAMMOU
--          | Projet [10350] : Ajout de la procédure GetSitesByCountry
--          |
--  V01.519 | 2017.05.15 | Maria Casals
--          | Projets 10128/10161 - Gestion des interactions et campagnes d'appels / CRM Lot 1
--          | => ajout des fonctions IS_IN_CRM, GetSiteid
--          |
--  V01.520 | 2017.05.30 | Hocine HAMMOU
--          | Bug 88044 :[CRM] : ANO = Création automatique d'une indispo « Pas de PDA associé » pour un point de type consigne
--          | ==> Ajout dans la proc. GetSitesByCountry d'un filtre séléction sur les PUDO_TYPE_ID : MIGRATION_POINT, STANDARD_PICKUP_POINT et PARTNER_RELAY_POINT et Pickup Store
--          |
-- ***************************************************************************
IS

c_packagename CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ;
c_country_code_NIR CONSTANT VARCHAR2(3) := 'NIR' ;  -- Code country 'IRELANDE DU NORD'

c_MIGRATION_POINT        CONSTANT MASTER.SITE.PUDO_TYPE_ID%TYPE := 1 ;
c_STANDARD_PICKUP_POINT  CONSTANT MASTER.SITE.PUDO_TYPE_ID%TYPE := 2 ;
c_PARTNER_RELAY_POINT    CONSTANT MASTER.SITE.PUDO_TYPE_ID%TYPE := 3 ;
c_PICKUP_STORE           CONSTANT MASTER.SITE.PUDO_TYPE_ID%TYPE := 21 ;

-- ---------------------------------------------------------------------------
--  UNIT         : GetActiveSites
--  DESCRIPTION  : Recupcre la liste de SITE_ID dans des états actifs pour un pays
--  IN           : p_COUNTRY_CODE
--  OUT          : p_site_tab sera une table TAB_SITE_TYPE avec la liste de sites
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.17 | Hocine HAMMOU
--          | version initiale
--  V01.100 | 2015.07.10 | Hocine HAMMOU
--          | Remplacement de SITE_ID par INTERNATIONAL_SITE_ID
--  V01.101 | 2016.06.21 | Hocine HAMMOU
--          | Projet RM2 [10093]
--          | Récupération de données supplémentaires : LANGUAGE_CODE, OPERATOR_ID
--          | dans la query GetActiveSites
--  V01.102 | 2017.03.01 | Hocine HAMMOU
--          | Projet RM2 [10350]
--          | Prise en compte des sites ayant les types de devices suivants : PDA Android, Mobile, Webapp et BYOD
-- ---------------------------------------------------------------------------
PROCEDURE GetActiveSites(p_country_code IN VARCHAR2, p_site_tab OUT NOCOPY api_core.TAB_SITE_TYPE ) IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GETACTIVESITES';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_requiredparams VARCHAR2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   IF TRIM(p_country_code) IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'P_COUNTRY_CODE');
   END IF;

   -- RAISE EXCEPTION EN CAS DE DONNEES OBLIGATOIRES NON RENSEIGNEES
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   p_site_tab := TAB_SITE_TYPE();

   ------------------------------------------------------------------------
   -- requete élaborée pour contourner la non-unicité de SITE.SITE_INTERNATIONAL_ID.
   -- en attente de mise a jour des données et mise en place d'une contrainte NOT NULL UNIQUE sur SITE.SITE_INTERNATIONAL_ID
   ------------------------------------------------------------------------

   SELECT SITE_TYPE( UPPER(TRIM(s.COUNTRY_CODE))
                   , UPPER(TRIM(s.SITE_INTERNATIONAL_ID))
                   , UPPER(TRIM(s.LANGUAGE_CODE)) -- [10093] 2016.06.21
                   , s.OPERATOR_ID                -- [10093] 2016.06.21
                   , COALESCE( MIN(TRIM(c.EMAIL)), max(TRIM(c.EMAIL)))
                   , s.SITE_STATE_ID
                   )
   BULK COLLECT INTO p_site_tab
   FROM MASTER.SITE s
   INNER JOIN MASTER.SITE_CONTACT_REL r ON (s.site_id=r.site_id)
   INNER JOIN MASTER.CONTACT c ON ( r.contact_id = c.contact_id )
   INNER JOIN CONFIG.SITE_DEVICE_TYPE_REL d on ( s.site_id = d.SITE_ID )
   WHERE s.COUNTRY_CODE = p_country_code
   AND TRIM(s.SITE_INTERNATIONAL_ID) IS NOT NULL
   AND r.CONTACT_TYPE_ID = PCK_API_CONSTANTS.c_SITE_MAIN_CONTACT -- CONTACT PRINCIPAL
   AND s.SITE_STATE_ID IN ( -- statuts de sites actifs
                            PCK_API_CONSTANTS.c_SITESTATE_PUDO_CREATED
                          , PCK_API_CONSTANTS.c_SITESTATE_STARTING_ACTIVITY
                          , PCK_API_CONSTANTS.c_SITESTATE_ACTIVE
                          , PCK_API_CONSTANTS.c_SITESTATE_END_ACTIVITY
                          )
   --AND s.DEVICE_TYPE_WEBAPP = PCK_API_CONSTANTS.c_DEVICE_TYPE_WEBAPP -- [10163] 2016.01.13
   AND d.DEVICE_TYPE_ID IN ( PCK_API_CONSTANTS.c_device_type_id_PDA_ANDROID
                           , PCK_API_CONSTANTS.c_device_type_id_MOBILE
                           , PCK_API_CONSTANTS.c_device_type_id_BYOD
                           , PCK_API_CONSTANTS.c_device_type_id_WEBAPP
                           )
   GROUP BY UPPER(TRIM(s.COUNTRY_CODE)), UPPER(TRIM(s.SITE_INTERNATIONAL_ID)), UPPER(TRIM(s.LANGUAGE_CODE)), s.OPERATOR_ID ,s.SITE_STATE_ID ;

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ACTIVES SITES REQUEST' || '-ELAPSED TIME:'||api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms.' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetActiveSites;


-- ---------------------------------------------------------------------------
--  UNIT         : GetActiveSites
--  DESCRIPTION  : Voir procedure homonyme
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.17 | Hocine HAMMOU
--          | version initiale
-- ---------------------------------------------------------------------------
FUNCTION  GetActiveSites(p_country_code IN VARCHAR2) RETURN api_core.TAB_SITE_TYPE IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GETACTIVESITES';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_site_tab TAB_SITE_TYPE;
BEGIN
  GetActiveSites(p_country_code => p_country_code, p_site_tab => l_site_tab);
  RETURN l_site_tab;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetActiveSites;


-- ---------------------------------------------------------------------------
--  UNIT         : GetSiteRules
--  DESCRIPTION  : Récupcre les infos sur les prestations du PUDO (MASTER.SITE_RULES/CONFIG.PDA_PROPERTY)
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.05 | Hocine HAMMOU
--          | version initiale
-- ---------------------------------------------------------------------------
PROCEDURE GetSiteRules(p_international_site_id IN VARCHAR2, p_SITE_RULES_TYPE OUT NOCOPY api_core.TAB_SITE_RULES_TYPE ) IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetSiteConfig';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams VARCHAR2(4000);
   l_site_id MASTER.SITE.SITE_ID%TYPE;
   l_query_site_rules CLOB;
   l_xmlquery  VARCHAR2 (32000);

BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   IF TRIM(p_international_site_id) IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'P_INTERNATIONAL_SITE_ID');
   END IF;

   -- -----------------------------------------------------------------------------
   -- A PARTIR DE INTERNATIONAL_SITE_ID, CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   l_site_id := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => p_international_site_id );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || p_international_site_id);
   END IF;

   -- Retrieve des infos Pudo (MASTER.SITE_RULES/CONFIG.PDA_PROPERTY)
   EXPORT_PDA.PCK_CONFIG_TO_PDA.BUILD_QUERY_RULES(p_site_id => l_site_id, p_Sql_Rules => l_query_site_rules, p_xmlquery => l_xmlquery);

   -- instanciation d'un tableau Message
   p_SITE_RULES_TYPE := NEW api_core.TAB_SITE_RULES_TYPE();

   l_query_site_rules := 'SELECT API_CORE.SITE_RULES_TYPE(RULE_NAME, RULE_VALUE) FROM ( ' || l_query_site_rules || ' )  ';

   EXECUTE IMMEDIATE l_query_site_rules BULK COLLECT INTO p_SITE_RULES_TYPE;

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] CONFIG RETRIEVED (INTERNATIONAL_SITE_ID:' || p_international_site_id || '-ELAPSED TIME:'||api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSiteRules;


-- ---------------------------------------------------------------------------
--  UNIT         : GetSiteRules
--  DESCRIPTION  : Voir procedure homonyme
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.06.21 | Hocine HAMMOU
--          | version initiale
-- ---------------------------------------------------------------------------
FUNCTION  GetSiteRules(p_international_site_id IN VARCHAR2) RETURN api_core.TAB_SITE_RULES_TYPE IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetSiteRules';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_site_rules_tab api_core.TAB_SITE_RULES_TYPE;
BEGIN

   GetSiteRules( p_international_site_id => p_international_site_id
               , p_SITE_RULES_TYPE       => l_site_rules_tab
               );

   RETURN l_site_rules_tab;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSiteRules;

-- ---------------------------------------------------------------------------
--  UNIT         : GetAllSites
--  DESCRIPTION  : Récupère la liste de tous les pudos (à l'exception des pudos prospects et des pudos d'Ireland du Nord )
--  IN           :
--  OUT          : p_site_tab sera une table TAB_SITE_TYPE avec la liste de sites
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.02.06 | Hocine HAMMOU
--          | Projet [10350] version initiale
-- ---------------------------------------------------------------------------
PROCEDURE GetAllSites(p_site_tab OUT NOCOPY api_core.TAB_SITE_TYPE ) IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetAllSites';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_requiredparams VARCHAR2(4000);
BEGIN

   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   p_site_tab := TAB_SITE_TYPE();

   ----------------------------------------------------------------------------------------------------------------------------
   -- requete élaborée pour contourner la non-unicité de SITE.SITE_INTERNATIONAL_ID.
   -- en attente de mise a jour des données et mise en place d'une contrainte NOT NULL UNIQUE sur SITE.SITE_INTERNATIONAL_ID
   ----------------------------------------------------------------------------------------------------------------------------
   SELECT SITE_TYPE( UPPER(TRIM(s.COUNTRY_CODE))
                   , UPPER(TRIM(s.SITE_INTERNATIONAL_ID))
                   , UPPER(TRIM(s.LANGUAGE_CODE)) -- [10093] 2016.06.21
                   , s.OPERATOR_ID                -- [10093] 2016.06.21
                   , COALESCE( MIN(TRIM(c.EMAIL)), max(TRIM(c.EMAIL)))
                   , s.SITE_STATE_ID
                   )
   BULK COLLECT INTO p_site_tab
   FROM MASTER.SITE s
   LEFT OUTER JOIN MASTER.SITE_CONTACT_REL r ON (s.site_id = r.site_id)
   LEFT OUTER JOIN MASTER.CONTACT c ON ( r.contact_id = c.contact_id AND r.CONTACT_TYPE_ID = PCK_API_CONSTANTS.c_SITE_MAIN_CONTACT )
   WHERE s.COUNTRY_CODE <> c_country_code_NIR
   AND TRIM(s.SITE_INTERNATIONAL_ID) IS NOT NULL
   AND s.SITE_STATE_ID  <> 1
   GROUP BY UPPER(TRIM(s.COUNTRY_CODE)), UPPER(TRIM(s.SITE_INTERNATIONAL_ID)), UPPER(TRIM(s.LANGUAGE_CODE)), s.OPERATOR_ID ,s.SITE_STATE_ID ;

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ACTIVES SITES REQUEST' || '-ELAPSED TIME:'||api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms.' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetAllSites;

-- ---------------------------------------------------------------------------
--  UNIT         : GetAllSites
--  DESCRIPTION  : Voir procedure homonyme
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.02.06 | Hocine HAMMOU
--          | Projet [10350] version initiale
-- ---------------------------------------------------------------------------
FUNCTION  GetAllSites RETURN api_core.TAB_SITE_TYPE IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetAllSites';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_site_tab TAB_SITE_TYPE;
BEGIN
  GetAllSites(p_site_tab => l_site_tab);
  RETURN l_site_tab;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetAllSites;

-- ---------------------------------------------------------------------------
--  UNIT         : GetSitesByCountry
--  DESCRIPTION  : Récupère la liste de tous les pudos pour un pays donné
--  IN           : p_COUNTRY_CODE_tab : liste des codes pays ISO3
--  OUT          : p_site_tab sera une table TAB_SITE_TYPE avec la liste de sites
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.03.06 | Hocine HAMMOU
--          | Projet [10350] version initiale
--          |
--  V01.001 | 2017.05.30 | Hocine HAMMOU
--          | Ajout filtre séléction sur les PUDO_TYPE_ID : MIGRATION_POINT, STANDARD_PICKUP_POINT et PARTNER_RELAY_POINT et PICKUP STORE
--          |
-- ---------------------------------------------------------------------------
PROCEDURE GetSitesByCountry(p_country_code_tab IN api_core.TAB_ELEMENT_VARCHAR_TYPE, p_site_tab OUT NOCOPY api_core.TAB_SITE_TYPE )
IS
  l_unit           MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetSitesByCountry';
  l_start_date     MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_requiredparams VARCHAR2(4000);
  l_count INTEGER;
BEGIN

   IF p_country_code_tab IS NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,PCK_API_CONSTANTS.errmsg_requiredparam || 'Le paramètre p_country_code_tab ne peut être vide.');
   ELSE
      IF p_country_code_tab.COUNT > 0 THEN
         IF TRIM(l_requiredparams) IS NOT NULL THEN
            RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
         END IF;

         p_site_tab := TAB_SITE_TYPE();

         ----------------------------------------------------------------------------------------------------------------------------
         -- requete élaborée pour contourner la non-unicité de SITE.SITE_INTERNATIONAL_ID.
         -- en attente de mise a jour des données et mise en place d'une contrainte NOT NULL UNIQUE sur SITE.SITE_INTERNATIONAL_ID
         ----------------------------------------------------------------------------------------------------------------------------
         SELECT SITE_TYPE( UPPER(TRIM(s.COUNTRY_CODE))
                         , UPPER(TRIM(s.SITE_INTERNATIONAL_ID))
                         , UPPER(TRIM(s.LANGUAGE_CODE))
                         , s.OPERATOR_ID
                         , COALESCE( MIN(TRIM(c.EMAIL)), max(TRIM(c.EMAIL)))
                         , s.SITE_STATE_ID
                         )
         BULK COLLECT INTO p_site_tab
         FROM MASTER.SITE s
         LEFT OUTER JOIN MASTER.SITE_CONTACT_REL r ON (s.site_id = r.site_id)
         LEFT OUTER JOIN MASTER.CONTACT c ON ( r.contact_id = c.contact_id AND r.CONTACT_TYPE_ID = PCK_API_CONSTANTS.c_SITE_MAIN_CONTACT )
         WHERE s.COUNTRY_CODE  IN ( SELECT column_value
                                    FROM TABLE(CAST( p_country_code_tab AS TAB_ELEMENT_VARCHAR_TYPE))
                                  )
         AND TRIM(s.SITE_INTERNATIONAL_ID) IS NOT NULL
         AND s.SITE_STATE_ID  <> 1
         AND s.PUDO_TYPE_ID IN ( c_MIGRATION_POINT, c_STANDARD_PICKUP_POINT, c_PARTNER_RELAY_POINT, c_PICKUP_STORE )
         GROUP BY UPPER(TRIM(s.COUNTRY_CODE)), UPPER(TRIM(s.SITE_INTERNATIONAL_ID)), UPPER(TRIM(s.LANGUAGE_CODE)), s.OPERATOR_ID , s.SITE_STATE_ID;

      END IF;

      MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ACTIVES SITES REQUEST' || '-ELAPSED TIME:'||api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms.' );

   END IF;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSitesByCountry;


-- ---------------------------------------------------------------------------
--  UNIT         : IS_IN_CRM
--  DESCRIPTION  : Permet de savooir si le site est géré dans le CRM ou non
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.05.15 | Maria Casals
--          | Projets 10128/10161 - Gestion des interactions et campagnes d'appels / CRM Lot 1
-- ---------------------------------------------------------------------------
FUNCTION IS_IN_CRM(p_SITE_ID IN NUMBER) RETURN NUMBER
IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'IS_IN_CRM';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_result NUMBER := 0 ;
BEGIN
  l_result := MASTER_PROC.PCK_SITE.IS_IN_CRM(p_SITE_ID => p_SITE_ID);
  RETURN l_result;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END IS_IN_CRM;


-- ---------------------------------------------------------------------------
--  UNIT         : IS_IN_CRM
--  DESCRIPTION  : Permet de savoir si le site est géré dans le CRM ou non
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.05.15 | Maria Casals
--          | Projets 10128/10161 - Gestion des interactions et campagnes d'appels / CRM Lot 1
-- ---------------------------------------------------------------------------
FUNCTION IS_IN_CRM( p_SITE_INTERNATIONAL_ID IN VARCHAR2) RETURN NUMBER
IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'IS_IN_CRM';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_result NUMBER := 0 ;
BEGIN
  l_result := MASTER_PROC.PCK_SITE.IS_IN_CRM(p_SITE_INTERNATIONAL_ID => p_SITE_INTERNATIONAL_ID);
  RETURN l_result;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END IS_IN_CRM;


-- ---------------------------------------------------------------------------
--  UNIT         : GetSiteid
--  DESCRIPTION  : Permet de récupérer, pour un PDA donné, le SITE_INTERNATIONAL_ID auqel est rattaché le PDA
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.05.15 | Maria Casals
--          | Projets 10128/10161 - Gestion des interactions et campagnes d'appels / CRM Lot 1
-- ---------------------------------------------------------------------------
FUNCTION GetSiteID(p_pdaid IN CONFIG.PDA.PDA_ID%TYPE, p_date IN DATE DEFAULT SYSDATE) RETURN VARCHAR2
IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetSiteid';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_SITE_ID MASTER.SITE.SITE_ID%TYPE := NULL;
  l_SITE_INTERNATIONAL_ID MASTER.SITE.SITE_INTERNATIONAL_ID%TYPE := NULL;
BEGIN

  -- 1ere etape récupération du site_id pour un pda_id donné
  BEGIN
     l_SITE_ID := MASTER_PROC.PCK_SITE.GetSiteid(p_pdaid => p_pdaid, p_date => p_date);
  EXCEPTION
     WHEN OTHERS THEN
        RETURN NULL;
  END;

  -- 2eme etape : si un site_id a précédemment été obtenu alors on récupère son site_international_id
  BEGIN
     l_SITE_INTERNATIONAL_ID := MASTER_PROC.PCK_SITE.GetSiteInternationalID(p_site_id =>l_SITE_ID);
  EXCEPTION
     WHEN OTHERS THEN
        RETURN NULL;
  END;

  RETURN l_SITE_INTERNATIONAL_ID;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSiteid;


END PCK_BO_SITE_INFO;

/