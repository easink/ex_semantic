module Main exposing (..)

import Html exposing (Html, Attribute, div, h1, input, text)
import Html.Attributes exposing (class, style, placeholder, classList)
import Html.Events exposing (onClick)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Html.Events exposing (onInput)
import Table
import Json.Encode as JE
import Json.Decode as JD exposing (field)


-- import SemanticUI exposing (..)

import SemanticUI.Elements.Button as Button
import SemanticUI.Elements.Icon as Icon
import Debug exposing (log)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- CONSTANTS


socketServer : String
socketServer =
    "ws://localhost:4000/socket/websocket"


room : String
room =
    "room:lobby"



-- MODEL


type alias Model =
    { people : List Person
    , tableState : Table.State
    , query : String
    , phxSocket : Phoenix.Socket.Socket Msg
    }


init : ( Model, Cmd Msg )
init =
    let
        socket =
            Phoenix.Socket.init socketServer
                |> Phoenix.Socket.withDebug
                |> Phoenix.Socket.on "new:msg" room ReceivePersons

        model =
            { people = []
            , tableState = Table.initialSort "Year"
            , query = ""
            , phxSocket = socket
            }
    in
        ( model, Cmd.none )



-- PHOENIX STUFF
-- type alias ChatMessage =
--     { user : String
--     , body : String
--     }
-- userParams : JE.Value
-- userParams =
--     JE.object [ ( "user_id", JE.string "123" ) ]


personMessageDecoder : JD.Decoder Person
personMessageDecoder =
    let
        _ =
            log "Model" 1
    in
        JD.map5 Person
            (field "name" JD.string)
            (field "year" JD.int)
            (field "city" JD.string)
            (field "state" JD.string)
            (field "selected" JD.bool)


presidentsMessageDecoder : JD.Decoder Presidents
presidentsMessageDecoder =
    let
        _ =
            log "Model" 2
    in
        JD.map Presidents
            (field "presidents" (JD.list personMessageDecoder))



-- UPDATE


