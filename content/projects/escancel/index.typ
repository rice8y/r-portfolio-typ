#show: project.with(
  title: "escansel",
  description: "A simple and convenient CLI tool to cancel your SLURM jobs — essentially an easy scancel.",
  date: "2025-10-22",
  section: "projects",
  toc: false,
  languages: ("Python",),
  links: (
    (label: "GitHub", url: "https://github.com/rice8y/escansel"),
  ),
)

#import "/content/_prelude.typ": *

#strong[escancel] is a simple and convenient CLI tool to cancel your SLURM jobs — essentially an #strong[easy scancel].
It lists your active jobs and lets you interactively select which ones to cancel, making `scancel` faster and more user-friendly.

== Installation

You can install this CLI tool using `uv` in two different ways:

=== A. Install directly from GitHub (recommended)

```bash
uv tool install git+https://github.com/rice8y/escancel.git
```

This will fetch and install the latest version directly from the repository.

=== B. Install from a local clone
+ Clone the repository:

```bash
git clone https://github.com/rice8y/escancel.git
```
+ Move into the project directory:

```bash
cd escancel
```
+ Install the package in editable mode using uv tool:

```bash
uv tool install -e .
```

This is useful if you plan to modify the code locally.

== Upgrade

To upgrade escancel to the latest version:

```bash
uv tool upgrade escancel
```

This will fetch the latest version from the original source and update your installation.

== License

This project is distributed under the MIT License. See #link("https://raw.githubusercontent.com/rice8y/escancel/main/LICENSE")[LICENSE].
