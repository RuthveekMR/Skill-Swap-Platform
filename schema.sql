CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  location TEXT,
  availability BOOLEAN DEFAULT TRUE,
  profile_photo TEXT,
  is_public BOOLEAN DEFAULT TRUE,
  role TEXT DEFAULT 'user',
  warnings INT DEFAULT 0
);

CREATE TABLE skills_offered (
  user_id INT NOT NULL,
  skill TEXT NOT NULL,
  PRIMARY KEY (user_id, skill),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE skills_wanted (
  user_id INT NOT NULL,
  skill TEXT NOT NULL,
  PRIMARY KEY (user_id, skill),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE swap_requests (
  s_id SERIAL PRIMARY KEY,
  from_user_id INT NOT NULL,
  to_user_id INT NOT NULL,
  message TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE feedback (
  user_id INT NOT NULL,
  target_user_id INT NOT NULL,
  swap_id INT NOT NULL,
  rating INT CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  PRIMARY KEY (user_id, swap_id),
  FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (swap_id) REFERENCES swap_requests(s_id) ON DELETE CASCADE
);

insert into users (id,name, email, password_hash, location, availability, profile_photo, is_public, role, warnings) values
(1,'Alice', 'alice@example.com', 'hash_alice', 'New York', TRUE, 'http://example.com/alice.jpg', TRUE, 'user', 0),
(2,'Bob', 'bob@example.com', 'hash_bob', 'San Francisco', TRUE, NULL, TRUE, 'user', 0),
(3,'Charlie', 'charlie@example.com', 'hash_charlie', 'Chicago', FALSE, NULL, FALSE, 'user', 1);


insert into skills_offered (user_id, skill) values
(1, 'Python'),
(1, 'Guitar'),
(2, 'Spanish'),
(3, 'JavaScript');


insert into skills_wanted (user_id, skill) values
(1, 'Spanish'),
(2, 'Python'),
(3, 'Guitar');


insert into swap_requests (s_id,from_user_id, to_user_id, message, status, created_at) values
(1,1, 2, 'Hi Bob, want to swap Python lessons for Spanish?', 'pending', NOW()),
(2,3, 1, 'Alice, interested in a JavaScript-Guitar swap?', 'accepted', NOW());


insert into feedback (user_id, target_user_id, swap_id, rating, comment) values
(1, 2, 1, 5, 'Great exchange! Learned a lot.'),
(3, 1, 2, 4, 'Good experience, but scheduling was tough.');


CREATE OR REPLACE FUNCTION insert_user_with_skills(
    p_name TEXT,
    p_email TEXT,
    p_password_hash TEXT,
    p_location TEXT,
    p_availability BOOLEAN DEFAULT TRUE,
    p_profile_photo TEXT DEFAULT NULL,
    p_is_public BOOLEAN DEFAULT TRUE,
    p_role TEXT DEFAULT 'user',
    p_warnings INT DEFAULT 0,
    p_skills_offered TEXT[] DEFAULT ARRAY[]::TEXT[],
    p_skills_wanted TEXT[] DEFAULT ARRAY[]::TEXT[]
)
RETURNS VOID AS $$
DECLARE
    new_user_id INT;
    skill TEXT;
BEGIN
    -- Insert into users
    INSERT INTO users (
        name, email, password_hash, location,
        availability, profile_photo, is_public, role, warnings
    )
    VALUES (
        p_name, p_email, p_password_hash, p_location,
        p_availability, p_profile_photo, p_is_public, p_role, p_warnings
    )
    RETURNING id INTO new_user_id;

    -- Insert skills offered
    FOREACH skill IN ARRAY p_skills_offered LOOP
        INSERT INTO skills_offered (user_id, skill)
        VALUES (new_user_id, skill);
    END LOOP;

    -- Insert skills wanted
    FOREACH skill IN ARRAY p_skills_wanted LOOP
        INSERT INTO skills_wanted (user_id, skill)
        VALUES (new_user_id, skill);
    END LOOP;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION create_swap_request(
    p_from_user_id INT,
    p_to_user_id INT,
    p_message TEXT,
    p_status TEXT DEFAULT 'pending'
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO swap_requests (
        from_user_id, to_user_id, message, status
    )
    VALUES (
        p_from_user_id, p_to_user_id, p_message, p_status
    );
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION leave_feedback(
    p_user_id INT,
    p_target_user_id INT,
    p_swap_id INT,
    p_rating INT,
    p_comment TEXT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO feedback (
        user_id, target_user_id, swap_id, rating, comment
    )
    VALUES (
        p_user_id, p_target_user_id, p_swap_id, p_rating, p_comment
    );
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION update_swap_status(
    p_swap_id INT,
    p_new_status TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE swap_requests
    SET status = p_new_status
    WHERE s_id = p_swap_id;
END;
$$ LANGUAGE plpgsql;

SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));


SELECT insert_user_with_skills(
    'Alice',
    'alice1@example.com',
    'hashed_password',
    'Delhi',
    TRUE,
    'https://example.com/photo.jpg',
    TRUE,
    'user',
    0,
    ARRAY['Python', 'Guitar'],
    ARRAY['Spanish', 'Photography']
);

SELECT setval('swap_requests_s_id_seq', (SELECT MAX(s_id) FROM swap_requests));

SELECT create_swap_request(1, 2, 'Hi, want to swap Python for Spanish?');




SELECT leave_feedback(2, 1, 1, 5, 'Great exchange!');
-- or
SELECT leave_feedback(1, 2, 2, 5, 'Amazing!');




SELECT update_swap_status(1, 'accepted');




SELECT
  u.id,
  u.name,
  u.email,
  u.location,
  u.profile_photo,
  u.availability,
  u.is_public,
  u.role,
  u.warnings,
  ARRAY(
    SELECT skill FROM skills_offered WHERE user_id = u.id
  ) AS skills_offered,
  ARRAY(
    SELECT skill FROM skills_wanted WHERE user_id = u.id
  ) AS skills_wanted
FROM users u
WHERE u.id = 1;



SELECT
  sr.s_id,
  sr.from_user_id,
  fu.name AS from_user_name,
  sr.message,
  sr.status,
  sr.created_at
FROM swap_requests sr
JOIN users fu ON fu.id = sr.from_user_id
WHERE sr.to_user_id = 1 AND sr.status = 'pending'
ORDER BY sr.created_at DESC;


SELECT
  s.s_id,
  s.from_user_id,
  fu.name AS from_user_name,
  s.to_user_id,
  tu.name AS to_user_name,
  s.message,
  s.status,
  s.created_at
FROM swap_requests s
JOIN users fu ON s.from_user_id = fu.id
JOIN users tu ON s.to_user_id = tu.id
WHERE (s.from_user_id = 1 OR s.to_user_id = 1)
  AND s.status = 'accepted'
ORDER BY s.created_at DESC;


SELECT
  f.user_id AS from_user_id,
  u.name AS from_user_name,
  f.swap_id,
  f.rating,
  f.comment
FROM feedback f
JOIN users u ON u.id = f.user_id
WHERE f.target_user_id = 1;


SELECT DISTINCT u.id, u.name, u.email, u.location
FROM users u
JOIN skills_offered so ON u.id = so.user_id
WHERE so.skill = 'Python' AND u.availability = TRUE;


SELECT id, name, email, warnings
FROM users
WHERE warnings > 1;



UPDATE users SET role = 'banned' WHERE id = 3;


DELETE FROM users WHERE id = 3;


SELECT DISTINCT u.id, u.name, u.email
FROM users u
JOIN skills_offered so ON u.id = so.user_id
JOIN skills_wanted sw ON u.id = sw.user_id
WHERE so.skill IN (
    SELECT skill FROM skills_wanted WHERE user_id = 1
)
AND sw.skill IN (
    SELECT skill FROM skills_offered WHERE user_id = 1
)
AND u.id != 1;



SELECT
  f.target_user_id,
  tu.name AS target_user_name,
  f.swap_id,
  f.rating,
  f.comment
FROM feedback f
JOIN users tu ON tu.id = f.target_user_id
WHERE f.user_id = 1;


SELECT skill, COUNT(*) AS users_offering
FROM skills_offered
GROUP BY skill
ORDER BY users_offering DESC;



SELECT
  u.id,
  u.name,
  ROUND(AVG(f.rating), 2) AS avg_rating,
  COUNT(f.rating) AS total_feedbacks
FROM users u
LEFT JOIN feedback f ON u.id = f.target_user_id
GROUP BY u.id
ORDER BY avg_rating DESC NULLS LAST;


SELECT id, name, email, location
FROM users
WHERE name ILIKE '%ali%';