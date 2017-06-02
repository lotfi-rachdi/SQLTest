CREATE OR REPLACE PACKAGE api_core.PCK_BO_SITE_INFO
-- ***************************************************************************
--  PACKAGE     : API_CORE.PCK_BO_SITE_INFO
--  DESCRIPTION : Création des procédures utilisés par les WEB API pour
--                traiter les SITES.
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
--  V01.501 | 2016.04.05 | Hocine HAMMOU
--          | RM2 [10302]
--          | Ajout de la procédure GetSiteRules qui envoie au mobiles les infos
--          | sur les prestations du Pudo
--          |
--  V01.502 | 2016.06.21 | Hocine HAMMOU
--          | Ajout de la fonction GetSiteRules
--          |
--  V01.503 | 2017.02.06 | Hocine HAMMOU
--          | Projet [10350] Ajout de la procédure GetAllSites
--          |
--  V01.504 | 2017.03.06 | Hocine HAMMOU
--          | Projet [10350] : Ajout de la procédure GetSitesByCountry
--          |
--  V01.505 | 2017.05.15 | Maria Casals
--          | Projets 10128/10161 - Gestion des interactions et campagnes d'appels / CRM Lot 1
--          | => ajout des fonctions IS_IN_CRM, GetSiteid
-- ***************************************************************************
IS

PROCEDURE GetActiveSites(p_country_code IN VARCHAR2, p_site_tab OUT NOCOPY api_core.TAB_SITE_TYPE );

FUNCTION  GetActiveSites(p_country_code IN VARCHAR2) RETURN api_core.TAB_SITE_TYPE;

PROCEDURE GetSiteRules(p_international_site_id IN VARCHAR2, p_SITE_RULES_TYPE OUT NOCOPY api_core.TAB_SITE_RULES_TYPE );

FUNCTION  GetSiteRules(p_international_site_id IN VARCHAR2) RETURN api_core.TAB_SITE_RULES_TYPE;

PROCEDURE GetAllSites(p_site_tab OUT NOCOPY api_core.TAB_SITE_TYPE );

FUNCTION  GetAllSites RETURN api_core.TAB_SITE_TYPE;

PROCEDURE GetSitesByCountry(p_country_code_tab IN api_core.TAB_ELEMENT_VARCHAR_TYPE, p_site_tab OUT NOCOPY api_core.TAB_SITE_TYPE );

FUNCTION IS_IN_CRM(p_SITE_ID IN NUMBER) RETURN NUMBER;

FUNCTION IS_IN_CRM(p_SITE_INTERNATIONAL_ID IN VARCHAR2) RETURN NUMBER;

FUNCTION GetSiteid(p_pdaid IN CONFIG.PDA.PDA_ID%TYPE, p_date IN DATE DEFAULT SYSDATE) RETURN VARCHAR2;

END PCK_BO_SITE_INFO;

/