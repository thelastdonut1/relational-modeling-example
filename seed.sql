-- ============================================================
-- Seed data for the University Course Registration system.
--
-- Scale: small but realistic — enough rows to write meaningful
-- queries and exercise every tricky part of the schema:
--
--   • Current enrollments alongside historical ones
--     (spring-2026 is completed; fall-2026 is in progress)
--   • A co-listed course: CS 240 is also MATH 240
--   • Prerequisites with both AND and OR semantics
--   • Minimum-grade prereqs (CS 250 requires CS 201 with C+ or better)
--   • Two enrollments that VIOLATE prerequisites, on purpose, to
--     support the registrar's "find them" query
--   • A withdrawal (status='withdrawn', grade='W')
--
-- IDs are human-readable strings rather than UUIDs. In production
-- you'd want UUIDs; here, `student-001` and `fac-chen` make the
-- seed itself readable as documentation of what rows mean.
-- ============================================================


-- ---------- Time ----------

INSERT INTO semesters (id, start_date, end_date) VALUES
('spring-2026', '2026-01-13', '2026-05-08'),  -- past: completed enrollments
('fall-2026',   '2026-08-24', '2026-12-11');  -- current: active enrollments


-- ---------- Spatial ----------

INSERT INTO buildings (id, name) VALUES
('bldg-eng',  'Engineering Building'),
('bldg-math', 'Mathematics Hall'),
('bldg-sci',  'Science Center');

INSERT INTO rooms (id, name, capacity, building_id) VALUES
('room-eng-101',  '101', 100, 'bldg-eng'),
('room-eng-215',  '215',  40, 'bldg-eng'),
('room-eng-310',  '310',  25, 'bldg-eng'),
('room-math-120', '120',  60, 'bldg-math'),
('room-math-220', '220',  30, 'bldg-math'),
('room-sci-150',  '150',  80, 'bldg-sci');

INSERT INTO room_features (id, name) VALUES
('feat-whiteboard',   'whiteboard'),
('feat-projector',    'projector'),
('feat-computer-lab', 'computer lab'),
('feat-recording',    'lecture recording');

INSERT INTO room_feature_assignments (room_id, feature_id) VALUES
('room-eng-101',  'feat-whiteboard'),
('room-eng-101',  'feat-projector'),
('room-eng-101',  'feat-recording'),
('room-eng-215',  'feat-whiteboard'),
('room-eng-215',  'feat-projector'),
('room-eng-310',  'feat-whiteboard'),
('room-eng-310',  'feat-projector'),
('room-eng-310',  'feat-computer-lab'),
('room-math-120', 'feat-whiteboard'),
('room-math-120', 'feat-projector'),
('room-math-220', 'feat-whiteboard'),
('room-sci-150',  'feat-whiteboard'),
('room-sci-150',  'feat-projector');


-- ---------- Org units ----------

-- Departments first with head_id NULL — faculty don't exist yet.
-- This is the nullable-FK pattern for resolving cycles between tables
-- (Department.head_id → faculty.id; Faculty.department_id → departments.id).
INSERT INTO departments (id, name, abbreviation, head_id) VALUES
('dept-cs',   'Computer Science', 'CS',   NULL),
('dept-math', 'Mathematics',      'MATH', NULL),
('dept-phys', 'Physics',          'PHYS', NULL);

INSERT INTO faculty (id, first_name, last_name, department_id) VALUES
('fac-chen',      'Wei',    'Chen',      'dept-cs'),
('fac-rodriguez', 'Maria',  'Rodriguez', 'dept-cs'),
('fac-okafor',    'Adaeze', 'Okafor',    'dept-cs'),
('fac-johnson',   'Sarah',  'Johnson',   'dept-math'),
('fac-patel',     'Raj',    'Patel',     'dept-math'),
('fac-mueller',   'Hans',   'Mueller',   'dept-phys'),
('fac-kim',       'Jihoon', 'Kim',       'dept-phys');

-- Now close the cycle — assign department heads.
UPDATE departments SET head_id = 'fac-chen'    WHERE id = 'dept-cs';
UPDATE departments SET head_id = 'fac-johnson' WHERE id = 'dept-math';
UPDATE departments SET head_id = 'fac-mueller' WHERE id = 'dept-phys';

