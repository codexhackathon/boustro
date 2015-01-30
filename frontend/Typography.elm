module Typography where

import String
import Html (Html, Attribute, span, div, text, toElement, fromElement, p)
import Html.Attributes (style, classList)
import Graphics.Element (widthOf)
import List as L
import Array
import Array (Array)
import Text
import Color
import Maybe
import Dict
import Dict (Dict)
import Model (AppState)
import Utils

type Item = Box Int Html
          | Spring Int Int Int
          | Penalty Float Float Bool

textStyle = { typeface = [ "Georgia", "serif" ]
            , height   = Just 16
            , color    = Color.black
            , bold     = False
            , italic   = False
            , line     = Nothing
            }

strToWordArray : String -> Array String
strToWordArray str = let txtLines = L.filter (not << String.isEmpty) << String.lines <| str
                         paragraphPrefix str = "¶ " ++ str
                         singleParText = String.join " " << L.map paragraphPrefix <| txtLines
                     in  Array.fromList <| String.words singleParText

boustro : Html -> (List Html, Bool) -> (List Html, Bool)
boustro h (hs, reverseState) =
    let classes = classList [ ("reverse", reverseState) ]
        nextH = div [ classes ] [ h ]
        nextLineState = not reverseState
    in (nextH :: hs, nextLineState)

toPage : List Html -> Html
toPage = div [] << L.reverse << fst << L.foldl boustro ([], False)

wordsPerLine : List Item -> Int
wordsPerLine = L.length << L.filter (not << isSpring)

wordCount : List (List Item) -> List Item -> Int
wordCount hs is = (L.sum <| L.map wordsPerLine hs) + L.length is

typesetPage : Int -> AppState -> (Html, Int)
typesetPage wordIndex appState =
    let lineWidth = appState.viewDims.textWidth
        numLines = appState.viewDims.linesPerPage
        wordArray = appState.fullText
        maxWords = numLines * lineWidth // 35 + wordIndex
        wordList = Array.toList <| Array.slice wordIndex maxWords wordArray
        itemList = wordListToItems wordList
        (hs, lastLineItems) = L.foldl (justifyItems numLines lineWidth) ([], []) itemList
        page = toPage << L.take numLines << L.reverse <| unjustifyLine lastLineItems :: L.map (justifyLine lineWidth) hs
        wc = wordCount hs lastLineItems
    in (page, wc)

typesetPrevPage : Int -> AppState -> (Html, Int)
typesetPrevPage wordIndex appState =
    let lineWidth = appState.viewDims.textWidth
        numLines = appState.viewDims.linesPerPage
        wordArray = appState.fullText
        maxWords = max 0 <| wordIndex - numLines * lineWidth // 35
        wordList = L.reverse << Array.toList <| Array.slice maxWords wordIndex wordArray
        itemList = wordListToItems wordList
        (hs, lastLineItems) = L.foldl (justifyItems numLines lineWidth) ([], []) itemList
        nhs = L.map L.reverse hs
        nlli = L.reverse lastLineItems
        page = toPage << L.reverse <| L.take numLines << L.reverse <| unjustifyLine nlli :: L.map (justifyLine lineWidth) nhs
        wc = wordCount hs lastLineItems
    in (page, wc)

strWidth : String -> Int
strWidth str = let txtElement = Text.rightAligned << Text.style textStyle
                                                  <| Text.fromString str
               in widthOf txtElement

wordListToItems : List String -> List Item
wordListToItems words =
        let classes = classList [ ("maintext", True) ]
            toItem word = Box (strWidth word) (p [classes] [ text word ])
        in L.intersperse (Spring 4 2 2) <| L.map toItem words

itemWidth : Item -> Int
itemWidth i = case i of
    Box w _      -> w
    Spring w _ _ -> w
    otherwise    -> 0

itemHtml : Item -> Html
itemHtml item =
    let spanStyle : Int -> Attribute
        spanStyle w = style [ ("width", toString w ++ "px")
                            , ("display", "inline-block") ]
    in case item of
            Box w h   -> span [spanStyle w] [h]
            Spring w _ _ -> span [spanStyle w] []
            otherwise -> div [] []

itemListWidth : List Item -> Int
itemListWidth = L.sum << L.map itemWidth

isSpring : Item -> Bool
isSpring item = case item of
    Spring _ _ _ -> True
    otherwise    -> False

toSpring : Int -> Item
toSpring w = Spring w 0 0

justifyLine : Int -> List Item -> Html
justifyLine lineWidth is =
    let cleanList = L.filter (not << isSpring) is
        widthToAdd = lineWidth - itemListWidth cleanList
        numberSprings = L.length cleanList - 1
        baseSpringWidth = widthToAdd // numberSprings
        remainingWidth = rem widthToAdd numberSprings
        widthsToAdd = L.repeat remainingWidth (baseSpringWidth + 1) ++ L.repeat (numberSprings - remainingWidth) baseSpringWidth
        springs = L.map toSpring widthsToAdd
        items = Utils.interleave cleanList springs
    in p [] << L.map itemHtml <| items

unjustifyLine : List Item -> Html
unjustifyLine = p [] << L.map itemHtml << L.reverse

justifyItems : Int -> Int -> Item -> (List (List Item), List Item) -> (List (List Item), List Item)
justifyItems numLines lineWidth item (hs, is) =
    if | L.length hs == numLines -> (hs, [])
       | otherwise -> let currentWidth = itemListWidth (item :: is)
                      in if | currentWidth > lineWidth ->
                               let nextLine = L.reverse is
                                   nextIs = if | isSpring item -> []
                                               | otherwise -> [item]
                               in (nextLine :: hs, nextIs)
                         | otherwise -> (hs, item :: is)
