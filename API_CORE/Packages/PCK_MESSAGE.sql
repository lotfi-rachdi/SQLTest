CREATE OR REPLACE PACKAGE api_core.PCK_MESSAGE
-- ***************************************************************************
--  PACKAGE     : PCK_MESSAGE
--  DESCRIPTION : Package to deal with Message coming from BO
--
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.12.02 | Hocine HAMMOU
--          | Init
--          |
-- ***************************************************************************
IS
c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_MESSAGE';

PROCEDURE GetSiteMessages(p_international_site_id IN VARCHAR2, p_tab_message OUT NOCOPY api_core.TAB_MESSAGE_TYPE );

FUNCTION  GetSiteMessages(p_international_site_id IN VARCHAR2) RETURN api_core.TAB_MESSAGE_TYPE;

PROCEDURE SetSiteMessageRead(p_message IN OUT NOCOPY api_core.MESSAGE_TYPE );

END PCK_MESSAGE;

/