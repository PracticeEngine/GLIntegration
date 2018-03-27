using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class CashbookExtract
    {
        /// <summary>
        /// The Nominal Bank ID (BankNominal from tblTranNominalControl)
        /// </summary>
        public string NomBankId { get; set; }

        /// <summary>
        /// The Batch ID in tblTranNominalBank
        /// </summary>
        public int BatchID { get; set; }

        /// <summary>
        /// The Dete of the Deposit
        /// </summary>
        public DateTime LodgeDate { get; set; }

        /// <summary>
        /// The Index of the Deposit (Header/batch)
        /// </summary>
        public int LodgeIndex { get; set; }

        /// <summary>
        /// Type of Deposit (CHEQUE, CASH, DD, etc)
        /// </summary>
        public string LodgeType { get; set; }

        /// <summary>
        /// The Deposit Reference (Effectively our Batch ID)
        /// </summary>
        public string LodgeRef { get; set; }

        /// <summary>
        /// The Client Index of the Payor
        /// </summary>
        public int LodgeDebtor { get; set; }

        /// <summary>
        /// The Client Code of the Payor
        /// </summary>
        public string LodgeClient { get; set; }

        /// <summary>
        /// The Payor on the Deposit
        /// </summary>
        public string LodgePayor { get; set; }

        /// <summary>
        /// The Amount of the Deposit
        /// </summary>
        public decimal LodgeAmt { get; set; }

        /// <summary>
        /// The Deposit Detail Index
        /// </summary>
        public int LodgeDetIndex { get; set; }
        
        /// <summary>
        /// The Batch ID this is part of
        /// </summary>
        public int NomBatch { get; set; }
    }
}
