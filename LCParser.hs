module LCParser where

import Data.Char
import Data.Void
import Text.Megaparsec
import Text.Megaparsec.Char
import LCTerm 

type Parser = Parsec Void String

readTermIO :: String -> IO (Maybe Term)
readTermIO t = case parse parseTerm "readTermIO" t of
  Left bundle -> putStrLn (errorBundlePretty bundle) >> return Nothing
  Right term -> return (Just term)

parens :: Parser a -> Parser a
parens = between (char '(') (char ')')
stripParens :: Parser a -> Parser a
stripParens p = stripParensOnly p <|> p
  where
    stripParensOnly :: Parser a -> Parser a
    stripParensOnly p = do
      first <- some (char '(')
      inner <- p
      second <- string (replicate (length first) ')')
      return inner
                
parseTerm :: Parser Term
parseTerm = do
  terms <- some $
    parens (try parseAbst <|> try parseVar) <|>
    (try parseAbst <|> try parseVar)
  return $ foldl1 Appl terms

parseAbst :: Parser Term
parseAbst = stripParens $ do
  _ <- satisfy (\c -> c == 'λ' || c == '\\')
  (Var v) <- parseVar
  _ <- char '.'
  body <- parseTerm
  return $ Abst v body
    
parseVar :: Parser Term
parseVar = stripParens $ do
  base <- letterChar
  primes <- many (char '\'')
  return $ Var (base:primes)
