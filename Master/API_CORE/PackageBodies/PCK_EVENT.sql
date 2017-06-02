CREATE OR REPLACE PACKAGE BODY api_core.PCK_EVENT IS
-- ***************************************************************************
--  PACKAGE BODY: PCK_EVENT
--  DESCRIPTION : Package to deal with events coming from web API
--                inspired from and reusing how XML files of types
--                T_EVENT and T_EVENT_PROPERTIES coming from PDAs are uploaded
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.23 | Hocine HAMMOU + Maria CASALS
--          | Init
--          |
--  V01.100 | 2015.06.24 | Maria CASALS
--          | Plus de parametre p_USER_LOGIN
--          | Q_OPENNED_PARCEL renommé à Q_OPEN_PARCEL dans les TYPES (pas dans les property names
--          | Pour tous les evenements:
--          |    · Les colonnes EVENT_ID et PARCEL_KNOWN disparaissent
--          |    · LOCAL_DTM devient DATE (donc datetime jusqu'à la seconde)
--  V01.200 | 2015.06.29 | Maria CASALS
--          | Ajout de l'évènement REFUSE
--          |
--  V01.300 | 2015.07.02| Hocine HAMMOU
--          | Ajout d'un controle sur les Property Name pour éviter
--          | d'insérer des property sans value dans la table T_EVENT_PROPERTIES_IMPORTED
--          |
--  V01.350 | 2015.07.10| Hocine HAMMOU
--          | INTERNATIONAL_SITE_ID remplacé par SITE_ID
--          |
--  V01.360 | 2015.07.15| Hocine HAMMOU
--          | Ajout des fonctionnalités EASY PINCODE + COD ( Cash On Delivery)
--          |
--  V01.370 | 2015.07.20 | Maria CASALS
--          | Suppression de la procédure et fonction traitant l'évènement REFUSE
--          | Ajout de la procédure et fonction traitant l'évènement PREPARATION
--          |
--  V01.380 | 2015.07.28 | Amadou YOUNSAH
--          | Creation de la procédure traitant les collections
--          |
--  V01.390 | 2015.07.31 | Amadou YOUNSAH
--          | Creation de la procédure traitant les dropoff
--          |
--  V01.395 | 2015.08.21 | Hocine HAMMOU
--          | Gestion du FIRM_PARCEL_OTHER comme une propertie
--          |
--  V01.400 | 2015.08.27 | Hocine HAMMOU
--          | Remplacement de SITE_ID par INTERNATIONAL_SITE_ID dans T_XMLFILES
--          |
--  V01.410 | 2015.10.20 | Hocine HAMMOU
--          | Creation de la procédure process_xmlfile
--          |
--  V01.411 | 2015.11.16 | Hocine HAMMOU
--          | Ajout gestion des propriétés RECEIVER_TYPE (Lien de parenté), et CHECKLIST (NATURE_OF_GOODS)
--          |
--  V01.412 | 2015.10.20 | Hocine HAMMOU
--          | LOT2 INDE : ajout du motif de raison de refus client 'Refused to pay COD amount' , 'Parcel damaged' , 'Other'
--          |
--  V01.413 | 2016.02.03 | Hocine HAMMOU
--          | [10163] RM1 LOT2 INDE : Ajout des réserves -> Q_DAMAGED_PARCEL
--          |                                            -> Q_OPEN_PARCEL
--          |
--  V01.414 | 2016.02.16 | Hocine HAMMOU
--          | [10093] MODE DECONNECTE
--          | Correction des traitements de dates TIMESTAMP(6) WITH TIMEZONE
--          | Principe retenue l'heure envoyé par l'API est en UTC
--          | Puis cette heure est CAST avec la TIME ZONE UTC
--          |
--  V01.415 | 2016.03.21 | Hocine HAMMOU
--          | projet RM2 [10302] Transfert de responsabilité :
--          | Ajout dans l'event DELIVERY de la gestion attributs CAB2DKEY et CAB2DSTATUS
--          | Ajout dans l'event COLLECTION de la gestion attributs CAB2DKEY et CAB2DSTATUS
--          | Ajout gestion de l'event SCAN_COLLECTION
--          |
--  V01.416 | 2016.08.17 | Hocine HAMMOU
--          | projet RM3 [10330] Application Hybride Android V3
--          | Ajout gestion de l'event INVENTORY
--          |
--  V01.417 | 2016.08.19 | Hocine HAMMOU
--          | projet RM3 [10330] Application Hybride Android V3
--          | Ajout des propriétés RECEIPT_NUMBER (alias le TRACKING NUMBER) et PHONE_NUMBER dans l'event DROPOFF
--          |
--  V01.418 | 2016.08.22 | Hocine HAMMOU
--          | projet RM3 [10330] Application Hybride Android V3
--          | Ajout gestion de l'event SCAN pour le DROPPOFF
--          |
--  V01.419 | 2016.09.09 | Hocine HAMMOU
--          | projet RM3 [10330] Application Hybride Android V3
--          | Ajout gestion de l'event SCAN pour le DELIVERY et PICKUP
--          |
--  V01.420 | 2016.09.15 | Hocine HAMMOU
--          | projet RM3 [10330] Application Hybride Android V3
--          | Ajout gestion de l'event SCAN pour le COLLECTION_PREPARATION ( colis à collecter suite à préparation)
--          |
--  V01.421 | 2016.11.02 | Hocine HAMMOU
--          | projet [10472] Ajout propriété Transporteur Physique => PHYSICAL_CARRIER_ID
--          |
--  V01.422 | 2016.11.16 | Hocine HAMMOU
--          | Projet [10472] Evolution PICKUP UK - Ajout propriété IDENTITY_VERIFICATION_2
--          |
--  V01.423 | 2016.11.25 | Hocine HAMMOU
--          | Projet [10472] Evolution PICKUP - Ajout fonctionnalité SWAP : propriétés SWAP et RETURN_FIRM_PARCEL_ID
--          |                Evolution DROPOFF - Ajout fonctionnalité SWAP : propriétés SWAP et DELIVERY_FIRM_PARCEL_ID
--          |
--  V01.424 | 2017.01.24 | Hocine HAMMOU
--          | Projet [10237] Integration des dates/heures des evenements dans le fuseau horaire du pudo
-- ***************************************************************************

c_JOB_ACTION                   CONSTANT VARCHAR2(100):= 'IMPORT_PDA.PCK_TRACING_PDA.TRACING_PDA_V1_STEP2';
c_FILE_SENDER                  CONSTANT VARCHAR2(50) := IMPORT_PDA.PCK_TRACING_PDA.c_FILE_SENDER_WEB_API; -- IMPORT_PDA.T_XMLFILES.FILE_SENDER
c_FILE_TYPE                    CONSTANT VARCHAR2(15) := 'T_EVENT';                                        -- IMPORT_PDA.T_XMLFILES.FILE_TYPE
c_FILE_VERSION                 CONSTANT VARCHAR2(3)  := '1.0';                                            -- IMPORT_PDA.T_XMLFILES.FILE_VERSION
c_STATUS_BUILD                 CONSTANT VARCHAR2(15) := 'NA';                                             -- IMPORT_PDA.T_XMLFILES.STATUS_BUILD
c_EVT_LINE_NUMBER              CONSTANT PLS_INTEGER  := 1;                                                -- IMPORT_PDA.T_EVENT_IMPORTED.LINE_NBR initialisé à 1 car un seul evenement par fichier
c_FILE_DTM_MASK                CONSTANT VARCHAR2(30) := 'YYYYMMDDHH24MISS';                               -- IMPORT_PDA.T_EVENT_IMPORTED.LINE_NBR initialisé à 1 car un seul evenement par fichier
c_FILE_NAME_EXTENSION          CONSTANT VARCHAR2(5)  := '.XML';
c_FILE_NAME_SEPARATOR          VARCHAR2(1)           := '-';
c_EVENT_ID                     INTEGER               := 1;                                                -- IMPORT_PDA.T_EVENT_IMPORTED.PDA_EVENT_ID
c_PARCEL_KNOWN                 CONSTANT NUMBER(1)    := 0;                                                -- Flag 1/0 --> IMPORT_PDA.T_EVENT_IMPORTED.PARCEL_KNOWN
c_TIMESTAMP_TIME_ZONE          CONSTANT VARCHAR2(50) := 'Europe/Paris';                                   -- pour faire pareil que IMPORT_PDA.PCK_TRACING_PDA.TRACING_PDA_V1_STEP1
--c_EVT_LINE_STATE_TRAINING      CONSTANT PLS_INTEGER  := 1;                                              -- IMPORT_PDA.T_EVENT_IMPORTED.LINE_STATE à 1 pour le TRAINING. Ces events ne sont pas pris en compte par le PROCESS_ALL

-- record and list to store the properties in key - value format
TYPE evt_prop_type IS RECORD
   ( property_name  IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_NAME%TYPE
   , property_value IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED.PROPERTY_VALUE%TYPE
   );
TYPE evt_prop_tab_type IS TABLE OF evt_prop_type;

FUNCTION filename( p_FILE_PDA_ID  IN VARCHAR2     --ENTRY_FILE.SITE_ID%TYPE
                 , p_FILE_DTM_UTC IN DATE         --ENTRY_FILE.LOCAL_DTM%TYPE)
                 , p_FILE_ID      IN PLS_INTEGER
                 )
RETURN VARCHAR2
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'filename';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_file_name  IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
BEGIN

  l_file_name :=                           c_FILE_TYPE
               || c_FILE_NAME_SEPARATOR || c_FILE_SENDER
               || c_FILE_NAME_SEPARATOR || p_FILE_PDA_ID
               || c_FILE_NAME_SEPARATOR || c_STATUS_BUILD
               || c_FILE_NAME_SEPARATOR || c_FILE_VERSION
               || c_FILE_NAME_SEPARATOR || 'UTC' || to_char(p_FILE_DTM_UTC,c_FILE_DTM_MASK)
               || c_FILE_NAME_SEPARATOR || to_char(p_FILE_ID)  -- pour l'unicité de filename...
               || c_FILE_NAME_EXTENSION;
   RETURN    l_file_name;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END filename;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : recevies a list and a key-value record
--               initializes the list if it is empty
--               adds the row to the list
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
PROCEDURE addKeyValue(p_list IN OUT NOCOPY evt_prop_tab_type, p_prop IN evt_prop_type)
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'addKeyValue';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   IF p_prop.PROPERTY_NAME IS NOT NULL THEN
      IF p_list IS NULL THEN
         p_list := new evt_prop_tab_type();
      END IF;
      p_list.extend;
      p_list(p_list.COUNT):= p_prop;
   END if;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END addKeyValue;

-- ---------------------------------------------------------------------------
-- ATTENTION AN OVERLOAD OF THIS FUNCTION MUST EXIST FOR EVERY POSSIBLE PROPERTY TYPE
-- OTHERWISE if we call the overload treating integers with a float, we will loose decimal positions
--
-- DESCRIPTION : Transforms property of NUMBER type into a key-value pair
-- ---------------------------------------------------------------------------
-- PARAMETERS  : p_property_value the value of the NUMBER property
--             :
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_property_value IN NUMBER, p_property_name IN VARCHAR2, p_property_mask IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   IF PCK_API_TOOLS.ITEM_IN_LIST(P_LIST => p_relevant_properties, p_item => p_property_name) then
      IF p_property_value is not null then
         l_prop.PROPERTY_NAME := p_property_name;
         IF p_property_mask is not null then
            l_prop.PROPERTY_VALUE := to_char(p_property_value, p_property_mask);
         ELSE
            l_prop.PROPERTY_VALUE := p_property_value; -- conversion implicite
         END IF;
      END IF;
   END IF;

   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- ATTENTION AN OVERLOAD OF THIS FUNCTION MUST EXIST FOR EVERY POSSIBLE PROPERTY TYPE
-- OTHERWISE if we call the overload treating integers with a float, we will loose decimal positions
--
-- DESCRIPTION : Transforms property of VARCHAR type into a key-value pair
-- ---------------------------------------------------------------------------
-- PARAMETERS  : p_property_value the value of the VARCHAR property
--             :
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_property_value IN VARCHAR, p_property_name IN VARCHAR2, p_property_mask IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   IF PCK_API_TOOLS.ITEM_IN_LIST (P_LIST => p_relevant_properties, p_item => p_property_name) then
      IF p_property_value is not null then
         l_prop.PROPERTY_NAME := p_property_name;
         IF p_property_mask is not null then
            l_prop.PROPERTY_VALUE := to_char(p_property_value, p_property_mask);
         ELSE
            l_prop.PROPERTY_VALUE := p_property_value; -- conversion implicite
         END IF;
      END IF;
   END IF;

   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property DURATION into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_DURATION IN PLS_INTEGER, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_DURATION
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_DURATION
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_DURATION
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property BARCODE into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_BARCODE IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_BARCODE
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_BARCODE
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_BARCODE
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property SIGN_DATA into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_SIGN_DATA IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_SIGN_DATA
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_SIGN_DATA
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_SIGN_DATA
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property Q_DAMAGED_PARCEL into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_Q_DAMAGED_PARCEL IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   if p_Q_DAMAGED_PARCEL = 1 then
     l_prop.PROPERTY_NAME := PCK_API_CONSTANTS.c_PROP_DAMAGED_PARCEL;
   END if;
   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property Q_OPENNED_PARCEL into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_Q_OPENNED_PARCEL IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   if p_Q_OPENNED_PARCEL = 1 then
     l_prop.PROPERTY_NAME := PCK_API_CONSTANTS.c_PROP_OPEN_PARCEL;
   END if;
   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property FORM into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_FORM IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_FORM
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_FORM
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_FORM
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property REASON into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_REASON IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit       MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_REASON
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_REASON
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_REASON
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;


-- 2015.07.15 START
-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property CDC_CODE into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_CDC_CODE IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_CDC_CODE
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_CDC_CODE
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_CDC_CODE
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property NAME_OF_RECIPIENT into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_NAME_OF_RECIPIENT IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_NAME_OF_RECIPIENT
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_RECIPIENT_NAME
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_RECIPIENT_NAME
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property IDENTITY_VERIFICATION into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_IDENTITY_VERIFICATION IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_IDENTITY_VERIFICATION
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_IDENTITY_VERIF
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_IDENTITY_VERIF
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property ID_RECORD into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_ID_RECORD IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_ID_RECORD
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_ID_RECORD
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_ID_RECORD
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property COD_AMOUNT_PAID into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_COD_AMOUNT_PAID IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_COD_AMOUNT_PAID
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_COD_AMOUNT_PAID
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_COD_AMOUNT_PAID
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property COD_CURRENCY into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_COD_CURRENCY IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_COD_CURRENCY
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_COD_CURRENCY
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_COD_CURRENCY
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property COD_MEANS_PAYMENT_ID into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_COD_MEANS_PAYMENT_ID IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_COD_MEANS_PAYMENT_ID
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_COD_MEANS_PAYMENT_ID
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_COD_MEANS_PAYMNT
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;
-- 2015.07.15 END

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property FIRM_PARCEL_OTHER into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_FIRM_PARCEL_OTHER IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_FIRM_PARCEL_OTHER
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_FIRM_PARCEL_OTHER
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_FIRM_PARCEL_OTHER
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property CHECKLIST into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_CHECKLIST IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_CHECKLIST
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_CHECKLIST
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_CHECKLIST
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property RECEIVER_TYPE into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_RECEIVER_TYPE IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_RECEIVER_TYPE
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_RECEIVER_TYPE
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_RECEIVER_TYPE
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;



-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property CAB2DKEY into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_CAB2DKEY IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   if p_CAB2DKEY IS NOT NULL then
     l_prop.PROPERTY_NAME := PCK_API_CONSTANTS.c_PROP_CAB2DKEY;
     l_prop.PROPERTY_VALUE := p_CAB2DKEY;
   END if;
   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property CABD2STATUS into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_CAB2DSTATUS IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   if p_CAB2DSTATUS IS NOT NULL then
     l_prop.PROPERTY_NAME := PCK_API_CONSTANTS.c_PROP_CAB2DSTATUS;
     l_prop.PROPERTY_VALUE := p_CAB2DSTATUS;
   END if;
   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property RECEIPT_NUMBER into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_RECEIPT_NUMBER IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   if p_RECEIPT_NUMBER IS NOT NULL then
     l_prop.PROPERTY_NAME := PCK_API_CONSTANTS.c_PROP_RECEIPT_NUMBER;
     l_prop.PROPERTY_VALUE := p_RECEIPT_NUMBER;
   END if;
   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property PHONE_NUMBER into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_PHONE_NUMBER IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   if p_PHONE_NUMBER IS NOT NULL then
     l_prop.PROPERTY_NAME := PCK_API_CONSTANTS.c_PROP_PHONE_NUMBER;
     l_prop.PROPERTY_VALUE := p_PHONE_NUMBER;
   END if;
   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property PHYSICAL_CARRIER_ID into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_PHYSICAL_CARRIER_ID IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   if p_PHYSICAL_CARRIER_ID IS NOT NULL then
     l_prop.PROPERTY_NAME := PCK_API_CONSTANTS.c_PROP_PHYSICAL_CARRIER_ID;
     l_prop.PROPERTY_VALUE := p_PHYSICAL_CARRIER_ID;
   END if;
   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;


-- --------------------------------------------------------------------------------
-- DESCRIPTION : Transforms property IDENTITY_VERIFICATION_2 into a key-value pair
-- --------------------------------------------------------------------------------
--  PARAMETERS
-- --------------------------------------------------------------------------------
FUNCTION KeyValuePair(p_IDENTITY_VERIFICATION_2 IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_IDENTITY_VERIFICATION_2
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_IDENTITY_VERIF_2
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_IDENTITY_VERIF_2
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property SWAP into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_SWAP IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   if p_SWAP = 1 then
     l_prop.PROPERTY_NAME := PCK_API_CONSTANTS.c_PROP_SWAP;
   END if;
   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- --------------------------------------------------------------------------------
-- DESCRIPTION : Transforms property RETURN_FIRM_PARCEL_ID into a key-value pair
-- --------------------------------------------------------------------------------
--  PARAMETERS
-- --------------------------------------------------------------------------------
FUNCTION KeyValuePair(p_RETURN_FIRM_PARCEL IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_RETURN_FIRM_PARCEL
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_RETURN_FIRM_PARCEL
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_RETURN_FIRM_PARCEL
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- --------------------------------------------------------------------------------
-- DESCRIPTION : Transforms property DELIVERY_FIRM_PARCEL_ID into a key-value pair
-- --------------------------------------------------------------------------------
--  PARAMETERS
-- --------------------------------------------------------------------------------
FUNCTION KeyValuePair(p_DELIVERY_FIRM_PARCEL IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_DELIVERY_FIRM_PARCEL
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_DELIVERY_FIRM_PARCEL
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_DELIVERY_FIRM_PARC
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- --------------------------------------------------------------------------------
-- DESCRIPTION : Transforms property ASSOCIATED_CAB2D into a key-value pair
-- --------------------------------------------------------------------------------
--  PARAMETERS
-- --------------------------------------------------------------------------------
FUNCTION KeyValuePair(p_ASSOCIATED_CAB2D IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_ASSOCIATED_CAB2D
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_ASSOCIATED_CAB2D
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_ASSOCIATED_CAB2D
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Transforms property ABANDONED into a key-value pair
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION KeyValuePair(p_ABANDONED IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_prop        evt_prop_type;
BEGIN
   if p_ABANDONED = 1 then
     l_prop.PROPERTY_NAME := PCK_API_CONSTANTS.c_PROP_ABANDONED;
   END if;
   RETURN l_prop;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- --------------------------------------------------------------------------------
-- DESCRIPTION : Transforms property INVENTORY_STATE into a key-value pair
-- --------------------------------------------------------------------------------
--  PARAMETERS
-- --------------------------------------------------------------------------------
FUNCTION KeyValuePair(p_INVENTORY_STATE IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_INVENTORY_STATE
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_INVENTORY_STATE
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_INVENTORY_STATE
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- --------------------------------------------------------------------------------
-- DESCRIPTION : Transforms property INVENTORY_SESSION into a key-value pair
-- --------------------------------------------------------------------------------
--  PARAMETERS
-- --------------------------------------------------------------------------------
FUNCTION KeyValuePair(p_INVENTORY_SESSION IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_INVENTORY_SESSION
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_INVENTORY_SESSION
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_INVENTORY_SESSION
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- --------------------------------------------------------------------------------
-- DESCRIPTION : Transforms property INVENTORY_ORIGIN into a key-value pair
-- --------------------------------------------------------------------------------
--  PARAMETERS
-- --------------------------------------------------------------------------------
FUNCTION KeyValuePair(p_INVENTORY_ORIGIN IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_INVENTORY_ORIGIN
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_INVENTORY_ORIGIN
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_INVENTORY_ORIGIN
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- --------------------------------------------------------------------------------
-- DESCRIPTION : Transforms property INVENTORY_USE_CASE into a key-value pair
-- --------------------------------------------------------------------------------
--  PARAMETERS
-- --------------------------------------------------------------------------------
FUNCTION KeyValuePair(p_INVENTORY_USE_CASE IN VARCHAR2, p_relevant_properties IN VARCHAR2) RETURN evt_prop_type
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'KeyValuePair';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   RETURN KeyValuePair( p_property_value => p_INVENTORY_USE_CASE
                      , p_property_name => PCK_API_CONSTANTS.c_PROP_INVENTORY_USE_CASE
                      , p_property_mask => PCK_API_CONSTANTS.c_PROP_MASK_INVENTORY_USE_CASE
                      , p_relevant_properties => p_relevant_properties);
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END KeyValuePair;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Validate the value  . Fonction à sortir de API_CORE
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
-- TODO : voir où placer cette fonction ?? MASTER_PROC.PCK_PARCEL ??
FUNCTION GetReasonId(p_REASON IN VARCHAR2) RETURN CONFIG.SHIPTO_REFUSE_REASON.REFUSE_REASON_ID%TYPE
IS
   l_refuse_reason_id CONFIG.SHIPTO_REFUSE_REASON.REFUSE_REASON_ID%TYPE;
BEGIN
   SELECT SRR.REFUSE_REASON_ID INTO l_refuse_reason_id
   FROM CONFIG.SHIPTO_REFUSE_REASON SRR
   WHERE SRR.REFUSE_REASON_CODE = p_REASON;
   RETURN l_refuse_reason_id;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN NULL;
      WHEN OTHERS THEN
         RETURN NULL;
END GetReasonId;


-- TODO
-- ---------------------------------------------------------------------------
-- DESCRIPTION : Checks value of property REASON
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
PROCEDURE checkAttrValue(p_REASON IN VARCHAR2)
is
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'checkAttrValue';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   IF GetReasonId (p_REASON => p_REASON ) IS NULL then
      -- RAISE_APPLICATION_ERROR  UN TRUC DE DIRE QUE LE DOMAINE DES VALEURS POSSIBLES NON NON NON
      RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_wrong_value_domain,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_wrong_value_domain||'( Attribute : REASON - Value:'||p_REASON||').');
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END checkAttrValue;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of any type
--               meant to receive information for one event
--               together with an array of properties in key-value format
--               then it will insert into
--                 · IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
--                 · IMPORT_PDA.T_EVENT_IMPORTED
--                 · IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED (in key-value format)
-- ---------------------------------------------------------------------------
--  PARAMETERS
-- ---------------------------------------------------------------------------
FUNCTION  INS_EVT
( p_evt_type    in VARCHAR -- same value as received so far in T_EVENT file, inside <EVT_TYPE_ID> tag. Example 'PICKUP'. Which list of possible values? / constant
, p_event_id    IN NUMBER
, p_evt         IN api_core.EVT_TYPE
, p_properties  IN evt_prop_tab_type
) RETURN INTEGER
is l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_start_date_UTC DATE := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   l_evt_file_name    IMPORT_PDA.T_XMLFILES.FILE_NAME%TYPE;
   l_filexml_id       IMPORT_PDA.T_XMLFILES.FILE_ID%TYPE := null;
   l_count_properties INTEGER;
   l_site_id          MASTER.SITE.SITE_ID%TYPE;
   l_file_state       NUMBER(1);
   l_SiteTestTypeId   NUMBER(1);
   l_timezone         MASTER.SITE.TIMEZONE%TYPE;      -- 2017.01.20 projet [10237]

BEGIN
   --if p_evt is null then RAISE_application_error ????

   -- -----------------------------------------------------------------------------
   -- A PARTIR DE INTERNATIONAL_SITE_ID, CONTROLE SI EXISTENCE DU SITE_ID ASSOCIE
   -- -----------------------------------------------------------------------------
   l_site_id := MASTER_PROC.PCK_SITE.GetSiteid( p_site_international_id => p_evt.INTERNATIONAL_SITE_ID );
   IF l_site_id = -1 THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_sitenotexists,PCK_API_CONSTANTS.errmsg_sitenotexists || p_evt.INTERNATIONAL_SITE_ID);
   END IF;

  -- -----------------------------------------------------------------------------
  -- CONTROLE SI VRAI PUDO (PAS FORMATION, PAS TRAINING
  -- -----------------------------------------------------------------------------
   l_SiteTestTypeId:= PCK_SITE.SiteTestTypeId( p_site_id => l_site_id );
   IF l_SiteTestTypeId = PCK_SITE.c_SITE_TEST_TYPE_ID_NO_TEST THEN
      l_file_state := IMPORT_PDA.PCK_XMLFILE.c_FILE_STATE_EXTRACTED_XML;
   ELSE
      RAISE_APPLICATION_ERROR(PCK_API_CONSTANTS.errnum_wrong_site_type_id,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_wrong_site_type_id||'(TYPE:'||l_SiteTestTypeId || '-SITE:'||p_evt.INTERNATIONAL_SITE_ID||').');
   END IF;

   -- -----------------------------------------------------------------------------
   -- RECUPERATION DE LA TIMEZONE DU PUDO
   -- -----------------------------------------------------------------------------
   l_timezone := MASTER_PROC.PCK_SITE.GetSiteTimezone(p_siteid => l_site_id);

   -- IF l_timezone IS NULL THEN
   --    l_timezone := PCK_API_CONSTANTS.c_TIMESTAMP_TIME_ZONE_UTC ;
   -- END IF;

   -- -----------------------------------------------------------------------------
   -- GENERATION ID POUR LE FICHIER
   -- -----------------------------------------------------------------------------
   l_filexml_id := IMPORT_PDA.PCK_XMLFILE.GenerateFileId;

   -- ------------------------------------------------------------------------
   -- build file name following the rule used in IMPORT_PDA to cut it out
   -- ------------------------------------------------------------------------
   l_evt_file_name := filename( p_FILE_PDA_ID => p_evt.INTERNATIONAL_SITE_ID, p_FILE_DTM_UTC => l_start_date_UTC, p_file_id => l_filexml_id);

   -- ------------------------------------------------------------------------
   -- insert into    IMPORT_PDA.T_XMLFILES with empty XML and convenient default values
   -- ------------------------------------------------------------------------
   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => 'l_filexml_id : ' || to_char(l_filexml_id)   );
   IMPORT_PDA.PCK_XMLFILE.InsertFile( p_file_id         => l_filexml_id
                                    , p_file_name       => l_evt_file_name
                                    , p_creation_dtm    => l_start_date
                                    , p_file_type       => c_FILE_TYPE
                                    , p_file_version    => c_FILE_VERSION
                                    , p_file_sender     => c_FILE_SENDER
                                    , p_file_pda_id     => p_evt.INTERNATIONAL_SITE_ID
                                    , p_file_dtm        => p_evt.local_dtm
                                    , p_file_state      => l_file_state
                                    , p_file_state_dtm  => l_start_date
                                    , p_status_build    => c_STATUS_BUILD
                                    );

   -- ------------------------------------------------------------------------
   -- insert into    IMPORT_PDA.T_EVENT_IMPORTED
   -- ------------------------------------------------------------------------
   IF p_properties IS NOT NULL THEN
     l_count_properties :=  p_properties.COUNT;
   END IF;

   IMPORT_PDA.PCK_EVENT_IMPORTED.InsertEventImported( p_file_id         => l_filexml_id
                                                    , p_line_nbr        => c_EVT_LINE_NUMBER
                                                    , p_bo_parcel_id    => p_evt.BO_PARCEL_ID
                                                    , p_parcel_known    => c_PARCEL_KNOWN
                                                    , p_firm_id         => p_evt.FIRM_ID
                                                    , p_firm_parcel_id  => p_evt.FIRM_PARCEL_ID
                                                    , p_pda_event_id    => p_event_id
                                                    , p_event_type_id   => p_evt_type
                                                    , p_dtm             => ( FROM_TZ(CAST(p_evt.LOCAL_DTM AS TIMESTAMP ), PCK_API_CONSTANTS.c_TIMESTAMP_TIME_ZONE_UTC ) ) AT TIME ZONE l_timezone -- 2016.12.30 Projet [10237] Integration date/heure dans la timezone du pudo
                                                    , p_properties_qty  => NVL(l_count_properties,0)
                                                    );

   FOR i IN 1 ..NVL(l_count_properties,0)
   LOOP
      -- --------------------------------------------------------------------------------------------
      -- insert properties common to every event type in IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED     -
      -- des valeurs qui seraient dans le type et pourtant mappes comme property??
      -- insert specific properties received in key-value list into IMPORT_PDA.T_EVENT_PROPERTIES_IMPORTED  -
      -- ----------------------------------------------------------------------------------------------------
      IMPORT_PDA.PCK_EVENT_IMPORTED.InsertEventPropertiesImported( p_file_id => l_filexml_id
                                                                 , p_line_nbr => i
                                                                 , p_pda_event_id => p_event_id
                                                                 , p_property_name => p_properties(i).property_name
                                                                 , p_property_value => p_properties(i).property_value
                                                                 );


   END LOOP;

   -- ------------------------------------------------------------------------
   -- output: FILE_ID
   -- ------------------------------------------------------------------------
   RETURN l_filexml_id;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of type PICKUP
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific PICKUP event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE ins_EVT_PICKUP( p_evt IN EVT_PICKUP_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_PICKUP';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE ;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN

   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- CONTROLE DU CHAMP ID_TYPE
   l_requiredparams := p_evt.MissingMandAttrs_IDType(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- CONTROLE DU CHAMP PAYMENT_TYPE
   l_requiredparams := p_evt.MissingMandAttrs_PaymentType(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- CONTROLE DU CHAMP REFUSE_TYPE
   l_requiredparams := p_evt.MissingMandAttrs_RefuseType(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- CONTROLE DU CHAMP RECEIVER_TYPE_MANDATORY
   l_requiredparams := p_evt.MissingMandAttrs_ReceiverType(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- CONTROLE DES CHAMPS SWAP_MANDATORY
   l_requiredparams := p_evt.MissingMandAttrs_SWAP(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- transform properties specific to PICKUP event to a list of key-value format
   -- ------------------------------------------------------------------------
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_DURATION => p_evt.DURATION, p_relevant_properties => l_relevant_properties ));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_DAMAGED_PARCEL => p_evt.Q_DAMAGED_PARCEL));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_OPENNED_PARCEL => p_evt.Q_OPEN_PARCEL));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_SIGN_DATA => p_evt.SIGN_DATA, p_relevant_properties => l_relevant_properties));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CDC_CODE => p_evt.CDC_CODE, p_relevant_properties => l_relevant_properties));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_NAME_OF_RECIPIENT => p_evt.NAME_OF_RECIPIENT, p_relevant_properties => l_relevant_properties));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_IDENTITY_VERIFICATION => p_evt.IDENTITY_VERIFICATION, p_relevant_properties => l_relevant_properties));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_ID_RECORD => p_evt.ID_RECORD, p_relevant_properties => l_relevant_properties));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_COD_AMOUNT_PAID => p_evt.COD_AMOUNT_PAID, p_relevant_properties => l_relevant_properties));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_COD_CURRENCY => p_evt.COD_CURRENCY, p_relevant_properties => l_relevant_properties));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_COD_MEANS_PAYMENT_ID => p_evt.COD_MEANS_PAYMENT_ID, p_relevant_properties => l_relevant_properties));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_RECEIVER_TYPE => p_evt.RECEIVER_TYPE, p_relevant_properties => l_relevant_properties));

