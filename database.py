"""
Persistence models — flat dataclasses, one per database table.

Each class corresponds 1:1 with a table in schema.sql. Foreign keys are
represented as raw UUIDs. There are no nested objects or collections here —
this is the shape data takes when it crosses the database boundary.

These objects are typically only seen inside the repository layer. Application
code should work with domain models (see domain.py).
"""

from dataclasses import dataclass
from datetime import date, time
from uuid import UUID


@dataclass
class SemesterRow:
    id: UUID
    start_date: date
    end_date: date


@dataclass
class BuildingRow:
    id: UUID
    name: str


@dataclass
class RoomRow:
    id: UUID
    name: str
    capacity: int
    building_id: UUID


@dataclass
class RoomFeatureRow:
    id: UUID
    name: str


@dataclass
class RoomFeatureAssignmentRow:
    room_id: UUID
    feature_id: UUID


@dataclass
class DepartmentRow:
    id: UUID
    name: str
    abbr: str
    head_id: UUID | None


@dataclass
class FacultyRow:
    id: UUID
    first_name: str
    last_name: str
    department_id: UUID


@dataclass
class ProgramRow:
    id: UUID
    name: str
    degree_level: str
    department_id: UUID
    total_credit_hours: int


@dataclass
class ProgramRequiredCourseRow:
    program_id: UUID
    course_id: UUID


@dataclass
class StudentRow:
    id: UUID
    first_name: str
    last_name: str
    advisor_id: UUID
    program_id: UUID


@dataclass
class CourseRow:
    id: UUID
    code: str
    name: str
    description: str
    credit_hours: int


@dataclass
class CourseDepartmentRow:
    course_id: UUID
    department_id: UUID
    is_primary: bool


@dataclass
class PrerequisiteGroupRow:
    id: UUID
    course_id: UUID
    minimum_grade: str


@dataclass
class PrerequisiteGroupOptionRow:
    group_id: UUID
    course_id: UUID


@dataclass
class SectionRow:
    id: UUID
    section_number: str
    capacity: int
    course_id: UUID
    semester_id: UUID
    professor_id: UUID
    room_id: UUID


@dataclass
class SectionMeetingRow:
    id: UUID
    section_id: UUID
    day_of_week: int
    start_time: time
    end_time: time


@dataclass
class EnrollmentRow:
    id: UUID
    student_id: UUID
    section_id: UUID
    grade: str | None
    status: str
