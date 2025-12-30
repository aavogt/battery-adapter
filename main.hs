import Linear
import Waterfall

-- ghcid -r
main = do
  writeSTEP "battery-adapter.step" $
    (scale (V3 b b t) centeredCube <> sleeve)
      `difference` scale (V3 (a / 2) (a / 2) 10) centeredCylinder

sleeve = translate (V3 0 0 (h / 2)) $ scale (V3 (a / 2 + t) (a / 2 + t) h) centeredCylinder

{- ORMOLU_DISABLE -}
a = 14.5
b = 26
h = 5
t = 2 
