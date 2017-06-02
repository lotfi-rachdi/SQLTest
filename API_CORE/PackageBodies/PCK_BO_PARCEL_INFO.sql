CREATE OR REPLACE PACKAGE BODY api_core.PCK_BO_PARCEL_INFO
-- ***************************************************************************
--  PACKAGE BODY : API_CORE.PCK_BO_PARCEL_INFO
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
--          | Q_OPENNED_PARCEL renommé à Q_OPEN_PARCEL
--          | BO_PARCEL_ID et SITE_ID deviennent INTEGER
--          | MAPPED_PARCEL_STATE_DTM passe à DATE et sera converti à l'heure locale du SITE
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
--  V01.XXX | 2015.07.XX | À FAIRE
--          | CARRIER_NAME (AKA FIRM_ID) : pour être cohérent avec le comportement des PDA,
--          | s'il y a un _ ("underscore") dans le carrier_name, seulement la partie avant le 1r underscore
--          | s'affiche
--          | est-ce que c'est à la partie Oracle de faire ça??
--          | Ou alors une transformation dans l'affichage coté Web Appli?
--          | Ou dans le "passe-plat" du Web API?
--          | ou alors nous rajoutons une colonne "display FIRM_ID" en plus, comme ça nous avons les deux?
--          | serait-il en fait une autre colonne dans CARRIER (qui coincide souvent avec le CARRIER_NAME rabioté?
--          | --> attention il y a des transformations comme ça aussi en dur dans le code pour des tracings, ça a l'air du spécifique
--          | à étudier pour prendre en compte dans la paramétrization
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
--  V01.510 | 2016.01.08 | Hocine HAMMOU
--          | [10163] MODE DECONNECTE
--          | Remplacer TAB_PARCEL_SRCH_TYPE (supprimé) par TAB_PARCEL_INFO_TYPE
--          |
--  V01.515 | 2016.02.15 | Hocine HAMMOU
--          | [10093] MODE DECONNECTE
--          | Modification de GetSiteParcelsCore : prise en compte également des file_id d'event en attente
--          | pour des colis inconnus dans le BO ( suite à pb de réception d'encours par exemple)
--          |
--  V01.516 | 2016.02.25 | Hocine HAMMOU
--          | Bug 40017 : MCO#774 - Colis déjà scannée dans la WebApp
--          | Modification de la FUNCTION CALCULATE_MAPPED_PARCEL_STATE et de la PROCEDURE GetSiteParcels
--          | Bug 40211 : MCO#785 - Colis à préparer ne remontent pas dans la web-app
--          | Modification de la FUNCTION CALCULATE_MAPPED_PARCEL_STATE et de la PROCEDURE GetSiteParcels
--          |
--  V01.517 | 2016.05.23 | Hocine HAMMOU
--          | Remplacement du coalesce dans les clauses WHERE et ajout du LAST_UPDATE_DTM de MASTER.PARCEL (cf. partitionnement de table)
--          |
--  V01.518 | 2016.06.07 | Hocine HAMMOU
--          | Ajout TRIM dans la clause de concaténation shipto_lastname et l_parcel.shipto_firstname
--          |
--  V01.519 | 2016.08.29 | Hocine HAMMOU
--          | Ajout de la fonction GetSiteParcelsCore qui appelle la procédure du même nom
--          |
--  V01.520 | 2017.03.13 | Hocine HAMMOU
--          | Mise à 0 des reserves lorsqeu le colis n'pas de d'état  (current_step_id is null)
--          | Cas du SWAP avec les colis retours
--          |
--TODO prise en compte de la recherche par firm_parcel_other
-- ***************************************************************************
IS
c_packagename CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ;
c_LINE_STATE_TO_BE_PROCESSED  CONSTANT NUMBER(1) := 0 ;

c_COD_AMOUNT_PAID       CONSTANT VARCHAR2(30) := 'COD_AMOUNT_PAID' ;
c_COD_MEANS_PAYMENT_ID  CONSTANT VARCHAR2(30) := 'COD_MEANS_PAYMENT_ID' ;
c_DOO_AMOUNT_PAID       CONSTANT VARCHAR2(30) := 'DOO_AMOUNT_PAID' ;
c_DOO_CURRENCY          CONSTANT VARCHAR2(30) := 'DOO_CURRENCY' ;
c_COD_CURRENCY          CONSTANT VARCHAR2(30) := 'COD_CURRENCY' ;
c_ROD_AMOUNT_PAID       CONSTANT VARCHAR2(30) := 'ROD_AMOUNT_PAID' ;
c_ROD_MEANS_PAYMENT_ID  CONSTANT VARCHAR2(30) := 'ROD_MEANS_PAYMENT_ID' ;


FUNCTION CALCULATE_MAPPED_PARCEL_STATE(p_CURRENT_STEP_ID MASTER.PARCEL.CURRENT_STEP_ID%TYPE, p_CURRENT_PARCEL_STEPS_ID MASTER.PARCEL.CURRENT_PARCEL_STEPS_ID%TYPE, p_CURRENT_STEP_ISVALID MASTER.PARCEL.CURRENT_STEP_ISVALID%TYPE )
RETURN VARCHAR2
IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'CALCULATE_MAPPED_PARCEL_STATE';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_mapped_parcel_state varchar2(30);
BEGIN
   CASE
    WHEN p_CURRENT_STEP_ID IS NULL THEN l_mapped_parcel_state := NULL ; -- FAUT-IL PRENDRE CE CAS COMME UNE ERREUR/ ???? LA DONNEE N'ETANT PAS OBLIGATOIRE
                             --------------------------------------------------
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_SHIPMENT                  THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_SHIPPED;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_DROPOFF_SEND              THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_DROPPEDOFF;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_CARRIER                   THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_SHIPPED;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_REFUSE_PUDO               THEN
       IF MASTER_PROC.PCK_STEP.GetParcelSteps(p_PARCEL_STEPS_ID => p_CURRENT_PARCEL_STEPS_ID).STEP_MOTIVE_ID = PCK_API_CONSTANTS.c_motive_REFUSED_BY_SHIPFROM THEN
          l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_REFUSED;
       ELSE
          l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_SHIPPED;
       END IF;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_DELIVERY                 THEN
       IF p_CURRENT_STEP_ISVALID = 1 THEN
          l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_DELIVERED_ACK;
       ELSE
          l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_DELIVERED;
       END iF;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_PICKUP                   THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_PICKEDUP;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_PREPARATION              THEN
       IF p_CURRENT_STEP_ISVALID = 1 THEN
          --l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_PREPARED;
          l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_PREP_FOR_COLL;  -- PREPARED FOR COLLECTION
       ELSE
          l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_TO_PREPARE;
       END iF;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_DROPOFF                  THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_DROPPEDOFF;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_COLLECTION               THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_COLLECTED;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_COLLECTION_CARRIER       THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_COLLECTED;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_REFUSE_PUDO_RETURN       THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_SHIPPED;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_DELIVERY_PUDO_RETURN     THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_DELIVERED;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_PICKUP_SHIPFROM          THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_PICKEDUP;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_PICKUP_SHIPPER           THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_PICKEDUP;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_PREPARATION_SEND         THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_PREPARED;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_CARRIER_WASTE_SHIPFROM   THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_COLLECTED;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_CARRIER_WASTE_SHIPTO     THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_COLLECTED;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_REFUSE_CARRIER_WASTE     THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_SHIPPED;
    WHEN p_CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_CARRIER_WASTE            THEN l_mapped_parcel_state := PCK_API_CONSTANTS.c_mapped_state_DELIVERED;
  END CASE;

  RETURN l_mapped_parcel_state;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '|| Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace);
      RAISE;
END CALCULATE_MAPPED_PARCEL_STATE;


-- ---------------------------------------------------------------------------
--  UNIT         : GetParcelProperties
--  DESCRIPTION  : Récupère les propriétés d'un parcel donné
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.11.24 | Hocine HAMMOU
--          | version initiale
--          | Récupère les parcel properties , de préférence celles envoyés par le carrier (SOURCE_TYPE_ID=2)
--          | TODO faut-il vraiment filtrer que sur SOURCE_TYPE_ID à 2 ???
-- ---------------------------------------------------------------------------
PROCEDURE GetParcelProperties (p_parcel_id IN MASTER.PARCEL.PARCEL_ID%TYPE, p_tab_parcel_properties OUT NOCOPY api_core.TAB_PROPERTY_TYPE)
IS
  l_unit                  MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetParcelProperties';
  l_start_date            MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN

   SELECT api_core.PROPERTY_TYPE(c.PARCEL_PROPERTY_NAME , pp.PARCEL_PROPERTY_VALUE )
   BULK COLLECT INTO p_tab_parcel_properties
   FROM PARCEL p
   INNER JOIN PARCEL_PROPERTIES pp ON (pp.parcel_id = p.parcel_id)
   INNER join CONFIG.PARCEL_PROPERTY c on c.PARCEL_PROPERTY_ID = pp.PARCEL_PROPERTY_ID
   INNER JOIN PARCEL_PROPERTY ON (PARCEL_PROPERTY.PARCEL_PROPERTY_ID = pp.parcel_property_id AND pp.event_id IS NULL )
   WHERE p.parcel_id = p_parcel_id
   AND p.SHIPMENT = 1 -- parcel pour lequel un EDI encours été réceptionné
   AND pp.SOURCE_TYPE_ID = 2 -- parcel properties crées par le CARRIER
   ;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      NULL;
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace);
      RAISE;
END GetParcelProperties;


-- ---------------------------------------------------------------------------
--  UNIT         : GetPaymentSummary
--  DESCRIPTION  : Procédure qui récupère la liste des paiements effectués dans le cadre du COD, ROD et DOO
--
--  IN           : p_PARCEL_ID as MASTER.PARCEL.PARCEL_ID%TYPE
--  OUT          : p_payment_summary as API_CORE.PAYMENT_SUMMARY_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.12.20 | Hocine HAMMOU
--          | version initiale
-- ---------------------------------------------------------------------------
PROCEDURE GetPaymentSummary(p_INTERNATIONAL_SITE_ID IN MASTER.SITE.SITE_INTERNATIONAL_ID%TYPE, p_PARCEL_ID IN MASTER.PARCEL.PARCEL_ID%TYPE, p_payment_summary OUT NOCOPY api_core.PAYMENT_SUMMARY_TYPE ) IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetPaymentSummary';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams VARCHAR2(4000);
   l_site_ID MASTER.SITE.SITE_ID%TYPE;
   l_SiteTestTypeId NUMBER(1);
BEGIN

   p_payment_summary := NULL;

   IF p_INTERNATIONAL_SITE_ID IS NOT NULL AND p_PARCEL_ID IS NOT NULL THEN

      p_payment_summary := PAYMENT_SUMMARY_TYPE();

      WITH properties as ( select PARCEL_PROPERTY_ID, c.PARCEL_PROPERTY_NAME
                         from CONFIG.PARCEL_PROPERTY c
                           where c.PARCEL_PROPERTY_NAME IN ( c_COD_AMOUNT_PAID
                                                            ,c_COD_MEANS_PAYMENT_ID
                                                            ,c_DOO_AMOUNT_PAID
                                                            ,c_DOO_CURRENCY
                                                            ,c_COD_CURRENCY
                                                            ,c_ROD_AMOUNT_PAID
                                                            ,c_ROD_MEANS_PAYMENT_ID )
      )
      , parcels as ( select p.SITE_ID                 SITE_ID
                          , p.SITE_INTERNATIONAL_ID   SITE_INTERNATIONAL_ID
                          , p.PARCEL_ID               PARCEL_ID
                          , p.FIRM_PARCEL_CARRIER     FIRM_PARCEL_CARRIER
                          , p.EVENT_ID                EVENT_ID
                          , pp.PARCEL_PROPERTY_ID     PARCEL_PROPERTY_ID
                          , c.PARCEL_PROPERTY_NAME    PARCEL_PROPERTY_NAME
                          , pp.PARCEL_PROPERTY_VALUE  PARCEL_PROPERTY_VALUE
                          --, t.EVENT_TYPE_NAME       EVENT_TYPE_NAME
                          , p.DTM                     DTM -- en UTC
                     from ( select *
                            from ( select s.SITE_ID                   SITE_ID
                                        , s.SITE_INTERNATIONAL_ID     SITE_INTERNATIONAL_ID
                                        , p.parcel_id                 PARCEL_ID
                                        , p.FIRM_PARCEL_CARRIER       FIRM_PARCEL_CARRIER
                                        , e.EVENT_ID                  EVENT_ID
                                        , MIN(SYS_EXTRACT_UTC(e.DTM)) DTM -- en UTC
                                        --, first_value(SYS_EXTRACT_UTC(e.DTM))    over (partition by e.EVENT_ID order by e.DTM desc)   AS DTM
                                        from master.site s
                                        inner join master.parcel p on ( p.site_id_delivery = s.site_id
                                                                         or p.site_id_dropoff = s.site_id
                                                                         or p.site_id_delivery_target = s.site_id
                                                                         or p.site_id_dropoff_target = s.site_id
                                                                         )
                                        inner join MASTER.PARCEL_PROPERTIES pp on p.PARCEL_ID = pp.PARCEL_ID
                                        inner join properties c on c.PARCEL_PROPERTY_ID = pp.PARCEL_PROPERTY_ID
                                        inner join MASTER.EVENT e on pp.EVENT_ID = e.EVENT_ID
                                        inner join CONFIG.EVENT_TYPE t on e.EVENT_TYPE_ID = t.EVENT_TYPE_ID
                                        where s.SITE_INTERNATIONAL_ID = p_INTERNATIONAL_SITE_ID
                                        and p.parcel_id = p_PARCEL_ID
                                        and p.LAST_UPDATE_DTM > ( SYSDATE - PCK_API_CONSTANTS.c_MAX_DAYS_TO_SEARCH )
                                        and p.PARCEL_STATE_ID < PCK_API_CONSTANTS.c_Parcel_State_ID_FORCLOS
                                        and s.SITE_ID = e.SOURCE_ID
                                        group by s.SITE_ID, s.SITE_INTERNATIONAL_ID,p.parcel_id , p.FIRM_PARCEL_CARRIER ,e.EVENT_ID )
                            where rownum = 1
                     ) p
                     inner join MASTER.PARCEL_PROPERTIES pp on pp.PARCEL_ID = p.PARCEL_ID and pp.EVENT_ID = p.EVENT_ID
                     inner join properties c on c.PARCEL_PROPERTY_ID = pp.PARCEL_PROPERTY_ID
      )
      , payment as
      (
      -- Liste COD
      select p1.FIRM_PARCEL_CARRIER AS FIRM_PARCEL_ID, 'COD' AS PAYMENT_PRESTATION, p1.DTM AS PAYMENT_DATE, p1.PARCEL_PROPERTY_VALUE AS AMOUNT_PAID, p2.PARCEL_PROPERTY_VALUE as MEANS_PAYMENT_ID
      from parcels p1, parcels p2
      where p1.event_id = p2.event_id
      and p1.PARCEL_PROPERTY_NAME = 'COD_AMOUNT_PAID'      -- property COD_AMOUNT_PAID
      and p2.PARCEL_PROPERTY_NAME = 'COD_MEANS_PAYMENT_ID' -- property COD_MEANS_PAYMENT_ID

      -- Liste ROD
      union
      select p1.FIRM_PARCEL_CARRIER AS FIRM_PARCEL_ID, 'ROD' AS PAYMENT_PRESTATION, p1.DTM AS PAYMENT_DATE, p1.PARCEL_PROPERTY_VALUE AS AMOUNT_PAID, p2.PARCEL_PROPERTY_VALUE as MEANS_PAYMENT_ID
      from parcels p1, parcels p2
      where p1.event_id = p2.event_id
      and p1.PARCEL_PROPERTY_NAME = 'ROD_AMOUNT_PAID'      -- property ROD_AMOUNT_PAID
      and p2.PARCEL_PROPERTY_NAME = 'ROD_MEANS_PAYMENT_ID' -- property ROD_MEANS_PAYMENT_ID

      -- Liste DROP-OFF OFFLINE ( PAIEMENT ETIQUETTE AUPRES DU PUDO )
      union
      select p1.FIRM_PARCEL_CARRIER AS FIRM_PARCEL_ID, 'DOO' AS PAYMENT_PRESTATION, p1.DTM AS PAYMENT_DATE, p1.PARCEL_PROPERTY_VALUE AS AMOUNT_PAID, NULL as MEANS_PAYMENT_ID
      from parcels p1
      where p1.PARCEL_PROPERTY_NAME = 'DOO_AMOUNT_PAID' -- property DOO_AMOUNT_PAID
      )
      SELECT PAYMENT_SUMMARY_TYPE(FIRM_PARCEL_ID, PAYMENT_PRESTATION, PAYMENT_DATE, AMOUNT_PAID, MEANS_PAYMENT_ID)
      INTO p_payment_summary
      FROM payment ;

   END IF;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      NULL;
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetPaymentSummary;


-- ---------------------------------------------------------------------------
--  UNIT         : GetPaymentSummary
--  DESCRIPTION  : Fonction aui appelle la procédure du meme nom
--
--  IN           : p_PARCEL_ID as MASTER.PARCEL.PARCEL_ID%TYPE
--  OUT          : p_payment_summary as API_CORE.PAYMENT_SUMMARY_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.12.20 | Hocine HAMMOU
--          | version initiale
-- ---------------------------------------------------------------------------
FUNCTION GetPaymentSummary(p_INTERNATIONAL_SITE_ID IN MASTER.SITE.SITE_INTERNATIONAL_ID%TYPE, p_PARCEL_ID IN MASTER.PARCEL.PARCEL_ID%TYPE) RETURN api_core.PAYMENT_SUMMARY_TYPE IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetPaymentSummary';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_payment_type api_core.PAYMENT_SUMMARY_TYPE;
BEGIN

   GetPaymentSummary(p_INTERNATIONAL_SITE_ID => p_international_site_id, p_parcel_id => p_PARCEL_ID, p_payment_summary => l_payment_type) ;

   RETURN l_payment_type;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetPaymentSummary;


-- ---------------------------------------------------------------------------
--  UNIT         : PARCEL INFO DETAILS
--                 CETTE PROGRAM UNIT EST PRIVÉE ET NE DOIT JAMAIS FIGURER DANS LE PACKAGE SPECIFICATION
--                 Elle ne doit etre appellée que par parcel_info après validation de paramètres
--
--  DESCRIPTION  : recupère les infos d'un colis à partir de son FIRM_PARCEL_ID
--  IN           : p_parcel_info_type.FIRM_PARCEL_ID
--  OUT          : p_parcel_info_type aura les infos sur le colis
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.09.11 | Hocine HAMMOU
--          | version initiale
--          |
--  V01.000 | 2016.10.17 | Hocine HAMMOU
--          | Bug 63668 : Suppression du NVL sur le COD_AMOUNT. Si COD_AMOUNT est NULL, alors on envoie NULL
--          |
--  V01.001 | 2016.11.24 | Hocine HAMMOU
--          | Ajout du tableau de parcel properties
-- ---------------------------------------------------------------------------
PROCEDURE parcel_info_details ( p_parcel_info_type IN OUT NOCOPY PARCEL_INFO_TYPE, P_INTERNATIONAL_SITE_ID IN VARCHAR2, p_site_ID IN MASTER.SITE.SITE_ID%TYPE )
IS
  l_unit                  MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'PARCEL_INFO_DETAILS';
  l_start_date            MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_carrier               CARRIER%ROWTYPE;
  l_parcel                PARCEL%ROWTYPE := NULL;
  l_parcel_extend         PARCEL_EXTEND%ROWTYPE;
  l_country_code          MASTER.SITE.COUNTRY_CODE%TYPE;
  l_language_code         MASTER.SITE.LANGUAGE_CODE%TYPE;
  l_timezone              MASTER.SITE.TIMEZONE%TYPE;
  l_parcel_site_ID        MASTER.SITE.SITE_ID%TYPE;
  p_tab_event_file_id     IMPORT_PDA.PCK_EVENT_IMPORTED.TAB_ELEMENT_NUMBER_TYPE;
  --l_tab_event_file_id   API_CORE.TAB_ELEMENT_NUMBER_TYPE;
  l_tab_parcel_properties api_core.TAB_PROPERTY_TYPE;
  l_payment_type          api_core.PAYMENT_SUMMARY_TYPE;

BEGIN

   -- -------------------------------------------------------------------------------------------------------------------------
   -- Recherche colis et informations transporteur par la fonction FindParcel(p_Firm_Parcel PARCEL.FIRM_PARCEL_CARRIER%TYPE)
   -- -------------------------------------------------------------------------------------------------------------------------
   l_parcel := pck_parcel.FindParcel(p_Firm_Parcel => p_parcel_info_type.FIRM_PARCEL_ID);

   --TODO?? prise en compte de la recherche par firm_parcel_other

   IF l_parcel.parcel_id IS NOT NULL THEN
      p_parcel_info_type.FIRM_PARCEL_ID          := l_parcel.firm_parcel_carrier;
      p_parcel_info_type.BO_PARCEL_ID            := l_parcel.parcel_id;
      p_parcel_info_type.CREATOR                 := PCK_API_CONSTANTS.c_PARCEL_INFO_CREATOR; -- par défaut toujours BO
      p_parcel_info_type.CODAMOUNT               := l_parcel.COD_AMOUNT;
      p_parcel_info_type.CUSTOMER_NAME           := trim(l_parcel.shipto_lastname || ' ' || l_parcel.shipto_firstname); --information à récupérer

      -- -----------------------------------------------------------------------------
      -- RECUPERATION DE INTERNATIONAL_SITE_ID ASSOCIE AU SITE DEDUIT PAR LE COALESCE
      -- -----------------------------------------------------------------------------
      l_parcel_site_ID := COALESCE(l_parcel.site_id_delivery, l_parcel.site_id_dropoff, l_parcel.site_id_delivery_target, l_parcel.site_id_dropoff_target);
      p_parcel_info_type.INTERNATIONAL_SITE_ID := MASTER_PROC.PCK_SITE.GetSiteInternationalID(l_parcel_site_ID);

      -- -----------------------------------------------------------------------------
      -- MAPPED_PARCEL_STATE_DTM passe à DATE et sera converti à l'heure locale du SITE appellant
      -- -----------------------------------------------------------------------------
      MASTER_PROC.pck_site.GetNLSBySiteId(p_site_id => p_site_id, p_country_code => l_country_code, p_language_code => l_language_code, p_timezone => l_timezone );
      p_parcel_info_type.MAPPED_PARCEL_STATE_DTM := l_parcel.current_step_dtm AT TIME ZONE PCK_API_CONSTANTS.c_TIMESTAMP_TIME_ZONE_UTC ; -- [10093] RM1 2016.02.17 RENVOI DE LA DATE/HEURE AU FORMAT UTC

      -- -----------------------------------------------------------------------------
      -- Transcodification du step colis en state
      -- -----------------------------------------------------------------------------
      p_parcel_info_type.MAPPED_PARCEL_STATE := Calculate_Mapped_Parcel_State(p_CURRENT_STEP_ID         => l_parcel.CURRENT_STEP_ID
                                                                            , p_CURRENT_PARCEL_STEPS_ID => l_parcel.CURRENT_PARCEL_STEPS_ID
                                                                            , p_CURRENT_STEP_ISVALID    => l_parcel.CURRENT_STEP_ISVALID
                                                                             );

      -- -----------------------------------------------------------------------------
      -- Recherche du CARRIER_NAME
      -- -----------------------------------------------------------------------------
      l_carrier := pck_carrier.GetCarrier(p_carrier_id => l_parcel.carrier_id);
      p_parcel_info_type.FIRM_ID := l_carrier.carrier_name; --information à récupérer dans CONFIG.CARRIER.CARRIER_NAME%TYPE

      -- -----------------------------------------------------------------------------
      -- Recherche du ParcelExtendS
      -- -----------------------------------------------------------------------------
      l_parcel_extend := pck_parcel.GetParcelExtend(l_parcel.parcel_id);
      p_parcel_info_type.SHIPPING_DTM := l_parcel_extend.shipping_dtm ;-- information à récupérer MASTER.PARCEL_EXTEND.SHIPPING_DTM%TYPE
      p_parcel_info_type.KEEPING_PERIOD := pck_shipper.GetShipperParam(l_parcel_extend.shipfrom_id, l_parcel.shipper_group_id, l_parcel.carrier_id).cnr_duration  ; --information à récupérer

      -- -----------------------------------------------------------------------------
      -- Recherche de reserves
      -- -----------------------------------------------------------------------------
      IF l_parcel.CURRENT_PARCEL_STEPS_ID IS NOT NULL THEN
         -- on check si présence de la réserve Q_DAMAGED_PARCEL
         p_parcel_info_type.Q_DAMAGED_PARCEL := MASTER_PROC.PCK_STEP.IsExistParcelStepsReserve(p_ParcelStepsID => l_parcel.CURRENT_PARCEL_STEPS_ID, p_ReserveTypeName => PCK_API_CONSTANTS.c_RESERVE_DAMAGED_PARCEL);

         -- on check si présence de la réserve Q_OPEN_PARCEL
         p_parcel_info_type.Q_OPEN_PARCEL := MASTER_PROC.PCK_STEP.IsExistParcelStepsReserve(p_ParcelStepsID => l_parcel.CURRENT_PARCEL_STEPS_ID, p_ReserveTypeName => PCK_API_CONSTANTS.c_RESERVE_OPEN_PARCEL);
      ELSE -- 2017.03.13 Set à 0 les reserves lorsque le colis n'a pas d'état
         p_parcel_info_type.Q_DAMAGED_PARCEL := 0 ;
         p_parcel_info_type.Q_OPEN_PARCEL := 0 ;
      END IF;


      -- ------------------------------------------------------------------------------------------------------------------
      -- [10163] recuperation des file_id des events en attente d'etre traités par le PROCESS ALL pour le mode deconnecté
      -- ------------------------------------------------------------------------------------------------------------------

      IMPORT_PDA.PCK_EVENT_IMPORTED.GetUnprocessedEventFileID ( p_FIRM_PARCEL_CARRIER => p_parcel_info_type.FIRM_PARCEL_ID, p_tab_event_file_id => p_tab_event_file_id );
      IF p_tab_event_file_id.COUNT > 0 THEN
         p_parcel_info_type.TAB_EVENT_FILE_ID := NEW api_core.TAB_ELEMENT_NUMBER_TYPE();
         p_parcel_info_type.TAB_EVENT_FILE_ID.EXTEND(p_tab_event_file_id.COUNT);
         FOR i IN p_tab_event_file_id.FIRST .. p_tab_event_file_id.LAST
         LOOP
            p_parcel_info_type.TAB_EVENT_FILE_ID(i) := p_tab_event_file_id(i);
         END LOOP;
      END IF;

      -- ------------------------------------------------------------------------------------------------------------------
      -- [10472] Récuperation d'eventuels parcel properties crées par le tracing d'encours carrier
      -- ------------------------------------------------------------------------------------------------------------------
      GetParcelProperties(p_parcel_id => l_parcel.parcel_id, p_tab_parcel_properties => l_tab_parcel_properties) ;
      IF l_tab_parcel_properties IS NOT NULL THEN
         IF l_tab_parcel_properties.COUNT > 0 THEN
            p_parcel_info_type.TAB_PARCEL_PROPERTIES := l_tab_parcel_properties ;
         END IF;
      END IF;

      -- ------------------------------------------------------------------------------------------------------------------
      -- [10472] Fonctionnalité du Payment Summary
      -- ------------------------------------------------------------------------------------------------------------------
      GetPaymentSummary(p_INTERNATIONAL_SITE_ID => p_INTERNATIONAL_SITE_ID, p_parcel_id => l_parcel.parcel_id, p_payment_summary => l_payment_type) ;
      IF l_payment_type IS NOT NULL THEN
         p_parcel_info_type.payment := l_payment_type ;
      END IF;

      MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] PARCEL INFO REQUEST (FIRM_PARCEL_ID:'|| p_parcel_info_type.FIRM_PARCEL_ID || '-ELAPSED TIME:'||api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );
   ELSE
      MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] PARCEL INFO REQUEST (FIRM_PARCEL_ID:'|| p_parcel_info_type.FIRM_PARCEL_ID || ' NOT EXISTS-ELAPSED TIME:'||api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace);
      RAISE;
END parcel_info_details;


-- ---------------------------------------------------------------------------
--  UNIT         : PARCEL INFO
--  DESCRIPTION  : recupère les infos d'un colis à partir de son FIRM_PARCEL_ID
--  IN           : p_parcel_info_type.FIRM_PARCEL_ID
--  OUT          : p_parcel_info_type aura les infos sur le colis
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.11 | Hocine HAMMOU
--          | version initiale
--  V01.100 | 2015.06.24 | Maria CASALS
--          | Q_OPENNED_PARCEL renommé à Q_OPEN_PARCEL
--          | MAPPED_PARCEL_STATE_DTM passe à DATE et sera converti à l'heure locale du SITE
--          |   => il nous faut le site_id de l'utilisateur
--  V01.150 | 2015.07.10 | Hocine HAMMOU
--          | Ajout de la donnée INTERNATIONAL_SITE_ID en complément/remplacement de SITE_ID
-- ---------------------------------------------------------------------------
PROCEDURE parcel_info ( p_parcel_info_type IN OUT NOCOPY PARCEL_INFO_TYPE, P_INTERNATIONAL_SITE_ID IN VARCHAR2 )
IS
  l_unit                  MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'PARCEL_INFO';
  l_start_date            MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_requiredparams        VARCHAR2(4000);
  l_site_ID               MASTER.SITE.SITE_ID%TYPE; --L international traduit
  l_SiteTestTypeId        NUMBER(1);
BEGIN

   -- --------------------------------------------------------------------------------
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   -- --------------------------------------------------------------------------------
   IF TRIM(p_parcel_info_type.FIRM_PARCEL_ID) IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'P_FIRM_PARCEL');
   END IF;

   IF TRIM(p_INTERNATIONAL_SITE_ID ) IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'P_INTERNATIONAL_SITE_ID');
   END IF;

   -- --------------------------------------------------------------------------------
   -- RAISE EXCEPTION EN CAS DE DONNEES OBLIGATOIRES NON RENSEIGNEES
   -- --------------------------------------------------------------------------------
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- --------------------------------------------------------------------------------
   -- RECUPERATION DU SITE_ID à partir de INTERNATIONAL_SITE_ID
   -- --------------------------------------------------------------------------------
   l_site_ID := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => P_INTERNATIONAL_SITE_ID );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || P_INTERNATIONAL_SITE_ID);
   END IF;

   -- --------------------------------------------------------------------------------
   -- CONTROLE SI PUDO DE FORMATION et traitement différent dans ce cas-là
   -- --------------------------------------------------------------------------------
   l_SiteTestTypeId := PCK_SITE.SiteTestTypeId( p_site_id => l_site_id );

   IF l_SiteTestTypeId = PCK_SITE.c_SITE_TEST_TYPE_ID_NO_TEST THEN
      PARCEL_INFO_DETAILS(p_parcel_info_type => p_parcel_info_type,P_INTERNATIONAL_SITE_ID => P_INTERNATIONAL_SITE_ID , p_site_ID => l_site_id);
   ELSE
      NULL;
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_wrong_site_type_id,PCK_API_CONSTANTS.errmsg_wrong_site_type_id||'(TYPE:'||l_SiteTestTypeId || '-SITE:'||P_INTERNATIONAL_SITE_ID||').');
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '|| Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END parcel_info;

