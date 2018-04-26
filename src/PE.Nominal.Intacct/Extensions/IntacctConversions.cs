using System;
using System.Collections.Generic;
using System.Text;

namespace PE.Nominal
{
    public static class IntacctConversions
    {
        /// <summary>
        /// Handles Mapping <see cref="Nullable{DateTime}"/> to 
        /// <see cref="DateTime"/> for Intacct which considers '1/1/0001 12:00 am' as an empty value
        /// </summary>
        /// <param name="date">Date to Convert</param>
        /// <returns></returns>
        public static DateTime ToIntacctDate(this DateTime? date)
        {
            return date.HasValue ? date.Value : DateTime.MinValue;
        }
    }
}
