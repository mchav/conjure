-- Copyright (C) 2021 Rudy Matela
-- Distributed under the 3-Clause BSD licence (see the file LICENSE).

import Test
import Conjure.Cases

main :: IO ()
main  =  mainTest tests 5040

tests :: Int -> [Bool]
tests n  =
  [ True

  , length (cases (undefined :: ()))      == 1
  , length (cases (undefined :: Bool))    == 2
  , length (cases (undefined :: Int))     == 0
  , length (cases (undefined :: Integer)) == 0
  , length (cases (undefined :: [Int]))   == 2
  , length (cases (undefined :: [Bool]))  == 2

  , feval exprExpr 6 sumFxpr (0::Int) (sumV :$ val [1,2,3,11::Int]) == 17
  , feval exprExpr 6 sumFxpr (0::Int) (sumV :$ val [1,2,3::Int])    == 6
  , feval exprExpr 6 sumFxpr (0::Int) (sumV :$ val [1,2,3,4::Int])  == 10
  ]

sumV :: Expr
sumV  =  var "sum" (undefined :: [Int] -> Int)

-- in Conjure.Conjurable there should be a function
-- called conjureExprExpr that conjures this for the required types.
exprExpr :: Expr -> Expr
exprExpr e  =  evl $ headOr err $ mapMaybe ($$ e)
  [ value "expr" (expr :: Int -> Expr)
  , value "expr" (expr :: [Int] -> Expr)
  , value "expr" (expr :: Bool -> Expr)
  , value "expr" (expr :: [Bool] -> Expr)
  ]
  where
  err  =  error "exprExpr: unhandled type"