-- ---------------------------------------------------------------------------
--  UNIT         : PARCEL INFO
--  DESCRIPTION  : Voir procedure homonyme
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.11 | Hocine HAMMOU
--          | version initiale
--  V01.100 | 2015.06.24 | Maria CASALS
--          | rajout p_SITE_ID
--  V01.110 | 2015.07.10 | Hocine HAMMOU
--          | Remplacement de SITE_ID par INTERNATIONAL_SITE_ID
-- ---------------------------------------------------------------------------
--PROCEDURE parcel_info ( p_firm_parcel in VARCHAR2 , p_parcel_info_type OUT NOCOPY PARCEL_INFO_TYPE, p_SITE_ID IN INTEGER )
PROCEDURE parcel_info ( p_firm_parcel in VARCHAR2 , p_parcel_info_type OUT NOCOPY PARCEL_INFO_TYPE, P_INTERNATIONAL_SITE_ID IN VARCHAR2 )
IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'PARCEL_INFO';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;

BEGIN
   -- INSTANTIATION DE L'OBJET PARCEL_INFO_TYPE
   p_parcel_info_type := NEW PARCEL_INFO_TYPE;
   p_parcel_info_type.FIRM_PARCEL_ID := p_firm_parcel ;

   parcel_info( p_parcel_info_type => p_parcel_info_type, p_INTERNATIONAL_SITE_ID => p_INTERNATIONAL_SITE_ID );
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace);
      RAISE;