INSERT INTO programs (id, name, degree_level, department_id, total_credit_hours) VALUES
('prog-bs-cs',   'Computer Science', 'BS', 'dept-cs',   120),
('prog-bs-math', 'Mathematics',      'BS', 'dept-math', 120),
('prog-ms-cs',   'Computer Science', 'MS', 'dept-cs',    36);

INSERT INTO students (id, first_name, last_name, advisor_id, program_id) VALUES
('student-001', 'Alex',   'Morgan',   'fac-chen',      'prog-bs-cs'),
('student-002', 'Priya',  'Sharma',   'fac-rodriguez', 'prog-bs-cs'),
('student-003', 'Jamal',  'Williams', 'fac-okafor',    'prog-bs-cs'),
('student-004', 'Emma',   'Chen',     'fac-johnson',   'prog-bs-math'),
('student-005', 'Diego',  'Martinez', 'fac-patel',     'prog-bs-math'),
('student-006', 'Sofia',  'Petrov',   'fac-chen',      'prog-ms-cs'),
('student-007', 'Marcus', 'Brown',    'fac-rodriguez', 'prog-bs-cs'),
('student-008', 'Yuki',   'Tanaka',   'fac-patel',     'prog-bs-math');


-- ---------- Catalog ----------

INSERT INTO courses (id, code, name, description, credit_hours) VALUES
('cs-101',   'CS 101',   'Introduction to Programming',
    'Foundations of programming using Python: variables, control flow, functions, basic data structures.',
    4),
('cs-201',   'CS 201',   'Data Structures',
    'Arrays, lists, trees, hash tables, graphs. Big-O analysis. Implementation in a statically-typed language.',
    4),
('cs-240',   'CS 240',   'Discrete Mathematics',
    'Logic, sets, combinatorics, graph theory, proofs. Co-listed as MATH 240.',
    3),
('cs-250',   'CS 250',   'Algorithms',
    'Algorithm design and analysis: divide-and-conquer, dynamic programming, greedy, graph algorithms.',
    4),
('cs-301',   'CS 301',   'Advanced Algorithms',
    'Approximation algorithms, randomized algorithms, NP-completeness, complexity theory.',
    3),
('math-121', 'MATH 121', 'Calculus I',
    'Limits, derivatives, integrals of single-variable functions. Fundamental theorem of calculus.',
    4),
('math-220', 'MATH 220', 'Linear Algebra',
    'Vector spaces, linear maps, matrices, eigenvalues, applications.',
    3),
('phys-101', 'PHYS 101', 'Classical Mechanics',
    'Kinematics, dynamics, energy, momentum, rotational motion. Calculus-based.',
    4);

-- Course → Department associations.
-- Most courses have exactly one (primary) department.
-- CS 240 is co-listed: belongs to BOTH CS and Math, with CS as primary.
-- This is the writeup's "is_primary flag SQL can't quite constrain" example.
INSERT INTO course_departments (course_id, department_id, is_primary) VALUES
('cs-101',   'dept-cs',   1),
('cs-201',   'dept-cs',   1),
('cs-240',   'dept-cs',   1),  -- primary listing
('cs-240',   'dept-math', 0),  -- secondary listing (the co-list)
('cs-250',   'dept-cs',   1),
('cs-301',   'dept-cs',   1),
('math-121', 'dept-math', 1),
('math-220', 'dept-math', 1),
('phys-101', 'dept-phys', 1);

INSERT INTO program_required_courses (program_id, course_id) VALUES
('prog-bs-cs',   'cs-101'),
('prog-bs-cs',   'cs-201'),
('prog-bs-cs',   'cs-240'),
('prog-bs-cs',   'cs-250'),
('prog-bs-cs',   'math-121'),
('prog-bs-cs',   'math-220'),
('prog-bs-math', 'math-121'),
('prog-bs-math', 'math-220'),
('prog-bs-math', 'cs-240'),    -- math majors take the discrete math course too
('prog-ms-cs',   'cs-250'),
('prog-ms-cs',   'cs-301');


-- ---------- Prerequisites (the interesting part) ----------
--
-- The AND-of-ORs model:
--   prerequisite_groups       — one row per OR-clause (multiple groups → ANDed)
--   prerequisite_group_options — the courses that satisfy each group
--
-- So `cs-301` having TWO groups means BOTH must be satisfied (AND).
-- A group with TWO options means EITHER one satisfies it (OR).