-- LOT2 INDE : ajout du motif de raison de refus client 'Refused to pay COD amount' , 'Parcel damaged' , 'Other'
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_REASON => p_evt.REASON, p_relevant_properties => l_relevant_properties));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_IDENTITY_VERIFICATION_2 => p_evt.IDENTITY_VERIFICATION_2, p_relevant_properties => l_relevant_properties)); -- 2016.11.16 [10472]

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_SWAP => p_evt.SWAP)); -- 2016.11.25 [10472]

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_RETURN_FIRM_PARCEL => p_evt.RETURN_FIRM_PARCEL_ID, p_relevant_properties => l_relevant_properties)); -- 2016.11.25 [10472]

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FIRM_PARCEL_ID:'|| p_evt.FIRM_PARCEL_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_PICKUP;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : See procedure with the same name
-- ---------------------------------------------------------------------------
FUNCTION  ins_EVT_PICKUP( p_evt IN EVT_PICKUP_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_PICKUP';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_PICKUP( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_PICKUP;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of type DELIVERY
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- ---------------------------------------------------------------------------
--  V01.001 | 2016.11.02 | Hocine HAMMOU
--          | projet [10472] Ajout propriété Transporteur Physique => PHYSICAL_CARRIER_ID
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific SCAN event properties from DELIVERY
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE ins_EVT_DELIVERY ( p_evt IN EVT_DELIVERY_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_DELIVERY';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- ------------------------------------------------------------------------
   -- transform properties specific to DELIVERY event to a list of key-value format
   -- ------------------------------------------------------------------------
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_DAMAGED_PARCEL => p_evt.Q_DAMAGED_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_OPENNED_PARCEL => p_evt.Q_OPEN_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CAB2DKEY => p_evt.CAB2DKEY));         -- 2016.03.21 projet [10302]
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CAB2DSTATUS => p_evt.CAB2DSTATUS));   -- 2016.03.21 projet [10302]
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_PHYSICAL_CARRIER_ID => p_evt.PHYSICAL_CARRIER_ID));   -- 2016.11.02 projet [10472]

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------

   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FIRM_PARCEL_ID:'|| p_evt.FIRM_PARCEL_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_DELIVERY;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : See procedure with the same name
