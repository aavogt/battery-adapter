{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE QuasiQuotes #-}
import Rapids
import Rapids.SVG

-- read ./config.ini
[iniVal| extrusion_width layer_height first_layer_height |]

main = do
  write <- mkStepWriterColor
  write $ stacked ey sym csg

csg = ($yellow flange + $green sleeve - $blue hole) * scale d1 (h + 1) ($darkbrown unitSphere)

-- a more symmetric version
sym = $purple $ foldMap (revolution . offset (t/2)) [svg|
  m d1/2 + t/2, h - t/2
  V 0
  H d2/2 - t/2
  |]

{- ORMOLU_DISABLE -}
hole = scale (d1 / 2) (10 + h) centeredCylinder
flange = scale d2 t centeredCube
sleeve = translate ez (h / 2) $ scale (d1 / 2 + t) h centeredCylinder
d1 = 14.5
d2 = 26
h = 5
t = 2 * extrusion_width
