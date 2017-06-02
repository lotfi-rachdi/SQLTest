CREATE OR REPLACE TYPE api_core."SITE_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.SITE_TYPE
--  DESCRIPTION : Identifiants du SITE pour la sécurité du WEB API
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.06.17 | Hocine HAMMOU
--          | Init
--          |
--  V01.100 | 2015.07.10 | Hocine HAMMOU
--          | Suppression de la donnée de SITE_ID
--          |
--  V01.101 | 2016.06.21 | Hocine HAMMOU
--          | Projet [10093] : Ajout de données supplémentaires : LANGUAGE_CODE, OPERATOR_ID
--          |
--  V01.102 | 2017.03.06 | Hocine HAMMOU
--          | Projet [10350] : Ajout de la donnée : STATE_ID
-- ***************************************************************************
( COUNTRY_CODE           VARCHAR2(3)    -- MASTER.SITE.COUNTRY_CODE%TYPE
, INTERNATIONAL_SITE_ID  VARCHAR2(35)   -- MASTER.SITE.SITE_INTERNATIONAL_ID%TYPE
, LANGUAGE_CODE          VARCHAR2(2)    -- MASTER.SITE.LANGUAGE_CODE%TYPE
, OPERATOR_ID            NUMBER(8,0)    -- MASTER.SITE.OPERATOR_ID%TYPE
, EMAIL                  VARCHAR2(250)  -- MASTER.SITE.EMAIL%TYPE
, STATE_ID               NUMBER(1)      -- MASTER.SITE.SITE_STATE_ID%TYPE
, CONSTRUCTOR FUNCTION SITE_TYPE(SELF IN OUT NOCOPY SITE_TYPE) RETURN SELF AS RESULT
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."SITE_TYPE" 
-- ***************************************************************************
--  TYPE        : API_CORE.SITE_TYPE
--  DESCRIPTION : Identifiants du SITE pour la sécurité du WEB API
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.06.17 | Hocine HAMMOU
--          | Init
--          |
--  V01.100 | 2015.07.10 | Hocine HAMMOU
--          | Suppression de la donnée de SITE_ID
--          |
--  V01.101 | 2016.06.21 | Hocine HAMMOU
--          | Projet [10093] : Ajout de données supplémentaires : LANGUAGE_CODE, OPERATOR_ID
--          |
--  V01.102 | 2017.03.06 | Hocine HAMMOU
--          | Projet [10350] : Ajout de la donnée : STATE_ID
-- ***************************************************************************
IS
  CONSTRUCTOR FUNCTION SITE_TYPE(SELF IN OUT NOCOPY SITE_TYPE) RETURN SELF AS RESULT
  IS
  BEGIN
     SELF := SITE_TYPE
        (COUNTRY_CODE          => NULL
       , INTERNATIONAL_SITE_ID => NULL
       , LANGUAGE_CODE         => NULL
       , OPERATOR_ID           => NULL
       , EMAIL                 => NULL
       , STATE_ID              => NULL
        );
     RETURN;
  END;

END;

/