-- Query 2
-- Description: Show all the travel history records for a given passenger account
SELECT *
FROM `transaction` T JOIN trip Tr ON t.TargetID = tr.TripID
WHERE T.UserID = @account AND T.TargetType = 'Trip'
ORDER BY Tr.StartDate DESC;

-- Query 6
-- Description: Show the least frequent delayed vehicles for all public transpotations
WITH delayed_cnt AS (
    SELECT
        r.TransportationID,
        COUNT(*) AS delay_cnt
    FROM route AS r
    WHERE r.STATUS = 'Delayed'
    GROUP BY r.TransportationID
),
min_cnt AS (
    SELECT MIN(delay_cnt) AS val FROM delayed_cnt
)
SELECT
    d.TransportationID,
    d.delay_cnt
FROM delayed_cnt AS d
JOIN min_cnt AS m  ON d.delay_cnt = m.val
ORDER BY d.TransportationID;

-- Query 7
-- Description: Show the remaining seats for a route
SELECT
    R.RouteID,
    R.UnitNumber,
    T.TYPE AS SeatType,
    T.Class AS SeatClass
FROM route_unit AS R
JOIN travel_unit AS T
    ON R.TransportationID = T.TransportationID
    AND R.UnitNumber = T.UnitNumber
WHERE R.RouteID = @route_id AND R.IsAvailable = TRUE
ORDER BY T.Class, T.TYPE;
LIMIT @limit_number;


-- Query 8
-- Description: Show the hotels, the average price is the closest to the average hotel costs in the past year for a given passenger
WITH user_avg AS (
    SELECT AVG(T.TotalAmount) AS avg_cost
    FROM `transaction` AS T
    WHERE T.UserID = @user_account
    AND T.TargetType = 'Accommodation'
    AND T.STATUS = 'Completed'
    AND T.CreatedAt >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR) 
),
accommodation_avg AS (
    SELECT R.AccommodationID, AVG(R.BasePrice) AS avg_price
    FROM room AS R
    GROUP BY R.AccommodationID
    UNION ALL
    SELECT bnb.AccommodationID, AVG(bnb.BasePrice) AS avg_price
    FROM bnb
    GROUP BY bnb.AccommodationID
)
SELECT 
    A.AccommodationID,
    A.ContactPhone,  
    A.Rating,
    AA.avg_price,
    ABS(AA.avg_price - U.avg_cost) AS price_diff
FROM accommodation_avg AA
CROSS JOIN user_avg U
JOIN accommodation A ON AA.AccommodationID = A.AccommodationID
INNER JOIN hotel H ON A.AccommodationID = H.AccommodationID  
ORDER BY price_diff
LIMIT @limit_number;

-- Query 9
-- Description: Show the total cost of an user account in history
WITH user_trans AS (
    SELECT t.TotalAmount
    FROM review         AS r
    JOIN `transaction`  AS t ON t.TransactionID = r.TransactionID
    WHERE r.UserID      = @user_id
      AND t.STATUS      = 'Completed'
      AND t.CreatedAt  >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
)
SELECT
    @user_id                          AS UserID,
    IFNULL(SUM(TotalAmount), 0)       AS total_spent
FROM user_trans;


-- Query 10
-- Show the highest average ratings of the locations, based on the review ratings corresponding to the transportations start from or end in the location, and the ratings of the resturants, activities, accommodation in the city


