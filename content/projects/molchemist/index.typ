#import "/content/_prelude.typ": *

#show: project.with(
  title: "molchemist",
  description: "A Typst package for rendering chemical structures from Molfile / SDF data and from SMILES strings..",
  date: "2026-03-03",
  updated: "2026-09-11",
  section: "projects",
  toc: false,
  languages: ("Typst", "Rust", "C++"),
  links: (
    (label: "GitHub", url: "https://github.com/rice8y/molchemist"),
    (label: "Typst Universe", url: "https://typst.app/universe/package/molchemist/"),
  ),
)

#strong[molchemist] renders chemical structures in Typst from Molfile/SDF data or SMILES. It preserves usable input coordinates and uses a Rust/WASM layout plugin when a 2D layout must be generated.

Molfile/SDF parsing is powered by #link("https://github.com/hfooladi/sdfrust")[`sdfrust`], SMILES parsing by #link("https://crates.io/crates/opensmiles")[`opensmiles`], SMILES and fallback SDF 2D coordinate generation by #link("https://github.com/schrodinger/coordgenlibs")[`CoordgenLibs`], and final Typst drawing by #link("https://github.com/Typsium/alchemist")[`alchemist`]. The Rust/WASM components connect these libraries and preserve chemical semantics across parsing, layout, and rendering.

== Quick start

This SDF example uses the bundled PubChem record for CID 93406:

```typ
#import "@preview/molchemist:0.1.5": render-mol, render-smiles

#let molecule = read("Structure2D_COMPOUND_CID_93406.sdf")
#render-mol(molecule, abbreviate: true)
```

#img("/images/projects/molchemist/ex02.png", alt: "Typeset PubChem CID 93406")

Source data: #link("https://pubchem.ncbi.nlm.nih.gov/compound/93406")[PubChem Compound CID 93406].

SMILES input uses the same renderer after generating a 2D layout. This example is melatonin (PubChem CID 896):

```typ
#render-smiles(
  "CC(=O)NCCC1=CNC2=C1C=C(C=C2)OC",
  abbreviate: true,
)
```

#img("/images/projects/molchemist/ex06.png", alt: "Typeset PubChem CID 896")

Source data: #link("https://pubchem.ncbi.nlm.nih.gov/compound/896")[PubChem Compound CID 896].

`render-mol` accepts V2000/V3000 Molfile and multi-record SDF input. Its one-based `record` option selects an SDF record. Typst 0.15 or later can also pass a `path(...)` directly; `read(...)` remains portable across supported Typst versions.

== Rendering modes

All three modes below use the bundled 2D SDF for benzene, PubChem CID 241:

```typ
#let benzene = read("Structure2D_COMPOUND_CID_241.sdf")

#grid(
  columns: 3,
  gutter: 8mm,
  align: center + horizon,
  render-mol(benzene),
  render-mol(benzene, abbreviate: true),
  render-mol(benzene, skeletal: true),
)
```

#img("/images/projects/molchemist/readme-rendering-modes.png", alt: "Full, abbreviated, and skeletal benzene")

From left to right: full, abbreviated, and skeletal mode.

Source data: #link("https://pubchem.ncbi.nlm.nih.gov/compound/241")[PubChem Compound CID 241].

Appearance is controlled through the `config` dictionary passed to Alchemist.

== CTfile fidelity

This real ACD/Labs fixture distributed by RDKit contains two multi-atom `SUP` SGroups. `inspect-mol` preserves the source semantics while strict rendering contracts them to `NO₂` and `COOH` glyphs:

```typ
#import "@preview/molchemist:0.1.5": inspect-mol, render-mol

#let data = read("Sgroups_Abbreviations.mol", encoding: none)
#let semantic = inspect-mol(data)
#render-mol(data, skeletal: true, fidelity: "strict")
```

#img("/images/projects/molchemist/readme-sgroup-abbreviations.png", alt: "Typeset RDKit ACD/Labs SGroup fixture")

Source data: #link("https://github.com/rdkit/rdkit/blob/b421f19c9f564d0cb66148c4e614c59abadf5413/Code/GraphMol/FileParsers/sgroup_test_data/Sgroups_Abbreviations.mol")[RDKit `Sgroups_Abbreviations.mol`]. The bundled copy only normalizes CRLF line endings to LF.

The inspected record includes source IDs, query attributes, SGroups, Collections, link nodes, ordered SDF properties, and diagnostics. Strict mode reports unsupported or malformed fidelity data rather than inventing a glyph.

== Annotations

Atom, bond, and molecule anchors support restrained callouts and arrows. Enable `show-indices: true` while authoring them. Use `cetz-annotation` for custom CeTZ overlays or `dump: true` for manual Alchemist editing.

== Command line

The optional CLI emits the same generated Alchemist source:

```sh
cargo install --locked molchemist-cli

molchemist dump Structure2D_COMPOUND_CID_241.sdf --mode skeletal --standalone --output benzene.typ
molchemist dump --smiles 'CC(=O)NCCC1=CNC2=C1C=C(C=C2)OC' --standalone --output melatonin.typ
molchemist inspect Sgroups_Abbreviations.mol --output sgroups.json
molchemist dump Sgroups_Abbreviations.mol --mode skeletal --fidelity strict --standalone --output sgroups.typ
```

These commands use the same benzene, melatonin, and RDKit/ACD Labs records shown above. `inspect` writes semantic JSON; strict fidelity belongs to `dump`.


== Documentation

The #link("https://github.com/rice8y/molchemist/blob/v0.1.5/package/docs/documentation.pdf")[complete manual] contains the API reference, CTfile fidelity tables, sample code with corresponding typeset output, configuration details, and CLI workflows.

Dependency licenses and example-data provenance are recorded in #link("https://github.com/rice8y/molchemist/blob/v0.1.5/THIRD_PARTY_NOTICES.md")[THIRD_PARTY_NOTICES.md]. PubChem data usage is described by the #link("https://www.ncbi.nlm.nih.gov/home/about/policies/")[NCBI Website and Data Usage Policies].
