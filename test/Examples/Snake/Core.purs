module Test.Examples.Snake.Core
  ( Board(..)
  , Goodie(..)
  , LevelSpec(..)
  , Maze(..)
  , MazeItem(..)
  , Snake(..)
  , Tile(..)
  , Vec
  , boardToMaze
  , findSnake
  , findSnakeDirection
  , mkBoard
  , parseLevelSpec
  , printBoard
  ) where

import Prelude

import Data.Array as Arr
import Data.Array.NonEmpty (NonEmptyArray)
import Data.Array.NonEmpty as NEA
import Data.Foldable (foldM)
import Data.Generic.Rep (class Generic)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype, un)
import Data.Show.Generic (genericShow)
import Data.Traversable (traverse)
import Data.Tuple (Tuple(..))
import Data.Unfoldable (unfoldr)
import Test.Examples.Snake.CharGrid as CharGrid
import Test.Examples.Snake.Direction (Direction)
import Test.Examples.Snake.Direction as Dir
import Test.Examples.Snake.Grid (Grid)
import Test.Examples.Snake.Grid as Grid
import Test.Examples.Snake.Vector (Vector)
import Unsafe.Coerce (unsafeCoerce)

--- Vec 

type Vec = Vector Int


--- Tile

data Tile
  = Tile_SnakeHead
  | Tile_SnakeBody
  | Tile_Goodie
  | Tile_Wall
  | Tile_Floor

derive instance Generic Tile _

derive instance Eq Tile

instance Show Tile where
  show = genericShow

--

newtype Board = Board (Grid Tile)

derive instance Newtype Board _

data Snake = Snake Vec (Array Vec)

newtype Maze = Maze (Grid MazeItem)

data MazeItem = Maze_Wall | Maze_Floor

newtype Goodie = Goodie Vec

data LevelSpec = LevelSpec Snake Maze Direction

---

type Size = Vec



-- f :: forall m. Env m -> m (Array Goodie)
-- f = unfold

-- getFreeBoards :: Size -> Board -> Array Vec
-- getFreeBoards size = positionsInSize size <#> Arr.filter (\x -> )

-- oneOf :: Env m -> NonEmptyArray a -> m a
-- oneOf = unsafeCoerce 1


parseLevelSpecFromBoard :: Board -> Maybe LevelSpec
parseLevelSpecFromBoard board = ado
  snake <- findSnake board
  let maze = boardToMaze board
  direction <- findSnakeDirection board
  in LevelSpec snake maze direction

parseLevelSpec :: String -> Maybe LevelSpec
parseLevelSpec = parseBoard >=> parseLevelSpecFromBoard

-- positionsInSize :: Vec -> Array Vec
-- positionsInSize (Vec sizex sizey) = do
--   x <- Arr.range 0 (sizex - 1)
--   y <- Arr.range 0 (sizey - 1)
--   pure $ Vec x y

mazeItemToTile :: MazeItem -> Tile
mazeItemToTile = case _ of
  Maze_Wall -> Tile_Wall
  Maze_Floor -> Tile_Floor

findFreeSpots :: Board -> Maybe (NonEmptyArray Vec)
findFreeSpots = un Board
  >>> Grid.toMap
  >>> Map.toUnfoldable
  >>> Arr.mapMaybe (\(Tuple k v) -> if v == Tile_Floor then Just k else Nothing)
  >>> NEA.fromArray

mkBoard :: Maze -> Snake -> Goodie -> Maybe Board
mkBoard (Maze maze) (Snake snakeHead snakeTail) (Goodie goodie) =
  maze
    <#> mazeItemToTile
    # (\grid -> Grid.insert snakeHead Tile_SnakeHead grid)
    >>= (\grid -> foldM (\g v -> Grid.insert v Tile_SnakeBody g) grid snakeTail)
    >>= (\grid -> Grid.insert goodie Tile_Goodie grid)
    <#> Board

findSnake :: Board -> Maybe Snake
findSnake (Board grid) = ado
  snakeHead <- Grid.findIndex (_ == Tile_SnakeHead) grid
  let snakeTail = unfoldr next snakeHead
  in Snake snakeHead snakeTail
  where
  next :: Vec -> Maybe (Tuple Vec Vec)
  next vec = ado
    nextVec <- (Dir.toVector <$> Dir.directionsClockwise) #
      Arr.find \dirVec -> Grid.lookup (vec + dirVec) grid == Just Tile_SnakeBody
    in Tuple nextVec nextVec

findSnakeDirection :: Board -> Maybe Direction
findSnakeDirection (Board grid) = do
  snakeHead <- Grid.findIndex (_ == Tile_SnakeHead) grid
  dir <- Dir.directionsClockwise #
    Arr.find \dir -> Grid.lookup (snakeHead + Dir.toVector dir) grid == Just Tile_SnakeBody
  pure $ dir

boardToMaze :: Board -> Maze
boardToMaze = un Board
  >>> map case _ of
    Tile_Wall -> Maze_Wall
    _ -> Maze_Floor
  >>> Maze

parseChar :: Char -> Maybe Tile
parseChar = case _ of
  '#' -> Just Tile_Wall
  'O' -> Just Tile_SnakeBody
  '+' -> Just Tile_SnakeHead
  '_' -> Just Tile_Floor
  _ -> Nothing

parseBoard :: String -> Maybe Board
parseBoard str = do
  charBoard <- CharGrid.fromString str
  board <- traverse parseChar charBoard
  pure $ Board board

printTile :: Tile -> Char
printTile = case _ of
  Tile_Wall -> '#'
  Tile_SnakeBody -> 'O'
  Tile_SnakeHead -> '+'
  Tile_Goodie -> 'x'
  Tile_Floor -> ' '

printBoard :: Board -> String
printBoard = un Board >>> map printTile >>> CharGrid.toString