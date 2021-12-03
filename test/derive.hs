-- Copyright (c) 2019-2021 Rudy Matela.
-- Distributed under the 3-Clause BSD licence (see the file LICENSE).
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveDataTypeable #-}

-- uncomment to debug derivation:
-- {-# OPTIONS_GHC -ddump-splices #-}

import Test hiding ((-:), (->:))
-- -: and ->: should be generated by deriveConjurable

data Choice  =  Ae | Bee | Cee deriving (Show, Eq, Typeable)
data Peano  =  Zero | Succ Peano deriving (Show, Eq, Typeable)
data List a  =  a :- List a | Nil deriving (Show, Eq, Typeable)
data Bush a  =  Bush a :-: Bush a | Leaf a deriving (Show, Eq, Typeable)
data Tree a  =  Node (Tree a) a (Tree a) | Null deriving (Show, Eq, Typeable)

deriveConjurable ''Choice
deriveConjurable ''Peano
deriveConjurable ''List
deriveConjurable ''Bush
deriveConjurable ''Tree

-- Nested datatype cascade
data Nested  =  Nested N0 (N1 Int) (N2 Int Int) deriving (Eq, Show, Typeable)
data N0      =  R0 Int deriving (Eq, Show, Typeable)
data N1 a    =  R1 a   deriving (Eq, Show, Typeable)
data N2 a b  =  R2 a b deriving (Eq, Show, Typeable)

deriveConjurableCascading ''Nested

-- Recursive nested datatype cascade
data RN       =  RN RN0 (RN1 Int) (RN2 Int RN) deriving (Eq, Show, Typeable)
data RN0      =  Nest0 Int | Recurse0 RN deriving (Eq, Show, Typeable)
data RN1 a    =  Nest1 a   | Recurse1 RN deriving (Eq, Show, Typeable)
data RN2 a b  =  Nest2 a b | Recurse2 RN deriving (Eq, Show, Typeable)
-- beware: values of the above type are always infinite!
--         derivation works but full evaluation does not terminate

deriveConjurableCascading ''RN

-- Those should have no effect (instance already exists):
{- uncommenting those should generate warnings
deriveConjurable ''Bool
deriveConjurable ''Maybe
deriveConjurable ''Either
-}

-- Those should not generate warnings
deriveConjurableIfNeeded ''Bool
deriveConjurableIfNeeded ''Maybe
deriveConjurableIfNeeded ''Either

data Mutual    =  Mutual0   | Mutual CoMutual deriving (Eq, Show, Typeable)
data CoMutual  =  CoMutual0 | CoMutual Mutual deriving (Eq, Show, Typeable)

deriveConjurableCascading ''Mutual


main :: IO ()
main  =  mainTest tests 5040

tests :: Int -> [Bool]
tests n  =
  [ True

  , conjurableOK (undefined :: Bool)
  , conjurableOK (undefined :: Int)
  , conjurableOK (undefined :: Char)
  , conjurableOK (undefined :: [Bool])
  , conjurableOK (undefined :: [Int])
  , conjurableOK (undefined :: String)

  , conjurableOK (undefined :: Choice)
  , conjurableOK (undefined :: Peano)
  , conjurableOK (undefined :: List Int)
  , conjurableOK (undefined :: Bush Int)
  , conjurableOK (undefined :: Tree Int)
--, conjurableOK (undefined :: RN) -- TODO: FIX: infinite loop somewhere...

  , conjureSize Ae == 1
  , conjureSize Bee == 1
  , conjureSize Cee == 1
  , conjureSize Zero == 1
  , conjureSize (Succ Zero) == 2
  , conjureSize (Succ (Succ Zero)) == 3
  , conjureSize (Nil :: List Int) == 1
  , conjureSize (10 :- (20 :- Nil) :: List Int) == 33

  , conjureCases choice
    == [ val Ae
       , val Bee
       , val Cee
       ]

  , conjureCases peano
    == [ val Zero
       , value "Succ" Succ :$ hole (undefined :: Peano)
       ]

  , conjureCases (lst int)
    == [ value ":-" ((:-) ->>: lst int) :$ hole int :$ hole (lst int)
       , val (Nil :: List Int)
       ]

  , conjureCases (undefined :: Tree Int)
    == [ value "Node" (Node ->>>: tree int) :$ hole (tree int) :$ hole int :$ hole (tree int)
       , val (Null :: Tree Int)
       ]

  , conjureHoles (undefined :: Choice) == [ hole (undefined :: Choice)
                                          , hole (undefined :: Bool)
                                          ]
  , conjureHoles (undefined :: Peano) == [ hole (undefined :: Peano)
                                         , hole (undefined :: Bool)
                                         ]
  , conjureHoles (undefined :: List Int) == [ hole (undefined :: Int)
                                            , hole (undefined :: List Int)
                                            , hole (undefined :: Bool)
                                            ]
  , conjureHoles (undefined :: Nested) == [ hole (undefined :: N0)
                                          , hole (undefined :: N1 Int)
                                          , hole (undefined :: Int)
                                          , hole (undefined :: N2 Int Int)
                                          , hole (undefined :: Nested)
                                          , hole (undefined :: Bool)
                                          ]
  , conjureHoles (undefined :: RN) == [ hole (undefined :: RN0)
                                      , hole (undefined :: RN1 Int)
                                      , hole (undefined :: Int)
                                      , hole (undefined :: RN2 Int RN)
                                      , hole (undefined :: RN)
                                      , hole (undefined :: Bool)
                                      ]
  , conjureHoles (undefined :: Mutual) == [ hole (undefined :: CoMutual)
                                          , hole (undefined :: Mutual)
                                          , hole (undefined :: Bool)
                                          ]
  , conjureHoles (undefined :: CoMutual) == [ hole (undefined :: Mutual)
                                            , hole (undefined :: CoMutual)
                                            , hole (undefined :: Bool)
                                            ]
  ]


-- checks if the functions conjureEquality, conjureExpress and conjureTiers
-- were correctly generated.
conjurableOK :: (Eq a, Show a, Express a, Listable a, Conjurable a) => a -> Bool
conjurableOK x  =  and
  [ holds 60 $ (-==-) ==== (==)
  , holds 60 $ expr' === expr
  , tiers =| 6 |= (tiers -: [[x]])
  ]
  where
  (-==-)  =  evl (fromJust $ conjureEquality x) -:> x
  tiers'  =  mapT evl (fromJust $ conjureTiers x) -: [[x]]
  expr'  =  (conjureExpress x . val) -:> x


-- proxies --
choice :: Choice
choice  =  undefined

peano :: Peano
peano  =  undefined

lst :: a -> List a
lst _  =  undefined

tree :: a -> Tree a
tree _  =  undefined
