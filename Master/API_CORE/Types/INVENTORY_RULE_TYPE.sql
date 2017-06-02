CREATE OR REPLACE TYPE api_core.INVENTORY_RULE_TYPE FORCE AS OBJECT

-- ***************************************************************************
--  TYPE        : API_CORE.INVENTORY_RULE_TYPE
--  DESCRIPTION : Type à importer pour mettre dans la table MASTER.PDA_PROPERTIES
--
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.04.04 | Leang NGUON
--          | version initiale - RM1 2017 [ 10417 - Inventaire colis ]
--          | Init
-- ***************************************************************************
(
    SITE_INTERNATIONAL_ID           VARCHAR2(35)    -- Identifiant International du site
  , PROPERTY_NAME                   VARCHAR2(30)    -- Property name
  , PROPERTY_VALUE                  VARCHAR2(500)   -- valeur de la property
  , CHECK_RESULT                    NUMBER          -- Retourner le résultat si c'est bien passé ou non, valeur se trouve dans PCK_API_CONSTANTS
  , CONSTRUCTOR FUNCTION INVENTORY_RULE_TYPE              (SELF IN OUT NOCOPY INVENTORY_RULE_TYPE) RETURN SELF AS RESULT
  , MEMBER      FUNCTION MissingMandatoryParameters       (SELF IN INVENTORY_RULE_TYPE)            RETURN VARCHAR2
  , MEMBER      FUNCTION MissingMandatoryParameters2      (SELF IN INVENTORY_RULE_TYPE)            RETURN VARCHAR2

)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core.INVENTORY_RULE_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.INVENTORY_RULE_TYPE
--  DESCRIPTION : Type à importer pour mettre dans la table MASTER.PDA_PROPERTIES
--
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.04.04 | Leang NGUON
--          | version initiale - RM1 2017 [ 10417 - Inventaire colis ]
--          | Init
-- ***************************************************************************
IS


CONSTRUCTOR FUNCTION INVENTORY_RULE_TYPE(SELF IN OUT NOCOPY INVENTORY_RULE_TYPE) RETURN SELF AS RESULT
IS
      --
BEGIN
      SELF := INVENTORY_RULE_TYPE
            (
								  SITE_INTERNATIONAL_ID => NULL
							  , PROPERTY_NAME         => NULL
							  , PROPERTY_VALUE        => NULL
                , CHECK_RESULT          => NULL
             );
      RETURN;
END;

-- -----------------------------------------------------------------------------
-- Fonction MissingMandatoryParameters2 :
--    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
--    (donc si tout ok ça va renvoyer une liste vide) pour un PICKUP STANDARD
--    Utiliser pour obtenir la valeur de RULE : PROPERTY_VALUE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
--
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.04.04 | Leang NGUON
--          | version initiale - RM1 2017 [ 10417 - Inventaire colis ]
--          | Init
-- -----------------------------------------------------------------------------

MEMBER FUNCTION MissingMandatoryParameters2 (self in INVENTORY_RULE_TYPE) RETURN VARCHAR2
IS
      --
      l_result    VARCHAR2(4000) := NULL;

BEGIN

      IF self IS NULL THEN
             l_result  := api_core.PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'NULL ');
      END IF;

      IF TRIM(self.SITE_INTERNATIONAL_ID) IS NULL THEN
             l_result  := api_core.PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'SITE_INTERNATIONAL_ID is NULL');
      END IF;

      IF TRIM(self.PROPERTY_NAME) IS NULL THEN
             l_result  := api_core.PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'PROPERTY_NAME is NULL');
      END IF;

      RETURN l_result;

EXCEPTION
      WHEN OTHERS THEN
             l_result       := '[API_CORE][INVENTORY_RULE_TYPE] ' || PCK_API_CONSTANTS.errmsg_oracle_exception ;
             RAISE_APPLICATION_ERROR( PCK_API_CONSTANTS.errnum_oracle_exception, l_result);
             RETURN l_result;
END;

-- -----------------------------------------------------------------------------
-- Fonction MissingMandatoryParameters :
--    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
--    (donc si tout ok ça va renvoyer une liste vide) pour un PICKUP STANDARD
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
--
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.04.04 | Leang NGUON
--          | version initiale - RM1 2017 [ 10417 - Inventaire colis ]
--          | Init
-- -----------------------------------------------------------------------------

MEMBER FUNCTION MissingMandatoryParameters (self in INVENTORY_RULE_TYPE) RETURN VARCHAR2
IS
      --
      l_result    VARCHAR2(4000) := NULL;

BEGIN

      l_result    := MissingMandatoryParameters2 ;
      IF l_result IS NOT NULL THEN
             RETURN l_result;
      END IF;


      IF TRIM(self.PROPERTY_VALUE) IS NULL THEN
             l_result  := api_core.PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'PROPERTY_VALUE is NULL');
      END IF;

      RETURN l_result;

EXCEPTION
      WHEN OTHERS THEN
             l_result       := '[API_CORE][INVENTORY_RULE_TYPE] ' || PCK_API_CONSTANTS.errmsg_oracle_exception ;
             RAISE_APPLICATION_ERROR( PCK_API_CONSTANTS.errnum_oracle_exception, l_result);
             RETURN l_result;
END;


END;

/