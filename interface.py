import atexit
import datetime
import mysql.connector
import streamlit as st
# import streamlit.components.v1 as components


def get_queries(file_path):
    with open(file_path, "r") as f:
        sql_script = f.read()
    return sql_script.strip().split(";")


def initialize(init_file):
    connector = mysql.connector.connect(
      host="localhost",
      user="root",
      password="",
    )
    cursor = connector.cursor()

    init_sql = get_queries(init_file)
    for stmt in init_sql:
        if stmt.strip():
            try:
                cursor.execute(stmt)
            except mysql.connector.Error as err:
                print(f"Initialization Error: {err}\nStatement: {stmt}")

    print(f"{'-'*10} Initialization Completed {'-'*10}")
    connector.commit()
    cursor.close()
    connector.close()


def connect_database(database="travel_agency"):
    if "db_connector" not in st.session_state:
        connector = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database=database,
        )
        st.session_state.db_connector = connector
        # st.session_state.cursor = connector.cursor()
        print(f"{'-'*10} Connect to database: {database} {'-'*10}")


def close_connection():
    connector = st.session_state.get("db_connector", None)
    # cursor = st.session_state.get("db_connector", None)
    # if cursor:
    #     cursor.close()
    if connector:
        connector.close()
    print(f"{'-'*10} Close connections {'-'*10}")


def set_up():
    # Initialize database, Create tables
    initialize("init.sql")

    # Insert data
    connect_database()
    insert_sql = get_queries("insert_data.sql")
    for stmt in insert_sql:
        stmt = stmt.strip()
        if stmt.strip():
            try:
                cursor = st.session_state.db_connector.cursor()
                cursor.execute(stmt)
                cursor.close()
            except mysql.connector.Error as err:
                print(f"Insert data Error: {err}\nStatement: {stmt}")
    st.session_state.db_connector.commit()
    print(f"{'-'*10} Insert data Completed {'-'*10}")
    # close_connection()

    st.session_state.limit_number = 5
    st.session_state.locations = {
        "Boston": "LOC0001",
        "Providence": "LOC0002",
        "New York": "LOC0003",
        "Philadelphia": "LOC0004",
        "Baltimore": "LOC0005",
        "Washington": "LOC0006",
        "Richmond": "LOC0007",
        "Charlotte": "LOC0008",
        "Jacksonville": "LOC0009",
        "Miami": "LOC0010",
    }
    st.session_state.seat_query_list = ["ROUTETRAIN001", "ROUTEPLANE001"]
    st.session_state.user_list = ["USR00001", "USR00002", "USR00003",
                                  "USR00004", "USR00005"]
    st.session_state.cancel_transaction_list = ["TXN00200", "TXN00201"]


def run_sql(query):
    connector = st.session_state.db_connector
    cursor = None
    try:
        cursor = connector.cursor()
        cursor.execute(query)
        result = cursor.fetchall()
        # Important: fetch all results before committing
        connector.commit()
        return result
    except mysql.connector.Error as err:
        print(f"Query Error: {err}")
        connector.rollback()  # rollback on error
        raise err
    finally:
        if cursor:
            cursor.close()  # Always close the cursor


