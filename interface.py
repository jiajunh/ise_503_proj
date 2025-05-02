import mysql.connector


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


if __name__ == '__main__':
    initialize("init.sql")
    pass
