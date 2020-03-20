namespace PE.Nominal {

    /** Standard Enum Pub/Sub Topics */
    enum KOTOPIC {
        PAGE
    };

    var baseURL: string;

    /**
     * Base Class for all ViewModels
     */
    export abstract class BaseVM {
        isReady: KnockoutObservable<boolean>;
        protected toDispose: Array<{ dispose: () => void }>;
        private pages: Array<PE.Nominal.IMenuItem>;

        constructor(isReady: boolean = true) {
            this.isReady = ko.observable(isReady);
            this.toDispose = [];
        }


        dispose(): void {
            for (let d = 0; d < this.toDispose.length; d++) {
                if (typeof this.toDispose[d].dispose === "function") {
                    this.toDispose[d].dispose();
                }
            }
        }

        showMessage(msg:string = "please wait..."): void {
            $.blockUI({
                ignoreIfBlocked:true,
                baseZ: 10000,
                message: `<h2><img style="height:50px;width:50px;margin-right:50px;" src="${this.getBaseUrl()}images/loader.gif" />${msg}</h2>`
            });
        }

        clearMessage(): void {
            $.unblockUI();
        }

        showPage(page: string): void {
            if (ko.components.isRegistered(page) === false) {
                ko.components.register(page, {
                    template: {
                        element: "body-" + page
                    },
                    viewModel: PE.Nominal[page]
                });
            }
            ko.postbox.publish(KOTOPIC[KOTOPIC.PAGE], { name: page });
        }

        goHome(): void {
            this.showPage("Home");
        }

        getSession<T>(item:string): T {
            let pageJSON = sessionStorage.getItem(item);
            return JSON.parse(pageJSON);
        }

        hasAccess(name: string): boolean {
            if (!this.pages) {
                this.pages = this.getSession<PE.Nominal.IMenuItem[]>("MenuItems");
            }
            let match = this.pages.filter(function (pg) {
                return pg.VM === name;
            });
            if (match && match.length)
                return true;
            return false;
        }

        protected getBaseUrl(): string {
            if (typeof baseURL === "undefined") {
                baseURL = sessionStorage.getItem("rootURL");
                if (!baseURL) {
                    baseURL = "/";
                }
            }
            return baseURL;
        }


        /**
         * Handles Ajax Error
         * @param xhr the XMLHttpRequestObject
         * @param url the Requested URL
         * @param defaultMessage the default message to provide if server response is not well formatted
         * @param reject the reject method (from Promise)
         */
        private handleAjaxError(xhr: XMLHttpRequest, url: string, defaultMessage: string, reject: (error: any) => void): void {
            console.warn(defaultMessage, url);
            try {
                if (xhr.status == 400) {
                    alert(defaultMessage + "\n================\n" + xhr.response + "\n================");
                }
                else {
                    alert("Sorry, " + defaultMessage + ".  STATUS CODE: " + xhr.status);
                }
                this.clearMessage();
            } catch (e) {
                reject(e);
            }
        }

        /**
         * Builds a Formatted and Open XMLHttpRequest Object with Headers Set
         * @param method The HTTP Method to send
         * @param url the URL to Connect to
         */
        private buildJSONRequest(method: string, url: string, reject: (error: any) => void): XMLHttpRequest {


            let xhr = new XMLHttpRequest();
            xhr.timeout = 90000;
            xhr.addEventListener("abort", () => {
                $.unblockUI();
                this.handleAjaxError(xhr, url, "request aborted", reject);
            });
            xhr.addEventListener("error", () => {
                $.unblockUI();
                this.handleAjaxError(xhr, url, "request error", reject);
            });
            xhr.addEventListener("timeout", () => {
                $.unblockUI();
                this.handleAjaxError(xhr, url, "request timeout", reject);
            });
            if (url.indexOf("http") === -1) {
                xhr.open(method, this.getBaseUrl() + url);
            } else {
                xhr.open(method, url);
            }

            xhr.setRequestHeader("Accept", "application/json");
            xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
            xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
            return xhr;
        }

        /**
         * Builds a Formatted and Open XMLHttpRequest Object with Headers Set
         * @param method The HTTP Method to send
         * @param url the URL to Connect to
         */
        private buildFileRequest(method: string, url: string, reject: (reason: string) => void): XMLHttpRequest {
            let xhr = new XMLHttpRequest();
            xhr.addEventListener("abort", () => {
                console.warn("request aborted", url);
                reject("request aborted");
            });
            xhr.addEventListener("error", () => {
                console.error("request error", url);
                reject("request error");
            });
            xhr.addEventListener("timeout", () => {
                console.error("request timeout", url);
                reject("request timeout");
            });
            xhr.open(method, "/" + url);
            xhr.setRequestHeader("accept", "application/json");
            xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
            return xhr;
        }


        /**
         * Loads data using an HTTP GET via JSON
         * @param url the URL to Load
         */
        protected ajaxGet<T>(url: string): Promise<T> {
            return new Promise<T>((resolve, reject) => {
                let xhr = this.buildJSONRequest("GET", url, reject);
                xhr.addEventListener("load", () => {
                    if (xhr.status >= 200 && xhr.status < 300) {
                        if (xhr.responseText) {
                            let data = JSON.parse(xhr.responseText);
                            resolve(data);
                        } else {
                            resolve(undefined);
                        }
                    } else if (xhr.status === 400) {
                        $.unblockUI();
                        this.handleAjaxError(xhr, url, "bad request", reject);
                    } else {
                        $.unblockUI();
                        this.handleAjaxError(xhr, url, xhr.statusText + "(" + xhr.status.toString() + ")", reject);
                    }
                });
                xhr.send();
            });
        }

        /**
         * Loads data using an HTTP POST via JSON
         * @param url the URL to Load
         */
        protected ajaxSendReceive<T, D>(url: string, data: D): Promise<T> {
            return new Promise<T>((resolve, reject) => {
                let xhr = this.buildJSONRequest("POST", url, reject);
                xhr.addEventListener("load", () => {
                    if (xhr.status >= 200 && xhr.status < 300) {
                        let data = JSON.parse(xhr.responseText);
                        resolve(data);
                    } else if (xhr.status === 400) {
                        $.unblockUI();
                        this.handleAjaxError(xhr, url, "bad request", reject);
                    } else {
                        $.unblockUI();
                        this.handleAjaxError(xhr, url, xhr.statusText + "(" + xhr.status.toString() + ")", reject);
                    }
                });
                xhr.send(JSON.stringify(data));
            });
        }

        /**
         * Loads data using an HTTP POST via JSON
         * @param url the URL to Load
         */
        protected ajaxSendOnly<D>(url: string, data: D): Promise<{}> {
            return new Promise<{}>((resolve, reject) => {
                let xhr = this.buildJSONRequest("POST", url, reject);
                xhr.addEventListener("load", () => {
                    if (xhr.status >= 200 && xhr.status < 300) {
                        resolve();
                    } else if (xhr.status === 400) {
                        $.unblockUI();
                        this.handleAjaxError(xhr, url, "bad request", reject);
                    } else {
                        $.unblockUI();
                        this.handleAjaxError(xhr, url, xhr.statusText + "(" + xhr.status.toString() + ")", reject);
                    }
                });
                xhr.send(JSON.stringify(data));
            });
        }
    }

    /**
     * Root Page VM
     */
    export class PageVM extends BaseVM {
        bodyVM: KnockoutObservable<{ name: string, params?: any }>;
        constructor() {
            super();
            this.bodyVM = ko.observable(null).subscribeTo(KOTOPIC[KOTOPIC.PAGE]);
            this.goHome();
        }
    }
    
    /**
     * Home Component VM
     */
    export class Home extends BaseVM {
        extract: boolean;
        journal: boolean;
        mapping: boolean;
        posting: boolean;
        bankrec: boolean;
        mtd: boolean;
        expense: boolean;
        constructor() {
            console.info("Home");
            super();
            this.extract = this.hasAccess("IntegrationExtract");
            this.journal = this.hasAccess("PostCreate");
            this.mapping = this.hasAccess("MissingMap");
            this.posting = this.hasAccess("Journal");
            this.bankrec = this.hasAccess("BankRec");
            this.mtd = this.hasAccess("MTD");
            this.expense = this.hasAccess("ExpensePost");
        }
    }

    /**
     * Integration Extract VM
     */
    export class IntegrationExtract extends BaseVM {
        startDate: string;
        endDate: string;
        constructor() {
            console.info("IntegrationExtract");
            super(false);
            let datesData = this.getSession<PE.Nominal.ISelectedDates>("SelectedDates");
            this.startDate = moment(datesData.PracPeriodStart.substr(0, 10)).format("ddd MMM DD YYYY");
            this.endDate = moment(datesData.PracPeriodEnd.substr(0, 10)).format("ddd MMM DD YYYY");
            this.init();
        }

        async init(): Promise<void> {
            this.isReady(true);
        }

        async run(): Promise<void> {
            this.showMessage("Running Extract...");
            await this.ajaxSendOnly("api/Actions/IntegrationExtract", {});
            this.clearMessage();            
            alert("Integration Extract has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
            this.goHome();
        }
    }

    /**
     * Journal Create VM
     */
    export class PostCreate extends BaseVM {
        Periods: KnockoutObservableArray<PE.Nominal.IPostPeriods>;
        SelectedPeriod: KnockoutObservable<PE.Nominal.IPostPeriods>;
        startDate: KnockoutComputed<string>;
        endDate: KnockoutComputed<string>;

        constructor() {
            console.info("PostCreate");
            super(false);
            this.Periods = ko.observableArray([]);
            this.SelectedPeriod = ko.observable(null);
            this.startDate = ko.computed(() => {
                let period = this.SelectedPeriod();
                if (period) {
                    return moment(period.PeriodStartDate).format("ddd MMM DD YYYY");
                }
                return "";
            });
            this.endDate = ko.computed(() => {
                let period = this.SelectedPeriod();
                if (period) {
                    return moment(period.PeriodEndDate).format("ddd MMM DD YYYY");
                }
                return "";
            });
            this.toDispose.push(this.startDate, this.endDate);
            this.init();
        }

        async init(): Promise<void> {
            this.showMessage("Loading Periods...");
            let periods = await this.ajaxGet<PE.Nominal.IPostPeriods[]>("api/Actions/PostPeriods");
            this.Periods(periods);
            this.clearMessage();
            this.isReady(true);
        }

        async run(): Promise<void> {
            this.showMessage("Creating Journal...");
            await this.ajaxSendOnly<number>("api/Actions/PostPeriods", this.SelectedPeriod().NLPeriodIndex);
            this.clearMessage();
            alert("Posting Journal Created");
            this.goHome();
        }
    }

    const CLOSE_MAP_EDITOR = "CLOSEMAPEDITOR";
    /**
     * Missing Mappings VM
     */
    export class MissingMap extends BaseVM {
        editor: KnockoutObservable<MapEditor>;
        constructor() {
            console.info("MissingMap");
            super();
            this.editor = ko.observable(null);
            this.toDispose.push(ko.postbox.subscribe(CLOSE_MAP_EDITOR, () => {
                // Close the Editor
                this.editor(null);
                // Refresh the Data
                this.init(true);
            }));
            this.init();
        }

        async init(refresh: boolean = false): Promise<void> {
            this.showMessage("Loading Missing Mapping Details...");
            let data = await this.ajaxGet<PE.Nominal.IMissingMap[]>("api/Actions/MissingMap");
            if (refresh) {
                // Wipe out existing
                $("#gltable").DataTable().destroy();
                $("#gltable").empty();
            }
            let table = $("#gltable").DataTable({
                select: {
                    style: "single",
                    info: false
                },
                data: data.map(function (item) {
                    return [
                        item.OrgName,
                        item.NomSource,
                        item.NomSection,
                        item.NomAccount,
                        item.OfficeName,
                        item.ServiceName,
                        item.PartnerName,
                        item.DepartmentName,
                        item
                    ];
                }),
                columns: [
                    { title: "Organization" },
                    { title: "Source" },
                    { title: "Section" },
                    { title: "Account" },
                    { title: "Office" },
                    { title: "Service" },
                    { title: "Partner" },
                    { title: "Department" },
                    { name: "item", visible: false }
                ]
            });
            (<DataTables.SelectApi><any>table).on("select.dt", (e: JQueryEventObject, dt: DataTables.Api, type: string, indexes: Array<any>) => {
                // On Row Select
                let arrData = <Array<any>>table.row(indexes).data();
                let item = arrData[arrData.length - 1];
                this.editor(new MapEditor(item));
                });
            this.clearMessage();
        }
    }

    /**
     * Class for Editing a Mapping (Missing or Journal)
     */
    class MapEditor extends BaseVM {
        item: PE.Nominal.IMissingMap;
        acctTypes: KnockoutObservableArray<PE.Nominal.IGLType>;
        selectedType: KnockoutObservable<string>;
        accounts: KnockoutObservableArray<PE.Nominal.IGLAccount>;
        selectedAccount: KnockoutObservable<string>;
        constructor(item:PE.Nominal.IMissingMap) {
            super(false);
            this.item = item;
            this.acctTypes = ko.observableArray([]);
            this.selectedType = ko.observable(item.AccountTypeCode);
            this.accounts = ko.observableArray([]);
            this.selectedAccount = ko.observable(item.AccountCode);
            this.toDispose.push(this.selectedType.subscribe(async (acctType) => {
                if (this.item && this.item.NomOrg && acctType) {
                    this.showMessage("Loading Account List...");
                    let acctList = await this.ajaxGet<PE.Nominal.IGLAccount[]>("api/Actions/Accounts/" + this.item.NomOrg + "/" + acctType);
                    this.accounts(acctList);
                    this.clearMessage();
                } else {
                    this.accounts([]);
                }
            }));
            this.init();
        }

        async init(): Promise<void> {
            this.showMessage("Loading GL Information...");
            if (this.item.NomOrg) {
                let types = await this.ajaxGet<PE.Nominal.IGLType[]>("api/Actions/AccountTypes/" + this.item.NomOrg);
                this.acctTypes(types);
                if (this.item.AccountTypeCode) {
                    let acctList = await this.ajaxGet<PE.Nominal.IGLAccount[]>("api/Actions/Accounts/" + this.item.NomOrg + "/" + this.item.AccountTypeCode);
                    this.accounts(acctList);
                }
            }
            this.clearMessage();
            this.isReady(true);
        }

        async saveMapping(): Promise<void> {
            this.showMessage("Saving Mapping Details...");
            let toSave: PE.Nominal.IMapUpdate = {
                MapIndex: this.item.MapIndex,
                AccountTypeCode: this.selectedType() || "",
                AccountCode: this.selectedAccount() || ""
            };
            await this.ajaxSendOnly("api/Actions/UpdateMapping", toSave);
            this.clearMessage();
            ko.postbox.publish(CLOSE_MAP_EDITOR, {});
        }
    }

    /**
     * Export Account Mappings VM
     */
    export class NLMap extends BaseVM {
        editor: KnockoutObservable<MapEditor>;
        constructor() {
            console.info("NLMap");
            super();
            this.editor = ko.observable(null);
            this.toDispose.push(ko.postbox.subscribe(CLOSE_MAP_EDITOR, () => {
                // Close the Editor
                this.editor(null);
                // Refresh the Data
                this.init(true);
            }));
            this.init();
        }

        async init(refresh: boolean = false): Promise<void> {
            this.showMessage("Loading Export Mapping Details...");
            let data = await this.ajaxGet<PE.Nominal.IMissingMap[]>("api/Actions/NLMap");
            if (refresh) {
                // Wipe out existing
                $("#gltable").DataTable().destroy();
                $("#gltable").empty();
            }
            let table = $("#gltable").DataTable({
                select: {
                    style: "single",
                    info: false
                },
                data: data.map(function (item) {
                    return [
                        item.OrgName,
                        item.NomSource,
                        item.NomSection,
                        item.NomAccount,
                        item.OfficeName,
                        item.ServiceName,
                        item.PartnerName,
                        item.DepartmentName,
                        item
                    ];
                }),
                columns: [
                    { title: "Organization" },
                    { title: "Source" },
                    { title: "Section" },
                    { title: "Account" },
                    { title: "Office" },
                    { title: "Service" },
                    { title: "Partner" },
                    { title: "Department" },
                    { name: "item", visible: false }
                ]
            });
            (<DataTables.SelectApi><any>table).on("select.dt", (e: JQueryEventObject, dt: DataTables.Api, type: string, indexes: Array<any>) => {
                // On Row Select
                let arrData = <Array<any>>table.row(indexes).data();
                let item = arrData[arrData.length - 1];
                this.editor(new MapEditor(item));
            });
            this.clearMessage();
        }
    }

    interface GroupNode {
        group: Partial<PE.Nominal.IJournalGroup>;
        title: string;
        children: GroupNode[];
        filter: boolean;
        htmlSpace: string;
        expanded: KnockoutObservable<boolean>;
    }

    interface DetailNode {
        group: Partial<PE.Nominal.IDetailGroup>;
        title: string;
        children: GroupNode[];
        filter: boolean;
        htmlSpace: string;
        expanded: KnockoutObservable<boolean>;
    }


    /**
     * Class for Editing an Import Mapping
     */
    class ImportMapEditor extends BaseVM {
        item: PE.Nominal.IImportMap;
        disbCodes: KnockoutObservableArray<PE.Nominal.IDisbCode>;
        selectedDisb: KnockoutObservable<string>;
        constructor(item: PE.Nominal.IImportMap) {
            super(false);
            this.item = item;
            this.disbCodes = ko.observableArray([]);
            this.selectedDisb = ko.observable(item.DisbCode);
            this.init();
        }

        async init(): Promise<void> {
            this.showMessage("Loading GL Information...");
            let disbs = await this.ajaxGet<PE.Nominal.IDisbCode[]>("api/Actions/DisbCodes");
            this.disbCodes(disbs);
            this.clearMessage();
            this.isReady(true);
        }

        async saveMapping(): Promise<void> {
            this.showMessage("Saving Mapping Details...");
            let toSave: PE.Nominal.IImportMapUpdate = {
                DisbMapIndex: this.item.DisbMapIndex,
                DisbCode: this.selectedDisb() || ""
            };
            await this.ajaxSendOnly("api/Actions/UpdateImportMapping", toSave);
            this.clearMessage();
            ko.postbox.publish(CLOSE_MAP_EDITOR, {});
        }
    }

    /**
     * Import Account Mappings VM
     */
    export class DisbMap extends BaseVM {
        editor: KnockoutObservable<ImportMapEditor>;
        constructor() {
            console.info("NLImportMap");
            super();
            this.editor = ko.observable(null);
            this.toDispose.push(ko.postbox.subscribe(CLOSE_MAP_EDITOR, () => {
                // Close the Editor
                this.editor(null);
                // Refresh the Data
                this.init(true);
            }));
            this.init();
        }

        async init(refresh: boolean = false): Promise<void> {
            this.showMessage("Loading Import Mapping Details...");
            let data = await this.ajaxGet<PE.Nominal.IImportMap[]>("api/Actions/NLImportMap");
            if (refresh) {
                // Wipe out existing
                $("#gltable").DataTable().destroy();
                $("#gltable").empty();
            }
            let table = $("#gltable").DataTable({
                select: {
                    style: "single",
                    info: false
                },
                data: data.map(function (item) {
                    return [
                        item.OrgName,
                        item.NLAcc,
                        item.DisbName,
                        item
                    ];
                }),
                columns: [
                    { title: "Organisation" },
                    { title: "GL Account" },
                    { title: "Disbursement Code" },
                    { name: "item", visible: false }
                ]
            });
            (<DataTables.SelectApi><any>table).on("select.dt", (e: JQueryEventObject, dt: DataTables.Api, type: string, indexes: Array<any>) => {
                // On Row Select
                let arrData = <Array<any>>table.row(indexes).data();
                let item = arrData[arrData.length - 1];
                this.editor(new ImportMapEditor(item));
            });
            this.clearMessage();
        }
    }

    /**
     * Journal Posting VM
     */
    export class Journal extends BaseVM {
        children: KnockoutObservableArray<GroupNode>;
        selectedItem: KnockoutObservable<GroupNode>;
        editor: KnockoutObservable<MapEditor>;
        table: DataTables.Api;
        constructor() {
            console.info("Journal");
            super(false);
            this.children = ko.observableArray([]);
            this.selectedItem = ko.observable(undefined);
            this.editor = ko.observable(undefined);
            this.toDispose.push(this.selectedItem.subscribe((val) => {
                if (val && val.filter) {
                    this.loadItem(val);
                } else {
                    // Wipe out existing
                    if (this.table) {
                        // Wipe out existing
                        $("#gltable").DataTable().destroy();
                        $("#gltable").empty();
                        this.table = null;
                    }
                }
            }));
            this.toDispose.push(ko.postbox.subscribe(CLOSE_MAP_EDITOR, () => {
                // Close the Editor
                this.editor(null);
                // Refresh the Data
                this.selectedItem.valueHasMutated();
            }));
            this.init();
        }

        toggleItem(item: GroupNode): void {
            if (item) {
                item.expanded(!item.expanded());
            }
        }

        async loadItem(item: GroupNode): Promise<void> {
            this.showMessage("Loading Group...");
            let data = await this.ajaxSendReceive<PE.Nominal.IJournalMap[], Partial<PE.Nominal.IJournalGroup>>("api/Actions/JournalList", item.group);
            if (this.table) {
                // Wipe out existing
                $("#gltable").DataTable().destroy();
                $("#gltable").empty();
                this.table = null;
            }

            this.table = $("#gltable").DataTable({
                select: {
                    style: "single",
                    info: false
                },
                data: data.map(function (item) {
                    return [
                        item.NomDate,
                        item.NomAmount,
                        item.AccountCode,
                        item.NomOrg,
                        item.NomSource,
                        item.NomSection,
                        item.NomAccount,
                        item.NomOffice,
                        item.NomService,
                        item.NomPartner,
                        item.NomDept,
                        item
                    ];
                }),
                columns: [
                    {
                        title: "Date",
                        render: function (val) {
                            return moment(val).format("MMM DD YYYY");
                        }
                    },
                    {
                        title: "Amount",
                        className: "text-right",
                        render: function (num) {
                            num = isNaN(num) || num === '' || num === null ? 0.00 : num;
                            return "$ " + parseFloat(num).toFixed(2);
                        }
                    },
                    { title: "GL Account" },
                    { title: "Org" },
                    { title: "Source" },
                    { title: "Section" },
                    { title: "Account" },
                    { title: "Office" },
                    { title: "Service" },
                    { title: "Partner" },
                    { title: "Dept" },
                    { name: "item", visible: false }
                ]
            });
            (<DataTables.SelectApi><any>this.table).on("select.dt", (e, dt, type, indexes) => {
                // On Row Select
                let arrData = <Array<any>>this.table.row(indexes).data();
                let item = arrData[arrData.length - 1];
                this.editor(new MapEditor(item));
                });
            this.clearMessage();
        }


        async init(): Promise<void> {
            this.showMessage("Loading Group...");
            let allGroups = await this.ajaxGet<PE.Nominal.IJournalGroup[]>("api/Actions/JournalGroups");

            // Group by Org, Source, Section, [Account, Office, Service, Department, Partner] (selectable items in [])
            let groups: Array<{ unq: keyof PE.Nominal.IJournalGroup, name: keyof PE.Nominal.IJournalGroup, filter:boolean }> = [
                    { unq: "NomOrg", name: "OrgName", filter:false },
                    { unq: "NomSource", name: "NomSource", filter: false },
                    { unq: "NomSection", name: "NomSection", filter: false },
                    { unq: "NomAccount", name: "NomAccount", filter: true },
                    { unq: "NomOffice", name: "OfficeName", filter: true },
                    { unq: "NomService", name: "ServiceName", filter: true },
                    { unq: "NomDept", name: "DepartmentName", filter: true},
                    { unq: "NomPartner", name: "PartnerName", filter: true}
            ];

            // function to build partial item based on level
            function buildItem(from: PE.Nominal.IJournalGroup, level: number): Partial<PE.Nominal.IJournalGroup> {
                let x = {};
                for (let i = 0; i <= level; i++) {
                    let fld = groups[i].unq;
                    x[fld] = from[fld];
                }
                return x;
            }


            // function to recursively build groups
            function buildGroups(grps: PE.Nominal.IJournalGroup[], level: number = 0): GroupNode[] {
                let grpSettings = groups[level];
                let distValues = ko.utils.arrayGetDistinctValues(grps.map(function (g) {
                    return g[grpSettings.unq];
                }));
                return distValues.map(function (o) {
                    let matches = grps.filter(function (g) {
                        return g[grpSettings.unq] === o;
                    });
                    return {
                        filter: grpSettings.filter,
                        htmlSpace: "&nbsp;".repeat(level),
                        title: matches[0][grpSettings.name].toString(),
                        group: buildItem(matches[0], level),
                        children: (level + 1 < groups.length) ? buildGroups(matches, level + 1) : [],
                        expanded: ko.observable(false)
                    };
                });
            }
            // Call buildGroups to construct the nexted groups 
            this.children(buildGroups(allGroups));
            this.clearMessage();
            this.isReady(true);
        }

        report(): void {
            window.open(this.getBaseUrl() + "api/Reports/JournalReport");
        }

        export(): void {
            window.open(this.getBaseUrl() + "api/Actions/Journal.csv");
        }

        async transfer(): Promise<void> {
            this.showMessage("Submitting Journal...");
            await this.ajaxSendOnly("api/Actions/Transfer", {});
            this.clearMessage();
            alert("Transfer has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
            this.init();
        }

        async statHours(): Promise<void> {
            this.showMessage("Sending STATS Journal...");
            await this.ajaxSendOnly("api/Actions/StatHours", {});
            this.clearMessage();
            alert("Transfer has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
            this.init();
        }

        async flagTransfer(): Promise<void> {
            this.showMessage("Flagging Current Items as Transferred...");
            await this.ajaxSendOnly("api/Actions/FlagTransferred", {});
            this.clearMessage();
            this.init();
        }
    }

    /**
     * Integration Details VM
     */
    export class Integrationdetails extends BaseVM {
        Periods: KnockoutObservableArray<PE.Nominal.IPostPeriods>;
        SelectedPeriod: KnockoutObservable<PE.Nominal.IPostPeriods>;
        children: KnockoutObservableArray<DetailNode>;
        selectedItem: KnockoutObservable<DetailNode>;
        table: DataTables.Api;
        constructor() {
            console.info("Integrationdetails");
            super(false);
            this.Periods = ko.observableArray([]);
            this.SelectedPeriod = ko.observable(null);
            this.children = ko.observableArray([]);
            this.selectedItem = ko.observable(undefined);
            this.toDispose.push(this.selectedItem.subscribe((val) => {
                if (val && val.filter) {
                    val.group.NLPeriodIndex = this.SelectedPeriod().NLPeriodIndex;
                    this.loadItem(val);
                } else {
                    // Wipe out existing
                    if (this.table) {
                        // Wipe out existing
                        $("#gltable").DataTable().destroy();
                        $("#gltable").empty();
                        this.table = null;
                    }
                }
            }));
            this.toDispose.push(this.SelectedPeriod.subscribe(async (postPeriod) => {
                this.showMessage("Loading Group...");
                let allGroups = await this.ajaxGet<PE.Nominal.IDetailGroup[]>("api/Actions/DetailGroups/" + postPeriod.NLPeriodIndex.toString());

                // Group by Org, Source, Section, [Account, Office, Service, Department, Partner] (selectable items in [])
                let groups: Array<{ unq: keyof PE.Nominal.IDetailGroup, name: keyof PE.Nominal.IDetailGroup, filter: boolean }> = [
                    { unq: "NLOrg", name: "OrgName", filter: false },
                    { unq: "NLSource", name: "NLSource", filter: false },
                    { unq: "NLSection", name: "NLSection", filter: false },
                    { unq: "NLAccount", name: "NLAccount", filter: true },
                    { unq: "NLOffice", name: "OfficeName", filter: true },
                    { unq: "NLService", name: "ServiceName", filter: true },
                    { unq: "NLDept", name: "DepartmentName", filter: true },
                    { unq: "NLPartner", name: "PartnerName", filter: true }
                ];

                // function to build partial item based on level
                function buildItem(from: PE.Nominal.IDetailGroup, level: number): Partial<PE.Nominal.IDetailGroup> {
                    let x = {};
                    for (let i = 0; i <= level; i++) {
                        let fld = groups[i].unq;
                        x[fld] = from[fld];
                    }
                    return x;
                }


                // function to recursively build groups
                function buildGroups(grps: PE.Nominal.IDetailGroup[], level: number = 0): DetailNode[] {
                    let grpSettings = groups[level];
                    let distValues = ko.utils.arrayGetDistinctValues(grps.map(function (g) {
                        return g[grpSettings.unq];
                    }));
                    return distValues.map(function (o) {
                        let matches = grps.filter(function (g) {
                            return g[grpSettings.unq] === o;
                        });
                        return {
                            filter: grpSettings.filter,
                            htmlSpace: "&nbsp;".repeat(level),
                            title: matches[0][grpSettings.name].toString(),
                            group: buildItem(matches[0], level),
                            children: (level + 1 < groups.length) ? buildGroups(matches, level + 1) : [],
                            expanded: ko.observable(false)
                        };
                    });
                }
                // Call buildGroups to construct the nexted groups 
                this.children(buildGroups(allGroups));
                this.clearMessage();
            }));
            this.init();
        }

        toggleItem(item: DetailNode): void {
            if (item) {
                item.expanded(!item.expanded());
            }
        }

        async loadItem(item: DetailNode): Promise<void> {
            this.showMessage("Loading Group...");
            let data = await this.ajaxSendReceive<PE.Nominal.IDetailLine[], Partial<PE.Nominal.IDetailGroup>>("api/Actions/DetailList", item.group);
            if (this.table) {
                // Wipe out existing
                $("#gltable").DataTable().destroy();
                $("#gltable").empty();
                this.table = null;
            }

            this.table = $("#gltable").DataTable({
                select: {
                    style: "single",
                    info: false
                },
                data: data.map(function (item) {
                    return [
                        item.NLDate,
                        item.TransTypeDescription,
                        item.TransRefAlpha,
                        item.Amount,
                        item
                    ];
                }),
                columns: [
                    {
                        title: "Date",
                        render: function (val) {
                            return moment(val).format("MMM DD YYYY");
                        }
                    },
                    { title: "Description" },
                    { title: "Reference" },
                    {
                        title: "Amount",
                        className: "text-right",
                        render: function (num) {
                            num = isNaN(num) || num === '' || num === null ? 0.00 : num;
                            return "$ " + parseFloat(num).toFixed(2);
                        }
                    },
                    { name: "item", visible: false }
                ]
            });
            this.clearMessage();
        }

        async init(): Promise<void> {
            this.showMessage("Loading Periods...");
            let periods = await this.ajaxGet<PE.Nominal.IPostPeriods[]>("api/Actions/JournalPeriods");
            this.Periods(periods);
            this.clearMessage();
            this.isReady(true);

        }

        report(): void {
            window.open(this.getBaseUrl() + "api/Reports/JournalReport");
        }
    }

    /**
     * Journal RePosting VM
     */
    export class RepostJournal extends BaseVM {
        Periods: KnockoutObservableArray<PE.Nominal.IPostPeriods>;
        SelectedPeriod: KnockoutObservable<PE.Nominal.IPostPeriods>;
        startDate: KnockoutComputed<string>;
        endDate: KnockoutComputed<string>;
        table: DataTables.Api;
        constructor() {
            console.info("RepostJournal");
            super(false);
            this.Periods = ko.observableArray([]);
            this.SelectedPeriod = ko.observable(null);
            this.startDate = ko.computed(() => {
                let period = this.SelectedPeriod();
                if (period) {
                    return moment(period.PeriodStartDate).format("ddd MMM DD YYYY");
                }
                return "";
            });
            this.endDate = ko.computed(() => {
                let period = this.SelectedPeriod();
                if (period) {
                    return moment(period.PeriodEndDate).format("ddd MMM DD YYYY");
                }
                return "";
            });
            this.toDispose.push(this.startDate, this.endDate);
            this.toDispose.push(this.SelectedPeriod.subscribe(async (postPeriod) => {
                this.showMessage("Loading Available Journals for Reposting...");
                let data = await this.ajaxGet<PE.Nominal.IJournalRepostBatch[]>("api/Actions/JournalRepostList/" + postPeriod.NLPeriodIndex.toString());
                if (this.table) {
                    // Wipe out existing
                    $("#gltable").DataTable().destroy();
                    $("#gltable").empty();
                    this.table = null;
                }

                this.table = $("#gltable").DataTable({
                    select: {
                        style: "single",
                        info: false
                    },
                    searching: false,
                    paging: false,
                    data: data.map(function (item) {
                        return [
                            item.NomBatch,
                            item.NumLines,
                            item.Debits,
                            item.Credits,
                            item
                        ];
                    }),
                    columns: [
                        { title: "Batch No." },
                        { title: "Entries" },
                        {
                            title: "Debits",
                            className: "text-right",
                            render: function (num) {
                                num = isNaN(num) || num === '' || num === null ? 0.00 : num;
                                return "$ " + parseFloat(num).toFixed(2);
                            }
                        },
                        {
                            title: "Credits",
                            className: "text-right",
                            render: function (num) {
                                num = isNaN(num) || num === '' || num === null ? 0.00 : num;
                                return "$ " + parseFloat(num).toFixed(2);
                            }
                        },
                        { name: "item", visible: false }
                    ]
                });
                (<DataTables.SelectApi><any>this.table).on("select.dt", async (e, dt, type, indexes) => {
                    // On Row Select
                    let arrData = <Array<any>>this.table.row(indexes).data();
                    let data = arrData[arrData.length - 1];
                    console.log("repost", data);
                    if (confirm("Repost batch #" + data.NomBatch + "?")) {
                        this.showMessage("Reposting Journal...");
                        await this.ajaxSendOnly("api/Actions/RepostJournal/" + data.NomBatch.toString(), {});
                        this.clearMessage();
                    }
                });
                this.clearMessage();
            }));
            this.init();
        }

        async init(): Promise<void> {
            this.showMessage("Loading Periods...");
            let periods = await this.ajaxGet<PE.Nominal.IPostPeriods[]>("api/Actions/JournalPeriods");
            this.Periods(periods);
            this.clearMessage();
            this.isReady(true);
        }

    }

    /**
     * Journal RePrinting VM
     */
    export class ReprintJournal extends BaseVM {
        Periods: KnockoutObservableArray<PE.Nominal.IPostPeriods>;
        SelectedPeriod: KnockoutObservable<PE.Nominal.IPostPeriods>;
        startDate: KnockoutComputed<string>;
        endDate: KnockoutComputed<string>;
        table: DataTables.Api;
        constructor() {
            console.info("ReprintJournal");
            super(false);
            this.Periods = ko.observableArray([]);
            this.SelectedPeriod = ko.observable(null);
            this.startDate = ko.computed(() => {
                let period = this.SelectedPeriod();
                if (period) {
                    return moment(period.PeriodStartDate).format("ddd MMM DD YYYY");
                }
                return "";
            });
            this.endDate = ko.computed(() => {
                let period = this.SelectedPeriod();
                if (period) {
                    return moment(period.PeriodEndDate).format("ddd MMM DD YYYY");
                }
                return "";
            });
            this.toDispose.push(this.startDate, this.endDate);
            this.toDispose.push(this.SelectedPeriod.subscribe(async (postPeriod) => {
                if (postPeriod == undefined) {
                    return;
                }
                this.showMessage("Loading Available Journals for Reprinting...");
                let data = await this.ajaxGet<PE.Nominal.IJournalRepostBatch[]>("api/Actions/JournalRepostList/" + postPeriod.NLPeriodIndex.toString());
                if (this.table) {
                    // Wipe out existing
                    $("#gltable").DataTable().destroy();
                    $("#gltable").empty();
                    this.table = null;
                }

                this.table = $("#gltable").DataTable({
                    select: {
                        style: "single",
                        info: false
                    },
                    searching: false,
                    paging: false,
                    data: data.map(function (item) {
                        return [
                            item.NomBatch,
                            item.NumLines,
                            item.Debits,
                            item.Credits,
                            item
                        ];
                    }),
                    columns: [
                        { title: "Batch No." },
                        { title: "Entries" },
                        {
                            title: "Debits",
                            className: "text-right",
                            render: function (num) {
                                num = isNaN(num) || num === '' || num === null ? 0.00 : num;
                                return "$ " + parseFloat(num).toFixed(2);
                            }
                        },
                        {
                            title: "Credits",
                            className: "text-right",
                            render: function (num) {
                                num = isNaN(num) || num === '' || num === null ? 0.00 : num;
                                return "$ " + parseFloat(num).toFixed(2);
                            }
                        },
                        { name: "item", visible: false }
                    ]
                });
                (<DataTables.SelectApi><any>this.table).on("select.dt", async (e, dt, type, indexes) => {
                    // On Row Select
                    let arrData = <Array<any>>this.table.row(indexes).data();
                    let data = arrData[arrData.length - 1];
                    console.log("reprint", data);
                    if (confirm("Reprint batch #" + data.NomBatch + "?")) {
                        window.open(this.getBaseUrl() + `api/Reports/ReprintJournalReport?batch=${data.NomBatch}`);
                    }
                });
                this.clearMessage();
            }));
            this.init();
        }

        async init(): Promise<void> {
            this.showMessage("Loading Periods...");
            let periods = await this.ajaxGet<PE.Nominal.IPostPeriods[]>("api/Actions/JournalPeriods");
            this.Periods(periods);
            this.clearMessage();
            this.isReady(true);
        }

    }

    /**
     * Journal RePrinting Details VM
     */
    export class ReprintJournalDetails extends BaseVM {
        Periods: KnockoutObservableArray<PE.Nominal.IPostPeriods>;
        SelectedPeriod: KnockoutObservable<PE.Nominal.IPostPeriods>;
        Orgs: KnockoutObservableArray<PE.Nominal.INomOrganisation>;
        SelectedOrg: KnockoutObservable<PE.Nominal.INomOrganisation>;
        SelectedSource: KnockoutObservable<string>;
        startDate: KnockoutComputed<string>;
        endDate: KnockoutComputed<string>;
        table: DataTables.Api;
        constructor() {
            console.info("ReprintJournal");
            super(false);
            this.Periods = ko.observableArray([]);
            this.SelectedPeriod = ko.observable(null);
            this.Orgs = ko.observableArray([]);
            this.SelectedOrg = ko.observable(null);
            this.SelectedSource = ko.observable(null);
            this.startDate = ko.computed(() => {
                let period = this.SelectedPeriod();
                if (period) {
                    return moment(period.PeriodStartDate).format("ddd MMM DD YYYY");
                }
                return "";
            });
            this.endDate = ko.computed(() => {
                let period = this.SelectedPeriod();
                if (period) {
                    return moment(period.PeriodEndDate).format("ddd MMM DD YYYY");
                }
                return "";
            });
            this.toDispose.push(this.startDate, this.endDate);
            this.toDispose.push(this.SelectedPeriod.subscribe(async (postPeriod) => {
                if (postPeriod == undefined) {
                    return;
                }
                this.showMessage("Loading Available Journals for Reprinting...");
                let data = await this.ajaxGet<PE.Nominal.IJournalRepostBatch[]>("api/Actions/JournalRepostList/" + postPeriod.NLPeriodIndex.toString());
                if (this.table) {
                    // Wipe out existing
                    $("#gltable").DataTable().destroy();
                    $("#gltable").empty();
                    this.table = null;
                }

                this.table = $("#gltable").DataTable({
                    select: {
                        style: "single",
                        info: false
                    },
                    searching: false,
                    paging: false,
                    data: data.map(function (item) {
                        return [
                            item.NomBatch,
                            item.NumLines,
                            item.Debits,
                            item.Credits,
                            item
                        ];
                    }),
                    columns: [
                        { title: "Batch No." },
                        { title: "Entries" },
                        {
                            title: "Debits",
                            className: "text-right",
                            render: function (num) {
                                num = isNaN(num) || num === '' || num === null ? 0.00 : num;
                                return "$ " + parseFloat(num).toFixed(2);
                            }
                        },
                        {
                            title: "Credits",
                            className: "text-right",
                            render: function (num) {
                                num = isNaN(num) || num === '' || num === null ? 0.00 : num;
                                return "$ " + parseFloat(num).toFixed(2);
                            }
                        },
                        { name: "item", visible: false }
                    ]
                });
                (<DataTables.SelectApi><any>this.table).on("select.dt", async (e, dt, type, indexes) => {
                    // On Row Select
                    let arrData = <Array<any>>this.table.row(indexes).data();
                    let data = arrData[arrData.length - 1];
                    console.log("reprint", data);
                    if (confirm("Reprint batch #" + data.NomBatch + "?")) {
                        window.open(this.getBaseUrl() + `api/Reports/ReprintJournalDetails?batch=${data.NomBatch}&org=${this.SelectedOrg().PracID}&source=${this.SelectedSource()}`);
                    }
                });
                this.clearMessage();
            }));
            this.init();
        }

        async init(): Promise<void> {
            this.showMessage("Loading Periods and Orgs...");
            let periods = await this.ajaxGet<PE.Nominal.IPostPeriods[]>("api/Actions/JournalPeriods");
            this.Periods(periods);
            let orgs = await this.ajaxGet<PE.Nominal.INomOrganisation[]>("api/Actions/OrgList");
            this.Orgs(orgs);
            this.clearMessage();
            this.isReady(true);
        }

    }

    /**
     * Bank Reconciliation VM
     */
    export class BankRec extends BaseVM {
        startDate: string;
        endDate: string;
        constructor() {
            console.info("BankRec");
            super();
            let datesData = this.getSession<PE.Nominal.ISelectedDates>("SelectedDates");
            this.startDate = moment(datesData.PracPeriodStart.substr(0, 10)).format("ddd MMM DD YYYY");
            this.endDate = moment(datesData.PracPeriodEnd.substr(0, 10)).format("ddd MMM DD YYYY");
        }

        async run(): Promise<void> {
            this.showMessage("Submitting Bank Reconciliation...");
            await this.ajaxSendOnly("api/Actions/BankReconciliation", {});
            this.clearMessage();
            alert("Updated Bank Reconciliation successfully");
            this.goHome();
        }
    }

    /**
     * Update Costing VM
     */
    export class CostingUpdate extends BaseVM {
        startDate: string;
        endDate: string;
        constructor() {
            console.info("CostingUpdate");
            super();
            let datesData = this.getSession<PE.Nominal.ISelectedDates>("SelectedDates");
            this.startDate = moment(datesData.PracPeriodStart.substr(0, 10)).format("ddd MMM DD YYYY");
            this.endDate = moment(datesData.PracPeriodEnd.substr(0, 10)).format("ddd MMM DD YYYY");
        }

        async run(): Promise<void> {
            this.showMessage("Updating Costing Data...");
            await this.ajaxSendOnly("api/Actions/CostingUpdate", {});
            this.clearMessage();
            alert("Updated Costing Data successfully");
            this.goHome();
        }
    }
    /**
     * BankRec RePosting VM
     */
    export class BankRecPost extends BaseVM {
        Periods: KnockoutObservableArray<PE.Nominal.IPostPeriods>;
        SelectedPeriod: KnockoutObservable<PE.Nominal.IPostPeriods>;
        startDate: KnockoutComputed<string>;
        endDate: KnockoutComputed<string>;
        table: DataTables.Api;
        constructor() {
            console.info("BankRecPost");
            super(false);
            this.Periods = ko.observableArray([]);
            this.SelectedPeriod = ko.observable(null);
            this.startDate = ko.computed(() => {
                let period = this.SelectedPeriod();
                if (period) {
                    return moment(period.PeriodStartDate).format("ddd MMM DD YYYY");
                }
                return "";
            });
            this.endDate = ko.computed(() => {
                let period = this.SelectedPeriod();
                if (period) {
                    return moment(period.PeriodEndDate).format("ddd MMM DD YYYY");
                }
                return "";
            });
            this.toDispose.push(this.startDate, this.endDate);
            this.toDispose.push(this.SelectedPeriod.subscribe(async (postPeriod) => {
                this.showMessage("Loading Available Journals for Reposting...");
                let data = await this.ajaxGet<PE.Nominal.ICashbookRepostBatch[]>("api/Actions/BankRecRepostList/" + postPeriod.NLPeriodIndex.toString());
                if (this.table) {
                    // Wipe out existing
                    $("#gltable").DataTable().destroy();
                    $("#gltable").empty();
                    this.table = null;
                }

                this.table = $("#gltable").DataTable({
                    select: {
                        style: "single",
                        info: false
                    },
                    searching: false,
                    paging: false,
                    data: data.map(function (item) {
                        return [
                            item.LodgeBatch,
                            item.NumDep,
                            item.ValDep,
                            item
                        ];
                    }),
                    columns: [
                        { title: "Batch No." },
                        { title: "# Deposits" },
                        {
                            title: "Deposit Total",
                            className: "text-right",
                            render: function (num) {
                                num = isNaN(num) || num === '' || num === null ? 0.00 : num;
                                return "$ " + parseFloat(num).toFixed(2);
                            }
                        },
                        { name: "item", visible: false }
                    ]
                });
                (<DataTables.SelectApi><any>this.table).on("select.dt", async (e, dt, type, indexes) => {
                    // On Row Select
                    let arrData = <Array<any>>this.table.row(indexes).data();
                    let item = arrData[arrData.length - 1];
                    if (confirm("Repost batch #" + item.LodgeBatch + "?")) {
                        await this.ajaxSendOnly("api/Actions/RepostBankRec/" + item.LodgeBatch.toString(), {});
                    }
                });
                this.clearMessage();
            }));
            this.init();
        }

        async init(): Promise<void> {
            this.showMessage("Loading Periods...");
            let periods = await this.ajaxGet<PE.Nominal.IPostPeriods[]>("api/Actions/BankRecPeriods");
            this.Periods(periods);
            this.clearMessage();
            this.isReady(true);
        }
    }


    /**
     * Integration Setup VM
     */
    export class NominalControl extends BaseVM {
        wipOffice: KnockoutObservable<boolean>;
        wipService: KnockoutObservable<boolean>;
        wipPartner: KnockoutObservable<boolean>;
        wipDepartment: KnockoutObservable<boolean>;
        drsOffice: KnockoutObservable<boolean>;
        drsService: KnockoutObservable<boolean>;
        drsPartner: KnockoutObservable<boolean>;
        drsDepartment: KnockoutObservable<boolean>;

        wipLevel: KnockoutObservable<string>;
        drsLevel: KnockoutObservable<string>;
        disbDetail: KnockoutObservable<string>;
        stdDisbCode: KnockoutObservable<string>;
        feeSource: KnockoutObservable<string>;
        feeProfits: KnockoutObservable<string>;
        feePartner: KnockoutObservable<string>;

        glSystem: KnockoutObservable<string>;

        interCompany: KnockoutObservable<boolean>;
        cashbook: KnockoutObservable<boolean>;
        expenses: KnockoutObservable<boolean>;

        disbCodes: KnockoutObservableArray<PE.Nominal.IDisbCode>;

        constructor() {
            console.info("IntegrationSetup");
            super(false);
            this.wipOffice = ko.observable(false);
            this.wipService = ko.observable(false);
            this.wipPartner = ko.observable(false);
            this.wipDepartment = ko.observable(false);
            this.drsOffice = ko.observable(false);
            this.drsService = ko.observable(false);
            this.drsPartner = ko.observable(false);
            this.drsDepartment = ko.observable(false);
            this.wipLevel = ko.observable("");
            this.drsLevel = ko.observable("");
            this.disbDetail = ko.observable("");
            this.stdDisbCode = ko.observable("");
            this.feeSource = ko.observable("");
            this.feeProfits = ko.observable("");
            this.feePartner = ko.observable("");
            this.glSystem = ko.observable("");
            this.interCompany = ko.observable(false);
            this.cashbook = ko.observable(false);
            this.expenses = ko.observable(false);
            this.disbCodes = ko.observableArray([]);
            this.init();
        }

        async init(): Promise<void> {
            this.showMessage("Loading Nominal Control Details...");
            let codes = await this.ajaxGet<PE.Nominal.IDisbCode[]>("api/Actions/DisbCodes");
            this.disbCodes(codes);
            let data = await this.ajaxGet<PE.Nominal.IGLSetup>("api/Actions/NominalControl");
            this.wipOffice(data.WIPOffice !== 0);
            this.wipService(data.WIPServ !== 0);
            this.wipPartner(data.WIPPart !== 0);
            this.wipDepartment(data.WIPDept !== 0);
            this.drsOffice(data.DRSOffice !== 0);
            this.drsService(data.DRSServ !== 0);
            this.drsPartner(data.DRSPart !== 0);
            this.drsDepartment(data.DRSDept !== 0);
            this.wipLevel (data.WIPLevel.toString());
            this.drsLevel (data.DRSLevel.toString());
            this.disbDetail (data.DisbLevel.toString());
            this.stdDisbCode (data.DisbStd);
            this.feeSource (data.FeeSource.toString());
            this.feeProfits (data.FeeProfit.toString());
            this.feePartner (data.FeePart.toString());
            this.glSystem (data.IntSystem);
            this.interCompany (data.InterCo);
            this.cashbook (data.Cashbook);
            this.expenses(data.Expenses);
            this.clearMessage();
            this.isReady(true);
        }

        async save(): Promise<void> {
            this.showMessage("Saving Configuration...");
            let data: PE.Nominal.IGLSetup = {
                WIPOffice: this.wipOffice() ? 1 : 0,
                WIPServ: this.wipService() ? 1 : 0,
                WIPPart: this.wipPartner() ? 1 : 0,
                WIPDept: this.wipDepartment() ? 1 : 0,
                DRSOffice: this.drsOffice() ? 1 : 0,
                DRSServ: this.drsService() ? 1 : 0,
                DRSPart: this.drsPartner() ? 1 : 0,
                DRSDept: this.drsDepartment() ? 1 : 0,
                WIPLevel: parseInt(this.wipLevel()),
                DRSLevel: parseInt(this.drsLevel()),
                DisbLevel: parseInt(this.disbDetail()),
                DisbStd: this.stdDisbCode() || " ",
                FeeSource: this.feeSource(),
                FeeProfit: parseInt(this.feeProfits()),
                FeePart: parseInt(this.feePartner()),
                IntSystem: this.glSystem(),
                InterCo: this.interCompany(),
                Cashbook: this.cashbook(),
                Expenses: this.expenses()
            };
            await this.ajaxSendOnly<PE.Nominal.IGLSetup>("api/Actions/NominalControl", data);
            this.clearMessage();
            this.goHome();
        }

        async buildMap(): Promise<void> {
            this.showMessage("Building Mappings...");
            await this.ajaxGet("api/Actions/BuildMap");
            this.clearMessage();
            alert('Map was built');
        }

        async clearMap(): Promise<void> {
            this.showMessage("Clearing Mappings...");
            await this.ajaxGet("api/Actions/BuildMap");
            this.clearMessage();
            alert('Map was cleared');
        }
    }

    /**
     * Create Disbursements VM
     */
    export class NLImport extends BaseVM {
        startDate: string;
        endDate: string;
        constructor() {
            console.info("CreateDisb");
            super();
            let datesData = this.getSession<PE.Nominal.ISelectedDates>("SelectedDates");
            this.startDate = moment(datesData.PracPeriodStart.substr(0, 10)).format("ddd MMM DD YYYY");
            this.endDate = moment(datesData.PracPeriodEnd.substr(0, 10)).format("ddd MMM DD YYYY");
        }

        run(): void {
            console.log("do create disb batch");
            this.goHome();
        }
    }

    /**
     * Organizations VM
     */
    export class Organisations extends BaseVM {
        orgs: KnockoutObservableArray<PE.Nominal.INomOrganisation>;
        editOrg: KnockoutObservable<PE.Nominal.INomOrganisation>;
        server: KnockoutObservable<string>;
        database: KnockoutObservable<string>;
        transfer: KnockoutObservable<boolean>;

        constructor() {
            console.info("Organisations");
            super();
            this.orgs = ko.observableArray([]);
            this.editOrg = ko.observable(undefined);
            this.server = ko.observable("");
            this.database = ko.observable("");
            this.transfer = ko.observable(false);
            this.toDispose.push(this.editOrg.subscribe((toEdit) => {
                if (toEdit) {
                    this.server(toEdit.NLServer);
                    this.database(toEdit.NLDatabase);
                    this.transfer(toEdit.NLTransfer);
                }
            }));
            this.init();
        }

        async init(): Promise<void> {
            this.showMessage("Loading Orgs...");
            let data = await this.ajaxGet<PE.Nominal.INomOrganisation[]>("api/Actions/OrgList");
            this.orgs(data);
            this.clearMessage();
        }

        async updateOrg(): Promise<void> {
            this.showMessage("Saving Org...");
            let editing = this.editOrg();
            editing.NLServer = this.server();
            editing.NLDatabase = this.database();
            editing.NLTransfer = this.transfer();
            await this.ajaxSendOnly<PE.Nominal.INomOrganisation>("api/Actions/OrgUpdate", editing);
            this.editOrg(undefined);
            this.clearMessage();
        }
    }

    /**
     * Intacct Sync VM
     */
    export class IntacctSync extends BaseVM {
        onlyNew: KnockoutObservable<boolean>;

        constructor() {
            super();
            this.onlyNew = ko.observable(false);
        }

        async runCustomerSync(): Promise<void> {
            this.showMessage("Starting Sync...");
            let newQS = this.onlyNew() ? "?OnlyNew=True" : "";
            await this.ajaxSendOnly("api/IntacctSync/Customers" + newQS, {});
            alert("Customers Synchronization has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
            this.clearMessage();
        }

        async runProjectSync(): Promise<void> {
            this.showMessage("Starting Sync...");
            let newQS = this.onlyNew() ? "?OnlyNew=True" : "";
            await this.ajaxSendOnly("api/IntacctSync/Projects" + newQS, {});
            alert("Projects Synchronization has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
            this.clearMessage();
        }

        async runEmployeeSync(): Promise<void> {
            this.showMessage("Starting Sync...");
            let newQS = this.onlyNew() ? "?OnlyNew=True" : "";
            await this.ajaxSendOnly("api/IntacctSync/Employees" + newQS, {});
            alert("Employees Synchronization has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
            this.clearMessage();
        }

        async runSyncAll(): Promise<void> {
            this.showMessage("Starting Sync...");
            let newQS = this.onlyNew() ? "?OnlyNew=True" : "";
            await this.ajaxSendOnly("api/IntacctSync/SyncAll" + newQS, {});
            alert("Synchronization has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
            this.clearMessage();
        }
    }

    /**
     * MTD Sync VM
     */
    export class MTD extends BaseVM {
        startDate: string;
        endDate: string;
        constructor() {
            console.info("MTD");
            super(false);
            let datesData = this.getSession<PE.Nominal.ISelectedDates>("SelectedDates");
            this.startDate = moment(datesData.PracPeriodStart.substr(0, 10)).format("ddd MMM DD YYYY");
            this.endDate = moment(datesData.PracPeriodEnd.substr(0, 10)).format("ddd MMM DD YYYY");
            this.init();
        }

        async init(): Promise<void> {
            this.isReady(true);
        }

        async run(): Promise<void> {
            this.showMessage("Running MTD Sync...");
            await this.ajaxSendOnly("api/Actions/MTDSync", {});
            this.clearMessage();
            alert("Making Tax Digital Sync has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
            this.goHome();
        }
    }


    /**
     * Expense Posting VM
     */
    export class ExpensePost extends BaseVM {
        children: KnockoutObservableArray<GroupNode>;
        selectedItem: KnockoutObservable<GroupNode>;
        noMissingData: KnockoutObservable<boolean>;
        hasMissingStaff: KnockoutObservable<boolean>;
        hasMissingAccounts: KnockoutObservable<boolean>;
        table: DataTables.Api;
        constructor() {
            console.info("ExpensePost");
            super(false);
            this.children = ko.observableArray([]);
            this.selectedItem = ko.observable(undefined);
            this.noMissingData = ko.observable(false);
            this.hasMissingStaff = ko.observable(true);
            this.hasMissingAccounts = ko.observable(true);
            this.toDispose.push(this.selectedItem.subscribe((val) => {
                if (val && val.filter) {
                    this.loadItem(val);
                } else {
                    // Wipe out existing
                    if (this.table) {
                        // Wipe out existing
                        $("#gltable").DataTable().destroy();
                        $("#gltable").empty();
                        this.table = null;
                    }
                }
            }));
            this.init();
        }

        toggleItem(item: GroupNode): void {
            if (item) {
                item.expanded(!item.expanded());
            }
        }

        async loadItem(item: GroupNode): Promise<void> {
            this.showMessage("Loading Staff...");
            let data = await this.ajaxSendReceive<PE.Nominal.IExpenseLines[], Partial<PE.Nominal.IExpenseStaff>>("api/Actions/ExpenseLines", item.group);
            if (this.table) {
                // Wipe out existing
                $("#gltable").DataTable().destroy();
                $("#gltable").empty();
                this.table = null;
            }

            this.table = $("#gltable").DataTable({
                select: {
                    style: "single",
                    info: false
                },
                data: data.map(function (item) {
                    return [
                        item.ExpDate,
                        item.Amount,
                        item.PostAcc,
                        item.ExpOrg,
                        item.Description,
                        item
                    ];
                }),
                columns: [
                    {
                        title: "Date",
                        render: function (val) {
                            return moment(val).format("MMM DD YYYY");
                        }
                    },
                    {
                        title: "Amount",
                        className: "text-right",
                        render: function (num) {
                            num = isNaN(num) || num === '' || num === null ? 0.00 : num;
                            return "$ " + parseFloat(num).toFixed(2);
                        }
                    },
                    { title: "GL Account" },
                    { title: "Org" },
                    { title: "Description" },
                    { name: "item", visible: false }
                ]
            });
            this.clearMessage();
        }


        async init(): Promise<void> {
            this.showMessage("Loading Staff...");
            let allGroups = await this.ajaxGet<PE.Nominal.IExpenseStaff[]>("api/Actions/ExpenseStaff");

            // Group by Org, Staff] (selectable items in [])
            let groups: Array<{ unq: keyof PE.Nominal.IExpenseStaff, name: keyof PE.Nominal.IExpenseStaff, filter: boolean }> = [
                { unq: "StaffOrg", name: "OrgName", filter: false },
                { unq: "StaffIndex", name: "StaffName", filter: true }
            ];

            // function to build partial item based on level
            function buildItem(from: PE.Nominal.IExpenseStaff, level: number): Partial<PE.Nominal.IExpenseStaff> {
                let x = {};
                for (let i = 0; i <= level; i++) {
                    let fld = groups[i].unq;
                    x[fld] = from[fld];
                }
                return x;
            }


            // function to recursively build groups
            function buildGroups(grps: PE.Nominal.IExpenseStaff[], level: number = 0): GroupNode[] {
                let grpSettings = groups[level];
                let distValues = ko.utils.arrayGetDistinctValues(grps.map(function (g) {
                    return g[grpSettings.unq];
                }));
                return distValues.map(function (o) {
                    let matches = grps.filter(function (g) {
                        return g[grpSettings.unq] === o;
                    });
                    return {
                        filter: grpSettings.filter,
                        htmlSpace: "&nbsp;".repeat(level),
                        title: matches[0][grpSettings.name].toString(),
                        group: buildItem(matches[0], level),
                        children: (level + 1 < groups.length) ? buildGroups(matches, level + 1) : [],
                        expanded: ko.observable(false)
                    };
                });
            }
            // Call buildGroups to construct the nexted groups 
            this.children(buildGroups(allGroups));
            if (allGroups.length > 0) {
                this.hasMissingStaff(allGroups[0].BlankStaff > 0);
                this.hasMissingAccounts(allGroups[0].BlankAccounts > 0);
                this.noMissingData(!this.hasMissingStaff() && !this.hasMissingAccounts());
            }
            this.clearMessage();
            this.isReady(true);
        }

        async transfer(): Promise<void> {
            this.showMessage("Submitting Expenses...");
            await this.ajaxSendOnly("api/Actions/TransferExpenses", {});
            this.clearMessage();
            alert("Transfer has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
            this.init();
        }

        goToMappings(): void {
            this.showPage("MissingExpenseAccountMap");
        }

        goToStaff(): void {
            this.showPage("MissingExpenseStaff");
        }
    }

    const CLOSE_EXPMAP_EDITOR = "CLOSEEXPMAPEDITOR";
    /**
     * Missing Expense Account Mappings VM
     */
    export class MissingExpenseAccountMap extends BaseVM {
        editor: KnockoutObservable<ExpAccountMapEditor>;
        constructor() {
            console.info("MissingExpenseAccountMap");
            super();
            this.editor = ko.observable(null);
            this.toDispose.push(ko.postbox.subscribe(CLOSE_EXPMAP_EDITOR, () => {
                // Close the Editor
                this.editor(null);
                // Refresh the Data
                this.init(true);
            }));
            this.init();
        }

        async init(refresh: boolean = false): Promise<void> {
            this.showMessage("Loading Missing Mapping Details...");
            let data = await this.ajaxGet<PE.Nominal.IMissingExpenseAccountMap[]>("api/Actions/MissingExpenseAccountMap");
            if (refresh) {
                // Wipe out existing
                $("#gltable").DataTable().destroy();
                $("#gltable").empty();
            }
            let table = $("#gltable").DataTable({
                select: {
                    style: "single",
                    info: false
                },
                data: data.map(function (item) {
                    return [
                        item.PracName,
                        item.ChargeCode,
                        item.ChargeName,
                        item.ChargeExpAccount,
                        item.NonChargeExpAccount,
                        item
                    ];
                }),
                columns: [
                    { title: "Organisation" },
                    { title: "Expense Code" },
                    { title: "Expense Name" },
                    { title: "Chargeable Account" },
                    { title: "Non-Chargeable Account" },
                    { name: "item", visible: false }
                ]
            });
            (<DataTables.SelectApi><any>table).on("select.dt", (e: JQueryEventObject, dt: DataTables.Api, type: string, indexes: Array<any>) => {
                // On Row Select
                let arrData = <Array<any>>table.row(indexes).data();
                let item = arrData[arrData.length - 1];
                this.editor(new ExpAccountMapEditor(item));
            });
            this.clearMessage();
        }

        goToExpenses(): void {
            this.showPage("ExpensePost");
        }
    }

    /**
     * Class for Editing a Expense Account Mapping
     */
    class ExpAccountMapEditor extends BaseVM {
        item: PE.Nominal.IMissingExpenseAccountMap;
        chargeCode: KnockoutObservable<string>;
        nonchargeCode: KnockoutObservable<string>;
        chargeSuffix1: KnockoutObservable<number>;
        chargeSuffix2: KnockoutObservable<number>;
        chargeSuffix3: KnockoutObservable<number>;
        nonChargeSuffix1: KnockoutObservable<number>;
        nonChargeSuffix2: KnockoutObservable<number>;
        nonChargeSuffix3: KnockoutObservable<number>;
        constructor(item: PE.Nominal.IMissingExpenseAccountMap) {
            super(false);
            this.item = item;
            this.chargeCode = ko.observable(item.ChargeExpAccount);
            this.nonchargeCode = ko.observable(item.NonChargeExpAccount);
            this.chargeSuffix1 = ko.observable(item.ChargeSuffix1);
            this.chargeSuffix2 = ko.observable(item.ChargeSuffix2);
            this.chargeSuffix3 = ko.observable(item.ChargeSuffix3);
            this.nonChargeSuffix1 = ko.observable(item.NonChargeSuffix1);
            this.nonChargeSuffix2 = ko.observable(item.NonChargeSuffix2);
            this.nonChargeSuffix3 = ko.observable(item.NonChargeSuffix3);
            this.init();
        }

        async init(): Promise<void> {
            this.showMessage("Loading GL Information...");
            this.clearMessage();
            this.isReady(true);
        }

        async saveMapping(): Promise<void> {
            this.showMessage("Saving Mapping Details...");
            let toSave: PE.Nominal.IMissingExpenseAccountMap = this.item;
            toSave.ChargeExpAccount = this.chargeCode();
            toSave.ChargeSuffix1 = this.chargeSuffix1();
            toSave.ChargeSuffix2 = this.chargeSuffix2();
            toSave.ChargeSuffix3 = this.chargeSuffix3();
            toSave.NonChargeExpAccount = this.nonchargeCode();
            toSave.NonChargeSuffix1 = this.nonChargeSuffix1();
            toSave.NonChargeSuffix2 = this.nonChargeSuffix2();
            toSave.NonChargeSuffix3 = this.nonChargeSuffix3();
            await this.ajaxSendOnly("api/Actions/UpdateExpenseAccountMapping", toSave);
            this.clearMessage();
            ko.postbox.publish(CLOSE_EXPMAP_EDITOR, {});
        }
    }
    /**
  * Missing Expense Staff VM
  */
    export class MissingExpenseStaff extends BaseVM {
        constructor() {
            console.info("MissingExpenseStaff");
            super();
            this.init();
        }

        async init(refresh: boolean = false): Promise<void> {
            this.showMessage("Loading Missing Staff Details...");
            let data = await this.ajaxGet<PE.Nominal.IMissingExpenseStaff[]>("api/Actions/MissingExpenseStaff");
            if (refresh) {
                // Wipe out existing
                $("#gltable").DataTable().destroy();
                $("#gltable").empty();
            }
            let table = $("#gltable").DataTable({
                select: {
                    style: "single",
                    info: false
                },
                data: data.map(function (item) {
                    return [
                        item.StaffIndex,
                        item.StaffCode,
                        item.StaffName,
                        item
                    ];
                }),
                columns: [
                    { title: "Staff ID" },
                    { title: "Staff Reference" },
                    { title: "Staff Name" },
                    { name: "item", visible: false }
                ]
            });
            this.clearMessage();
        }

        goToExpenses(): void {
            this.showPage("ExpensePost");
        }
    }
    /**
     * Missing Expense Account Mappings VM
     */
    export class ExpMap extends BaseVM {
        editor: KnockoutObservable<ExpAccountMapEditor>;
        constructor() {
            console.info("ExpMap");
            super();
            this.editor = ko.observable(null);
            this.toDispose.push(ko.postbox.subscribe(CLOSE_EXPMAP_EDITOR, () => {
                // Close the Editor
                this.editor(null);
                // Refresh the Data
                this.init(true);
            }));
            this.init();
        }

        async init(refresh: boolean = false): Promise<void> {
            this.showMessage("Loading Expense Code Mapping Details...");
            let data = await this.ajaxGet<PE.Nominal.IMissingExpenseAccountMap[]>("api/Actions/ExpenseAccountMap");
            if (refresh) {
                // Wipe out existing
                $("#gltable").DataTable().destroy();
                $("#gltable").empty();
            }
            let table = $("#gltable").DataTable({
                select: {
                    style: "single",
                    info: false
                },
                data: data.map(function (item) {
                    return [
                        item.PracName,
                        item.ChargeCode,
                        item.ChargeName,
                        item.ChargeExpAccount,
                        item.NonChargeExpAccount,
                        item
                    ];
                }),
                columns: [
                    { title: "Organisation" },
                    { title: "Expense Code" },
                    { title: "Expense Name" },
                    { title: "Chargeable Account" },
                    { title: "Non-Chargeable Account" },
                    { name: "item", visible: false }
                ]
            });
            (<DataTables.SelectApi><any>table).on("select.dt", (e: JQueryEventObject, dt: DataTables.Api, type: string, indexes: Array<any>) => {
                // On Row Select
                let arrData = <Array<any>>table.row(indexes).data();
                let item = arrData[arrData.length - 1];
                this.editor(new ExpAccountMapEditor(item));
            });
            this.clearMessage();
        }
    }
}

// Knockout Binding Handlers
ko.bindingHandlers.bsmodal = {
    update: function (element, valueAccessor, allBindings, viewModel, bindingContext) {
        let value = valueAccessor();
        let _value = ko.unwrap(value);
        if (_value) {
            $(element).modal("show");
            $(element).on("hidden.bs.modal", function () {
                if (typeof _value.dispose === "function") {
                    _value.dispose();
                }
                if (ko.isWriteableObservable(value)) {
                    value(null);
                }
            });
        } else {
            $(element).modal("hide");
        }
    }
};

// Wait for everything to load then start Binding
$(document).ready(function () {
    ko.applyBindings(new PE.Nominal.PageVM());
});