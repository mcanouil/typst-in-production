---
title: How to reuse functions and components across files in Typst
---

When a project grows, keeping everything in one `.typ` file quickly becomes hard to maintain. A common pattern is to move reusable functions/components to a shared file, then import them from multiple templates.

## Import from one file to another

Typst lets you import symbols from another file with `#import`.

```typst
#import "components.typ": status-badge, section-card
```

This means:

- `"components.typ"` is the path to the Typst file to import from (**relative to the current file**)
- `status-badge` and `section-card` are the symbols we want to import

You can also import everything with `*`, but importing only what you need is usually easier to read.

```typst
#import "components.typ": *
```

## Project architecture example

A practical layout is to keep shared components in one folder and templates in another:

```text
project/
├── components/
│   └── shared.typ
└── templates/
    ├── invoice.typ
    └── report.typ
```

First, we define our function:

```typst title="components/shared.typ"
#let status-badge(label, fill-col) = {
  box(fill: fill-col, inset: 6pt, text(fill: white, weight: "bold", label))
}
```

Then both templates can import the same shared function:

```typst title="templates/invoice.typ"
#import "../components/shared.typ": status-badge

#status-badge("Hey" red)
```

```typst title="templates/report.typ"
#import "../components/shared.typ": status-badge

#status-badge("World" blue)
```
