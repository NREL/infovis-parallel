module Data.List.Util (
  headWith
, elemPermutation
) where


import Data.List (elemIndex)


headWith :: a
         -> [a]
         -> a
headWith x []      = x
headWith _ (x : _) = x


elemPermutation :: Eq a => [a] -> [a] -> Maybe [Int]
elemPermutation = mapM . flip elemIndex
