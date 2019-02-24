{-# LANGUAGE DataKinds #-}

import Data.Function
import Data.Set

-- DEFINITION 1.1
data Term =
  Var String |
  Appl Term Term |
  Abst String Term deriving (Eq)

instance Show Term where
  show (Var v) = v
  show (Appl t1 (Appl t2 t3)) = show t1 ++ "(" ++ show t2 ++ show t3 ++ ")"
  show (Appl t1 t2) = show t1 ++ show t2
  show (Abst v t) = "(λ" ++ v ++ "." ++ show t ++ ")"

p_example = Appl (Appl (Abst "y" (Appl (Appl (Var "y") (Var "x")) (Abst "x" (Appl (Appl (Var "y") (Abst "y" (Var "z"))) (Var "x"))))) (Var "v")) (Var "w")

-- DEFINIITION 1.5: the LENGTH of term M
lgh :: Term -> Integer
lgh (Var _) = 1
lgh (Appl t1 t2) = ((+) `on` lgh) t1 t2
lgh (Abst _ t) = 1 + lgh t

-- DEFINITION 1.6: term Q contains P
contains :: Term -> Term -> Bool
q `contains` p =
  q == p ||
  (case q of
     (Appl q1 q2) -> (q1 `contains` p) || (q2 `contains` p)
     (Abst v q1) -> (q1 `contains` p) || (Var v == p)
  )

-- DEFINITION 1.10: the FREE VARIABLES of term P
-- intuitively, the FREE VARIABLES are all un-bound variables
-- a variable x is BOUND in P iff P is of the form λx.M
fv :: Term -> Set String
fv p = fv' p empty
  where
    fv' :: Term -> Set String -> Set String
    fv' (Var v) bound = if v `member` bound then empty else singleton v
    --fv' (Appl p1 p2) bound = (union `on` (flip fv' $ bound)) p1 p2
    fv' (Appl p1 p2) bound = union <$> fv' p1 <*> fv' p2 $ bound
    fv' (Abst v p) bound = fv' p (insert v bound)

-- DEFINITION 1.11: SUBSTITUTION
-- [N/x]M is substituting N for every free occurence of x in M
-- this is precisely defined by induction on M
substitute :: Term -> String -> Term -> Term
substitute n x (Var v) =
  if x == v then n                             -- (a)
  else Var v                                   -- (b)
substitute n x (Appl p q) =
  (Appl `on` substitute n x) p q               -- (c)
substitute n x (Abst y p) 
  | y == x = Abst y p                          -- (d)
  | y `notMember` (fv n) || x `notMember` (fv p) =
    Abst y (substitute n x p)                  -- (e)
  | otherwise =
    Abst z (substitute n x $ substitute (Var z) y p) -- (f)
    where
      takenVarNames = (fv n) `union` (fv p)
      z = head $ dropWhile (`member` takenVarNames) (iterate (++"'") y)

-- DEFINITION 1.22: BETA-REDUCTION
-- (λx.M)N -> [N/x]M
beta_reduce :: Term -> Term
beta_reduce (Appl (Abst x m) n) = substitute n x m
beta_reduce p = p

-- DEFINITION 1.24: BETA-NORMAL FORM
beta_normal_form :: Term -> Term
beta_normal_form p = if p == beta_reduce p then p else beta_normal_form $ beta_reduce p 
