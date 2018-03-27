declare namespace DataTables {

    interface SelectApi {
        on(event: "select.dt", callback: (e: JQueryEventObject, dt: DataTables.Api, type: string, indexes: Array<any>) => void): Api;
    }
}