#show: project.with(
  title: "CeTZuron",
  description: "A Typst package for drawing neural network diagrams.",
  date: "2025-08-30",
  section: "projects",
  toc: false,
  languages: ("Typst",),
  links: (
    (label: "GitHub", url: "https://github.com/rice8y/cetzuron"),
  ),
)

#import "/content/_prelude.typ": *

== Installation

=== 1. Clone the repository

```bash
$ git clone https://github.com/rice8y/cetzuron.git
$ cd cetzuron
```

=== 2. Install the package locally via `justfile`, `.sh`, or `.bat`

==== 2-1. Using `justfile`

```bash
$ just install
```

#details(summary: "Example on WSL2 (Ubuntu)")[
```bash
$ just install
Package cetzuron version 0.1.0 has been installed to /home/rice8/.local/share/typst/packages/local/cetzuron/0.1.0
```
]

==== 2-2. Using `.sh`

```bash
$ chmod +x install.sh
$ ./install.sh
```

#details(summary: "Example on WSL2 (Ubuntu)")[
```bash
$ ./install.sh
Package cetzuron version 0.1.0 has been installed to /home/rice8/.local/share/typst/packages/local/cetzuron/0.1.0
```
]

==== 2-3. Using `.bat`

```cmd
> install.bat
```

#details(summary: "Example on Windows (cmd)")[
```cmd
> install.bat
C:install.sh
C:justfile
C:README.md
C:typst.toml
C:docs\ae\sample_ae.pdf
C:docs\ae\sample_ae.png
C:docs\ae\sample_ae.typ
C:docs\fcnn\sample_fcnn.pdf
C:docs\fcnn\sample_fcnn.png
C:docs\fcnn\sample_fcnn.typ
C:docs\lstm\sample_lstm.pdf
C:docs\lstm\sample_lstm.png
C:docs\lstm\sample_lstm.typ
C:docs\rnn\sample_rnn.pdf
C:docs\rnn\sample_rnn.png
C:docs\rnn\sample_rnn.typ
C:src\ae.typ
C:src\fcnn.typ
C:src\lib.typ
C:src\lstm.typ
C:src\requirements.typ
C:src\rnn.typ
23 File(s) copied
Package cetzuron version 0.1.0 has been installed to C:\Users\yoneyama\AppData\Roaming\typst\packages\local\cetzuron\0.1.0
```
]

== Usage

Import the package using `#import`.

```typ
#import "@local/cetzuron:0.1.0"
```

=== Fully Connected Neural Network `#fcnn`

==== Parameters

```typ
fcnn(
    inputNodes: int,
    middleNodes: int,
    outputNodes: int,
    middleLayers: int,
    label: bool,
) -> content
```

#strong[inputNodes:] Number of nodes in the input layer
#strong[middleNodes:] Number of nodes in hidden layers
#strong[outputNodes:] Number of nodes in the output layer
#strong[middleLayers:] Number of hidden layers (default: 3)
#strong[label:] Whether to show labels (default: true)

==== Example usage of `#fcnn`

```typ
#import "@local/cetzuron:0.1.0": *
#set page(width: auto, height: auto)
#set text(lang: "ja", font: "TeX Gyre Termes", size: 10pt)
#show regex("[\p{scx:Han}\p{scx:Hira}\p{scx:Kana}]"): set text(lang: "ja", font: "Harano Aji Mincho", size: 10pt)

#figure(
  fcnn(3, 4, 3),
  caption: [With Labels]
)
#figure(
  fcnn(5, 4, 3, middleLayers: 1, label: false),
  caption: [Without Labels]
)
```

#img("/images/projects/cetzuron/sample_fcnn_en.png", alt: "sample")

=== Recurrent Neural Network `#rnn`

==== Parameters

```typ
rnn(
    inputNodes: int,
    middleNodes: int,
    outputNodes: int,
    middleLayers: int,
    label: bool,
) -> content
```

#strong[inputNodes:] Number of nodes in the input layer
#strong[middleNodes:] Number of nodes in hidden layers
#strong[outputNodes:] Number of nodes in the output layer
#strong[middleLayers:] Number of hidden layers (default: 3)
#strong[label:] Whether to show labels (default: true)

==== Example usage of `#rnn`

```typ
#import "@local/cetzuron:0.1.0": *
#set page(width: auto, height: auto)
#set text(lang: "ja", font: "TeX Gyre Termes", size: 10pt)
#show regex("[\p{scx:Han}\p{scx:Hira}\p{scx:Kana}]"): set text(lang: "ja", font: "Harano Aji Mincho", size: 10pt)

#figure(
  rnn(3, 4, 3),
  caption: [With Labels]
)
#figure(
  rnn(5, 4, 3, middleLayers: 1, label: false),
  caption: [Without Labels]
)
```

#img("/images/projects/cetzuron/sample_rnn_en.png", alt: "sample")

=== Long Short-Term Memory `#lstm`

==== Parameters

```typ
lstm(
    inputNodes: int,
    middleNodes: int,
    outputNodes: int,
    middleLayers: int,
    label: bool,
) -> content
```

#strong[inputNodes:] Number of nodes in the input layer
#strong[middleNodes:] Number of nodes in hidden layers
#strong[outputNodes:] Number of nodes in the output layer
#strong[middleLayers:] Number of hidden layers (default: 3)
#strong[label:] Whether to show labels (default: true)

==== Example usage of `#lstm`

```typ
#import "@local/cetzuron:0.1.0": *
#set page(width: auto, height: auto)
#set text(lang: "ja", font: "TeX Gyre Termes", size: 10pt)
#show regex("[\p{scx:Han}\p{scx:Hira}\p{scx:Kana}]"): set text(lang: "ja", font: "Harano Aji Mincho", size: 10pt)

#figure(
  lstm(3, 4, 3),
  caption: [With Labels]
)
#figure(
  lstm(5, 4, 3, middleLayers: 1, label: false),
  caption: [Without Labels]
)
```

#img("/images/projects/cetzuron/sample_lstm_en.png", alt: "sample")

=== Autoencoder `#ae`

==== Parameters

```typ
ae(
    inputNodes: int,
    middleNodes: int,
    style: string,
    label: bool,
) -> content
```

#strong[inputNodes:] Number of nodes in input/output layers
#strong[middleNodes:] Number of nodes in hidden layer
#strong[style:] Shape of hidden layer \["short", "full"\] (default: "short")
#strong[label:] Whether to show labels (default: true)

==== Example usage of `#ae`

```typ
#import "@local/cetzuron:0.1.0": *
#set page(width: auto, height: auto)
#set text(lang: "ja", font: "TeX Gyre Termes", size: 10pt)
#show regex("[\p{scx:Han}\p{scx:Hira}\p{scx:Kana}]"): set text(lang: "ja", font: "Harano Aji Mincho", size: 10pt)

#figure(
  ae(5, 3),
  caption: [With Labels (short)]
)
#figure(
  ae(5, 3, style: "full"),
  caption: [With Labels (full)]
)
#figure(
  ae(4, 2, style: "full", label: false),
  caption: [Without Labels (full)]
)
```

#img("/images/projects/cetzuron/sample_ae_en.png", alt: "sample")
