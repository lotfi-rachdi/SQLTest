CREATE OR REPLACE TYPE api_core.SITE_INFORMATION_TYPE FORCE AS OBJECT

-- ***************************************************************************
--  TYPE        : API_CORE.SITE_INFORMATION_TYPE
--  DESCRIPTION : Type à exportertable pour l'INFORMATION dsur un pudo
--
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.03.28 | Leang NGUON
--          | version initiale - RM1 2017 [ 10417 - Inventaire colis ]
--          | Init
-- ***************************************************************************
(
    SITE_INTERNATIONAL_ID       VARCHAR2(35)    -- Identifiant International du site
  , BUSINESS_NAME               VARCHAR2(100)   -- Nom commercial
  , SYNC_TIME                   VARCHAR2(8)     -- Dernière synchronisation
  , COUNTRY_CODE                VARCHAR2(3)
  , CONSTRUCTOR FUNCTION SITE_INFORMATION_TYPE      (SELF IN OUT NOCOPY SITE_INFORMATION_TYPE) RETURN SELF AS RESULT
  , MEMBER      FUNCTION MissingMandatoryParameters (SELF IN SITE_INFORMATION_TYPE)            RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core.SITE_INFORMATION_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.SITE_INFORMATION_TYPE
--  DESCRIPTION : Type à exportertable pour l'INFORMATION dsur un pudo
--
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.03.28 | Leang NGUON
--          | version initiale - RM1 2017 [ 10417 - Inventaire colis ]
--          | Init
-- ***************************************************************************
IS


CONSTRUCTOR FUNCTION SITE_INFORMATION_TYPE(SELF IN OUT NOCOPY SITE_INFORMATION_TYPE) RETURN SELF AS RESULT
IS
      --
BEGIN
      SELF := SITE_INFORMATION_TYPE
            (
								  SITE_INTERNATIONAL_ID => NULL
							  , BUSINESS_NAME         => NULL
							  , SYNC_TIME             => NULL
                , COUNTRY_CODE          => NULL

             );
      RETURN;
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
--  V01.000 | 2017.03.28 | Leang NGUON
--          | version initiale - RM1 2017 [ 10417 - Inventaire colis ]
--          | Init
-- -----------------------------------------------------------------------------

MEMBER FUNCTION MissingMandatoryParameters (self in SITE_INFORMATION_TYPE) RETURN VARCHAR2
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

      RETURN l_result;

EXCEPTION
      WHEN OTHERS THEN
             l_result       := '[API_CORE][SITE_INFORMATION_TYPE] ' || PCK_API_CONSTANTS.errmsg_oracle_exception ;
             RAISE_APPLICATION_ERROR( PCK_API_CONSTANTS.errnum_oracle_exception, l_result);
             RETURN l_result;
END;

END;

/