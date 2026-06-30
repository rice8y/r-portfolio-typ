#show: project.with(
  title: "FracTeX",
  description: "A comprehensive 2D fractal visualization package for LaTeX.",
  date: "2025-08-29",
  section: "projects",
  toc: false,
  languages: ("TeX",),
  links: (
    (label: "GitHub", url: "https://github.com/rice8y/FracTeX"),
  ),
)

#import "/content/_prelude.typ": *

This package provides commands to visualize various types of fractals using PGFPlots and LuaTeX.

#img("/images/projects/fractex/mandelbrot.png", alt: "")

#strong[Supported Fractals:]

- Mandelbrot Set
- Julia Set
- Barnsley Fern (IFS)
- Burning Ship Fractal
- Newton Fractal
- Phoenix Fractal
- Tricorn Fractal
- Buffalo Fractal
- Sierpiński Triangle
- Lyapunov Fractal
- Magnet Fractal
- Multibrot Set
- Gingerbreadman Map

== Requirements

This package requires `pgfplots`, `luacode` and `xkeyva`. Additionally, since Lua is used for coordinate calculations, LuaLaTeX must be used.

== Installation

To install this package, you can clone the repository from GitHub:

```bash
git clone https://github.com/rice8y/FracTeX.git
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

=== Mandelbrot Set

```tex
\MandelbrotSet
% options: \MandelbrotSet[xmin=-2,xmax=1,ymin=-1.5,ymax=1.5,dx=0.02,dy=0.02,max_iter=100,cmap=jet]
```

#strong[Parameters:]

- xmin/xmax: X-axis range (default: -2/1)
- ymin/ymax: Y-axis range (default: -1.5/1.5)
- dx/dy: Resolution parameters (default: 0.02/0.02)
- max_iter: Iteration limit (default: 100)
- cmap: Color scheme (default: jet)

=== Julia Set

```tex
\JuliaSet
% options: \JuliaSet[xmin=-2,xmax=2,ymin=-1.5,ymax=1.5,dx=0.02,dy=0.02,c_re=-0.8,c_im=0.156,max_iter=100,cmap=jet]
```

#strong[Parameters:]

- xmin/xmax: X-axis range (default: -2/2)
- ymin/ymax: Y-axis range (default: -1.5/1.5)
- dx/dy: Resolution parameters (default: 0.02/0.02)
- c_re/c_im: Complex constant components (default: -0.8/0.156)
- max_iter: Iteration limit (default: 100)
- cmap: Color scheme (default: jet)

=== Barnsley Fern

```tex
\BarnsleyFern
% options: \BarnsleyFern[num_points=50000,color=green]
```

#strong[Parameters:]

- num_points: Number of generated points (default: 50000)
- color: Base color (default: green)

=== Burning Ship Fractal

```tex
\BurningShipFractal
% options: \BurningShipFractal[xmin=-2,xmax=1.5,ymin=-2,ymax=1,dx=0.02,dy=0.02,max_iter=100,cmap=jet]
```

#strong[Parameters:]

- xmin/xmax: X-axis range (default: -2/1.5)
- ymin/ymax: Y-axis range (default: -2/1)
- dx/dy: Resolution parameters (default: 0.02/0.02)
- max_iter: Iteration limit (default: 100)
- cmap: Color scheme (default: jet)

=== Newton Fractal

```tex
\NewtonFractal
% options: \NewtonFractal[xmin=-1.5,xmax=1.5,ymin=-1.5,ymax=1.5,dx=0.02,dy=0.02,max_iter=20,cmap=jet]
```

#strong[Parameters:]

- xmin/xmax: X-axis range (default: -1.5/1.5)
- ymin/ymax: Y-axis range (default: -1.5/1.5)
- dx/dy: Resolution parameters (default: 0.02/0.02)
- max_iter: Iteration limit (default: 20)
- cmap: Color scheme (default: jet)

=== Phoenix Fractal

```tex
\PhoenixFractal
% options: \PhoenixFractal[xmin=-1.5,xmax=1.5,ymin=-1.5,ymax=1.5,dx=0.02,dy=0.02,P=0.3,max_iter=50,cmap=jet]
```

#strong[Parameters:]

- xmin/xmax: X-axis range (default: -1.5/1.5)
- ymin/ymax: Y-axis range (default: -1.5/1.5)
- dx/dy: Resolution parameters (default: 0.02/0.02)
- P: Feedback parameter (default: 0.3)
- max_iter: Iteration limit (default: 50)
- cmap: Color scheme (default: jet)

=== Tricorn Fractal

```tex
\TricornFractal
% options: \TricornFractal[xmin=-2,xmax=1,ymin=-1.5,ymax=1.5,dx=0.02,dy=0.02,max_iter=100,cmap=jet]
```

#strong[Parameters:]

- xmin/xmax: X-axis range (default: -2/1)
- ymin/ymax: Y-axis range (default: -1.5/1.5)
- dx/dy: Resolution parameters (default: 0.02/0.02)
- max_iter: Iteration limit (default: 100)
- cmap: Color scheme (default: jet)

=== Buffalo Fractal

```tex
\BuffaloFractal
% options: \BuffaloFractal[xmin=-2,xmax=1,ymin=-1.5,ymax=1.5,dx=0.02,dy=0.02,max_iter=100,cmap=jet]
```

#strong[Parameters:]

- xmin/xmax: X-axis range (default: -2/1)
- ymin/ymax: Y-axis range (default: -1.5/1.5)
- dx/dy: Resolution parameters (default: 0.02/0.02)
- max_iter: Iteration limit (default: 100)
- cmap: Color scheme (default: jet)

=== Sierpinski Triangle

```tex
\SierpinskiTriangle
% options: \SierpinskiTriangle[num_points=50000,color=blue]
```

#strong[Parameters:]

- num_points: Points count (default: 50000)
- color: Base color (default: blue)

=== Lyapunov Fractal

```tex
\LyapunovFractal
% options: \LyapunovFractal[amin=2.4,amax=3.6,bmin=2.4,bmax=3.6,da=0.01,db=0.01, max_iter=100,cmap=hot]
```

#strong[Parameters:]

- amin/amax: Parameter `a` range (default: 2.4/3.6)
- bmin/bmax: Parameter `b` range (default: 2.4/3.6)
- da/db: Resolution parameters (default: 0.01/0.01)
- max_iter: Iteration limit (default: 100)
- cmap: Color scheme (default: hot)

=== Magnet Fractal

```tex
\MagnetFractal
% options: \MagnetFractal[xmin=-2,xmax=2,ymin=-2,ymax=2,dx=0.02,dy=0.02,max_iter=100,cmap=jet]
```

#strong[Parameters:]

- xmin/xmax: X-axis range (default: -2/2)
- ymin/ymax: Y-axis range (default: -2/2)
- dx/dy: Resolution parameters (default: 0.02/0.02)
- max_iter: Iteration limit (default: 100)
- cmap: Color scheme (default: jet)

=== Multibrot Set

```tex
\MultibrotSet
% options: \MultibrotSet[xmin=-2,xmax=2,ymin=-2,ymax=2,dx=0.02,dy=0.02,d=3,max_iter=100,cmap=jet]
```

#strong[Parameters:]

- xmin/xmax: X-axis range (default: -2/2)
- ymin/ymax: Y-axis range (default: -2/2)
- dx/dy: Resolution parameters (default: 0.02/0.02)
- d: Power parameter (default: 3)
- max_iter: Iteration limit (default: 100)
- cmap: Color scheme (default: jet)

=== Gingerbreadman Map

```tex
\GingerbreadmanMap
% options: \GingerbreadmanMap[num_points=50000, color=red]
```

#strong[Parameters:]

- num_points: Points count (default: 50000)
- color: Base color (default: red)

== License

This package is distributed under the BSD 2-Clause License. See #link("https://raw.githubusercontent.com/rice8y/FracTeX/main/LICENSE")[LICENSE].
