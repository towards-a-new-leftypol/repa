
module Data.Array.Repa.Series.Vector
        ( Vector
        , length
        , new
        , read
        , write
        , take

          -- * Conversions
        , fromUnboxed
        , toUnboxed)
where
import qualified Data.Vector.Unboxed            as U
import qualified Data.Vector.Unboxed.Mutable    as UM
import Data.Vector.Unboxed                      (Unbox)
import System.IO.Unsafe
import GHC.Exts
import Prelude  hiding (length, read, take)


-- | Abstract mutable vector.
-- 
--   Use `fromUnboxed` and `toUnboxed` to convert to and from regular
--   immutable unboxed vectors.
data Vector a
        = Vector
        { vectorLength  :: Word#
        , vectorData    :: !(UM.IOVector a) }


instance (Unbox a, Show a) => Show (Vector a) where
 show vec 
  = unsafePerformIO
  $ do  fvec    <- U.unsafeFreeze (vectorData vec)
        return  $ show fvec


-- | Take the length of a vector.
length :: Vector a -> Word#
length vec
        = vectorLength vec
{-# INLINE length #-}


-- | Create a new vector of the given length.
new  :: Unbox a => Word# -> IO (Vector a)
new len
 = do   vec     <- UM.new (I# (word2Int# len))
        return  $ Vector len vec
{-# INLINE new #-}


-- | Read a value from a vector.
read :: Unbox a => Vector a -> Word# -> IO a
read vec ix
        = UM.unsafeRead (vectorData vec) (I# (word2Int# ix))
{-# INLINE read #-}


-- | Write a value into a vector.
write :: Unbox a => Vector a -> Word# -> a -> IO ()
write vec ix val
        = UM.unsafeWrite (vectorData vec) (I# (word2Int# ix)) val
{-# INLINE write #-}


-- | Take the first n elements of a vector
take :: Unbox a => Word# -> Vector a -> IO (Vector a)
take len (Vector _ mvec)
 = do   return  $ Vector len 
                $ UM.unsafeTake (I# (word2Int# len)) mvec
{-# INLINE take #-}


-- | O(1). Unsafely convert from an Unboxed vector.
--
--   You promise not to access the source vector again.
fromUnboxed :: Unbox a => U.Vector a -> IO (Vector a)
fromUnboxed vec
 = do   let !(I# len)   = U.length vec
        mvec            <- U.unsafeThaw vec
        return $ Vector (int2Word# len) mvec
{-# INLINE fromUnboxed #-}


-- | O(1). Unsafely convert to an Unboxed vector.
--
--   You promise not to modify the source vector again.
toUnboxed :: Unbox a => Vector a -> IO (U.Vector a)
toUnboxed (Vector _ mvec)
 =      U.unsafeFreeze mvec
{-# INLINE toUnboxed #-}