-- ---------------------------------------------------------------------------
FUNCTION  ins_EVT_DELIVERY ( p_evt IN EVT_DELIVERY_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_DELIVERY';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_DELIVERY ( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_DELIVERY;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of type PREPARATION
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific PREARATION event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE ins_EVT_PREPARATION ( p_evt IN EVT_PREPARATION_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_PREPARATION';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- ------------------------------------------------------------------------
   -- transform properties specific to PREPARATION event to a list of key-value format
   -- ------------------------------------------------------------------------
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------

   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FIRM_PARCEL_ID:'|| p_evt.FIRM_PARCEL_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_PREPARATION;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : See procedure with the same name
-- ---------------------------------------------------------------------------
FUNCTION  ins_EVT_PREPARATION ( p_evt IN EVT_PREPARATION_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_PREPARATION';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_PREPARATION ( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_PREPARATION;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of type COLLECTION
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- ---------------------------------------------------------------------------
--  V01.001 | 2016.11.07 | Hocine HAMMOU
--          | projet [10472] Ajout propriété Transporteur Physique => PHYSICAL_CARRIER_ID
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific COLLECTION event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE ins_EVT_COLLECTION ( p_evt IN EVT_COLLECTION_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_COLLECTION';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- ------------------------------------------------------------------------
   -- transform properties specific to COLLECTION event to a list of key-value format
   -- ------------------------------------------------------------------------
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_SIGN_DATA => p_evt.SIGN_DATA, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_DAMAGED_PARCEL => p_evt.Q_DAMAGED_PARCEL)); -- 2016.02.03 [10163] RM1 LOT2 INDE
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_OPENNED_PARCEL => p_evt.Q_OPEN_PARCEL)); -- 2016.02.03 [10163] RM1 LOT2 INDE
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CAB2DKEY => p_evt.CAB2DKEY));         -- 2016.03.21 projet [10302]
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CAB2DSTATUS => p_evt.CAB2DSTATUS));   -- 2016.03.21 projet [10302]
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_PHYSICAL_CARRIER_ID => p_evt.PHYSICAL_CARRIER_ID));   -- 2016.11.07 projet [10472]

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FIRM_PARCEL_ID:'|| p_evt.FIRM_PARCEL_ID || '-FILE_ID:' || p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_COLLECTION;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : See procedure with the same name
-- ---------------------------------------------------------------------------
FUNCTION  ins_EVT_COLLECTION ( p_evt IN EVT_COLLECTION_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_COLLECTION';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_COLLECTION ( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_COLLECTION;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : Web API to insert an event of type DROPOFF
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific DROPOFF event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE ins_EVT_DROPOFF ( p_evt IN EVT_DROPOFF_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_DROPOFF';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- CONTROLE DU CHAMP CONSIGNMENT_TYPE
   l_requiredparams := p_evt.MissingMandAttrs_ConsignType(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- CONTROLE DU CHAMP CHECKLIST_MANDATORY
   l_requiredparams := p_evt.MissingMandAttrs_CheckList(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- CONTROLE DES CHAMPS SWAP_MANDATORY
   l_requiredparams := p_evt.MissingMandAttrs_SWAP(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- CONTROLE DES CHAMPS CAB2D
   l_requiredparams := p_evt.MissingMandAttrs_CAB2D(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- ------------------------------------------------------------------------
   -- transform properties specific to DROPOFF event to a list of key-value format
   -- ------------------------------------------------------------------------
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_DAMAGED_PARCEL => p_evt.Q_DAMAGED_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_OPENNED_PARCEL => p_evt.Q_OPEN_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_FIRM_PARCEL_OTHER => p_evt.FIRM_PARCEL_OTHER, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CHECKLIST => p_evt.CHECKLIST, p_relevant_properties => l_relevant_properties));

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_RECEIPT_NUMBER => p_evt.RECEIPT_NUMBER)); -- 2016.08.19 [10330] -- (alias le TRACKING NUMBER)
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_PHONE_NUMBER => p_evt.PHONE_NUMBER)); -- 2016.08.19 [10330]
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_SIGN_DATA => p_evt.SIGN_DATA, p_relevant_properties => l_relevant_properties)); -- 2016.08.29 [10330]
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_SWAP => p_evt.SWAP)); -- 2016.11.25 [10472]
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_DELIVERY_FIRM_PARCEL => p_evt.DELIVERY_FIRM_PARCEL_ID, p_relevant_properties => l_relevant_properties)); -- 2016.11.25 [10472]
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_ASSOCIATED_CAB2D => p_evt.ASSOCIATED_CAB2D, p_relevant_properties => l_relevant_properties)); -- 2016.11.25 [10472]

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FIRM_PARCEL_ID:'|| p_evt.FIRM_PARCEL_ID || '-FILE_ID:' || p_FILE_ID || '- FIRM_PARCEL_OTHER : ' || NVL(p_evt.FIRM_PARCEL_OTHER,'N/C') ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_DROPOFF;