@st.fragment
def run_query1():
    print(f"{'-'*10} run_query1 {'-'*10}")
    
    query_container1 = st.container()
    # query_container1.header("Query 1")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query1",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show all the possible combanations of selected "
                "public transpotations from source location to target "
                "location with given StartDate sand EndDate</p>",
                unsafe_allow_html=True)

    input_col, output_col = st.columns([1, 2])
    with query_container1:
        with input_col:
            with st.form("query1"):
                src_location = st.selectbox(
                    "Departure Location",
                    options=st.session_state["locations"].keys()
                )
                dest_location = st.selectbox(
                    "Arrival Location",
                    options=st.session_state["locations"].keys()
                )
                num_transfers = st.selectbox(
                    "Num of transfers",
                    options=[1, 2, 3, 4, 5],
                )

                start_date = st.date_input("SatrtDate", 
                                           datetime.date(2025, 4, 27), 
                                           min_value=datetime.date(2025, 4, 27),
                                           max_value=datetime.date(2025, 5, 3))
                start_datetime = start_date.strftime('%Y-%m-%d 00:00:00')
                
                end_date = st.date_input("EndDate",
                                           datetime.date(2025, 4, 27),
                                           min_value=datetime.date(2025, 4, 27),
                                           max_value=datetime.date(2025, 5, 4))
                end_datetime = end_date.strftime('%Y-%m-%d 23:59:59')

                col1, col2 = st.columns(2)
                with col1:
                    use_plane = st.checkbox("Plane")
                with col2:
                    use_train = st.checkbox("Train")
                
                col3, col4 = st.columns(2)
                with col3:
                    use_bus = st.checkbox("Bus")
                with col4:
                    use_ship = st.checkbox("Ship")

                q1_submitted = st.form_submit_button("query")

                if q1_submitted:
                    transport_types = []
                    if use_plane:
                        transport_types.append("Plane")
                    if use_ship:
                        transport_types.append("Ship")
                    if use_train:
                        transport_types.append("Train")
                    if use_bus:
                        transport_types.append("Bus")

                    transport_str = ", ".join([f"'{t}'" for t in transport_types])
                    print("transport_str", transport_str)

                    q1 = f"""
                    WITH RECURSIVE route_chain AS (
                    -- Base case: Direct routes from the source
                    SELECT
                        r.ScheduledDeparture,
                        r.ScheduledArrival,
                        r.DestinationLocationID,
                        CAST(r.ScheduledDeparture AS CHAR(1000)) AS schedule_departure_path,
                        CAST(r.ScheduledArrival AS CHAR(1000)) AS scheduled_arrival_path,
                        CAST(r.SourceLocationID AS CHAR(1000)) AS source_location_path,
                        CAST(r.DestinationLocationID AS CHAR(1000)) AS dest_location_path,
                        CAST(r.TransportationID AS CHAR(1000)) AS transpotation_path,
                        0 AS depth,
                        CAST(r.RouteID AS CHAR(1000)) AS route_path
                    FROM route r
                    JOIN transportation t ON r.TransportationID = t.TransportationID
                    WHERE r.SourceLocationID = '{st.session_state["locations"][src_location]}'
                    AND r.ScheduledDeparture >= '{start_datetime}'
                    AND r.ScheduledArrival <= '{end_datetime}'
                    AND t.TYPE IN ({transport_str})

                    UNION ALL

                    SELECT
                        r.ScheduledDeparture,
                        r.ScheduledArrival,
                        r.DestinationLocationID,
                        CONCAT(rc.schedule_departure_path, '->', r.ScheduledDeparture),
                        CONCAT(rc.scheduled_arrival_path, '->', r.ScheduledArrival),
                        CONCAT(rc.source_location_path,'->',r.SourceLocationID),
                        CONCAT(rc.dest_location_path,'->',r.DestinationLocationID),
                        CONCAT(rc.transpotation_path, '->', r.TransportationID),
                        rc.depth + 1,
                        CONCAT(rc.route_path, '->', r.RouteID)
                    FROM route r
                    JOIN transportation t ON r.TransportationID = t.TransportationID
                    JOIN route_chain rc ON r.SourceLocationID = rc.DestinationLocationID
                    WHERE r.ScheduledDeparture >= rc.ScheduledArrival
                    AND r.ScheduledArrival <= '{end_datetime}'
                    AND rc.depth < {num_transfers}
                    AND t.TYPE IN ({transport_str})
                    )

                    SELECT *
                    FROM route_chain
                    WHERE DestinationLocationID = '{st.session_state["locations"][dest_location]}'
                    ORDER BY depth, ScheduledDeparture ASC
                    LIMIT {st.session_state["limit_number"]};
                    """
                    result = run_sql(q1)
                    print("Source Location: ", src_location, 
                          st.session_state["locations"][src_location])
                    print("Destination Location: ", dest_location, 
                          st.session_state["locations"][dest_location])
                    print("StartDate:", type(start_datetime), start_datetime)
                    print("EndDate:", type(end_datetime), end_datetime)
                    print("num_transfers", num_transfers)
                    print(f"Use plane: {use_plane}, Use ship: {use_ship}, "
                          f"Use bus: {use_bus}, Use train: {use_train}")
                    st.session_state["query1_result"] = result

        with output_col:
            if "query1_result" not in st.session_state:
                st.write("No result")
            else:
                for item in st.session_state["query1_result"]:
                    # route_chain = item[-1]
                    # num_transfers = item[-2]
                    # transpotation_chain = item[-3]
                    # source_location_chain = item[-5]
                    # dest_location_chain = item[-4]
                    # schedule_departure_chain = item[-7]
                    # arrival_departure_chain = item[-6]

                    # print(schedule_departure_chain.split("->"))
                    st.write(item)

    query_container1_sql = st.container()
    with query_container1_sql:
        with st.expander("Show SQL"):
            if "query1_result" not in st.session_state:
                st.write("Please first make a query")
            else:
                st.code(q1, language='sql')


