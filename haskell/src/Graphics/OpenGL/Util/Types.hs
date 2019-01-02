{-# LANGUAGE DeriveAnyClass     #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE RecordWildCards    #-}


module Graphics.OpenGL.Util.Types (
  Stereo(..)
, Viewer(..)
, Display(..)
, Screen(..)
, upperRight
, PointOfView
) where


import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Binary (Binary(..))
import Data.Data (Data)
import Data.Default (Default(..))
import Data.Typeable (Typeable)
import GHC.Generics (Generic)
import Linear.Affine (Point, (.-.), (.+^))
import Linear.Quaternion (Quaternion)
import Linear.Util.Instances ()
import Linear.V3 (V3)

-- | The type of stereo.  
data Stereo =
    DLP        -- ^ Frame-sequential DLP 3D ReadySync stereo.
  | QuadBuffer -- ^ Quad buffer stereo.
  | Cardboard  -- ^ Google Cardboard stereo.
  | Mono       -- ^ No stereo.
  deriving (Binary, Bounded, Data, Enum, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON, Typeable)

instance Default Stereo where
  def = Mono


data Viewer a =
  Viewer
  {
    stereo        :: Stereo
  , nearPlane     :: a
  , farPlane      :: a
  , eyeSeparation :: V3 a
  , display       :: Display a
  }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


data Display a =
  Display
  {
    host       :: Maybe String
  , port       :: Maybe Int
  , identifier :: Maybe String
  , geometry   :: Maybe String
  , screen     :: Screen a
  }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


-- | Description of a physical screen geometry.
data Screen a =
  Screen
  {
    lowerLeft  :: Point V3 a -- ^ The lower left corner.
  , lowerRight :: Point V3 a -- ^ The lower right corner.
  , upperLeft  :: Point V3 a -- ^ The upper left corner.
  }
    deriving (Binary, Data, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)

instance Functor Screen where
  fmap f Screen{..} =
    Screen
    {
      lowerLeft  = f <$> lowerLeft
    , lowerRight = f <$> lowerRight
    , upperLeft  = f <$> upperLeft
    }


upperRight :: (Num a)
           => Screen a
           -> Point V3 a
upperRight Screen{..} = lowerRight .+^ (upperLeft .-. lowerLeft)


type PointOfView a = (Point V3 a, Quaternion a)
