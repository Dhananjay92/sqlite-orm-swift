import Foundation
@testable import SQLiteORM

enum SQLiteApiProviderCallType {
    case sqlite3Open(_ filename: String, _ ppDb: Ignorable<UnsafeMutablePointer<OpaquePointer?>>)
    case sqlite3Errmsg(_ ppDb: OpaquePointer!)
    case sqlite3Close(_ ppDb: Ignorable<OpaquePointer>)
    case sqlite3LastInsertRowid(_ ppDb: Ignorable<OpaquePointer>)
    case sqlite3PrepareV2(_ db: Ignorable<OpaquePointer>,
                          _ zSql: String,
                          _ nByte: Int32,
                          _ ppStmt: Ignorable<UnsafeMutablePointer<OpaquePointer?>>,
                          _ pzTail: UnsafeMutablePointer<UnsafePointer<CChar>?>!)
    case sqlite3Exec(_ db: OpaquePointer!,
                     _ sql: String,
                     _ callback: SQLiteApiProvider.ExecCallback!,
                     _ data: UnsafeMutableRawPointer!,
                     _ errmsg: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!)
    case sqlite3Finalize(_ pStmt: Ignorable<OpaquePointer>)
    case sqlite3Step(_ pStmt: Ignorable<OpaquePointer>)
    case sqlite3ColumnCount(_ pStmt: Ignorable<OpaquePointer>)
    case sqlite3ColumnValue(_ pStmt: Ignorable<OpaquePointer>, _ iCol: Int32)
    case sqlite3ColumnText(_ pStmt: Ignorable<OpaquePointer>, _ iCol: Int32)
    case sqlite3ColumnType(_ pStmt: OpaquePointer!, _ iCol: Int32)
    case sqlite3ColumnInt(_ pStmt: Ignorable<OpaquePointer>, _ iCol: Int32)
    case sqlite3ColumnDouble(_ pStmt: Ignorable<OpaquePointer>, _ iCol: Int32)
    case sqlite3BindText(_ pStmt: Ignorable<OpaquePointer>,
                         _ idx: Int32,
                         _ value: String,
                         _ len: Int32,
                         _ dtor: (@convention(c) (UnsafeMutableRawPointer?) -> Void)!)
    case sqlite3BindInt(_ pStmt: OpaquePointer!, _ idx: Int32, _ value: Int32)
    case sqlite3BindDouble(_ pStmt: OpaquePointer!, _ idx: Int32, _ value: Double)
    case sqlite3BindNull(_ pStmt: OpaquePointer!, _ idx: Int32)
    case sqlite3ValueInt(_ value: Ignorable<OpaquePointer>)
    case sqlite3ValueText(_ value: Ignorable<OpaquePointer>)
    case sqlite3ValueType(_ value: Ignorable<OpaquePointer>)
    case sqlite3ValueDouble(_ value: Ignorable<OpaquePointer>)
}

extension SQLiteApiProviderCallType: Equatable {

    static func compareDtors<T>(_ lhs: T!,
                                _ rhs: T!) -> Bool {
        return (lhs == nil) == (rhs == nil)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.sqlite3ValueType(leftValue), .sqlite3ValueType(rightValue)):
            return leftValue == rightValue
        case let (.sqlite3Open(leftFilename, leftDbPointer), .sqlite3Open(rightFilename, rightDbPointer)):
            return (strcmp(leftFilename, rightFilename) == 0) && leftDbPointer == rightDbPointer
        case let (.sqlite3Errmsg(leftDb), .sqlite3Errmsg(rightDb)):
            return leftDb == rightDb
        case let (.sqlite3Close(leftDb), .sqlite3Close(rightDb)):
            return leftDb == rightDb
        case let (.sqlite3LastInsertRowid(leftDb), .sqlite3LastInsertRowid(rightDb)):
            return leftDb == rightDb
        case let (.sqlite3PrepareV2(leftDb, leftZSql, leftNByte, leftPPStmt, leftPZTail),
                  .sqlite3PrepareV2(rightDb, rightZSql, rightNByte, rightPPStmt, rightPZTail)):
            return leftDb == rightDb && (strcmp(leftZSql, rightZSql) == 0) && leftNByte == rightNByte
                && leftPPStmt == rightPPStmt
                && leftPZTail == rightPZTail
        case let (.sqlite3Exec(leftDb, leftSql, leftCallback, leftData, leftErrmg),
                  .sqlite3Exec(rightDb, rightSql, rightCallback, rightData, rightErrmg)):
            return leftDb == rightDb && (strcmp(leftSql, rightSql) == 0) && self.compareDtors(leftCallback, rightCallback)
                && leftData == rightData
                && leftErrmg == rightErrmg
        case let (.sqlite3Finalize(leftPStmt), .sqlite3Finalize(rightPStmt)):
            return leftPStmt == rightPStmt
        case let (.sqlite3Step(leftPStmt), .sqlite3Step(rightPStmt)):
            return leftPStmt == rightPStmt
        case let (.sqlite3ColumnCount(leftPStmt), .sqlite3ColumnCount(rightPStmt)):
            return leftPStmt == rightPStmt
        case let (.sqlite3ColumnValue(leftPStmt, leftICol), .sqlite3ColumnValue(rightPStmt, rightICol)):
            return leftPStmt == rightPStmt && leftICol == rightICol
        case let (.sqlite3ColumnText(leftPStmt, leftICol), .sqlite3ColumnText(rightPStmt, rightICol)):
            return leftPStmt == rightPStmt && leftICol == rightICol
        case let (.sqlite3ColumnType(leftPStmt, leftICol), .sqlite3ColumnType(rightPStmt, rightICol)):
            return leftPStmt == rightPStmt && leftICol == rightICol
        case let (.sqlite3ColumnInt(leftPStmt, leftICol), .sqlite3ColumnInt(rightPStmt, rightICol)):
            return leftPStmt == rightPStmt && leftICol == rightICol
        case let (.sqlite3ColumnDouble(leftPStmt, leftICol), .sqlite3ColumnDouble(rightPStmt, rightICol)):
            return leftPStmt == rightPStmt && leftICol == rightICol
        case let (.sqlite3BindText(leftPStmt, leftIdx, leftValue, leftLen, leftDtor),
                  .sqlite3BindText(rightPStmt, rightIdx, rightValue, rightLen, rightDtor)):
            return leftPStmt == rightPStmt && leftIdx == rightIdx && (strcmp(leftValue, rightValue) == 0)
                && leftLen == rightLen
                && self.compareDtors(leftDtor, rightDtor)
        case let (.sqlite3BindInt(leftStmt, leftIdx, leftValue), .sqlite3BindInt(rightStmt, rightIdx, rightValue)):
            return leftStmt == rightStmt && leftIdx == rightIdx && leftValue == rightValue
        case let (.sqlite3BindDouble(leftStmt, leftIdx, leftValue), .sqlite3BindDouble(rightStmt, rightIdx, rightValue)):
            return leftStmt == rightStmt && leftIdx == rightIdx && leftValue == rightValue
        case let (.sqlite3ValueInt(leftValue), .sqlite3ValueInt(rightValue)):
            return leftValue == rightValue
        case let (.sqlite3ValueText(leftValue), .sqlite3ValueText(rightValue)):
            return leftValue == rightValue
        case let (.sqlite3ValueDouble(leftValue), .sqlite3ValueDouble(rightValue)):
            return leftValue == rightValue
        default:
            return false
        }
    }
}