-- cs-201 requires cs-101 (any passing grade)
INSERT INTO prerequisite_groups (id, course_id, minimum_grade) VALUES
('preq-cs201-g1', 'cs-201', 'D');
INSERT INTO prerequisite_group_options (group_id, course_id) VALUES
('preq-cs201-g1', 'cs-101');

-- cs-240 (Discrete Math) accepts math-121 OR cs-101 — the OR case
INSERT INTO prerequisite_groups (id, course_id, minimum_grade) VALUES
('preq-cs240-g1', 'cs-240', 'D');
INSERT INTO prerequisite_group_options (group_id, course_id) VALUES
('preq-cs240-g1', 'math-121'),
('preq-cs240-g1', 'cs-101');

-- cs-250 requires cs-201 with C or better (the min-grade case)
INSERT INTO prerequisite_groups (id, course_id, minimum_grade) VALUES
('preq-cs250-g1', 'cs-250', 'C');
INSERT INTO prerequisite_group_options (group_id, course_id) VALUES
('preq-cs250-g1', 'cs-201');

-- cs-301: TWO groups (AND), the second has TWO options (OR).
-- (CS 201 with C+) AND (CS 250 OR Math 220, with C+).
INSERT INTO prerequisite_groups (id, course_id, minimum_grade) VALUES
('preq-cs301-g1', 'cs-301', 'C'),
('preq-cs301-g2', 'cs-301', 'C');
INSERT INTO prerequisite_group_options (group_id, course_id) VALUES
('preq-cs301-g1', 'cs-201'),
('preq-cs301-g2', 'cs-250'),
('preq-cs301-g2', 'math-220');

-- math-220 requires math-121
INSERT INTO prerequisite_groups (id, course_id, minimum_grade) VALUES
('preq-math220-g1', 'math-220', 'D');
INSERT INTO prerequisite_group_options (group_id, course_id) VALUES
('preq-math220-g1', 'math-121');

-- phys-101 requires math-121
INSERT INTO prerequisite_groups (id, course_id, minimum_grade) VALUES
('preq-phys101-g1', 'phys-101', 'D');
INSERT INTO prerequisite_group_options (group_id, course_id) VALUES
('preq-phys101-g1', 'math-121');


-- ---------- Sections ----------
--
-- Two semesters: spring-2026 (past), fall-2026 (current).
-- Capacity, professor, and room are all assigned. Section times are
-- non-overlapping in shared rooms (a constraint SQL can't enforce —
-- see writeup — but the seed respects it so queries return clean answers).

INSERT INTO sections (id, section_number, capacity, course_id, semester_id, professor_id, room_id) VALUES
-- Spring 2026 (completed)
('sec-cs101-sp26-01',   '001', 100, 'cs-101',   'spring-2026', 'fac-chen',      'room-eng-101'),
('sec-cs101-sp26-02',   '002', 100, 'cs-101',   'spring-2026', 'fac-rodriguez', 'room-eng-101'),
('sec-cs201-sp26-01',   '001',  40, 'cs-201',   'spring-2026', 'fac-chen',      'room-eng-215'),
('sec-math121-sp26-01', '001',  60, 'math-121', 'spring-2026', 'fac-johnson',   'room-math-120'),
('sec-math121-sp26-02', '002',  60, 'math-121', 'spring-2026', 'fac-patel',     'room-math-120'),
('sec-math220-sp26-01', '001',  30, 'math-220', 'spring-2026', 'fac-patel',     'room-math-220'),

-- Fall 2026 (in progress)
('sec-cs101-fa26-01',   '001', 100, 'cs-101',   'fall-2026', 'fac-rodriguez', 'room-eng-101'),
('sec-cs201-fa26-01',   '001',  40, 'cs-201',   'fall-2026', 'fac-chen',      'room-eng-215'),
('sec-cs201-fa26-02',   '002',  25, 'cs-201',   'fall-2026', 'fac-okafor',    'room-eng-310'),
('sec-cs240-fa26-01',   '001',  25, 'cs-240',   'fall-2026', 'fac-rodriguez', 'room-eng-310'),
('sec-cs250-fa26-01',   '001',  40, 'cs-250',   'fall-2026', 'fac-chen',      'room-eng-215'),
('sec-cs301-fa26-01',   '001',  25, 'cs-301',   'fall-2026', 'fac-chen',      'room-eng-310'),
('sec-math121-fa26-01', '001',  60, 'math-121', 'fall-2026', 'fac-johnson',   'room-math-120'),
('sec-math220-fa26-01', '001',  30, 'math-220', 'fall-2026', 'fac-patel',     'room-math-220'),
('sec-phys101-fa26-01', '001',  80, 'phys-101', 'fall-2026', 'fac-mueller',   'room-sci-150');

