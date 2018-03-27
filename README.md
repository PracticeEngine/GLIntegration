# GLIntegration

General Ledger Integration with Practice Engine

# Overview

The GL Integration works by providing a set of Nominal Ledger tables that map our single-entry accounting system into a double-entry system.  Once the double entry values are created, the system (this project) has a GL Provider that is mapped to a GL System, where it queries for Account Types and Accounts which create a set of mappings.  

After the mappings are created, a Journal is created in the Nominal Ledger tables.  That Journal is then available to be posted to the provider.

## Database

Expected to be deployed to the Practice Engine Database - the NominalLedger.Db dacpac includes the 'core' bits needed to run this application.  The PE.CustomProcedures include Stored Procedures that are typically very customized for a client to create the double-entry values needed to support the mappings they desire.

## Providers

At present, we support two real providers (SQL and Intacct). We also have a Fake Provider that supports running the application without a live provider.  The Fake Provider does not really do anything - just provides some mock data that helps with testing and development.

The Sql Provider expects that the system is run on a Sql Server that holds both a GL Database and the PE Database (or via Linked Servers).  There are several different Providers that run via the Sql Provider.  Including (Great Plains, Access Dynamics, and Sun Systems).

## Other Aspects

There are several other aspects which have been added for various clients, etc.  These include 'Statistic Journals' and 'Expense Journals' that will transfer Staff Hours and Staff Expenses to the GL system.