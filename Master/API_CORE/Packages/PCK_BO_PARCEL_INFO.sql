CREATE OR REPLACE PACKAGE api_core.PCK_BO_PARCEL_INFO
-- ***************************************************************************
--  PACKAGE     : API_CORE.PCK_BO_PARCEL_INFO
--  DESCRIPTION : Création des procédures utilisés par les WEB API pour
--                traiter l'évènement INFO COLIS.
--                En entrée la procédure reçoit un code barre colis et
--                en retour extrait les infos sur le colis
--                Rajouté pour Web API
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.06.11 | Hocine HAMMOU
--          | version initiale
--  V01.200 | 2015.06.26 | Maria CASALS
--          | rajout GetSiteParcels
--          |
--  V01.300 | 2015.07.10 | Hocine HAMMOU
--          | Ajout de la donnée INTERNATIONAL_SITE_ID en remplacement de SITE_ID
--          |
--  V01.301 | 2015.07.20 | Maria CASALS
--          | Rajout GetParcelsToPrepare
--          |
--  V01.457 | 2015.09.09 | Amadou YOUNSAH
--          | Renommage du type API_CORE.SITE_TAB_TYPE en API_CORE.TAB_SITE_TYPE
--          |
--  V01.500 | 2015.09.18 | Hocine HAMMOU
--          | Dans le cadre du découplage des Parcels et des Sites,
--          | création d'un package PCK_BO_SITE_INFO dédiés aux SITES
--          |
--  V01.501 | 2016.08.29 | Hocine HAMMOU
--          | Ajout de la fonction GetSiteParcelsCore qui appelle la procédure du même nom
--          |
-- ***************************************************************************
IS

FUNCTION CALCULATE_MAPPED_PARCEL_STATE(p_CURRENT_STEP_ID MASTER.PARCEL.CURRENT_STEP_ID%TYPE, p_CURRENT_PARCEL_STEPS_ID MASTER.PARCEL.CURRENT_PARCEL_STEPS_ID%TYPE, p_CURRENT_STEP_ISVALID MASTER.PARCEL.CURRENT_STEP_ISVALID%TYPE )
RETURN VARCHAR2;


-- 2015.07.10  PROCEDURE PARCEL_INFO(p_firm_parcel IN VARCHAR2, p_parcel_info_type OUT NOCOPY PARCEL_INFO_TYPE, p_SITE_ID IN INTEGER );
PROCEDURE PARCEL_INFO(p_firm_parcel IN VARCHAR2, p_parcel_info_type OUT NOCOPY PARCEL_INFO_TYPE, p_INTERNATIONAL_SITE_ID IN VARCHAR2 );

-- 2015.07.10  PROCEDURE PARCEL_INFO(p_parcel_info_type IN OUT NOCOPY PARCEL_INFO_TYPE, p_SITE_ID IN INTEGER );
PROCEDURE PARCEL_INFO(p_parcel_info_type IN OUT NOCOPY PARCEL_INFO_TYPE, p_INTERNATIONAL_SITE_ID IN VARCHAR2 );

FUNCTION  PARCEL_INFO( p_firm_parcel in VARCHAR2 , P_INTERNATIONAL_SITE_ID IN VARCHAR2 ) RETURN PARCEL_INFO_TYPE ;

-- 17.02.2016 FONCTION DEPLACEE DANS API_CORE.PCK_API_TOOLS
-- FUNCTION convert_timeZONE ( p_TIMESTWITHZONE in TIMESTAMP WITH TIME ZONE, p_tz IN VARCHAR2) return DATE ;
-- pour contourner le bug, comme http://www.dbforums.com/showthread.php?1628036-timezone-variable-in-PL-SQL

-- 2015.07.10  PROCEDURE GetSiteParcels(p_SITE_ID IN INTEGER, p_querytype IN INTEGER, p_NAME IN VARCHAR2 DEFAULT NULL, p_site_parcels OUT NOCOPY  TAB_PARCEL_SRCH_TYPE );
PROCEDURE GetSiteParcels(p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_querytype IN INTEGER, p_NAME IN VARCHAR2 DEFAULT NULL, p_site_parcels OUT NOCOPY  TAB_PARCEL_INFO_TYPE );

-- 2015.07.10  FUNCTION  GetSiteParcels(p_SITE_ID IN INTEGER, p_querytype IN INTEGER, p_NAME IN VARCHAR2 DEFAULT NULL) RETURN TAB_PARCEL_SRCH_TYPE;
FUNCTION  GetSiteParcels(p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_querytype IN INTEGER, p_NAME IN VARCHAR2 DEFAULT NULL) RETURN TAB_PARCEL_INFO_TYPE;

PROCEDURE GetParcelsToPrepare(p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_site_parcels OUT NOCOPY  TAB_PARCEL_PREPARATION_TYPE );

FUNCTION  GetParcelsToPrepare(p_INTERNATIONAL_SITE_ID IN VARCHAR2 ) RETURN TAB_PARCEL_PREPARATION_TYPE;

PROCEDURE GetSiteParcelsCore(p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_querytype IN INTEGER, p_NAME IN VARCHAR2  DEFAULT NULL, p_site_parcels OUT NOCOPY  api_core.TAB_PARCEL_INFO_TYPE, p_site_ID IN MASTER.SITE.SITE_ID%TYPE , p_timezone IN MASTER.SITE.TIMEZONE%TYPE );

FUNCTION GetSiteParcelsCore(p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_querytype IN INTEGER, p_NAME IN VARCHAR2  DEFAULT NULL, p_site_ID IN MASTER.SITE.SITE_ID%TYPE , p_timezone IN MASTER.SITE.TIMEZONE%TYPE ) RETURN api_core.TAB_PARCEL_INFO_TYPE;

FUNCTION GetPaymentSummary(p_INTERNATIONAL_SITE_ID IN MASTER.SITE.SITE_INTERNATIONAL_ID%TYPE, p_PARCEL_ID IN MASTER.PARCEL.PARCEL_ID%TYPE) RETURN api_core.PAYMENT_SUMMARY_TYPE;

END PCK_BO_PARCEL_INFO;

/