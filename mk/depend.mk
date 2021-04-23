bench/arith: \
  bench/arith.hs \
  mk/toplibs
bench/arith.o: \
  src/Conjure/Utils.hs \
  src/Conjure.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Engine.hs \
  src/Conjure/Conjurable.hs \
  bench/arith.hs
bench/bools: \
  bench/bools.hs \
  mk/toplibs
bench/bools.o: \
  src/Conjure/Utils.hs \
  src/Conjure.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Engine.hs \
  src/Conjure/Conjurable.hs \
  bench/bools.hs
bench/factorial: \
  bench/factorial.hs \
  mk/toplibs
bench/factorial.o: \
  src/Conjure/Utils.hs \
  src/Conjure.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Engine.hs \
  src/Conjure/Conjurable.hs \
  bench/factorial.hs
bench/ints: \
  bench/ints.hs \
  mk/toplibs
bench/ints.o: \
  src/Conjure/Utils.hs \
  src/Conjure.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Engine.hs \
  src/Conjure/Conjurable.hs \
  bench/ints.hs
mk/All.o: \
  src/Conjure/Utils.hs \
  src/Conjure.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Engine.hs \
  src/Conjure/Conjurable.hs \
  mk/All.hs
mk/Toplibs.o: \
  src/Conjure/Utils.hs \
  src/Conjure.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Engine.hs \
  src/Conjure/Conjurable.hs \
  mk/Toplibs.hs
proto/u-conjure.o: \
  proto/u-conjure.hs
proto/u-conjure: \
  proto/u-conjure.hs \
  mk/toplibs
src/Conjure/Arguable.o: \
  src/Conjure/Utils.hs \
  src/Conjure/TypeBinding.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Arguable.hs
src/Conjure/Conjurable.o: \
  src/Conjure/Utils.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Conjurable.hs
src/Conjure/Engine.o: \
  src/Conjure/Utils.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Engine.hs \
  src/Conjure/Conjurable.hs
src/Conjure/Expr.o: \
  src/Conjure/Utils.hs \
  src/Conjure/Expr.hs
src/Conjure.o: \
  src/Conjure/Utils.hs \
  src/Conjure.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Engine.hs \
  src/Conjure/Conjurable.hs
src/Conjure/TypeBinding.o: \
  src/Conjure/TypeBinding.hs
src/Conjure/Utils.o: \
  src/Conjure/Utils.hs
test/expr.o: \
  test/Test.hs \
  test/expr.hs \
  src/Conjure/Utils.hs \
  src/Conjure.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Engine.hs \
  src/Conjure/Conjurable.hs
test/expr: \
  test/Test.hs \
  test/expr.hs \
  mk/toplibs
test/Test.o: \
  test/Test.hs \
  src/Conjure/Utils.hs \
  src/Conjure.hs \
  src/Conjure/Expr.hs \
  src/Conjure/Engine.hs \
  src/Conjure/Conjurable.hs
test/Test: \
  test/Test.hs \
  mk/toplibs
