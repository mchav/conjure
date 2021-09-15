-- |
-- Module      : Conjure.Defn
-- Copyright   : (c) 2021 Rudy Matela
-- License     : 3-Clause BSD  (see the file LICENSE)
-- Maintainer  : Rudy Matela <rudy@matela.com.br>
--
-- This module is part of "Conjure".
--
-- This module exports the 'Defn' type synonym and utilities involving it.
--
-- You are probably better off importing "Conjure".
{-# LANGUAGE TupleSections #-}
module Conjure.Defn
  ( Defn
  , Bndn
  , toDynamicWithDefn
  , devaluate
  , deval
  , devl
  , devalFast
  , showDefn
  , defnApparentlyTerminates
  , module Conjure.Expr
  )
where

import Conjure.Utils
import Conjure.Expr
import Data.Express
import Data.Express.Express
import Data.Express.Fixtures
import Data.Dynamic
import Control.Applicative ((<$>)) -- for older GHCs
import Test.LeanCheck.Utils ((-:>)) -- for toDynamicWithDefn

-- | A function definition as a list of top-level case bindings ('Bndn').
--
-- Here is an example using the notation from "Data.Express.Fixtures":
--
-- > sumV :: Expr
-- > sumV  =  var "sum" (undefined :: [Int] -> Int)
-- >
-- > (=-) = (,)
-- > infixr 0 =-
-- >
-- > sumDefn :: Defn
-- > sumDefn  =  [ sum' nil           =-  zero
-- >             , sum' (xx -:- xxs)  =-  xx -+- (sumV :$ xxs)
-- >             ]  where  sum' e  =  sumV :$ e

type Defn  =  [Bndn]

-- | A single binding in a definition ('Denf').
type Bndn  =  (Expr,Expr)

showDefn :: Defn -> String
showDefn  =  unlines . map show1
  where
  show1 (lhs,rhs)  =  showExpr lhs ++ "  =  " ++ showExpr rhs

type Memo  =  [(Expr, Maybe Dynamic)]

-- | Evaluates an 'Expr' using the given 'Defn' as definition
--   when a recursive call is found.
toDynamicWithDefn :: (Expr -> Expr) -> Int -> Defn -> Expr -> Maybe Dynamic
toDynamicWithDefn exprExpr mx cx  =  fmap (\(_,_,d) -> d) . re (mx * sum (map (size . snd) cx)) []
  where
  (ef':_)  =  unfoldApp . fst $ head cx

  -- recursively evaluate an expression, the entry point
  re :: Int -> Memo -> Expr -> Maybe (Int, Memo, Dynamic)
  re n m _  | length m > mx  =  error "toDynamicWithDefn: recursion limit reached"
  re n m _  | n <= 0  =  error "toDynamicWithDefn: evaluation limit reached"
  re n m (Value "if" _ :$ ec :$ ex :$ ey)  =  case rev n m ec of
    Nothing    -> Nothing
    Just (n,m,True)  -> re n m ex
    Just (n,m,False) -> re n m ey
  re n m (Value "||" _ :$ ep :$ eq)  =  case rev n m ep of
    Nothing        -> Nothing
    Just (n,m,True)  -> (n,m,) <$> toDynamic (val True)
    Just (n,m,False) -> re n m eq
  re n m (Value "&&" _ :$ ep :$ eq)  =  case rev n m ep of
    Nothing    -> Nothing
    Just (n,m,True)  -> re n m eq
    Just (n,m,False) -> (n,m,) <$> toDynamic (val False)
  re n m e  =  case unfoldApp e of
    [] -> error "toDynamicWithDefn: empty application unfold"  -- should never happen
    [e] -> (n-1,m,) <$> toDynamic e
    (ef:exs) | ef == ef' -> red n m (foldApp (ef:map exprExpr exs))
             | otherwise -> foldl ($$) (re n m ef) exs

  -- like 're' but is bound to an actual Haskell value instead of a Dynamic
  rev :: Typeable a => Int -> Memo -> Expr -> Maybe (Int, Memo, a)
  rev n m e  =  case re n m e of
                Nothing    -> Nothing
                Just (n,m,d) -> case fromDynamic d of
                                Nothing -> Nothing
                                Just x  -> Just (n, m, x)

  -- evaluates by matching on one of cases of the actual definition
  -- should only be used to evaluate an expr of the form:
  -- ef' :$ exprExpr ex :$ exprExpr ey :$ ...
  red :: Int -> Memo -> Expr -> Maybe (Int, Memo, Dynamic)
  red n m e  =  case lookup e m of
    Just Nothing -> error $ "toDynamicWithDefn: loop detected " ++ show e
    Just (Just d) -> Just (n,m,d)
    Nothing -> case [re n ((e,Nothing):m) $ e' //- bs | (a',e') <- cx, Just bs <- [e `match` a']] of
               [] -> error $ "toDynamicWithDefn: unhandled pattern " ++ show e
               (Nothing:_) -> Nothing
               (Just (n,m,d):_) -> Just (n,[(e',if e == e' then Just d else md) | (e',md) <- m],d)

  ($$) :: Maybe (Int,Memo,Dynamic) -> Expr -> Maybe (Int, Memo, Dynamic)
  Just (n,m,d1) $$ e2  =  case re n m e2 of
                          Nothing -> Nothing
                          Just (n', m', d2) -> (n',m',) <$> dynApply d1 d2
  _ $$ _               =  Nothing

devaluate :: Typeable a => (Expr -> Expr) -> Int -> Defn -> Expr -> Maybe a
devaluate ee n fxpr e  =  toDynamicWithDefn ee n fxpr e >>= fromDynamic

deval :: Typeable a => (Expr -> Expr) -> Int -> Defn -> a -> Expr -> a
deval ee n fxpr x  =  fromMaybe x . devaluate ee n fxpr

devalFast :: Typeable a => (Expr -> Expr) -> Int -> Defn -> a -> Expr -> a
devalFast _ n [defn] x  =  reval defn n x

devl :: Typeable a => (Expr -> Expr) -> Int -> Defn -> Expr -> a
devl ee n fxpr  =  deval ee n fxpr (error "devl: incorrect type?")

defnApparentlyTerminates :: Defn -> Bool
defnApparentlyTerminates [(efxs, e)]  =  apparentlyTerminates efxs e
defnApparentlyTerminates _  =  True
