CREATE OR REPLACE TYPE api_core.INVENTORY_SITE_TYPE FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.INVENTORY_SITE_TYPE
--  DESCRIPTION : Type à exportertable pour les inventaires de chaque pudo
--                contiendra le récapitulatif des inventaires colis d'un site
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
    INVENTORY_SITE_ID NUMBER(38)         -- PK : Identifiant
  , SESSION_DTM       DATE               -- Date de fin de session de l'inventaire
  , STATE             VARCHAR2(128)      -- Statut de l'inventaire (COMPLETE ou PARTIAL)
  , ORIGIN            VARCHAR2(128)      -- Origine de l'inventaire sur le PDA : MESSAGE, TASK_MENU, DESKTOP
  , CREATION_DTM      TIMESTAMP(6)       -- Date de création
  , LAST_UPDATE_DTM   TIMESTAMP(6)       -- Date de mise à jour
  , DURATION          NUMBER             -- Durée d'inventaire en minutes
  , CONSTRUCTOR FUNCTION INVENTORY_SITE_TYPE        (SELF IN OUT NOCOPY INVENTORY_SITE_TYPE) RETURN SELF AS RESULT
  , MEMBER      FUNCTION MissingMandatoryParameters (SELF IN INVENTORY_SITE_TYPE)            RETURN VARCHAR2

)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core.INVENTORY_SITE_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.INVENTORY_SITE_TYPE
--  DESCRIPTION : Type à exportertable pour les inventaires de chaque pudo
--                contiendra le récapitulatif des inventaires colis d'un site
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
CONSTRUCTOR FUNCTION INVENTORY_SITE_TYPE(SELF IN OUT NOCOPY INVENTORY_SITE_TYPE) RETURN SELF AS RESULT
IS
BEGIN
      SELF := INVENTORY_SITE_TYPE
            (
                INVENTORY_SITE_ID => NULL
                , SESSION_DTM       => NULL
                , STATE             => NULL
                , ORIGIN            => NULL
                , CREATION_DTM      => NULL
                , LAST_UPDATE_DTM   => NULL
                , DURATION          => NULL
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

MEMBER FUNCTION MissingMandatoryParameters (self in INVENTORY_SITE_TYPE) RETURN VARCHAR2
IS
      --
      l_result    VARCHAR2(4000) := NULL;

BEGIN

      IF self IS NULL THEN
             l_result  := api_core.PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'NULL ');
      END IF;

      IF TRIM(self.INVENTORY_SITE_ID) IS NULL THEN
             l_result  := api_core.PCK_API_TOOLS.LIST(P_LIST => l_result, p_item => 'INVENTORY_SITE_ID is NULL');
      END IF;

      RETURN l_result;

EXCEPTION
      WHEN OTHERS THEN
             l_result       := '[API_CORE][INVENTORY_SITE_TYPE] ' || PCK_API_CONSTANTS.errmsg_oracle_exception ;
             RAISE_APPLICATION_ERROR( PCK_API_CONSTANTS.errnum_oracle_exception, l_result);
END;



END;

/