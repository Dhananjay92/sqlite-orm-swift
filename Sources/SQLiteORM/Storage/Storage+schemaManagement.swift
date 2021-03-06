import Foundation

extension Storage {

    public func tableExists(with name: String) throws -> Bool {
        let connectionRef = try ConnectionRef(connection: self.connection)
        return try self.tableExists(with: name, connectionRef: connectionRef)
    }

    private func tableExists(with name: String, connectionRef: ConnectionRef) throws -> Bool {
        var res = false
        let sql = "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = '\(name)'"
        let statement = try connectionRef.prepare(sql: sql)
        var resultCode = Int32(0)
        repeat {
            resultCode = statement.step()
            switch resultCode {
            case apiProvider.SQLITE_ROW:
                let intValue = statement.columnInt(index: 0)
                res = intValue == 1
            case apiProvider.SQLITE_DONE:
                break
            default:
                let errorString = connectionRef.errorMessage
                throw Error.sqliteError(code: resultCode, text: errorString)
            }
        }while resultCode != apiProvider.SQLITE_DONE
        return res
    }

    private func tableInfo(forTableWith name: String, connectionRef: ConnectionRef) throws -> [TableInfo] {
        let sql = "PRAGMA table_info('\(name)')"
        let statement = try connectionRef.prepare(sql: sql)
        var res = [TableInfo]()
        var resultCode = Int32(0)
        repeat {
            resultCode = statement.step()
            switch resultCode {
            case apiProvider.SQLITE_ROW:
                var tableInfo = TableInfo()
                tableInfo.cid = statement.columnInt(index: 0)
                tableInfo.name = statement.columnText(index: 1)
                tableInfo.type = statement.columnText(index: 2)
                tableInfo.notNull = statement.columnInt(index: 3) == 1
                tableInfo.dfltValue = statement.columnText(index: 4)
                tableInfo.pk = statement.columnInt(index: 5)
                res.append(tableInfo)
            case apiProvider.SQLITE_DONE:
                break
            default:
                let errorString = connectionRef.errorMessage
                throw Error.sqliteError(code: resultCode, text: errorString)
            }
        }while resultCode != apiProvider.SQLITE_DONE
        return res
    }

    static private func calculateRemoveAddColumns(columnsToAdd: inout [TableInfo],
                                                  storageTableInfo: inout [TableInfo],
                                                  dbTableInfo: inout [TableInfo]) -> Bool {
        var notEqual = false

        //  iterate through storage columns
        var storageColumnInfoIndex = 0
        repeat {

            //  get storage's column info
            let storageColumnInfo = storageTableInfo[storageColumnInfoIndex]
            let columnName = storageColumnInfo.name

            //  search for a column in db eith the same name
            if let dbColumnInfo = dbTableInfo.first(where: { $0.name == columnName }) {
                let columnsAreEqual = dbColumnInfo.name == storageColumnInfo.name
                    && dbColumnInfo.notNull == storageColumnInfo.notNull
                    && dbColumnInfo.dfltValue.isEmpty == storageColumnInfo.dfltValue.isEmpty
                    && dbColumnInfo.pk == storageColumnInfo.pk
                if !columnsAreEqual {
                    notEqual = true
                    break
                }
                dbTableInfo.removeAll(where: { $0.name == columnName })
                storageTableInfo.remove(at: storageColumnInfoIndex)
                storageColumnInfoIndex -= 1
            } else {
                columnsToAdd.append(storageColumnInfo)
            }

            storageColumnInfoIndex += 1
        }while storageColumnInfoIndex < storageTableInfo.count

        return notEqual
    }

