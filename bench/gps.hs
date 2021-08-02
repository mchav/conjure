-- gps.hs: General Program Synthesis Benchmark Suite
--
-- Copyright (C) 2021 Rudy Matela
-- Distributed under the 3-Clause BSD licence (see the file LICENSE).
import Conjure
import System.Environment (getArgs)

import Data.Char (isLetter) -- GPS #5
import Data.Char (isSpace)  -- GPS #7


gps1p :: Int -> Float -> Float
gps1p 0 1.0  =  1.0
gps1p 1 0.0  =  1.0
gps1p 1 1.0  =  2.0
gps1p 1 1.5  =  2.5

gps1g :: Int -> Float -> Float
gps1g x f  =  fromIntegral x + f

gps1c :: IO ()
gps1c  =  conjure "gps1" gps1p
  [ prim "+" ((+) :: Float -> Float -> Float)
  , prim "fromIntegral" (fromIntegral :: Int -> Float)
  ]


gps2p :: Int -> Maybe String
gps2p    0  =  Just "small"
gps2p  500  =  Just "small"
gps2p 1000  =  Nothing
gps2p 1500  =  Nothing
gps2p 2000  =  Just "large"
gps2p 2500  =  Just "large"

gps2g :: Int -> Maybe String
gps2g n
  | n <  1000  =  Just "small"
  | 2000 <= n  =  Just "large"
  | otherwise  =  Nothing

gps2c :: IO ()
gps2c  =  conjureWith args{maxTests=5080, maxSize=30} "gps2" gps2p
  [ pr "small"
  , pr "large"
  , pr (1000 :: Int)
  , pr (2000 :: Int)
  , prim "Just" (Just :: String -> Maybe String)
  , prim "Nothing" (Nothing :: Maybe String)
  , prim "<=" ((<=) :: Int -> Int -> Bool)
  , prim "<" ((<) :: Int -> Int -> Bool)
  , prif (undefined :: Maybe String)
  ]


gps3p :: Int -> Int -> Int -> [Int]
gps3p 0 9 1  =  [0,1,2,3,4,5,6,7,8]
gps3p 2 9 2  =  [2,4,6,8]

gps3g1 :: Int -> Int -> Int -> [Int]
gps3g1 start end step  =  enumFromThenTo start (step+start) (end-1)

gps3g2 :: Int -> Int -> Int -> [Int]
gps3g2 start end step  =  if start < end
                          then start : gps3g2 (start+step) end step
                          else []

gps3c :: IO ()
gps3c  =  do
  conjure "gps3" gps3p
    [ pr (1 :: Int)
    , prim "enumFromThenTo" ((\x y z -> take 360 $ enumFromThenTo x y z) :: Int -> Int -> Int -> [Int])
    , prim "+" ((+) :: Int -> Int -> Int)
    , prim "-" ((-) :: Int -> Int -> Int)
    ]

  -- not possible, no recursive descent
  conjureWith args{maxSize=8} "gps3" gps3p
    [ pr ([] :: [Int])
    , prim ":" ((:) :: Int -> [Int] -> [Int])
    , prim "+" ((+) :: Int -> Int -> Int)
    , prim "<" ((<) :: Int -> Int -> Bool)
    , prif (undefined :: [Int])
    ]


gps4p :: String -> String -> String -> Bool
gps4p "" "a" "aa"  =  True
gps4p "aa" "a" ""  =  False
gps4p "a" "aa" ""  =  False
gps4p "a" "aa" "aaa"  =  True
gps4p "a" "aaa" "aa"  =  False
gps4p "aa" "a" "aaa"  =  False
gps4p "aa" "aaa" "a"  =  False
gps4p "aaa" "a" "aa"  =  False
gps4p "aaa" "aa" "a"  =  False

gps4g :: String -> String -> String -> Bool
gps4g s1 s2 s3  =  length s1 < length s2 && length s2 < length s3