@st.fragment
def run_query2():
    print(f"{'-'*10} run_query2 {'-'*10}")
    query_container2 = st.container()
    # query_container2.header("Query 2")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query2",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show all the travel history records for a "
                "given passenger account</p>", unsafe_allow_html=True)

    input_col, output_col = st.columns([1, 2])
    with query_container2:
        with input_col:
            with st.form("query2"):
                account = st.selectbox(
                    "Accounts",
                    options=st.session_state.user_list,
                )

                q2_submitted = st.form_submit_button("query")

                if q2_submitted:
                    q2 = f"""
                    SELECT
                        Tr.TripID AS TripID,
                        Tr.TotalCost AS Cost,
                        Tr.StartDate AS StartDate,
                        Tr.EndDate AS EndDate
                    FROM `transaction` T
                    JOIN trip Tr ON T.TargetID = Tr.TripID
                    WHERE T.UserID = '{account}' AND T.TargetType = 'Trip'
                    LIMIT {st.session_state["limit_number"]};
                    """
                    result = run_sql(q2)
                    st.session_state["query2_result"] = result

        with output_col:
            if "query2_result" not in st.session_state:
                st.write("No result")
            else:
                for item in st.session_state["query2_result"]:
                    st.write(item)

    query_container2_sql = st.container()
    with query_container2_sql:
        with st.expander("Show SQL"):
            if "query2_result" not in st.session_state: 
                st.write("Please first make a query")
            else:
                st.code(q2, language='sql')


@st.fragment
def run_query3():
    print(f"{'-'*10} run_query3 {'-'*10}")
    query_container3 = st.container()
    # query_container3.header("Query 3")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query3",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Cancel a pending or completed transaction, "
                "given the TranactionID</p>", unsafe_allow_html=True)

    input_col, output_col = st.columns([1, 2])
    with query_container3:
        with input_col:
            with st.form("query3"):
                transaction_id = st.selectbox(
                    "Test TranactionID",
                    options=st.session_state.cancel_transaction_list,
                )

                q3_submitted = st.form_submit_button("query")

                if q3_submitted:
                    q3_select = f"""
                    SELECT 
                        TransactionID,
                        UserID,
                        TotalAmount,
                        Currency,
                        PaymentMethod,
                        STATUS,
                        UpdatedAt
                    FROM `transaction`
                    WHERE TransactionID = '{transaction_id}';
                    """
                    result_before = run_sql(q3_select)
                    q3 = f"""
                    UPDATE `transaction`
                    SET STATUS = 'Cancelled',
                        UpdatedAt = NOW()
                    WHERE TransactionID = '{transaction_id}'
                    AND STATUS IN ('Pending','Completed');
                    """
                    _ = run_sql(q3)
                    result_after = run_sql(q3_select)
                    st.session_state["query3_before_result"] = result_before
                    st.session_state["query3_after_result"] = result_after

        with output_col:
            if "query3_after_result" not in st.session_state:
                st.write("No result")
            else:
                st.write("Before cancelling:")
                for item in st.session_state["query3_before_result"]:
                    st.write(item)
                st.write("After cancelling:")
                for item in st.session_state["query3_after_result"]:
                    st.write(item)

    query_container3_sql = st.container()
    with query_container3_sql:
        with st.expander("Show SQL"):
            if "query3_after_result" not in st.session_state: 
                st.write("Please first make a query")
            else:
                st.code(q3, language='sql')