END parcel_info;


-- ---------------------------------------------------------------------------
--  UNIT         : parcel_info
--  DESCRIPTION  : Voir procedure homonyme
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.28 | Maria CASALS
--          | version initiale
--          |
-- ---------------------------------------------------------------------------
FUNCTION  parcel_info ( p_firm_parcel in VARCHAR2 , P_INTERNATIONAL_SITE_ID IN VARCHAR2 ) RETURN PARCEL_INFO_TYPE IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'PARCEL_INFO';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_parcel_info_type PARCEL_INFO_TYPE;
BEGIN
   parcel_info ( p_firm_parcel => p_firm_parcel, p_parcel_info_type => l_parcel_info_type, P_INTERNATIONAL_SITE_ID => P_INTERNATIONAL_SITE_ID );
   RETURN l_parcel_info_type;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END parcel_info;



-- ---------------------------------------------------------------------------
--  UNIT         : GetSiteParcelsCore
--  DESCRIPTION  :
--
--  IN           :
--  OUT          :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.11.03 | Hocine HAMMOU
--          | version initiale
--
--  V01.100 | 2016.01.11 | Hocine HAMMOU
--          | Supprimer les référence PARCEL_SRCH_TYPE et les remplacer par PARCEL_INFO_TYPE
--          | Supprimer les référence TAB_PARCEL_SRCH_TYPE et les remplacer par TAB_PARCEL_INFO_TYPE
--          |
--  V01.110 | 2016.02.15 | Hocine HAMMOU
--          | [10093] MODE DECONNECTE
--          | Modification : prise en compte également des file_id d'event en attente
--          | pour des colis inconnus dans le BO ( suite à pb de réception d'encours par exemple)
--          |
--  V01.111 | 2016.08.04 | Vbr optim : supp creation_dtm > (sysdate -...) et carrier_name => select dans la colonne
--          |
--  V01.112 | 2016.10.11 | Hocine HAMMOU
--          | Suppression du "UNKNOWN" lorsque le shipto_lastname est NULL
--          |
--  V01.112 | 2016.10.17 | Hocine HAMMOU
--          | Bug 63668 : Suppression du NVL sur le COD_AMOUNT. Si COD_AMOUNT est NULL, alors on envoie NULL
--          |
-- ---------------------------------------------------------------------------
PROCEDURE GetSiteParcelsCore(p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_querytype IN INTEGER, p_NAME IN VARCHAR2  DEFAULT NULL, p_site_parcels OUT NOCOPY  api_core.TAB_PARCEL_INFO_TYPE, p_site_ID IN MASTER.SITE.SITE_ID%TYPE , p_timezone IN MASTER.SITE.TIMEZONE%TYPE )
IS
   l_CURRENT_PARCEL_STEPS_ID  MASTER.PARCEL.CURRENT_PARCEL_STEPS_ID%TYPE;
   p_tab_event_file_id        IMPORT_PDA.PCK_EVENT_IMPORTED.TAB_ELEMENT_NUMBER_TYPE;
   l_tab_parcel_properties    api_core.TAB_PROPERTY_TYPE;
   l_payment_type             api_core.PAYMENT_SUMMARY_TYPE;
BEGIN

   WITH existing_prcls AS
   ( -- CAS mapped_state_SHIPPED simple
     SELECT  p.CURRENT_STEP_DTM       CURRENT_STEP_DTM
           , p.FIRM_PARCEL_CARRIER    FIRM_PARCEL_CARRIER
           , (select c.CARRIER_NAME from CONFIG.CARRIER c where p.CARRIER_ID = c.CARRIER_ID) as CARRIER_NAME --vbr
           , p.PARCEL_ID              BO_PARCEL_ID
           , pck_shipper.GetShipperParam(pe.shipfrom_id, p.shipper_group_id, p.carrier_id).cnr_duration KEEPING_PERIOD
           , p.COD_AMOUNT             COD_AMOUNT
           , p.shipto_lastname        shipto_lastname
           , p.shipto_firstname       shipto_firstname
           , pe.shipping_dtm          SHIPPING_DTM
           --, PCK_API_CONSTANTS.c_mapped_state_SHIPPED MAPPED_PARCEL_STATE 2016.02.25
           , (CALCULATE_MAPPED_PARCEL_STATE(p_CURRENT_STEP_ID => p.CURRENT_STEP_ID, p_CURRENT_PARCEL_STEPS_ID => p.CURRENT_PARCEL_STEPS_ID, p_CURRENT_STEP_ISVALID => p.CURRENT_STEP_ISVALID )) MAPPED_PARCEL_STATE --  2016.02.25
           , p.CARRIER_ID              CARRIER_ID
           , TAB_ELEMENT_NUMBER_TYPE(NULL) TAB_EVENT_FILE_ID
           , NULL                          TAB_PARCEL_PROPERTIES
     FROM MASTER.PARCEL p
     INNER JOIN MASTER.PARCEL_EXTEND pe ON pe.PARCEL_ID = p.parcel_id
     WHERE p.LAST_UPDATE_DTM > ( SYSDATE - PCK_API_CONSTANTS.c_MAX_DAYS_TO_SEARCH )
       AND p.PARCEL_STATE_ID < PCK_API_CONSTANTS.c_Parcel_State_ID_FORCLOS
       --AND p_site_ID = COALESCE(p.site_id_delivery, p.site_id_dropoff, p.site_id_delivery_target, p.site_id_dropoff_target)  -- 2016.05.23
       AND  ( p.site_id_delivery = p_site_ID
              OR p.site_id_dropoff = p_site_ID
              OR p.site_id_delivery_target = p_site_ID
              OR p.site_id_dropoff_target = p_site_ID )
     -- cas des COLIS inconnus dans le BO ( ex: les encours n'ont pas été intégrés dans le BO )
     -- mais de fichiers venant de ce site
     )
   , nonexisting_prcls AS
   (
     SELECT  NULL                                   CURRENT_STEP_DTM        -- p.CURRENT_STEP_DTM
           , ev.FIRM_PARCEL_ID                      FIRM_PARCEL_CARRIER
           , NULL                                   CARRIER_NAME
           , NULL                                   BO_PARCEL_ID             -- p.PARCEL_ID BO_PARCEL_ID
           , NULL                                   KEEPING_PERIOD           -- pck_shipper.GetShipperParam(pe.shipfrom_id, p.shipper_group_id, p.carrier_id).cnr_duration KEEPING_PERIOD
           , NULL                                   COD_AMOUNT               -- NVL(p.COD_AMOUNT,0) COD_AMOUNT
           , NULL                                   shipto_lastname          -- p.shipto_lastname
           , NULL                                   shipto_firstname         -- p.shipto_firstname
           , NULL                                   SHIPPING_DTM             -- pe.shipping_dtm SHIPPING_DTM
           , PCK_API_CONSTANTS.c_mapped_state_NONE  MAPPED_PARCEL_STATE      -- PCK_API_CONSTANTS.c_mapped_state_COLLECTED
           , NULL                                   CARRIER_ID               -- p.CARRIER_ID
           , CAST( COLLECT( ev.FILE_ID ) AS api_core.TAB_ELEMENT_NUMBER_TYPE )  TAB_EVENT_FILE_ID
           , NULL TAB_PARCEL_PROPERTIES
     FROM IMPORT_PDA.T_EVENT_IMPORTED ev
     INNER JOIN IMPORT_PDA.T_XMLFILES x ON ev.FILE_ID = x.FILE_ID
     WHERE x.FILE_PDA_ID       = p_INTERNATIONAL_SITE_ID
       AND x.FILE_STATE        = IMPORT_PDA.PCK_XMLFILE.c_FILE_STATE_EXTRACTED_XML
       AND x.FILE_TYPE         = PCK_API_CONSTANTS.c_EVENT_XMLFILE
       AND x.FILE_CREATION_DTM > ( SYSDATE - PCK_API_CONSTANTS.c_MAX_DAYS_TO_SEARCH )
       AND ev.LINE_STATE       = c_LINE_STATE_TO_BE_PROCESSED
       AND ev.DTM              > ( SYSDATE - PCK_API_CONSTANTS.c_MAX_DAYS_TO_SEARCH )
       AND ( --  p.PARCEL_ID is null -- vraiment le colis n'est pas encore dans le BO, autrement s'il est relié à notre site il apparaitra dans les autres branches
             -- s'assurer qu'il ne s'agit pas d'un code à barres déjà traité
             --OR p.FIRM_PARCEL_CARRIER not in ( SELECT  FIRM_PARCEL_CARRIER from existing_prcls )
             ev.FIRM_PARCEL_ID not in ( SELECT  FIRM_PARCEL_CARRIER from existing_prcls )
           )
     GROUP BY ev.FIRM_PARCEL_ID
   )
   , prcls as
   ( select * from existing_prcls
     union all
     select * from nonexisting_prcls
   )
   SELECT PARCEL_INFO_TYPE (
          p.FIRM_PARCEL_CARRIER                                                                              -- FIRM_PARCEL_ID
        , p.CARRIER_NAME -- c.CARRIER_NAME                                                                   -- FIRM_ID
        , p.BO_PARCEL_ID                                 -- 2016.01.11                                          BO_PARCEL_ID
        , PCK_API_CONSTANTS.c_PARCEL_INFO_CREATOR        -- 2016.01.11                                          CREATOR
        , p.KEEPING_PERIOD                               -- 2016.01.11                                          KEEPING_PERIOD
        , p_INTERNATIONAL_SITE_ID                                                                            -- SITE_INTERNATIONAL_ID
        , p.COD_AMOUNT                                   -- 2016.01.11                                          CODAMOUNT
        , TRIM(p.shipto_lastname || ' ' || p.shipto_firstname ) --BUG 2016.06.07                             -- CUSTOMER_NAME
        , p.SHIPPING_DTM                                 -- 2016.01.11                                          SHIPPING_DTM
        , p.MAPPED_PARCEL_STATE                                                                              -- MAPPED_PARCEL_STATE
          -- CECI NE MARCHE PAS -- p.CURRENT_STEP_DTM AT TIME ZONE l_timezone                                -- MAPPED_PARCEL_STATE_DTM
          -- CECI MARCHE, AVEC ZONE EN DUR -- cast( p.CURRENT_STEP_DTM at time zone 'Europe/Berlin' as date) -- MAPPED_PARCEL_STATE_DTM
         , PCK_API_TOOLS.convert_timeZONE ( p_TIMESTWITHZONE => p.CURRENT_STEP_DTM, p_tz => PCK_API_CONSTANTS.c_TIMESTAMP_TIME_ZONE_UTC )                    -- MAPPED_PARCEL_STATE_DTM
        --, p.CURRENT_STEP_DTM AT TIME ZONE PCK_API_CONSTANTS.c_TIMESTAMP_TIME_ZONE_UTC
        , NULL                      -- 2016.01.11                                                               Q_DAMAGED_PARCEL
        , NULL                      -- 2016.01.11                                                               Q_OPEN_PARCEL
        , TAB_EVENT_FILE_ID -- NULL   -- 2016.01.11                                                             TAB_EVENT_FILE_ID
        , TAB_PARCEL_PROPERTIES  -- 2016.11.24
        , NULL -- PAYMENT SUMMARY 2016.12.21
        )
   BULK COLLECT INTO p_site_parcels
   FROM prcls p
   WHERE (
           (    p_querytype = PCK_API_CONSTANTS.c_querytype_ALL_PARCELS ) -- donc aucun autre filtre
        OR (    p_querytype = PCK_API_CONSTANTS.c_querytype_BYRECIPIENTNAME
            AND UPPER(p.shipto_lastname || ' ' || p.shipto_firstname) LIKE '%'||UPPER(p_NAME)||'%'
           )
        OR (    p_querytype = PCK_API_CONSTANTS.c_querytype_UNKNOWNRECIPIENT
            AND TRIM(p.shipto_lastname) IS NULL AND TRIM(p.shipto_firstname) IS NULL
           )
       ); -- Pas de tris


   IF p_site_parcels IS NOT NULL THEN
      IF p_site_parcels.COUNT > 0 THEN
         FOR i IN p_site_parcels.FIRST .. p_site_parcels.LAST
         LOOP
            IF p_site_parcels(i).MAPPED_PARCEL_STATE <> PCK_API_CONSTANTS.c_mapped_state_NONE THEN

               -- RECUPERE LES FILE_ID DES EVENTS EN ATTENTE D'ETRE TRAITE PAR LE PROCESS_ALL
               IMPORT_PDA.PCK_EVENT_IMPORTED.GetUnprocessedEventFileID ( p_FIRM_PARCEL_CARRIER => p_site_parcels(i).FIRM_PARCEL_ID, p_tab_event_file_id => p_tab_event_file_id );
               IF p_tab_event_file_id.COUNT > 0 THEN
                  p_site_parcels(i).TAB_EVENT_FILE_ID := NEW api_core.TAB_ELEMENT_NUMBER_TYPE();
                  p_site_parcels(i).TAB_EVENT_FILE_ID.EXTEND(p_tab_event_file_id.COUNT);
                  FOR j IN p_tab_event_file_id.FIRST .. p_tab_event_file_id.LAST
                  LOOP
                     p_site_parcels(i).TAB_EVENT_FILE_ID(j) := p_tab_event_file_id(j);
                  END LOOP;
               END IF;

               -- RECUPERE L'ID MASTER.PARCEL.CURRENT_PARCEL_STEPS_ID
               l_CURRENT_PARCEL_STEPS_ID := MASTER_PROC.PCK_STEP.GetCurrentParcelStepsID(p_site_parcels(i).FIRM_PARCEL_ID);

               -- RECUPERE LES RESERVES
               IF l_CURRENT_PARCEL_STEPS_ID IS NOT NULL THEN
                  p_site_parcels(i).Q_DAMAGED_PARCEL := MASTER_PROC.PCK_STEP.IsExistParcelStepsReserve(p_ParcelStepsID => l_CURRENT_PARCEL_STEPS_ID, p_ReserveTypeName => PCK_API_CONSTANTS.c_RESERVE_DAMAGED_PARCEL);
                  p_site_parcels(i).Q_OPEN_PARCEL := MASTER_PROC.PCK_STEP.IsExistParcelStepsReserve(p_ParcelStepsID => l_CURRENT_PARCEL_STEPS_ID, p_ReserveTypeName => PCK_API_CONSTANTS.c_RESERVE_OPEN_PARCEL);
               ELSE -- 2017.03.13 Set à 0 les reserves lorsque le colis n'a pas d'état
                  p_site_parcels(i).Q_DAMAGED_PARCEL := 0;
                  p_site_parcels(i).Q_OPEN_PARCEL := 0;
               END IF;

               -- RECUPERATION D'EVENTUELS PARCEL PROPERTIES CREES PAR LE TRACING D'ENCOURS CARRIER  -- 2016.11.25
               GetParcelProperties(p_parcel_id => p_site_parcels(i).BO_PARCEL_ID, p_tab_parcel_properties => l_tab_parcel_properties) ;
               IF l_tab_parcel_properties IS NOT NULL THEN
                  IF l_tab_parcel_properties.COUNT > 0 THEN
                     p_site_parcels(i).TAB_PARCEL_PROPERTIES := l_tab_parcel_properties ;
                  END IF;
               END IF;

               -- PAYMENT SUMMARY  -- 2016.12.20
               GetPaymentSummary(p_INTERNATIONAL_SITE_ID => p_site_parcels(i).INTERNATIONAL_SITE_ID, p_parcel_id => p_site_parcels(i).BO_PARCEL_ID, p_payment_summary => l_payment_type) ;
               IF l_payment_type IS NOT NULL THEN
                  p_site_parcels(i).payment := l_payment_type ;
               END IF;

            END IF;
         END LOOP;
      END IF;
   END IF;

   -- --------------------------------------------------
   -- supprimer de la liste les colis dans état "plus dans le site"
   -- (déjà collectés par le transporteur ou alors récupérés par le client)
   -- sans file_id en attente ???
   -- exemple pickup déjà traités et tout???
   -- Seulement si LAST_UPDATE_DTM du colis > 2 jours??
   -- --------------------------------------------------
   -- TODO; à confirmer exactement comment

END GetSiteParcelsCore;

-- ---------------------------------------------------------------------------
--  UNIT         : Function GetSiteParcelsCore
--  DESCRIPTION  : Fonction appelant la procédure GetSiteParcelsCore
--
--  IN           :
--  OUT          :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.08.29 | Hocine HAMMOU
--          | version initiale
--          |
-- ---------------------------------------------------------------------------
FUNCTION GetSiteParcelsCore(p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_querytype IN INTEGER, p_NAME IN VARCHAR2  DEFAULT NULL, p_site_ID IN MASTER.SITE.SITE_ID%TYPE , p_timezone IN MASTER.SITE.TIMEZONE%TYPE ) RETURN api_core.TAB_PARCEL_INFO_TYPE IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GetSiteParcelsCore';
  l_start_date MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_TAB_PARCEL_INFO_TYPE api_core.TAB_PARCEL_INFO_TYPE;
BEGIN

   l_TAB_PARCEL_INFO_TYPE := api_core.TAB_PARCEL_INFO_TYPE();
   GetSiteParcelsCore(p_INTERNATIONAL_SITE_ID => p_INTERNATIONAL_SITE_ID
                    , p_querytype => p_querytype
                    , p_NAME => p_NAME
                    , p_site_parcels => l_TAB_PARCEL_INFO_TYPE
                    , p_site_ID => p_site_ID
                    , p_timezone => p_timezone );
   RETURN l_TAB_PARCEL_INFO_TYPE;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSiteParcelsCore;

-- ---------------------------------------------------------------------------
--  UNIT         : GetSiteParcels
--  DESCRIPTION  : recherches COLIS pour pickup-refuse (SEARCH IN STOCK)
--                 tous ceux du site  / par nom de destinataire / sans destinataire
--                 FILTRE COMMUN AUX RECHERCHES:
--                   · p_SITE_ID reçu entrée = COALESCE(PARCEL.site_id_delivery, PARCEL.site_id_dropoff, PARCEL.site_id_delivery_target, PARCEL.site_id_dropoff_target);
--                   · PARCEL.CURRENT_STEP_ID :
--                         ceux qui Calculate_Mapped_Parcel_State allait transformer
--                         c_mapped_state_SHIPPED, c_mapped_state_DELIVERED
--                         et si jamais p_CURRENT_STEP_ID IS nous le renvoyons aussi
--
--  IN           : p_SITE_ID
--  IN           : P_QUERYTYPE  -> 0 - tous ceux du site
--                                 1 - par nom de destinataire
--                                 2 - sans destinataire
--  IN           : p_NAME
--  OUT          : p_site_parcels sera une table TAB_PARCEL_SRCH_TYPE avec la liste de colis
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.26 | Maria CASALS
--          | version initiale
--          |
--  V01.100 | 2015.07.10 | Hocine HAMMOU
--          | Remplacement de SITE_ID par INTERNATIONAL_SITE_ID
--          |
--  V01.100 | 2016.01.11 | Hocine HAMMOU
--          | Supprimer les référence PARCEL_SRCH_TYPE et les remplacer par PARCEL_INFO_TYPE
--          | Supprimer les référence TAB_PARCEL_SRCH_TYPE et les remplacer par TAB_PARCEL_INFO_TYPE
--          |
-- ---------------------------------------------------------------------------
PROCEDURE GetSiteParcels(p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_querytype IN INTEGER, p_NAME IN VARCHAR2  DEFAULT NULL, p_site_parcels OUT NOCOPY  TAB_PARCEL_INFO_TYPE ) IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GETSITEPARCELS';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_country_code   MASTER.SITE.COUNTRY_CODE%TYPE;
   l_language_code  MASTER.SITE.LANGUAGE_CODE%TYPE;
   l_timezone       MASTER.SITE.TIMEZONE%TYPE;
   l_requiredparams VARCHAR2(4000);
   l_site_ID        MASTER.SITE.SITE_ID%TYPE;
   l_SiteTestTypeId NUMBER(1);
BEGIN

   -- --------------------------------------------------------------------------------
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   -- --------------------------------------------------------------------------------
   IF TRIM(p_INTERNATIONAL_SITE_ID) IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'P_INTERNATIONAL_SITE_ID');
   END IF;

   IF TRIM(P_QUERYTYPE) IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'P_QUERYTYPE');
   END IF;

   IF P_QUERYTYPE = 1 AND trim(p_NAME) IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'P_NAME');
   END IF;

   -- --------------------------------------------------------------------------------
   -- RAISE EXCEPTION EN CAS DE DONNEES OBLIGATOIRES NON RENSEIGNEES OU mauvais valeur de type de recherche
   -- --------------------------------------------------------------------------------
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   IF NOT (p_querytype = PCK_API_CONSTANTS.c_querytype_ALL_PARCELS
   OR p_querytype = PCK_API_CONSTANTS.c_querytype_BYRECIPIENTNAME
   OR p_querytype = PCK_API_CONSTANTS.c_querytype_UNKNOWNRECIPIENT)
   THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_paramdomain,PCK_API_CONSTANTS.errmsg_paramdomain || '(P_QUERYTYPE:' || p_querytype ||').');
   END IF;

   -- --------------------------------------------------------------------------------
   -- RECUPERATION DU SITE_ID à partir de INTERNATIONAL_SITE_ID
   -- --------------------------------------------------------------------------------
   l_site_ID := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => P_INTERNATIONAL_SITE_ID );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || P_INTERNATIONAL_SITE_ID);
   END IF;

   -- --------------------------------------------------------------------------------
   -- chercher la timezone et autres détails du site
   -- --------------------------------------------------------------------------------
   MASTER_PROC.pck_site.GetNLSBySiteId(p_site_id => l_site_ID, p_country_code => l_country_code, p_language_code => l_language_code, p_timezone => l_timezone );
   p_site_parcels := TAB_PARCEL_INFO_TYPE();

   -- --------------------------------------------------------------------------------
   -- CONTROLE SI PUDO DE FORMATION et traitement différent dans ce cas-là
   -- --------------------------------------------------------------------------------
   l_SiteTestTypeId := PCK_SITE.SiteTestTypeId( p_site_id => l_site_id ); -- 20151103 MODULE FORMATION

   IF l_SiteTestTypeId = PCK_SITE.c_SITE_TEST_TYPE_ID_NO_TEST THEN -- 20151103 MODULE FORMATION
      GetSiteParcelsCore(p_INTERNATIONAL_SITE_ID => p_INTERNATIONAL_SITE_ID,p_querytype => p_querytype, p_NAME => p_NAME, p_site_parcels => p_site_parcels, p_site_ID => l_site_ID , p_timezone => l_timezone );
   ELSE
      NULL;
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_wrong_site_type_id,PCK_API_CONSTANTS.errmsg_wrong_site_type_id||'(TYPE:'||l_SiteTestTypeId || '-SITE:'||P_INTERNATIONAL_SITE_ID||').');
   END IF;

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] PARCELS INFO REQUEST '
                                                                                                         || '(INTERNATIONAL_SITE_ID:' || NVL(p_INTERNATIONAL_SITE_ID,'N/C')
                                                                                                         || '-QUERY TYPE:' || NVL(TO_CHAR(p_querytype),'N/C')
                                                                                                         || '-NAME:' || NVL(p_NAME,'N/C')
                                                                                                         || '-ELAPSED TIME:'||api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).'
                                                                                                         );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSiteParcels;