-- Meeting times. MWF = three rows, TR = two rows.
-- day_of_week: 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri.

INSERT INTO section_meetings (id, section_id, day_of_week, start_time, end_time) VALUES
-- Spring 2026
('mt-cs101-sp26-01-m',   'sec-cs101-sp26-01',   0, '09:00', '09:50'),
('mt-cs101-sp26-01-w',   'sec-cs101-sp26-01',   2, '09:00', '09:50'),
('mt-cs101-sp26-01-f',   'sec-cs101-sp26-01',   4, '09:00', '09:50'),
('mt-cs101-sp26-02-m',   'sec-cs101-sp26-02',   0, '10:00', '10:50'),
('mt-cs101-sp26-02-w',   'sec-cs101-sp26-02',   2, '10:00', '10:50'),
('mt-cs101-sp26-02-f',   'sec-cs101-sp26-02',   4, '10:00', '10:50'),
('mt-cs201-sp26-01-t',   'sec-cs201-sp26-01',   1, '09:30', '10:45'),
('mt-cs201-sp26-01-r',   'sec-cs201-sp26-01',   3, '09:30', '10:45'),
('mt-math121-sp26-01-m', 'sec-math121-sp26-01', 0, '10:00', '10:50'),
('mt-math121-sp26-01-w', 'sec-math121-sp26-01', 2, '10:00', '10:50'),
('mt-math121-sp26-01-f', 'sec-math121-sp26-01', 4, '10:00', '10:50'),
('mt-math121-sp26-02-m', 'sec-math121-sp26-02', 0, '11:00', '11:50'),
('mt-math121-sp26-02-w', 'sec-math121-sp26-02', 2, '11:00', '11:50'),
('mt-math121-sp26-02-f', 'sec-math121-sp26-02', 4, '11:00', '11:50'),
('mt-math220-sp26-01-t', 'sec-math220-sp26-01', 1, '11:00', '12:15'),
('mt-math220-sp26-01-r', 'sec-math220-sp26-01', 3, '11:00', '12:15'),
-- Fall 2026
('mt-cs101-fa26-01-m',   'sec-cs101-fa26-01',   0, '09:00', '09:50'),
('mt-cs101-fa26-01-w',   'sec-cs101-fa26-01',   2, '09:00', '09:50'),
('mt-cs101-fa26-01-f',   'sec-cs101-fa26-01',   4, '09:00', '09:50'),
('mt-cs201-fa26-01-t',   'sec-cs201-fa26-01',   1, '09:30', '10:45'),
('mt-cs201-fa26-01-r',   'sec-cs201-fa26-01',   3, '09:30', '10:45'),
('mt-cs201-fa26-02-t',   'sec-cs201-fa26-02',   1, '14:00', '15:15'),
('mt-cs201-fa26-02-r',   'sec-cs201-fa26-02',   3, '14:00', '15:15'),
('mt-cs240-fa26-01-m',   'sec-cs240-fa26-01',   0, '13:00', '13:50'),
('mt-cs240-fa26-01-w',   'sec-cs240-fa26-01',   2, '13:00', '13:50'),
('mt-cs240-fa26-01-f',   'sec-cs240-fa26-01',   4, '13:00', '13:50'),
('mt-cs250-fa26-01-m',   'sec-cs250-fa26-01',   0, '11:00', '11:50'),
('mt-cs250-fa26-01-w',   'sec-cs250-fa26-01',   2, '11:00', '11:50'),
('mt-cs250-fa26-01-f',   'sec-cs250-fa26-01',   4, '11:00', '11:50'),
('mt-cs301-fa26-01-t',   'sec-cs301-fa26-01',   1, '11:00', '12:15'),
('mt-cs301-fa26-01-r',   'sec-cs301-fa26-01',   3, '11:00', '12:15'),
('mt-math121-fa26-01-m', 'sec-math121-fa26-01', 0, '10:00', '10:50'),
('mt-math121-fa26-01-w', 'sec-math121-fa26-01', 2, '10:00', '10:50'),
('mt-math121-fa26-01-f', 'sec-math121-fa26-01', 4, '10:00', '10:50'),
('mt-math220-fa26-01-t', 'sec-math220-fa26-01', 1, '14:00', '15:15'),
('mt-math220-fa26-01-r', 'sec-math220-fa26-01', 3, '14:00', '15:15'),
('mt-phys101-fa26-01-m', 'sec-phys101-fa26-01', 0, '11:00', '11:50'),
('mt-phys101-fa26-01-w', 'sec-phys101-fa26-01', 2, '11:00', '11:50'),
('mt-phys101-fa26-01-f', 'sec-phys101-fa26-01', 4, '11:00', '11:50');