@st.fragment
def run_query4():
    print(f"{'-'*10} run_query4 {'-'*10}")
    query_container4 = st.container()
    # query_container4.header("Query 4")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query4",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the most popular route in the past "
                "30 days</p>", unsafe_allow_html=True)
    
    input_col, output_col = st.columns([1, 2])
    with query_container4:
        with input_col:
            with st.form("query4"):
                q4_submitted = st.form_submit_button("query")

                if q4_submitted:
                    q4 = f"""
                    SELECT 
                        R.RouteID,
                        COUNT(*) AS UsageCount
                    FROM transaction T
                    JOIN trip TR ON T.TargetID = TR.TripID
                    JOIN trip_route TRT ON TR.TripID = TRT.TripID
                    JOIN route R ON TRT.RouteID = R.RouteID
                    WHERE T.TargetType = 'Trip'
                        AND T.STATUS = 'Completed'
                        AND T.CreatedAt >= NOW() - INTERVAL 30 DAY
                    GROUP BY R.RouteID
                    ORDER BY UsageCount DESC
                    LIMIT {st.session_state["limit_number"]};
                    """
                    result = run_sql(q4)
                    st.session_state["query4_result"] = result

        with output_col:
            if "query4_result" not in st.session_state:
                st.write("No result")
            else:
                for item in st.session_state["query4_result"]:
                    st.write(item)

    query_container4_sql = st.container()
    with query_container4_sql:
        with st.expander("Show SQL"):
            if "query4_result" not in st.session_state:
                st.write("Please first make a query")
            else:
                st.code(q4, language='sql')



@st.fragment
def run_query5():
    print(f"{'-'*10} run_query5 {'-'*10}")
    query_container5 = st.container()
    # query_container5.header("Query 5")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query5",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the safest transpotation type "
                "(order by accidents asc)</p>", unsafe_allow_html=True)

    input_col, output_col = st.columns([1, 2])
    with query_container5:
        with input_col:
            with st.form("query5"):
                q5_submitted = st.form_submit_button("query")

                if q5_submitted:
                    q5 = f"""
                    SELECT 
                        T.TYPE AS TransportationType,
                        COUNT(A.AccidentID) AS AccidentCount
                    FROM transportation T
                    LEFT JOIN accident A ON T.TransportationID = A.TransportationID
                    GROUP BY T.TYPE
                    ORDER BY AccidentCount ASC;
                    """
                    result = run_sql(q5)
                    st.session_state["query5_result"] = result

        with output_col:
            if "query5_result" not in st.session_state:
                st.write("No result")
            else:
                for item in st.session_state["query5_result"]:
                    st.write(item)

    query_container5_sql = st.container()
    with query_container5_sql:
        with st.expander("Show SQL"):
            if "query5_result" not in st.session_state:
                st.write("Please first make a query")
            else:
                st.code(q5, language='sql')

