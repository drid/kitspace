import Color
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import List exposing (..)
import Signal exposing (..)
import Text exposing (..)
import Task exposing (..)
import Http
import Window
import Debug
import Json.Decode exposing (..)
import Graphics.Input exposing (..)
import CustomGraphics exposing (..)
import Html

type alias BoardInfo =
    { name        : String
    , folder      : String
    , description : String
    , author      : String
    , version     : String
    , site        : String
    , license     : String
    }

boardDecoder : Decoder BoardInfo
boardDecoder =
    object7 BoardInfo
        ("name"        := string)
        ("folder"      := string)
        ("description" := string)
        ("author"      := string)
        ("version"     := string)
        ("site"        := string)
        ("license"     := string)

boardMB : Signal.Mailbox (List BoardInfo)
boardMB = Signal.mailbox []

boardJsonUrl = "boards.json"

port getBoards : Task Http.Error ()
port getBoards = Http.get (list boardDecoder) boardJsonUrl
                    `Task.andThen` Signal.send boardMB.address


buttonMB : Signal.Mailbox ()
buttonMB = Signal.mailbox ()

dim = {thumb = {w = 300, h = 225, capH = 30}}

boardImage w h folder =
    image w h ("boards/" ++ folder ++ "/images/thumb.png")

thumb info =
    let txt = centered
        <| Text.style
            { defaultStyle | height <- Just 16
                           , bold   <- True
                           , color  <- Color.rgb 55 55 55
            }
        <| fromString info.folder
        w = dim.thumb.w + 32
        h = dim.thumb.h + dim.thumb.capH + 32
        img height = container w height middle
                <| flow down
                    [ boardImage dim.thumb.w dim.thumb.h info.folder
                    , container dim.thumb.w dim.thumb.capH middle txt
                    ]

        hover = layers
            [ roundedRect w h 10 (Color.rgb 200 200 200)
            , img h
            ]
    in customButton (message buttonMB.address ()) (img h) hover hover

boardView w h boards =
    let thumbs    = List.map thumb boards
        thumbRows = List.map row [0..nRows]
        nPerRow   = max 1 (w // (dim.thumb.w + 32))
        nRows     = ceiling (toFloat (length thumbs) / toFloat nPerRow)
        row n     = take nPerRow (drop (n * nPerRow) thumbs)
        rows = flow down <| List.map (flow right) thumbRows
    in container w h midTop rows

searchBarView w h =
        layers
            [ collage w 100 [rect (toFloat w) 120 |> filled (Color.rgb 0x40 0x40 0x40)]
            , flow right
                [ spacer 20 1
                , flow down
                    [ spacer 0 20
                    , image 198 70 "images/logo.png"
                    ]
                ]
            ]

view (w,h) boards =
    flow down
        [ searchBarView w 64
        , spacer 1 20
        , boardView w (h - 64 - 20) boards
        ]

main : Signal Element
main = Signal.map2 view Window.dimensions boardMB.signal
