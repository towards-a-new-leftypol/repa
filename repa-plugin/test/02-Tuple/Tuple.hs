module Main where
import Data.Array.Repa.Series           as R
import Data.Array.Repa.Series.Series    as S
import Data.Array.Repa.Series.Vector    as V
import qualified Data.Vector.Unboxed    as U

---------------------------------------------------------------------
-- | Set the primitives used by the lowering transform.
repa_primitives :: R.Primitives
repa_primitives =  R.primitives


---------------------------------------------------------------------
main
 = do   v1      <- V.fromUnboxed $ U.enumFromN (1 :: Int) 10
        print $ R.runSeries v1 lower_fffold
        print $ R.runSeries v1 lower_fffold_nest
        print $ R.runSeries v1 lower_fffold_4
        print $ R.runSeries v1 lower_fold_map


-- Triple fold fusion.
--  We end up with an extra let-binding for the second baseband 
--  addition that needs to be handled properly.
lower_fffold :: R.Series k Int -> (Int, Int)
lower_fffold s
 = (R.fold (+) 0 s + R.fold (*) 1 s, R.fold (*) 1 s)


lower_fffold_nest :: R.Series k Int -> ((Int,Int), (Int,Int))
lower_fffold_nest s
 = ((R.fold (+) 0 s, R.fold (*) 1 s), (R.fold (*) 1 s, 500))


lower_fffold_4 :: R.Series k Int -> (Int, Int, Int, Int)
lower_fffold_4 s
 = (R.fold (+) 0 s, R.fold (*) 1 s, R.fold (*) 1 s, 500)


-- Fold a series while mapping across it.
--  The source elements are only read from memory once.
lower_fold_map :: R.Series k Int -> (Int, Vector Int)
lower_fold_map s
 = ( R.fold (+) 0 s
   , S.toVector (R.map  (\x -> x * 2) s))


-- Fold a series of tuples.
-- TODO: this doesn't convert to DDC due to tuples
-- lower_fold_tuples :: R.Series k (Int, Int) -> (Int, Int)
-- lower_fold_tuples s
 -- = R.fold (\(x1, y1) (x2, y2) -> (x1 + x2, y1 + y2)) (0, 0) s

