using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Internal;
using Microsoft.EntityFrameworkCore.Storage;
using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public static class DatabaseFacadeExtensions
    {
        /// <summary>
        /// Executes a SQL Query Asynchronously creating non-entity Objects
        /// </summary>
        /// <typeparam name="T">Type of object to Build up</typeparam>
        /// <param name="databaseFacade">The Database to use</param>
        /// <param name="sql">The SQL Statement to Execute</param>
        /// <param name="cancellationToken">A Cancellation Token</param>
        /// <param name="parameters">Parameters that can be provided</param>
        /// <returns></returns>
        public static async Task<IEnumerable<T>> SqlQueryAsync<T>(
            this DatabaseFacade databaseFacade,
            string sql,
            params object[] parameters) where T : class, new()
        {
            List<T> results = new List<T>();

            var concurrencyDetector = databaseFacade.GetService<IConcurrencyDetector>();

            using (concurrencyDetector.EnterCriticalSection())
            {
                var rawSqlCommand = databaseFacade
                    .GetService<IRawSqlCommandBuilder>()
                    .Build(sql, parameters);

                var reader = await rawSqlCommand
                    .RelationalCommand
                    .ExecuteReaderAsync(
                        databaseFacade.GetService<IRelationalConnection>(),
                        parameterValues: rawSqlCommand.ParameterValues).ConfigureAwait(false);
                using (DbDataReader dbReader = reader.DbDataReader)
                {
                    List<Tuple<string, PropertyInfo, int>> propertyList = new List<Tuple<string, PropertyInfo, int>>();
                    for (int x = 0; x < dbReader.FieldCount; x++)
                    {

                        var propName = dbReader.GetName(x);
                        var prop = typeof(T).GetProperty(propName);
                        if (prop != null)
                        {
                            propertyList.Add(
                                new Tuple<string, PropertyInfo, int>(
                                    propName,
                                    prop,
                                    x));
                        }
                    }
                    while (await dbReader.ReadAsync().ConfigureAwait(false))
                    {
                        T obj = Activator.CreateInstance<T>();
                        foreach (Tuple<string, PropertyInfo, int> propToRead in propertyList)
                        {
                            if (!reader.DbDataReader.IsDBNull(propToRead.Item3))
                            {
                                propToRead.Item2.SetValue(obj, reader.DbDataReader[propToRead.Item1]);
                            }
                            else
                            {
                                propToRead.Item2.SetValue(obj, null);
                            }
                        }
                        results.Add(obj);
                    }
                }
                return results;
            }
        }
    }
}