-- ---------------------------------------------------------------------------
--  UNIT         : GetSiteParcels
--  DESCRIPTION  : Voir procedure homonyme
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.26 | Maria CASALS
--          | version initiale
--  V01.100 | 2015.07.10 | Hocine HAMMOU
--          | Remplacement de SITE_ID par INTERNATIONAL_SITE_ID
-- ---------------------------------------------------------------------------
FUNCTION  GetSiteParcels(p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_querytype IN INTEGER, p_NAME IN VARCHAR2 DEFAULT NULL ) RETURN TAB_PARCEL_INFO_TYPE IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GETSITEPARCELS';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_site_parcels   TAB_PARCEL_INFO_TYPE;
BEGIN
   GetSiteParcels(p_INTERNATIONAL_SITE_ID => p_INTERNATIONAL_SITE_ID, p_querytype => p_querytype, p_NAME => p_NAME, p_site_parcels => l_site_parcels);
   RETURN l_site_parcels;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetSiteParcels;



-- ---------------------------------------------------------------------------
--  UNIT         : GetParcelsToPrepareCore
--  DESCRIPTION  :
--
--  IN           :
--  OUT          :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.11.03 | Hocine HAMMOU
--          | version initiale
--  V01.001 | 2016.08.04 | Vbr optim : supp creation_dtm > (sysdate -...)
--          |
-- ---------------------------------------------------------------------------
PROCEDURE GetParcelsToPrepareCore(p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_site_parcels OUT NOCOPY  TAB_PARCEL_PREPARATION_TYPE, p_site_ID IN MASTER.SITE.SITE_ID%TYPE )
IS
BEGIN

   SELECT PARCEL_PREPARATION_TYPE (
          p_INTERNATIONAL_SITE_ID                                                     -- SITE_INTERNATIONAL_ID
        , p.FIRM_PARCEL_CARRIER                                                       -- FIRM_PARCEL_ID
        , TRIM(p.shipto_lastname || ' ' || p.shipto_firstname) --BUG 2016.06.07       -- CUSTOMER_NAME
        )
   BULK COLLECT INTO p_site_parcels
   FROM MASTER.PARCEL p
   INNER JOIN PARCEL_STEPS ps ON PS.PARCEL_STEPS_ID = p.CURRENT_PARCEL_STEPS_ID
   WHERE p.LAST_UPDATE_DTM > ( SYSDATE - PCK_API_CONSTANTS.c_MAX_DAYS_TO_SEARCH )
   AND p.PARCEL_STATE_ID < PCK_API_CONSTANTS.c_Parcel_State_ID_FORCLOS
   --AND p_site_ID = COALESCE(p.site_id_delivery, p.site_id_dropoff, p.site_id_delivery_target, p.site_id_dropoff_target) -- 2016.05.23
   AND  ( p.site_id_delivery = p_site_ID
          OR p.site_id_dropoff = p_site_ID
          OR p.site_id_delivery_target = p_site_ID
          OR p.site_id_dropoff_target = p_site_ID )
   AND p.CURRENT_STEP_ID = PCK_API_CONSTANTS.c_STEP_PREPARATION --70
   AND p.CURRENT_STEP_ISVALID = 0
   AND ps.STEP_MOTIVE_ID =  PCK_API_CONSTANTS.c_motive_PU_FIN_INS --FIN D'INSTANCE ??  A confirmer. Si motive n'est pas utile, enlever jointure avec PARCEL_STEPS
   ;

