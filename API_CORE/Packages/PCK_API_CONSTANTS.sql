CREATE OR REPLACE PACKAGE api_core.PCK_API_CONSTANTS
-- ***************************************************************************
--  PACKAGE     : API_CORE.PCK_API_CONSTANTS
--  DESCRIPTION : Package de constantes pour la couche API
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.06.11 | Hocine HAMMOU
--          | Init
--          |
--  V00.100 | 2015.06.29 | Hocine HAMMOU
--          | Ajout de la constante lié à l'évènement REFUSE
--          |
--  V00.200 | 2015.07.09 | Hocine HAMMOU
--          | Suppression de la gestion des reserves 'Q_DAMAGED_PARCEL' et 'Q_OPENED_PARCEL'
--          | en tant que Property . GEstion des reserves 'Q_DAMAGED_PARCEL' et 'Q_OPENED_PARCEL'
--          | de la table CONFIG.RESERVE_TYPE.RESERVE_TYPE_NAME
--          |
--  V00.200 | 2015.07.10 | Hocine HAMMOU
--          | Définition section de constantes pour les messages d'erreur
--          |
--  V00.201 | 2015.07.20 | Maria CASALS
--          | Rajout PREPARATION_FOR_COLLECTION
--          | ATTENTION pas IN_PREPARATION, selon acté par PLOP en réunion le 2015.07.10
--          |
--  V00.202 | 2015.07.31 | Amadou YOUNSAH
--          | Rajout de la constante c_evt_type_DROPOFF pour le DROPPEDOFF
--          |
--  V00.203 | 2015.11.17 | Hocine HAMMOU
--          | LOT 2 INDE : Rajout des constantes c_PROP_NATURE_OF_GOODS, c_PROP_CHECKLIST, c_PROP_RECEIVER_TYPE
--          |
--  V00.204 | 2015.11.26 | Hocine HAMMOU
--          | LOT 2 INDE : [10163] Ajout de constantes liés à OPENING HOURS
--          |
--  V00.205 | 2016.01.13 | Hocine HAMMOU
--          | LOT 2 INDE : [10163] Ajout de la constante pour  PCK_BO_SITE_INFO.GetActiveSites
--          |
--  V00.206 | 2016.01.26 | Hocine HAMMOU
--          | LOT 2 INDE : [10163] Ajout des constantes c_mapped_state_PREP_FOR_COLL et c_mapped_state_TO_PREPARE
--          |
--  V00.207 | 2016.02.25 | Hocine HAMMOU
--          | Bug 40017 :MCO#774 - Colis déjà scannée dans la WebApp
--          | Ajout constante c_mapped_state_DELIVERED_ACK
--          | Bug 40211 :MCO#785 - Colis à préparer ne remontent pas dans la web-app
--          | Ajout constante c_mapped_state_TO_PREPARE
--          |
--  V00.208 | 2016.03.21 | Hocine HAMMOU
--          | projet RM2 [10302] Transfert de responsabilité :
--          | Ajout constantes : c_PROP_CAB2DKEY , c_PROP_MASK_CAB2DKEY , c_evt_type_SCAN
--          |
--  V00.209 | 2016.08.18 | Hocine HAMMOU
--          | projet RM2 [10330] Event INVENTORY :
--          | Ajout constante c_evt_type_INVENTORY
--          |
--  V00.210 | 2016.08.19 | Hocine HAMMOU
--          | projet RM2 [10330] Event DROPOFF :
--          | Ajout des constantes relatives aux proprietes PHONE_NUMBER et RECEIPT_NUMBER
--          |
--  V00.211 | 2016.11.02 | Hocine HAMMOU
--          | projet [10472] Ajout propriété Transporteur Physique => PHYSICAL_CARRIER_ID
--          |
--  V00.212 | 2016.11.16 | Hocine HAMMOU
--          | projet [10472] Ajout propriété de justificatif d'identité => IDENTITY_VERIFICATION_2
--          |
--  V00.213 | 2016.11.25 | Hocine HAMMOU
--          | Projet [10472] Ajout fonctionnalité SWAP : propriétés SWAP, RETURN_FIRM_PARCEL_ID, DELIVERY_FIRM_PARCEL_ID
--          |
--  V00.214 | 2017.03.01 | Hocine HAMMOU
--          | Projet [10350] Ajout des constantes type de device
--          |
-- ***************************************************************************
IS

