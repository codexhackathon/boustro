module Server where

import Signal as S
import Model exposing (TextPart)

serverUrl : String
serverUrl = "http://boustro.com/"

textList : List TextPart
textList = [ { title = "My Lost City", path = "my-lost-city-fitzgerald.txt" }
           , { title = "A Room of one's own", path = "room-of-ones-own.txt" }
           , { title = "Les Chants de Maldoror", path = "chants.txt" }
           , { title = "История Русской Революции", path = "trotsky.txt" }
           ]

fileName : S.Mailbox String
fileName = S.mailbox "my-lost-city-fitzgerald.txt"

textContent : S.Mailbox String
textContent = S.mailbox ""
