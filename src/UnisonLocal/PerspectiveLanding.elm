module UnisonLocal.PerspectiveLanding exposing (..)

import Code.Config exposing (Config)
import Code.Definition.Doc as Doc
import Code.Definition.Readme as Readme
import Code.Definition.Reference exposing (Reference)
import Code.DefinitionSummaryTooltip as DefinitionSummaryTooltip
import Code.FullyQualifiedName as FQN exposing (FQN)
import Code.Namespace exposing (Namespace(..))
import Code.Perspective as Perspective exposing (Perspective)
import Code.Syntax as Syntax
import Html exposing (Html, a, article, div, h2, header, p, section, span, strong, text)
import Html.Attributes exposing (class, href, id, rel, target)
import Lib.Util as Util
import RemoteData exposing (RemoteData(..))
import UI
import UI.Button as Button exposing (Button)
import UI.Click as Click
import UI.Icon as Icon


type alias Model =
    { foldToggles : Doc.DocFoldToggles
    , definitionSummaryTooltip : DefinitionSummaryTooltip.Model
    }


init : Model
init =
    { foldToggles = Doc.emptyDocFoldToggles
    , definitionSummaryTooltip = DefinitionSummaryTooltip.init
    }


type Msg
    = OpenReference Reference
    | ToggleDocFold Doc.FoldId
    | Find
    | DefinitionSummaryTooltipMsg DefinitionSummaryTooltip.Msg


type OutMsg
    = OpenDefinition Reference
    | ShowFinderRequest
    | None


update : Config -> Msg -> Model -> ( Model, Cmd Msg, OutMsg )
update config msg model =
    case msg of
        OpenReference r ->
            ( model, Cmd.none, OpenDefinition r )

        Find ->
            ( model, Cmd.none, ShowFinderRequest )

        ToggleDocFold fid ->
            ( { model | foldToggles = Doc.toggleFold model.foldToggles fid }, Cmd.none, None )

        DefinitionSummaryTooltipMsg tMsg ->
            let
                ( definitionSummaryTooltip, tCmd ) =
                    DefinitionSummaryTooltip.update config tMsg model.definitionSummaryTooltip
            in
            ( { model | definitionSummaryTooltip = definitionSummaryTooltip }
            , Cmd.map DefinitionSummaryTooltipMsg tCmd
            , None
            )



-- VIEW


container : List (Html msg) -> Html msg
container content =
    article [ id "perspective-landing" ]
        [ section
            [ id "perspective-landing-content" ]
            content
        ]


viewLoading : Html msg
viewLoading =
    container
        [ div
            [ class "loading" ]
            [ UI.loadingPlaceholderRow
            , UI.loadingPlaceholderRow
            ]
        ]


viewError : FQN -> String -> Html msg
viewError fqn message =
    container
        [ div
            [ class "perspective-landing-error" ]
            [ header [] [ Icon.view Icon.warn, text ("Error loading " ++ FQN.toString fqn) ]
            , p [] [ text message ]
            ]
        ]


viewEmptyState : Html msg -> List (Html msg) -> Button msg -> Html msg
viewEmptyState title description cta =
    let
        fauxItem =
            div [ class "faux-empty-state-item" ]
                [ UI.loadingPlaceholderRow
                , UI.loadingPlaceholderRow
                ]
    in
    container
        [ section [ class "perspective-landing-empty-state" ]
            [ section
                [ class "content" ]
                (h2 [] [ title ]
                    :: description
                    ++ [ fauxItem
                       , fauxItem
                       , section [ class "actions" ] [ Button.view cta ]
                       ]
                )
            ]
        ]


viewEmptyStateRoot : Html Msg
viewEmptyStateRoot =
    viewEmptyState
        (span [ class "unison-local" ] [ text "Your ", span [ class "context" ] [ text "Local" ], text " Unison Codebase" ])
        [ p [] [ text "Browse, search, read docs, open definitions, and explore your local codebase." ]
        , p []
            [ text "Check out "
            , a [ class "unison-share", href "https://share.unison-lang.org", rel "noopener", target "_blank" ] [ strong [] [ text "Unison Share" ] ]
            , text " for community projects."
            ]
        ]
        (Button.iconThenLabel Find Icon.search "Find Definition"
            |> Button.emphasized
            |> Button.medium
        )


viewEmptyStateNamespace : FQN -> Html Msg
viewEmptyStateNamespace fqn =
    let
        fqn_ =
            FQN.toString fqn
    in
    viewEmptyState
        (FQN.view fqn)
        [ p [] [ text "Browse, search, read docs, open definitions, and explore" ] ]
        (Button.iconThenLabel Find Icon.search ("Find Definitions in " ++ fqn_)
            |> Button.emphasized
            |> Button.medium
        )


view : Perspective -> Model -> Html Msg
view perspective model =
    case perspective of
        Perspective.Root _ ->
            viewEmptyStateRoot

        Perspective.Namespace { fqn, details } ->
            case details of
                NotAsked ->
                    viewLoading

                Loading ->
                    viewLoading

                Success (Namespace _ _ { readme }) ->
                    case readme of
                        Just r ->
                            let
                                syntaxConfig =
                                    Syntax.linkedWithTooltipConfig
                                        (OpenReference >> Click.onClick)
                                        (DefinitionSummaryTooltip.tooltipConfig
                                            DefinitionSummaryTooltipMsg
                                            model.definitionSummaryTooltip
                                        )
                            in
                            container
                                [ div [ class "perspective-landing-readme" ]
                                    [ header [ class "title" ] [ Icon.view Icon.doc, text "README" ]
                                    , Readme.view
                                        syntaxConfig
                                        ToggleDocFold
                                        model.foldToggles
                                        r
                                    ]
                                ]

                        Nothing ->
                            viewEmptyStateNamespace fqn

                Failure error ->
                    viewError fqn (Util.httpErrorToString error)