-- nombre de jours maximale à compter de la date de création de colis
-- les recherches seront filtrés avec
c_MAX_DAYS_TO_SEARCH           CONSTANT INTEGER := 60;

-- ce sont les event type traités
c_evt_type_PICKUP              CONSTANT CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE := 'PICKUP';
c_evt_type_DELIVERY            CONSTANT CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE := 'DELIVERY';
c_evt_type_REFUSE              CONSTANT CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE := 'REFUSE';
c_evt_type_COLLECTION          CONSTANT CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE := 'COLLECTION'; -- COLLECTION Parcel handed over to driver
c_evt_type_PREP_FOR_COLLECTION CONSTANT CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE := 'PREPARATION_FOR_COLLECTION'; --PREPARATION_FOR_COLLECTION parcel to be prepared
c_evt_type_DROPOFF             CONSTANT CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE := 'DROPOFF';
c_evt_type_SCAN                CONSTANT CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE := 'SCAN';  -- 2016.03.21 projet [10302]
c_evt_type_INVENTORY           CONSTANT CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE := 'INVENTORY';  -- 2016.08.18 projet [10330]
c_evt_type_PARCEL_INVENTORY    CONSTANT CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE := 'PARCEL_INVENTORY';  -- 2016.12.23 projet [10472]
c_evt_type_SCAN_DPL            CONSTANT CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE := 'SCAN_DPL';  -- 2016.12.27 projet [10472]
c_evt_type_NOT_FOUND           CONSTANT CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE := 'NOT_FOUND';  -- 2017.01.10 projet [10472]


-- Ce sont les statuts à renvoyer vers la couche WEB API
c_mapped_state_SHIPPED         CONSTANT VARCHAR2(30) := 'SHIPPED';
c_mapped_state_DROPPEDOFF      CONSTANT VARCHAR2(30) := 'DROPPEDOFF';
c_mapped_state_DELIVERED       CONSTANT VARCHAR2(30) := 'DELIVERED';-- Bug 40017 : reçu tracing transporteur mais le pudo n’a pas encore scanné le colis en réception
c_mapped_state_DELIVERED_ACK   CONSTANT VARCHAR2(30) := 'DELIVERY_ACKNOWLEDGED'; -- Bug 40017 : le pudo a scanné le colis en réception et donc à validé le step
c_mapped_state_PICKEDUP        CONSTANT VARCHAR2(30) := 'PICKEDUP';
c_mapped_state_PREPARED        CONSTANT VARCHAR2(30) := 'PREPARED';
c_mapped_state_COLLECTED       CONSTANT VARCHAR2(30) := 'COLLECTED';
c_mapped_state_REFUSED         CONSTANT VARCHAR2(30) := 'REFUSED';
c_mapped_state_PREP_FOR_COLL   CONSTANT VARCHAR2(30) := 'PREPARED_FOR_COLLECTION'; --[10163] 2016.01.26  RM1 LOT2 INDE : COLIS PREPARE POUR LA COLLECTION
c_mapped_state_TO_PREPARE      CONSTANT VARCHAR2(30) := 'TO_PREPARE';              --[10163] 2016.01.26  RM1 LOT2 INDE : COLIS A PREPARER / 2016.02.25 Bug 40211
c_mapped_state_NONE            CONSTANT VARCHAR2(30) := 'NONE';                    --[10163] 2016.01.26  RM1 LOT2 INDE : MAPPED STATE utilisé pour la WEBAPI dans le cas des colis NON existants dans le BO