type Msg
    = SetQuery String
    | SetTableState Table.State
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinChannel
    | LoadData
    | SendMessage
    | ReceivePersons JE.Value
    | ShowJoinedMessage String
    | ShowLeftMessage String
    | ToggleSelected Person


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetQuery newQuery ->
            ( { model | query = newQuery }
            , Cmd.none
            )

        SetTableState newState ->
            ( { model | tableState = newState }
            , Cmd.none
            )

        PhoenixMsg msg ->
            let
                _ =
                    log "Subscription Triggered" msg

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        JoinChannel ->
            let
                channel =
                    Phoenix.Channel.init room

                -- |> Phoenix.Channel.onJoin (always (ShowJoinedMessage room))
                -- |> Phoenix.Channel.onClose (always (ShowLeftMessage room))
                -- |> Phoenix.Channel.withPayload userParams
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.join channel model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        LoadData ->
            let
                _ =
                    log "Model" model
            in
                ( model, Cmd.none )

        SendMessage ->
            let
                -- We'll build our message out as a json encoded object
                -- payload =
                --     (JE.object [ ( "body", JE.string "test payload" ) ])
                -- We prepare to push the message
                push =
                    Phoenix.Push.init "get_presidents" room

                -- |> Phoenix.Push.withPayload payload
                -- We update our `phxSocket` and `phxCmd` by passing this push
                -- into the Phoenix.Socket.push function
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push push model.phxSocket

                _ =
                    log "SendMessage" phxCmd
            in
                -- And we clear out the `newMessage` field, update our model's
                -- socket, and return our Phoenix command
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        ReceivePersons raw ->
            case JD.decodeValue presidentsMessageDecoder raw of
                Ok person ->
                    let
                        _ =
                            log "Person" person.presidents
                    in
                        ( { model | people = person.presidents }
                        , Cmd.none
                        )

                Err error ->
                    ( model, Cmd.none )

        ShowJoinedMessage channelName ->
            ( model, Cmd.none )

        ShowLeftMessage channelName ->
            ( model, Cmd.none )

        ToggleSelected person ->
            ( { model | people = List.map (togglePerson person) model.people }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view { people, tableState, query } =
    let
        lowerQuery =
            String.toLower query

        acceptablePeople =
            List.filter (String.contains lowerQuery << String.toLower << .name) people
    in
        div []
            [ h1 [] [ text "Birthplaces of U.S. Presidents" ]
            , input [ placeholder "Search by Name", onInput SetQuery ] []
            , Table.view config tableState acceptablePeople
            , div []
                [ Button.button
                    (Button.init
                        |> Button.attributes [ onClick LoadData ]
                        |> Button.primary
                        |> Button.icon (Just Icon.Search)
                    )
                    [ text "Load" ]
                , Button.button
                    (Button.init
                        |> Button.attributes [ onClick JoinChannel ]
                        |> Button.icon (Just Icon.Search)
                    )
                    [ text "Join" ]
                , Button.button
                    (Button.init
                        |> Button.attributes [ onClick SendMessage ]
                        |> Button.icon (Just Icon.Search)
                    )
                    [ text "SendMessage" ]
                ]
            ]


config : Table.Config Person Msg
config =
    Table.customConfig
        { toId = .name
        , toMsg = SetTableState
        , columns =
            [ Table.stringColumn "Name" .name
            , Table.intColumn "Year" .year
            , Table.stringColumn "City" .city
            , Table.stringColumn "State" .state
            ]
        , customizations = defaultCustomizations
        }


defaultCustomizations : Table.Customizations Person Msg
defaultCustomizations =
    { tableAttrs = [ class "ui selectable celled table" ]
    , caption = Nothing
    , thead = simpleThead
    , tfoot = Nothing
    , tbodyAttrs = []
    , rowAttrs = simpleRowAttrs
    }



-- simpleRowAttrs : Person -> List (Attribute Msg)
-- simpleRowAttrs person =
--     [ onClick (ToggleSelected person)
--     , (if person.selected then
--         class "positive"
--        else
--         class ""
--       )
--     ]


simpleRowAttrs : Person -> List (Attribute Msg)
simpleRowAttrs person =
    [ onClick (ToggleSelected person)
    , classList [ ( "positive", person.selected ) ]
    ]


simpleThead : List ( String, Table.Status, Attribute msg ) -> Table.HtmlDetails msg
simpleThead headers =
    Table.HtmlDetails [] (List.map simpleTheadHelp headers)


simpleTheadHelp : ( String, Table.Status, Attribute msg ) -> Html msg
simpleTheadHelp ( name, status, onClick ) =
    let
        content =
            case status of
                Table.Unsortable ->
                    [ Html.text name ]

                Table.Sortable selected ->
                    [ Html.text name
                    , if selected then
                        darkGrey "↓"
                      else
                        lightGrey "↓"
                    ]

                Table.Reversible Nothing ->
                    [ Html.text name
                    , lightGrey "↕"
                    ]

                Table.Reversible (Just isReversed) ->
                    [ Html.text name
                    , darkGrey
                        (if isReversed then
                            "↑"
                         else
                            "↓"
                        )
                    ]
    in
        Html.th [ onClick ] content


darkGrey : String -> Html msg
darkGrey symbol =
    Html.span [ style [ ( "color", "#555" ) ] ] [ Html.text (" " ++ symbol) ]


lightGrey : String -> Html msg
lightGrey symbol =
    Html.span [ style [ ( "color", "#ccc" ) ] ] [ Html.text (" " ++ symbol) ]


togglePerson : Person -> Person -> Person
togglePerson triggeredPerson person =
    if triggeredPerson.name == person.name then
        { person | selected = not person.selected }
    else
        person



-- config =
--     Table.config
--         { toId = .name
--         , toMsg = SetTableState
--         , columns =
--             [ Table.stringColumn "Name" .name
--             , Table.intColumn "Year" .year
--             , Table.stringColumn "City" .city
--             , Table.stringColumn "State" .state
--             ]
--         }
-- PEOPLE


type alias Person =
    { name : String
    , year : Int
    , city : String
    , state : String
    , selected : Bool
    }


type alias Presidents =
    { presidents : List Person }



-- presidents : List Person
-- presidents =
--     [ Person "George Washington" 1732 "Westmoreland County" "Virginia"
--     , Person "John Adams" 1735 "Braintree" "Massachusetts"
--     , Person "Thomas Jefferson" 1743 "Shadwell" "Virginia"
--     , Person "James Madison" 1751 "Port Conway" "Virginia"
--     , Person "James Monroe" 1758 "Monroe Hall" "Virginia"
--     , Person "Andrew Jackson" 1767 "Waxhaws Region" "South/North Carolina"
--     , Person "John Quincy Adams" 1767 "Braintree" "Massachusetts"
--     , Person "William Henry Harrison" 1773 "Charles City County" "Virginia"
--     , Person "Martin Van Buren" 1782 "Kinderhook" "New York"
--     , Person "Zachary Taylor" 1784 "Barboursville" "Virginia"
--     , Person "John Tyler" 1790 "Charles City County" "Virginia"
--     , Person "James Buchanan" 1791 "Cove Gap" "Pennsylvania"
--     , Person "James K. Polk" 1795 "Pineville" "North Carolina"
--     , Person "Millard Fillmore" 1800 "Summerhill" "New York"
--     , Person "Franklin Pierce" 1804 "Hillsborough" "New Hampshire"
--     , Person "Andrew Johnson" 1808 "Raleigh" "North Carolina"
--     , Person "Abraham Lincoln" 1809 "Sinking spring" "Kentucky"
--     , Person "Ulysses S. Grant" 1822 "Point Pleasant" "Ohio"
--     , Person "Rutherford B. Hayes" 1822 "Delaware" "Ohio"
--     , Person "Chester A. Arthur" 1829 "Fairfield" "Vermont"
--     , Person "James A. Garfield" 1831 "Moreland Hills" "Ohio"
--     , Person "Benjamin Harrison" 1833 "North Bend" "Ohio"
--     , Person "Grover Cleveland" 1837 "Caldwell" "New Jersey"
--     , Person "William McKinley" 1843 "Niles" "Ohio"
--     , Person "Woodrow Wilson" 1856 "Staunton" "Virginia"
--     , Person "William Howard Taft" 1857 "Cincinnati" "Ohio"
--     , Person "Theodore Roosevelt" 1858 "New York City" "New York"
--     , Person "Warren G. Harding" 1865 "Blooming Grove" "Ohio"
--     , Person "Calvin Coolidge" 1872 "Plymouth" "Vermont"
--     , Person "Herbert Hoover" 1874 "West Branch" "Iowa"
--     , Person "Franklin D. Roosevelt" 1882 "Hyde Park" "New York"
--     , Person "Harry S. Truman" 1884 "Lamar" "Missouri"
--     , Person "Dwight D. Eisenhower" 1890 "Denison" "Texas"
--     , Person "Lyndon B. Johnson" 1908 "Stonewall" "Texas"
--     , Person "Ronald Reagan" 1911 "Tampico" "Illinois"
--     , Person "Richard M. Nixon" 1913 "Yorba Linda" "California"
--     , Person "Gerald R. Ford" 1913 "Omaha" "Nebraska"
--     , Person "John F. Kennedy" 1917 "Brookline" "Massachusetts"
--     , Person "George H. W. Bush" 1924 "Milton" "Massachusetts"
--     , Person "Jimmy Carter" 1924 "Plains" "Georgia"
--     , Person "George W. Bush" 1946 "New Haven" "Connecticut"
--     , Person "Bill Clinton" 1946 "Hope" "Arkansas"
--     , Person "Barack Obama" 1961 "Honolulu" "Hawaii"
--     , Person "Donald Trump" 1946 "New York City" "New York"
--     ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg



-- main =
--     Button.button
--         (Button.init
--             |> Button.primary
--             |> Button.icon (Just Icon.Search)
--         )
--         [ text "Search" ]
