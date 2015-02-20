import List as L
import Array
import Signal as S
import Graphics.Element (Element, empty)
import UI (..)
import Model (..)
import Utils
import Typography
import Debug (log)

stringToModelState : String -> ViewDimensions -> ModelState
stringToModelState str viewDimensions =
    let text = strToWordArray str
        wordIndex = 0
        (page, wc) = Typography.typesetPage text wordIndex viewDimensions
        view = textScene page viewDimensions
        _ = log "wc" <| toString wc
    in TextModel { fullText  = text
                 , wordIndex = wordIndex
                 , pageWordCount = wc
                 , view = view
                 }

updateView : ModelState -> ViewDimensions -> ModelState
updateView modelState viewDimensions = case modelState of
    EmptyModel -> EmptyModel
    MenuModel menuModel ->
        let view = menuScene menuModel viewDimensions
        in MenuModel { menuModel | view <- view }
    TextModel textModel ->
        let (page, wc) = Typography.typesetPage textModel.fullText textModel.wordIndex viewDimensions
            view = textScene page viewDimensions
        in TextModel { textModel | pageWordCount <- wc
                                 , view <- view }

appState : Signal (ViewDimensions, ModelState)
appState = let input = (S.map Input userInput)
               viewChange = (S.map ViewChange currentViewDimensions)
               emptyState = (viewHelper (300, 300), EmptyModel)
           in S.foldp updateState emptyState <| S.merge input viewChange

updateState : Update -> (ViewDimensions, ModelState) -> (ViewDimensions, ModelState)
updateState update (viewDimensions, modelState) =
    case update of
        ViewChange newViewDims -> (newViewDims, updateView modelState newViewDims)
        Input (SetText str) ->
            let newModelState = stringToModelState str viewDimensions
            in (viewDimensions, newModelState)
        Input (Gesture Next) ->
            let newModel = case modelState of
                    TextModel textModel ->
                        let textLength = Array.length textModel.fullText
                            newWordIndex = textModel.wordIndex + textModel.pageWordCount
                            idx = if newWordIndex < textLength then newWordIndex else textModel.wordIndex
                            (page, wc) = Typography.typesetPage textModel.fullText idx viewDimensions
                            view = textScene page viewDimensions
                            _ = log "new word index" <| toString idx
                            _ = log "old word index" <| toString textModel.wordIndex
                            _ = log "word count" <| toString textModel.pageWordCount
                        in TextModel { textModel | wordIndex <- idx
                                                 , pageWordCount <- wc
                                                 , view <- view }
                    otherwise -> modelState
            in (viewDimensions, newModel)
        Input (Gesture NoGesture) -> (viewDimensions, modelState)
        Input (Gesture Prev) ->
            let newModel = case modelState of
                    TextModel textModel ->
                        let pwc = Typography.prevPageWordCount textModel.fullText textModel.wordIndex viewDimensions
                            idx = max (textModel.wordIndex - pwc) 0
                            (page, wc) = Typography.typesetPage textModel.fullText idx viewDimensions
                            view = textScene page viewDimensions
                        in TextModel { textModel | wordIndex <- idx
                                                 , pageWordCount <- wc
                                                 , view <- view }
                    otherwise -> modelState
            in (viewDimensions, newModel)

main : Signal Element
main = S.map (modelToView << snd) appState