END GetParcelsToPrepareCore;



-- ---------------------------------------------------------------------------
--  UNIT         : GetParcelsToPrepare
--  DESCRIPTION  : recherches COLIS à préparer
--                 inspiré de MASTER_PROC.PROCESS_FIN_INS

--                 ATTENTION FILTRE À DÉFINIR À 2015.07.20
--                 FILTRE COMMUN AUX RECHERCHES:
--                   · p_SITE_ID reçu entrée = COALESCE(PARCEL.site_id_delivery, PARCEL.site_id_dropoff, PARCEL.site_id_delivery_target, PARCEL.site_id_dropoff_target);
--                   · ??????PARCEL.CURRENT_STEP_ID :
--                     ??????    ceux qui Calculate_Mapped_Parcel_State allait transformer
--                     ??????    c_mapped_state_SHIPPED, c_mapped_state_DELIVERED
--                     ??????    et si jamais p_CURRENT_STEP_ID IS nous le renvoyons aussi
--
--  IN           : p_INTERNATIONAL_SITE_ID
--  OUT          : p_site_parcels sera une table TAB_PARCEL_PREPARATION_TYPE avec la liste de colis
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.20 | Hocine HAMMOU
--          | version initiale
--          |
-- ---------------------------------------------------------------------------
PROCEDURE GetParcelsToPrepare(p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_site_parcels OUT NOCOPY  TAB_PARCEL_PREPARATION_TYPE ) IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GETPARCELSTOPREPARE';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_requiredparams VARCHAR2(4000);
   l_site_ID MASTER.SITE.SITE_ID%TYPE;
   l_SiteTestTypeId NUMBER(1);