@st.fragment
def run_query6():
    print(f"{'-'*10} run_query6 {'-'*10}")
    query_container6 = st.container()
    # query_container6.header("Query 6")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query6",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the least frequent delayed public "
                "transpotation</p>", unsafe_allow_html=True)

    input_col, output_col = st.columns([1, 2])
    with query_container6:
        with input_col:
            with st.form("query6"):
                q6_submitted = st.form_submit_button("query")

                if q6_submitted:
                    q6 = f"""
                    SELECT 
                        T.TYPE AS TransportationType,
                        COUNT(CASE WHEN R.STATUS = 'Delayed' THEN 1 END) * 1.0 / COUNT(*) AS DelayRatio
                    FROM route R
                    JOIN transportation T 
                    ON R.TransportationID = T.TransportationID
                    GROUP BY T.TYPE
                    ORDER BY DelayRatio ASC;
                    """
                    result = run_sql(q6)
                    st.session_state["query6_result"] = result

        with output_col:
            if "query6_result" not in st.session_state:
                st.write("No result")
            else:
                for item in st.session_state["query6_result"]:
                    st.write(item)

    query_container6_sql = st.container()
    with query_container6_sql:
        with st.expander("Show SQL"):
            if "query6_result" not in st.session_state: 
                st.write("Please first make a query")
            else:
                st.code(q6, language='sql')



@st.fragment
def run_query7():
    print(f"{'-'*10} run_query7 {'-'*10}")
    query_container7 = st.container()
    # query_container7.header("Query 7")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query7",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the remaining seats for a route</p>",
                unsafe_allow_html=True)

    input_col, output_col = st.columns([1, 2])
    with query_container7:
        with input_col:
            with st.form("query7"):
                route = st.selectbox(
                    "Route",
                    options=st.session_state.seat_query_list,
                )

                q7_submitted = st.form_submit_button("query")

                if q7_submitted:
                    q7 = f"""
                    SELECT
                        R.RouteID,
                        R.UnitNumber,
                        T.TYPE AS SeatType,
                        T.Class AS SeatClass
                    FROM route_unit AS R
                    JOIN travel_unit AS T
                        ON R.TransportationID = T.TransportationID
                        AND R.UnitNumber = T.UnitNumber
                    WHERE R.RouteID = '{route}' AND R.IsAvailable = TRUE
                    ORDER BY T.Class, T.TYPE
                    LIMIT {st.session_state["limit_number"]};
                    """
                    result = run_sql(q7)
                    st.session_state["query7_result"] = result

        with output_col:
            if "query7_result" not in st.session_state:
                st.write("No result")
            else:
                for item in st.session_state["query7_result"]:
                    st.write(item)

    query_container7_sql = st.container()
    with query_container7_sql:
        with st.expander("Show SQL"):
            if "query7_result" not in st.session_state: 
                st.write("Please first make a query")
            else:
                st.code(q7, language='sql')


@st.fragment
def run_query8():
    print(f"{'-'*10} run_query8 {'-'*10}")
    query_container8 = st.container()
    # query_container8.header("Query 8")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query8",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the hotels, whose average price is the "
                "closest to the average accomodation costs "
                "for a given passenger account over recent 1 year.</p>",
                unsafe_allow_html=True)

    input_col, output_col = st.columns([1, 2])
    with query_container8:
        with input_col:
            with st.form("query8"):
                account = st.selectbox(
                    "Account",
                    options=st.session_state.user_list,
                )

                q8_submitted = st.form_submit_button("query")

                if q8_submitted:
                    q8 = f"""
                    WITH user_avg AS (
                        SELECT AVG(T.TotalAmount) AS avg_cost
                        FROM `transaction` AS T
                        WHERE T.UserID = '{account}'
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
                    LIMIT {st.session_state["limit_number"]};
                    """
                    result = run_sql(q8)
                    st.session_state["query8_result"] = result

        with output_col:
            if "query8_result" not in st.session_state:
                st.write("No result")
            else:
                for item in st.session_state["query8_result"]:
                    st.write(item)

    query_container8_sql = st.container()
    with query_container8_sql:
        with st.expander("Show SQL"):
            if "query8_result" not in st.session_state: 
                st.write("Please first make a query")
            else:
                st.code(q8, language='sql')

