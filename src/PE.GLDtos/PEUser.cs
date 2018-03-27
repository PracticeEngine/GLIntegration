using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace PE.Nominal
{
    /// <summary>
    /// The Logical PE User Identity
    /// </summary>
    public class PEUser
    {
        public int StaffIndex { get; set; }

        public string StaffUser { get; set; }

        public string Password { get; set; }

        public DateTime? LastPasswordFailureDate { get; set; }

        public int PasswordFailuresSinceLastSuccess { get; set; }
    }
}