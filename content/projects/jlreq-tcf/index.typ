#import "/content/prelude.typ": *

#let entry = project(
  title: "jlreq-tcf",
  description: "A LaTeX package providing two-column footnotes compatible with the jlreq class.",
  published: "2026/02/20",
  repo-url: "https://github.com/rice8y/jlreq-tcf",
)[
This package provides commands to arrange footnotes into two columns (left and right) at the bottom of the page, designed to visually blend with the #link("https://github.com/abenori/jlreq/tree/master?tab=readme-ov-file")[`jlreq`] document class.

For full details and visual examples, please refer to the #link("https://raw.githubusercontent.com/rice8y/jlreq-tcf/main/docs/documentation.pdf")[documentation].

== Installation

=== Using l3build (Recommended)

To install this package using `l3build`, run the following command in the package directory:

```bash
l3build install
```

=== Manual Installation

Alternatively, you can copy `jlreq-tcf.sty` to a location where LaTeX can find it (e.g., your local `texmf` tree or the same directory as your project `.tex` file).

== Usage

Load the package in your preamble:

```latex
\usepackage{jlreq-tcf}
```

== Command Specifications

This package uses its own internal counter (shared between column L and column R) to manage footnote numbers.

=== Basic Footnotes

These commands insert a footnote mark and the corresponding text immediately.

- *`\footnoteL{<text>}`*
- Typesets a footnote in the *left-hand* column.
- Automatically increments the internal footnote counter.

- *`\footnoteR{<text>}`*
- Typesets a footnote in the *right-hand* column.
- Automatically increments the internal footnote counter.

=== Separated Mark and Text

You can separate the mark generation from the text definition. This is useful when placing footnotes in titles, tables, or other restricted environments.

- *`\footnotemarkL[<num>]`* / *`\footnotemarkR[<num>]`*
- Prints the footnote mark for the left (L) or right (R) column.
- *With `[<num>]`*: Uses the integer `<num>` as the mark number. Does *not* increment the internal counter.
- *Without `[<num>]`*: Increments the internal counter and uses that value.

- *`\footnotetextL[<num>]{<text>}`* / *`\footnotetextR[<num>]{<text>}`*
- Defines the footnote text for the left (L) or right (R) column without printing a mark in the main text.
- *With `[<num>]`*: Uses `<num>` as the label in the footnote area.
- *Without `[<num>]`*: Uses the current value of the internal counter.

== Example

```latex
\documentclass{jlreq}
\usepackage{jlreq-tcf}
\usepackage{bxjalipsum}

\begin{document}
% \footnoteL (Left column)
\jalipsum[1]{kusamakura}~\footnoteL{左の脚注1}\par
\jalipsum[2]{kusamakura}~\footnoteL{左の脚注2}\par
\jalipsum[3]{kusamakura}~\footnoteL{左の脚注3}

% \footnoteR (Right column)
\jalipsum[4]{kusamakura}~\footnoteR{右の脚注1}\par
\jalipsum[5]{kusamakura}~\footnoteR{右の脚注2}\par
\jalipsum[6]{kusamakura}~\footnoteR{右の脚注3}

% Separated mark and text
\jalipsum[7]{kusamakura}~\footnotemarkL
\jalipsum[8]{kusamakura}~\footnotemarkR

% Text definitions for the marks above
\footnotetextL[7]{左の脚注4}
\footnotetextR[8]{右の脚注4}
\end{document}
```

== Known Issues and Limitations

Please be aware of the following limitations regarding the design and implementation of this package:
+ *Layout Emulation*:
This package attempts to reproduce the footnote layout (rules, spacing, indentation) of the `jlreq` class. However, this is an *emulation* created using `minipage` environments and manual spacing. It does not strictly inherit the internal typesetting logic of `jlreq`. There may be slight visual discrepancies depending on the document settings.
+ *Conflict with Standard `\footnote`*:
*Do not use the standard `\footnote` command on the same page as `\footnoteL` or `\footnoteR`.*
Since this package manages its own output routine for two-column footnotes, using the standard `\footnote` command simultaneously will result in *two separate footnote blocks* appearing at the bottom of the page (one handled by LaTeX's standard mechanism and one by this package). This usage is not supported.
+ *Long Footnotes*:
Extremely long footnotes that exceed the available height of the page may cause the layout to break or push content off the page. The internal mechanism relies on `minipage`, which limits the ability to break long footnote text across pages.

== License

This package is distributed under the BSD 2-Clause License. See #link("https://raw.githubusercontent.com/rice8y/jlreq-tcf/main/LICENSE")[LICENSE].
]