-- ---------------------------------------------------------------------------
-- DESCRIPTION : See procedure with the same name
FUNCTION  ins_EVT_DROPOFF ( p_evt IN EVT_DROPOFF_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_DROPOFF';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_DROPOFF ( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_DROPOFF;


-- ---------------------------------------------------------------------------
-- 2016.03.21 projet [10302]
-- DESCRIPTION : Web API to insert an event of type SCAN
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- ---------------------------------------------------------------------------
--  V01.001 | 2016.11.07 | Hocine HAMMOU
--          | projet [10472] Ajout propriété Transporteur Physique => PHYSICAL_CARRIER_ID
-- -------------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific SCAN event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- -------------------------------------------------------------------------------

PROCEDURE ins_EVT_SCAN_COLLECTION ( p_evt IN EVT_SCAN_COLLECTION_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_SCAN_COLLECTION';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;


   -- ------------------------------------------------------------------------
   -- transform properties specific to SCAN event to a list of key-value format
   -- ------------------------------------------------------------------------

   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_SIGN_DATA => p_evt.SIGN_DATA, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_DAMAGED_PARCEL => p_evt.Q_DAMAGED_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_OPENNED_PARCEL => p_evt.Q_OPEN_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CAB2DKEY => p_evt.CAB2DKEY));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CAB2DSTATUS => p_evt.CAB2DSTATUS));
   --addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_PHYSICAL_CARRIER_ID => p_evt.PHYSICAL_CARRIER_ID));   -- 2016.11.07 projet [10472]
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_FORM => p_evt.FORM, p_relevant_properties => l_relevant_properties));

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FILE_ID:' || p_FILE_ID || '-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_SCAN_COLLECTION;

