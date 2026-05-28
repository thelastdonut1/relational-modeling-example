SELECT
	s.id AS student_id,
	s.first_name || ' ' || s.last_name AS student_name,
	p.name AS program_name
FROM students s
JOIN programs p ON p.id = s.program_id
ORDER BY s.id;
