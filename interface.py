import atexit
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
        st.session_state.cursor = connector.cursor()
        print(f"{'-'*10} Connect to database: {database} {'-'*10}")


def close_connection():
    connector = st.session_state.get("db_connector", None)
    cursor = st.session_state.get("db_connector", None)
    if cursor:
        cursor.close()
    if connector:
        connector.close()
    print(f"{'-'*10} Close connections {'-'*10}")


def set_up():
    # Initialize database, Create tables
    initialize("init.sql")


@st.fragment
def run_query1():
    print(f"{'-'*10} run_query1 {'-'*10}")
    query_container1 = st.container()
    # query_container1.header("Query 1")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query1",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show all the possible combanations of selected "
                "transpotations from source location to target location "
                "within the time interval</p>", unsafe_allow_html=True)


@st.fragment
def run_query2():
    print(f"{'-'*10} run_query2 {'-'*10}")
    query_container2 = st.container()
    # query_container2.header("Query 2")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query2",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show all the travel history records for a "
                "given passenger</p>", unsafe_allow_html=True)


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


@st.fragment
def run_query4():
    print(f"{'-'*10} run_query4 {'-'*10}")
    query_container4 = st.container()
    # query_container4.header("Query 4")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query4",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the most popular routine in the past "
                "30 days</p>", unsafe_allow_html=True)


@st.fragment
def run_query5():
    print(f"{'-'*10} run_query5 {'-'*10}")
    query_container5 = st.container()
    # query_container5.header("Query 5")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query5",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the safest transpotation type "
                "(Least accidents)</p>", unsafe_allow_html=True)


@st.fragment
def run_query6():
    print(f"{'-'*10} run_query6 {'-'*10}")
    query_container6 = st.container()
    # query_container6.header("Query 6")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query6",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the least frequent delayed vehicles for "
                "all public transpotations</p>", unsafe_allow_html=True)


@st.fragment
def run_query7():
    print(f"{'-'*10} run_query7 {'-'*10}")
    query_container7 = st.container()
    # query_container7.header("Query 7")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query7",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the remaining seats for a routine</p>",
                unsafe_allow_html=True)


@st.fragment
def run_query8():
    print(f"{'-'*10} run_query8 {'-'*10}")
    query_container8 = st.container()
    # query_container8.header("Query 8")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query8",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the hotels, the average price is the "
                "closest to the average hotel costs in the past year "
                "for a given passenger</p>",
                unsafe_allow_html=True)


@st.fragment
def run_query9():
    print(f"{'-'*10} run_query9 {'-'*10}")
    query_container9 = st.container()
    # query_container9.header("Query 9")
    st.markdown("<h3 style='font-family:Arial; font-size:26px;'>Query9",
                unsafe_allow_html=True)
    st.markdown("<p style='font-family:Arial; font-size:18px;'>"
                "Description: Show the total cost of an user account in the "
                "past year</p>",
                unsafe_allow_html=True)


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
                "start from or end in the location, and the ratings of the "
                "resturants, activities, accommodation in the city</p>",
                unsafe_allow_html=True)


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
