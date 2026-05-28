# Relational Modeling — University Registration

Lessons from designing the schema from scratch. Organized by concept, not by table.

## Foreign key placement

The relationship between Faculty and Department is one-to-many. One department
has many faculty; each faculty member belongs to one department. In relational
modeling, the foreign key always lives on the "many" side.

This isn't a stylistic choice — it falls out of how relational databases
represent data. A column holds one atomic value, so a list of foreign keys
on the "one" side simply doesn't fit the model. Put `department_id` on Faculty
and you get bidirectional queryability for free (with a secondary index on the
FK column), which is what Kleppmann means by "stores the relationship in only
one place and relies on secondary indexes to query it in both directions."

**Rule: one-to-many → foreign key on the many side. Always.**

## Normalization vs. denormalization

These are distinct from FK placement. Normalization is about whether the same
fact is stored in one place or duplicated across rows. Storing `department_id`
on Faculty is normalized. Also storing `department_name` on Faculty (so you
don't have to join) would be denormalized — faster reads, but now two places
can disagree if a department is renamed.

For learning purposes: stay normalized. Denormalization is a performance
optimization you reach for when joins become a bottleneck, not a design default.

## Junction tables

The relational pattern for many-to-many relationships. A third table whose
only job is to record pairings.

- The primary key is the combination of the two foreign keys.
- Synthetic IDs on pure junction tables are pointless — you'll never look one up.
- When the relationship itself has attributes (a grade, a date, a flag), add
  columns to the junction table. At some point this stops feeling like a
  junction table and starts feeling like an entity in its own right.
  `Enrollment` is the example — it has `grade` and `status`, so it's exposed
  as a first-class object in the domain layer, not hidden.

**Rule: any list-of-references in your head → junction table in the schema.**

## Array columns

Modern databases (Postgres especially) support array column types. Don't reach
for them when the array elements are references to other rows. The downsides:

- No foreign key constraints — the database can't verify referenced rows exist.
- Joins become awkward and harder to optimize.
- Updates rewrite the whole array.
- Not portable (SQLite doesn't have them).

Arrays are reasonable when the array is genuinely owned by the row and never
referenced from elsewhere — tags on a blog post, feature flags, notification
preferences. But if the elements have identity (Department, Course, Student),
use a junction table.

## SQL forces decisions Python lets you defer

Writing the schema in raw SQL surfaces things the dataclass version glossed over:

- **Nullability.** Every column is a `NOT NULL` decision. Python's `| None`
  exists but is rarely enforced; SQL is strict.
- **Controlled vocabularies.** `grade: str` became `CHECK (grade IN (...))`.
  At the application layer, this is also where enums earn their keep.
- **Cardinality of optional relationships.** `Department.head_id` is nullable
  because a department can exist before a head is appointed. This also resolves
  the chicken-and-egg between Faculty (needs a department) and Department
  (needs a head) — one of the FKs has to allow NULL.
- **Indexes.** Foreign keys aren't indexed automatically in most databases.
  Index the columns you filter and join on.

## Prerequisites — the AND-of-ORs model

The most interesting modeling problem in the schema. Real prerequisites are
boolean formulas like `(CS 201) AND (CS 250 OR Math 220)`. A flat junction
table can't express the OR.

Solution: any boolean formula can be rewritten in **conjunctive normal form**
(an AND of ORs), which maps to two tables:

- `prerequisite_groups` — one row per OR-clause. Multiple groups for the same
  course are implicitly ANDed.
- `prerequisite_group_options` — the courses inside each group, any one of
  which satisfies it.

Pattern worth remembering: any time the relationship structure includes
both AND and OR semantics, you probably want a "group of options" shape.

## What SQL constraints can't enforce

SQL is good at:
- Local constraints (this column's value is in this set)
- Referential constraints (this FK points to a real row)

SQL is bad at:
- Cross-row constraints (no two sections overlap in the same room at the
  same time)
- Conditional uniqueness (exactly one row in this group has `is_primary = true`)

These get enforced via triggers, application logic, or Postgres-specific
features like exclusion constraints. Worth knowing the boundary exists.

## The impedance mismatch

The recurring theme of the chapter, now felt firsthand.

The shape data takes for storage (flat tables, foreign keys, junction tables)
is not the shape it takes in application code (objects with nested objects,
lists of related entities, behavior attached to data). The persistence layer
bridges these — that's its whole job. ORMs hide the gap behind declarative
configuration, which is productive but obscures what's actually happening.

Two distinct sets of classes are legitimate:

- **Persistence models** — flat, 1:1 with tables, foreign keys as raw IDs.
  Only seen inside the repository layer.
- **Domain models** — rich, application-shaped, junction tables hidden,
  foreign keys resolved to nested objects, behavior attached.

The **repository** owns the translation between them. Not "pure database
interactions" — its purpose is to be the boundary that hides the database
from the domain. If it returned raw rows, it would just be a DAO.

## Files in this folder

- `schema.sql` — database schema (source of truth)
- `database.py` — flat dataclasses matching tables 1:1
- `domain.py` — rich application-layer objects
- `seed.sql` — seed data (next session)
- `queries.sql` — scenario queries (next session)
- `db.sqlite` — built from schema.sql + seed.sql, gitignored

## Things to revisit

- Writing the repository layer for real — would teach the assembly logic
  that's currently hand-waved.
- Querying the prerequisite tables in SQL (GROUP BY + HAVING) to feel
  whether the AND-of-ORs model is actually pleasant to query against.
- Time-overlap constraints for room scheduling — would need triggers or
  application logic; worth seeing what that looks like.