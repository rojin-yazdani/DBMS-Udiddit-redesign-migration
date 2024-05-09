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
---------------------------------------------------------------