gps4c :: IO ()
gps4c  =  do
  conjure "gps4" gps4p
    [ prim "length" (length :: String -> Int)
    , prim "<" ((<) :: Int -> Int -> Bool)
    , prim "&&" (&&)
    ]


gps5p :: String -> String
gps5p "a"  =  "aa"
gps5p "b"  =  "bb"
gps5p " "  =  " "
gps5p "!"  =  "!!!"
gps5p "aa"  =  "aaaa"

gps5g :: String -> String
gps5g []  =  []
gps5g (c:cs)
  | isLetter c  =  c:c:gps5g cs
  | c == '!'    =  c:c:c:gps5g cs
  | otherwise   =  c:gps5g cs

gps5c :: IO ()
gps5c  =  conjureWith args{maxSize=6} "gps5" gps5p -- can't find
  [ pr ""
  , prim ":" ((:) :: Char -> String -> String)
  , pr '!'
  , prim "==" ((==) :: Char -> Char -> Bool)
  , prim "isLetter" (isLetter :: Char -> Bool)
  , prif (undefined :: String -> String)
  ]


-- GPS Benchmark #6 -- Collatz/Hailstone numbers --

gps6p :: Int -> Int
gps6p 1  =  1
gps6p 2  =  2
gps6p 3  =  8
gps6p 4  =  3
gps6p 5  =  6
gps6p 6  =  9
gps6p 12  =  10
gps6p 60  =  20
gps6p 360  =  20

gps6g :: Int -> Int
gps6g  =  tnp1
  where
  tnp1 n | n <= 0  =  undefined
  tnp1 1  =  1                          --  1
  tnp1 n  =  1 + gps6g (if even n       --  7
                        then n `div` 2  -- 10
                        else 3*n + 1)   -- 15

-- This one is out of reach performance wise:
-- Speculate hangs with this background.
-- Removing three or setting maxEqSize to 4 makes it unhang.
-- But a size of 15 or 17 is simplyl out of our reach.
gps6c :: IO ()
gps6c  =  conjureWith args{maxSize=6,maxEquationSize=3} "gps6" gps6p
  [ pr (1 :: Int)
  , pr (2 :: Int)
  , pr (3 :: Int)
  , prim "+" ((+) :: Int -> Int -> Int)
  , prim "*" ((*) :: Int -> Int -> Int)
  , prim "`div`" (div :: Int -> Int -> Int)
  , prim "even" (even :: Int -> Bool)
  , prif (undefined :: Int)
  ]


-- GPS Benchmark #7 -- Replace Space with Newline (P 4.3)

gps7p :: String -> (String, Int)
gps7p "a"  =  ("a", 1)
gps7p "aa"  =  ("aa", 2)
gps7p "a a"  =  ("a\na", 2)
gps7p "a\na"  =  ("a\na", 2)

gps7g :: String -> (String, Int)
gps7g s  =  (init $ unlines $ words s, length (filter (not . isSpace) s))

gps7c :: IO ()
gps7c  =  conjure "gps7" gps7p
  [ prim "," ((,) :: String -> Int -> (String, Int))
  , prim "init" (init :: String -> String)
  , prim "unlines" unlines
  , prim "words" words
  , prim "length" (length :: String -> Int)
  , prim "filter" (filter :: (Char -> Bool) -> String -> String)
  , prim "not" not
  , prim "." ((.) :: (Bool -> Bool) -> (Char -> Bool) -> Char -> Bool) -- cheat?
  , prim "isSpace" (isSpace :: Char -> Bool)
  ]


main :: IO ()
main  =  do
  as <- getArgs
  case as of
    [] -> sequence_ gpss
    (n:_) -> gpss !! (read n - 1)


gpss :: [IO ()]
gpss  =  [ gps1c
         , gps2c
         , gps3c
         , gps4c
         , gps5c
         , gps6c
         , gps7c
         ]