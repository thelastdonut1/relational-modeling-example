-- MySQL 8.0+ assumed throughout

CREATE TABLE semesters (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(64) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CHECK (end_date > start_date)
) ENGINE=InnoDB;

CREATE TABLE buildings (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(128) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE rooms (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(64) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    building_id CHAR(36) NOT NULL,
    UNIQUE (building_id, name),
    FOREIGN KEY (building_id) REFERENCES buildings(id)
) ENGINE=InnoDB;

CREATE TABLE room_features (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(64) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE room_feature_assignments (
    room_id CHAR(36) NOT NULL,
    feature_id CHAR(36) NOT NULL,
    PRIMARY KEY (room_id, feature_id),
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (feature_id) REFERENCES room_features(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Forward-reference workaround: create departments without head_id FK,
-- create faculty, then ALTER.
CREATE TABLE departments (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(128) NOT NULL UNIQUE,
    abbreviation VARCHAR(16) NOT NULL UNIQUE,
    head_id CHAR(36),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE faculty (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    first_name VARCHAR(64) NOT NULL,
    last_name VARCHAR(64) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department_id CHAR(36) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(id)
) ENGINE=InnoDB;

ALTER TABLE departments
    ADD CONSTRAINT departments_head_id_fkey
    FOREIGN KEY (head_id) REFERENCES faculty(id);

CREATE TABLE programs (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(128) NOT NULL,
    degree_level ENUM('BS', 'BA', 'MS', 'MA', 'PhD') NOT NULL,
    department_id CHAR(36) NOT NULL,
    total_credit_hours INT NOT NULL CHECK (total_credit_hours > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (name, degree_level),
    FOREIGN KEY (department_id) REFERENCES departments(id)
) ENGINE=InnoDB;

CREATE TABLE students (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    first_name VARCHAR(64) NOT NULL,
    last_name VARCHAR(64) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    advisor_id CHAR(36) NOT NULL,
    program_id CHAR(36) NOT NULL,
    enrolled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (advisor_id) REFERENCES faculty(id),
    FOREIGN KEY (program_id) REFERENCES programs(id)
) ENGINE=InnoDB;

CREATE TABLE courses (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    code VARCHAR(16) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    credit_hours INT NOT NULL CHECK (credit_hours > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE course_departments (
    course_id CHAR(36) NOT NULL,
    department_id CHAR(36) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    -- Generated column for partial-unique workaround
    primary_marker CHAR(36) AS (IF(is_primary, course_id, NULL)) STORED,
    PRIMARY KEY (course_id, department_id),
    UNIQUE (primary_marker),
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(id)
) ENGINE=InnoDB;

CREATE TABLE program_required_courses (
    program_id CHAR(36) NOT NULL,
    course_id CHAR(36) NOT NULL,
    PRIMARY KEY (program_id, course_id),
    FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id)
) ENGINE=InnoDB;

CREATE TABLE prerequisite_groups (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    course_id CHAR(36) NOT NULL,
    minimum_grade ENUM('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D')
        NOT NULL DEFAULT 'D',
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE prerequisite_group_options (
    group_id CHAR(36) NOT NULL,
    course_id CHAR(36) NOT NULL,
    PRIMARY KEY (group_id, course_id),
    FOREIGN KEY (group_id) REFERENCES prerequisite_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id)
) ENGINE=InnoDB;

CREATE TABLE sections (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    section_number VARCHAR(16) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    course_id CHAR(36) NOT NULL,
    semester_id CHAR(36) NOT NULL,
    professor_id CHAR(36) NOT NULL,
    room_id CHAR(36) NOT NULL,
    UNIQUE (course_id, section_number, semester_id),
    FOREIGN KEY (course_id) REFERENCES courses(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (professor_id) REFERENCES faculty(id),
    FOREIGN KEY (room_id) REFERENCES rooms(id)
) ENGINE=InnoDB;

CREATE TABLE section_meetings (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    section_id CHAR(36) NOT NULL,
    day_of_week TINYINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),  -- 0 = Monday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CHECK (end_time > start_time),
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE enrollments (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    student_id CHAR(36) NOT NULL,
    section_id CHAR(36) NOT NULL,
    grade ENUM('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'I', 'W'),
    status ENUM('enrolled', 'completed', 'dropped', 'withdrawn') NOT NULL,
    enrolled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE (student_id, section_id),
    CHECK (
        (status = 'completed' AND grade IS NOT NULL)
        OR (status = 'enrolled' AND grade IS NULL)
        OR (status = 'dropped' AND grade IS NULL)
        OR (status = 'withdrawn' AND grade = 'W')
    ),
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (section_id) REFERENCES sections(id)
) ENGINE=InnoDB;

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