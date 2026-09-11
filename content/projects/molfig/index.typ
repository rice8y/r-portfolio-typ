#import "/content/_prelude.typ": *

#show: project.with(
  title: "molfig",
  description: "A Typst package for rendering molecular structure files in static documents.",
  date: "2026-06-21",
  updated: "2026-09-11",
  section: "projects",
  toc: false,
  languages: ("Typst", "Rust"),
  links: (
    (label: "GitHub", url: "https://github.com/rice8y/molfig"),
    (label: "Typst Universe", url: "https://typst.app/universe/package/molfig/"),
  ),
)

#strong[Molfig] is a Typst package for rendering molecular structure files in static documents.

It accepts PDB, mmCIF, BinaryCIF, and XYZ input, converts structures through a CPU-side #link("https://molstar.org/")[Mol#super[#sym.ast]]-style Model/Structure/Unit layer, exports static OBJ/STL/PLY mesh bytes, and delegates final document rendering to #link("https://typst.app/universe/package/maquette")[`maquette`].

You can try the #link("https://bernsteining.github.io/maquette/?a=9R1O")[web demo] by #link("https://github.com/bernsteining")[maquette's author] to adjust the scene and copy the Typst source.

#img("/images/projects/molfig/gallary.png", alt: "Gallery of molecular structures rendered with Molfig")

== Quickstart

```typst
#import "@preview/molfig:0.1.5"
#set page(width: auto, height: auto, margin: 0mm)

// Uses structural data from RCSB PDB / wwPDB.
// PDB ID: 9R1O
// PDB DOI: https://doi.org/10.2210/pdb9R1O/pdb
// Deposition authors: Petrenas, R.; Ozga, K.; Chubb, J.J.; Woolfson, D.N.
// PDB archive data files are available under CC0 1.0.
#let pdb = read("9R1O.pdb", encoding: none)

#molfig.render(
  pdb,
  format: "pdb",
  representation: "cartoon",
  assembly: "1",
  mesh-format: "obj",
  quality: "high",
  center: true,
  output-format: "svg",
  config: (
    azimuth: 35,
    elevation: 24,
    background: "",
  ),
)
```

#strong[Rendered 9R1O Example]

#img("/images/projects/molfig/9R1O.png", alt: "Example protein structure rendered from PDB entry 9R1O using Molfig with the Mol* representation")

Structural data source: RCSB PDB / wwPDB, PDB ID `9R1O`, DOI #link("https://doi.org/10.2210/pdb9R1O/pdb")[`10.2210/pdb9R1O/pdb`]. PDB archive data files are distributed under CC0 1.0.

== XYZ Example

```typst
#import "@preview/molfig:0.1.5"

// Uses coordinate data from PubChem.
// PubChem CID: 702 (ethanol)
// PubChem3D conformer: 000002BE00000001
#let xyz = read("ethanol.xyz", encoding: none)

#molfig.render(
  xyz,
  format: "xyz",
  representation: "default",
  color-theme: "element-symbol",
  mesh-format: "obj",
  quality: "high",
  center: true,
  output-format: "svg",
  config: (
    azimuth: 35,
    elevation: 24,
    background: "",
  ),
)
```

#strong[Rendered Ethanol Example]

#img("/images/projects/molfig/ethanol-xyz.png", alt: "Ethanol rendered from a PubChem3D XYZ conformer with Molfig")

Coordinate data source: PubChem CID #link("https://pubchem.ncbi.nlm.nih.gov/compound/702")[`702`], PubChem3D conformer `000002BE00000001`, retrieved through #link("https://pubchem.ncbi.nlm.nih.gov/docs/pug-rest")[PubChem PUG REST].

Use `format: "mmcif"`, `format: "bcif"`, or `format: "xyz"` for text mmCIF, BinaryCIF, and XYZ inputs. For reproducible documents, prefer explicit `format`, `representation`, `assembly`, `alt-loc`, `mesh-format`, and geometry quality options instead of relying on auto-detection.

== Examples

The #link("https://github.com/rice8y/molfig/tree/v0.1.3/package/examples")[`package/examples`] directory contains complete example sources, rendered PDFs, and their accompanying structural data files. The example data files are kept under #link("https://github.com/rice8y/molfig/tree/v0.1.3/package/examples/data")[`package/examples/data`], together with attribution metadata.

The #link("https://github.com/rice8y/molfig/tree/v0.1.5/package/examples")[`package/examples`] directory contains complete example sources, rendered PDFs, and their accompanying structural data files. The example data files are kept under #link("https://github.com/rice8y/molfig/tree/v0.1.5/package/examples/data")[`package/examples/data`], together with attribution metadata.

== Public API

- `render(data, ..., config: (:), width: auto, height: auto)` converts and renders through maquette.
- `render-object(data, ...)` returns generated mesh bytes, rendered content, and metadata.
- `to-obj(data, ...)`, `to-mtl(data, ...)`, `to-stl(data, ...)`, and `to-ply(data, ...)` return export bytes.
- `info(data, ...)` returns molecular and mesh-planning metadata without rendering.
- `mesh-info(data, mesh-format: "obj", config: (:), ...)` delegates to maquette's mesh metadata helpers for the generated mesh.

