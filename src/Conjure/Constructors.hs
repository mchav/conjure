-- |
-- Module      : Conjure.Constructors
-- Copyright   : (c) 2021 Rudy Matela
-- License     : 3-Clause BSD  (see the file LICENSE)
-- Maintainer  : Rudy Matela <rudy@matela.com.br>
--
-- This module is part of 'Conjure'.
--
-- This module defines the 'Constructors' typeclass
-- that allows listing constructors of a type
-- encoded as 'Expr's
--
-- You are probably better off importing "Conjure".
{-# Language DeriveDataTypeable, StandaloneDeriving #-} -- for GHC < 7.10
module Conjure.Constructors
  ( Constructors (..)
  , Fxpr
  , Fxpress (..)
  , fxprExample2
  )
where

import Conjure.Utils
import Data.Express
import Data.Express.Express
import Data.Express.Fixtures
import Data.Typeable (Typeable)

type Fxpr  =  [([Expr],Expr)]

fxprExample2 :: Fxpr
fxprExample2  =
  [ [nil]           =-  zero
  , [(xx -:- xxs)]  =-  xx -+- sum' xxs
  ]
  where
  (=-) = (,)
  infixr 0 =-

class Typeable a => Fxpress a where
  fvl :: Fxpr -> a
  fvl (([],e):_)  =  evl e
  fvl _           =  error "fvl: incomplete pattern match"

instance Fxpress ()
instance Fxpress Int
instance Fxpress Bool
instance Fxpress Char
instance Fxpress a => Fxpress [a]
instance Fxpress a => Fxpress (Maybe a)
instance (Fxpress a, Fxpress b) => Fxpress (Either a b)

instance (Constructors a, Fxpress b) => Fxpress (a -> b) where
  fvl cs x  =  fvl [ (ps,exp //- bs)
                   | (p:ps,exp) <- cs
                   , bs <- maybeToList (match (expr1 x) p)
                   ]
-- TODO: add exception above for "Num" values.


class Express a => Constructors a where
  expr1 :: a -> Expr
  constructors :: a -> [Expr]

instance Constructors () where
  expr1  =  val
  constructors _  =  [val ()]

instance Constructors Bool where
  expr1  =  val
  constructors _  =  [val False, val True]

constructorsNum :: (Num a, Express a) => a -> [Expr]
constructorsNum x  =  [ val (0 -: x)
                      , value "inc" ((+1) ->: x) :$ hole x
                      ]

expr1Num :: (Num a, Express a) => a -> Expr
expr1Num  =  undefined

instance Constructors Int where
  expr1  =  expr1Num
  constructors  =  constructorsNum

instance Constructors Integer where
  expr1  =  expr1Num
  constructors  =  constructorsNum

instance Constructors Char where
  expr1  =  val
  constructors _  =  []

instance Express a => Constructors [a] where
  expr1 xs  =  case xs of
               [] -> val xs
               (y:ys) -> value ":" ((:) ->>: xs) :$ val y :$ val ys
  constructors xs  =  [ val ([] -: xs)
                      , value ":" ((:) ->>: xs) :$ hole x :$ hole xs
                      ]
    where
    x  =  head xs


instance (Express a, Express b) => Constructors (a,b) where
  expr1 (x,y)  =  value "," ((,) ->>: (x,y))
               :$ val x :$ val y
  constructors xy  =  [value "," ((,) ->>: xy) :$ hole x :$ hole y]
    where
    (x,y) = (undefined,undefined) -: xy

instance (Express a, Express b, Express c) => Constructors (a,b,c) where
  expr1 (x,y,z)  =  value ",," ((,,) ->>>: (x,y,z))
                 :$ val x :$ val y :$ val z

  constructors xyz  =  [value ",," ((,,) ->>>: xyz) :$ hole x :$ hole y :$ hole z]
    where
    (x,y,z) = (undefined,undefined,undefined) -: xyz

instance Express a => Constructors (Maybe a) where
  expr1 mx@Nothing   =  value "Nothing" (Nothing -: mx)
  expr1 mx@(Just x)  =  value "Just"    (Just   ->: mx) :$ val x
  constructors mx  =  [ value "Nothing" (Nothing -: mx)
                      , value "Just" (Just ->: mx) :$ hole x
                      ]
    where
    x  =  Just undefined -: mx


instance (Express a, Express b) => Constructors (Either a b) where
  expr1 lx@(Left x)   =  value "Left"  (Left  ->: lx) :$ val x
  expr1 ry@(Right y)  =  value "Right" (Right ->: ry) :$ val y
  constructors exy  =  [ value "Left" (Left ->: exy) :$ hole x
                       , value "Right" (Right ->: exy) :$ hole y
                       ]
    where
    x  =  Left undefined -: exy
    y  =  Right undefined -: exy
