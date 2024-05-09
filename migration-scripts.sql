---------------------------------------------------------------
-- Extracts usernames from the tables bad_posts and bad_comments and 
-- inserts them into a new table, users, with assigning new IDs.
INSERT INTO users (username)
SELECT DISTINCT username 
FROM (
	SELECT REGEXP_SPLIT_TO_TABLE(bp.upvotes,',') username FROM bad_posts bp 
	UNION ALL
	SELECT REGEXP_SPLIT_TO_TABLE(bp.downvotes,',') username FROM bad_posts bp
	UNION ALL
	SELECT bp.username username FROM bad_posts bp
	UNION ALL
	SELECT bc.username username FROM bad_comments bc
   );
---------------------------------------------------------------
-- Extracts topics from the bad_posts table and 
-- inserts them into a new table, topics, with assigning new IDs.
INSERT INTO topics (topic_name)
SELECT DISTINCT bp.topic FROM bad_posts bp ORDER BY bp.topic;
---------------------------------------------------------------
-- Extracts posts from the bad_posts table and 
-- inserts them into a new table, posts, with using the old IDs.
INSERT INTO posts (id, topic_id, user_id, title, url, text_content)	
SELECT bp.id post_id, top.id topic_id, u.id user_id, 
       SUBSTRING(bp.title,1,100) title, 
       bp.url, bp.text_content  
FROM bad_posts bp
JOIN topics top ON bp.topic = top.topic_name 
JOIN users u ON bp.username = u.username;
---------------------------------------------------------------
-- Extracts posts from the bad_comments table and 
-- inserts them into a new table, all_comments, with using the old IDs.
INSERT INTO all_comments (id, user_id, post_id, text_content)
SELECT bc.id, u.id user_id, bc.post_id, bc.text_content 
FROM bad_comments bc
JOIN users u ON bc.username = u.username;
---------------------------------------------------------------
-- Extracts usernames from the upvotes column of the bad_posts table and 
-- inserts equivalent user_ids with vote 1 as the new rows 
-- into a new table, votes.
INSERT INTO votes (user_id, post_id, up_down)
SELECT u.id user_id, upu.post_id, 1
FROM
	(SELECT bp.id post_id, REGEXP_SPLIT_TO_TABLE(bp.upvotes,',') upvote_username 
	 FROM bad_posts bp
	) upu
JOIN users u 
  ON upu.upvote_username = u.username;
---------------------------------------------------------------
-- Extracts usernames from the downvotes column of the bad_posts table and 
-- inserts equivalent user_ids with vote -1 as the new rows 
-- into a new table, votes.
INSERT INTO votes (user_id, post_id, up_down)
SELECT u.id user_id, dou.post_id, -1
FROM
	(SELECT bp.id post_id, 
            REGEXP_SPLIT_TO_TABLE(bp.downvotes,',') downvote_username 
	 FROM bad_posts bp
	) dou
JOIN users u 
  ON dou.downvote_username = u.username;
---------------------------------------------------------------
-- Changes the next value for sequence of posts table 
-- because we used old IDs.
SELECT setval(pg_get_serial_sequence('posts', 'id'), 50000, true); 
---------------------------------------------------------------
-- Changes the next value for sequence of all_comments table 
-- because we used old IDs.
SELECT setval(pg_get_serial_sequence('all_comments', 'id'), 100000, true);
---------------------------------------------------------------
COMMIT;
---------------------------------------------------------------
SELECT COUNT(*) FROM users; -- 11077
SELECT COUNT(*) FROM topics; -- 89

SELECT COUNT(*) FROM posts; -- 50000
SELECT COUNT(*) FROM bad_posts; --50000

SELECT COUNT(*) FROM all_comments; -- 100000
SELECT COUNT(*) FROM bad_comments; -- 100000

SELECT COUNT(*) FROM votes; -- 499710
