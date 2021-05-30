-- Copyright (C) 2021 Rudy Matela
-- Distributed under the 3-Clause BSD licence (see the file LICENSE).

import Test

main :: IO ()
main  =  mainTest tests 5040

tests :: Int -> [Bool]
tests n  =
  [ True

  , holds n $ \x -> iterateUntil (==) (`quot` (2 :: Int)) x == 0
  , holds n $ \xs -> iterateUntil (==) (drop 1) xs == ([]::[Bool])

  , holds n $ \xs ys -> length xs == length ys
                    ==> zipWith (<>) xs ys == mzip xs (ys :: [[Int]])

  , holds n $ \xs ys -> length xs >= length ys
                    ==> zipWith (<>) xs (ys <> repeat mempty) == mzip xs (ys :: [[Int]])

  , takeUntil (== 5) [1..] == [1,2,3,4]
  , takeUntil (> 4)  [1..] == [1,2,3,4]

  , takeNextWhile (<) []  ==  ([]::[Int])
  , takeNextWhile (<) [0]  ==  [0]
  , takeNextWhile (<) [0,1]  ==  [0,1]
  , takeNextWhile (<) [0,1,2]  ==  [0,1,2]
  , takeNextWhile (<) [0,1,2,1,0]  ==  [0,1,2]
  , takeNextWhile (/=) [3,2,1,0,0,0] == [3,2,1,0]
  , takeNextUntil (==) [3,2,1,0,0,0] == [3,2,1,0]
  , takeNextUntil (>) [0,1,2,1,0] == [0,1,2]

  , deconstructions null tail [1,2,3 :: Int]
    == [ [1,2,3]
       , [2,3]
       , [3]
       ]
  , deconstructions (==0) (`div`2) 15
    == [15, 7, 3, 1]

  , isDeconstructor n (null :: [A] -> Bool) tail
  , isDeconstructor n (null :: [A] -> Bool) (drop 1)
  , isDeconstructor n (<0) (\x -> x-1 :: Int)
  , isDeconstructor n (==0) (\x -> x-1 :: Int)
  , isDeconstructor n (==0) (\x -> x `div` 2 :: Int)
  , isDeconstructor n (==0) (\x -> x `quot` 2 :: Int)
  ]


isDeconstructor :: (Eq a, Listable a, Show a)
                => Int
                -> (a -> Bool) -> (a -> a) -> Bool
isDeconstructor m z d  =  count is (take m list) >= (m `div` 2)
  where
  is x  =  not (z x)
       ==> length (take m $ deconstructions z d x) < m
