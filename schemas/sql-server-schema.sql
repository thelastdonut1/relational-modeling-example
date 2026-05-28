-- SQL Server 2017+ assumed

CREATE TABLE semesters (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    name NVARCHAR(64) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CONSTRAINT chk_semesters_dates CHECK (end_date > start_date)
);

CREATE TABLE buildings (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    name NVARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE rooms (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    name NVARCHAR(64) NOT NULL,
    capacity INT NOT NULL CONSTRAINT chk_rooms_capacity CHECK (capacity > 0),
    building_id UNIQUEIDENTIFIER NOT NULL REFERENCES buildings(id),
    CONSTRAINT uq_rooms_building_name UNIQUE (building_id, name)
);

CREATE TABLE room_features (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    name NVARCHAR(64) NOT NULL UNIQUE
);

CREATE TABLE room_feature_assignments (
    room_id UNIQUEIDENTIFIER NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    feature_id UNIQUEIDENTIFIER NOT NULL REFERENCES room_features(id) ON DELETE CASCADE,
    PRIMARY KEY (room_id, feature_id)
);

CREATE TABLE departments (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    name NVARCHAR(128) NOT NULL UNIQUE,
    abbreviation NVARCHAR(16) NOT NULL UNIQUE,
    head_id UNIQUEIDENTIFIER NULL,  -- FK added after faculty exists
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE faculty (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    first_name NVARCHAR(64) NOT NULL,
    last_name NVARCHAR(64) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    department_id UNIQUEIDENTIFIER NOT NULL REFERENCES departments(id),
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

ALTER TABLE departments
    ADD CONSTRAINT fk_departments_head
    FOREIGN KEY (head_id) REFERENCES faculty(id);

CREATE TABLE programs (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    name NVARCHAR(128) NOT NULL,
    degree_level NVARCHAR(8) NOT NULL
        CONSTRAINT chk_programs_degree
        CHECK (degree_level IN ('BS', 'BA', 'MS', 'MA', 'PhD')),
    department_id UNIQUEIDENTIFIER NOT NULL REFERENCES departments(id),
    total_credit_hours INT NOT NULL
        CONSTRAINT chk_programs_hours CHECK (total_credit_hours > 0),
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT uq_programs_name_level UNIQUE (name, degree_level)
);

CREATE TABLE students (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    first_name NVARCHAR(64) NOT NULL,
    last_name NVARCHAR(64) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    advisor_id UNIQUEIDENTIFIER NOT NULL REFERENCES faculty(id),
    program_id UNIQUEIDENTIFIER NOT NULL REFERENCES programs(id),
    enrolled_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    is_active BIT NOT NULL DEFAULT 1
);

CREATE TABLE courses (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    code NVARCHAR(16) NOT NULL UNIQUE,
    name NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    credit_hours INT NOT NULL
        CONSTRAINT chk_courses_hours CHECK (credit_hours > 0),
    is_active BIT NOT NULL DEFAULT 1
);

CREATE TABLE course_departments (
    course_id UNIQUEIDENTIFIER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    department_id UNIQUEIDENTIFIER NOT NULL REFERENCES departments(id),
    is_primary BIT NOT NULL DEFAULT 0,
    PRIMARY KEY (course_id, department_id)
);

-- SQL Server supports filtered indexes — like Postgres partial indexes
CREATE UNIQUE INDEX uq_one_primary_department_per_course
    ON course_departments (course_id)
    WHERE is_primary = 1;

CREATE TABLE program_required_courses (
    program_id UNIQUEIDENTIFIER NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    course_id UNIQUEIDENTIFIER NOT NULL REFERENCES courses(id),
    PRIMARY KEY (program_id, course_id)
);

CREATE TABLE prerequisite_groups (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    course_id UNIQUEIDENTIFIER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    minimum_grade NVARCHAR(2) NOT NULL DEFAULT 'D'
        CONSTRAINT chk_prereq_grade
        CHECK (minimum_grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D'))
);

CREATE TABLE prerequisite_group_options (
    group_id UNIQUEIDENTIFIER NOT NULL REFERENCES prerequisite_groups(id) ON DELETE CASCADE,
    course_id UNIQUEIDENTIFIER NOT NULL REFERENCES courses(id),
    PRIMARY KEY (group_id, course_id)
);

CREATE TABLE sections (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    section_number NVARCHAR(16) NOT NULL,
    capacity INT NOT NULL CONSTRAINT chk_sections_capacity CHECK (capacity > 0),
    course_id UNIQUEIDENTIFIER NOT NULL REFERENCES courses(id),
    semester_id UNIQUEIDENTIFIER NOT NULL REFERENCES semesters(id),
    professor_id UNIQUEIDENTIFIER NOT NULL REFERENCES faculty(id),
    room_id UNIQUEIDENTIFIER NOT NULL REFERENCES rooms(id),
    CONSTRAINT uq_sections UNIQUE (course_id, section_number, semester_id)
);

CREATE TABLE section_meetings (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    section_id UNIQUEIDENTIFIER NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    day_of_week TINYINT NOT NULL
        CONSTRAINT chk_meeting_day CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CONSTRAINT chk_meeting_times CHECK (end_time > start_time)
);

CREATE TABLE enrollments (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    student_id UNIQUEIDENTIFIER NOT NULL REFERENCES students(id),
    section_id UNIQUEIDENTIFIER NOT NULL REFERENCES sections(id),
    grade NVARCHAR(2) NULL
        CONSTRAINT chk_enrollment_grade
        CHECK (grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'I', 'W')),
    status NVARCHAR(16) NOT NULL
        CONSTRAINT chk_enrollment_status
        CHECK (status IN ('enrolled', 'completed', 'dropped', 'withdrawn')),
    enrolled_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT uq_enrollment UNIQUE (student_id, section_id),
    CONSTRAINT chk_enrollment_status_grade CHECK (
        (status = 'completed' AND grade IS NOT NULL)
        OR (status = 'enrolled' AND grade IS NULL)
        OR (status = 'dropped' AND grade IS NULL)
        OR (status = 'withdrawn' AND grade = 'W')
    )
);

-- Trigger to update `updated_at` on row modifications (SQL Server has no
-- equivalent to MySQL's ON UPDATE CURRENT_TIMESTAMP)
CREATE TRIGGER trg_enrollments_updated_at
ON enrollments
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE e
    SET updated_at = SYSUTCDATETIME()
    FROM enrollments e
    INNER JOIN inserted i ON e.id = i.id;
END;

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