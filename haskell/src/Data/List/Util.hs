module Data.List.Util (
  headWith
) where


headWith :: a
         -> [a]
         -> a
headWith x []      = x
headWith _ (x : _) = x
