using Microsoft.Extensions.Options;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Hangfire.Server;
using Hangfire.Console;
using Microsoft.AspNetCore.Hosting;
using System.IO;
using Intacct.SDK;
using Intacct.SDK.Functions.Common;
using Intacct.SDK.Functions.AccountsReceivable;
using Intacct.SDK.Functions;
using Intacct.SDK.Functions.Company;
using Intacct.SDK.Functions.EmployeeExpenses;
using Intacct.SDK.Functions.Projects;

namespace PE.Nominal.Intacct
{
    /// <summary>
    /// Service to provide extra functionality for Intacct Integrations
    /// </summary>
    public class IntacctSyncService : IntacctBaseService
    {
        public IntacctSyncService(IOptions<IntacctConfig> config, IHostingEnvironment env)
            :base(config.Value, env)
        {
            this.SyncOnlyNew = false;
        }

        /// <summary>
        /// Do not perform updates
        /// </summary>
        public bool SyncOnlyNew { get; set; }

        /// <summary>
        /// Performs a Sync of All Customers into Intacct
        /// </summary>
        /// <param name="customers"></param>
        public async Task SyncAllEmployees(IEnumerable<IntacctEmployee> employees, PerformContext context)
        {
            var Orgs = employees.Select(c => c.Org).Distinct();
            foreach (var org in Orgs)
            {
                if (HasOrgConfig(org))
                {
                    context.WriteLine("Processing Organization #{0}", org);
                    var client = GetClient(org);
                    var orgemployees = employees.Where(c => c.Org == org);
                    await SyncOrgEmployees(client, orgemployees, context);
                }
            }

        }
        /// <summary>
        /// Performs a Sync of All Customers into Intacct
        /// </summary>
        /// <param name="customers"></param>
        public async Task SyncAllCustomers(IEnumerable<IntacctCustomer> customers, PerformContext context)
        {
            var Orgs = customers.Select(c => c.Org).Distinct();
            foreach(var org in Orgs)
            {
                if (HasOrgConfig(org))
                {
                    context.WriteLine("Processing Organization #{0}", org);
                    var client = GetClient(org);
                    var orgcustomers = customers.Where(c => c.Org == org);
                    await SyncOrgCustomers(client, orgcustomers, context);
                }
            }
        }

        /// <summary>
        /// Performs a Sync of All Projects into Intacct
        /// </summary>
        /// <param name="customers"></param>
        public async Task SyncAllProjects(IEnumerable<IntacctProject> projects, PerformContext context)
        {
            var Orgs = projects.Select(c => c.Org).Distinct();
            foreach (var org in Orgs)
            {
                if (HasOrgConfig(org))
                {
                    context.WriteLine("Processing Organization #{0}", org);
                    var client = GetClient(org);
                    var orgprojects = projects.Where(c => c.Org == org);
                    await SyncOrgProjects(client, orgprojects, context);
                }
            }
        }