-- ---------------------------------------------------------------------------
-- 2016.03.21 projet [10302]
-- DESCRIPTION : See procedure with the same name
-- ---------------------------------------------------------------------------
FUNCTION  ins_EVT_SCAN_COLLECTION ( p_evt IN EVT_SCAN_COLLECTION_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_SCAN_COLLECTION';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_SCAN_COLLECTION ( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_SCAN_COLLECTION;


-- ---------------------------------------------------------------------------
-- 2016.08.17 projet [10330]
-- DESCRIPTION : Web API to insert an event of type INVENTORY
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- -------------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific INVENTORY event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- -------------------------------------------------------------------------------

PROCEDURE ins_EVT_INVENTORY ( p_evt IN EVT_INVENTORY_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_INVENTORY';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);

   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- transform properties specific to SCAN event to a list of key-value format
   -- ------------------------------------------------------------------------
   -- Si ancien Inventaire Colis : INVENTORY alors pas de propriété
   -- Si nouvel Inventaire Colis : PARCEL_INVENTORY alors ajout de propriétés
   if l_evt_type = PCK_API_CONSTANTS.c_evt_type_PARCEL_INVENTORY THEN
      addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));                       -- 2016.12.26
      addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_INVENTORY_STATE => p_evt.INVENTORY_STATE, p_relevant_properties => l_relevant_properties));       -- 2016.12.26
      addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_INVENTORY_SESSION => to_char(p_evt.INVENTORY_SESSION,'YYYY-MM-DD"T"hh24:mi:ss'), p_relevant_properties => l_relevant_properties));   -- 2016.12.26
      addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_INVENTORY_ORIGIN => p_evt.INVENTORY_ORIGIN, p_relevant_properties => l_relevant_properties));     -- 2016.12.26
      addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_INVENTORY_USE_CASE => p_evt.INVENTORY_USE_CASE, p_relevant_properties => l_relevant_properties)); -- 2016.12.26
   end if;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FILE_ID:' || p_FILE_ID || '-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_INVENTORY;

