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
    connector = mysql.connector.connect(
      host="localhost",
      user="root",
      password="",
      database=database,
    )
    cursor = connector.cursor()
    print(f"{'-'*10} Connect to database: {database} {'-'*10}")
    return connector, cursor


def close_connection(connector, cursor):
    cursor.close()
    connector.close()
    print(f"{'-'*10} Close connections {'-'*10}")


def set_up():
    # Initialize database, Create tables
    initialize("init.sql")


def run_streamlit():
    st.set_page_config(page_title="ISE 503 Project", layout="centered")
    st.title('ISE 503 Project')


def main():
    # Connect to the database
    connector, cursor = connect_database("travel_agency")

    run_streamlit()

    # Close connections
    close_connection(connector, cursor)


if __name__ == '__main__':
    set_up()
    main()
