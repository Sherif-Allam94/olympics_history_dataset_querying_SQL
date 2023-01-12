--Identify the sport which was played in all summer olympics.
WITH CTE1 AS(
	SELECT COUNT(DISTINCT games) AS total_summer_games
	FROM olympics_history
	WHERE season = 'Summer'
),

CTE2 AS(
	SELECT DISTINCT(sport), games
	FROM olympics_history
	WHERE season = 'Summer'
	ORDER BY 2
),

CTE3 AS(
	SELECT sport, count(games) AS no_of_games
	FROM CTE2
	GROUP BY 1
)

SELECT * 
FROM CTE3
JOIN CTE1
ON CTE3.no_of_games = CTE1.total_summer_games;
----------------------------------------------------------------

--Fetch the top 5 athletes who have won the most gold medals.

WITH CTE1 AS(
	SELECT name, team, count(medal) AS total_medals
	FROM olympics_history
	WHERE medal = 'Gold'
	GROUP BY 1,2
	ORDER BY 3 DESC
),

CTE2 AS(
	SELECT *, DENSE_RANK() OVER(ORDER BY total_medals DESC) AS rank
	FROM CTE1
)

SELECT * 
FROM CTE2
WHERE rank < 6;
----------------------------------------------------------------

--List down total gold, silver and broze medals won by each country.

SELECT country,
	COALESCE(gold, 0) AS gold,
	COALESCE(Silver, 0) AS Silver,
	COALESCE(bronze, 0) AS bronze
FROM CROSSTAB(	
	'SELECT noc.region AS country,
		oh.medal AS medal,
		COUNT(oh.medal) AS total_medals
	FROM olympics_history_noc_regions AS noc
	JOIN olympics_history AS oh
	ON noc.noc = oh.noc
	WHERE medal <> ''NA''
	GROUP BY 1,2
	ORDER BY 1,2',
	'Values (''Bronze''), (''Gold''), (''Silver'')'
)
AS FINAL_RESULT(country varchar, bronze bigint, gold bigint, silver bigint)
ORDER BY gold DESC, silver DESC, bronze DESC;
----------------------------------------------------------------

--Identify which country won the most gold, most silver and most bronze medals in each olympic games.

WITH temp AS(
		SELECT SUBSTRING(games, 1, POSITION(' - ' IN games)-1) AS games,
			SUBSTRING(games, POSITION(' - ' IN games)+3) AS country,
			COALESCE(gold, 0) AS gold,
			COALESCE(Silver, 0) AS Silver,
			COALESCE(bronze, 0) AS bronze
		FROM CROSSTAB(	
		'SELECT CONCAT(oh.games,'' - '',noc.region) AS games,
			oh.medal AS medal,
			COUNT(oh.medal) AS total_medals
		FROM olympics_history_noc_regions AS noc
		JOIN olympics_history AS oh
		ON noc.noc = oh.noc
		WHERE medal <> ''NA''
		GROUP BY games, region, medal
		ORDER BY games, medal',
		'Values (''Bronze''), (''Gold''), (''Silver'')'
		)
		AS FINAL_RESULT(games varchar, bronze bigint, gold bigint, silver bigint)
)
SELECT DISTINCT games,
	CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY gold DESC), ' - ', FIRST_VALUE(gold) OVER(PARTITION BY games ORDER BY gold DESC)) AS Max_Gold,
	CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY silver DESC), ' - ', FIRST_VALUE(Silver) OVER(PARTITION BY games ORDER BY silver DESC)) AS Max_Silver,
	CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY bronze DESC), ' - ', FIRST_VALUE(Bronze) OVER(PARTITION BY games ORDER BY bronze DESC)) AS Max_bronze
FROM temp
ORDER BY games;
----------------------------------------------------------------

--Fetch the total no of sports played in each olympic games.

SELECT games, COUNT(DISTINCT sport) AS sport
FROM olympics_history
GROUP BY 1
ORDER BY 2 DESC;
----------------------------------------------------------------

--Fetch oldest athletes to win a gold medal

WITH temp AS(	
	SELECT *,
		RANK() OVER(ORDER BY age DESC) AS rank
	FROM olympics_history
	WHERE medal = 'Gold' 
			AND age <> 'NA'
	ORDER BY age DESC
)

SELECT *
FROM temp
WHERE rank = 1;
----------------------------------------------------------------

--Find the Ratio of male and female athletes participated in all olympic games.

WITH temp1 AS(
	SELECT 
		CASE WHEN sex = 'M' THEN sex END AS M,
		CASE WHEN sex = 'F' THEN sex END AS F
	FROM olympics_history
	WHERE SEX <> 'NA'
),
temp2 AS(
	SELECT 
		COUNT(f) AS females,
		Count(m) AS males
	FROM temp1
)
SELECT CONCAT('1:', ROUND(males/females::DECIMAL,2)) AS Ratio
FROM temp2;
----------------------------------------------------------------

--Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

WITH temp AS(
		SELECT name,
				team,
				COUNT(medal) AS total_medals,
				DENSE_RANK() OVER(ORDER BY COUNT(medal) DESC) AS rank
		FROM olympics_history
		WHERE medal <> 'NA'
		GROUP BY 1,2
		ORDER BY 3 DESC
)
SELECT name, team,
		total_medals
FROM temp
WHERE rank < 6;
----------------------------------------------------------------

--Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

WITH temp AS(
	SELECT noc.region AS country,
		COUNT(oh.medal) AS total_medals,
		RANK() OVER(ORDER BY COUNT(oh.medal) DESC) AS rnk
	FROM olympics_history_noc_regions AS noc
	JOIN olympics_history AS oh
	ON noc.noc = oh.noc
	WHERE medal <> 'NA'
	GROUP BY 1
	ORDER BY 2 DESC
)
SELECT * 
FROM temp 
WHERE rnk <= 5;
----------------------------------------------------------------

--In which Sport/event, Egypt has won highest medals.

SELECT oh.sport,
	COUNT(oh.medal) AS total_medals
FROM olympics_history_noc_regions AS noc
JOIN olympics_history AS oh
ON noc.noc = oh.noc
WHERE medal <> 'NA'
	AND noc.region ='Egypt'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

