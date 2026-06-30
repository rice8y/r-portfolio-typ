#show: project.with(
  title: "auto-jrubby",
  description: "A Typst package that provides automatic Japanese morphological analysis and furigana (ruby) insertion.",
  date: "2026-01-02",
  updated: "2026-02-20",
  section: "projects",
  toc: false,
  languages: ("Typst", "Rust"),
  links: (
    (label: "GitHub", url: "https://github.com/rice8y/auto-jrubby"),
    (label: "Typst Universe", url: "https://typst.app/universe/package/auto-jrubby/"),
  ),
)

#import "/content/_prelude.typ": *

#strong[auto-jrubby] is a Typst package that provides automatic Japanese morphological analysis and furigana (ruby) insertion.

It leverages a Rust-based WASM plugin to tokenize text using #link("https://github.com/lindera/lindera")[Lindera] (a morphological analysis library) and uses the #link("https://typst.app/universe/package/rubby")[rubby] package to render the furigana.

== Features

- #strong[Automatic Furigana Generation:] Automatically determines readings for Kanji based on context and renders them as ruby text.
- #strong[Smart Okurigana Alignment:] Intelligent handling of mixed Kanji/Hiragana words (e.g., `食べる` is rendered with ruby `た` over `食`, leaving `べる` untouched).
- #strong[Morphological Analysis Table:] Visualize the text structure (Part of Speech, Detailed POS, Readings, Base forms) via a formatted data table.
- #strong[Customizable Styling:] Supports custom ruby sizing and positioning via the `rubby` package backend.
- #strong[Flexible Script Output:] Choose between #strong[Hiragana] (default) or #strong[Katakana] for the ruby text.
- #strong[High Performance:] Powered by a Rust WASM plugin using #strong[Lindera] for fast and accurate tokenization.

== Usage

=== Basic Furigana

To automatically add readings to Japanese text:

```typst
#import "@preview/auto-jrubby:0.3.4": *
#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Hiragino Sans", lang: "ja")

#let sample = "東京スカイツリーの最寄り駅はとうきょうスカイツリー駅です"
#show-ruby(sample)
```

#img("/images/projects/auto-jrubby/sample01.png", alt: "Basic Furigana")

=== Morphological Analysis Table

To debug or display the linguistic structure of the text:

```typst
#import "@preview/auto-jrubby:0.3.4": *
#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Hiragino Sans", lang: "ja")

#let sample = "東京スカイツリーの最寄り駅はとうきょうスカイツリー駅です"
#show-analysis-table(sample)
```

#img("/images/projects/auto-jrubby/sample02.png", alt: "Morphological Analysis Table")

=== Kana Selection

You can choose to output ruby in Hiragana (default) or Katakana:

```typst
#import "@preview/auto-jrubby:0.3.4": *
#set page(width: auto, height: auto, margin: 0.5cm)

#let sample = "東京スカイツリーの高さは634mです"

// Default (Hiragana)
#show-ruby(sample)
// Katakana
#show-ruby(sample, kana: "katakana")
```

#img("/images/projects/auto-jrubby/sample03.png", alt: "Kana Selection")

== API Reference

=== `show-ruby`

Renders the input text with automatic furigana.

```typst
#show-ruby(
  input-text,
  size: 0.5em,
  leading: 1.5em,
  ruby-func: auto,
  user-dict: none,
  dict: "ipadic",
  kana: "hiragana"
)
```

#strong[Parameters:]

- `input-text` (string): The Japanese text to analyze and render.
- `size` (length): The font size of the ruby text. Defaults to `0.5em`.
- `leading` (length): The vertical space between lines to accommodate ruby text. Defaults to `1.5em`.
- `ruby-func` (function | auto): A custom ruby function from the `rubby` package.
- If `auto`, it uses the default configuration (`get-ruby(size: size)`).
- If provided, it allows advanced customization of ruby positioning (e.g., specific `pos` or `alignment`).
- `user-dict` (string | array | none): Optional user dictionary for custom tokenization.
- If `string`: A CSV-formatted string with custom dictionary entries.
- If `array`: An array of arrays, where each inner array represents a CSV row.
- If `none`: No user dictionary is used.
- `dict` (string): The dictionary to use for tokenization. Must be one of:
- `"ipadic"` (default): Standard Japanese dictionary
- `"unidic"`: Alternative dictionary with different grammatical analysis
- `kana` (string): The script to use for the ruby text. Must be one of:
- `"hiragana"` (default): Converts dictionary readings to Hiragana.
- `"katakana"`: Uses Katakana readings.

=== `show-analysis-table`

Renders a table displaying the morphological breakdown of the text.

```typst
#show-analysis-table(
  input-text,
  user-dict: none,
  dict: "ipadic"
)
```

#strong[Parameters:]

- `input-text` (string): The text to analyze.
- `user-dict` (string | array | none): Optional user dictionary for custom tokenization.
- `dict` (string): The dictionary to use. Must be one of: `"ipadic"` (default) or `"unidic"`.

#strong[Table Columns:]

The columns displayed depend on the selected `dict`.

#strong[If `dict: "ipadic"` (10 columns):]
+ #strong[Surface Form (表層形):] The word as it appears in the text.
+ #strong[Part of Speech (品詞):] Grammatical category (Noun, Verb, etc.).
+ #strong[POS Subcategory 1 (品詞細分類1)]
+ #strong[POS Subcategory 2 (品詞細分類2)]
+ #strong[POS Subcategory 3 (品詞細分類3)]
+ #strong[Conjugation Form (活用形)]
+ #strong[Conjugation Type (活用型)]
+ #strong[Base Form (原形):] The dictionary form of the word.
+ #strong[Reading (読み):] Katakana reading.
+ #strong[Pronunciation (発音)]

