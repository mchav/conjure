-- |
-- Module      : Conjure.Engine
-- Copyright   : (c) 2021 Rudy Matela
-- License     : 3-Clause BSD  (see the file LICENSE)
-- Maintainer  : Rudy Matela <rudy@matela.com.br>
--
-- An internal module of 'Conjure',
-- a library for Conjuring function implementations
-- from tests or partial definitions.
-- (a.k.a.: functional inductive programming)
{-# LANGUAGE CPP, RecordWildCards, TupleSections #-}
module Conjure.Engine
  ( module Data.Express
  , module Data.Express.Fixtures
  , module Test.Speculate.Engine
  , module Test.Speculate.Reason
  , Args(..)
  , args
  , conjure
  , conjureWith
  , conjureWithMaxSize
  , conjpure
  , conjpureWith
  , candidateExprs
  )
where

import Data.Express
import Data.Express.Fixtures hiding ((-==-))
import qualified Data.Ratio
import Test.LeanCheck.Error (errorToTrue, errorToFalse, errorToNothing)
import Test.Speculate hiding ((===), Args(..), args)
import Test.Speculate.Reason
import Test.Speculate.Engine
import Test.Speculate.Expr
import System.IO

import Conjure.Expr
import Conjure.Conjurable

-- | Arguments to be passed to 'conjureWith' or 'conjpureWith'.
--   See 'args' for the defaults.
data Args = Args
  { maxTests          :: Int  -- ^ defaults to 60
  , maxSize           :: Int  -- ^ defaults to 9, keep greater than maxEquationSize
  , maxRecursiveCalls :: Int  -- ^ defaults to 1
  , maxEquationSize   :: Int  -- ^ defaults to 5, keep smaller than maxSize
  , maxRecursionSize  :: Int  -- ^ defaults to 60
  }

-- | Default arguments to conjure.
--
-- * 60 tests
-- * functions of up to 9 symbols
-- * maximum of 1 recursive call
-- * pruning with equations up to size 5
-- * recursion up to 60 symbols.
args :: Args
args = Args
  { maxTests           =  60
  , maxSize            =  12
  , maxRecursiveCalls  =   1
  , maxEquationSize    =   5
  , maxRecursionSize   =  60
  }

-- | Like 'conjure' but in the pure world.
--
-- Returns tiers of implementations paired with 'tiers' of candidate bodies.
conjpure :: Conjurable f => String -> f -> [Expr] -> ([[Expr]], [[Expr]])
conjpure =  conjpureWith args

-- | Like 'conjpure' but allows setting options through 'Args' and 'args'.
conjpureWith :: Conjurable f => Args -> String -> f -> [Expr] -> ([[Expr]], [[Expr]])
conjpureWith Args{..} nm f es  =  (implementationsT, candidatesT)
  where
  implementationsT  =  mapT (vffxx -==-) $ filterT implements candidatesT
  implements e  =  apparentlyTerminates rrff e
                && ffxx ?=? recursexpr maxRecursionSize vffxx e
  candidatesT  =  filterT (\e -> typ e == typ ffxx)
               .  take maxSize
               $  candidateExprs nm f maxEquationSize maxRecursiveCalls (===) es
  ffxx   =  canonicalApplication nm f
  vffxx  =  canonicalVarApplication nm f
  (rrff:_)   =  unfoldApp vffxx

  e1 === e2  =  isReallyTrue (e1 -==- e2)
  e1 ?=? e2  =  isTrueWhenDefined (e1 -==- e2)
  (-==-)  =  conjureMkEquation f

  isTrueWhenDefined e  =  all (errorToFalse . eval False) $ map (e //-) dbss
  isReallyTrue  =  all (errorToFalse . eval False) . gs

  gs :: Expr -> [Expr]
  gs  =  take maxTests . grounds (conjureTiersFor f)

  bss, dbss :: [[(Expr,Expr)]]
  bss  =  take maxTests $ groundBinds (conjureTiersFor f) ffxx
  dbss  =  [bs | bs <- bss, errorToFalse . eval False $ e //- bs]
    where
    e  =  ffxx -==- ffxx

-- | Conjures an implementation of a partially defined function.
--
-- Takes a 'String' with the name of a function,
-- a partially-defined function from a conjurable type,
-- and a list of building blocks encoded as 'Expr's.
--
-- For example, given:
--
-- > square :: Int -> Int
-- > square 0  =  0
-- > square 1  =  1
-- > square 2  =  4
-- >
-- > primitives :: [Expr]
-- > primitives =
-- >   [ val (0::Int)
-- >   , val (1::Int)
-- >   , value "+" ((+) :: Int -> Int -> Int)
-- >   , value "*" ((*) :: Int -> Int -> Int)
-- > ]
--
-- The conjure function does the following:
--
-- > > conjure "square" square primitives
-- > square :: Int -> Int
-- > -- looking through 815 candidates, 100% match, 3/3 assignments
-- > square x  =  x * x
--
-- The primitives list is defined with 'val' and 'value'.
conjure :: Conjurable f => String -> f -> [Expr] -> IO ()
conjure  =  conjureWith args

-- | Like 'conjure' but allows setting the maximum size of considered expressions
--   instead of the default value of 9.
--
-- > conjureWithMaxSize 10 "function" function [...]
conjureWithMaxSize :: Conjurable f => Int -> String -> f -> [Expr] -> IO ()
conjureWithMaxSize sz  =  conjureWith args
                       {  maxSize = sz
                       ,  maxEquationSize = min sz (maxEquationSize args)
                       }

-- | Like 'conjure' but allows setting options through 'Args'/'args'.
--
-- > conjureWith args{maxSize = 11} "function" function [...]
conjureWith :: Conjurable f => Args -> String -> f -> [Expr] -> IO ()
conjureWith args nm f es  =  do
  print (var (head $ words nm) f)
  pr 1 rs
  where
  pr n []  =  putStrLn $ "cannot conjure"
  pr n ((is,es):rs)  =  do
    putStrLn $ "-- looking through " ++ show (length es) ++ " candidates of size " ++ show n
    case is of
      []     ->  pr (n+1) rs
      (i:_)  ->  do putStrLn $ showEq i
                    putStrLn ""
  rs  =  uncurry zip $ conjpureWith args nm f es
  showEq eq  =  showExpr (lhs eq) ++ "  =  " ++ showExpr (rhs eq)

candidateExprs :: Conjurable f
               => String -> f
               -> Int
               -> Int
               -> (Expr -> Expr -> Bool)
               -> [Expr]
               -> [[Expr]]
candidateExprs nm f sz mc (===) es  =
  candidateExprsT nm f sz mc (===)
    [nub $ [val False, val True] ++ es ++ conjureIfs f]

candidateExprsT :: Conjurable f
                => String -> f
                -> Int
                -> Int
                -> (Expr -> Expr -> Bool)
                -> [[Expr]]
                -> [[Expr]]
candidateExprsT nm f sz mc (===) ess  =  expressionsT $ [ef:exs] \/ ess
  where
  (ef:exs)  =  unfoldApp $ canonicalVarApplication nm f
  thy  =  theoryFromAtoms (===) sz $ [conjureHoles f] \/ ess
  expressionsT ds  =  filterT (\e -> count (== ef) (vars e) <= mc)
                   $  filterT (isRootNormalE thy)
                   $  ds \/ (delay $ productMaybeWith ($$) es es)
    where
    es = expressionsT ds

lhs, rhs :: Expr -> Expr
lhs (((Value "==" _) :$ e) :$ _)  =  e
rhs (((Value "==" _) :$ _) :$ e)  =  e

compareResult :: (Int,Expr) -> (Int,Expr) -> Ordering
compareResult (n1,e1) (n2,e2)  =  n2 `compare` n1
                               <> e1 `compareSimplicity` e2

(%) :: Int -> Int -> Int
x % y  =  x * 100 `div` y
