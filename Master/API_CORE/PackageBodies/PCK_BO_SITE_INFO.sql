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
--          |
--  V01.519 | 2017.03.28 | Leang NGUON
--          | Projet RM2 2017  [10417] - Inventaire colis
--          |
-- ***************************************************************************
IS

c_packagename CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ;
c_country_code_NIR CONSTANT VARCHAR2(3) := 'NIR' ;  -- Code country 'IRELANDE DU NORD'

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
--  UNIT         : CHECK_VALIDITY_VALUE
--  DESCRIPTION  : FLEET MANAGER envoie le mouvement d'un PDA
--
--
--  IN           : @Param p_SITE_INTERNATIONAL_ID               - site to be verified
--
--  OUT          : numéro de l'erreur type
--
---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.03.28 | Leang NGUON
--
--          |
-- ---------------------------------------------------------------------------
PROCEDURE CHECK_VALIDITY_VALUE ( p_SITE_INTERNATIONAL_ID IN VARCHAR2, p_check_result OUT NUMBER)
IS
      l_unit           MASTER_PROC.PROC_LOG.PROC_NAME%TYPE     := c_packagename||'.'||'CHECK_VALIDITY_VALUE';
      l_start_date     MASTER_PROC.PROC_LOG.START_TIME%TYPE    := systimestamp;
      l_result         VARCHAR2(4000);

BEGIN

      -- ERROR NULL Controle le paramètre d'entré null
      IF p_SITE_INTERNATIONAL_ID IS NULL THEN
             p_check_result := PCK_API_CONSTANTS.errnum_requiredparam ;
             l_result       := '[API_CORE] ' || PCK_API_CONSTANTS.errmsg_requiredparam || 'INPUT NULL' ;
             RAISE_APPLICATION_ERROR( p_check_result, l_result);
      END IF;


      BEGIN
            -- site existe, p_check_result = 0;
            select 0 into p_check_result
              from master.site t
             where t.site_international_id = p_SITE_INTERNATIONAL_ID
               and rownum = 1 ;


      EXCEPTION
            WHEN NO_DATA_FOUND THEN
               p_check_result := PCK_API_CONSTANTS.errnum_sitenotexists ;
      END;


EXCEPTION
      WHEN OTHERS THEN
             p_check_result := PCK_API_CONSTANTS.errnum_oracle_exception ;
             MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit , p_start_time => l_start_date );
             RAISE;

END CHECK_VALIDITY_VALUE;

-- ---------------------------------------------------------------------------
--  UNIT         : GetInventoriesBySite
--  DESCRIPTION  :
--
--
--  IN           : @Param p_site_id                      - Site identification for inventory
--
--  OUT          : @Param p_TAB_INVENTORY_SITE           - liste of inventory
--                 @Param p_result_code                  - if 0 the proc is correctly executed
--
---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.03.28 | Leang NGUON
--
-- ---------------------------------------------------------------------------
PROCEDURE GetInventoriesBySite ( p_SITE_INTERNATIONAL_ID IN VARCHAR2, p_TAB_INVENTORY_SITE OUT NOCOPY TAB_INVENTORY_SITE_TYPE, p_result_code OUT NUMBER)
IS
      l_unit           MASTER_PROC.PROC_LOG.PROC_NAME%TYPE     := c_packagename||'.'||'GetInventoriesBySite';
      l_start_date     MASTER_PROC.PROC_LOG.START_TIME%TYPE    := systimestamp;
      l_site_id               MASTER.INVENTORY_SITE.INVENTORY_SITE_ID%TYPE ;
      l_result         VARCHAR2(4000);
BEGIN
      -- value validation is KO
      CHECK_VALIDITY_VALUE ( p_SITE_INTERNATIONAL_ID => p_SITE_INTERNATIONAL_ID, p_check_result => p_result_code );
      IF p_result_code != 0 THEN
             return;
      END IF;


      -- Limiter les lignes sortantes
      with inventory as
      (
            SELECT i.inventory_site_id
            from master.inventory_site i
            inner join master.site s on s.site_id = i.site_id
            where s.site_international_id = p_SITE_INTERNATIONAL_ID
      )
      , duration as
      (
            select p.inventory_site_id, round( (MAX(p.inventory_dtm) - MIN(p.inventory_dtm)) * 1440) as inventory_duration
            from master.inventory_parcel p
            inner join inventory inv on inv.inventory_site_id = p.inventory_site_id
            group by p.inventory_site_id
      )

      -- C'est OK  p_result_code := 0 ;
      SELECT INVENTORY_SITE_TYPE
              (
                  INVENTORY_SITE_ID => i.inventory_site_id
                , SESSION_DTM       => i.session_dtm
                , STATE             => i.state
                , ORIGIN            => i.origin
                , CREATION_DTM      => i.creation_dtm
                , LAST_UPDATE_DTM   => i.last_update_dtm
                , DURATION          => d.inventory_duration
              )
      BULK COLLECT INTO p_TAB_INVENTORY_SITE
      from master.inventory_site i
           inner join      inventory inv on inv.inventory_site_id = i.inventory_site_id
           left outer join duration d    on d.inventory_site_id   = i.inventory_site_id
      order by i.last_update_dtm desc
      ;