#strong[If `dict: "unidic"` (18 columns):]
+ #strong[Surface Form (表層形)]
+ #strong[POS Major (品詞大分類)]
+ #strong[POS Medium (品詞中分類)]
+ #strong[POS Minor (品詞小分類)]
+ #strong[POS Fine (品詞細分類)]
+ #strong[Conjugation Type (活用型)]
+ #strong[Conjugation Form (活用形)]
+ #strong[Lexeme Reading (語彙素読み)]
+ #strong[Lexeme (語彙素)]
+ #strong[Orthographic Surface (書字形出現形)]
+ #strong[Phonological Surface (発音形出現形)]
+ #strong[Orthographic Base (書字形基本形)]
+ #strong[Phonological Base (発音形基本形)]
+ #strong[Word Type (語種)]
+ #strong[Initial Mutation Type (語頭変化型)]
+ #strong[Initial Mutation Form (語頭変化形)]
+ #strong[Final Mutation Type (語末変化型)]
+ #strong[Final Mutation Form (語末変化形)]

=== `tokenize`

Low-level function that returns the raw JSON data from the WASM plugin. Useful if you want to process the analysis data manually.

```typst
#tokenize(
  input-text,
  user-dict: none,
  dict: "ipadic"
)
```

#strong[Parameters:]

- `input-text` (string): The text to tokenize.
- `user-dict` (string | array | none): Optional user dictionary for custom tokenization.
- `dict` (string): The dictionary to use. Must be one of: `"ipadic"` or `"unidic"`.

#strong[Returns:] An array of dictionaries containing:

- `surface` (string): The surface form of the token.
- `details` (array of strings): The raw detailed information for the token. The content and length depend on the dictionary used (e.g., POS, conjugation, reading, etc.).
- `ruby_segments` (array of dictionaries): A pre-calculated list of segments for furigana, where each item has `text` and `ruby` fields.

== User Dictionary Format

The user dictionary allows you to define custom word segmentation and readings. It uses a simple CSV format with three columns:

```csv
<surface>,<part_of_speech>,<reading>
```

- `surface`: The word as it appears in text
- `part_of_speech`: Custom part-of-speech label (e.g., "カスタム名詞")
- `reading`: Katakana reading for the word

#strong[Usage Examples:]

#strong[Method 1: Inline string]

```typst
#let sample = "東京タワーの最寄駅は赤羽橋駅です"
#let user-dict-str = "赤羽橋駅,カスタム名詞,アカバネバシエキ"

#show-ruby(sample)
#show-ruby(sample, user-dict: user-dict-str)
```

#strong[Method 2: Array of arrays]

```typst
#let sample = "東京タワーの最寄駅は赤羽橋駅です"
#let user-dict-array = (
  ("赤羽橋駅", "カスタム名詞", "アカバネバシエキ")
)

#show-ruby(sample)
#show-ruby(sample, user-dict: user-dict-array)
```

#strong[Method 3: Load from CSV file]

```bash
$ cat user_dict.csv
赤羽橋駅,カスタム名詞,アカバネバシエキ
```

```typst
#let sample = "東京タワーの最寄駅は赤羽橋駅です"
#let user-dict-from-file = csv("user_dict.csv")

#show-ruby(sample)
#show-ruby(sample, user-dict: user-dict-from-file)
```

#img("/images/projects/auto-jrubby/sample04.png", alt: "User Dictionary Format")

== Under the Hood

This package uses #strong[Lindera] (a Rust port of Kuromoji) with two available dictionary options:

- #strong[IPADIC]: Standard Japanese morphological dictionary
- #strong[UniDic]: Alternative dictionary with different part-of-speech classifications

The processing workflow:
+ The text is passed from Typst to the Rust WASM plugin.
+ Lindera tokenizes the text using the specified dictionary and retrieves readings.
+ A custom algorithm aligns the readings with the surface form to separate okurigana (kana endings of verbs/adjectives) from the kanji stems.
+ The structured data is returned to Typst and rendered using the `rubby` package for furigana display.

== Optional: Enabling IPADIC-NEologd

#strong[IPADIC-NEologd Support]

IPADIC-NEologd (an extended dictionary with contemporary terms and named entities) has been removed from the default distribution due to its large file size. However, you can manually enable it if needed:
+ Navigate to `./wasm-plugins/ipadic-neologd` and build the WASM module:
   ```bash
   cargo build --target wasm32-unknown-unknown --release
   ```
   + Copy the built WASM file to the package directory:
   ```bash
   cp ./target/wasm32-unknown-unknown/release/ipadic_neologd.wasm ../../package/ipadic_neologd.wasm
   ```
   + Navigate to `./package` and update `./package/lib.typ` to allow the `ipadic-neologd` option. Change:
   ```typst
   if dict not in ("ipadic", "unidic") {
     panic("dict must be one of: ipadic, unidic")
   }
   ```
   to:
   ```typst
   if dict not in ("ipadic", "ipadic-neologd", "unidic") {
     panic("dict must be one of: ipadic, ipadic-neologd, unidic")
   }
   ```
   + Install the package locally:
   ```bash
   just install
   ```
   + Import and use with `@local`:
   ```typst
   #import "@local/auto-jrubby:0.3.3": *
   #let sample = "東京スカイツリーの最寄り駅はとうきょうスカイツリー駅です"
   #show-ruby(sample, dict: "ipadic-neologd")
   ```

== License

This project is distributed under the AGPL-3.0-or-later License. See #link("https://raw.githubusercontent.com/rice8y/auto-jrubby/main/LICENSE")[LICENSE] for details.
