// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/catalog.dart';
import '../model/catalog_item.dart';
import '../primitives/constants.dart';
import 'basic_catalog_widgets/audio_player.dart' as audio_player_item;
import 'basic_catalog_widgets/button.dart' as button_item;
import 'basic_catalog_widgets/card.dart' as card_item;
import 'basic_catalog_widgets/check_box.dart' as check_box_item;
import 'basic_catalog_widgets/choice_picker.dart' as choice_picker_item;
import 'basic_catalog_widgets/column.dart' as column_item;
import 'basic_catalog_widgets/date_time_input.dart' as date_time_input_item;
import 'basic_catalog_widgets/divider.dart' as divider_item;
import 'basic_catalog_widgets/icon.dart' as icon_item;
import 'basic_catalog_widgets/image.dart' as image_item;
import 'basic_catalog_widgets/list.dart' as list_item;
import 'basic_catalog_widgets/modal.dart' as modal_item;
import 'basic_catalog_widgets/row.dart' as row_item;
import 'basic_catalog_widgets/slider.dart' as slider_item;
import 'basic_catalog_widgets/tabs.dart' as tabs_item;
import 'basic_catalog_widgets/text.dart' as text_item;
import 'basic_catalog_widgets/text_field.dart' as text_field_item;
import 'basic_catalog_widgets/video.dart' as video_item;

// 'genui with logic' widgets
import 'usecases/logic_2048.dart' as Logic2048;
import 'usecases/logic_anagram.dart' as LogicAnagram;
import 'usecases/logic_battleship.dart' as LogicBattleship;
import 'usecases/logic_birth_chart.dart' as LogicBirthChart;
import 'usecases/logic_bmi.dart' as LogicBmi;
import 'usecases/logic_calculator.dart' as LogicCalculator;
import 'usecases/logic_chess.dart' as LogicChess;
import 'usecases/logic_codebreaker.dart' as LogicCodebreaker;
import 'usecases/logic_color_picker.dart' as LogicColorPicker;
import 'usecases/logic_connect4.dart' as LogicConnect4;
import 'usecases/logic_countdown.dart' as LogicCountdown;
import 'usecases/logic_currency.dart' as LogicCurrency;
import 'usecases/logic_dice.dart' as LogicDice;
import 'usecases/logic_flashcards.dart' as LogicFlashcards;
import 'usecases/logic_gradient_colors.dart' as LogicGradientColors;
import 'usecases/logic_gravity.dart' as LogicGravity;
import 'usecases/logic_guess_number.dart' as LogicGuessNumber;
import 'usecases/logic_handwriting.dart' as LogicHandwriting;
import 'usecases/logic_hangman.dart' as LogicHangman;
import 'usecases/logic_math_trainer.dart' as LogicMathTrainer;
import 'usecases/logic_memory_game.dart' as LogicMemoryGame;
import 'usecases/logic_minesweeper.dart' as LogicMinesweeper;
import 'usecases/logic_password_gen.dart' as LogicPasswordGen;
import 'usecases/logic_piano.dart' as LogicPiano;
import 'usecases/logic_poll_vote.dart' as LogicPollVote;
import 'usecases/logic_pomodoro.dart' as LogicPomodoro;
import 'usecases/logic_quiz_card.dart' as LogicQuizCard;
import 'usecases/logic_reaction_time.dart' as LogicReactionTime;
import 'usecases/logic_reversi.dart' as LogicReversi;
import 'usecases/logic_rps.dart' as LogicRps;
import 'usecases/logic_simon.dart' as LogicSimon;
import 'usecases/logic_snakes_ladders.dart' as LogicSnakesLadders;
import 'usecases/logic_stopwatch.dart' as LogicStopwatch;
import 'usecases/logic_sudoku.dart' as LogicSudoku;
import 'usecases/logic_tarot.dart' as LogicTarot;
import 'usecases/logic_tetris.dart' as LogicTetris;
import 'usecases/logic_tic_tac_toe.dart' as LogicTicTacToe;
import 'usecases/logic_tip_calculator.dart' as LogicTipCalculator;
import 'usecases/logic_todo_list.dart' as LogicTodoList;
import 'usecases/logic_trivia.dart' as LogicTrivia;
import 'usecases/logic_unit_converter.dart' as LogicUnitConverter;
import 'usecases/logic_wheel_picker.dart' as LogicWheelPicker;
import 'usecases/logic_wordle.dart' as LogicWordle;
import 'basic_functions.dart';

