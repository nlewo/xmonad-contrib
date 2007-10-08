-----------------------------------------------------------------------------
-- |
-- Module      :  XMonadContrib.WindowPrompt
-- Copyright   :  Devin Mullins <me@twifkak.com>
--                Andrea Rossato <andrea.rossato@unibz.it>
-- License     :  BSD-style (see LICENSE)
--
-- Maintainer  :  Devin  Mullins <me@twifkak.com>
--                Andrea Rossato <andrea.rossato@unibz.it>
-- Stability   :  unstable
-- Portability :  unportable
--
-- xprompt operations to bring windows to you, and bring you to windows.
--
-----------------------------------------------------------------------------

module XMonadContrib.WindowPrompt
    (
    -- * Usage
    -- $usage 
    windowPromptGoto,
    windowPromptBring
    ) where

import qualified Data.Map as M
import Data.List

import qualified StackSet as W
import XMonad
import Operations (windows)
import XMonadContrib.XPrompt
import XMonadContrib.WindowBringer

-- $usage
-- WindowPrompt brings windows to you and you to windows.
-- That is to say, it pops up a dmenu with window names, in case you forgot
-- where you left your XChat.
--
-- Place in your Config.hs:
--
-- > import XMonadContrib.XPrompt
-- > import XMonadContrib.WindowPrompt
--
-- and in the keys definition:
--
-- > , ((modMask .|. shiftMask, xK_g     ), windowPromptGoto  defaultXPConfig)
-- > , ((modMask .|. shiftMask, xK_g     ), windowPromptBring defaultXPConfig)
--
-- %import XMonadContrib.XPrompt
-- %import XMonadContrib.WindowPrompt
-- %keybind ((modMask .|. shiftMask, xK_g     ), windowPromptGoto  defaultXPConfig)
-- %keybind ((modMask .|. shiftMask, xK_g     ), windowPromptBring defaultXPConfig)

data WindowPrompt = Goto | Bring
instance XPrompt WindowPrompt where 
    showXPrompt Goto  = "Go to window:  "
    showXPrompt Bring = "Bring me here:  "

windowPromptGoto, windowPromptBring :: XPConfig -> X ()
windowPromptGoto  c = doPrompt Goto  c
windowPromptBring c = doPrompt Bring c

-- | Pops open a prompt with window titles. Choose one, and you will be
-- taken to the corresponding workspace.
doPrompt :: WindowPrompt -> XPConfig -> X ()
doPrompt t c = do
  a <- case t of
         Goto  -> return . gotoAction  =<< windowMapWith (W.tag . fst)                     
         Bring -> return . bringAction =<< windowMapWith snd
  wm <- windowMapWith id
  mkXPrompt t c (compList wm) a

    where

      winAction a m    = flip whenJust (windows . a) . flip M.lookup m . unescape   
      gotoAction       = winAction W.greedyView
      bringAction      = winAction bringWindow
      bringWindow w ws = W.shiftWin (W.tag . W.workspace . W.current $ ws) w ws

      compList m s = return . filter (isPrefixOf s) . map (escape . fst) . M.toList $ m

      escape []       = []
      escape (' ':xs) = "\\ " ++ escape xs
      escape (x  :xs) = x : escape xs

      unescape []            = []
      unescape ('\\':' ':xs) = ' ' : unescape xs
      unescape (x:xs)        = x   : unescape xs