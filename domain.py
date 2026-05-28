"""
Domain models — rich application-layer objects.

These represent how your *application* thinks about university registration,
not how the *database* stores it. Junction tables disappear; relationships
become nested objects or lists. Multiple persistence rows often collapse
into a single domain object (e.g., an Enrollment with its Section, Course,
Professor, and Semester all hydrated).

These are produced by the repository layer, which is responsible for
querying the database and assembling them from persistence models.
"""

from dataclasses import dataclass, field
from datetime import date, time
from enum import Enum
from uuid import UUID

# ---------- Enums for controlled vocabularies ----------
# In database.py these are bare strings (matching the CHECK
# constraints in SQL). At the domain layer, we promote them to enums
# so application code gets type safety and autocompletion.


class DegreeLevel(str, Enum):
    BS = "BS"
    BA = "BA"
    MS = "MS"
    MA = "MA"
    PHD = "PhD"


class EnrollmentStatus(str, Enum):
    ENROLLED = "enrolled"
    COMPLETED = "completed"
    WITHDRAWN = "withdrawn"
    DROPPED = "dropped"


class Grade(str, Enum):
    A = "A"
    A_MINUS = "A-"
    B_PLUS = "B+"
    B = "B"
    B_MINUS = "B-"
    C_PLUS = "C+"
    C = "C"
    C_MINUS = "C-"
    D_PLUS = "D+"
    D = "D"
    F = "F"
    W = "W"
    INC = "I"

    @property
    def grade_points(self) -> float:
        """Standard 4.0 scale, for GPA calculation."""
        mapping = {
            "A": 4.0,
            "A-": 3.7,
            "B+": 3.3,
            "B": 3.0,
            "B-": 2.7,
            "C+": 2.3,
            "C": 2.0,
            "C-": 1.7,
            "D+": 1.3,
            "D": 1.0,
            "F": 0.0,
            "W": 0.0,
            "I": 0.0,
        }
        return mapping[self.value]


# ---------- Spatial ----------


@dataclass
class Building:
    id: UUID
    name: str


@dataclass
class Room:
    id: UUID
    name: str
    capacity: int
    building: Building  # nested object, not building_id
    features: list[str]  # the join through RoomFeatureAssignment is hidden
    # — features are just strings at this layer


# ---------- Org units ----------


@dataclass
class Department:
    id: UUID
    name: str
    abbr: str
    head: "Faculty | None" = None  # forward reference — Faculty defined below
    faculty: list["Faculty"] = field(default_factory=list)
    # often lazy-loaded; populated only when needed


@dataclass
class Faculty:
    id: UUID
    first_name: str
    last_name: str
    department: Department

    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"


@dataclass
class Program:
    id: UUID
    name: str
    degree_level: DegreeLevel
    department: Department
    total_credit_hours: int
    required_courses: list["Course"] = field(default_factory=list)
    # junction table hidden; just a list of courses


# ---------- Courses ----------


@dataclass
class PrerequisiteGroup:
    """
    A set of courses, ANY of which (with sufficient grade) satisfies this
    part of a course's prerequisite chain. Multiple groups on a course are
    ANDed together.
    """

    options: list["Course"]
    minimum_grade: Grade

    def is_satisfied_by(self, completed: dict["Course", Grade]) -> bool:
        """Did the student complete any option with a sufficient grade?"""
        for option in self.options:
            if (
                option in completed
                and completed[option].grade_points >= self.minimum_grade.grade_points
            ):
                return True
        return False


@dataclass
class Course:
    id: UUID
    code: str
    name: str
    description: str
    credit_hours: int
    departments: list[Department]  # junction hidden
    primary_department: Department  # derived from is_primary flag
    prerequisite_groups: list[PrerequisiteGroup] = field(default_factory=list)

    def has_prerequisites_met(self, completed: dict["Course", Grade]) -> bool:
        """All groups must be satisfied (AND semantics)."""
        return all(
            group.is_satisfied_by(completed) for group in self.prerequisite_groups
        )

    def __hash__(self) -> int:
        return hash(self.id)


# ---------- Time & scheduling ----------


@dataclass
class Semester:
    id: UUID
    start_date: date
    end_date: date

    @property
    def name(self) -> str:
        year = self.start_date.year
        if self.start_date.month in (1, 2, 3, 4, 5):
            term = "Spring"
        elif self.start_date.month in (6, 7, 8):
            term = "Summer"
        else:
            term = "Fall"
        return f"{term} {year}"


@dataclass
class MeetingTime:
    day_of_week: int  # 0=Mon ... 6=Sun
    start_time: time
    end_time: time

    @property
    def day_abbr(self) -> str:
        return ["M", "T", "W", "R", "F", "S", "U"][self.day_of_week]


@dataclass
class Section:
    id: UUID
    section_number: str
    capacity: int
    course: Course  # nested, not course_id
    semester: Semester
    professor: Faculty
    room: Room
    meetings: list[MeetingTime]
    enrolled_count: int  # often derived/computed — exposed as a field
    # for convenience even though it's not "stored"

    @property
    def seats_remaining(self) -> int:
        return self.capacity - self.enrolled_count

    @property
    def is_full(self) -> bool:
        return self.seats_remaining <= 0


# ---------- Students & enrollments ----------


@dataclass
class Enrollment:
    """
    A student's participation in a section. Note this *is* exposed at the
    domain level (not hidden like a pure junction) because it has its own
    attributes — grade and status.
    """

    id: UUID
    student: "Student"
    section: Section
    grade: Grade | None
    status: EnrollmentStatus


@dataclass
class Student:
    id: UUID
    first_name: str
    last_name: str
    advisor: Faculty
    program: Program
    enrollments: list[Enrollment] = field(default_factory=list)

    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"

    @property
    def current_schedule(self) -> list[Section]:
        return [
            e.section for e in self.enrollments if e.status == EnrollmentStatus.ENROLLED
        ]

    @property
    def transcript(self) -> list[Enrollment]:
        return [e for e in self.enrollments if e.status == EnrollmentStatus.COMPLETED]

    def gpa(self) -> float:
        completed = [e for e in self.transcript if e.grade is not None]
        if not completed:
            return 0.0
        total_points = sum(
            e.grade.grade_points * e.section.course.credit_hours for e in completed if e.grade
        )
        total_credits = sum(e.section.course.credit_hours for e in completed)
        return total_points / total_credits if total_credits else 0.0