-- ---------------------------------------------------------------------------
-- 2016.08.17 projet [10330]
-- DESCRIPTION : See procedure with the same name
-- ---------------------------------------------------------------------------
FUNCTION  ins_EVT_INVENTORY ( p_evt IN EVT_INVENTORY_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_INVENTORY';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_INVENTORY ( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_INVENTORY;


-- ---------------------------------------------------------------------------
-- 2016.08.22 projet [10330]
-- DESCRIPTION : Web API to insert an event of type SCAN
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- -------------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific SCAN event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- -------------------------------------------------------------------------------

PROCEDURE ins_EVT_SCAN_DROPOFF ( p_evt IN EVT_SCAN_DROPOFF_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_SCAN_DROPOFF';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;


   -- ------------------------------------------------------------------------
   -- transform properties specific to SCAN event to a list of key-value format
   -- ------------------------------------------------------------------------
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_DAMAGED_PARCEL => p_evt.Q_DAMAGED_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_OPENNED_PARCEL => p_evt.Q_OPEN_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_FIRM_PARCEL_OTHER => p_evt.FIRM_PARCEL_OTHER, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CHECKLIST => p_evt.CHECKLIST, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_RECEIPT_NUMBER => p_evt.RECEIPT_NUMBER));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_PHONE_NUMBER => p_evt.PHONE_NUMBER));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_SIGN_DATA => p_evt.SIGN_DATA, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_FORM => p_evt.FORM, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_REASON => p_evt.REASON, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_ASSOCIATED_CAB2D => p_evt.ASSOCIATED_CAB2D, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_ABANDONED => p_evt.ABANDONED));

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------

   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FILE_ID:' || p_FILE_ID || '-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_SCAN_DROPOFF;

