{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeOperators #-}

-- | cascade, waterfall, rapids
-- simplify waterfall-cad expressions by complicating the types and type errors
module Rapids (module Rapids, module Linear, module Control.Lens, module Waterfall) where

import Control.Lens hiding (prism)
import Data.Maybe
import Data.Proxy (Proxy (..))
import GHC.TypeLits
import Linear hiding (rotate)
import Waterfall hiding (mirror, rotate, scale, translate)
import qualified Waterfall as W

-- | `t` is shorthand for 'translate' applied to different objects:
--
-- > v = V3 x y z
-- > bxyz = t x y z b
-- > bxyz = t v b -- equivalent
class Translate a where
  translate :: a

instance {-# INCOHERENT #-} (d ~ Double, e ~ Double, f ~ Double, a ~ Solid, a' ~ a) => Translate (d -> e -> f -> a -> a') where
  translate x y z a = W.translate (V3 x y z) a

instance {-# OVERLAPPABLE #-} (d ~ Double, a ~ Solid, a ~ a') => Translate (V3 d -> a -> a') where
  translate v a = W.translate v a

-- | Linear defines 'ex' 'ey' 'ez'
-- t 'ex' 3 solid
instance {-# OVERLAPPABLE #-} (v ~ V3, amt ~ Double, a ~ Solid, a' ~ a) => Translate (E v -> amt -> a -> a') where
  translate (E e) amt a = W.translate (0 & e .~ amt) a

class Rotate a where
  rotate :: a

instance {-# INCOHERENT #-} (x ~ Double, y ~ Double, z ~ Double, ang ~ Double, a ~ Solid, a' ~ a) => Rotate (x -> y -> z -> ang -> a -> a') where
  rotate x y z ang a = W.rotate (V3 x y z) ang a

instance {-# OVERLAPPABLE #-} (d ~ Double, ang ~ Double, a ~ Solid, a' ~ a) => Rotate (V3 d -> ang -> a -> a') where
  rotate v ang a = W.rotate v ang a

instance {-# OVERLAPPABLE #-} (d ~ Double, a ~ Solid, a' ~ a) => Rotate (Quaternion d -> a -> a') where
  rotate q a = W.rotate (q ^. _yzw) (acos (q ^. _x)) a

instance {-# OVERLAPPABLE #-} (v ~ V3, ang ~ Double, a ~ Solid, a' ~ a) => Rotate (E v -> ang -> a -> a') where
  rotate (E e) ang a = W.rotate (0 & e .~ 1) ang a

-- not too happy about this one... because the degrees should be at the end?
class RotateBy a where
  rotateDeg :: a

instance {-# INCOHERENT #-} (deg ~ Double, x ~ Double, y ~ Double, z ~ Double, a ~ Solid, a' ~ a) => RotateBy (x -> y -> z -> deg -> a -> a') where
  rotateDeg x y z p a = W.rotate (V3 x y z) (p * pi / 180) a

instance {-# OVERLAPPABLE #-} (deg ~ Double, d ~ Double, a ~ Solid, a' ~ a) => RotateBy (V3 d -> deg -> a -> a') where
  rotateDeg v p a = W.rotate v (p * pi / 180) a

instance {-# OVERLAPPABLE #-} (deg ~ Double, d ~ Double, a ~ Solid, a' ~ a) => RotateBy (Quaternion d -> deg -> a -> a') where
  rotateDeg q p = W.rotate (q ^. _yzw) (p * pi / 180)

instance {-# OVERLAPPABLE #-} (deg ~ Double, v ~ V3, a ~ Solid, a' ~ a) => RotateBy (E v -> deg -> a -> a') where
  rotateDeg (E e) p a = W.rotate (0 & e .~ 1) (p * pi / 180) a

class Scale a where
  scale :: a

instance {-# INCOHERENT #-} (v ~ V3, amt ~ Double, a ~ Solid, a' ~ a) => Scale (E v -> amt -> a -> a') where
  scale (E e) amt a = W.scale (0 & e .~ amt) a

instance {-# OVERLAPPABLE #-} (x ~ Double, y ~ Double, z ~ Double, a ~ Solid, a' ~ a) => Scale (x -> y -> z -> a -> a') where
  scale x y z a = W.scale (V3 x y z) a

instance {-# OVERLAPPABLE #-} (a ~ Solid, a' ~ a, Double ~ d) => Scale (d -> a -> a') where
  scale xyz a = W.scale (V3 xyz xyz xyz) a

class Mirror a where
  mirror :: a

instance {-# INCOHERENT #-} (d ~ Double, s ~ Solid, s' ~ s) => Mirror (V3 d -> s -> s') where
  mirror v a = W.mirror v a

instance {-# OVERLAPPABLE #-} (v ~ V3, amt ~ Double, s ~ Solid, s' ~ s) => Mirror (E v -> s -> s') where
  mirror (E e) a = W.mirror (0 & e .~ 1) a

instance {-# OVERLAPPABLE #-} (x ~ Double, y ~ Double, z ~ Double, s ~ Solid, s ~ s') => Mirror (x -> y -> z -> s -> s') where
  mirror x y z a = W.mirror (V3 x y z) a

-- won't be upstreamed maybe Joe will depend on `algebra`
--
-- other ideas are minkowski sum
instance Num Solid where
  (-) = difference
  (+) = union
  (*) = intersection
  negate = complement
  fromInteger n = scale (fromInteger n) unitCube

  -- \| reflect if the 'centerOfMass' is behind the plane centered at the origin with normal (1,1,1)
  abs x
    | sum (centerOfMass x) < 0 = mirror (1 :: V3 Double) x
    | otherwise = x

  -- \| `abs . signum = signum . abs`
  -- violated because the aabb center of mass can be on the other side of the plane.
  -- consider a solid that's a big sphere at (-1, 0,0) and a small sphere at 2,0,0
  -- abs . signum will not mirror
  -- signum . abs will mirror
  signum = aabbToSolid . fromMaybe (error msg) . axisAlignedBoundingBox
    where
      msg = "Rapids.signum :: Waterfall.Solid->Waterfall.Solid: can't compute axisAlignedBoundingBox"