        /// <summary>
        /// Synchronizes a set of customers using a connected IntacctClient
        /// </summary>
        /// <param name="client">The Client to sync to</param>
        /// <param name="orgcustomers">Customer Data to Send</param>
        private async Task SyncOrgCustomers(OnlineClient client, IEnumerable<IntacctCustomer> orgcustomers, PerformContext context)
        {
            IList<string> types = await GetCustTypes(client, context);
            IDictionary<string, string> customermap = await GetCustomerIds(client, context);

            // Filter Existing Out
            if (SyncOnlyNew)
            {
                context.WriteLine("Filtering out Existing Customers");
                orgcustomers = orgcustomers.Where(c => !customermap.ContainsKey(c.CUSTOMERID)).ToArray();
            }

            // Send in batches of Customers
            int sent = 0;
            int total = orgcustomers.Count();
            while (sent < total)
            {
                // What's in this batch
                var batchData = orgcustomers.Skip(sent).Take(100).ToList();
                context.WriteLine("Preparing Batch of 100 ({0} - {1} of {2})", sent, sent + batchData.Count, total);
                sent += batchData.Count;

                // Create the Batch for Intacct
                List<IFunction> batchFunctions = new List<IFunction>();
                foreach (var customer in batchData)
                {
                    var hasValidCustType = types.Contains(customer.CUSTTYPENAME);
                    if (customermap.ContainsKey(customer.CUSTOMERID))
                    {
                        // Update the Customer
                        CustomerUpdate update = new CustomerUpdate
                        {
                            CustomerId = customer.CUSTOMERID,
                            CustomerName = IntacctCleanString(customer.CUSTNAME),
                            PrintAs = customer.CONTACTNAME,
                            FirstName = customer.FIRSTNAME,
                            LastName = customer.LASTNAME,
                            PrimaryEmailAddress = customer.EMAIL1,
                            Active = customer.STATUS == "active",
                            AddressLine1 = customer.ADDRESS1,
                            City = customer.CITY,
                            StateProvince = customer.STATE,
                            Country = "United States",
                            ZipPostalCode = customer.ZIP,
                            ParentCustomerId = customer.PARENTID
                        };
                        if (!String.IsNullOrWhiteSpace(customer.FIRSTNAME))
                        {
                            update.FirstName = customer.FIRSTNAME;
                        }
                        if (!String.IsNullOrWhiteSpace(customer.LASTNAME))
                        {
                            update.LastName = customer.LASTNAME;
                        }
                        update.CustomFields.Add("RECORDNO", customermap[customer.CUSTOMERID]);
                        if (hasValidCustType)
                        {
                            update.CustomerTypeId = customer.CUSTTYPENAME;
                        }
                        batchFunctions.Add(update);
                    }
                    else
                    {
                        // Create the Customer
                        CustomerCreate create = new CustomerCreate
                        {
                            CustomerId = customer.CUSTOMERID,
                            CustomerName = IntacctCleanString(customer.CUSTNAME),
                            PrintAs = customer.CONTACTNAME,
                            FirstName = customer.FIRSTNAME,
                            LastName = customer.LASTNAME,
                            PrimaryEmailAddress = customer.EMAIL1,
                            Active = customer.STATUS == "active",
                            AddressLine1 = customer.ADDRESS1,
                            City = customer.CITY,
                            StateProvince = customer.STATE,
                            Country = "United States",
                            ZipPostalCode = customer.ZIP,
                            ParentCustomerId = customer.PARENTID
                        };
                        if (hasValidCustType)
                        {
                            create.CustomerTypeId = customer.CUSTTYPENAME;
                        }
                        batchFunctions.Add(create);
                    }
                }

                // Send the Batch to Intacct
                context.WriteLine("Sending Batch to Intacct");
                var response = await client.ExecuteBatch(batchFunctions);
                context.WriteLine("Inspecting Response from Intacct");
                foreach (var result in response.Results)
                {
                    if (result.Errors != null)
                    {
                        context.SetTextColor(ConsoleTextColor.Red);
                        context.WriteLine("==================================");
                        foreach (var err in result.Errors)
                        {
                            context.WriteLine(err);
                        }
                        context.WriteLine("==================================");
                        context.WriteLine();
                        Console.ResetColor();
                    }
                }
            }
        }


