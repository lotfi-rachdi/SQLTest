CREATE OR REPLACE PACKAGE api_core.PCK_OPENING_HOURS
-- ***************************************************************************
--  PACKAGE     : PCK_OPENING_HOURS
--  DESCRIPTION : Package to deal with Period coming from web API
--                inspired from and reusing how XML files of types
--                T_OPENING_HOURS coming from PDAs are uploaded
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.11.24 | Hocine HAMMOU
--          | Init
--          |
-- ***************************************************************************
is
c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_OPENING_HOURS';

PROCEDURE SetSiteOpeningHours( p_opening_hours IN api_core.OPENING_HOURS_TYPE, p_FILE_ID OUT INTEGER);

PROCEDURE GetSiteOpeningHours( p_opening_hours IN OUT NOCOPY api_core.OPENING_HOURS_TYPE);

FUNCTION  GetSiteOpeningHours(p_international_site_id IN VARCHAR2) RETURN api_core.OPENING_HOURS_TYPE;

PROCEDURE process_xmlfile_openinghours( p_FILE_ID IN INTEGER );

END PCK_OPENING_HOURS;

/