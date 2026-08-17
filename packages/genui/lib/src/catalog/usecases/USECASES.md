# GenUI: Top-50 Use-Case Widget Program

Goal: for each of the top AI use cases, ship a purpose-built genui
`CatalogItem` widget tuned for the best way to *visualize* that result type,
plus a per-platform "intent / deeplink" resolver so the result can be acted on
(open mail app, deep-link into a mobile app, render HTML, email, etc.).

Coded under the `Sk8er22/genui` fork (branch `linux-support`), in
`packages/genui/lib/src/catalog/usecases/`, each use case = ONE small self-
contained widget file + one example + one row here.

## How a use case becomes a widget

Every widget follows the genui `CatalogItem` contract (verified in
`lib/src/model/catalog_item.dart`):
- `string name` (the JSON `component:` discriminator, e.g. `ListBigImage`)
- `Schema dataSchema` (typed JSON props the LLM fills in)
- `widgetBuilder(CatalogItemContext)` -> Widget
- `exampleData` (JSON doc so the model can learn the shape)

Dispatch is type-first: the LLM answers "what widget best shows this result?"
and genui renders it. We do NOT fight the model; we give it a rich explicit
menu (this registry is also the prompt appendix fed to gemma).

## Type dispatch (renderer rules)
| Result type | Widget(s) provided |
|---|---|
| list (big image) | `ListBigImage` — full-bleed image, title, desc, cell row |
| list (cell)    | `ListCell` — compact rows, tap -> event |
| grid           | `GridMedia` — N-col image grid |
| markdown       | `MarkdownView` — render MD (flutter_markdown_plus dep already present) |
| html           | `HtmlView` — render safe HTML (on web/dekstop); sanitized |
| chart/data     | `ChartView` + `StatCard` (bar/line/pie; kpi card) |
| timeline       | `TimelineView` — events on a line |
| map/location   | `MapView` — OSM/here:44 tile (leaflet-style), with intent to open native map |
| email intent   | `EmailIntent` card — compose/send via deeplink (mailto / url_launcher) |
| deeplink/intent| per-platform resolver (below) |
| code           | `CodeBlock` — syntax-highlighted, copy button |
| audio/video    | existing `audio_player` / `video` |
| table          | `DataTable` — sortable grid |
| form           | existing `text_field` / `choice_picker` / `date_time_input` |
| json           | `JsonTree` — collapsible tree view |

## Per-platform intent / deeplink resolver
`UsecaseIntent` maps an intent name + a payload URI to the platform-standard
way to accomplish it. A single widget (`IntentButton`) renders a button that,
on tap, calls the resolver, which returns the right mechanism per platform:

| Platform | Resolver behavior |
|---|---|
| iOS   | `canLaunch`/`launchUrl` (UIApplication.openURL), universal links |
| Android | Intent (ACTION_VIEW, intent:// URIs) / Iaancode deep links |
| macos | `url_launcher` -> default handler (x-callback-url, mailto:...) |
| linux | `xdg-open` / url_launcher -> default app |
| windows | `url_launcher` -> ShellExecute default handler |
| web   | `window.open` / `<a href>` |

Intent catalog (first slice): `emailCompose`, `sms`, `tel`, `openMap`,
`openUrl`, `share`, `copy`, `calendarEvent`, `openInApp(universal link)`,
`runCommand(desktop only)`, `saveFile`.

## Logic widgets (genui with logic)
Read-only renderers + intents cover "show me X". A second tier adds **stateful
logic widgets**: full interactive mini-apps with real local rules, rendered as
a single `CatalogItem`. The LLM only picks the component + params; the logic
lives in Dart, so it's deterministic and testable. Interactive actions flow
out through genui's existing `dispatchEvent` (and back via `dispatchEvent` ->
system handlers in the host app).

Small, self-contained logic widgets (each under ~200-400 LOC, pure Dart + the
`logic/` helper lib so the rules are unit-testable without Flutter):
- `ChessBoard`   — full legal-move chess (move gen, check/checkmate/stalemate,
                   promotion, PGN export; taps via dispatchEvent). Uses a tiny
                   pure-Dart `chess_core` helper (no package dep needed).
- `TicTacToe`    — 3x3 vs another human / eval + win detection.
- `Calculator`   — RPN/infix keypad, chain math.
- `QuizCard`     — a question with options + scoring + feedback.
- `PollVote`     — pick an option, cast a vote, show results bar.
- `TodoList`     — add/check/delete items, persist via handler event.
- `Flashcards`   — flip card, next/prev deck.
- `Stopwatch/Timer` — start/stop/reset ticks.
- `SignaturePad` — capture drawn signature as a path -> PNG event.
- `ColorPicker`  — HSV sliders, returns hex.
- `Birthday/Countdown` — date math to now.