c_motive_REFUSED_BY_SHIPFROM   CONSTANT INTEGER      := 3; -- CONFIG.STEP_MOTIVE.STEP_MOTIVE_ID for REFUSED_BY_SHIPFROM - Refused by customer
c_motive_PU_FIN_INS            CONSTANT INTEGER      := 1; -- CONFIG.STEP_MOTIVE.STEP_MOTIVE_ID for 'Holding time ended' (Fin d'instance)

c_Parcel_State_ID_FORCLOS      CONSTANT INTEGER      := 99;  -- MASTER.PARCEL.PARCEL_STATE_ID - Statut Fermé pour le parcel


-- LE CREATEUR EST LE BACK OFFICE
c_PARCEL_INFO_CREATOR          CONSTANT VARCHAR2(10) := 'BO';

-- types de recherche colis
c_querytype_ALL_PARCELS        CONSTANT INTEGER := 0;
c_querytype_BYRECIPIENTNAME    CONSTANT INTEGER := 1;
c_querytype_UNKNOWNRECIPIENT   CONSTANT INTEGER := 2;


-- RESERVES : 'Q_DAMAGED_PARCEL' et 'Q_OPENED_PARCEL' de la table CONFIG.RESERVE_TYPE.RESERVE_TYPE_NAME
c_RESERVE_DAMAGED_PARCEL          CONSTANT VARCHAR2(50) := 'Q_DAMAGED_PARCEL';     --c_PROP_MASK_DAMAGED_PARCEL     CONSTANT VARCHAR2(50) := '';
c_RESERVE_OPEN_PARCEL             CONSTANT VARCHAR2(50) := 'Q_OPENED_PARCEL';     --c_PROP_MASK_OPEN_PARCEL        CONSTANT VARCHAR2(50) := '';


-- PARCEL PROPERTY NAMES                                                           MASKS FOR TO_CHAR CONVERSION IF ANY
c_PROP_DAMAGED_PARCEL          CONSTANT VARCHAR2(50) := 'Q_DAMAGED_PARCEL';        --c_PROP_MASK_DAMAGED_PARCEL     CONSTANT VARCHAR2(50) := '';
c_PROP_OPEN_PARCEL             CONSTANT VARCHAR2(50) := 'Q_OPENED_PARCEL';         --c_PROP_MASK_OPEN_PARCEL        CONSTANT VARCHAR2(50) := '';
c_PROP_BARCODE                 CONSTANT VARCHAR2(50) := 'BARCODE';                 c_PROP_MASK_BARCODE            CONSTANT VARCHAR2(50)  := '';
c_PROP_SIGN_DATA               CONSTANT VARCHAR2(50) := 'SIGN_DATA';               c_PROP_MASK_SIGN_DATA          CONSTANT VARCHAR2(50)  := '';
c_PROP_DURATION                CONSTANT VARCHAR2(50) := 'DURATION';                c_PROP_MASK_DURATION           CONSTANT VARCHAR2(50)  := '';
c_PROP_FORM                    CONSTANT VARCHAR2(50) := 'FORM';                    c_PROP_MASK_FORM               CONSTANT VARCHAR2(50)  := '';
c_PROP_REASON                  CONSTANT VARCHAR2(50) := 'REASON';                  c_PROP_MASK_REASON             CONSTANT VARCHAR2(50)  := '';
c_PROP_COD_AMOUNT_PAID         CONSTANT VARCHAR2(50) := 'COD_AMOUNT_PAID';         c_PROP_MASK_COD_AMOUNT_PAID    CONSTANT VARCHAR2(50)  := '';
c_PROP_COD_CURRENCY            CONSTANT VARCHAR2(50) := 'COD_CURRENCY';            c_PROP_MASK_COD_CURRENCY       CONSTANT VARCHAR2(50)  := '';
c_PROP_COD_MEANS_PAYMENT_ID    CONSTANT VARCHAR2(50) := 'COD_MEANS_PAYMENT_ID';    c_PROP_MASK_COD_MEANS_PAYMNT   CONSTANT VARCHAR2(50)  := '';
c_PROP_CDC_CODE                CONSTANT VARCHAR2(50) := 'PINCODE';                 c_PROP_MASK_CDC_CODE           CONSTANT VARCHAR2(50)  := '';
c_PROP_RECIPIENT_NAME          CONSTANT VARCHAR2(50) := 'NAME_OF_RECIPIENT';       c_PROP_MASK_RECIPIENT_NAME     CONSTANT VARCHAR2(50)  := '';
c_PROP_IDENTITY_VERIF          CONSTANT VARCHAR2(50) := 'IDENTITY_VERIFICATION';   c_PROP_MASK_IDENTITY_VERIF     CONSTANT VARCHAR2(50)  := '';
c_PROP_ID_RECORD               CONSTANT VARCHAR2(50) := 'ID_RECORD';               c_PROP_MASK_ID_RECORD          CONSTANT VARCHAR2(50)  := '';
c_PROP_FIRM_PARCEL_OTHER       CONSTANT VARCHAR2(50) := 'FIRM_PARCEL_OTHER';       c_PROP_MASK_FIRM_PARCEL_OTHER  CONSTANT VARCHAR2(50)  := '';
c_PROP_NATURE_OF_GOODS         CONSTANT VARCHAR2(50) := 'NATURE_OF_GOODS';         c_PROP_MASK_NATURE_OF_GOODS    CONSTANT VARCHAR2(200) := '';
c_PROP_CHECKLIST               CONSTANT VARCHAR2(50) := 'NATURE_OF_GOODS';         c_PROP_MASK_CHECKLIST          CONSTANT VARCHAR2(200) := '';
c_PROP_RECEIVER_TYPE           CONSTANT VARCHAR2(50) := 'RECEIVER';                c_PROP_MASK_RECEIVER_TYPE      CONSTANT VARCHAR2(50)  := '';
c_PROP_CAB2DKEY                CONSTANT VARCHAR2(50) := 'CAB2DKEY';                c_PROP_MASK_CAB2DKEY           CONSTANT VARCHAR2(50)  := ''; -- TODO longueur à redéfinir  -- 2016.03.21 projet [10302]
c_PROP_CAB2DSTATUS             CONSTANT VARCHAR2(50) := 'CAB2DSTATUS';             c_PROP_MASK_CAB2DSTATUS        CONSTANT VARCHAR2(50)  := ''; -- TODO longueur à redéfinir  -- 2016.03.21 projet [10302]
c_PROP_RECEIPT_NUMBER          CONSTANT VARCHAR2(50) := 'RECEIPT_NUMBER';          c_PROP_MASK_RECEIPT_NUMBER     CONSTANT VARCHAR2(50)  := ''; -- 2016.08.19 projet [10330]
c_PROP_PHONE_NUMBER            CONSTANT VARCHAR2(50) := 'PHONE_NUMBER';            c_PROP_MASK_PHONE_NUMBER       CONSTANT VARCHAR2(30)  := ''; -- 2016.08.19 projet [10330]
c_PROP_PHYSICAL_CARRIER_ID     CONSTANT VARCHAR2(50) := 'PHYSICAL_CARRIER_ID';     c_PROP_MASK_PHYSICAL_CARRIER   CONSTANT VARCHAR2(50)  := ''; -- 2016.11.02 projet [10472]
c_PROP_IDENTITY_VERIF_2        CONSTANT VARCHAR2(50) := 'IDENTITY_VERIFICATION_2'; c_PROP_MASK_IDENTITY_VERIF_2   CONSTANT VARCHAR2(50)  := '';
c_PROP_SWAP                    CONSTANT VARCHAR2(50) := 'SWAP';
c_PROP_RETURN_FIRM_PARCEL      CONSTANT VARCHAR2(50) := 'RETURN_FIRM_PARCEL_ID';   c_PROP_MASK_RETURN_FIRM_PARCEL CONSTANT VARCHAR2(50)  := '';
c_PROP_DELIVERY_FIRM_PARCEL    CONSTANT VARCHAR2(50) := 'DELIVERY_FIRM_PARCEL_ID'; c_PROP_MASK_DELIVERY_FIRM_PARC CONSTANT VARCHAR2(50)  := '';
c_PROP_ASSOCIATED_CAB2D        CONSTANT VARCHAR2(50) := 'ASSOCIATED_CAB2D'       ; c_PROP_MASK_ASSOCIATED_CAB2D   CONSTANT VARCHAR2(50)  := '';
c_PROP_ABANDONED               CONSTANT VARCHAR2(50) := 'ABANDONED';

c_PROP_INVENTORY_STATE         CONSTANT VARCHAR2(50) := 'INVENTORY_STATE';    c_PROP_MASK_INVENTORY_STATE   CONSTANT VARCHAR2(50)  := '';
c_PROP_INVENTORY_SESSION       CONSTANT VARCHAR2(50) := 'INVENTORY_SESSION';  c_PROP_MASK_INVENTORY_SESSION   CONSTANT VARCHAR2(50)  := '';
c_PROP_INVENTORY_ORIGIN        CONSTANT VARCHAR2(50) := 'INVENTORY_ORIGIN';   c_PROP_MASK_INVENTORY_ORIGIN   CONSTANT VARCHAR2(50)  := '';
c_PROP_INVENTORY_USE_CASE      CONSTANT VARCHAR2(50) := 'INVENTORY_USE_CASE'; c_PROP_MASK_INVENTORY_USE_CASE   CONSTANT VARCHAR2(50)  := '';



-- LISTE EXHAUSTIVE DES STATUTS D'ETAPE DU CYCLE DE VIE D'UN COLIS
-- CES CONSTANTES DOIVENT IMPERATIVEMENT MATCHER AVEC LES DONNEES DE LA TABLE CONFIG.STEP
c_STEP_SHIPMENT                 CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 10 ;
c_STEP_DROPOFF_SEND             CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 20 ;
c_STEP_CARRIER                  CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 30 ;
c_STEP_REFUSE_PUDO              CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 40 ;
c_STEP_DELIVERY                 CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 50 ;
c_STEP_PICKUP                   CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 60 ;
c_STEP_PREPARATION              CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 70 ;
c_STEP_DROPOFF                  CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 80 ;
c_STEP_COLLECTION               CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 90 ;
c_STEP_COLLECTION_CARRIER       CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 100;
c_STEP_REFUSE_PUDO_RETURN       CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 110;
c_STEP_DELIVERY_PUDO_RETURN     CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 120;
c_STEP_PICKUP_SHIPFROM          CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 130;
c_STEP_PICKUP_SHIPPER           CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 140;
c_STEP_PREPARATION_SEND         CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 150;
c_STEP_CARRIER_WASTE_SHIPFROM   CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 160;
c_STEP_CARRIER_WASTE_SHIPTO     CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 170;
c_STEP_REFUSE_CARRIER_WASTE     CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 180;
c_STEP_CARRIER_WASTE            CONSTANT  CONFIG.STEP.STEP_ID%TYPE := 190;

-- LISTE EXHAUSTIVE DES STATUTS DE SITE
-- CES CONSTANTES DOIVENT IMPERATIVEMENT MATCHER AVEC LES DONNEES DE LA TABLE CONFIG.SITE_STATE
c_SITESTATE_HOT_PROSPECT       CONSTANT CONFIG.SITE_STATE.SITE_STATE_ID%TYPE := 1;
c_SITESTATE_PUDO_CREATED       CONSTANT CONFIG.SITE_STATE.SITE_STATE_ID%TYPE := 2;
c_SITESTATE_PUDO_TRAINING      CONSTANT CONFIG.SITE_STATE.SITE_STATE_ID%TYPE := 3;
c_SITESTATE_STARTING_ACTIVITY  CONSTANT CONFIG.SITE_STATE.SITE_STATE_ID%TYPE := 4;
c_SITESTATE_ACTIVE             CONSTANT CONFIG.SITE_STATE.SITE_STATE_ID%TYPE := 5;
c_SITESTATE_END_ACTIVITY       CONSTANT CONFIG.SITE_STATE.SITE_STATE_ID%TYPE := 6;
c_SITESTATE_INACTIVE           CONSTANT CONFIG.SITE_STATE.SITE_STATE_ID%TYPE := 7;
c_SITESTATE_FINISHED           CONSTANT CONFIG.SITE_STATE.SITE_STATE_ID%TYPE := 8;
c_SITESTATE_REFUSE             CONSTANT CONFIG.SITE_STATE.SITE_STATE_ID%TYPE := 9;

-- LISTE DES TYPES DE CONTACTS
-- CES CONSTANTES DOIVENT IMPERATIVEMENT MATCHER AVEC LES DONNEES DE LA TABLE CONFIG.CONTACT_TYPE
c_SITE_MAIN_CONTACT            CONSTANT CONFIG.CONTACT_TYPE.CONTACT_TYPE_ID%TYPE := 1;  -- MAIN_CONTACT       : Contact Principal
c_SITE_OPERATIONAL_CONTACT     CONSTANT CONFIG.CONTACT_TYPE.CONTACT_TYPE_ID%TYPE := 2;  -- OPERATIONAL_CONTACT : Contact Opérationnel
c_SITE_BILLING_CONTACT         CONSTANT CONFIG.CONTACT_TYPE.CONTACT_TYPE_ID%TYPE := 3;  -- BILLING_CONTACT   : Contact de facturation
c_SITE_OTHERS_CONTACT          CONSTANT CONFIG.CONTACT_TYPE.CONTACT_TYPE_ID%TYPE := 4;  -- OTHERS               : Autres

-- Type d'indisponibilité cherché pour les enlever
INDISPO_TYPE_MISSING_PDA_ASSOC CONSTANT CONFIG.INDISPO_TYPE.TYPE_NAME%TYPE := 'MISSING_PDA_ASSOCIATION';

-- Constantes utilisées dans Opening Hours
c_Day_MONDAY_ID     CONSTANT INTEGER      := 1; -- constante pour le LUNDI
c_Day_TUESDAY_ID    CONSTANT INTEGER      := 2; --                   MARDI
c_Day_WEDNESDAY_ID  CONSTANT INTEGER      := 3; --                   MERCREDI
c_Day_THURSDAY_ID   CONSTANT INTEGER      := 4; --                   JEUDI
c_Day_FRIDAY_ID     CONSTANT INTEGER      := 5; --                   VENDREDI
c_Day_SATURDAY_ID   CONSTANT INTEGER      := 6; --                   SAMEDI
c_Day_SUNDAY_ID     CONSTANT INTEGER      := 7; --                   DIMANCHE
c_Day_CLOSED        CONSTANT VARCHAR2(1)  := '0'; -- constante pour indiquer un jour fermé

c_Day_MONDAY        CONSTANT VARCHAR2(10) := 'MONDAY';
c_Day_TUESDAY       CONSTANT VARCHAR2(10) := 'TUESDAY';
c_Day_WEDNESDAY     CONSTANT VARCHAR2(10) := 'WEDNESDAY';
c_Day_THURSDAY      CONSTANT VARCHAR2(10) := 'THURSDAY';
c_Day_FRIDAY        CONSTANT VARCHAR2(10) := 'FRIDAY';
c_Day_SATURDAY      CONSTANT VARCHAR2(10) := 'MONDAY';
c_Day_SUNDAY        CONSTANT VARCHAR2(10) := 'SUNDAY';

c_Type_Period_VACATION CONSTANT NUMBER(1)  := 1;  --cf. CONFIG.PERIOD_TYPE / saisi dans MASTER.PERIOD.PERIOD_TYPE_ID


-- Constantes pour MEssage_PDA
c_POPUP_TYPE_AUCUN CONSTANT CONFIG.POPUP_TYPE.POPUP_TYPE_NAME%TYPE := 'AUCUN';  -- libellé AUCUN
c_FORM_TYPE_AUCUN  CONSTANT CONFIG.FORM_TYPE.FORM_TYPE_NAME%TYPE   := 'AUCUN';  -- libellé AUCUN


-- [10163] Ajout de la constante pour  PCK_BO_SITE_INFO.GetActiveSites pour les sites utilisant la WEBAPP/MOBILE
c_DEVICE_TYPE_WEBAPP CONSTANT NUMBER(1)  := 1;


-- [10093] Ajout de la constante pour  PCK_BO_SITE_INFO.GetActiveSites pour les sites utilisant la WEBAPP/MOBILE
c_EVENT_XMLFILE        CONSTANT VARCHAR2(20)  := 'T_EVENT';          -- cf. IMPORT_PDA.T_XMLFILE.FILE_TYPE / cf. les valeurs dans la table CONFIG.FILE_TYPE.FILE_TYPE_ID
c_OPENINGHOURS_XMLFILE CONSTANT VARCHAR2(20)  := 'T_OPENING_HOURS';  --
c_PERIOD_XMLFILE       CONSTANT VARCHAR2(20)  := 'T_PERIOD';         --


-- TIME ZONE UTC
c_TIMESTAMP_TIME_ZONE_UTC CONSTANT VARCHAR2(10)  := 'UTC';
-- TIME ZONE EUROPE/PARIS
c_TIMESTAMP_TIME_ZONE_PARIS CONSTANT VARCHAR2(20)  := 'EUROPE/PARIS';


c_device_type_id_PDA_ANDROID  CONSTANT CONFIG.DEVICE_TYPE.DEVICE_TYPE_ID%TYPE := 1 ;
c_device_type_id_MOBILE       CONSTANT CONFIG.DEVICE_TYPE.DEVICE_TYPE_ID%TYPE := 2 ;
c_device_type_id_PDA_WINDOWS  CONSTANT CONFIG.DEVICE_TYPE.DEVICE_TYPE_ID%TYPE := 3 ;
c_device_type_id_BYOD         CONSTANT CONFIG.DEVICE_TYPE.DEVICE_TYPE_ID%TYPE := 4 ;
c_device_type_id_WEBAPP       CONSTANT CONFIG.DEVICE_TYPE.DEVICE_TYPE_ID%TYPE := 5 ;

-- DEFINITION DES CONSTANTES D'ERREUR
errnum_requiredparam           constant number := -20500;
errmsg_requiredparam           constant varchar2(200):= 'MISSING REQUIRED PARAMETER VALUE(S):' ;

errnum_paramdomain             constant number := -20501;
errmsg_paramdomain             constant varchar2(200):= 'PARAMETER VALUE NOT ALLOWED ' ;

errnum_wrong_site_type_id      constant number := -20502;
errmsg_wrong_site_type_id      constant varchar2(200):= 'SITE_TYPE_ID NOT ALLOWED ' ;

errnum_wrong_value_domain      constant number := -20503;
errmsg_wrong_value_domain      constant varchar2(200):= 'ATTRIBUTE VALUE NOT IN DOMAIN.' ;

errnum_invalid_range_date      constant number := -20504;
errmsg_invalid_range_date      constant varchar2(200):= 'INVALID RANGE DATE.' ;

errnum_period_overlapping      constant number := -20505;
errmsg_period_overlapping      constant varchar2(200):= 'PERIOD OVERLAPPING.' ;

errnum_sitenotexists           constant number := -20506; -- NO DATA FOUND               -- 2017.02.21
errmsg_sitenotexists           constant varchar2(200):= 'THIS SITE DOES NOT EXIST : ' ;

END PCK_API_CONSTANTS;

/