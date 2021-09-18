import Foundation

public class Table<T>: AnyTable {
    
    override var type: Any.Type {
        return T.self
    }
    
    func bindNonPrimaryKey(statement: Binder, object: T, apiProvider: SQLiteApiProvider) throws -> Int32 {
        var resultCode = Int32(0)
        var columnIndex = 0
        for anyColumn in self.columns {
            if !anyColumn.isPrimaryKey {
                let columnBinder = ColumnBinderImpl(columnIndex: columnIndex + 1, binder: statement)
                resultCode = try anyColumn.bind(columnBinder: columnBinder, object: object)
                columnIndex += 1
                if apiProvider.SQLITE_OK != resultCode {
                    break
                }
            }
        }
        return resultCode
    }
    
    func bind(statement: Binder, object: T, apiProvider: SQLiteApiProvider) throws -> Int32 {
        var resultCode = Int32(0)
        for (columnIndex, anyColumn) in self.columns.enumerated() {
            let columnBinder = ColumnBinderImpl(columnIndex: columnIndex + 1, binder: statement)
            resultCode = try anyColumn.bind(columnBinder: columnBinder, object: object)
            if apiProvider.SQLITE_OK != resultCode {
                break
            }
        }
        return resultCode
    }
}