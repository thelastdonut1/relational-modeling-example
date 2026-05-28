CREATE TABLE semesters (
    id TEXT PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CHECK (end_date > start_date)
);

CREATE TABLE buildings (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE rooms (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    building_id TEXT NOT NULL REFERENCES buildings(id)
    UNIQUE (building_id, name)
);

CREATE TABLE room_features (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

-- Junction table for many-to-many relationship between rooms and features
CREATE TABLE room_feature_assignments (
    room_id TEXT NOT NULL REFERENCES rooms(id),
    feature_id TEXT NOT NULL REFERENCES room_features(id),
    PRIMARY KEY (room_id, feature_id)
);

CREATE TABLE departments (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    abbreviation TEXT NOT NULL UNIQUE,
    head_id TEXT REFERENCES faculty(id)  -- NULLABLE: chicken-and-egg with faculty table
);

CREATE TABLE faculty (
    id TEXT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    department_id TEXT NOT NULL REFERENCES departments(id)
);

CREATE TABLE programs (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    degree_level TEXT NOT NULL CHECK (degree_level IN ('BS', 'BA', 'MS', 'MA', 'PhD')),
    department_id TEXT NOT NULL REFERENCES departments(id),
    total_credit_hours INTEGER NOT NULL CHECK (total_credit_hours > 0),
    UNIQUE (name, degree_level)
);

CREATE TABLE students (
    id TEXT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    advisor_id TEXT NOT NULL REFERENCES faculty(id),
    program_id TEXT NOT NULL REFERENCES programs(id)
);

CREATE TABLE courses (
    id TEXT PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    credit_hours INTEGER NOT NULL CHECK (credit_hours > 0),
);

-- Junction table for many-to-many relationship between courses and departments
CREATE TABLE course_departments (
    course_id TEXT NOT NULL REFERENCES courses(id),
    department_id TEXT NOT NULL REFERENCES departments(id),
    is_primary INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (course_id, department_id)
);

-- Each course should have exactly one primary department.
-- SQLite can't enforce this with a simple constraint; would need a trigger,
-- or you enforce it at the application layer.

-- Junction table for many-to-many relationship between programs and required courses
CREATE TABLE program_required_courses (
    program_id TEXT NOT NULL REFERENCES programs(id),
    course_id TEXT NOT NULL REFERENCES courses(id),
    PRIMARY KEY (program_id, course_id)
);

CREATE TABLE prerequisite_groups (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL REFERENCES courses(id),
    minimum_grade TEXT NOT NULL DEFAULT 'D'
        CHECK (minimum_grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D'))
);

-- Junction table for many-to-many relationship between prerequisite groups and courses
CREATE TABLE prerequisite_group_options(
    group_id TEXT NOT NULL REFERENCES prerequisite_groups(id),
    course_id TEXT NOT NULL REFERENCES courses(id),
    PRIMARY KEY (group_id, course_id)
);

CREATE TABLE sections (
    id TEXT PRIMARY KEY,
    section_number TEXT NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    course_id TEXT NOT NULL REFERENCES courses(id),
    semester_id TEXT NOT NULL REFERENCES semesters(id),
    professor_id TEXT NOT NULL REFERENCES faculty(id),
    room_id TEXT NOT NULL REFERENCES rooms(id),
    UNIQUE (course_id, section_number, semester_id)
);

CREATE TABLE section_meetings (
    id TEXT PRIMARY KEY,
    section_id TEXT NOT NULL REFERENCES sections(id),
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CHECK (end_time > start_time)
);

-- Note: enforcing "no room double-booked at the same time" requires
-- either a trigger or application-level checking. SQL constraints
-- can't express overlap detection across rows portably.

CREATE TABLE enrollments (
    id TEXT PRIMARY KEY,
    student_id TEXT NOT NULL REFERENCES students(id),
    section_id TEXT NOT NULL REFERENCES sections(id),
    grade TEXT CHECK (grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'I', 'W')),
    status TEXT NOT NULL CHECK (status IN ('enrolled', 'completed', 'dropped', 'withdrawn')),
    UNIQUE (student_id, section_id)
);

-- INDEXES

CREATE INDEX idx_faculty_department ON faculty(department_id);
CREATE INDEX idx_students_advisor ON students(advisor_id);
CREATE INDEX idx_students_program ON students(program_id);
CREATE INDEX idx_sections_semester ON sections(semester_id);
CREATE INDEX idx_sections_course ON sections(course_id);
CREATE INDEX idx_sections_professor ON sections(professor_id);
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_section ON enrollments(section_id);
CREATE INDEX idx_section_meetings_room ON section_meetings(section_id);
