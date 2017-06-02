CREATE OR REPLACE PACKAGE api_core.PCK_EVENT is
-- ***************************************************************************
--  PACKAGE     : PCK_EVENT
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
--          |
--  V01.200 | 2015.06.29 | Maria CASALS
--          | Ajout de la procédure et fonction traitant l'évcnement REFUSE
--          |
--  V01.210 | 2015.07.20 | Maria CASALS
--          | Suppression de la procédure et fonction traitant l'évcnement REFUSE
--          | Ajout de la procédure et fonction traitant l'évcnement PREPARATION
--          |
--  V01.220 | 2015.07.28 | Amadou YOUNSAH
--          | Creation de la procédure traitant les collections
--          |
--  V01.230 | 2015.07.31 | Amadou YOUNSAH
--          | Creation de la procédure traitant les dropoff
--          |
--  V01.240 | 2015.10.20 | Hocine HAMMOU
--          | Creation de la procédure process_xmlfile
--          |
--  V01.241 | 2016.04.11 | Hocine HAMMOU
--          | Projet RM2 [10302] Transfert de responsabilité :
--          | Ajout signatures ins_EVT_SCAN_COLLECTION
--          |
--  V01.242 | 2016.08.17 | Hocine HAMMOU
--          | projet RM3 [10330] Application Hybride Android V3
--          | Ajout gestion de l'event INVENTORY
--          |
--  V01.243 | 2016.08.22 | Hocine HAMMOU
--          | projet RM3 [10330] Application Hybride Android V3
--          | Ajout gestion de l'event SCAN pour le DROPOFF
--          |
--  V01.243 | 2016.09.09 | Hocine HAMMOU
--          | projet RM3 [10330] Application Hybride Android V3
--          | Ajout gestion de l'event SCAN pour le DELIVERY et PICKUP
--          |
--  V01.244 | 2016.09.15 | Hocine HAMMOU
--          | projet RM3 [10330] Application Hybride Android V3
--          | Ajout gestion de l'event SCAN pour le COLLECTION_PREPARATION ( colis a collecter suite a préparation)
--          |
-- ***************************************************************************

c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_EVENT';
-- 2015.06.24 p_USER_LOGIN disparait --
PROCEDURE ins_EVT_PICKUP( p_evt IN EVT_PICKUP_TYPE, p_FILE_ID OUT INTEGER)
;
FUNCTION  ins_EVT_PICKUP( p_evt IN EVT_PICKUP_TYPE) RETURN INTEGER -- returns  p_FILE_ID
;

PROCEDURE ins_EVT_DELIVERY ( p_evt IN EVT_DELIVERY_TYPE, p_FILE_ID OUT INTEGER)
;
FUNCTION  ins_EVT_DELIVERY ( p_evt IN EVT_DELIVERY_TYPE) RETURN INTEGER -- returns  p_FILE_ID
;

PROCEDURE ins_EVT_PREPARATION ( p_evt IN EVT_PREPARATION_TYPE, p_FILE_ID OUT INTEGER)
;
FUNCTION  ins_EVT_PREPARATION ( p_evt IN EVT_PREPARATION_TYPE) RETURN INTEGER
;

PROCEDURE ins_EVT_COLLECTION ( p_evt IN EVT_COLLECTION_TYPE, p_FILE_ID OUT INTEGER)
;
FUNCTION  ins_EVT_COLLECTION ( p_evt IN EVT_COLLECTION_TYPE) RETURN INTEGER
;
PROCEDURE ins_EVT_DROPOFF ( p_evt IN EVT_DROPOFF_TYPE, p_FILE_ID OUT INTEGER)
;
FUNCTION  ins_EVT_DROPOFF ( p_evt IN EVT_DROPOFF_TYPE) RETURN INTEGER
;

PROCEDURE process_xmlfile_event ( p_FILE_ID IN INTEGER )
;

PROCEDURE ins_EVT_SCAN_COLLECTION ( p_evt IN EVT_SCAN_COLLECTION_TYPE, p_FILE_ID OUT INTEGER) -- 2016.04.11 Projet RM2 [10302] Transfert de responsabilité
;
FUNCTION  ins_EVT_SCAN_COLLECTION ( p_evt IN EVT_SCAN_COLLECTION_TYPE) RETURN INTEGER -- 2016.04.11 Projet RM2 [10302] Transfert de responsabilité
;

PROCEDURE ins_EVT_INVENTORY ( p_evt IN EVT_INVENTORY_TYPE, p_FILE_ID OUT INTEGER) --2016.08.17 projet RM3 [10330]
;
FUNCTION  ins_EVT_INVENTORY ( p_evt IN EVT_INVENTORY_TYPE) RETURN INTEGER --2016.08.17 projet RM3 [10330]
;

PROCEDURE ins_EVT_SCAN_DROPOFF ( p_evt IN EVT_SCAN_DROPOFF_TYPE, p_FILE_ID OUT INTEGER) -- 2016.08.22 projet RM3 [10330]
;
FUNCTION  ins_EVT_SCAN_DROPOFF ( p_evt IN EVT_SCAN_DROPOFF_TYPE) RETURN INTEGER -- 2016.08.22 projet RM3 [10330]
;

PROCEDURE ins_EVT_SCAN_DELIVERY ( p_evt IN EVT_SCAN_DELIVERY_TYPE, p_FILE_ID OUT INTEGER) -- 2016.09.09 projet RM3 [10330]
;
FUNCTION  ins_EVT_SCAN_DELIVERY ( p_evt IN EVT_SCAN_DELIVERY_TYPE) RETURN INTEGER -- 2016.09.09 projet RM3 [10330]
;

PROCEDURE ins_EVT_SCAN_PICKUP ( p_evt IN EVT_SCAN_PICKUP_TYPE, p_FILE_ID OUT INTEGER) -- 2016.09.09 projet RM3 [10330]
;
FUNCTION  ins_EVT_SCAN_PICKUP ( p_evt IN EVT_SCAN_PICKUP_TYPE) RETURN INTEGER -- 2016.09.09 projet RM3 [10330]
;

PROCEDURE ins_EVT_SCAN_PREPARATION ( p_evt IN EVT_SCAN_PREPARATION_TYPE, p_FILE_ID OUT INTEGER) -- 2016.09.09 projet RM3 [10330]
;
FUNCTION  ins_EVT_SCAN_PREPARATION ( p_evt IN EVT_SCAN_PREPARATION_TYPE) RETURN INTEGER -- 2016.09.09 projet RM3 [10330]
;

PROCEDURE ins_EVT_NOT_FOUND ( p_evt IN EVT_NOT_FOUND_TYPE, p_FILE_ID OUT INTEGER) -- 2017.01.10 projet [10472]
;
FUNCTION  ins_EVT_NOT_FOUND ( p_evt IN EVT_NOT_FOUND_TYPE) RETURN INTEGER -- 2017.01.10 projet [10472]
;

END PCK_EVENT;

/