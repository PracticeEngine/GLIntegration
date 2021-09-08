var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
        return extendStatics(d, b);
    }
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var PE;
(function (PE) {
    var Nominal;
    (function (Nominal) {
        var KOTOPIC;
        (function (KOTOPIC) {
            KOTOPIC[KOTOPIC["PAGE"] = 0] = "PAGE";
        })(KOTOPIC || (KOTOPIC = {}));
        ;
        var baseURL;
        var BaseVM = (function () {
            function BaseVM(isReady) {
                if (isReady === void 0) { isReady = true; }
                this.isReady = ko.observable(isReady);
                this.toDispose = [];
            }
            BaseVM.prototype.dispose = function () {
                for (var d = 0; d < this.toDispose.length; d++) {
                    if (typeof this.toDispose[d].dispose === "function") {
                        this.toDispose[d].dispose();
                    }
                }
            };
            BaseVM.prototype.showMessage = function (msg) {
                if (msg === void 0) { msg = "please wait..."; }
                $.blockUI({
                    ignoreIfBlocked: true,
                    baseZ: 10000,
                    message: "<h2><img style=\"height:50px;width:50px;margin-right:50px;\" src=\"" + this.getBaseUrl() + "images/loader.gif\" />" + msg + "</h2>"
                });
            };
            BaseVM.prototype.clearMessage = function () {
                $.unblockUI();
            };
            BaseVM.prototype.showPage = function (page) {
                if (ko.components.isRegistered(page) === false) {
                    ko.components.register(page, {
                        template: {
                            element: "body-" + page
                        },
                        viewModel: PE.Nominal[page]
                    });
                }
                ko.postbox.publish(KOTOPIC[KOTOPIC.PAGE], { name: page });
            };
            BaseVM.prototype.goHome = function () {
                this.showPage("Home");
            };
            BaseVM.prototype.getSession = function (item) {
                var pageJSON = sessionStorage.getItem(item);
                return JSON.parse(pageJSON);
            };
            BaseVM.prototype.hasAccess = function (name) {
                if (!this.pages) {
                    this.pages = this.getSession("MenuItems");
                }
                var match = this.pages.filter(function (pg) {
                    return pg.VM === name;
                });
                if (match && match.length)
                    return true;
                return false;
            };
            BaseVM.prototype.getBaseUrl = function () {
                if (typeof baseURL === "undefined") {
                    baseURL = sessionStorage.getItem("rootURL");
                    if (!baseURL) {
                        baseURL = "/";
                    }
                }
                return baseURL;
            };
            BaseVM.prototype.handleAjaxError = function (xhr, url, defaultMessage, reject) {
                console.warn(defaultMessage, url);
                try {
                    if (xhr.status == 400) {
                        alert(defaultMessage + "\n================\n" + xhr.response + "\n================");
                    }
                    else {
                        alert("Sorry, " + defaultMessage + ".  STATUS CODE: " + xhr.status);
                    }
                    this.clearMessage();
                }
                catch (e) {
                    reject(e);
                }
            };
            BaseVM.prototype.buildJSONRequest = function (method, url, reject) {
                var _this = this;
                var xhr = new XMLHttpRequest();
                xhr.timeout = 90000;
                xhr.addEventListener("abort", function () {
                    $.unblockUI();
                    _this.handleAjaxError(xhr, url, "request aborted", reject);
                });
                xhr.addEventListener("error", function () {
                    $.unblockUI();
                    _this.handleAjaxError(xhr, url, "request error", reject);
                });
                xhr.addEventListener("timeout", function () {
                    $.unblockUI();
                    _this.handleAjaxError(xhr, url, "request timeout", reject);
                });
                if (url.indexOf("http") === -1) {
                    xhr.open(method, this.getBaseUrl() + url);
                }
                else {
                    xhr.open(method, url);
                }
                xhr.setRequestHeader("Accept", "application/json");
                xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
                xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
                return xhr;
            };
            BaseVM.prototype.buildFileRequest = function (method, url, reject) {
                var xhr = new XMLHttpRequest();
                xhr.addEventListener("abort", function () {
                    console.warn("request aborted", url);
                    reject("request aborted");
                });
                xhr.addEventListener("error", function () {
                    console.error("request error", url);
                    reject("request error");
                });
                xhr.addEventListener("timeout", function () {
                    console.error("request timeout", url);
                    reject("request timeout");
                });
                xhr.open(method, "/" + url);
                xhr.setRequestHeader("accept", "application/json");
                xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
                return xhr;
            };
            BaseVM.prototype.ajaxGet = function (url) {
                var _this = this;
                return new Promise(function (resolve, reject) {
                    var xhr = _this.buildJSONRequest("GET", url, reject);
                    xhr.addEventListener("load", function () {
                        if (xhr.status >= 200 && xhr.status < 300) {
                            if (xhr.responseText) {
                                var data = JSON.parse(xhr.responseText);
                                resolve(data);
                            }
                            else {
                                resolve(undefined);
                            }
                        }
                        else if (xhr.status === 400) {
                            $.unblockUI();
                            _this.handleAjaxError(xhr, url, "bad request", reject);
                        }
                        else {
                            $.unblockUI();
                            _this.handleAjaxError(xhr, url, xhr.statusText + "(" + xhr.status.toString() + ")", reject);
                        }
                    });
                    xhr.send();
                });
            };
            BaseVM.prototype.ajaxSendReceive = function (url, data) {
                var _this = this;
                return new Promise(function (resolve, reject) {
                    var xhr = _this.buildJSONRequest("POST", url, reject);
                    xhr.addEventListener("load", function () {
                        if (xhr.status >= 200 && xhr.status < 300) {
                            var data_1 = JSON.parse(xhr.responseText);
                            resolve(data_1);
                        }
                        else if (xhr.status === 400) {
                            $.unblockUI();
                            _this.handleAjaxError(xhr, url, "bad request", reject);
                        }
                        else {
                            $.unblockUI();
                            _this.handleAjaxError(xhr, url, xhr.statusText + "(" + xhr.status.toString() + ")", reject);
                        }
                    });
                    xhr.send(JSON.stringify(data));
                });
            };
            BaseVM.prototype.ajaxSendOnly = function (url, data) {
                var _this = this;
                return new Promise(function (resolve, reject) {
                    var xhr = _this.buildJSONRequest("POST", url, reject);
                    xhr.addEventListener("load", function () {
                        if (xhr.status >= 200 && xhr.status < 300) {
                            resolve();
                        }
                        else if (xhr.status === 400) {
                            $.unblockUI();
                            _this.handleAjaxError(xhr, url, "bad request", reject);
                        }
                        else {
                            $.unblockUI();
                            _this.handleAjaxError(xhr, url, xhr.statusText + "(" + xhr.status.toString() + ")", reject);
                        }
                    });
                    xhr.send(JSON.stringify(data));
                });
            };
            return BaseVM;
        }());
        Nominal.BaseVM = BaseVM;
        var PageVM = (function (_super) {
            __extends(PageVM, _super);
            function PageVM() {
                var _this = _super.call(this) || this;
                _this.bodyVM = ko.observable(null).subscribeTo(KOTOPIC[KOTOPIC.PAGE]);
                _this.goHome();
                return _this;
            }
            return PageVM;
        }(BaseVM));
        Nominal.PageVM = PageVM;
        var Home = (function (_super) {
            __extends(Home, _super);
            function Home() {
                var _this = this;
                console.info("Home");
                _this = _super.call(this) || this;
                _this.extract = _this.hasAccess("IntegrationExtract");
                _this.journal = _this.hasAccess("PostCreate");
                _this.mapping = _this.hasAccess("MissingMap");
                _this.posting = _this.hasAccess("Journal");
                _this.bankrec = _this.hasAccess("BankRec");
                _this.mtd = _this.hasAccess("MTD");
                _this.expense = _this.hasAccess("ExpensePost");
                _this.disbimp = _this.hasAccess("NLImport");
                _this.costing = _this.hasAccess("CostingUpdate");
                return _this;
            }
            return Home;
        }(BaseVM));
        Nominal.Home = Home;
        var IntegrationExtract = (function (_super) {
            __extends(IntegrationExtract, _super);
            function IntegrationExtract() {
                var _this = this;
                console.info("IntegrationExtract");
                _this = _super.call(this, false) || this;
                var datesData = _this.getSession("SelectedDates");
                _this.startDate = moment(datesData.PracPeriodStart.substr(0, 10)).format("ddd MMM DD YYYY");
                _this.endDate = moment(datesData.PracPeriodEnd.substr(0, 10)).format("ddd MMM DD YYYY");
                _this.init();
                return _this;
            }
            IntegrationExtract.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        this.isReady(true);
                        return [2];
                    });
                });
            };
            IntegrationExtract.prototype.run = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Running Extract...");
                                return [4, this.ajaxSendOnly("api/Actions/IntegrationExtract", {})];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                alert("Integration Extract has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
                                this.goHome();
                                return [2];
                        }
                    });
                });
            };
            return IntegrationExtract;
        }(BaseVM));
        Nominal.IntegrationExtract = IntegrationExtract;
        var PostCreate = (function (_super) {
            __extends(PostCreate, _super);
            function PostCreate() {
                var _this = this;
                console.info("PostCreate");
                _this = _super.call(this, false) || this;
                _this.Periods = ko.observableArray([]);
                _this.SelectedPeriod = ko.observable(null);
                _this.startDate = ko.computed(function () {
                    var period = _this.SelectedPeriod();
                    if (period) {
                        return moment(period.PeriodStartDate).format("ddd MMM DD YYYY");
                    }
                    return "";
                });
                _this.endDate = ko.computed(function () {
                    var period = _this.SelectedPeriod();
                    if (period) {
                        return moment(period.PeriodEndDate).format("ddd MMM DD YYYY");
                    }
                    return "";
                });
                _this.toDispose.push(_this.startDate, _this.endDate);
                _this.init();
                return _this;
            }
            PostCreate.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var periods;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Periods...");
                                return [4, this.ajaxGet("api/Actions/PostPeriods")];
                            case 1:
                                periods = _a.sent();
                                this.Periods(periods);
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            PostCreate.prototype.run = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Creating Journal...");
                                return [4, this.ajaxSendOnly("api/Actions/PostPeriods", this.SelectedPeriod().NLPeriodIndex)];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                alert("Posting Journal Created");
                                this.goHome();
                                return [2];
                        }
                    });
                });
            };
            return PostCreate;
        }(BaseVM));
        Nominal.PostCreate = PostCreate;
        var CLOSE_MAP_EDITOR = "CLOSEMAPEDITOR";
        var MissingMap = (function (_super) {
            __extends(MissingMap, _super);
            function MissingMap() {
                var _this = this;
                console.info("MissingMap");
                _this = _super.call(this) || this;
                _this.editor = ko.observable(null);
                _this.toDispose.push(ko.postbox.subscribe(CLOSE_MAP_EDITOR, function () {
                    _this.editor(null);
                    _this.init(true);
                }));
                _this.init();
                return _this;
            }
            MissingMap.prototype.init = function (refresh) {
                if (refresh === void 0) { refresh = false; }
                return __awaiter(this, void 0, void 0, function () {
                    var data, table;
                    var _this = this;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Missing Mapping Details...");
                                return [4, this.ajaxGet("api/Actions/MissingMap")];
                            case 1:
                                data = _a.sent();
                                if (refresh) {
                                    $("#gltable").DataTable().destroy();
                                    $("#gltable").empty();
                                }
                                table = $("#gltable").DataTable({
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
                                table.on("select.dt", function (e, dt, type, indexes) {
                                    var arrData = table.row(indexes).data();
                                    var item = arrData[arrData.length - 1];
                                    _this.editor(new MapEditor(item));
                                });
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            return MissingMap;
        }(BaseVM));
        Nominal.MissingMap = MissingMap;
        var ExportMapEditor = (function (_super) {
            __extends(ExportMapEditor, _super);
            function ExportMapEditor(item) {
                var _this = _super.call(this, false) || this;
                _this.item = item;
                _this.acctTypes = ko.observableArray([]);
                _this.selectedType = ko.observable(item.AccountTypeCode);
                _this.accounts = ko.observableArray([]);
                _this.selectedAccount = ko.observable(item.AccountCode);
                _this.toDispose.push(_this.selectedType.subscribe(function (acctType) { return __awaiter(_this, void 0, void 0, function () {
                    var acctList;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                if (!(this.item && this.item.MapOrg && acctType)) return [3, 2];
                                this.showMessage("Loading Account List...");
                                return [4, this.ajaxGet("api/Actions/Accounts/" + this.item.MapOrg + "/" + acctType)];
                            case 1:
                                acctList = _a.sent();
                                this.accounts(acctList);
                                this.clearMessage();
                                return [3, 3];
                            case 2:
                                this.accounts([]);
                                _a.label = 3;
                            case 3: return [2];
                        }
                    });
                }); }));
                _this.init();
                return _this;
            }
            ExportMapEditor.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var types, acctList;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading GL Information...");
                                if (!this.item.MapOrg) return [3, 3];
                                return [4, this.ajaxGet("api/Actions/AccountTypes/" + this.item.MapOrg)];
                            case 1:
                                types = _a.sent();
                                this.acctTypes(types);
                                if (!this.item.AccountTypeCode) return [3, 3];
                                return [4, this.ajaxGet("api/Actions/Accounts/" + this.item.MapOrg + "/" + this.item.AccountTypeCode)];
                            case 2:
                                acctList = _a.sent();
                                this.accounts(acctList);
                                _a.label = 3;
                            case 3:
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            ExportMapEditor.prototype.saveMapping = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var toSave;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Saving Mapping Details...");
                                toSave = {
                                    MapIndex: this.item.MapIndex,
                                    AccountTypeCode: this.selectedType() || "",
                                    AccountCode: this.selectedAccount() || ""
                                };
                                return [4, this.ajaxSendOnly("api/Actions/UpdateMapping", toSave)];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                ko.postbox.publish(CLOSE_MAP_EDITOR, {});
                                return [2];
                        }
                    });
                });
            };
            return ExportMapEditor;
        }(BaseVM));
        var MapEditor = (function (_super) {
            __extends(MapEditor, _super);
            function MapEditor(item) {
                var _this = _super.call(this, false) || this;
                _this.item = item;
                _this.acctTypes = ko.observableArray([]);
                _this.selectedType = ko.observable(item.AccountTypeCode);
                _this.accounts = ko.observableArray([]);
                _this.selectedAccount = ko.observable(item.AccountCode);
                _this.toDispose.push(_this.selectedType.subscribe(function (acctType) { return __awaiter(_this, void 0, void 0, function () {
                    var acctList;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                if (!(this.item && this.item.NomOrg && acctType)) return [3, 2];
                                this.showMessage("Loading Account List...");
                                return [4, this.ajaxGet("api/Actions/Accounts/" + this.item.NomOrg + "/" + acctType)];
                            case 1:
                                acctList = _a.sent();
                                this.accounts(acctList);
                                this.clearMessage();
                                return [3, 3];
                            case 2:
                                this.accounts([]);
                                _a.label = 3;
                            case 3: return [2];
                        }
                    });
                }); }));
                _this.init();
                return _this;
            }
            MapEditor.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var types, acctList;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading GL Information...");
                                if (!this.item.NomOrg) return [3, 3];
                                return [4, this.ajaxGet("api/Actions/AccountTypes/" + this.item.NomOrg)];
                            case 1:
                                types = _a.sent();
                                this.acctTypes(types);
                                if (!this.item.AccountTypeCode) return [3, 3];
                                return [4, this.ajaxGet("api/Actions/Accounts/" + this.item.NomOrg + "/" + this.item.AccountTypeCode)];
                            case 2:
                                acctList = _a.sent();
                                this.accounts(acctList);
                                _a.label = 3;
                            case 3:
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            MapEditor.prototype.saveMapping = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var toSave;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Saving Mapping Details...");
                                toSave = {
                                    MapIndex: this.item.MapIndex,
                                    AccountTypeCode: this.selectedType() || "",
                                    AccountCode: this.selectedAccount() || ""
                                };
                                return [4, this.ajaxSendOnly("api/Actions/UpdateMapping", toSave)];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                ko.postbox.publish(CLOSE_MAP_EDITOR, {});
                                return [2];
                        }
                    });
                });
            };
            return MapEditor;
        }(BaseVM));
        var NLMap = (function (_super) {
            __extends(NLMap, _super);
            function NLMap() {
                var _this = this;
                console.info("NLMap");
                _this = _super.call(this) || this;
                _this.editor = ko.observable(null);
                _this.toDispose.push(ko.postbox.subscribe(CLOSE_MAP_EDITOR, function () {
                    _this.editor(null);
                    _this.init(true);
                }));
                _this.init();
                return _this;
            }
            NLMap.prototype.init = function (refresh) {
                if (refresh === void 0) { refresh = false; }
                return __awaiter(this, void 0, void 0, function () {
                    var data, table;
                    var _this = this;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Export Mapping Details...");
                                return [4, this.ajaxGet("api/Actions/NLMap")];
                            case 1:
                                data = _a.sent();
                                if (refresh) {
                                    $("#gltable").DataTable().destroy();
                                    $("#gltable").empty();
                                }
                                table = $("#gltable").DataTable({
                                    select: {
                                        style: "single",
                                        info: false
                                    },
                                    data: data.map(function (item) {
                                        return [
                                            item.OrgName,
                                            item.MapSource,
                                            item.MapSection,
                                            item.MapAccount,
                                            item.OfficeName,
                                            item.ServiceName,
                                            item.PartnerName,
                                            item.DepartmentName,
                                            item.AccountCode,
                                            item
                                        ];
                                    }),
                                    columns: [
                                        { title: "Organisation" },
                                        { title: "Source" },
                                        { title: "Section" },
                                        { title: "Account" },
                                        { title: "Office" },
                                        { title: "Service" },
                                        { title: "Partner" },
                                        { title: "Department" },
                                        { title: "Account Code" },
                                        { name: "item", visible: false }
                                    ]
                                });
                                table.on("select.dt", function (e, dt, type, indexes) {
                                    var arrData = table.row(indexes).data();
                                    var item = arrData[arrData.length - 1];
                                    _this.editor(new ExportMapEditor(item));
                                });
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            return NLMap;
        }(BaseVM));
        Nominal.NLMap = NLMap;
        var ImportMapEditor = (function (_super) {
            __extends(ImportMapEditor, _super);
            function ImportMapEditor(item) {
                var _this = _super.call(this, false) || this;
                _this.item = item;
                _this.disbCodes = ko.observableArray([]);
                _this.selectedDisb = ko.observable(item.DisbCode);
                _this.init();
                return _this;
            }
            ImportMapEditor.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var disbs;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading GL Information...");
                                return [4, this.ajaxGet("api/Actions/DisbCodes")];
                            case 1:
                                disbs = _a.sent();
                                this.disbCodes(disbs);
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            ImportMapEditor.prototype.saveMapping = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var toSave;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Saving Mapping Details...");
                                toSave = {
                                    DisbMapIndex: this.item.DisbMapIndex,
                                    DisbCode: this.selectedDisb() || ""
                                };
                                return [4, this.ajaxSendOnly("api/Actions/UpdateImportMapping", toSave)];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                ko.postbox.publish(CLOSE_MAP_EDITOR, {});
                                return [2];
                        }
                    });
                });
            };
            return ImportMapEditor;
        }(BaseVM));
        var DisbMap = (function (_super) {
            __extends(DisbMap, _super);
            function DisbMap() {
                var _this = this;
                console.info("NLImportMap");
                _this = _super.call(this) || this;
                _this.editor = ko.observable(null);
                _this.toDispose.push(ko.postbox.subscribe(CLOSE_MAP_EDITOR, function () {
                    _this.editor(null);
                    _this.init(true);
                }));
                _this.init();
                return _this;
            }
            DisbMap.prototype.init = function (refresh) {
                if (refresh === void 0) { refresh = false; }
                return __awaiter(this, void 0, void 0, function () {
                    var data, table;
                    var _this = this;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Import Mapping Details...");
                                return [4, this.ajaxGet("api/Actions/NLImportMap")];
                            case 1:
                                data = _a.sent();
                                if (refresh) {
                                    $("#gltable").DataTable().destroy();
                                    $("#gltable").empty();
                                }
                                table = $("#gltable").DataTable({
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
                                table.on("select.dt", function (e, dt, type, indexes) {
                                    var arrData = table.row(indexes).data();
                                    var item = arrData[arrData.length - 1];
                                    _this.editor(new ImportMapEditor(item));
                                });
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            return DisbMap;
        }(BaseVM));
        Nominal.DisbMap = DisbMap;
        var Journal = (function (_super) {
            __extends(Journal, _super);
            function Journal() {
                var _this = this;
                console.info("Journal");
                _this = _super.call(this, false) || this;
                _this.children = ko.observableArray([]);
                _this.selectedItem = ko.observable(undefined);
                _this.editor = ko.observable(undefined);
                _this.currencySymbol = ko.observable("");
                _this.toDispose.push(_this.selectedItem.subscribe(function (val) {
                    if (val && val.filter) {
                        _this.loadItem(val);
                    }
                    else {
                        if (_this.table) {
                            $("#gltable").DataTable().destroy();
                            $("#gltable").empty();
                            _this.table = null;
                        }
                    }
                }));
                _this.toDispose.push(ko.postbox.subscribe(CLOSE_MAP_EDITOR, function () {
                    _this.editor(null);
                    _this.selectedItem.valueHasMutated();
                }));
                _this.init();
                return _this;
            }
            Journal.prototype.toggleItem = function (item) {
                if (item) {
                    item.expanded(!item.expanded());
                }
            };
            Journal.prototype.loadItem = function (item) {
                return __awaiter(this, void 0, void 0, function () {
                    var currencySymbol, data;
                    var _this = this;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                currencySymbol = this.currencySymbol();
                                this.showMessage("Loading Group...");
                                return [4, this.ajaxSendReceive("api/Actions/JournalList", item.group)];
                            case 1:
                                data = _a.sent();
                                if (this.table) {
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
                                                return currencySymbol + " " + parseFloat(num).toFixed(2);
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
                                this.table.on("select.dt", function (e, dt, type, indexes) {
                                    var arrData = _this.table.row(indexes).data();
                                    var item = arrData[arrData.length - 1];
                                    _this.editor(new MapEditor(item));
                                });
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            Journal.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    function buildItem(from, level) {
                        var x = {};
                        for (var i = 0; i <= level; i++) {
                            var fld = groups[i].unq;
                            x[fld] = from[fld];
                        }
                        return x;
                    }
                    function buildGroups(grps, level) {
                        if (level === void 0) { level = 0; }
                        var grpSettings = groups[level];
                        var distValues = ko.utils.arrayGetDistinctValues(grps.map(function (g) {
                            return g[grpSettings.unq];
                        }));
                        return distValues.map(function (o) {
                            var matches = grps.filter(function (g) {
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
                    var _a, allGroups, groups;
                    return __generator(this, function (_b) {
                        switch (_b.label) {
                            case 0:
                                this.showMessage("Loading Group...");
                                _a = this.currencySymbol;
                                return [4, this.ajaxGet("api/Actions/CurrencySymbol")];
                            case 1:
                                _a.apply(this, [_b.sent()]);
                                return [4, this.ajaxGet("api/Actions/JournalGroups")];
                            case 2:
                                allGroups = _b.sent();
                                groups = [
                                    { unq: "NomOrg", name: "OrgName", filter: false },
                                    { unq: "NomSource", name: "NomSource", filter: false },
                                    { unq: "NomSection", name: "NomSection", filter: false },
                                    { unq: "NomAccount", name: "NomAccount", filter: true },
                                    { unq: "NomOffice", name: "OfficeName", filter: true },
                                    { unq: "NomService", name: "ServiceName", filter: true },
                                    { unq: "NomDept", name: "DepartmentName", filter: true },
                                    { unq: "NomPartner", name: "PartnerName", filter: true }
                                ];
                                this.children(buildGroups(allGroups));
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            Journal.prototype.report = function () {
                window.open(this.getBaseUrl() + "api/Reports/JournalReport");
            };
            Journal.prototype.export = function () {
                window.open(this.getBaseUrl() + "api/Actions/Journal.csv");
            };
            Journal.prototype.transfer = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Submitting Journal...");
                                return [4, this.ajaxSendOnly("api/Actions/Transfer", {})];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                alert("Transfer has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
                                this.init();
                                return [2];
                        }
                    });
                });
            };
            Journal.prototype.statHours = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Sending STATS Journal...");
                                return [4, this.ajaxSendOnly("api/Actions/StatHours", {})];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                alert("Transfer has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
                                this.init();
                                return [2];
                        }
                    });
                });
            };
            Journal.prototype.flagTransfer = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Flagging Current Items as Transferred...");
                                return [4, this.ajaxSendOnly("api/Actions/FlagTransferred", {})];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                this.init();
                                return [2];
                        }
                    });
                });
            };
            return Journal;
        }(BaseVM));
        Nominal.Journal = Journal;
        var Integrationdetails = (function (_super) {
            __extends(Integrationdetails, _super);
            function Integrationdetails() {
                var _this = this;
                console.info("Integrationdetails");
                _this = _super.call(this, false) || this;
                _this.Periods = ko.observableArray([]);
                _this.SelectedPeriod = ko.observable(null);
                _this.children = ko.observableArray([]);
                _this.selectedItem = ko.observable(undefined);
                _this.toDispose.push(_this.selectedItem.subscribe(function (val) {
                    if (val && val.filter) {
                        val.group.NLPeriodIndex = _this.SelectedPeriod().NLPeriodIndex;
                        _this.loadItem(val);
                    }
                    else {
                        if (_this.table) {
                            $("#gltable").DataTable().destroy();
                            $("#gltable").empty();
                            _this.table = null;
                        }
                    }
                }));
                _this.toDispose.push(_this.SelectedPeriod.subscribe(function (postPeriod) { return __awaiter(_this, void 0, void 0, function () {
                    function buildItem(from, level) {
                        var x = {};
                        for (var i = 0; i <= level; i++) {
                            var fld = groups[i].unq;
                            x[fld] = from[fld];
                        }
                        return x;
                    }
                    function buildGroups(grps, level) {
                        if (level === void 0) { level = 0; }
                        var grpSettings = groups[level];
                        var distValues = ko.utils.arrayGetDistinctValues(grps.map(function (g) {
                            return g[grpSettings.unq];
                        }));
                        return distValues.map(function (o) {
                            var matches = grps.filter(function (g) {
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
                    var allGroups, groups;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Group...");
                                return [4, this.ajaxGet("api/Actions/DetailGroups/" + postPeriod.NLPeriodIndex.toString())];
                            case 1:
                                allGroups = _a.sent();
                                groups = [
                                    { unq: "NLOrg", name: "OrgName", filter: false },
                                    { unq: "NLSource", name: "NLSource", filter: false },
                                    { unq: "NLSection", name: "NLSection", filter: false },
                                    { unq: "NLAccount", name: "NLAccount", filter: true },
                                    { unq: "NLOffice", name: "OfficeName", filter: true },
                                    { unq: "NLService", name: "ServiceName", filter: true },
                                    { unq: "NLDept", name: "DepartmentName", filter: true },
                                    { unq: "NLPartner", name: "PartnerName", filter: true }
                                ];
                                this.children(buildGroups(allGroups));
                                this.clearMessage();
                                return [2];
                        }
                    });
                }); }));
                _this.init();
                return _this;
            }
            Integrationdetails.prototype.toggleItem = function (item) {
                if (item) {
                    item.expanded(!item.expanded());
                }
            };
            Integrationdetails.prototype.loadItem = function (item) {
                return __awaiter(this, void 0, void 0, function () {
                    var data;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Group...");
                                return [4, this.ajaxSendReceive("api/Actions/DetailList", item.group)];
                            case 1:
                                data = _a.sent();
                                if (this.table) {
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
                                return [2];
                        }
                    });
                });
            };
            Integrationdetails.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var periods;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Periods...");
                                return [4, this.ajaxGet("api/Actions/JournalPeriods")];
                            case 1:
                                periods = _a.sent();
                                this.Periods(periods);
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            Integrationdetails.prototype.report = function () {
                window.open(this.getBaseUrl() + "api/Reports/JournalReport");
            };
            return Integrationdetails;
        }(BaseVM));
        Nominal.Integrationdetails = Integrationdetails;
        var RepostJournal = (function (_super) {
            __extends(RepostJournal, _super);
            function RepostJournal() {
                var _this = this;
                console.info("RepostJournal");
                _this = _super.call(this, false) || this;
                _this.Periods = ko.observableArray([]);
                _this.SelectedPeriod = ko.observable(null);
                _this.startDate = ko.computed(function () {
                    var period = _this.SelectedPeriod();
                    if (period) {
                        return moment(period.PeriodStartDate).format("ddd MMM DD YYYY");
                    }
                    return "";
                });
                _this.endDate = ko.computed(function () {
                    var period = _this.SelectedPeriod();
                    if (period) {
                        return moment(period.PeriodEndDate).format("ddd MMM DD YYYY");
                    }
                    return "";
                });
                _this.toDispose.push(_this.startDate, _this.endDate);
                _this.toDispose.push(_this.SelectedPeriod.subscribe(function (postPeriod) { return __awaiter(_this, void 0, void 0, function () {
                    var currencySymbol, data;
                    var _this = this;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Available Journals for Reposting...");
                                return [4, this.ajaxGet("api/Actions/CurrencySymbol")];
                            case 1:
                                currencySymbol = _a.sent();
                                return [4, this.ajaxGet("api/Actions/JournalRepostList/" + postPeriod.NLPeriodIndex.toString())];
                            case 2:
                                data = _a.sent();
                                if (this.table) {
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
                                                return currencySymbol + " " + parseFloat(num).toFixed(2);
                                            }
                                        },
                                        {
                                            title: "Credits",
                                            className: "text-right",
                                            render: function (num) {
                                                num = isNaN(num) || num === '' || num === null ? 0.00 : num;
                                                return currencySymbol + " " + parseFloat(num).toFixed(2);
                                            }
                                        },
                                        { name: "item", visible: false }
                                    ]
                                });
                                this.table.on("select.dt", function (e, dt, type, indexes) { return __awaiter(_this, void 0, void 0, function () {
                                    var arrData, data;
                                    return __generator(this, function (_a) {
                                        switch (_a.label) {
                                            case 0:
                                                arrData = this.table.row(indexes).data();
                                                data = arrData[arrData.length - 1];
                                                console.log("repost", data);
                                                if (!confirm("Repost batch #" + data.NomBatch + "?")) return [3, 2];
                                                this.showMessage("Reposting Journal...");
                                                return [4, this.ajaxSendOnly("api/Actions/RepostJournal/" + data.NomBatch.toString(), {})];
                                            case 1:
                                                _a.sent();
                                                this.clearMessage();
                                                _a.label = 2;
                                            case 2: return [2];
                                        }
                                    });
                                }); });
                                this.clearMessage();
                                return [2];
                        }
                    });
                }); }));
                _this.init();
                return _this;
            }
            RepostJournal.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var periods;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Periods...");
                                return [4, this.ajaxGet("api/Actions/JournalPeriods")];
                            case 1:
                                periods = _a.sent();
                                this.Periods(periods);
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            return RepostJournal;
        }(BaseVM));
        Nominal.RepostJournal = RepostJournal;
        var ReprintJournal = (function (_super) {
            __extends(ReprintJournal, _super);
            function ReprintJournal() {
                var _this = this;
                console.info("ReprintJournal");
                _this = _super.call(this, false) || this;
                _this.Periods = ko.observableArray([]);
                _this.SelectedPeriod = ko.observable(null);
                _this.startDate = ko.computed(function () {
                    var period = _this.SelectedPeriod();
                    if (period) {
                        return moment(period.PeriodStartDate).format("ddd MMM DD YYYY");
                    }
                    return "";
                });
                _this.endDate = ko.computed(function () {
                    var period = _this.SelectedPeriod();
                    if (period) {
                        return moment(period.PeriodEndDate).format("ddd MMM DD YYYY");
                    }
                    return "";
                });
                _this.toDispose.push(_this.startDate, _this.endDate);
                _this.toDispose.push(_this.SelectedPeriod.subscribe(function (postPeriod) { return __awaiter(_this, void 0, void 0, function () {
                    var data;
                    var _this = this;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                if (postPeriod == undefined) {
                                    return [2];
                                }
                                this.showMessage("Loading Available Journals for Reprinting...");
                                return [4, this.ajaxGet("api/Actions/JournalRepostList/" + postPeriod.NLPeriodIndex.toString())];
                            case 1:
                                data = _a.sent();
                                if (this.table) {
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
                                this.table.on("select.dt", function (e, dt, type, indexes) { return __awaiter(_this, void 0, void 0, function () {
                                    var arrData, data;
                                    return __generator(this, function (_a) {
                                        arrData = this.table.row(indexes).data();
                                        data = arrData[arrData.length - 1];
                                        console.log("reprint", data);
                                        if (confirm("Reprint batch #" + data.NomBatch + "?")) {
                                            window.open(this.getBaseUrl() + ("api/Reports/ReprintJournalReport?batch=" + data.NomBatch));
                                        }
                                        return [2];
                                    });
                                }); });
                                this.clearMessage();
                                return [2];
                        }
                    });
                }); }));
                _this.init();
                return _this;
            }
            ReprintJournal.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var periods;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Periods...");
                                return [4, this.ajaxGet("api/Actions/JournalPeriods")];
                            case 1:
                                periods = _a.sent();
                                this.Periods(periods);
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            return ReprintJournal;
        }(BaseVM));
        Nominal.ReprintJournal = ReprintJournal;
        var ReprintJournalDetails = (function (_super) {
            __extends(ReprintJournalDetails, _super);
            function ReprintJournalDetails() {
                var _this = this;
                console.info("ReprintJournal");
                _this = _super.call(this, false) || this;
                _this.Periods = ko.observableArray([]);
                _this.SelectedPeriod = ko.observable(null);
                _this.Orgs = ko.observableArray([]);
                _this.SelectedOrg = ko.observable(null);
                _this.SelectedSource = ko.observable(null);
                _this.startDate = ko.computed(function () {
                    var period = _this.SelectedPeriod();
                    if (period) {
                        return moment(period.PeriodStartDate).format("ddd MMM DD YYYY");
                    }
                    return "";
                });
                _this.endDate = ko.computed(function () {
                    var period = _this.SelectedPeriod();
                    if (period) {
                        return moment(period.PeriodEndDate).format("ddd MMM DD YYYY");
                    }
                    return "";
                });
                _this.toDispose.push(_this.startDate, _this.endDate);
                _this.toDispose.push(_this.SelectedPeriod.subscribe(function (postPeriod) { return __awaiter(_this, void 0, void 0, function () {
                    var data;
                    var _this = this;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                if (postPeriod == undefined) {
                                    return [2];
                                }
                                this.showMessage("Loading Available Journals for Reprinting...");
                                return [4, this.ajaxGet("api/Actions/JournalRepostList/" + postPeriod.NLPeriodIndex.toString())];
                            case 1:
                                data = _a.sent();
                                if (this.table) {
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
                                this.table.on("select.dt", function (e, dt, type, indexes) { return __awaiter(_this, void 0, void 0, function () {
                                    var arrData, data;
                                    return __generator(this, function (_a) {
                                        arrData = this.table.row(indexes).data();
                                        data = arrData[arrData.length - 1];
                                        console.log("reprint", data);
                                        if (confirm("Reprint batch #" + data.NomBatch + "?")) {
                                            window.open(this.getBaseUrl() + ("api/Reports/ReprintJournalDetails?batch=" + data.NomBatch + "&org=" + this.SelectedOrg().PracID + "&source=" + this.SelectedSource()));
                                        }
                                        return [2];
                                    });
                                }); });
                                this.clearMessage();
                                return [2];
                        }
                    });
                }); }));
                _this.init();
                return _this;
            }
            ReprintJournalDetails.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var periods, orgs;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Periods and Orgs...");
                                return [4, this.ajaxGet("api/Actions/JournalPeriods")];
                            case 1:
                                periods = _a.sent();
                                this.Periods(periods);
                                return [4, this.ajaxGet("api/Actions/OrgList")];
                            case 2:
                                orgs = _a.sent();
                                this.Orgs(orgs);
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            return ReprintJournalDetails;
        }(BaseVM));
        Nominal.ReprintJournalDetails = ReprintJournalDetails;
        var BankRec = (function (_super) {
            __extends(BankRec, _super);
            function BankRec() {
                var _this = this;
                console.info("BankRec");
                _this = _super.call(this) || this;
                var datesData = _this.getSession("SelectedDates");
                _this.startDate = moment(datesData.PracPeriodStart.substr(0, 10)).format("ddd MMM DD YYYY");
                _this.endDate = moment(datesData.PracPeriodEnd.substr(0, 10)).format("ddd MMM DD YYYY");
                return _this;
            }
            BankRec.prototype.run = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Submitting Bank Reconciliation...");
                                return [4, this.ajaxSendOnly("api/Actions/BankReconciliation", {})];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                alert("Updated Bank Reconciliation successfully");
                                this.goHome();
                                return [2];
                        }
                    });
                });
            };
            return BankRec;
        }(BaseVM));
        Nominal.BankRec = BankRec;
        var CostingUpdate = (function (_super) {
            __extends(CostingUpdate, _super);
            function CostingUpdate() {
                var _this = this;
                console.info("CostingUpdate");
                _this = _super.call(this) || this;
                var datesData = _this.getSession("SelectedDates");
                _this.startDate = moment(datesData.PracPeriodStart.substr(0, 10)).format("ddd MMM DD YYYY");
                _this.endDate = moment(datesData.PracPeriodEnd.substr(0, 10)).format("ddd MMM DD YYYY");
                return _this;
            }
            CostingUpdate.prototype.run = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Updating Costing Data...");
                                return [4, this.ajaxSendOnly("api/Actions/CostingUpdate", {})];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                alert("Updated Costing Data successfully");
                                this.goHome();
                                return [2];
                        }
                    });
                });
            };
            return CostingUpdate;
        }(BaseVM));
        Nominal.CostingUpdate = CostingUpdate;
        var BankRecPost = (function (_super) {
            __extends(BankRecPost, _super);
            function BankRecPost() {
                var _this = this;
                console.info("BankRecPost");
                _this = _super.call(this, false) || this;
                _this.Periods = ko.observableArray([]);
                _this.SelectedPeriod = ko.observable(null);
                _this.startDate = ko.computed(function () {
                    var period = _this.SelectedPeriod();
                    if (period) {
                        return moment(period.PeriodStartDate).format("ddd MMM DD YYYY");
                    }
                    return "";
                });
                _this.endDate = ko.computed(function () {
                    var period = _this.SelectedPeriod();
                    if (period) {
                        return moment(period.PeriodEndDate).format("ddd MMM DD YYYY");
                    }
                    return "";
                });
                _this.toDispose.push(_this.startDate, _this.endDate);
                _this.toDispose.push(_this.SelectedPeriod.subscribe(function (postPeriod) { return __awaiter(_this, void 0, void 0, function () {
                    var currencySymbol, data;
                    var _this = this;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Available Journals for Reposting...");
                                return [4, this.ajaxGet("api/Actions/CurrencySymbol")];
                            case 1:
                                currencySymbol = _a.sent();
                                return [4, this.ajaxGet("api/Actions/BankRecRepostList/" + postPeriod.NLPeriodIndex.toString())];
                            case 2:
                                data = _a.sent();
                                if (this.table) {
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
                                                return currencySymbol + " " + parseFloat(num).toFixed(2);
                                            }
                                        },
                                        { name: "item", visible: false }
                                    ]
                                });
                                this.table.on("select.dt", function (e, dt, type, indexes) { return __awaiter(_this, void 0, void 0, function () {
                                    var arrData, item;
                                    return __generator(this, function (_a) {
                                        switch (_a.label) {
                                            case 0:
                                                arrData = this.table.row(indexes).data();
                                                item = arrData[arrData.length - 1];
                                                if (!confirm("Repost batch #" + item.LodgeBatch + "?")) return [3, 2];
                                                return [4, this.ajaxSendOnly("api/Actions/RepostBankRec/" + item.LodgeBatch.toString(), {})];
                                            case 1:
                                                _a.sent();
                                                _a.label = 2;
                                            case 2: return [2];
                                        }
                                    });
                                }); });
                                this.clearMessage();
                                return [2];
                        }
                    });
                }); }));
                _this.init();
                return _this;
            }
            BankRecPost.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var periods;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Periods...");
                                return [4, this.ajaxGet("api/Actions/BankRecPeriods")];
                            case 1:
                                periods = _a.sent();
                                this.Periods(periods);
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            return BankRecPost;
        }(BaseVM));
        Nominal.BankRecPost = BankRecPost;
        var NominalControl = (function (_super) {
            __extends(NominalControl, _super);
            function NominalControl() {
                var _this = this;
                console.info("IntegrationSetup");
                _this = _super.call(this, false) || this;
                _this.wipOffice = ko.observable(false);
                _this.wipService = ko.observable(false);
                _this.wipPartner = ko.observable(false);
                _this.wipDepartment = ko.observable(false);
                _this.drsOffice = ko.observable(false);
                _this.drsService = ko.observable(false);
                _this.drsPartner = ko.observable(false);
                _this.drsDepartment = ko.observable(false);
                _this.wipLevel = ko.observable("");
                _this.drsLevel = ko.observable("");
                _this.disbDetail = ko.observable("");
                _this.stdDisbCode = ko.observable("");
                _this.feeSource = ko.observable("");
                _this.feeProfits = ko.observable("");
                _this.feePartner = ko.observable("");
                _this.glSystem = ko.observable("");
                _this.interCompany = ko.observable(false);
                _this.cashbook = ko.observable(false);
                _this.expenses = ko.observable(false);
                _this.disbCodes = ko.observableArray([]);
                _this.init();
                return _this;
            }
            NominalControl.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var codes, data;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Nominal Control Details...");
                                return [4, this.ajaxGet("api/Actions/DisbCodes")];
                            case 1:
                                codes = _a.sent();
                                this.disbCodes(codes);
                                return [4, this.ajaxGet("api/Actions/NominalControl")];
                            case 2:
                                data = _a.sent();
                                this.wipOffice(data.WIPOffice !== 0);
                                this.wipService(data.WIPServ !== 0);
                                this.wipPartner(data.WIPPart !== 0);
                                this.wipDepartment(data.WIPDept !== 0);
                                this.drsOffice(data.DRSOffice !== 0);
                                this.drsService(data.DRSServ !== 0);
                                this.drsPartner(data.DRSPart !== 0);
                                this.drsDepartment(data.DRSDept !== 0);
                                this.wipLevel(data.WIPLevel.toString());
                                this.drsLevel(data.DRSLevel.toString());
                                this.disbDetail(data.DisbLevel.toString());
                                this.stdDisbCode(data.DisbStd);
                                this.feeSource(data.FeeSource.toString());
                                this.feeProfits(data.FeeProfit.toString());
                                this.feePartner(data.FeePart.toString());
                                this.glSystem(data.IntSystem);
                                this.interCompany(data.InterCo);
                                this.cashbook(data.Cashbook);
                                this.expenses(data.Expenses);
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            NominalControl.prototype.save = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var data;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Saving Configuration...");
                                data = {
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
                                return [4, this.ajaxSendOnly("api/Actions/NominalControl", data)];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                this.goHome();
                                return [2];
                        }
                    });
                });
            };
            NominalControl.prototype.buildMap = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Building Mappings...");
                                return [4, this.ajaxGet("api/Actions/BuildMap")];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                alert('Map was built');
                                return [2];
                        }
                    });
                });
            };
            NominalControl.prototype.clearMap = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Clearing Mappings...");
                                return [4, this.ajaxGet("api/Actions/BuildMap")];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                alert('Map was cleared');
                                return [2];
                        }
                    });
                });
            };
            return NominalControl;
        }(BaseVM));
        Nominal.NominalControl = NominalControl;
        var NLImport = (function (_super) {
            __extends(NLImport, _super);
            function NLImport() {
                var _this = this;
                console.info("CreateDisb");
                _this = _super.call(this) || this;
                var datesData = _this.getSession("SelectedDates");
                _this.startDate = moment(datesData.PracPeriodStart.substr(0, 10)).format("ddd MMM DD YYYY");
                _this.endDate = moment(datesData.PracPeriodEnd.substr(0, 10)).format("ddd MMM DD YYYY");
                return _this;
            }
            NLImport.prototype.run = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Importing Disbursements...");
                                return [4, this.ajaxSendOnly("api/Actions/DisbImport", {})];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                alert("Disbursement Import has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
                                this.goHome();
                                return [2];
                        }
                    });
                });
            };
            return NLImport;
        }(BaseVM));
        Nominal.NLImport = NLImport;
        var Organisations = (function (_super) {
            __extends(Organisations, _super);
            function Organisations() {
                var _this = this;
                console.info("Organisations");
                _this = _super.call(this) || this;
                _this.orgs = ko.observableArray([]);
                _this.editOrg = ko.observable(undefined);
                _this.server = ko.observable("");
                _this.database = ko.observable("");
                _this.transfer = ko.observable(false);
                _this.toDispose.push(_this.editOrg.subscribe(function (toEdit) {
                    if (toEdit) {
                        _this.server(toEdit.NLServer);
                        _this.database(toEdit.NLDatabase);
                        _this.transfer(toEdit.NLTransfer);
                    }
                }));
                _this.init();
                return _this;
            }
            Organisations.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var data;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Orgs...");
                                return [4, this.ajaxGet("api/Actions/OrgList")];
                            case 1:
                                data = _a.sent();
                                this.orgs(data);
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            Organisations.prototype.updateOrg = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var editing;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Saving Org...");
                                editing = this.editOrg();
                                editing.NLServer = this.server();
                                editing.NLDatabase = this.database();
                                editing.NLTransfer = this.transfer();
                                return [4, this.ajaxSendOnly("api/Actions/OrgUpdate", editing)];
                            case 1:
                                _a.sent();
                                this.editOrg(undefined);
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            return Organisations;
        }(BaseVM));
        Nominal.Organisations = Organisations;
        var IntacctSync = (function (_super) {
            __extends(IntacctSync, _super);
            function IntacctSync() {
                var _this = _super.call(this) || this;
                _this.onlyNew = ko.observable(false);
                return _this;
            }
            IntacctSync.prototype.runCustomerSync = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var newQS;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Starting Sync...");
                                newQS = this.onlyNew() ? "?OnlyNew=True" : "";
                                return [4, this.ajaxSendOnly("api/IntacctSync/Customers" + newQS, {})];
                            case 1:
                                _a.sent();
                                alert("Customers Synchronization has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            IntacctSync.prototype.runProjectSync = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var newQS;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Starting Sync...");
                                newQS = this.onlyNew() ? "?OnlyNew=True" : "";
                                return [4, this.ajaxSendOnly("api/IntacctSync/Projects" + newQS, {})];
                            case 1:
                                _a.sent();
                                alert("Projects Synchronization has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            IntacctSync.prototype.runEmployeeSync = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var newQS;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Starting Sync...");
                                newQS = this.onlyNew() ? "?OnlyNew=True" : "";
                                return [4, this.ajaxSendOnly("api/IntacctSync/Employees" + newQS, {})];
                            case 1:
                                _a.sent();
                                alert("Employees Synchronization has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            IntacctSync.prototype.runSyncAll = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var newQS;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Starting Sync...");
                                newQS = this.onlyNew() ? "?OnlyNew=True" : "";
                                return [4, this.ajaxSendOnly("api/IntacctSync/SyncAll" + newQS, {})];
                            case 1:
                                _a.sent();
                                alert("Synchronization has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            return IntacctSync;
        }(BaseVM));
        Nominal.IntacctSync = IntacctSync;
        var MTD = (function (_super) {
            __extends(MTD, _super);
            function MTD() {
                var _this = this;
                console.info("MTD");
                _this = _super.call(this, false) || this;
                var datesData = _this.getSession("SelectedDates");
                _this.startDate = moment(datesData.PracPeriodStart.substr(0, 10)).format("ddd MMM DD YYYY");
                _this.endDate = moment(datesData.PracPeriodEnd.substr(0, 10)).format("ddd MMM DD YYYY");
                _this.init();
                return _this;
            }
            MTD.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        this.isReady(true);
                        return [2];
                    });
                });
            };
            MTD.prototype.run = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Running MTD Sync...");
                                return [4, this.ajaxSendOnly("api/Actions/MTDSync", {})];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                alert("Making Tax Digital Sync has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
                                this.goHome();
                                return [2];
                        }
                    });
                });
            };
            return MTD;
        }(BaseVM));
        Nominal.MTD = MTD;
        var ExpensePost = (function (_super) {
            __extends(ExpensePost, _super);
            function ExpensePost() {
                var _this = this;
                console.info("ExpensePost");
                _this = _super.call(this, false) || this;
                _this.children = ko.observableArray([]);
                _this.selectedItem = ko.observable(undefined);
                _this.noMissingData = ko.observable(false);
                _this.hasMissingStaff = ko.observable(true);
                _this.hasMissingAccounts = ko.observable(true);
                _this.toDispose.push(_this.selectedItem.subscribe(function (val) {
                    if (val && val.filter) {
                        _this.loadItem(val);
                    }
                    else {
                        if (_this.table) {
                            $("#gltable").DataTable().destroy();
                            $("#gltable").empty();
                            _this.table = null;
                        }
                    }
                }));
                _this.init();
                return _this;
            }
            ExpensePost.prototype.toggleItem = function (item) {
                if (item) {
                    item.expanded(!item.expanded());
                }
            };
            ExpensePost.prototype.loadItem = function (item) {
                return __awaiter(this, void 0, void 0, function () {
                    var data;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Staff...");
                                return [4, this.ajaxSendReceive("api/Actions/ExpenseLines", item.group)];
                            case 1:
                                data = _a.sent();
                                if (this.table) {
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
                                return [2];
                        }
                    });
                });
            };
            ExpensePost.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    function buildItem(from, level) {
                        var x = {};
                        for (var i = 0; i <= level; i++) {
                            var fld = groups[i].unq;
                            x[fld] = from[fld];
                        }
                        return x;
                    }
                    function buildGroups(grps, level) {
                        if (level === void 0) { level = 0; }
                        var grpSettings = groups[level];
                        var distValues = ko.utils.arrayGetDistinctValues(grps.map(function (g) {
                            return g[grpSettings.unq];
                        }));
                        return distValues.map(function (o) {
                            var matches = grps.filter(function (g) {
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
                    var allGroups, groups;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Staff...");
                                return [4, this.ajaxGet("api/Actions/ExpenseStaff")];
                            case 1:
                                allGroups = _a.sent();
                                groups = [
                                    { unq: "StaffOrg", name: "OrgName", filter: false },
                                    { unq: "StaffIndex", name: "StaffName", filter: true }
                                ];
                                this.children(buildGroups(allGroups));
                                if (allGroups.length > 0) {
                                    this.hasMissingStaff(allGroups[0].BlankStaff > 0);
                                    this.hasMissingAccounts(allGroups[0].BlankAccounts > 0);
                                    this.noMissingData(!this.hasMissingAccounts());
                                }
                                this.clearMessage();
                                this.isReady(true);
                                return [2];
                        }
                    });
                });
            };
            ExpensePost.prototype.transfer = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Submitting Expenses...");
                                return [4, this.ajaxSendOnly("api/Actions/TransferExpenses", {})];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                alert("Transfer has been queued.\nPlease check the Hangfire Dashboard for details and logging.");
                                this.init();
                                return [2];
                        }
                    });
                });
            };
            ExpensePost.prototype.goToMappings = function () {
                this.showPage("MissingExpenseAccountMap");
            };
            ExpensePost.prototype.goToStaff = function () {
                this.showPage("MissingExpenseStaff");
            };
            return ExpensePost;
        }(BaseVM));
        Nominal.ExpensePost = ExpensePost;
        var CLOSE_EXPMAP_EDITOR = "CLOSEEXPMAPEDITOR";
        var MissingExpenseAccountMap = (function (_super) {
            __extends(MissingExpenseAccountMap, _super);
            function MissingExpenseAccountMap() {
                var _this = this;
                console.info("MissingExpenseAccountMap");
                _this = _super.call(this) || this;
                _this.editor = ko.observable(null);
                _this.toDispose.push(ko.postbox.subscribe(CLOSE_EXPMAP_EDITOR, function () {
                    _this.editor(null);
                    _this.init(true);
                }));
                _this.init();
                return _this;
            }
            MissingExpenseAccountMap.prototype.init = function (refresh) {
                if (refresh === void 0) { refresh = false; }
                return __awaiter(this, void 0, void 0, function () {
                    var data, table;
                    var _this = this;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Missing Mapping Details...");
                                return [4, this.ajaxGet("api/Actions/MissingExpenseAccountMap")];
                            case 1:
                                data = _a.sent();
                                if (refresh) {
                                    $("#gltable").DataTable().destroy();
                                    $("#gltable").empty();
                                }
                                table = $("#gltable").DataTable({
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
                                table.on("select.dt", function (e, dt, type, indexes) {
                                    var arrData = table.row(indexes).data();
                                    var item = arrData[arrData.length - 1];
                                    _this.editor(new ExpAccountMapEditor(item));
                                });
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            MissingExpenseAccountMap.prototype.goToExpenses = function () {
                this.showPage("ExpensePost");
            };
            return MissingExpenseAccountMap;
        }(BaseVM));
        Nominal.MissingExpenseAccountMap = MissingExpenseAccountMap;
        var ExpAccountMapEditor = (function (_super) {
            __extends(ExpAccountMapEditor, _super);
            function ExpAccountMapEditor(item) {
                var _this = _super.call(this, false) || this;
                _this.item = item;
                _this.chargeCode = ko.observable(item.ChargeExpAccount);
                _this.nonchargeCode = ko.observable(item.NonChargeExpAccount);
                _this.chargeSuffix1 = ko.observable(item.ChargeSuffix1);
                _this.chargeSuffix2 = ko.observable(item.ChargeSuffix2);
                _this.chargeSuffix3 = ko.observable(item.ChargeSuffix3);
                _this.nonChargeSuffix1 = ko.observable(item.NonChargeSuffix1);
                _this.nonChargeSuffix2 = ko.observable(item.NonChargeSuffix2);
                _this.nonChargeSuffix3 = ko.observable(item.NonChargeSuffix3);
                _this.init();
                return _this;
            }
            ExpAccountMapEditor.prototype.init = function () {
                return __awaiter(this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        this.showMessage("Loading GL Information...");
                        this.clearMessage();
                        this.isReady(true);
                        return [2];
                    });
                });
            };
            ExpAccountMapEditor.prototype.saveMapping = function () {
                return __awaiter(this, void 0, void 0, function () {
                    var toSave;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Saving Mapping Details...");
                                toSave = this.item;
                                toSave.ChargeExpAccount = this.chargeCode();
                                toSave.ChargeSuffix1 = this.chargeSuffix1();
                                toSave.ChargeSuffix2 = this.chargeSuffix2();
                                toSave.ChargeSuffix3 = this.chargeSuffix3();
                                toSave.NonChargeExpAccount = this.nonchargeCode();
                                toSave.NonChargeSuffix1 = this.nonChargeSuffix1();
                                toSave.NonChargeSuffix2 = this.nonChargeSuffix2();
                                toSave.NonChargeSuffix3 = this.nonChargeSuffix3();
                                return [4, this.ajaxSendOnly("api/Actions/UpdateExpenseAccountMapping", toSave)];
                            case 1:
                                _a.sent();
                                this.clearMessage();
                                ko.postbox.publish(CLOSE_EXPMAP_EDITOR, {});
                                return [2];
                        }
                    });
                });
            };
            return ExpAccountMapEditor;
        }(BaseVM));
        var MissingExpenseStaff = (function (_super) {
            __extends(MissingExpenseStaff, _super);
            function MissingExpenseStaff() {
                var _this = this;
                console.info("MissingExpenseStaff");
                _this = _super.call(this) || this;
                _this.init();
                return _this;
            }
            MissingExpenseStaff.prototype.init = function (refresh) {
                if (refresh === void 0) { refresh = false; }
                return __awaiter(this, void 0, void 0, function () {
                    var data, table;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Missing Staff Details...");
                                return [4, this.ajaxGet("api/Actions/MissingExpenseStaff")];
                            case 1:
                                data = _a.sent();
                                if (refresh) {
                                    $("#gltable").DataTable().destroy();
                                    $("#gltable").empty();
                                }
                                table = $("#gltable").DataTable({
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
                                return [2];
                        }
                    });
                });
            };
            MissingExpenseStaff.prototype.goToExpenses = function () {
                this.showPage("ExpensePost");
            };
            return MissingExpenseStaff;
        }(BaseVM));
        Nominal.MissingExpenseStaff = MissingExpenseStaff;
        var ExpMap = (function (_super) {
            __extends(ExpMap, _super);
            function ExpMap() {
                var _this = this;
                console.info("ExpMap");
                _this = _super.call(this) || this;
                _this.editor = ko.observable(null);
                _this.toDispose.push(ko.postbox.subscribe(CLOSE_EXPMAP_EDITOR, function () {
                    _this.editor(null);
                    _this.init(true);
                }));
                _this.init();
                return _this;
            }
            ExpMap.prototype.init = function (refresh) {
                if (refresh === void 0) { refresh = false; }
                return __awaiter(this, void 0, void 0, function () {
                    var data, table;
                    var _this = this;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                this.showMessage("Loading Expense Code Mapping Details...");
                                return [4, this.ajaxGet("api/Actions/ExpenseAccountMap")];
                            case 1:
                                data = _a.sent();
                                if (refresh) {
                                    $("#gltable").DataTable().destroy();
                                    $("#gltable").empty();
                                }
                                table = $("#gltable").DataTable({
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
                                table.on("select.dt", function (e, dt, type, indexes) {
                                    var arrData = table.row(indexes).data();
                                    var item = arrData[arrData.length - 1];
                                    _this.editor(new ExpAccountMapEditor(item));
                                });
                                this.clearMessage();
                                return [2];
                        }
                    });
                });
            };
            return ExpMap;
        }(BaseVM));
        Nominal.ExpMap = ExpMap;
    })(Nominal = PE.Nominal || (PE.Nominal = {}));
})(PE || (PE = {}));
ko.bindingHandlers.bsmodal = {
    update: function (element, valueAccessor, allBindings, viewModel, bindingContext) {
        var value = valueAccessor();
        var _value = ko.unwrap(value);
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
        }
        else {
            $(element).modal("hide");
        }
    }
};
$(document).ready(function () {
    ko.applyBindings(new PE.Nominal.PageVM());
});
//# sourceMappingURL=Site.js.map