        /// <summary>
        /// Synchronizes a set of employees using a connected IntacctClient
        /// </summary>
        /// <param name="client">The Client to sync to</param>
        /// <param name="orgemployees">Customer Data to Send</param>
        private async Task SyncOrgEmployees(OnlineClient client, IEnumerable<IntacctEmployee> orgemployees, PerformContext context)
        {
            IDictionary<string, string> employeemap = await GetEmployeeIds(client, context);
            IList<string> contactNames = await GetContacts(client, context);

            // Filter Existing Out
            if (SyncOnlyNew)
            {
                context.WriteLine("Filtering out Existing Employees");
                orgemployees = orgemployees.Where(c => !contactNames.Contains(IntacctCleanString(c.EMPLOYEENAME))).ToArray();
            }

            // Send in batches of Employees
            int sent = 0;
            int total = orgemployees.Count();
            while (sent < total)
            {
                // What's in this batch
                var batchData = orgemployees.Skip(sent).Take(50).ToList();
                context.WriteLine("Preparing Batch of 50 ({0} - {1} of {2})", sent, sent + batchData.Count, total);
                sent += batchData.Count;

                // Create the Batch for Intacct
                List<IFunction> batchFunctions = new List<IFunction>();
                foreach (var employee in batchData)
                {
                    // Process the Contact First
                    if (contactNames.Contains(IntacctCleanString(employee.EMPLOYEENAME)))
                    {
                        // Update the Contact
                        ContactUpdate update = new ContactUpdate
                        {
                            PrintAs = employee.EMPLOYEENAME,
                            ContactName = IntacctCleanString(employee.EMPLOYEENAME),
                            FirstName = employee.FIRSTNAME,
                            LastName = employee.LASTNAME,
                            Active = employee.EMPLOYEEACTIVE == "active",
                            PrimaryPhoneNo = employee.PHONE,
                            PrimaryEmailAddress = employee.EMAIL
                        };
                        batchFunctions.Add(update);
                    }
                    else
                    {
                        // Create the Contact
                        ContactCreate create = new ContactCreate
                        {
                            PrintAs = employee.EMPLOYEENAME,
                            ContactName = IntacctCleanString(employee.EMPLOYEENAME),
                            FirstName = employee.FIRSTNAME,
                            LastName = employee.LASTNAME,
                            Active = employee.EMPLOYEEACTIVE == "active",
                            PrimaryPhoneNo = employee.PHONE,
                            PrimaryEmailAddress = employee.EMAIL
                        };
                        batchFunctions.Add(create);
                        // Add to our List, so we don't update duplicates
                        contactNames.Add(employee.EMPLOYEENAME);
                    }

                    // Process the Employee Now
                    if (employeemap.ContainsKey(employee.EMPLOYEEID))
                    {
                        // Update the Employee
                        EmployeeUpdate update = new EmployeeUpdate
                        {
                            EmployeeId = employee.EMPLOYEEID,
                            ContactName = IntacctCleanString(employee.EMPLOYEENAME),
                            DepartmentId = employee.DEPARTMENTID,
                            LocationId = employee.LOCATIONID,
                            Active = employee.EMPLOYEEACTIVE == "active",
                            StartDate = employee.EMPLOYEESTART,
                            EndDate = employee.EMPLOYEETERMINATION
                        };
                        if (!String.IsNullOrWhiteSpace(employee.PE_STAFF_CODE))
                        {
                            update.CustomFields.Add("PE_STAFF_CODE", employee.PE_STAFF_CODE);
                        }
                        update.CustomFields.Add("RECORDNO", employeemap[employee.EMPLOYEEID]);
                        batchFunctions.Add(update);
                    }
                    else
                    {
                        // Create the Employee
                        EmployeeCreate create = new EmployeeCreate
                        {
                            EmployeeId = employee.EMPLOYEEID,
                            ContactName = IntacctCleanString(employee.EMPLOYEENAME),
                            DepartmentId = employee.DEPARTMENTID,
                            LocationId = employee.LOCATIONID,
                            Active = employee.EMPLOYEEACTIVE == "active",
                            StartDate = employee.EMPLOYEESTART,
                            EndDate = employee.EMPLOYEETERMINATION
                        };
                        if (!String.IsNullOrWhiteSpace(employee.PE_STAFF_CODE))
                        {
                            create.CustomFields.Add("PE_STAFF_CODE", employee.PE_STAFF_CODE);
                        }
                        batchFunctions.Add(create);
                    }
                }

                // Send the Batch to Intacct
                context.WriteLine("Sending Batch to Intacct");
                var response = await client.ExecuteBatch(batchFunctions);
                context.WriteLine("Inspecting Response from Intacct");
                foreach (var result in response.Results)
                {
                    if (result.Errors != null)
                    {
                        context.SetTextColor(ConsoleTextColor.Red);
                        context.WriteLine("==================================");
                        foreach (var err in result.Errors)
                        {
                            context.WriteLine(err);
                        }
                        context.WriteLine("==================================");
                        context.WriteLine();
                        Console.ResetColor();
                    }
                }
            }
        }


