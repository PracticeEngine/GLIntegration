using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class GLSetup
    {
         public short DRSDept {get; set;}
         public short DRSPart {get; set;}
         public short DRSServ {get; set;}
         public short DRSOffice {get; set;}
         public short WIPDept {get; set;}
         public short WIPPart {get; set;}
         public short WIPServ {get; set;}
         public short WIPOffice {get; set;}
         public short WIPLevel {get; set;}
         public short DRSLevel {get; set;}
         public string IntSystem {get; set;}
         public short DisbLevel {get; set;}
         public string DisbStd {get; set;}
         public string FeeSource {get; set;}
         public short FeeProfit {get; set;}
         public short FeePart {get; set;}
         public bool InterCo {get; set;}
         public bool Cashbook {get; set;}
         public bool Expenses {get; set;}
    }
}
