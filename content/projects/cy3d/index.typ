---
title = "CY3d"
description = "A LaTeX package for drawing Calabi-Yau manifold."
date = "2025-08-29"
section = "projects"
toc = false

[extra]
kind = "project"
has_math = true
published_raw = "2025/8/29"
languages = ["TeX"]
links = [{ label = "GitHub", url = "https://github.com/rice8y/cy3d" }]
---

#import "/content/_prelude.typ": *

This LaTeX package provides a command `\CalabiYau`, which can display Calabi-Yau manifold. This package utilizes PGFplots for drawing Calabi-Yau manifold.

#img("/images/projects/cy3d/cy3d.png", alt: "")

== Requirements

This package requires `pgfplots` and `luacode`. Additionally, since Lua is used for coordinate calculations, LuaLaTeX must be used.

== Installation

To install this package, you can clone the repository from GitHub:

```bash
git clone https://github.com/rice8y/cy3d
```

=== Windows

On Windows, you can simply run the following command to install the package:

```bash
install
```

=== Linux/macOS

For Linux and macOS, you can use the provided shell script to install the package:

```bash
./install.sh
```

== Usage

```tex
\CalabiYau[colormap]{power}{angle}{mesh size}
```

#strong[Parameters:]

 - power: The degree of the Calabi-Yau equation $z_1^n + z_2^n = 1$.
 - angle: The angle parameter to adjust the rotation or perspective of the surface.
 - mesh size: Defines the resolution of the mesh for plotting the surface.
 - colormap (option): Specifies the color scheme used for rendering the surface. This is based on the TikZ colormap. The default colormap is jet.

== License

This package is distributed under the BSD 2-Clause License. See #link("https://raw.githubusercontent.com/rice8y/cy3d/main/LICENSE")[LICENSE].