        /// <summary>
        /// Synchronizes a set of projects using a connected IntacctClient
        /// </summary>
        /// <param name="client">The Client to sync to</param>
        /// <param name="orgprojects">Project Data to Send</param>
        private async Task SyncOrgProjects(OnlineClient client, IEnumerable<IntacctProject> orgprojects, PerformContext context)
        {
            IDictionary<string, string> projectmap = await GetProjectIds(client, context);

            // Filter Existing Out
            if (SyncOnlyNew)
            {
                context.WriteLine("Filtering out Existing Projects");
                orgprojects = orgprojects.Where(c => !projectmap.ContainsKey(c.PROJECTID)).ToArray();
            }

            // Send in batches of Projects
            int sent = 0;
            int total = orgprojects.Count();
            while (sent < total)
            {
                // What's in this batch
                var batchData = orgprojects.Skip(sent).Take(100).ToList();
                context.WriteLine("Preparing Batch of 100 ({0} - {1} of {2})", sent, sent + batchData.Count, total);
                sent += batchData.Count;

                // Create the Batch for Intacct
                List<IFunction> batchFunctions = new List<IFunction>();
                foreach (var project in batchData)
                {
                    if (!projectmap.ContainsKey(project.PROJECTID))
                    {
                        // Create the Project
                        ProjectCreate create = new ProjectCreate
                        {
                            CustomerId = project.CUSTOMERID,
                            ProjectId = project.PROJECTID,
                            ProjectName = project.PROJECTNAME,
                            ProjectCategory = project.PROJECTCATEGORY,
                            ProjectStatus = project.PROJECTSTATUS,
                            Active = project.PROJECTACTIVE == "active",
                            DepartmentId = project.DEPARTMENTID,
                            LocationId = project.LOCATIONID,
                            ProjectManagerEmployeeId = project.PROJECTMANAGERID
                        };
                        if (!String.IsNullOrWhiteSpace(project.PROJECTPARENTID))
                        {
                            create.ParentProjectId = project.PROJECTPARENTID;
                        }
                        if (!String.IsNullOrWhiteSpace(project.PE_JOB_CODE))
                        {
                            create.CustomFields.Add("PE_JOB_CODE", project.PE_JOB_CODE);
                        }
                        if (!String.IsNullOrWhiteSpace(project.USER_RESTRICTIONS))
                        {
                            create.CustomFields.Add("USER_RESTRICTIONS", project.USER_RESTRICTIONS);
                        }
                        batchFunctions.Add(create);
                    }
                    else
                    {
                        // Update the Project
                        ProjectUpdate update = new ProjectUpdate
                        {
                            CustomerId = project.CUSTOMERID,
                            ProjectId = project.PROJECTID,
                            ProjectName = project.PROJECTNAME,
                            ProjectCategory = project.PROJECTCATEGORY,
                            ProjectStatus = project.PROJECTSTATUS,
                            Active = project.PROJECTACTIVE == "active",
                            DepartmentId = project.DEPARTMENTID,
                            LocationId = project.LOCATIONID,
                            ProjectManagerEmployeeId = project.PROJECTMANAGERID
                        };
                        if (!String.IsNullOrWhiteSpace(project.PROJECTPARENTID))
                        {
                            update.ParentProjectId = project.PROJECTPARENTID;
                        }
                        if (!String.IsNullOrWhiteSpace(project.PE_JOB_CODE))
                        {
                            update.CustomFields.Add("PE_JOB_CODE", project.PE_JOB_CODE);
                        }
                        if (!String.IsNullOrWhiteSpace(project.USER_RESTRICTIONS))
                        {
                            update.CustomFields.Add("USER_RESTRICTIONS", project.USER_RESTRICTIONS);
                        }
                        batchFunctions.Add(update);
                    }
                }

                // Send the Batch to Intacct
                context.WriteLine("Sending Batch to Intacct");
                var response = await client.ExecuteBatch(batchFunctions);
                context.WriteLine("Inspecting Response from Intacct");
                foreach (var result in response.Results)
                {
                    if (result.Errors != null)
                    {
                        context.SetTextColor(ConsoleTextColor.Red);
                        context.WriteLine("==================================");
                        foreach (var err in result.Errors)
                        {
                            context.WriteLine(err);
                        }
                        context.WriteLine("==================================");
                        context.WriteLine();
                        Console.ResetColor();
                    }
                }
            }
        }


        /// <summary>
        /// Returns a list of all known Customer Types from Intacct
        /// </summary>
        /// <param name="client"></param>
        /// <returns></returns>
        private async Task<IList<string>> GetCustTypes(OnlineClient client, PerformContext context)
        {
            // Get Types (assume less than 1000 exist)
            ReadByQuery read = new ReadByQuery
            {
                ObjectName = "CUSTTYPE",
                PageSize = 1000
            };
            context.WriteLine("Loading Customer Types from Intacct");
            var response = await client.Execute(read);
            var xmlResult = response.Results.First();
            xmlResult.EnsureStatusSuccess();

            return new List<string>(xmlResult.Data.Select(el => el.Element("NAME").Value));
        }

