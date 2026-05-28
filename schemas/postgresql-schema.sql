-- Enable UUID generation (built into PostgreSQL 13+)
-- If on older Postgres, use: CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ENUMS replace the CHECK-with-string-list pattern
CREATE TYPE degree_level AS ENUM ('BS', 'BA', 'MS', 'MA', 'PhD');

CREATE TYPE letter_grade AS ENUM (
    'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D'
);

CREATE TYPE final_grade AS ENUM (
    'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'I', 'W'
);

CREATE TYPE enrollment_status AS ENUM (
    'enrolled', 'completed', 'dropped', 'withdrawn'
);

CREATE TABLE semesters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CHECK (end_date > start_date)
);

CREATE TABLE buildings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    building_id UUID NOT NULL REFERENCES buildings(id),
    UNIQUE (building_id, name)
);

CREATE TABLE room_features (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE room_feature_assignments (
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    feature_id UUID NOT NULL REFERENCES room_features(id) ON DELETE CASCADE,
    PRIMARY KEY (room_id, feature_id)
);

-- Forward-reference workaround: create departments without head_id,
-- create faculty, then ALTER to add the FK.
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    abbreviation TEXT NOT NULL UNIQUE,
    head_id UUID,  -- FK added after faculty exists
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE faculty (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    department_id UUID NOT NULL REFERENCES departments(id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE departments
    ADD CONSTRAINT departments_head_id_fkey
    FOREIGN KEY (head_id) REFERENCES faculty(id);

CREATE TABLE programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    degree_level degree_level NOT NULL,
    department_id UUID NOT NULL REFERENCES departments(id),
    total_credit_hours INTEGER NOT NULL CHECK (total_credit_hours > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (name, degree_level)
);

CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    advisor_id UUID NOT NULL REFERENCES faculty(id),
    program_id UUID NOT NULL REFERENCES programs(id),
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    credit_hours INTEGER NOT NULL CHECK (credit_hours > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE course_departments (
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    department_id UUID NOT NULL REFERENCES departments(id),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (course_id, department_id)
);

-- Enforce "exactly one primary department per course" with a partial unique index.
-- This is a Postgres-specific feature that SQLite's comment said it couldn't do.
CREATE UNIQUE INDEX one_primary_department_per_course
    ON course_departments (course_id)
    WHERE is_primary = TRUE;

CREATE TABLE program_required_courses (
    program_id UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id),
    PRIMARY KEY (program_id, course_id)
);

CREATE TABLE prerequisite_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    minimum_grade letter_grade NOT NULL DEFAULT 'D'
);

CREATE TABLE prerequisite_group_options (
    group_id UUID NOT NULL REFERENCES prerequisite_groups(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id),
    PRIMARY KEY (group_id, course_id)
);

CREATE TABLE sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_number TEXT NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    course_id UUID NOT NULL REFERENCES courses(id),
    semester_id UUID NOT NULL REFERENCES semesters(id),
    professor_id UUID NOT NULL REFERENCES faculty(id),
    room_id UUID NOT NULL REFERENCES rooms(id),
    UNIQUE (course_id, section_number, semester_id)
);

CREATE TABLE section_meetings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),  -- 0 = Monday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CHECK (end_time > start_time)
);

CREATE TABLE enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id),
    section_id UUID NOT NULL REFERENCES sections(id),
    grade final_grade,
    status enrollment_status NOT NULL,
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (student_id, section_id),
    -- Completed enrollments must have a grade; non-completed must not have a letter grade
    -- (W is its own special case handled via 'withdrawn' status + 'W' grade)
    CHECK (
        (status = 'completed' AND grade IS NOT NULL)
        OR (status = 'enrolled' AND grade IS NULL)
        OR (status = 'dropped' AND grade IS NULL)
        OR (status = 'withdrawn' AND grade = 'W')
    )
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
CREATE INDEX idx_section_meetings_section ON section_meetings(section_id);
CREATE INDEX idx_rfa_feature ON room_feature_assignments(feature_id);