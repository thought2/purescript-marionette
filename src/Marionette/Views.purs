module Marionette.Views
  ( eventlessRenderEngine
  , module Exp
  , noRenderEngine
  )
  where

import Prelude

import Effect.Class.Console (log)
import Marionette.Types (RenderEngine)
import Marionette.Views.Commander (KeyInputConfig, KeyboardUserInput, PureCompleter, Surface, TextInputConfig, defaultKeyInputConfig, defaultTextInputConfig) as Exp

eventlessRenderEngine :: forall sta msg. { clearScreen :: Boolean } -> (sta -> String) -> RenderEngine msg sta
eventlessRenderEngine opts view =
  { onInit: pure unit
  , onState: \sta _ -> maybeClear <* (log $ view sta)
  , onFinish: maybeClear
  }
  where
  maybeClear = when opts.clearScreen (log eraseScreen)

noRenderEngine :: forall msg sta. RenderEngine msg sta
noRenderEngine =
  { onInit: pure unit
  , onState: \_ _ -> pure unit
  , onFinish: pure unit
  }

---

eraseScreen :: String
eraseScreen = "\x1b" <> "[2J"