        /// <summary>
        /// Returns a Dictionary of all EmployeeId (StaffRef) to Intacct Records
        /// </summary>
        /// <param name="client"></param>
        /// <returns></returns>
        private async Task<IDictionary<string, string>> GetEmployeeIds(OnlineClient client, PerformContext context)
        {
            var employeeMapping = new Dictionary<string, string>();
            ReadByQuery read = new ReadByQuery
            {
                ObjectName = "EMPLOYEE",
                PageSize = 1000
            };
            read.Fields.Clear();
            read.Fields.AddRange(new string[] { "RECORDNO", "EMPLOYEEID" });
            context.WriteLine("Loading Employee Records from Intacct for comparison");
            var response = await client.Execute(read);
            var xmlResult = response.Results.First();
            xmlResult.EnsureStatusSuccess();

            var details = xmlResult.Data;
            foreach (var detail in details)
            {
                var custid = detail.Element("EMPLOYEEID");
                var rec = detail.Element("RECORDNO");

                // Ignore Invalid Data
                if (custid == null || rec == null)
                    continue;

                if (!employeeMapping.ContainsKey(custid.Value))
                {
                    employeeMapping.Add(custid.Value, rec.Value);
                }
            }

            // Get More Data
            int receivedCount = xmlResult.Count;

            while (receivedCount < xmlResult.TotalCount)
            {
                // Read Additional Pages of Data
                ReadMore more = new ReadMore(xmlResult.ControlId)
                {
                    ResultId = xmlResult.ResultId
                };
                context.WriteLine("Loading Additional Employee Records from Intacct for comparison");
                response = await client.Execute(more);
                xmlResult = response.Results.First();
                xmlResult.EnsureStatusSuccess();

                // Process Results
                details = xmlResult.Data;
                foreach (var detail in details)
                {
                    var custid = detail.Element("EMPLOYEEID");
                    var rec = detail.Element("RECORDNO");

                    // Ignore Invalid Data
                    if (custid == null || rec == null)
                        continue;

                    if (!employeeMapping.ContainsKey(custid.Value))
                    {
                        employeeMapping.Add(custid.Value, rec.Value);
                    }
                }

                // Increment the Counter
                receivedCount += xmlResult.Count;
            }

            // Return the mappings
            context.WriteLine("Found {0} employees in Intacct", employeeMapping.Count);
            return employeeMapping;
        }

        /// <summary>
        /// Returns a Dictionary of all Contacts (Names) to Intacct Records
        /// </summary>
        /// <param name="client"></param>
        /// <returns></returns>
        private async Task<IList<string>> GetContacts(OnlineClient client, PerformContext context)
        {
            var nameList = new List<string>();
            ReadByQuery read = new ReadByQuery
            {
                ObjectName = "CONTACT",
                PageSize = 1000
            };
            read.Fields.Clear();
            read.Fields.AddRange(new string[] { "CONTACTNAME" });
            context.WriteLine("Loading Contact Records from Intacct for comparison");
            var response = await client.Execute(read);
            var xmlResult = response.Results.First();
            xmlResult.EnsureStatusSuccess();

            var details = xmlResult.Data;
            foreach (var detail in details)
            {
                var contName = detail.Element("CONTACTNAME");

                // Ignore Invalid Data
                if (contName == null)
                    continue;

                if (!nameList.Contains(contName.Value))
                {
                    nameList.Add(contName.Value);
                }
            }

            // Get More Data
            int receivedCount = xmlResult.Count;

            while (receivedCount < xmlResult.TotalCount)
            {
                // Read Additional Pages of Data
                ReadMore more = new ReadMore(xmlResult.ControlId)
                {
                    ResultId = xmlResult.ResultId
                };
                context.WriteLine("Loading Additional Contact Records from Intacct for comparison");
                response = await client.Execute(more);
                xmlResult = response.Results.First();
                xmlResult.EnsureStatusSuccess();

                // Process Results
                details = xmlResult.Data;
                foreach (var detail in details)
                {
                    var contName = detail.Element("CONTACTNAME");

                    // Ignore Invalid Data
                    if (contName == null)
                        continue;

                    if (!nameList.Contains(contName.Value))
                    {
                        nameList.Add(contName.Value);
                    }
                }

                // Increment the Counter
                receivedCount += xmlResult.Count;
            }

            // Return the mappings
            context.WriteLine("Found {0} contacts in Intacct", nameList.Count);
            return nameList;
        }