-- ---------------------------------------------------------------------------
-- 2016.08.22 projet [10330]
-- DESCRIPTION : See procedure with the same name
-- ---------------------------------------------------------------------------
FUNCTION  ins_EVT_SCAN_DROPOFF ( p_evt IN EVT_SCAN_DROPOFF_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_SCAN_DROPOFF';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_SCAN_DROPOFF ( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_SCAN_DROPOFF;


-- ---------------------------------------------------------------------------
-- 2016.09.09 projet [10330]
-- DESCRIPTION : Web API to insert an event of type SCAN of DELIVERY
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- ---------------------------------------------------------------------------
--  V01.001 | 2016.11.07 | Hocine HAMMOU
--          | projet [10472] Ajout propriété Transporteur Physique => PHYSICAL_CARRIER_ID
-- -------------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific SCAN event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- -------------------------------------------------------------------------------

PROCEDURE ins_EVT_SCAN_DELIVERY ( p_evt IN EVT_SCAN_DELIVERY_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_SCAN_DELIVERY';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;


   -- ------------------------------------------------------------------------
   -- transform properties specific to SCAN event to a list of key-value format
   -- ------------------------------------------------------------------------
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_DAMAGED_PARCEL => p_evt.Q_DAMAGED_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_OPENNED_PARCEL => p_evt.Q_OPEN_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CAB2DKEY => p_evt.CAB2DKEY));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CAB2DSTATUS => p_evt.CAB2DSTATUS));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_PHYSICAL_CARRIER_ID => p_evt.PHYSICAL_CARRIER_ID));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_FORM => p_evt.FORM, p_relevant_properties => l_relevant_properties));

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------

   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FILE_ID:' || p_FILE_ID || '-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_SCAN_DELIVERY;

-- ---------------------------------------------------------------------------
-- 2016.09.09 projet [10330]
-- DESCRIPTION : See procedure with the same name
-- ---------------------------------------------------------------------------
FUNCTION  ins_EVT_SCAN_DELIVERY ( p_evt IN EVT_SCAN_DELIVERY_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_SCAN_DELIVERY';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_SCAN_DELIVERY ( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_SCAN_DELIVERY;


-- ---------------------------------------------------------------------------
-- 2016.09.09 projet [10330]
-- DESCRIPTION : Web API to insert an event of type SCAN of PICKUP
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- -------------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific SCAN event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- -------------------------------------------------------------------------------

PROCEDURE ins_EVT_SCAN_PICKUP ( p_evt IN EVT_SCAN_PICKUP_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_SCAN_PICKUP';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;


   -- ------------------------------------------------------------------------
   -- transform properties specific to SCAN event to a list of key-value format
   -- ------------------------------------------------------------------------
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_DURATION => p_evt.DURATION, p_relevant_properties => l_relevant_properties ));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_DAMAGED_PARCEL => p_evt.Q_DAMAGED_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_Q_OPENNED_PARCEL => p_evt.Q_OPEN_PARCEL));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_SIGN_DATA => p_evt.SIGN_DATA, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_CDC_CODE => p_evt.CDC_CODE, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_NAME_OF_RECIPIENT => p_evt.NAME_OF_RECIPIENT, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_IDENTITY_VERIFICATION => p_evt.IDENTITY_VERIFICATION, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_ID_RECORD => p_evt.ID_RECORD, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_COD_AMOUNT_PAID => p_evt.COD_AMOUNT_PAID, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_COD_CURRENCY => p_evt.COD_CURRENCY, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_COD_MEANS_PAYMENT_ID => p_evt.COD_MEANS_PAYMENT_ID, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_RECEIVER_TYPE => p_evt.RECEIVER_TYPE, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_REASON => p_evt.REASON, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_IDENTITY_VERIFICATION_2 => p_evt.IDENTITY_VERIFICATION_2, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_SWAP => p_evt.SWAP)); -- 2016.11.25 [10472]
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_RETURN_FIRM_PARCEL => p_evt.RETURN_FIRM_PARCEL_ID, p_relevant_properties => l_relevant_properties)); -- 2016.11.25 [10472]
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_FORM => p_evt.FORM, p_relevant_properties => l_relevant_properties));

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FILE_ID:' || p_FILE_ID || '-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_SCAN_PICKUP;

