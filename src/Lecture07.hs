{-# OPTIONS_GHC -fno-warn-orphans -fno-warn-unused-imports #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE MultiParamTypeClasses #-}
module Lecture07 where

import Lecture07.Money
import Data.Semigroup
import Data.Foldable

{-
  07: Классы типов

  - ad-hoc polymorphism (overloading)
  - классы типов
    - Синтаксис
    - Eq, Show
    - default implementation
    - minimal implementation (Ord)
- Примеры
  - :i Num, Floating, Integral
  - :i Enum, Bounded
  - superclass
  - subclass
    - instance ClassA where
      f :: a -> a -- type signatures
      f = undefined
  - Dictionary passing (как работают тайпклассы)
    - https://mpickering.github.io/posts/2018-03-20-recordsvstypeclasses.html
    - http://www.haskellforall.com/2012/05/scrap-your-type-classes.html
    - https://homepages.inf.ed.ac.uk/wadler/papers/class/class.ps
  - Расширения
    - https://limperg.de/ghc-extensions/#basic-classes
      - FlexibleContexts
      - FlexibleInstances
      - TypeSynonymInstances
        - instance Class [Char] where
        - instance Class String where
      - MultiParamTypeClasses
        - class Class a b where ...
        - https://qfpl.io/posts/orphans-and-fundeps/
      - UndecidableInstances
      - OverlappingInstances
      - IncoherentInstances
      - ConstrainedClassMethods 
  - deriving (Eq, Show)
    - https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/compiler/generic-deriving
-}

-- <Задачи для самостоятельного решения>

{-
  Реализуйте инстанс Show для Expr:

    - Number 0 ~> 0
    - Plus (Number 0) (Number 3) ~> 0 + 3
    - Abs (Plus (Number 0) (Number 3)) ~> |0 + 3|
    - UnaryMinus (Plus (Mult (Number 2) (Number 2)) (Number 2)) ~> -((2 * 2) + 2)
-}
data Expr
  = Number Integer
  | Plus Expr Expr
  | Minus Expr Expr
  | Mult Expr Expr
  | UnaryMinus Expr
  | Abs Expr
  deriving Eq

instance Show Expr where
  show = \case
    Plus e e' -> binOp e e' " + "
    Minus e e' -> binOp e e' " - "
    Mult e e' -> binOp e e' " * "
    UnaryMinus e -> "-" ++ ensureBr e
    Abs e -> "|" ++ show e ++ "|"
    e -> ensureBr e
    where
      ensureBr (Number n) = show n
      ensureBr e = "(" ++ show e ++ ")"
      binOp e e' op = concat [ensureBr e, op, ensureBr e']

{-
  Реализуйте instance Semigroup для вектора:
-}
newtype Vec a = Vec { unVec :: [a] } deriving (Eq, Show)
instance (Num a) => Semigroup (Vec a) where
  Vec a <> Vec b = Vec $ map (\(a, b) -> a + b) $ zip a b

{-
  Реализуйте instance Semigroup для типа для логгирования:
-}
newtype LogEntry = LogEntry { unLogEntry :: String } deriving (Eq, Show)
instance Semigroup LogEntry where
  u <> v = LogEntry $ unLogEntry u ++ unLogEntry v

{-
  В `src/Lecture07/Money.hs` определены:
    - тип `Money a` для денег
    - типы `USD` и `RUB` для представления валют
    - конструкторы `mkDollars` и `mkRubbles`

  Реализуйте инстансы Semigroup для Money a.
-}
instance Semigroup (Money USD) where 
  u <> v = mkDollars $ getMoney u + getMoney v

instance Semigroup (Money RUB) where 
  u <> v = mkRubbles $ getMoney u + getMoney v

{-
  Реализуйте инстанс Functor для ExactlyOne
-}
data ExactlyOne a = ExactlyOne a deriving (Eq, Show)
instance Functor ExactlyOne where
  fmap f (ExactlyOne a) = ExactlyOne $ f a

{-
  Реализуйте инстанс Functor для `Maybe a`
-}
data Maybe' a = Just' a | Nothing' deriving (Eq, Show)
instance Functor Maybe' where
  fmap f x = case x of 
    Nothing' -> Nothing'
    Just' a -> Just' $ f a

{-
  Реализуйте инстанс Functor для `List a`
-}
data List a = Nil | Cons a (List a) deriving (Eq, Show)
instance Functor List where
  fmap f x = case x of
    Nil -> Nil
    Cons x xs -> Cons (f x) (fmap f xs) 

{-
  `FileTree a` — тип для представления дерева файловой системы.

  Параметр `a` позволяет населять файлы произвольным значением.
-}
data FileTree a
  = Empty
  | File String a
  | Dir String [FileTree a]
  deriving (Eq, Show)

{-
  `FileInfo` — тип с информацией о файле: содержит его размер и дату последнего изменения. 
-}
data FileInfo = FileInfo
  { size :: Integer
  , modified :: String
  } deriving (Eq, Show)

{-
  Тогда мы можем строить деревья типа `FileTree FileInfo` и работать с ними.

  Например ниже определены функции для вычисления суммы всех размеров файлов в дереве
  и нахождения последней даты обновления файла в дереве.
-}

-- Пример использования Foldable для суммирования размера файла
fileSizeOfTree :: FileTree FileInfo -> Integer
fileSizeOfTree = getSum . foldMap (\FileInfo{..} -> Sum size)
-- С помощью расширения RecordWildCards     ^
-- мы раскрываем record и получаем доступ к полю size   ^^^^

-- Нужно для `latestModified`. В обычном коде так делать не надо.
instance Bounded [Char] where
  minBound = ""
  maxBound = "99999"

-- А здесь используется для нахождения даты последнего изменения
latestModified :: FileTree FileInfo -> String
latestModified = getMax . foldMap (\FileInfo{..} -> Max modified)

{-
  Чтобы функции выше работали, необходимо
  реализовать instance Foldable для FileTree:
-}

instance Foldable FileTree where
  foldMap _ Empty = mempty
  foldMap f (File _ a) = f a
  foldMap f (Dir _ content) = mconcat $ map (foldMap f) content

{-
  В этом задании вам необходимо придумать и написать иерархию исключений
  с помощью классов типов на основе набора требований:

  1. Базовый класс Exception с возможностью получения сообщения ошибки
  2. Класс для API ошибок. Должен уметь возвращать
    - ошибку в формате JSON
    - уровень severity (debug, info, error, warn)
  3. Класс для ошибок при работе с базой данных.
    - дополнительно возвращает сообщение об ошибке от базы данных
  4. Класс для ошибок доменной логики
    - дополнительно возвращает контекс с данными

  Реализовывать инстансы не нужно.
-}

data Severity = Debug | Info | Warning | Error deriving (Eq, Show)
data Json = 
  JNull
  | JStr String
  | JBool Bool
  | JDouble Double
  | JInt Integer
  | JArr [Json]
  | JDict [(String, Json)]
  deriving (Show, Eq)

class Exception a where
  getErrMessage :: a -> String

class Exception a => APIException a where
  toJson :: a -> Json
  getSeverity :: a -> Severity


class Exception a => DBException a where
  getDBErrMessage :: a -> String


class Exception a => DomainException a b where
  getContext :: a -> b


-- </Задачи для самостоятельного решения>