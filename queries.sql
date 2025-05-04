-- Query 2
-- Description: Show all the travel history records for a given passenger account
SELECT 
    Tr.TripID AS TripID, 
    Tr.TotalCost AS Cost,
    Tr.StartDate AS StartDate,
    Tr.EndTime AS EndTime
FROM `transaction` T 
JOIN trip Tr ON t.TargetID = tr.TripID
WHERE T.UserID = @user_account AND T.TargetType = 'Trip'
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
-- Description: Show the total cost of an user account in last one year
SELECT T.UserID, SUM(T.TotalAmount)
FROM `transaction` AS T
WHERE T.UserID = @user_account
    AND T.STATUS = 'Completed'
    AND t.CreatedAt >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY T.UserID
LIMIT @limit_number;

-- Query 10
-- Show the highest average ratings of the locations, based on the review ratings corresponding to the transportations start from or end in the location, and the ratings of the resturants, activities, accommodation in the city
WITH trans_review AS (

    SELECT r.SourceLocationID   AS LocationID,
           rv.Rating
    FROM route        AS r
    JOIN trip_route   AS tr ON tr.RouteID      = r.RouteID
    JOIN `transaction`AS t  ON t.TargetType    = 'Trip'
                            AND t.TargetID     = tr.TripID
    JOIN review       AS rv ON rv.TransactionID = t.TransactionID
    WHERE r.SourceLocationID IS NOT NULL

    UNION ALL

    SELECT r.DestinationLocationID,
           rv.Rating
    FROM route        AS r
    JOIN trip_route   AS tr ON tr.RouteID      = r.RouteID
    JOIN `transaction`AS t  ON t.TargetType    = 'Trip'
                            AND t.TargetID     = tr.TripID
    JOIN review       AS rv ON rv.TransactionID = t.TransactionID
    WHERE r.DestinationLocationID IS NOT NULL
),

trans_avg  AS (SELECT LocationID, AVG(Rating) AS avg_trans_rating  FROM trans_review GROUP BY LocationID),
rest_avg   AS (SELECT LocationID, AVG(Rating) AS avg_rest_rating   FROM restaurant   GROUP BY LocationID),
act_avg    AS (SELECT LocationID, AVG(Rating) AS avg_act_rating    FROM activity     GROUP BY LocationID),
accom_avg  AS (SELECT LocationID, AVG(Rating) AS avg_accom_rating  FROM accommodation GROUP BY LocationID),

combined AS (
    SELECT
        l.LocationID,
        l.City,
        l.StateProvince,
        l.Country,

        AVG(val) AS overall_rating
    FROM location AS l
    LEFT JOIN trans_avg  ta ON ta.LocationID  = l.LocationID
    LEFT JOIN rest_avg   ra ON ra.LocationID  = l.LocationID
    LEFT JOIN act_avg    aa ON aa.LocationID  = l.LocationID
    LEFT JOIN accom_avg  ca ON ca.LocationID  = l.LocationID

    CROSS JOIN LATERAL (
        SELECT ta.avg_trans_rating  AS val UNION ALL
        SELECT ra.avg_rest_rating   UNION ALL
        SELECT aa.avg_act_rating    UNION ALL
        SELECT ca.avg_accom_rating
    ) AS x
    WHERE x.val IS NOT NULL            
    GROUP BY l.LocationID
)
SELECT
    LocationID,
    City,
    StateProvince,
    Country,
    ROUND(overall_rating, 2) AS overall_rating
FROM combined
ORDER BY overall_rating DESC
LIMIT @limit_number;                               


