CREATE OR REPLACE PACKAGE api_core.PCK_API_TOOLS
-- ***************************************************************************
--  PACKAGE     : API_CORE.PCK_API_TOOLS
--  DESCRIPTION : Package à très bas niveau avec des fonctions simples
--                Il ne peut appeller que PCK_API_CONSTANTS
--                Il ne peut faire référence aux TYPES parce que justement
--                les types vont s'en servir
--
--                En principe à ne pas être accédé en dehors du schema API_CORE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.17 | Maria CASALS
--          | version initiale
--  V01.100 | 2015.09.18 | Hocine HAMMOU
--          | Ajout de la fonction F_ELAPSED_MILISECONDS qui permet de calculer
--          | la durée écoulée dans un traitement
-- ***************************************************************************
IS
FUNCTION LIST (P_LIST IN VARCHAR, p_item IN VARCHAR2, P_SEP IN VARCHAR2 DEFAULT ',') RETURN VARCHAR;

FUNCTION ITEM_IN_LIST (P_LIST IN VARCHAR, p_item IN VARCHAR2, P_SEP IN VARCHAR2 DEFAULT ',') RETURN BOOLEAN;

FUNCTION f_elapsed_miliseconds ( p_timeSTAMP_before IN TIMESTAMP, p_timeSTAMP_after  IN TIMESTAMP) RETURN FLOAT;
PRAGMA RESTRICT_REFERENCES (f_elapsed_miliseconds, WNDS);

FUNCTION convert_timeZONE ( p_TIMESTWITHZONE in TIMESTAMP WITH TIME ZONE, p_tz IN VARCHAR2) RETURN DATE;

END PCK_API_TOOLS;

/