EXCEPTION
      WHEN OTHERS THEN
             MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit , p_start_time => l_start_date );
             p_result_code := PCK_API_CONSTANTS.errnum_oracle_exception ;
             l_result       := '[API_CORE] ' || PCK_API_CONSTANTS.errmsg_oracle_exception ;
             RAISE_APPLICATION_ERROR( p_result_code, l_result);

END GetInventoriesBySite;

-- ---------------------------------------------------------------------------
--  UNIT         : GetSiteInformation
--  DESCRIPTION  :
--
--
--  IN           : @Param p_site_id                      - Site identification for inventory
--
--  OUT          : @Param p_TAB_INVENTORY_SITE           - liste of inventory
--                 @Param p_result_code                  - if 0 the proc is correctly executed
--
---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.03.28 | Leang NGUON
--
-- ---------------------------------------------------------------------------
PROCEDURE GetSiteInformation ( p_SITE_INTERNATIONAL_ID IN VARCHAR2, p_SITE_INFORMATION_TYPE OUT NOCOPY SITE_INFORMATION_TYPE, p_result_code OUT NUMBER)
IS
      l_unit           MASTER_PROC.PROC_LOG.PROC_NAME%TYPE     := c_packagename||'.'||'GetSiteInformation';
      l_start_date     MASTER_PROC.PROC_LOG.START_TIME%TYPE    := systimestamp;
      l_site_id        MASTER.INVENTORY_SITE.INVENTORY_SITE_ID%TYPE ;
      l_site_name      VARCHAR2(100);
      l_result         VARCHAR2(4000);
BEGIN

      -- C'est OK au départ
      p_result_code := 0 ;

      -- ERREUR valeur null
      IF p_SITE_INTERNATIONAL_ID IS NULL THEN
            p_result_code := PCK_API_CONSTANTS.errmsg_requiredparam ;
            return ;
      END IF;

      BEGIN

            select SITE_INFORMATION_TYPE(
                    SITE_INTERNATIONAL_ID => s.site_international_id  -- AS site_international_id
                  , BUSINESS_NAME => s.name                           -- AS BUSINESS_NAME
                  , SYNC_TIME => s.sync_time                          -- AS sync_time
                  , COUNTRY_CODE => s.country_code
                  )
            into p_SITE_INFORMATION_TYPE
            from master.site s
            where s.site_international_id = p_SITE_INTERNATIONAL_ID
            and rownum = 1
            ;

      EXCEPTION
             WHEN NO_DATA_FOUND THEN
                   p_SITE_INFORMATION_TYPE := new SITE_INFORMATION_TYPE();
                   p_result_code := PCK_API_CONSTANTS.errnum_sitenotexists ;
      END ;

EXCEPTION
      WHEN OTHERS THEN
             MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit , p_start_time => l_start_date );
             p_result_code := PCK_API_CONSTANTS.errnum_oracle_exception ;
             l_result       := '[API_CORE] ' || PCK_API_CONSTANTS.errmsg_oracle_exception ;
             RAISE_APPLICATION_ERROR( p_result_code, l_result);

END GetSiteInformation;

-- ---------------------------------------------------------------------------
--  UNIT         : InventoryRulesBySite
--  DESCRIPTION  :
--
--
--  IN           : @Param p_INVENTORY_RULE_TYPE                      -  One rule to store
--
--  OUT          : @Param p_INVENTORY_RULE_TYPE                      -  Compte rendu dans CHECK_RESULT
--                 @Param p_site_rules                               -  Retourne le résultat trouvé
--
---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.04.10 | Leang NGUON
--
-- ---------------------------------------------------------------------------
PROCEDURE InventoryRulesBySite
                (
                    p_INVENTORY_RULE_TYPE IN OUT NOCOPY INVENTORY_RULE_TYPE
                  , p_site_rules             OUT NOCOPY MASTER.SITE_RULES%ROWTYPE
                )
 IS
      l_unit                MASTER_PROC.PROC_LOG.PROC_NAME%TYPE     := c_packagename||'.'||'InventoryRulesBySite';
      l_start_date          MASTER_PROC.PROC_LOG.START_TIME%TYPE    := systimestamp;
      l_result              VARCHAR2(4000);