        /// <summary>
        /// Returns a Dictionary of all CustomerID (ClientCodes) to Intacct Records
        /// </summary>
        /// <param name="client"></param>
        /// <returns></returns>
        private async Task<IDictionary<string,string>> GetCustomerIds(OnlineClient client, PerformContext context)
        {
            var customerMapping = new Dictionary<string, string>();
            ReadByQuery read = new ReadByQuery
            {
                ObjectName = "CUSTOMER",
                PageSize = 1000
            };
            read.Fields.Clear();
            read.Fields.AddRange(new string[]{ "RECORDNO", "CUSTOMERID" });
            context.WriteLine("Loading Customer Records from Intacct for comparison");
            var response = await client.Execute(read);
            var xmlResult = response.Results.First();
            xmlResult.EnsureStatusSuccess();

            var details = xmlResult.Data;
            foreach(var detail in details)
            {
                var custid = detail.Element("CUSTOMERID");
                var rec = detail.Element("RECORDNO");

                // Ignore Invalid Data
                if (custid == null || rec == null)
                    continue;

                if (!customerMapping.ContainsKey(custid.Value))
                {
                    customerMapping.Add(custid.Value, rec.Value);
                }
            }

            // Get More Data
            int receivedCount = xmlResult.Count;

            while (receivedCount < xmlResult.TotalCount)
            {
                // Read Additional Pages of Data
                ReadMore more = new ReadMore(xmlResult.ControlId)
                {
                    ResultId = xmlResult.ResultId
                };
                context.WriteLine("Loading Additional Customer Records from Intacct for comparison");
                response = await client.Execute(more);
                xmlResult = response.Results.First();
                xmlResult.EnsureStatusSuccess();

                // Process Results
                details = xmlResult.Data;
                foreach (var detail in details)
                {
                    var custid = detail.Element("CUSTOMERID");
                    var rec = detail.Element("RECORDNO");

                    // Ignore Invalid Data
                    if (custid == null || rec == null)
                        continue;

                    if (!customerMapping.ContainsKey(custid.Value))
                    {
                        customerMapping.Add(custid.Value, rec.Value);
                    }
                }

                // Increment the Counter
                receivedCount += xmlResult.Count;
            }

            // Return the mappings
            context.WriteLine("Found {0} customers in Intacct", customerMapping.Count);
            return customerMapping;
        }


        /// <summary>
        /// Returns a Dictionary of all ProjectID (ClientCode.JobCode) to Intacct Records
        /// </summary>
        /// <param name="client"></param>
        /// <returns></returns>
        private async Task<IDictionary<string, string>> GetProjectIds(OnlineClient client, PerformContext context)
        {
            var projectMapping = new Dictionary<string, string>();
            ReadByQuery read = new ReadByQuery
            {
                ObjectName = "PROJECT",
                PageSize = 1000
            };
            read.Fields.Clear();
            read.Fields.AddRange(new string[] { "RECORDNO", "PROJECTID" });
            context.WriteLine("Loading Project Records from Intacct for comparison");
            var response = await client.Execute(read);
            var xmlResult = response.Results.First();
            xmlResult.EnsureStatusSuccess();

            var details = xmlResult.Data;
            foreach (var detail in details)
            {
                var custid = detail.Element("PROJECTID");
                var rec = detail.Element("RECORDNO");

                // Ignore Invalid Data
                if (custid == null || rec == null)
                    continue;

                if (!projectMapping.ContainsKey(custid.Value))
                {
                    projectMapping.Add(custid.Value, rec.Value);
                }
            }

            // Get More Data
            int receivedCount = xmlResult.Count;

            while (receivedCount < xmlResult.TotalCount)
            {
                // Read Additional Pages of Data
                ReadMore more = new ReadMore(xmlResult.ControlId)
                {
                    ResultId = xmlResult.ResultId
                };
                context.WriteLine("Loading Additional Customer Records from Intacct for comparison");
                response = await client.Execute(more);
                xmlResult = response.Results.First();
                xmlResult.EnsureStatusSuccess();

                // Process Results
                details = xmlResult.Data;
                foreach (var detail in details)
                {
                    var custid = detail.Element("PROJECTID");
                    var rec = detail.Element("RECORDNO");

                    // Ignore Invalid Data
                    if (custid == null || rec == null)
                        continue;

                    if (!projectMapping.ContainsKey(custid.Value))
                    {
                        projectMapping.Add(custid.Value, rec.Value);
                    }
                }

                // Increment the Counter
                receivedCount += xmlResult.Count;
            }

            // Return the mappings
            context.WriteLine("Found {0} projects in Intacct", projectMapping.Count);
            return projectMapping;
        }



    }
}
