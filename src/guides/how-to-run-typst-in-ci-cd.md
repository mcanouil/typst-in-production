---
title: How to run Typst in CI/CD
---

Running Typst in CI/CD helps ensure your templates always compile in a clean environment, not only on your local machine.

## What is GitHub Actions?

GitHub Actions is GitHub's built-in CI/CD system. You define workflows in `.github/workflows/*.yml`, and GitHub runs them automatically based on triggers (push, pull request, schedule, etc.).

!!! note

    Here we'll only talk about GitHub Actions, but there are many other tools for CI/CD (GitLab CI/CD, CircleCI, Travis CI, etc.).

## Install Typst and compile in CI

A minimal workflow to install Typst and compile one file every Friday:

```yaml title=".github/workflows/typst-friday.yml"
name: Typst CI

on:
  schedule:
    - cron: "0 9 * * 5" # Every Friday at 09:00 UTC
  workflow_dispatch:

jobs:
  compile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Typst
        run: |
          curl -fsSL https://typst.community/typst-install/install.sh | sh
          echo "$HOME/.local/bin" >> "$GITHUB_PATH"

      - name: Compile smoke-test document
        run: typst compile summary-of-the-week.typ
```

In short:

- we define what triggers the CI (e.g., every Friday)
- we install what we need (Typst, among others)
- we specify which file to compile

This example is very minimalist, and you can build things that are much more complex. For instance, you can combine this with [Typst bindings](../from/index.md) such as Python, R, JavaScript, or Rust, and compile documents that connect to an external service (e.g., an API) and use that information to render the document.