BEGIN


      -- 1) ERROR MISSING PARAM Controle des champs obligatoires en entree
      l_result := p_INVENTORY_RULE_TYPE.MissingMandatoryParameters2;
      IF TRIM(l_result) IS NOT NULL THEN
             p_INVENTORY_RULE_TYPE.CHECK_RESULT := PCK_API_CONSTANTS.errnum_requiredparam ;
             return ;
      END IF;

      -- 2) Check existance of PUDO
      BEGIN
          select s.site_id into p_site_rules.site_id
            from master.site s
           where s.site_international_id = NVL( p_INVENTORY_RULE_TYPE.SITE_INTERNATIONAL_ID, '0')
             and rownum = 1
               ;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               p_INVENTORY_RULE_TYPE.CHECK_RESULT := PCK_API_CONSTANTS.errnum_sitenotexists ;
               return ;
      END ;

      -- 3) Check property_name
      BEGIN
          select pda_property_id into p_site_rules.pda_property_id
            from config.pda_property
           where pda_property_name = p_INVENTORY_RULE_TYPE.PROPERTY_NAME
             and rownum = 1 ;
      EXCEPTION
          -- Stop
          -- Fatal Error because no property name does not recongnised
          WHEN NO_DATA_FOUND THEN
             p_INVENTORY_RULE_TYPE.CHECK_RESULT := PCK_API_CONSTANTS.errnum_ppynotexists ;
             return ;
      END ;

      -- UPDATE OR INSERT PROPERTY
      BEGIN
          select * into p_site_rules
            from master.site_rules
           where pda_property_id = p_site_rules.pda_property_id
             and site_id         = p_site_rules.site_id
             and rownum          = 1
               ;

          p_INVENTORY_RULE_TYPE.CHECK_RESULT := 0 ;


      EXCEPTION
          -- INSERT
          WHEN NO_DATA_FOUND THEN
               p_INVENTORY_RULE_TYPE.CHECK_RESULT := PCK_API_CONSTANTS.errnum_rulenotexists ;

      END ;


EXCEPTION
      WHEN OTHERS THEN
             MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit , p_start_time => l_start_date );
             COMMIT;
             RAISE;
END InventoryRulesBySite;

-- ---------------------------------------------------------------------------
--  UNIT         : SetInventoryRulesBySite
--  DESCRIPTION  :
--
--
--  IN           : @Param p_TAB_INVENTORY_RULE_TYPE                      - List of Inventory Rule to set
--
--  OUT          : @Param p_TAB_INVENTORY_RULE_TYPE                      - liste of return statuses
--                 @Param p_result_code                                  - if  0, the operation is correctly done for all site, all properties
--                                                                         if -n, there are n values failed
--
---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.04.10 | Leang NGUON
--
-- ---------------------------------------------------------------------------

PROCEDURE SetInventoryRulesBySite ( p_TAB_INVENTORY_RULE_TYPE IN OUT NOCOPY TAB_INVENTORY_RULE_TYPE)
IS
      l_unit                MASTER_PROC.PROC_LOG.PROC_NAME%TYPE     := c_packagename||'.'||'SetInventoryRules';
      l_start_date          MASTER_PROC.PROC_LOG.START_TIME%TYPE    := systimestamp;
      l_result              VARCHAR2(4000);
      p_result_code         NUMBER ;
      l_last_update_dtm     TIMESTAMP(6) WITH TIME ZONE;
      l_site_rules          MASTER.SITE_RULES%ROWTYPE;



