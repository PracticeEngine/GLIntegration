using System;
using System.Collections.Generic;
using System.Text;

namespace PE.Nominal.Options
{
    public class LoginOptions
    {

        public TimeSpan RememberMeLoginDuration { get; set; }

        public int LockoutAfter { get; set; }

        public TimeSpan LockoutFor { get; set; }

        public bool SQLProvider { get; set; }
    }
}
