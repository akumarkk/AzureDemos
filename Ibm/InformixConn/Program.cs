using System;
using IBM.Data.Db2;
using System.Data.Odbc;

class Program
{

    static void TestODBCConnection()
    {
        // Connection string using native Informix SQLI protocol via ODBC
        string connectionString = "";

        try
        {
            using (OdbcConnection conn = new OdbcConnection(connectionString))
            {
                conn.Open();
                Console.WriteLine("Informix ODBC Connection Successful!");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Connection failed: {ex.Message}");
        }
    
    }


    static void Main()
    {
        

        // Build the connection string for Informix via DB2 driver
        string connectionString = $"Server={hostName}:{portNumber};" +
                                   $"Database={databaseName};" +
                                   //$"SERVER={serverName};" +
                                   $"UID={userId};" +
                                   $"PWD={password};";


        TestODBCConnection();

        try
        {
            using (DB2Connection connection = new DB2Connection(connectionString))
            {
                connection.Open();
                Console.WriteLine("Informix JDBC-equivalent Connection Successful!");

                string sqlQuery = "SELECT FIRST 1 * FROM systables;";
                using (DB2Command command = new DB2Command(sqlQuery, connection))
                using (DB2DataReader reader = command.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        Console.WriteLine($"Sample row first column: {reader[0]}");
                    }
                }
            }
        }
        catch (Exception exception)
        {
            Console.WriteLine($"Connection failed: {exception.Message}");
        }
    }



}