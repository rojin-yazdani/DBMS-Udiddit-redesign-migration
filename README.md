# Udiddit, a social news aggregator

## Introduction
I've finished the  [Nonodegree Program: SQL](https://learn.udacity.com/nanodegrees/nd072) at [Udacity](https://www.udacity.com) and this project was a part of my program study.

### Introduction
Udiddit, a social news aggregation, web content rating, and discussion website, is currently using a risky and unreliable Postgres database schema to store the forum posts, discussions, and votes made by their users about different topics.

The schema allows posts to be created by registered users on certain topics, and can include a URL or a text content. It also allows registered users to cast an upvote (like) or downvote (dislike) for any forum post that has been created. In addition to this, the schema also allows registered users to add comments on posts.

Here is the DDL used to create the schema:
<br>
```sql
CREATE TABLE bad_posts (
	id SERIAL PRIMARY KEY,
	topic VARCHAR(50),
	username VARCHAR(50),
	title VARCHAR(150),
	url VARCHAR(4000) DEFAULT NULL,
	text_content TEXT DEFAULT NULL,
	upvotes TEXT,
	downvotes TEXT
);

CREATE TABLE bad_comments (
	id SERIAL PRIMARY KEY,
	username VARCHAR(50),
	post_id BIGINT,
	text_content TEXT
);
```

## Part I: Investigate the existing schema
As a first step, this schema was investigated and outlined some specific things that could be improved about this schema. 

1) There is a username column in both bad_comments and bad_posts tables and also usernames have been used in upvotes and downvotes columns in the bad_comments table. User is an independent entity and based on the second normal form, it should be separated, and a new table, users, created separately, then instead of using the username, use the user's ID in the bad_comments table and bad_posts table to decrease disk space consumption and also decrease error probability during data entry. 

	* Creating a new table of users from all usernames
	* Using the user_id column instead of the username column in the bad_posts table
	* Using the user_id column instead of the username column in the bad_comments table
	* Removing the upvotes column from the bad_posts table
	* Removing the downvotes column from the bad_posts table
	* Creating a new table of votes, to retain the user_ids with their up and down votes 

2) Based on the first normal form, goal #2 (single value in a cell) and goal #3 (no repeating columns), using a list of usernames or even user IDs in upvotes and downvotes columns is sort of denormalized data, and we should separate them. It's better to use a votes table that has post_id and  user_id columns instead and remove the two upvotes and downvotes columns from the bad_posts table.
	* Creating a new table of topics
	* Using the topic_id column instead of the topic column in the bad_posts table

3) We have 89 distinct values in the Topic column of the bad_posts table, based on the second normal form, it's better to have a topics table separately, and instead of using the topic's name, use the topic's id in comments table to decrease disk space consumption and also decrease error probability during data entering.


## Part II: Create the DDL for your new schema

Before creating the DDL commands for a new schema, I should be paied attention to the requirements below. 

1)	Here is a list of features and specifications that Udiddit needs in order to support its website and administrative interface:
	*	Allow new users to register:
		*	Each username has to be unique
		*	Usernames can be composed of at most 25 characters
		*	Usernames can’t be empty
		*	PasswordsWe are not matters for this project
	*	Allow registered users to create new topics:
		*	Topic names have to be unique.
		*	The topic’s name is at most 30 characters
		*	The topic’s name can’t be empty
		*	Topics can have an optional description of at most 500 characters.
	*	Allow registered users to create new posts on existing topics:
		*	Posts have a required title of at most 100 characters
		*	The title of a post can’t be empty.
		*	Posts should contain either a URL or a text content, but not both.
		*	If a topic gets deleted, all the posts associated with it should be automatically deleted too.
		*	If the user who created the post gets deleted, then the post will remain, but it will become dissociated from that user.
	*	Allow registered users to comment on existing posts:
		*	A comment’s text content can’t be empty.
		*	Contrary to the current linear comments, the new structure should allow comment threads at arbitrary levels.
		*	If a post gets deleted, all comments associated with it should be automatically deleted too.
		*	If the user who created the comment gets deleted, then the comment will remain, but it will become dissociated from that user.
		*	If a comment gets deleted, then all its descendants in the thread structure should be automatically deleted too.
	*	Make sure that a given user can only vote once on a given post:
		*	If the user who cast a vote gets deleted, then all their votes will remain, but will become dissociated from the user.
		*	If a post gets deleted, then all the votes for that post should be automatically deleted too.

2)	Here is a list of queries that Udiddit needs in order to support its website and administrative interface. 
	*	List all users who haven’t logged in in the last year.
	*	List all users who haven’t created any post.
	*	Find a user by their username.
	*	List all topics that don’t have any posts.
	*	Find a topic by its name.
	*	List the latest 20 posts for a given topic.
	*	List the latest 20 posts made by a given user.
	*	Find all posts that link to a specific URL, for moderation purposes. 
	*	List all the top-level comments (those that don’t have a parent comment) for a given post.
	*	List all the direct children of a parent comment.
	*	List the latest 20 comments made by a given user.
	*	Compute the score of a post, defined as the difference between the number of upvotes and the number of downvotes


Based on the requirements and shortcomings that I pointed above, The new schema including five tables designed. The following script shows the DDL commands to create new normalized schema:

```sql
-- Creates a database schema for Udiddit, a social news aggregator.
---------------------------------------------------------------
-- Creates table users with its constraints and indexes.
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(25) NOT NULL,
    user_password VARCHAR(50) DEFAULT NULL,
    last_login_ts TIMESTAMP,
    
    CONSTRAINT "unique_users_username" UNIQUE ("username"),

    CONSTRAINT "check_users_username" CHECK (LENGTH(TRIM("username")) > 0 )
);

CREATE INDEX "idx_users_login_date" ON users ("last_login_ts");
---------------------------------------------------------------
-- Creates table topics with its constraints and indexes.
CREATE TABLE topics (
    id SMALLSERIAL PRIMARY KEY,
    topic_name VARCHAR(30) NOT NULL,
    description VARCHAR(500) DEFAULT NULL,
    created_user_id INTEGER,
    created_ts TIMESTAMP,
    
    CONSTRAINT "unique_topics_name" UNIQUE ("topic_name"),  

    CONSTRAINT "check_topics_name" CHECK (LENGTH(TRIM("topic_name")) > 0 ), 

    CONSTRAINT "fk_topics_user_id" 
      FOREIGN KEY ("created_user_id") REFERENCES "users" ("id") 
      ON DELETE SET NULL
);

CREATE UNIQUE INDEX  "idx_topics_topic_name" ON topics (LOWER("topic_name"));
---------------------------------------------------------------
-- Creates table posts with its constraints and indexes.
CREATE TABLE posts (
    id BIGSERIAL PRIMARY KEY,
    topic_id SMALLINT NOT NULL,
    user_id INTEGER,
    title VARCHAR(100) NOT NULL,
    url VARCHAR(4000),
    text_content TEXT,
    posted_ts TIMESTAMP,
    
    CONSTRAINT "fk_posts_user_id" 
      FOREIGN KEY ("user_id") REFERENCES "users" ("id") 
      ON DELETE SET NULL,   

    CONSTRAINT "fk_posts_topic_id" 
      FOREIGN KEY ("topic_id") REFERENCES "topics" ("id") 
      ON DELETE CASCADE,    

    CONSTRAINT "check_posts_title" CHECK (LENGTH("title") > 0 ),

    CONSTRAINT "check_posts_xor_url_content" 
      CHECK ((url IS NOT NULL AND text_content is NULL) OR 
             (url IS NULL AND text_content is NOT NULL))
);

CREATE INDEX "idx_posts_user_posted" ON posts ("user_id","posted_ts");

CREATE INDEX "idx_posts_topic_posted" ON posts ("topic_id","posted_ts");

CREATE INDEX "idx_posts_url" ON posts ("url");
---------------------------------------------------------------
-- Creates table all_comments with its constraints and indexes.
CREATE TABLE all_comments (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER,
    post_id BIGINT NOT NULL,
    parent_comment_id BIGINT,
    commented_ts TIMESTAMP,
    text_content TEXT NOT NULL,
    
    CONSTRAINT "fk_all_comments_user_id" 
      FOREIGN KEY ("user_id") REFERENCES "users" ("id") 
      ON DELETE SET NULL,   

    CONSTRAINT "fk_all_comments_post_id" 
      FOREIGN KEY ("post_id") REFERENCES "posts" ("id") 
      ON DELETE CASCADE, 

    CONSTRAINT "fk_all_comments_comment_id" 
      FOREIGN KEY ("parent_comment_id") REFERENCES "all_comments" ("id") 
      ON DELETE CASCADE,

    CONSTRAINT "check_all_comments_content" 
      CHECK (LENGTH(TRIM("text_content")) > 0 )
);

CREATE INDEX "idx_all_comments_post_parent_comment" 
  ON all_comments ("post_id","parent_comment_id");

CREATE INDEX "idx_all_comments_parent_comment" 
  ON all_comments ("parent_comment_id");

CREATE INDEX "idx_all_comments_user_ts" 
  ON all_comments ("user_id","commented_ts");
---------------------------------------------------------------
-- Creates table votes with its constraints and indexes.
CREATE TABLE votes (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER,
    post_id BIGINT NOT NULL,
    up_down SMALLINT NOT NULL,
    
    CONSTRAINT "fk_votes_user_id" 
    FOREIGN KEY ("user_id") REFERENCES "users" ("id") 
    ON DELETE SET NULL, 

    CONSTRAINT "fk_votes_post_id" 
    FOREIGN KEY ("post_id") REFERENCES "posts" ("id") 
    ON DELETE CASCADE,

    CONSTRAINT "unique_votes_user_post" UNIQUE ("user_id", post_id),

    CONSTRAINT "check_votes_up_down" CHECK (up_down in (1,-1))
);

CREATE INDEX "idx_votes_post_up_down" ON votes ("post_id","up_down");

```

## Part III: Migrate the provided data
After creating the new schema, it’s time to migrate the data from the provided schema in the project to my own schema. This allowed me to review some DML and DQL concepts, as you’ll be using INSERT...SELECT queries to do so. 

The DML commands to migrate the current data in bad_posts and bad_comments to my new database schema:

```sql
-- Starts a transaction 
BEGIN;
-- Extracts usernames from the tables bad_posts and bad_comments and 
-- inserts them into a new table, users, with assigning new IDs.
INSERT INTO users (username)
SELECT DISTINCT uu.username 
FROM (
    SELECT REGEXP_SPLIT_TO_TABLE(bp.upvotes,',') username FROM bad_posts bp 
    UNION ALL
    SELECT REGEXP_SPLIT_TO_TABLE(bp.downvotes,',') username FROM bad_posts bp
    UNION ALL
    SELECT bp.username username FROM bad_posts bp
    UNION ALL
    SELECT bc.username username FROM bad_comments bc
   ) uu;
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
-- Commit the transaction 
COMMIT;
---------------------------------------------------------------
SELECT COUNT(*) FROM users; -- 11077
SELECT COUNT(*) FROM topics; -- 89

SELECT COUNT(*) FROM posts; -- 50000
SELECT COUNT(*) FROM bad_posts; --50000

SELECT COUNT(*) FROM all_comments; -- 100000
SELECT COUNT(*) FROM bad_comments; -- 100000

SELECT COUNT(*) FROM votes; -- 499710

```