    private func schemaStatus(for table: AnyTable, connectionRef: ConnectionRef, preserve: Bool) throws -> SyncSchemaResult {
        var res = SyncSchemaResult.alredyInSync
        var gottaCreateTable = try !self.tableExists(with: table.name, connectionRef: connectionRef)
        if !gottaCreateTable {
            var storageTableInfo = table.tableInfo
            var dbTableInfo = try self.tableInfo(forTableWith: table.name, connectionRef: connectionRef)
            var columnsToAdd = [TableInfo]()
            if Storage.calculateRemoveAddColumns(columnsToAdd: &columnsToAdd, storageTableInfo: &storageTableInfo, dbTableInfo: &dbTableInfo) {
                gottaCreateTable = true
            }
            if !gottaCreateTable {  //  if all storage columns are equal to actual db columns but there are
                //  excess columns at the db..
                if dbTableInfo.count > 0 {
                    // extra table columns than storage columns
                    if !preserve {
                        gottaCreateTable = true
                    } else {
                        res = .oldColumnsRemoved
                    }
                }
            }
            if gottaCreateTable {
                res = .droppedAndRecreated
            } else {
                if !columnsToAdd.isEmpty {
                    // extra storage columns than table columns
                    for columnToAdd in columnsToAdd {
                        if columnToAdd.notNull && columnToAdd.dfltValue.isEmpty {
                            gottaCreateTable = true
                            break
                        }
                    }
                    if !gottaCreateTable {
                        if res == .oldColumnsRemoved {
                            res = .newColumnsAddedAndOldColumnsRemoved
                        } else {
                            res = .newColumnsAdded
                        }
                    } else {
                        res = .droppedAndRecreated
                    }
                } else {
                    if res != .oldColumnsRemoved {
                        res = .alredyInSync
                    }
                }
            }
        } else {
            res = .newTableCreated
        }
        return res
    }

    private func create(tableWith name: String, columns: [AnyColumn], connectionRef: ConnectionRef) throws {
        var sql = "CREATE TABLE '\(name)' ("
        let columnsCount = columns.count
        for (columnIndex, column) in columns.enumerated() {
            let columnString = column.serialize(with: .init(schemaProvider: self))
            sql += "\(columnString)"
            if columnIndex < columnsCount - 1 {
                sql += ", "
            }
        }
        sql += ")"
        try connectionRef.exec(sql: sql)
    }

    private func copy(table: AnyTable, name: String, connectionRef: ConnectionRef, columnsToIgnore: [TableInfo]) throws {
        var columnNames = [String]()
        for column in table.columns {   //  TODO: refactor to map and filter
            let columnName = column.name
            if !columnsToIgnore.contains(where: { $0.name == columnName }) {
                columnNames.append(columnName)
            }
        }
        let columnNamesCount = columnNames.count
        var sql = "INSERT INTO \(name) ("
        for (columnNameIndex, columnName) in columnNames.enumerated() {
            sql += "\"\(columnName)\""
            if columnNameIndex < columnNamesCount - 1 {
                sql += ", "
            }
        }
        sql += ") SELECT "
        for (columnNameIndex, columnName) in columnNames.enumerated() {
            sql += "\"\(columnName)\""
            if columnNameIndex < columnNamesCount - 1 {
                sql += ", "
            }
        }
        sql += " FROM '\(table.name)'"
        try connectionRef.exec(sql: sql)
    }

    private func dropTableInternal(tableName: String, connectionRef: ConnectionRef) throws {
        let sql = "DROP TABLE '\(tableName)'"
        try connectionRef.exec(sql: sql)
    }

    private func renameTable(connectionRef: ConnectionRef, oldName: String, newName: String) throws {
        let sql = "ALTER TABLE \(oldName) RENAME TO \(newName)"
        try connectionRef.exec(sql: sql)
    }