`CatalogItem.name` collision guard: prefix logic widgets with `Logic*`
(e.g. `LogicChessBoard`) so the model can't confuse them with `Card`/`ListCell`.

## Work loop (parallel, per-use-case git worktrees)
Each use case is a card. Cards ship independently via a worktree loop:
1. `git worktree add ../wcNN` off `linux-support`
2. implement ONE widget + schema + example (small, testable)
3. `flutter analyze` + widget test (widget builds with sample JSON)
4. commit to that worktree's branch, push, merge back to `linux-support`
5. loop next card (N parallel workers, each owns distinct worktrees)

Worker card types (both tiers feed the same loop):
- tier R (read-only render) — ListBigImage, ListCell, GridMedia, MarkdownView,
  CodeBlock, JsonTree, DataTable, StatCard, ChartView, Timeline, MapView,
  HtmlView, EmailIntent
- tier L (logic) — ChessBoard, TicTacToe, Calculator, QuizCard, PollVote,
  TodoList, Flashcards, Stopwatch, SignaturePad, ColorPicker, Countdown

## Card list — first 50 (input type -> widget -> intent)
01 list of places        -> ListBigImage       -> openMap
02 list of products      -> GridMedia          -> openUrl
03 list of tasks         -> ListCell           -> runCommand/opentinApp
04 events/timeline       -> TimelineView       -> calendarEvent
05 meeting/agenda        -> TimelineView       -> calendarEvent
06 decision/compare      -> DataTable          -> share
07 explain markdown      -> MarkdownView      -> copy
08 code sample           -> CodeBlock          -> copy
09 open web page         -> HtmlView           -> openUrl
10 newsletter            -> MarkdownView       -> emailCompose
11 email draft           -> EmailIntent        -> emailCompose
12 text rewrite          -> MarkdownView       -> copy
13 translate             -> Text               -> copy
14 summarize doc         -> MarkdownView       -> copy
15 extract action items  -> ListCell           -> calendarEvent
16 key-value facts       -> StatCard           -> share
17 JSON/view data        -> JsonTree           -> copy
18 table data            -> DataTable          -> exportCsv
19 KPI dashboard         -> StatCard           -> saveFile
20 charts               -> ChartView          -> saveFile
21 weather/hourly        -> ChartView          -> openUrl
22 forecast weekly       -> ChartView          -> openMap
23 addresses             -> MapView            -> openMap
24 directions/routes     -> MapView            -> openInApp(maps)
25 stock watch           -> StatCard+Chart     -> openUrl
26 wikipedia article     -> MarkdownView       -> openUrl
27 recipe                -> ListBigImage       -> share
28 playbook/steps        -> TimelineView       -> saveFile
29 FAQ/accordion         -> ListCell           -> openUrl
30 checklist             -> ListCell           -> copy
31 comparison table      -> DataTable          -> share
32 signup/form           -> form widgets       -> openUrl
33 payment/checkout      -> form + stat        -> openInApp
34 video tutorial        -> video              -> openUrl
35 podcast/audio         -> audio_player       -> openInApp
36 gallery/imgs          -> GridMedia          -> openUrl
37 profile/person        -> ListBigImage       -> emailCompose
38 org/repo health       -> StatCard+Chart     -> openUrl
39 changelog/release     -> TimelineView       -> openUrl
40 API response          -> JsonTree           -> copy
41 log/traces            -> JsonTree+Code      -> saveFile
42 error/debug report    -> CodeBlock          -> copy
43 security scan         -> DataTable          -> saveFile
44 architecture diagram  -> CodeBlock(Mermaid) -> saveFile
45 sql query             -> CodeBlock          -> copy
46 prompt template       -> CodeBlock          -> copy
47 course outline        -> TimelineView       -> saveFile
48 flashcards/quiz       -> ListCell/Card      -> share
49 citations/sources     -> MarkdownView+List  -> openUrl
50 datetime picker       -> date_time_input    -> calendarEvent

## Build order (little steps, dependencies first)
A. `UsecaseIntent` resolver + `IntentButton` + per-platform table (foundation)
B. shared `use_case_shell.dart` (card scaffold, scroll)
C. 10 read-only render widgets: ListBigImage, ListCell, GridMedia,
   MarkdownView, CodeBlock, JsonTree, DataTable, StatCard, ChartView, Timeline
D. interactive: MapView, HtmlView, EmailIntent
E. wire the registry + prompt appendix into the demo chat
F. per use-case polish + tests (each card)
