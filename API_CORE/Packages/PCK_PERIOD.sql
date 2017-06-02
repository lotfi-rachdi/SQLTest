CREATE OR REPLACE PACKAGE api_core.PCK_PERIOD
-- ***************************************************************************
--  PACKAGE     : PCK_PERIOD
--  DESCRIPTION : Package to deal with Period coming from web API
--                inspired from and reusing how XML files of types
--                T_PERIOD coming from PDAs are uploaded
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.11.20 | Hocine HAMMOU
--          | Init
--          |
--  V01.001 | 2016.11.09 | Hocine HAMMOU
--          | Ajout dans la spec. de la signature de la fonction GetSitePeriods
--          |
-- ***************************************************************************
is
c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_PERIOD';

PROCEDURE ins_PERIOD( p_period IN api_core.PERIOD_TYPE, p_FILE_ID OUT INTEGER);

PROCEDURE del_PERIOD( p_period IN api_core.PERIOD_TYPE, p_FILE_ID OUT INTEGER);

PROCEDURE upd_PERIOD( p_period IN api_core.PERIOD_TYPE, p_FILE_ID OUT INTEGER);

PROCEDURE GetSitePeriods( p_INTERNATIONAL_SITE_ID IN VARCHAR2, p_START_DATE_RANGE IN OUT DATE, p_END_DATE_RANGE IN OUT DATE, p_period_tab OUT api_core.TAB_PERIOD_TYPE);

FUNCTION GetSitePeriods(p_international_site_id MASTER.SITE.SITE_INTERNATIONAL_ID%TYPE, p_site_id MASTER.PERIOD.SITE_ID%TYPE, p_date_start DATE, p_date_end DATE, p_type_period MASTER.PERIOD.PERIOD_TYPE_ID%TYPE) RETURN api_core.TAB_PERIOD_TYPE ;

PROCEDURE process_xmlfile_period ( p_FILE_ID IN INTEGER );

END PCK_PERIOD;

/