@st.fragment
def run_query9():
    print(f"{'-'*10} run_query9 {'-'*10}")
    query_container9 = st.container()
    # query_container9.header("Query 9")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query9",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the total cost of an user account"
                " in last one year</p>",
                unsafe_allow_html=True)
    
    input_col, output_col = st.columns([1, 2])
    with query_container9:
        with input_col:
            with st.form("query9"):
                account = st.selectbox(
                    "Account",
                    options=st.session_state.user_list,
                )

                q9_submitted = st.form_submit_button("query")

                if q9_submitted:
                    q9 = f"""
                    SELECT T.UserID, SUM(T.TotalAmount)
                    FROM `transaction` AS T
                    WHERE T.UserID = '{account}'
                        AND T.STATUS = 'Completed'
                        AND t.CreatedAt >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
                    GROUP BY T.UserID
                    LIMIT {st.session_state["limit_number"]};
                    """
                    result = run_sql(q9)
                    st.session_state["query9_result"] = result

        with output_col:
            if "query9_result" not in st.session_state:
                st.write("No result")
            else:
                for item in st.session_state["query9_result"]:
                    st.write(item)

    query_container9_sql = st.container()
    with query_container9_sql:
        with st.expander("Show SQL"):
            if "query9_result" not in st.session_state:
                st.write("Please first make a query")
            else:
                st.code(q9, language='sql')


@st.fragment
def run_query10():
    print(f"{'-'*10} run_query10 {'-'*10}")
    query_container10 = st.container()
    # query_container10.header("Query 10")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query10",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Show the highest average ratings of the locations, based on "
                "the review ratings corresponding to the transportations "
                "start from or end with the location, and the ratings of the "
                "resturants, activities, accommodation in the city</p>",
                unsafe_allow_html=True)

    input_col, output_col = st.columns([1, 2])
    with query_container10:
        with input_col:
            with st.form("query10"):
                
                q10_submitted = st.form_submit_button("query")

                if q10_submitted:
                    q10 = f"""
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

                    trans_avg  AS (SELECT LocationID, AVG(Rating) AS avg_trans_rating  
                    FROM trans_review GROUP BY LocationID),

                    rest_avg AS (SELECT LocationID, AVG(Rating) AS avg_rest_rating   
                    FROM restaurant GROUP BY LocationID),

                    act_avg AS (SELECT LocationID, AVG(Rating) AS avg_act_rating    
                    FROM activity GROUP BY LocationID),
                    
                    accom_avg AS (SELECT LocationID, AVG(Rating) AS avg_accom_rating  
                    FROM accommodation GROUP BY LocationID),

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
                    LIMIT {st.session_state["limit_number"]};
                    """
                    result = run_sql(q10)
                    st.session_state["query10_result"] = result

        with output_col:
            if "query10_result" not in st.session_state:
                st.write("No result")
            else:
                for item in st.session_state["query10_result"]:
                    st.write(item)

    query_container10_sql = st.container()
    with query_container10_sql:
        with st.expander("Show SQL"):
            if "query10_result" not in st.session_state:
                st.write("Please first make a query")
            else:
                st.code(q10, language='sql')


def run_streamlit():
    st.set_page_config(page_title="ISE 503 Project", layout="centered")
    st.header('ISE 503 Project - Travel Agency System')

    run_query1()
    run_query2()
    run_query3()
    run_query4()
    run_query5()
    run_query6()
    run_query7()
    run_query8()
    run_query9()
    run_query10()


def main():
    # Connect to the database
    connect_database()

    run_streamlit()


if __name__ == '__main__':
    atexit.register(close_connection)
    set_up()
    main()
