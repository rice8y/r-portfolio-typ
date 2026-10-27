#import "/content/_prelude.typ": *

#show: project.with(
  title: "aclfolio",
  description: "An unofficial, read-only Rust SDK for ACL Anthology metadata.",
  date: "2026-10-27",
  start_date: "2026-10-25",
  section: "projects",
  toc: false,
  languages: ("Rust",),
  links: (
    (label: "GitHub", url: "https://github.com/rice8y/aclfolio"),
    (label: "crates.io", url: "https://crates.io/crates/aclfolio"),
  ),
)

An *unofficial*, read-only Rust SDK for ACL Anthology metadata. Load local XML and JSON data to explore papers, authors and venues, and generate BibTeX entries and formatted citations.

== Usage

Add `aclfolio` to your project's `Cargo.toml` (MSRV is *1.85*):

```toml
[dependencies]
aclfolio = "0.1"
```

With a local ACL Anthology metadata directory available, add the following to `src/main.rs` and run your application with `cargo run`:

```rust
use aclfolio::Anthology;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let anthology = Anthology::open("acl-anthology/data")?;
    if let Some(paper) = anthology.get_paper("C92-1025")? {
        println!("{} ({})", paper.title().as_text()?, paper.year());
        println!("{}", paper.to_bibtex(false)?);
        println!("{}", paper.to_citation(None)?);
        for credit in paper.author_credits() {
            let person = credit.resolve()?;
            println!("{}: {} publications", person.id, person.item_ids.len());
        }
    }
    Ok(())
}
```

See the examples for #link("https://github.com/rice8y/aclfolio/blob/v0.1.0/examples/inspect.rs")[snapshot inspection], #link("https://github.com/rice8y/aclfolio/blob/v0.1.0/examples/paper.rs")[paper lookup and citations], #link("https://github.com/rice8y/aclfolio/blob/v0.1.0/examples/changes.rs")[snapshot comparison] and #link("https://github.com/rice8y/aclfolio/blob/v0.1.0/examples/markup.rs")[markup conversion].

== Metadata and navigation

Provide a local `data/` directory containing `xml/*.xml` and `json/{people,venues,sigs}.json`. `Anthology::open` reads an immutable snapshot; `LoadOptions` configures resource limits, validation and URL templates.

- `get`, `get_collection`, `get_volume` and `get_paper` resolve modern and historical identifiers, including C69 and D19 exceptions. Tuple-based lookups use `IdParts`.
- `CollectionRef`, `VolumeRef` and `PaperRef` provide parent/root navigation and effective metadata: inherited editors, dates, journal names, venue associations, file references and front matter. `stored()` exposes the original typed record. Bound credit accessors normalize empty given names while retaining them in storage.
- `get_person`, `find_people`, `person_index` and credit resolution implement the reference's explicit-ID, ORCID, name-variant, slug and ambiguity rules, including inferred `/unverified` people. `PersonRef` provides publications, similar people, name specifications and coauthor counts.
- `get_event`, `get_venue` and `get_sig` provide inferred and explicit event links, talks, symmetric related directories, venue/SIG memberships and meeting years.
- `MarkupText` and `RichText` convert markup to Unicode text, HTML, LaTeX and XML. `MarkupText` also preserves wrapper attributes/tails and implements the reference's string operations. LaTeX parsing and math-symbol conversion run in Rust.
- Publications generate BibTeX, CiteProc JSON, ACL HTML and Markdown citations. `to_citation(Some(style_path))` supports custom CSL styles; the renderer follows the pinned citeproc-py behavior, including its limitations.
- Detached constructors, normalization, schema validation, checksum utilities and `to_xml` conversions operate without writing authoritative metadata.

See the #link("https://docs.rs/aclfolio/0.1.0/aclfolio/")[API documentation], #link("https://github.com/rice8y/aclfolio/blob/v0.1.0/docs/data-model.md")[data model] and #link("https://github.com/rice8y/aclfolio/blob/v0.1.0/docs/compatibility.md")[compatibility notes].

== Files and Git

Features are opt-in; both are disabled by default. Enable the features you need in your dependency declaration:

```toml
[dependencies]
aclfolio = { version = "0.1", features = ["network", "git"] }
```

#table(
  columns: (auto, 1fr),
  inset: 8pt,
  align: (left, left),
  table.header(
    [*Feature*],
    [*Read-oriented I/O*],
  ),
  [`network`],
  [`FileReference::download` with timeout, content-type checks, CRC32 verification and existing-file reuse],
  [`git`],
  [`Anthology::from_repo`, `from_within_repo` and `repository::clone_or_pull_from_repo`; requires the Git executable],
)

Downloads write to an explicit destination. A checksum mismatch is returned as `DownloadOutcome::ChecksumMismatch`, with the downloaded bytes retained as in the reference. Git synchronization returns an origin mismatch diagnostic and pulls the existing origin. It does not edit Anthology records through an administration API.

`Config` captures the URL prefix (including `ANTHOLOGY_PREFIX`) and URL templates when loading a snapshot. Pass it explicitly when using detached file references.

== Errors and validation

Lookups distinguish malformed IDs (`Err`) from absent records (`Ok(None)`). Loading returns positioned parse errors, I/O failures, limit errors and diagnostics. The default compatible policy retains structural/extension/reference diagnostics; strict policy rejects them. `schema::validate_xml` separately implements the pinned Anthology RELAX NG grammar, including its datatype constraints, entirely in Rust.

Default limits are 64 MiB per file, 2 GiB total input, 20,000 files, two million XML nodes per file and 64 element levels. DTDs, external entities, non-UTF-8 sources and symlink sources are rejected. Unknown JSON fields are retained in `extensions`; unknown XML fields are diagnosed. Metadata text is never executed.

`RichText::plain_text`, `resolve_person`, `people` and `works` are additional raw or explicit-link views. For Python-equivalent rendering and inferred identities, use `as_text`, `get_person`, `person_index` and `PersonRef` instead. Stored absent dates remain inspectable; effective `ingest_date()` supplies the reference fallback.

== Immutable updates

Snapshots are `Send + Sync`. Share an `Arc<Anthology>` across readers. Collections are eager; inferred person and bibkey indexes initialize once on demand. `old.reload(new_directory, options)` returns a new snapshot and shares unchanged collections. Failed reloads leave the old snapshot usable.

`old.diff(&new)` reports entity and source-byte changes. Paper changes include parent-volume metadata conservatively. Every input is hashed; a second manifest pass detects ordinary concurrent edits, but callers should use immutable source directories. A supplied revision is provenance declared by the caller; source SHA-256 hashes record the actual bytes.

== License

This project is distributed under #link("https://github.com/rice8y/aclfolio/blob/v0.1.0/LICENSE")[GPL-3.0-or-later]. See #link("https://github.com/rice8y/aclfolio/blob/v0.1.0/NOTICE")[NOTICE] for third-party licenses and attribution.