-- ---------------------------------------------------------------------------
-- 2016.09.09 projet [10330]
-- DESCRIPTION : See procedure with the same name
-- ---------------------------------------------------------------------------
FUNCTION  ins_EVT_SCAN_PICKUP ( p_evt IN EVT_SCAN_PICKUP_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_SCAN_PICKUP';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_SCAN_PICKUP ( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_SCAN_PICKUP;


-- ---------------------------------------------------------------------------
-- 2016.09.15 projet [10330]
-- DESCRIPTION : Web API to insert an event of type SCAN of COLLECTION_PREPARATION
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- -------------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific SCAN event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- -------------------------------------------------------------------------------

PROCEDURE ins_EVT_SCAN_PREPARATION ( p_evt IN EVT_SCAN_PREPARATION_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_SCAN_PREPARATION';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;


   -- ------------------------------------------------------------------------
   -- transform properties specific to SCAN event to a list of key-value format
   -- ------------------------------------------------------------------------
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_FORM => p_evt.FORM, p_relevant_properties => l_relevant_properties));

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FILE_ID:' || p_FILE_ID || '-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_SCAN_PREPARATION;

-- ---------------------------------------------------------------------------
-- 2016.09.15 projet [10330]
-- DESCRIPTION : See procedure with the same name
-- ---------------------------------------------------------------------------
FUNCTION  ins_EVT_SCAN_PREPARATION ( p_evt IN EVT_SCAN_PREPARATION_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_SCAN_PREPARATION';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_SCAN_PREPARATION ( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_SCAN_PREPARATION;

-- ---------------------------------------------------------------------------
-- 2017.01.10 projet [10472]
-- DESCRIPTION : Web API to insert an event of type NOT_FOUND
--               meant to receive a row by event that will include properties
--               then it will:
--                 · transform specific properties to a list of key-value format
--                 · call ins_EVT to continue the event treatment
-- -------------------------------------------------------------------------------
--  PARAMETER IN  : p_evt         --> information common to every event as well as specific SCAN event properties
--  PARAMETER OUT : p_FILE_ID     --> file_id from IMPORT_PDA.T_XMLFILES.FILE_ID
-- -------------------------------------------------------------------------------

PROCEDURE ins_EVT_NOT_FOUND ( p_evt IN EVT_NOT_FOUND_TYPE, p_FILE_ID OUT INTEGER)
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_NOT_FOUND';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_evt_type  CONFIG.EVENT_TYPE.EVENT_TYPE_NAME%TYPE;
   l_prop_list evt_prop_tab_type;
   l_requiredparams  VARCHAR2(4000);
   l_relevant_properties varchar2(4000);
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   l_requiredparams := p_evt.MissingMandatoryAttributes(p_relevant_properties => l_relevant_properties);
   IF TRIM(l_requiredparams) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || l_requiredparams);
   END IF;

   -- ------------------------------------------------------------------------
   -- transform properties specific to SCAN event to a list of key-value format
   -- ------------------------------------------------------------------------
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_BARCODE => p_evt.BARCODE, p_relevant_properties => l_relevant_properties));
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_INVENTORY_STATE => p_evt.INVENTORY_STATE, p_relevant_properties => l_relevant_properties));       -- 2016.12.26
   addKeyValue(p_list => l_prop_list, p_prop => KeyValuePair(p_INVENTORY_SESSION => to_char(p_evt.INVENTORY_SESSION,'YYYY-MM-DD"T"hh24:mi:ss'), p_relevant_properties => l_relevant_properties));   -- 2016.12.26

   -- ------------------------------------------------------------------------
   -- quel type d'évnement suis-je ?
   -- ------------------------------------------------------------------------
   l_evt_type := p_evt.TargetEventType;

   -- ------------------------------------------------------------------------
   -- call ins_EVT to continue the event treatment
   -- ------------------------------------------------------------------------
   p_FILE_ID:= ins_EVT
      ( p_evt_type   => l_evt_type
      , p_event_id   => c_EVENT_ID
      , p_evt        => p_evt
      , p_properties => l_prop_list
      );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] ' || l_evt_type ||' EVENT PROCESSED (FILE_ID:' || p_FILE_ID || '-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_NOT_FOUND;


-- ---------------------------------------------------------------------------
-- 2017.01.10 projet [10472]
-- DESCRIPTION : See procedure with the same name
-- ---------------------------------------------------------------------------
FUNCTION  ins_EVT_NOT_FOUND ( p_evt IN EVT_NOT_FOUND_TYPE) RETURN INTEGER
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ins_EVT_NOT_FOUND';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_FILE_ID INTEGER;
BEGIN
   ins_EVT_NOT_FOUND ( p_evt => p_evt, p_FILE_ID => l_FILE_ID );
   return l_FILE_ID;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END ins_EVT_NOT_FOUND;


-- ---------------------------------------------------------------------------
-- DESCRIPTION : lance le traitement de l'event
--               de façon proche à comme le ferait le process_all
--               en asynchron (en background)
-- ---------------------------------------------------------------------------
--  PARAMETER IN  : p_FILE_ID     --> IMPORT_PDA.T_XMLFILES.FILE_ID
-- ---------------------------------------------------------------------------
PROCEDURE process_xmlfile_event( p_FILE_ID IN INTEGER )
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'process_xmlfile_event';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
BEGIN
   -- CONTROLE DES CHAMPS OBLIGATOIRES EN ENTREE
   IF p_FILE_ID IS NULL THEN
      RAISE_APPLICATION_ERROR (PCK_API_CONSTANTS.errnum_requiredparam,'[API_CORE] '||PCK_API_CONSTANTS.errmsg_requiredparam || p_FILE_ID);
   END IF;

   IMPORT_PDA.PROCESS_XMLFILE_STEP2 ( p_xmlfile_id  => p_FILE_ID , p_action => c_JOB_ACTION );

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE]  JOB LAUNCHED (FILE_ID:'||  p_FILE_ID ||'-ELAPSED TIME:' || api_core.PCK_API_TOOLS.f_elapsed_miliseconds(l_start_date,systimestamp ) || 'ms).' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace );
      RAISE;
END process_xmlfile_event;


END PCK_EVENT;

/