/// A collection of basic catalog items that can be used to build simple
/// interactive UIs.
abstract final class BasicCatalogItems {
  BasicCatalogItems._();

  /// A UI element for playing audio content.
  ///
  /// This typically includes controls like play/pause, seek, and volume.
  static final CatalogItem audioPlayer = audio_player_item.audioPlayer;

  /// An interactive button that triggers an action when pressed.
  ///
  /// Conforms to Material Design guidelines for elevated buttons.
  static final CatalogItem button = button_item.button;

  /// A Material Design card, a container for related information and
  /// actions.
  ///
  /// Often used to group content visually.
  static final CatalogItem card = card_item.card;

  /// A checkbox that allows the user to toggle a boolean state.
  static final CatalogItem checkBox = check_box_item.checkBox;

  /// A layout widget that arranges its children in a vertical
  /// sequence.
  static final CatalogItem column = column_item.column;

  /// A widget for selecting a date and/or time.
  static final CatalogItem dateTimeInput = date_time_input_item.dateTimeInput;

  /// A thin horizontal line used to separate content.
  static final CatalogItem divider = divider_item.divider;

  /// An icon.
  static final CatalogItem icon = icon_item.icon;

  /// A UI element for displaying image data from a URL or other
  /// source.
  static final CatalogItem image = image_item.image;

  /// A scrollable list of child widgets.
  ///
  /// Can be configured to lay out items linearly.
  static final CatalogItem list = list_item.list;

  /// A modal overlay that slides up from the bottom of the screen.
  ///
  /// Used to present a set of options or a piece of content requiring user
  /// interaction.
  static final CatalogItem modal = modal_item.modal;

  /// A widget allowing the user to select one or more options from a
  /// list.
  static final CatalogItem choicePicker = choice_picker_item.choicePicker;

  /// A layout widget that arranges its children in a horizontal
  /// sequence.
  static final CatalogItem row = row_item.row;

  /// A slider control for selecting a value from a range.
  static final CatalogItem slider = slider_item.slider;

  /// A set of tabs for navigating between different views or
  /// sections.
  static final CatalogItem tabs = tabs_item.tabs;

  /// A block of styled text.
  static final CatalogItem text = text_item.text;

  /// An input field where the user can enter text.
  static final CatalogItem textField = text_field_item.textField;

  /// A UI element for playing video content.
  ///
  /// This typically includes controls like play/pause, seek, and volume.
  static final CatalogItem video = video_item.video;

  static final String basicCatalogRules = _basicCatalogRules;

  /// Creates a basic catalog without items that require additional data.
  ///
  /// This is useful for the app, that do not work with images, audio or video.
  static Catalog asNoAssetCatalog({
    List<String> systemPromptFragments = const [],
  }) => asCatalog(
    systemPromptFragments: systemPromptFragments,
  ).copyWithout(itemsToRemove: [audioPlayer, image, video]);

  /// Creates a catalog with all basic catalog items.
  ///
  /// Some items (audioPlayer, image, video) require additional data to be
  /// properly displayed. If the app does not work with such data, use
  /// [asNoAssetCatalog] instead.

