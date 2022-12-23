using log4net;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace terra.Common
{
    public static class SqlHelper
    {

        #region Design pattern "Singleton"

        private static readonly ILog log = LogManager.GetLogger(typeof(SqlHelper));

        #endregion


        #region Public properties

        public static SqlConnection GetConnection(string connectionString)
        {
            SqlConnection connection = new SqlConnection();
            try
            {
                if (connection != null)
                {
                    connection.ConnectionString = connectionString;
                    connection.Open();
                }
            }
            catch (Exception ex)
            {
                log.Error(ex.Message);
            }
            return connection;
        }

        public static SqlConnection GetConnection()
        {
            string connectionString = ConfigurationManager.ConnectionStrings["dbConnString"].ConnectionString;
            SqlConnection connection = new SqlConnection();
            try
            {
                if (connection != null)
                {
                    connection.ConnectionString = connectionString;
                    connection.Open();
                }
            }
            catch (Exception ex)
            {
                log.Error(ex.Message);
            }
            return connection;
        }


        public static SqlCommand GetCommand(string commandText, SqlConnection conn, List<SqlParameter> sqlParameters = null, int commandTimeout = 30)
        {
            SqlCommand command = new SqlCommand();
            try
            {
                if (command != null)
                {
                    command.Connection = conn;
                    command.CommandTimeout = commandTimeout;
                    command.CommandText = commandText;

                    command.Parameters.Clear();
                    if (sqlParameters != null)
                    {
                        foreach(SqlParameter sqlParameter in sqlParameters )
                        {
                            command.Parameters.Add(sqlParameter);
                        }
                    }

                }
            }
            catch (Exception ex)
            {
                log.Error(ex.Message);
            }
            return command;
        }

        public static SqlCommand GetCommand(string commandText, SqlConnection conn, List<SqlParameter> sqlParameters = null )
        {
            Int32 commandTimeout = Int32.Parse(ConfigurationManager.AppSettings["dbCommandTimeout"].ToString());

            SqlCommand command = new SqlCommand();
            try
            {
                if (command != null)
                {
                    command.Connection = conn;
                    command.CommandTimeout = commandTimeout;
                    command.CommandText = commandText;

                    command.Parameters.Clear();
                    if (sqlParameters != null)
                    {
                        foreach (SqlParameter sqlParameter in sqlParameters)
                        {
                            command.Parameters.Add(sqlParameter);
                        }
                    }

                }
            }
            catch (Exception ex)
            {
                log.Error(ex.Message);
            }
            return command;
        }


        #endregion

    }
}