BEGIN
      -- TIMESTAMP
      select to_timestamp_tz(to_char( sysdate, 'DD/MM/YYYY HH24:MI:SS') || ' ' || to_char((level -12), 'S00')|| ':00', 'DD/MM/YYYY HH24:MI:SS TZH:TZM')
        into l_last_update_dtm  from dual  connect by level < 1 ;

      -- ERROR NULL Controle le paramètre d'entré null
      IF p_TAB_INVENTORY_RULE_TYPE IS NULL THEN
             p_result_code  := PCK_API_CONSTANTS.errnum_requiredparam ;
             l_result       := '[API_CORE] ' || PCK_API_CONSTANTS.errmsg_requiredparam || 'INPUT NULL' ;
             RAISE_APPLICATION_ERROR( p_result_code, l_result);
      END IF;


      FOR indx IN p_TAB_INVENTORY_RULE_TYPE.FIRST .. p_TAB_INVENTORY_RULE_TYPE.LAST
      LOOP


           -- Check parameters are correct
           InventoryRulesBySite (
                p_INVENTORY_RULE_TYPE  => p_TAB_INVENTORY_RULE_TYPE(indx)
              , p_site_rules           => l_site_rules
           );

           -- PROPERTY_VALUE must be not null
           IF p_TAB_INVENTORY_RULE_TYPE(indx).PROPERTY_VALUE IS NULL THEN
                 p_TAB_INVENTORY_RULE_TYPE(indx).CHECK_RESULT := PCK_API_CONSTANTS.errnum_requiredparam ;
                 continue;
           END IF ;

           -- Rule does not exist, insert
           IF p_TAB_INVENTORY_RULE_TYPE(indx).CHECK_RESULT = PCK_API_CONSTANTS.errnum_rulenotexists THEN

                 -- C'est alors OK car on a bien inseré la nouvelle valeur
                 p_TAB_INVENTORY_RULE_TYPE(indx).CHECK_RESULT := 0 ;

                  -- C'est bon
                 INSERT INTO MASTER.SITE_RULES
                  (
                      site_id
                    , pda_property_id
                    , pda_property_value
                    , user_id
                  )
                 VALUES
                  (
                      l_site_rules.site_id
                    , l_site_rules.pda_property_id
                    , p_TAB_INVENTORY_RULE_TYPE(indx).PROPERTY_VALUE
                    , 0
                  );


           END IF;

           -- Rule exists, update new value
           IF p_TAB_INVENTORY_RULE_TYPE(indx).CHECK_RESULT = 0 THEN

                -- UPDATE IF aleready exists
                update master.site_rules
                   set pda_property_value = p_TAB_INVENTORY_RULE_TYPE(indx).PROPERTY_VALUE
                     , laste_update_dtm = l_last_update_dtm
                 where pda_property_id = l_site_rules.pda_property_id
                   and site_id = l_site_rules.site_id
                     ;
           END IF;


      END LOOP ;

      COMMIT ;


EXCEPTION
      WHEN OTHERS THEN
             MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit , p_start_time => l_start_date );
             COMMIT;
             p_result_code := PCK_API_CONSTANTS.errnum_oracle_exception ;
             RAISE;

END SetInventoryRulesBySite;

-- ---------------------------------------------------------------------------
--  UNIT         : GetInventoryRulesBySite
--  DESCRIPTION  :
--
--
--  IN           : @Param p_TAB_INVENTORY_RULE_TYPE                      - liste of inventory Rules to request
--
--  OUT          : @Param p_TAB_INVENTORY_RULE_TYPE                      - liste of obtained inventory rule values with return status
--                 @Param p_result_code                                  - if  0, everything is ok
--                                                                         ij -n, there are n values failed
---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.04.11 | Leang NGUON
--
-- ---------------------------------------------------------------------------
PROCEDURE GetInventoryRulesBySite ( p_TAB_INVENTORY_RULE_TYPE IN OUT NOCOPY TAB_INVENTORY_RULE_TYPE)
IS
      l_unit                MASTER_PROC.PROC_LOG.PROC_NAME%TYPE     := c_packagename||'.'||'SetInventoryRules';
      l_start_date          MASTER_PROC.PROC_LOG.START_TIME%TYPE    := systimestamp;
      l_result              VARCHAR2(4000);
      p_result_code         NUMBER ;
      l_site_rules          MASTER.SITE_RULES%ROWTYPE;

BEGIN


      -- ERROR NULL Controle le paramètre d'entré null
      IF p_TAB_INVENTORY_RULE_TYPE IS NULL THEN
             p_result_code  := PCK_API_CONSTANTS.errnum_requiredparam ;
             l_result       := '[API_CORE] ' || PCK_API_CONSTANTS.errmsg_requiredparam || 'INPUT NULL' ;
             RAISE_APPLICATION_ERROR( p_result_code, l_result);
      END IF;


      FOR indx IN p_TAB_INVENTORY_RULE_TYPE.FIRST .. p_TAB_INVENTORY_RULE_TYPE.LAST
      LOOP

           -- Check parameters are correct
           InventoryRulesBySite (
                p_INVENTORY_RULE_TYPE  => p_TAB_INVENTORY_RULE_TYPE(indx)
              , p_site_rules           => l_site_rules
           );

           -- Rule exists, update new value
           IF p_TAB_INVENTORY_RULE_TYPE(indx).CHECK_RESULT = 0 THEN

                p_TAB_INVENTORY_RULE_TYPE(indx).PROPERTY_VALUE := l_site_rules.pda_property_value ;

           END IF;

      END LOOP ;

      -- C'est OK
      COMMIT ;


EXCEPTION
      WHEN OTHERS THEN
             MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit , p_start_time => l_start_date );
             COMMIT;
             p_result_code := PCK_API_CONSTANTS.errnum_oracle_exception ;
             RAISE;

END GetInventoryRulesBySite;



END PCK_BO_SITE_INFO;

/