Common options include `format`, `representation`, `color-theme`, `theme`, `assembly`, `alt-loc`, `block-index`, `block-header`, `quality`, `decimate`, `sphere-detail`, `linear-segments`, `radial-segments`, `radius-scale`, `atom-radius`, `bond-radius`, `ribbon-radius`, `ribbon-width`, `helix-profile`, `round-cap`, `sheet-arrow-factor`, `tubular-helices`, `infer-bonds`, and `center`.

The `data` argument accepts bytes from `read(..., encoding: none)`, inline string data for small examples, and Typst 0.15+ path values created with `path("...")`.

== Choosing A Mesh Format

- Use OBJ for the closest static Mol#super[#sym.ast] exporter parity and readable diffs.
- Use STL when a downstream tool specifically requires binary triangle data.
- Use PLY when package-owned face group metadata is useful in a compact text mesh.

OBJ output can be paired with `to-mtl`. During `render`, OBJ material colors are automatically converted to maquette's `materials` map; entries supplied through `config.materials` override generated colors. OBJ and PLY preserve Molfig group or operator metadata where the format can represent it. Binary STL follows Mol#super[#sym.ast] static exporter behavior and keeps the two-byte facet attribute field at zero.

== Documentation

The full Molfig manual is available at #link("https://github.com/rice8y/molfig/tree/v0.1.5/package/docs/documentation.pdf")[`package/docs/documentation.pdf`]. It documents:

- installation and import conventions;
- input format handling, XYZ model behavior, and BinaryCIF block selection;
- every public command and return shape;
- mesh, representation, assembly, altLoc, and quality options;
- maquette passthrough configuration;
- metadata fields returned by `info` and `render-object`;
- licensing, third-party notices, and example data attribution;
- troubleshooting and development commands;
- embedded 9R1O and PubChem ethanol XYZ renderings.

The manual source is #link("https://github.com/rice8y/molfig/tree/v0.1.5/package/docs/documentation.typ")[`package/docs/documentation.typ`], and it reads the package version from #link("https://github.com/rice8y/molfig/tree/v0.1.5/package/typst.toml")[`package/typst.toml`].

== Notes And Limits

Molfig emits static presentation meshes. `representation: "surface"` implements the #super[#sym.ast] Viewer Quick Styles Molecular Surface preset on the CPU and exports the result as OBJ/STL/PLY. Gaussian volume and density/volume visuals remain outside the static export contract; the size-dependent ViewerAuto path uses a CPU Gaussian surface for Huge and Gigantic structures.

IHM coarse sphere and gaussian rows remain available as coarse model units and participate in the size-dependent ViewerAuto Gaussian-surface path.

== License And Notices

Molfig project code is licensed under the MIT License. See #link("https://github.com/rice8y/molfig/tree/v0.1.5/LICENSE")[`LICENSE`].

Molfig ports or adapts #link("https://github.com/molstar/molstar")[Mol#super[#sym.ast]] behavior and includes Mol#super[#sym.ast]-derived reference data in the Rust/WASM implementation. Mol#super[#sym.ast] is licensed under the MIT License, copyright (c) 2017 - now, Mol#super[#sym.ast] contributors.

Bundled example structure files under #link("https://github.com/rice8y/molfig/tree/v0.1.5/package/examples/data")[`examples/data`] are PDB archive data from RCSB PDB / wwPDB and are available under CC0 1.0. Per-file PDB IDs, DOIs, and recommended attributions are listed in #link("https://github.com/rice8y/molfig/tree/v0.1.5/package/examples/data/README.md")[`examples/data/README.md`].

See #link("https://github.com/rice8y/molfig/tree/v0.1.5/NOTICE.md")[`NOTICE.md`] and #link("https://github.com/rice8y/molfig/tree/v0.1.3/THIRD_PARTY_NOTICES.md")[`THIRD_PARTY_NOTICES.md`] for the full distribution notice.

== Benchmarks

The #link("https://github.com/rice8y/molfig/tree/v0.1.5/benchmarks")[`benchmarks`] suite compiles the published PDB, mmCIF, and BinaryCIF examples in isolated Typst processes. It measures Molfig's OBJ export pipeline by default and can include maquette rendering with `--mode render`. The runner provides pinned Nix builds of Typst 0.14.0, 0.14.1, 0.14.2, and 0.15.0 with a common hyperfine 1.20.0. The default shell uses Typst 0.15.0. The Molfig version defaults to `package/typst.toml` and can be changed without editing the benchmark source:

```sh
nix develop ./benchmarks --command \
  benchmarks/run.sh --version "$VERSION"
```

Pass `--baseline-version` together with `--version` to compare two Molfig releases on the same workload and receive hyperfine's relative performance summary.

See #link("https://github.com/rice8y/molfig/tree/v0.1.5/benchmarks/README.md")[`benchmarks/README.md`] for case selection and runner options.

== Development

```sh
cd wasm-plugin
cargo fmt --check
cargo test
node tests/validate-pubchem-xyz.mjs
cargo build --release --target wasm32-unknown-unknown
cp target/wasm32-unknown-unknown/release/molfig.wasm ../package/molfig.wasm
cd ../package
just docs
```

The checked-in `package/molfig.wasm` should be regenerated after Rust changes that affect the Typst plugin. Regenerate `package/docs/documentation.pdf` after public API or documentation changes.