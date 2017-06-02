CREATE OR REPLACE TYPE api_core."SITE_RULES_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.SITE_RULES_TYPE
--  DESCRIPTION : Objet type représentant la config. ( cf. traitements CONFIG_PDA )
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2016.03.30 | Hocine HAMMOU
--          | Init
-- ***************************************************************************

(
RULE_NAME    VARCHAR2(30) -- CONFIG.PDA_PROPERTY.PDA_PROPERTY_NAME /
,RULE_VALUE  VARCHAR2(30) -- CONFIG.PDA_PROPERTY.PDA_PROPERTY_NAME / MASTER.SITE_RULES.PDA_PROPERTY_VALUE

,CONSTRUCTOR FUNCTION SITE_RULES_TYPE(SELF IN OUT NOCOPY SITE_RULES_TYPE) RETURN SELF AS RESULT

)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."SITE_RULES_TYPE" 
-- ***************************************************************************
--  BODY TYPE   : API_CORE.SITE_RULES_TYPE
--  DESCRIPTION : Objet type représentant la config. ( cf. traitements CONFIG_PDA )
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2016.03.30 | Hocine HAMMOU
--          | Init
-- ***************************************************************************
IS
  CONSTRUCTOR FUNCTION SITE_RULES_TYPE(SELF IN OUT NOCOPY SITE_RULES_TYPE) RETURN SELF AS RESULT
  IS
  BEGIN
     SELF := SITE_RULES_TYPE
        (
          RULE_NAME     => NULL
         ,RULE_VALUE    => NULL
        );
     RETURN;
  END;
END;

/