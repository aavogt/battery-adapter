{-# LANGUAGE TemplateHaskell #-}
import Rapids

-- read ./config.ini
[iniVal| extrusion_width layer_height first_layer_height |]

main = do
  write <- mkStepWriterColor
  write $ ($yellow flange + $green sleeve - $blue hole) * scale a a (h + 1) ($darkbrown unitSphere)

{- ORMOLU_DISABLE -}
hole = scale (a / 2) (a / 2) (10 + h) centeredCylinder
flange = scale b b t centeredCube
sleeve = translate ez (h / 2) $ scale (a / 2 + t) (a / 2 + t) h centeredCylinder
a = 14.5
b = 26
h = 5
t = 2 * extrusion_width