-- ---------- Enrollments ----------
--
-- Spring 2026 — status 'completed', with final grades.

INSERT INTO enrollments (id, student_id, section_id, grade, status) VALUES
('enr-001', 'student-001', 'sec-cs101-sp26-01',   'A',  'completed'),
('enr-002', 'student-001', 'sec-math121-sp26-01', 'B+', 'completed'),
('enr-003', 'student-002', 'sec-cs101-sp26-01',   'B',  'completed'),
('enr-004', 'student-002', 'sec-math121-sp26-02', 'C+', 'completed'),
('enr-005', 'student-003', 'sec-cs101-sp26-02',   'A-', 'completed'),
('enr-006', 'student-004', 'sec-math121-sp26-01', 'A',  'completed'),
('enr-007', 'student-005', 'sec-math121-sp26-02', 'B',  'completed'),
('enr-008', 'student-005', 'sec-math220-sp26-01', 'A-', 'completed'),
('enr-009', 'student-006', 'sec-cs201-sp26-01',   'A',  'completed'),
('enr-010', 'student-008', 'sec-math121-sp26-01', 'A',  'completed'),
-- A withdrawal — status 'withdrawn', grade 'W'.
('enr-011', 'student-007', 'sec-cs101-sp26-02',   'W',  'withdrawn');


-- Fall 2026 — status 'enrolled', no grade yet (semester in progress).

INSERT INTO enrollments (id, student_id, section_id, grade, status) VALUES
-- Compliant enrollments (prereqs satisfied):
('enr-012', 'student-001', 'sec-cs201-fa26-01',   NULL, 'enrolled'),  -- CS 101: A
('enr-013', 'student-001', 'sec-math220-fa26-01', NULL, 'enrolled'),  -- Math 121: B+
('enr-014', 'student-001', 'sec-cs240-fa26-01',   NULL, 'enrolled'),  -- either CS 101 or Math 121
('enr-015', 'student-002', 'sec-cs201-fa26-02',   NULL, 'enrolled'),  -- CS 101: B
('enr-016', 'student-003', 'sec-cs201-fa26-01',   NULL, 'enrolled'),  -- CS 101: A-
('enr-017', 'student-004', 'sec-cs240-fa26-01',   NULL, 'enrolled'),  -- Math 121: A
('enr-018', 'student-005', 'sec-phys101-fa26-01', NULL, 'enrolled'),  -- Math 121: B
('enr-019', 'student-005', 'sec-cs240-fa26-01',   NULL, 'enrolled'),  -- Math 121: B
('enr-020', 'student-006', 'sec-cs250-fa26-01',   NULL, 'enrolled'),  -- CS 201: A (≥ C ✓)
('enr-021', 'student-008', 'sec-math220-fa26-01', NULL, 'enrolled'),  -- Math 121: A

-- INTENTIONAL prereq violations — to demonstrate the registrar's query
-- "students who haven't met prerequisites for their registered sections":
('enr-022', 'student-007', 'sec-cs201-fa26-01',   NULL, 'enrolled'),  -- CS 101 only 'W', no credit
('enr-023', 'student-006', 'sec-cs301-fa26-01',   NULL, 'enrolled');  -- missing CS 250 AND Math 220