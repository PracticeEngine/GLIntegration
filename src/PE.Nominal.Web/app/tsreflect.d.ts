declare namespace PE.Nominal {
	interface ICashbookExtract {
		NomBankId: string | null;
		BatchID: number;
		LodgeDate: string;
		LodgeIndex: number;
		LodgeType: string | null;
		LodgeRef: string | null;
		LodgeDebtor: number;
		LodgeClient: string | null;
		LodgePayor: string | null;
		LodgeAmt: number;
		LodgeDetIndex: number;
		NomBatch: number;
	}
	interface ICashbookRepostBatch {
		LodgeBatch: number;
		NumDep: number;
		ValDep: number;
    }
    interface IDetailGroup {
        NLPeriodIndex: number;
        NLOrg: number;
        NLSource: string | null;
        NLSection: string | null;
        NLAccount: string | null;
        NLOffice: string | null;
        NLDept: string | null;
        NLService: string | null;
        NLPartner: number | null;
        OrgName: string | null;
        ServiceName: string | null;
        OfficeName: string | null;
        PartnerName: string | null;
        DepartmentName: string | null;
    }
    interface IDetailLine {
        NLIndex: number;
        NLPeriodIndex: number;
        NLOrg: number;
        NLSource: string | null;
        NLSection: string | null;
        NLAccount: string | null;
        NLDate: string | null;
        NomPostAcc: string | null;
        TransRefAlpha: string | null;
        Amount: number | null;
        TransTypeDescription: string | null;
    }
	interface IDisbCode {
		ChargeCode: string | null;
		ChargeName: string | null;
	}
	interface IExpenseLines {
		NomExpIndex: number;
		PeriodIndex: number;
		ExpOrg: number;
		DisbCode: string | null;
		OrgName: string | null;
		DisbName: string | null;
		PostAcc: string | null;
		ExpDate: string;
		Amount: number;
		VATAmount: number;
		Description: string | null;
	}
	interface IExpenseStaff {
		StaffOrg: number;
		StaffIndex: number;
		OrgName: string | null;
		StaffName: string | null;
		BlankStaff: number;
		BlankAccounts: number;
	}
	interface IGLAccount {
		AccountDesc: string | null;
		AccountCode: string | null;
		AccountTypeCode: string | null;
		AccountTypeDesc: string | null;
	}
	interface IGLMapping {
		AccountCode: string | null;
		AccountTypeCode: string | null;
		MapIndex: number;
		MapAccount: string | null;
		MapDept: string | null;
		MapOffice: string | null;
		MapOrg: number;
		MapPart: number;
		MapSection: string | null;
		MapServ: string | null;
		MapSource: string | null;
        StaffName: string | null;
        OrgName: string | null;
        ServiceName: string | null;
        OfficeName: string | null;
        PartnerName: string | null;
        DepartmentName: string | null;
	}
	interface IGLNumEntries {
		NumEntries: number;
	}
	interface IGLSetup {
		DRSDept: number;
		DRSPart: number;
		DRSServ: number;
		DRSOffice: number;
		WIPDept: number;
		WIPPart: number;
		WIPServ: number;
		WIPOffice: number;
		WIPLevel: number;
		DRSLevel: number;
		IntSystem: string | null;
		DisbLevel: number;
		DisbStd: string | null;
		FeeSource: string | null;
		FeeProfit: number;
		FeePart: number;
		InterCo: boolean;
		Cashbook: boolean;
		Expenses: boolean;
	}
	interface IGLType {
		AccountTypeCode: string | null;
		AccountTypeDesc: string | null;
    }
    interface IImportMap {
        DisbCode: string | null;
        DisbName: string | null;
        DisbMapIndex: number;
        NLOrg: number;
        NLIdx: number;
        NLAcc: string | null;
        OrgName: string | null;
        NumBlank: number;
    }
    interface IImportMapUpdate {
        DisbCode: string | null;
        DisbMapIndex: number;
    }
	interface IJournalExtract extends PE.Nominal.IMapBase {
		NomBatch: number;
		NomNarrative: string | null;
		NomTransRef: string | null;
		NomAmount: number;
		NomDate: string;
		IntacctCustomerID: string | null;
		IntacctProjectID: string | null;
		IntacctEmployeeID: string | null;
		IntacctDepartment: string | null;
		IntacctLocation: string | null;
		client_partner_id: string | null;
		category_name_id: string | null;
		owner_name_id: string | null;
		service_type_id: string | null;
		client_partner: string | null;
		category_name: string | null;
		owner_name: string | null;
		service_type: string | null;
	}
	interface IJournalGroup {
		NomOrg: number;
		NomSource: string | null;
		NomSection: string | null;
		NomAccount: string | null;
		NomOffice: string | null;
		NomDept: string | null;
		NomService: string | null;
		NomPartner: number | null;
		OrgName: string | null;
		ServiceName: string | null;
		OfficeName: string | null;
		PartnerName: string | null;
		DepartmentName: string | null;
		NumBlank: number;
	}
	interface IJournalMap extends PE.Nominal.IJournalExtract {
		NumBlank: number;
		NomIndex: number;
		NomPeriodIndex: number;
		NomOrg: number;
		NomSource: string | null;
		NomSection: string | null;
		NomAccount: string | null;
		NomOffice: string | null;
		NomDept: string | null;
		NomService: string | null;
		NomPartner: number;
		NomVATAmount: number;
		OrgName: string | null;
		ServiceName: string | null;
		OfficeName: string | null;
		PartnerName: string | null;
		DepartmentName: string | null;
		NomPostAcc: string | null;
		NomVATAcc: string | null;
		NomDRSAcc: string | null;
		NomMaxRef: number;
		NomJnlType: string | null;
		NomDRSCode: string | null;
		NomVATCode: string | null;
		NomVATRateCode: string | null;
		NomPosted: boolean;
		NomPostDate: string | null;
		Job_Dept: string | null;
		Staff_Dept: string | null;
		ClientCode: string | null;
		StaffCode: string | null;
		Currency: string | null;
		ForeignAmount: number | null;
	}
	interface IJournalRepostBatch {
		NomBatch: number;
		NumLines: number;
		Debits: number;
		Credits: number;
		PostDate: string;
	}
	interface IMapBase {
		MapIndex: number;
		AccountTypeCode: string | null;
		AccountCode: string | null;
	}
	interface IMapUpdate {
		MapIndex: number;
		AccountCode: string | null;
		AccountTypeCode: string | null;
	}
	interface IMenuItem {
		MenuName: string | null;
		VM: string | null;
	}
	interface IMissingExpenseAccountMap {
		ExpMapIndex: number;
		ExpOrg: number;
		PracName: string | null;
		ChargeCode: string | null;
		ChargeName: string | null;
		ChargeExpAccount: string | null;
		NonChargeExpAccount: string | null;
        ChargeSuffix1: number | null;
        ChargeSuffix2: number | null;
        ChargeSuffix3: number | null;
        NonChargeSuffix1: number | null;
        NonChargeSuffix2: number | null;
        NonChargeSuffix3: number | null;
	}
	interface IMissingExpenseStaff {
		StaffIndex: number;
		StaffCode: string | null;
		StaffName: string | null;
	}
	interface IMissingMap extends PE.Nominal.IMapBase {
		NomOrg: number;
		NomSource: string | null;
		NomSection: string | null;
		NomAccount: string | null;
		NomOffice: string | null;
		NomDept: string | null;
		NomService: string | null;
		NomPartner: number;
		OrgName: string | null;
		ServiceName: string | null;
		OfficeName: string | null;
		PartnerName: string | null;
		DepartmentName: string | null;
		NumBlank: number;
	}
	interface IMTDClient {
		ContIndex: number;
		ClientCode: string | null;
		ClientName: string | null;
		ClientStatus: string | null;
		Address: string | null;
		TownCity: string | null;
		County: string | null;
		Country: string | null;
		PostCode: string | null;
	}
	interface IMTDInvoice {
		DebtTranIndex: number;
		DebtTranType: number;
		ContIndex: number;
		Address: string | null;
		DebtTranRefAlpha: string | null;
		DebtTranRefNum: number;
		DebtTranDate: string;
		DueDate: string;
		DebtTranAmount: number;
		DebtTranVAT: number;
		Lines: Array<PE.Nominal.IMTDLineItem>;
	}
	interface IMTDLineItem {
		DebtTranIndex: number;
		Amount: number;
		VATCode: string | null;
		VATAmount: number;
		Description: string | null;
		TaxCode: string | null;
		AccountCode: string | null;
	}
	interface INomOrganisation {
		PracID: number;
		PracName: string | null;
		NLServer: string | null;
		NLDatabase: string | null;
		NLTransfer: boolean;
	}
	interface IPEUser {
		StaffIndex: number;
		StaffUser: string | null;
		Password: string | null;
		LastPasswordFailureDate: string | null;
		PasswordFailuresSinceLastSuccess: number;
	}
	interface IPostPeriods {
		NLPeriodIndex: number;
		PeriodDescription: string | null;
		PeriodStartDate: string;
		PeriodEndDate: string;
	}
	interface ISelectedDates {
		PracPeriodStart: string | null;
		PracPeriodEnd: string | null;
	}
}
declare namespace PE.Nominal.Intacct {
	interface IIntacctCustomer {
		Org: number;
		CUSTOMERID: string | null;
		CUSTNAME: string | null;
		CUSTTYPENAME: string | null;
		STATUS: string | null;
		CONTACTNAME: string | null;
		EMAIL1: string | null;
		ADDRESS1: string | null;
		CITY: string | null;
		STATE: string | null;
		COUNTRY: string | null;
		ZIP: string | null;
		FIRSTNAME: string | null;
		LASTNAME: string | null;
		PARENTID: string | null;
	}
	interface IIntacctEmployee {
		Org: number;
		EMPLOYEEID: string | null;
		EMPLOYEENAME: string | null;
		EMPLOYEESTART: string;
		EMPLOYEETERMINATION: string | null;
		EMPLOYEEACTIVE: string | null;
		DEPARTMENTID: string | null;
		LOCATIONID: string | null;
		PE_STAFF_CODE: string | null;
		FIRSTNAME: string | null;
		LASTNAME: string | null;
		PHONE: string | null;
		EMAIL: string | null;
	}
	interface IIntacctProject {
		Org: number;
		PROJECTID: string | null;
		PROJECTNAME: string | null;
		CUSTOMERID: string | null;
		PROJECTCATEGORY: string | null;
		PROJECTSTATUS: string | null;
		PROJECTACTIVE: string | null;
		DEPARTMENTID: string | null;
		LOCATIONID: string | null;
		PROJECTMANAGERID: string | null;
		PROJECTPARENTID: string | null;
		PE_JOB_CODE: string | null;
		USER_RESTRICTIONS: string | null;
	}
	interface IIntacctStatHours {
		Journal: string | null;
		ProjectID: string | null;
		EmployeeID: string | null;
		Hours: number;
		Account: string | null;
		BatchDate: string;
		BatchID: string | null;
		IntacctCustomerID: string | null;
		IntacctDepartment: string | null;
		IntacctLocation: string | null;
		client_partner_id: string | null;
		category_name_id: string | null;
		owner_name_id: string | null;
		service_type_id: string | null;
		client_partner: string | null;
		category_name: string | null;
		owner_name: string | null;
		service_type: string | null;
	}
}
