{-# LANGUAGE Trustworthy #-}
{-# LANGUAGE CPP, NoImplicitPrelude #-}
{-# OPTIONS_HADDOCK hide #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  GHC.Unicode
-- Copyright   :  (c) The University of Glasgow, 2003
-- License     :  see libraries/base/LICENSE
--
-- Maintainer  :  cvs-ghc@haskell.org
-- Stability   :  internal
-- Portability :  non-portable (GHC extensions)
--
-- Implementations for the character predicates (isLower, isUpper, etc.)
-- and the conversions (toUpper, toLower).  The implementation uses
-- libunicode on Unix systems if that is available.
--
-----------------------------------------------------------------------------

module GHC.Unicode (
        isAscii, isLatin1, isControl,
        isAsciiUpper, isAsciiLower,
        isPrint, isSpace,  isUpper,
        isLower, isAlpha,  isDigit,
        isOctDigit, isHexDigit, isAlphaNum,
        toUpper, toLower, toTitle,
        wgencat
    ) where

import GHC.Base
import GHC.Char        (chr)
import GHC.Real
import GHC.Num

-- | Selects the first 128 characters of the Unicode character set,
-- corresponding to the ASCII character set.
isAscii                 :: Char -> Bool
isAscii c               =  c <  '\x80'

-- | Selects the first 256 characters of the Unicode character set,
-- corresponding to the ISO 8859-1 (Latin-1) character set.
isLatin1                :: Char -> Bool
isLatin1 c              =  c <= '\xff'

-- | Selects ASCII lower-case letters,
-- i.e. characters satisfying both 'isAscii' and 'isLower'.
isAsciiLower :: Char -> Bool
isAsciiLower c          =  c >= 'a' && c <= 'z'

-- | Selects ASCII upper-case letters,
-- i.e. characters satisfying both 'isAscii' and 'isUpper'.
isAsciiUpper :: Char -> Bool
isAsciiUpper c          =  c >= 'A' && c <= 'Z'

-- | Selects control characters, which are the non-printing characters of
-- the Latin-1 subset of Unicode.
isControl               :: Char -> Bool

-- | Selects printable Unicode characters
-- (letters, numbers, marks, punctuation, symbols and spaces).
isPrint                 :: Char -> Bool

-- | Returns 'True' for any Unicode space character, and the control
-- characters @\\t@, @\\n@, @\\r@, @\\f@, @\\v@.
isSpace                 :: Char -> Bool
-- isSpace includes non-breaking space
-- The magic 0x377 isn't really that magical. As of 2014, all the codepoints
-- at or below 0x377 have been assigned, so we shouldn't have to worry about
-- any new spaces appearing below there. It would probably be best to
-- use branchless ||, but currently the eqLit transformation will undo that,
-- so we'll do it like this until there's a way around that.
isSpace c
  | uc <= 0x377 = uc == 32 || uc - 0x9 <= 4 || uc == 0xa0
  | otherwise = iswspace (ord c)
  where
    uc = fromIntegral (ord c) :: Word

-- | Selects upper-case or title-case alphabetic Unicode characters (letters).
-- Title case is used by a small number of letter ligatures like the
-- single-character form of /Lj/.
isUpper                 :: Char -> Bool

-- | Selects lower-case alphabetic Unicode characters (letters).
isLower                 :: Char -> Bool

-- | Selects alphabetic Unicode characters (lower-case, upper-case and
-- title-case letters, plus letters of caseless scripts and modifiers letters).
-- This function is equivalent to 'Data.Char.isLetter'.
isAlpha                 :: Char -> Bool

-- | Selects alphabetic or numeric digit Unicode characters.
--
-- Note that numeric digits outside the ASCII range are selected by this
-- function but not by 'isDigit'.  Such digits may be part of identifiers
-- but are not used by the printer and reader to represent numbers.
isAlphaNum              :: Char -> Bool

-- | Selects ASCII digits, i.e. @\'0\'@..@\'9\'@.
isDigit                 :: Char -> Bool
isDigit c               =  (fromIntegral (ord c - ord '0') :: Word) <= 9

-- We use an addition and an unsigned comparison instead of two signed
-- comparisons because it's usually faster and puts less strain on branch
-- prediction. It likely also enables some CSE when combined with functions
-- that follow up with an actual conversion.

-- | Selects ASCII octal digits, i.e. @\'0\'@..@\'7\'@.
isOctDigit              :: Char -> Bool
isOctDigit c            =  (fromIntegral (ord c - ord '0') :: Word) <= 7

-- | Selects ASCII hexadecimal digits,
-- i.e. @\'0\'@..@\'9\'@, @\'a\'@..@\'f\'@, @\'A\'@..@\'F\'@.
isHexDigit              :: Char -> Bool
isHexDigit c            =  isDigit c ||
                           (fromIntegral (ord c - ord 'A')::Word) <= 5 ||
                           (fromIntegral (ord c - ord 'a')::Word) <= 5

-- | Convert a letter to the corresponding upper-case letter, if any.
-- Any other character is returned unchanged.
toUpper                 :: Char -> Char

-- | Convert a letter to the corresponding lower-case letter, if any.
-- Any other character is returned unchanged.
toLower                 :: Char -> Char

-- | Convert a letter to the corresponding title-case or upper-case
-- letter, if any.  (Title case differs from upper case only for a small
-- number of ligature letters.)
-- Any other character is returned unchanged.
toTitle                 :: Char -> Char

-- -----------------------------------------------------------------------------
-- Implementation with the supplied auto-generated Unicode character properties
-- table

-- Regardless of the O/S and Library, use the functions contained in WCsubst.c

isAlpha    c = iswalpha (ord c)
isAlphaNum c = iswalnum (ord c)
isControl  c = iswcntrl (ord c)
isPrint    c = iswprint (ord c)
isUpper    c = iswupper (ord c)
isLower    c = iswlower (ord c)

toLower c = chr (towlower (ord c))
toUpper c = chr (towupper (ord c))
toTitle c = chr (towtitle (ord c))

-- TODO: Most of the following should be verified to see if compatible with GHC
foreign import java unsafe "@static java.lang.Character.isLetter"
  iswalpha :: Int -> Bool

-- TODO: Inconsistent with GHC
foreign import java unsafe "@static java.lang.Character.isLetterOrDigit"
  iswalnum :: Int -> Bool

foreign import java unsafe "@static java.lang.Character.isISOControl"
  iswcntrl :: Int -> Bool

-- TODO: Inconsistent with GHC
foreign import java unsafe "@static java.lang.Character.isSpaceChar"
  iswspace :: Int -> Bool

foreign import java unsafe "@static ghcvm.base.Utils.isPrintableChar"
  iswprint :: Int -> Bool

foreign import java unsafe "@static java.lang.Character.isLowerCase"
  iswlower :: Int -> Bool

-- TODO: Inconsistent with GHC
foreign import java unsafe "@static java.lang.Character.isUpperCase"
  iswupper :: Int -> Bool

foreign import java unsafe "@static java.lang.Character.toLowerCase"
  towlower :: Int -> Int

foreign import java unsafe "@static java.lang.Character.toUpperCase"
  towupper :: Int -> Int

foreign import java unsafe "@static java.lang.Character.toTitleCase"
  towtitle :: Int -> Int

foreign import java unsafe "@static java.lang.Character.getType"
  wgencat :: Int -> Int
