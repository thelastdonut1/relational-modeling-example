# Relational Modeling: University Course Registration

A self-contained learning artifact. One scenario, one solution, the reasoning behind it.

## What this is

I had Claude generate me a relational schema design challenge for a university course registration system. This repo captures the full arc — the scenario, the code I wrote, and the lessons I extracted afterward — in a form I can re-open, re-execute, and link to from notes anywhere.

## The four artifacts

| File | Role |
|---|---|
| [`brief.md`](notes/brief.md) | The scenario, as originally written |
| [`schema.sql`](schema.sql) | The SQL solution — source of truth for the data model |
| [`database.py`](database.py) | Flat persistence dataclasses, 1:1 with tables |
| [`domain.py`](domain.py) | Rich domain-layer objects with behavior |
| [`writeup.md`](notes/writeup.md) | Lessons learned, organized by concept |

Read in roughly that order. The writeup makes the most sense after seeing both the schema and the two model layers side by side.

## Running it

The dev container brings up Python 3.12 with SQLite (a single click in Codespaces, or open the folder in VS Code with the Dev Containers extension installed locally). Once inside:

```bash
python build.py        # builds db.sqlite from schema.sql
sqlite3 db.sqlite      # poke around interactively
```

`db.sqlite` is gitignored — it's a build artifact, recreated from `schema.sql` on demand. The schema is the source of truth.

## Workflow this repo demonstrates

The folder follows a four-phase pattern meant to generalize to any practice exercise:

1. **Brief** — the prompt or scenario, preserved verbatim
2. **Solution** — runnable code that solves it, with the environment to execute it
3. **Reflection** — concept-organized lessons that came out of doing it
4. **Linkage** — every artifact references the others, so navigating between them is one click in any direction

Notes live in Markdown next to the code rather than in a separate notebook. The benefit: the relationship between prompt, code, and reflection is structural (folder + filenames) rather than memorized.