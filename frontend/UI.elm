module UI where

import Time (Time, every, second, millisecond, timestamp)
import Maybe as M
import List as L
import Touch
import Signal as S
import Signal ((<~), (~), Signal)
import Utils as U
import Window
import Server
import Debug (log)
import Utils

type alias ViewDimensions = { fullContainerWidth : Int
                            , fullContainerHeight : Int
                            , textWidth : Int
                            , textHeight : Int
                            }
lineHeight = 19

viewHelper : (Int, Int) -> ViewDimensions
viewHelper (w, h) = let a = log "width" w
                    in { fullContainerWidth = w
                    , fullContainerHeight = h
                    , textWidth = min (w - 40) 650
                    , textHeight = (h // lineHeight - 6) * lineHeight
                    }

initialSetupSignal : Signal ()
initialSetupSignal = S.map Utils.toUnit << S.dropRepeats << S.foldp (\x p -> 1) 0 << every <| 10 * millisecond

currentViewDimensions : Signal ViewDimensions
currentViewDimensions = let cues = S.mergeMany [ S.map Utils.toUnit Window.dimensions
                                               , S.map Utils.toUnit initialSetupSignal]
                        in S.sampleOn cues <| viewHelper <~ Window.dimensions

type SwipeDir = Next | Prev | NoSwipe
type UserInput = Swipe SwipeDir
               | SetText String
               | ViewUpdate ViewDimensions

type alias InputData = UserInput

touchDir : List Touch.Touch -> SwipeDir
touchDir ts = let getxOrDefault = M.withDefault 0 << M.map .x
                  firstTouch = getxOrDefault << U.listToMaybe <| ts
                  lastTouch  = getxOrDefault << U.listToMaybe << L.reverse <| ts
                  touchDist : Int
                  touchDist = firstTouch - lastTouch
              in  if | touchDist > 20 -> Prev
                     | touchDist < 20 -> Next
                     | otherwise      -> NoSwipe

type alias Tap = { x : Int, y : Int }

swipe : Signal SwipeDir
swipe = let untappedValue : (Time, Tap, Bool)
            untappedValue = (0, { x = -1, y = -1 }, False)
            doubleTap = S.map (\(x,y,z) -> z) <| S.foldp isDoubleTap untappedValue <| timestamp Touch.taps
            toSwipeDir tap viewDims = if | tap.x < (viewDims.fullContainerWidth // 2 - 10) -> Prev
                                         | tap.x > (viewDims.fullContainerWidth // 2 + 10) -> Next
                                         | otherwise -> NoSwipe
        in  S.sampleOn (U.onFalseTrueTransition doubleTap) <| S.map2 toSwipeDir Touch.taps currentViewDimensions

isDoubleTap : (Time, Tap) -> (Time, Tap, Bool) -> (Time, Tap, Bool)
isDoubleTap (newTapTime, newTap) (oldTapTime, oldTap, wasDoubleTap) =
    let doubleTapMargin : Int
        doubleTapMargin = 80
        maxDoubleTapInteval : Time
        maxDoubleTapInteval = 0.5 * second
    in if | wasDoubleTap -> (newTapTime, newTap, False)
          | newTapTime - oldTapTime < maxDoubleTapInteval &&
              abs (newTap.x - oldTap.x) < doubleTapMargin &&
              abs (newTap.y - oldTap.y) < doubleTapMargin ->
                            (newTapTime, newTap, True)
          | otherwise    -> (newTapTime, newTap, False)