BEGIN

   -- --------------------------------------------------------------------------------
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   -- --------------------------------------------------------------------------------
   IF TRIM(p_INTERNATIONAL_SITE_ID) IS NULL THEN
      l_requiredparams:= PCK_API_TOOLS.LIST (P_LIST => l_requiredparams, p_item => 'p_INTERNATIONAL_SITE_ID');
   END IF;

   -- --------------------------------------------------------------------------------
   -- RAISE EXCEPTION EN CAS DE DONNEES OBLIGATOIRES NON RENSEIGNEES
   -- --------------------------------------------------------------------------------
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- --------------------------------------------------------------------------------
   -- RECUPERATION DU SITE_ID à partir de INTERNATIONAL_SITE_ID
   -- --------------------------------------------------------------------------------
   l_site_ID := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => P_INTERNATIONAL_SITE_ID );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || P_INTERNATIONAL_SITE_ID);
   END IF;

   -- --------------------------------------------------------------------------------
   -- CONTROLE SI PUDO DE FORMATION et traitement différent dans ce cas-là
   -- --------------------------------------------------------------------------------
   l_SiteTestTypeId := PCK_SITE.SiteTestTypeId( p_site_id => l_site_id ); -- 20151103 MODULE FORMATION

   p_site_parcels := TAB_PARCEL_PREPARATION_TYPE();

   IF l_SiteTestTypeId = PCK_SITE.c_SITE_TEST_TYPE_ID_NO_TEST THEN -- 20151103 MODULE FORMATION
      GetParcelsToPrepareCore(p_INTERNATIONAL_SITE_ID => p_INTERNATIONAL_SITE_ID, p_site_parcels => p_site_parcels, p_site_ID => l_site_ID);
   ELSE
      NULL;
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_wrong_site_type_id,PCK_API_CONSTANTS.errmsg_wrong_site_type_id||'(TYPE:'||l_SiteTestTypeId || '-SITE:'||P_INTERNATIONAL_SITE_ID||').');
   END IF;

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] PARCELS IN PREPARATION REQUEST (INTERNATIONAL_SITE_ID:' || p_INTERNATIONAL_SITE_ID || '-ELAPSED TIME:'|| api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetParcelsToPrepare;


-- ---------------------------------------------------------------------------
--  UNIT         : GetParcelsToPrepare
--  DESCRIPTION  : Voir procedure homonyme
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.20 | Hocine HAMMOU
--          | version initiale
--          |
-- ---------------------------------------------------------------------------
FUNCTION  GetParcelsToPrepare(p_INTERNATIONAL_SITE_ID IN VARCHAR2) RETURN TAB_PARCEL_PREPARATION_TYPE IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'GETPARCELSTOPREPARE';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_site_parcels   TAB_PARCEL_PREPARATION_TYPE;
BEGIN
   GetParcelsToPrepare(p_INTERNATIONAL_SITE_ID => p_INTERNATIONAL_SITE_ID, p_site_parcels => l_site_parcels);
   RETURN l_site_parcels;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END GetParcelsToPrepare;


END PCK_BO_PARCEL_INFO;

/