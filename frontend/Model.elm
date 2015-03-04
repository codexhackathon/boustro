module Model where

import Array
import List as L
import String
import Graphics.Element (Element, empty)
import Json.Decode
import Json.Decode ((:=))

type alias TextPart = { title : String
                      , path  : String
                      }

jsonToTextPartlist : String -> List TextPart
jsonToTextPartlist json =
    let result = Json.Decode.decodeString textPartListDecoder json
        tupleToTextPart (title, path) = { title = title
                                        , path  = path }
    in case result of
        Ok ts -> L.map tupleToTextPart ts
        Err _ -> []

textPartListDecoder : Json.Decode.Decoder (List (String, String))
textPartListDecoder = Json.Decode.list textPartDecoder

textPartDecoder : Json.Decode.Decoder (String, String)
textPartDecoder = Json.Decode.object2 (,)
                        ("title" := Json.Decode.string)
                        ("path" := Json.Decode.string)

type Model = EmptyModel
           | MenuModel MenuModelData
           | TextModel TextModelData

type alias TextModelData = { fullText       : Array.Array String
                           , wordIndex      : Int
                           , pageWordCount  : Int
                           , view           : Element
                           }

type alias MenuModelData = { texts : List TextPart
                           , view : Element
                           }

strToWordArray : String -> Array.Array String
strToWordArray str = let txtLines = L.filter (not << String.isEmpty) << String.lines <| str
                         paragraphPrefix str = "¶ " ++ str
                         singleParText = String.join " " << L.map paragraphPrefix <| txtLines
                     in  Array.fromList <| String.words singleParText

modelToView model = case model of
    EmptyModel -> empty
    MenuModel data -> data.view
    TextModel data -> data.view
