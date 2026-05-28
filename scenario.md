## Scenario: University Course Registration System

You're designing the data backend for a mid-sized university's course registration system. Roughly 15,000 students, 800 faculty, and 2,500 courses offered per academic year.

**The domain:**

The university offers **courses** (e.g., "CS 301: Algorithms"). Each course has a fixed catalog entry — a description, credit hours, the department that owns it, and any prerequisite courses.

Each semester, the university schedules specific **sections** of courses — "CS 301, Section 002, Fall 2026, MWF 10:00-10:50, taught by Prof. Chen in Room 215 of the Engineering Building, capped at 40 students." A single course might have 1 section or 8 sections in a given semester. Some courses aren't offered every semester.

**Students** enroll in specific sections. A student takes maybe 4-6 sections per semester. When the semester ends, the section enrollment becomes part of their permanent academic record with a final grade.

**Faculty** are assigned to teach sections. A professor might teach 2-4 sections in a semester. Faculty belong to departments. Some courses are co-listed across departments (e.g., a course that counts as both CS and Math).

**Buildings and rooms** are scheduled — a room can only host one section at a given time slot. Rooms have capacities and features (whiteboards, projectors, lab equipment).

**Prerequisites** matter: before a student can enroll in CS 301, the system needs to verify they've completed CS 201 and CS 250 with a grade of C or better. Some prerequisites are "or" relationships (CS 250 OR Math 220).

**The questions people ask of this data:**

- A student wants to see their schedule for next semester, or their full transcript.
- A registrar wants to know: "Which sections still have open seats? Which rooms are unused at 2 PM on Tuesdays? Show me all students who haven't met prerequisites for their registered sections."
- A department chair wants: "What's the average class size in our department this semester? Which faculty are teaching overloads?"
- A faculty member wants their roster, or wants to see which of their advisees haven't registered yet.
- An auditor wants: "Show me every grade Professor Chen has ever assigned in CS 301, across all semesters."


## Your deliverable

Design the schema. Specifically:

1. List the tables you'd create. For each table, list the columns and identify primary keys and foreign keys. You don't need exact SQL syntax — a clean outline is fine, though SQL is welcome if you prefer.

2. Show how you'd handle the tricky bits. A few I want you to explicitly address:
    - Prerequisites, including "or" relationships
    - Co-listed courses (one course, multiple department associations)
    - The distinction between "course catalog entry" and "section being offered this semester"
    - A student's current enrollment vs. their historical academic record


3. Write 2-3 sentences explaining the key design decisions you made. Especially: where did you have to choose between competing options, and why did you pick what you picked? What did you optimize for, and what did you trade away?