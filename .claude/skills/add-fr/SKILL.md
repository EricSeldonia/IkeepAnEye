---
name: add-fr
description: Add a feature request to BACKLOG.md. Use when the user wants to log a new feature request.
argument-hint: "<priority> · <description>"
allowed-tools: Read, Edit, Bash
---

Add a new feature request to BACKLOG.md.

The user will provide: $ARGUMENTS

## Instructions

1. Read `BACKLOG.md` to understand the current table structure
2. Parse the input:
   - **Priority**: High / Normal / Low (default to Normal if not specified)
   - **Feature description**: the rest of the input
3. Infer a short **Feature** title (3–6 words, title case)
4. Infer the **Area** from the description (e.g. `iOS · Catalog`, `iOS · Cart`, `iOS · Auth`, `Cloud Functions`, `Admin`, etc.)
5. Write a concise **Notes** field (one sentence, implementation hint if obvious)
6. Append the new row to the table in `BACKLOG.md` using Edit
7. Commit: `git add BACKLOG.md && git commit -m "docs: backlog — <short lowercase title>"`
8. Confirm to the user what was added