    private func backup(_ table: AnyTable, connectionRef: ConnectionRef, columnsToIgnore: [TableInfo]) throws {

        //  here we copy source table to another with a name with '_backup' suffix, but in case table with such
        //  a name already exists we append suffix 1, then 2, etc until we find a free name..
        var backupTableName = "\(table.name)_backup"
        if try self.tableExists(with: backupTableName, connectionRef: connectionRef) {
            var suffix = 1
            repeat {
                let anotherBackupTableName = "\(backupTableName)\(suffix)"
                if try self.tableExists(with: anotherBackupTableName, connectionRef: connectionRef) == false {
                    backupTableName = anotherBackupTableName
                    break
                }
                suffix += 1
            }while true
        }
        try self.create(tableWith: backupTableName, columns: table.columns, connectionRef: connectionRef)
        try self.copy(table: table, name: backupTableName, connectionRef: connectionRef, columnsToIgnore: columnsToIgnore)
        try self.dropTableInternal(tableName: table.name, connectionRef: connectionRef)
        try self.renameTable(connectionRef: connectionRef, oldName: backupTableName, newName: table.name)
    }

    private func add(column tableInfo: TableInfo, table: AnyTable, connectionRef: ConnectionRef) throws {
        var sql = "ALTER TABLE \(table.name) ADD COLUMN \(tableInfo.name) \(tableInfo.type)"
        if tableInfo.pk == 1 {
            sql += " PRIMARY KEY"
        }
        if tableInfo.notNull {
            sql += " NOT NULL"
        }
        if !tableInfo.dfltValue.isEmpty {
            sql += " DEFAULT \(tableInfo.dfltValue)"
        }
        try connectionRef.exec(sql: sql)
    }

    private func sync(_ table: AnyTable, connectionRef: ConnectionRef, preserve: Bool) throws -> SyncSchemaResult {
        var res = SyncSchemaResult.alredyInSync
        let schemaStatus = try self.schemaStatus(for: table, connectionRef: connectionRef, preserve: preserve)
        if schemaStatus != .alredyInSync {
            if schemaStatus == .newTableCreated {
                try self.create(tableWith: table.name, columns: table.columns, connectionRef: connectionRef)
                res = .newTableCreated
            } else {
                if schemaStatus == .oldColumnsRemoved || schemaStatus == .newColumnsAdded || schemaStatus == .newColumnsAddedAndOldColumnsRemoved {

                    //  get table info provided in `make_table` call..
                    var storageTableInfo = table.tableInfo

                    //  now get current table info from db using `PRAGMA table_info` query..
                    var dbTableInfo = try self.tableInfo(forTableWith: table.name, connectionRef: connectionRef)

                    //  this array will contain pointers to columns that gotta be added..
                    var columnsToAdd = [TableInfo]()

                    _ = Storage.calculateRemoveAddColumns(columnsToAdd: &columnsToAdd, storageTableInfo: &storageTableInfo, dbTableInfo: &dbTableInfo)

                    if schemaStatus == .oldColumnsRemoved {

                        //  extra table columns than storage columns
                        try self.backup(table, connectionRef: connectionRef, columnsToIgnore: [])
                        res = .oldColumnsRemoved
                    }

                    if schemaStatus == .newColumnsAdded {
                        for columnToAdd in columnsToAdd {
                            try self.add(column: columnToAdd, table: table, connectionRef: connectionRef)
                        }
                        res = .newColumnsAdded
                    }

                    if schemaStatus == .newColumnsAddedAndOldColumnsRemoved {

                        // remove extra columns
                        try self.backup(table, connectionRef: connectionRef, columnsToIgnore: columnsToAdd)
                        res = .newColumnsAddedAndOldColumnsRemoved
                    }
                } else if schemaStatus == .droppedAndRecreated {
                    try self.dropTableInternal(tableName: table.name, connectionRef: connectionRef)
                    try self.create(tableWith: table.name, columns: table.columns, connectionRef: connectionRef)
                    res = .droppedAndRecreated
                }
            }
        }
        return res
    }

    @discardableResult
    public func syncSchema(preserve: Bool) throws -> [String: SyncSchemaResult] {
        let connectionRef = try ConnectionRef(connection: self.connection)

        var res = [String: SyncSchemaResult]()
        res.reserveCapacity(self.tables.count)
        for table in self.tables {
            let tableSyncResult = try self.sync(table, connectionRef: connectionRef, preserve: preserve)
            res[table.name] = tableSyncResult
        }

        return res
    }
}