  /// Interactive 'genui with logic' widgets.
  static final List<CatalogItem> logicCatalogItems = [
    Logic2048.Logic2048.catalogItem,
    LogicAnagram.LogicAnagram.catalogItem,
    LogicBattleship.LogicBattleship.catalogItem,
    LogicBirthChart.LogicBirthChart.catalogItem,
    LogicBmi.LogicBmi.catalogItem,
    LogicCalculator.LogicCalculator.catalogItem,
    LogicChess.LogicChess.catalogItem,
    LogicCodebreaker.LogicCodebreaker.catalogItem,
    LogicColorPicker.LogicColorPicker.catalogItem,
    LogicConnect4.LogicConnect4.catalogItem,
    LogicCountdown.LogicCountdown.catalogItem,
    LogicCurrency.LogicCurrency.catalogItem,
    LogicDice.LogicDice.catalogItem,
    LogicFlashcards.LogicFlashcards.catalogItem,
    LogicGradientColors.LogicGradientColors.catalogItem,
    LogicGravity.LogicGravity.catalogItem,
    LogicGuessNumber.LogicGuessNumber.catalogItem,
    LogicHandwriting.LogicHandwriting.catalogItem,
    LogicHangman.LogicHangman.catalogItem,
    LogicMathTrainer.LogicMathTrainer.catalogItem,
    LogicMemoryGame.LogicMemoryGame.catalogItem,
    LogicMinesweeper.LogicMinesweeper.catalogItem,
    LogicPasswordGen.LogicPasswordGen.catalogItem,
    LogicPiano.LogicPiano.catalogItem,
    LogicPollVote.LogicPollVote.catalogItem,
    LogicPomodoro.LogicPomodoro.catalogItem,
    LogicQuizCard.LogicQuizCard.catalogItem,
    LogicReactionTime.LogicReactionTime.catalogItem,
    LogicReversi.LogicReversi.catalogItem,
    LogicRps.LogicRps.catalogItem,
    LogicSimon.LogicSimon.catalogItem,
    LogicSnakesLadders.LogicSnakesLadders.catalogItem,
    LogicStopwatch.LogicStopwatch.catalogItem,
    LogicSudoku.LogicSudoku.catalogItem,
    LogicTarot.LogicTarot.catalogItem,
    LogicTetris.LogicTetris.catalogItem,
    LogicTicTacToe.LogicTicTacToe.catalogItem,
    LogicTipCalculator.LogicTipCalculator.catalogItem,
    LogicTodoList.LogicTodoList.catalogItem,
    LogicTrivia.LogicTrivia.catalogItem,
    LogicUnitConverter.LogicUnitConverter.catalogItem,
    LogicWheelPicker.LogicWheelPicker.catalogItem,
    LogicWordle.LogicWordle.catalogItem,
  ];

  static Catalog asCatalog({List<String> systemPromptFragments = const []}) {
    return Catalog(
      [
        audioPlayer,
        button,
        card,
        checkBox,
        column,
        dateTimeInput,
        divider,
        icon,
        image,
        list,
        modal,
        choicePicker,
        row,
        slider,
        tabs,
        text,
        textField,
        video,
        ...logicCatalogItems,
      ],
      functions: BasicFunctions.all,
      catalogId: basicCatalogId,
      systemPromptFragments: [basicCatalogRules, ...systemPromptFragments],
    );
  }
}

/// The text content of basic_catalog_rules.txt.
const String _basicCatalogRules = r'''
**REQUIRED PROPERTIES:** You MUST include ALL required properties for every component, even if they are inside a template or will be bound to data.
- For 'Text', you MUST provide 'text'. If dynamic, use { "path": "..." }.
- For 'Image', you MUST provide 'url'. If dynamic, use { "path": "..." }.
- For 'Button', you MUST provide 'action'.
- For 'TextField', 'CheckBox', etc., you MUST provide 'label'.

**EXAMPLES:**

1. Create a surface:
```json
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "main",
    "catalogId": "https://a2ui.org/specification/v0_9/basic_catalog.json",
    "sendDataModel": true
  }
}
```

2. Update components:
```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "main",
    "components": [
      {
        // The root component MUST have id "root"
        "id": "root",
        "component": "Column",
        "justify": "start",
        "children": [
          "headerText",
          "content"
        ]
      }
    ]
  }
}
```

**IMPORTANT:**
- One of the components sent in one of the `updateComponents` MUST have id "root", or nothing will be displayed.
- Do NOT nest `components` inside `createSurface`. Use `updateComponents` to add components to a surface.
- `createSurface` ONLY sets up the surface (ID and catalog). It does NOT take content.
- To show a UI, you typically send a `createSurface` message (if the surface doesn't exist), followed by an `updateComponents` message.
''';
