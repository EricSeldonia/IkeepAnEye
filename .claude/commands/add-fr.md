Add a new feature request to BACKLOG.md.

The user will provide: $ARGUMENTS

## Instructions

1. Read `BACKLOG.md` to understand the current table structure
2. Parse the input:
   - **Priority**: High / Normal / Low (default to Normal if not specified)
   - **Feature description**: the rest of the input
3. Determine the next **ID** by finding the highest `FR-NNN` in the table and incrementing by 1 (e.g. if FR-005 exists, use FR-006)
4. Infer a short **Feature** title (3–6 words, title case)
5. Infer the **Area** from the description (e.g. `iOS · Catalog`, `iOS · Cart`, `iOS · Auth`, `Cloud Functions`, `Admin`, etc.)
6. Write a concise **Notes** field (one sentence, implementation hint if obvious)
7. Set **Status** to `New`
8. Append the new row to the table in `BACKLOG.md` using Edit
9. Commit: `git add BACKLOG.md && git commit -m "docs: backlog — <short lowercase title>"`
10. Confirm to the user what was added
