USE ig_clone;

-- A)	Marketing Analysis:

/* 1.	Loyal User Reward: 
Identify the five oldest users on Instagram from the provided database.*/

SELECT * FROM Users ORDER BY created_at LIMIT 5;

/* 2.	Inactive User Engagement: 
Identify users who have never posted a single photo on Instagram*/

SELECT 
    u.id, u.username
FROM
    Users u
        LEFT JOIN
    Photos p ON u.id = p.user_id
WHERE
    p.user_id IS NULL;

-- Count total no. of user who never post a photo.

SELECT 
    count(*)
FROM
    Users u
        LEFT JOIN
    Photos p ON u.id = p.user_id
WHERE
    p.user_id IS NULL;

/*  3.	Contest Winner Declaration: 
Determine the winner of the contest and provide their details to the team.
(The User with the most likes on a single photo wins.)*/

SELECT 
    likes.photo_id,
    users.username,
    COUNT(likes.user_id) AS no_of_likes
FROM
    likes
        INNER JOIN
    photos ON likes.photo_id = photos.id
        INNER JOIN
    users ON photos.user_id = users.id
GROUP BY likes.photo_id , users.username
ORDER BY no_of_likes DESC;

/*  4.	Hashtag Research:
Identify and suggest the top five most commonly used hashtags on the platform.*/
SELECT 
    tag_name, COUNT(tag_id) AS tag_count
FROM
    Photo_tags
        JOIN
    Tags ON Photo_tags.tag_id = Tags.id
GROUP BY tag_name
ORDER BY tag_count DESC
LIMIT 5;


/* 5.	Ad Campaign Launch: 
Determine the day of the week when most users register on Instagram. Provide insights on when to schedule an ad campaign.*/

SELECT 
	DAYNAME(created_at) as day_of_week,
    COUNT(id) AS user_count
FROM users
GROUP BY day_of_week
ORDER BY user_count DESC
LIMIT 1;

-- B)	Investor Metrics:

/* 1.	User Engagement: 
Calculate the average number of posts per user on Instagram.*/

SELECT 
    AVG(post_count) AS avg_post_per_user
FROM
    (SELECT 
        user_id, COUNT(image_url) AS post_count
    FROM
        Photos
    GROUP BY user_id) user_post_count;
    
-- The total number of photos on Instagram divided by the total number of users.

SELECT (
(SELECT COUNT(image_url) FROM Photos)/ (SELECT COUNT(id) FROM Users)) AS Photo_User_Ratio;

/* 2.	Bots & Fake Accounts:
Identify users (potential bots) who have liked every single photo on the site, as this is not typically 
possible for a normal user.*/

SELECT user_id
FROM
    Likes
GROUP BY user_id
HAVING COUNT(photo_id) = (SELECT COUNT(id) FROM Photos);