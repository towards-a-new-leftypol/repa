module Data.Repa.Query.Source.Builder
        ( -- * Queries
          Query (..)

          -- * Flows
        , Flow  (..)
        , makeFlow, takeFlow

          -- * Values
        , Value (..)

          -- * Query builder monad.
        , Q, Config (..)
        , runQ
        , newFlow
        , addNode)
where
import qualified Data.Repa.Query.Format                 as F
import qualified Data.Repa.Query.Graph                  as G
import qualified Data.Repa.Query.Transform.Namify       as N
import Control.Monad


---------------------------------------------------------------------------------------------------
-- | A complete query.
data Query
        = forall a. Query   
        { queryOutDelim :: F.Delim
        , queryOutField :: F.Field a
        , queryOutFlow  :: Flow    a }

deriving instance Show Query


---------------------------------------------------------------------------------------------------
-- | Flows of the given element type.
--
--   Internally, this is a wrapper around a flow variable name.
data Flow a
        = Flow     String
        deriving Show


-- | Wrap a flow name with its phantom type.
makeFlow :: String -> Flow a
makeFlow name = Flow name


-- | Unwrap a flow name.
takeFlow :: Flow a -> String
takeFlow (Flow name) = name
     

---------------------------------------------------------------------------------------------------
-- | Scalar values of the given type.
--
--   Internally, this is a wrapper around an expression that
--   computes the value.
data Value a
        = Value   (G.Exp () () Int)
        deriving Show


---------------------------------------------------------------------------------------------------
-- | Query builder config.
data Config
        = Config
        { -- | Path to data root, containing meta-data for used tables.
          configRoot    :: FilePath }
        deriving Show


-- | Run a query builder.
--   
--   The provided config contains the path to the meta data needed by
--   operators like `sourceTable`.
--   
runQ    :: Config               -- ^ Query builder config.
        -> Q  Query             -- ^ Computation to produce query AST.
        -> IO (Either String (G.Query () String String String))

runQ config mkQuery
 = do   
        -- Run the query builder to get the AST / operator graph.
        (state', eQuery)
                <- evalQ mkQuery
                $  State { sConfig      = config
                         , sNodes       = []
                         , sGenFlow     = 0
                         , sGenScalar   = 0 }

        case eQuery of
         Left err       -> return $ Left err
         Right (Query delim field (Flow vFlow))
          -> do 
                -- The nodes added to the state use debruijn indices for variables,
                -- but we'll convert them to named variables while we're here.
                --
                -- This match should always succeed because the namifier only returns
                -- Nothing when there are out of scope variables. However, the only 
                -- way we can construct a (Q (Flow a)) is via the EDSL code, which
                -- doesn't provide a way of producing expressions with free indices.
                --
                let Just q  
                        = N.namify N.mkNamifierStrings 
                        $ G.Query vFlow delim 
                                (F.flattens field)
                                (G.Graph (sNodes state'))
                return $ Right q
 

 ---------------------------------------------------------------------------------------------------
-- | State used when building the operator graph.
data State  
        = State
        { -- | Query builder config
          sConfig       :: Config

          -- | We strip the type information from the nodes so we can put
          --   them all in the graph. Flows are named with strings, while
          --   scalars are named with debruijn indices.
        , sNodes        :: [G.Node () String () Int]

          -- | Counter to generate fresh flow variable names.
        , sGenFlow      :: Int

          -- | Counter to generate fresh scalar variable names.
        , sGenScalar    :: Int }
        deriving Show
        

-- | Allocate a new node name.
newFlow :: Q (Flow a)
newFlow 
 = do   ix      <- getsQ sGenFlow
        modifyQ $ \s -> s { sGenFlow = ix + 1}
        return  $ makeFlow $ "f" ++ show ix


-- | Add a new node to the graph
addNode :: G.Node () String () Int -> Q ()
addNode n
 = do   modifyQ $ \s -> s { sNodes = sNodes s ++ [n] }
        return ()


---------------------------------------------------------------------------------------------------
-- | Query building monad.
--
--   The usual combination of state, exception and IO.
--
data Q a
        = Q (State -> IO (State, Either String a))

instance Functor Q where
 fmap  = liftM

instance Applicative Q where
 (<*>) = ap
 pure  = return

instance Monad Q where
 return !x
  = Q (\s -> return $ (s, Right x))
 {-# INLINE return #-}

 (>>=)  !(Q f) !g
  = Q (\s -> do
        (s', r)   <- f s
        case r of
         Left  err -> return $ (s, Left err)
         Right y   -> case g y of
                        Q h     -> h s')
 {-# INLINE (>>=) #-}


-- | Evaluate a query builder computation.
evalQ  :: Q a -> State -> IO (State, Either String a)
evalQ (Q f) s = f s
{-# INLINE evalQ #-}


-- | Get an field of the builder state.
getsQ  :: (State -> a) -> Q a
getsQ f 
 = Q (\s -> return (s, Right $ f s))
{-# INLINE getsQ #-}


-- | Modify the builder state.
modifyQ :: (State -> State) -> Q ()
modifyQ f 
 = Q (\s -> return (f s, Right ()))
{-# INLINE modifyQ #-}


