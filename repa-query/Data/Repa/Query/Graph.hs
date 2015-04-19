
module Data.Repa.Query.Graph
        ( -- * Queries
          Query         (..)

          -- * Graphs
        , Graph         (..)
        , Node          (..)

          -- * Flow sources
        , Source        (..)

          -- * Flow operators
        , FlowOp        (..)

          -- * Scalar expressions
        , Exp           (..)
        , Val           (..)
        , Lit           (..)
        , ScalarOp      (..))
where
import Data.Repa.Query.Exp
import qualified Data.Repa.Query.Format as Format


---------------------------------------------------------------------------------------------------
-- | A query consisting of an graph, and the name of the output flow.
data Query a nF bV nV
        = Query 
        { queryOutput           :: nF                   -- ^ Name of output flow.
        , queryResultDelim      :: Format.Delim         -- ^ How to delimit fields in output.
        , queryResultFields     :: [Format.FieldBox]    -- ^ Format of fields in output.
        , queryGraph            :: Graph a nF bV nV     -- ^ Query operator graph.
        }

deriving instance (Show a, Show nF, Show bV, Show nV)
        => Show (Query a nF bV nV)


---------------------------------------------------------------------------------------------------
-- | Operator graph for a query.
data Graph a nF bV nV
        = Graph [Node a nF bV nV]
        deriving Show


---------------------------------------------------------------------------------------------------
-- | A single node in the graph.
data Node a nF bV nV
        -- | A flow source.
        = NodeSource    (Source a nF)

        -- | A flow operator.
        | NodeOp        (FlowOp a nF bV nV)
        deriving Show


---------------------------------------------------------------------------------------------------
-- | Flow sources.
data Source a nF
        -- | Source complete rows from a flat file.
        = SourceFile
        { sourceAnnot           :: a                    -- ^ Annotation.
        , sourceFilePath        :: FilePath             -- ^ Path to file.
        , sourceDelim           :: Format.Delim         -- ^ Delimitor for elements.
        , sourceFields          :: [Format.FieldBox]    -- ^ Format of fields.
        , sourceOutput          :: nF                   -- ^ Output flow.
        }


        -- | Source complete rows from a table.
        | SourceTable
        { sourceAnnot           :: a                    -- ^ Annotation.
        , sourceFilePath        :: FilePath             -- ^ Path to table.
        , sourceDelim           :: Format.Delim         -- ^ Delimitor for elements.
        , sourceFields          :: [Format.FieldBox]    -- ^ Format of fields.
        , sourceOutput          :: nF                   -- ^ Output flow.
        }


deriving instance (Show a, Show nF) 
        => Show (Source a nF)


---------------------------------------------------------------------------------------------------
-- | Flow operators.
data FlowOp a nF bV nV
        -- | Apply a function to every element of a flow.
        = FopMapI
        { fopInput              :: nF                   -- ^ Input flow.
        , fopOutput             :: nF                   -- ^ Output flow.
        , fopFun                :: Exp a bV nV          -- ^ Worker function.
        }

        -- | Keep only the elements that match the given predicate.
        | FopFilterI
        { fopInput              :: nF                   -- ^ Input flow.
        , fopOutput             :: nF                   -- ^ Output flow.
        , fopFun                :: Exp a bV nV          -- ^ Filter predicate.
        }

        -- | Fold all the elements of a flow, 
        --   yielding a new flow of a single result element.
        | FopFoldI      
        { fopInput              :: nF                   -- ^ Input flow.
        , fopOutput             :: nF                   -- ^ Output flow.
        , fopFun                :: Exp a bV nV          -- ^ Worker function.
        , fopNeutral            :: Exp a bV nV          -- ^ Neutral value of worker.
        }       

        -- | Segmented fold of the elements of a flow.
        | FopFoldsI     
        { fopInputLens          :: nF                   -- ^ Input flow for lengths.
        , fopInputElems         :: nF                   -- ^ Input flow for elements.
        , fopOutput             :: nF                   -- ^ Output flow.
        , fopFun                :: Exp a bV nV          -- ^ Worker function.
        , fopNeutral            :: Exp a bV nV          -- ^ Neutral value of worker.
        }

        -- | Group sequences of values by the given predicate,
        --   returning lengths of each group.
        | FopGroupsI
        { fopInput              :: nF                   -- ^ Input flow.
        , fopOuput              :: nF                   -- ^ Output flow.
        , fopFun                :: Exp a bV nV          -- ^ Comparison function for groups.
        }
        deriving Show

