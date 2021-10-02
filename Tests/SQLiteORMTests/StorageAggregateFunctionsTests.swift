import XCTest
@testable import SQLiteORM

class StorageAggregateFunctionsTests: XCTestCase {
    struct AvgTest: Initializable {
        var value = Double(0)
        var unused = Double(0)
    }
    
    struct StructWithNullable: Initializable {
        var value: Int?
    }
    
    struct Unknown {
        var value = Double(0)
    };
    
    var storage: Storage!
    var storageWithNullable: Storage!
    var apiProvider: SQLiteApiProviderMock!
    let filename = ""
    
    override func setUpWithError() throws {
        self.apiProvider = .init()
        self.apiProvider.forwardsCalls = true
        self.storage = try Storage(filename: self.filename,
                                   apiProvider: self.apiProvider,
                                   tables: [Table<AvgTest>(name: "avg_test",
                                                           columns: Column(name: "value", keyPath: \AvgTest.value))])
        self.storageWithNullable = try Storage(filename: self.filename,
                                               apiProvider: self.apiProvider,
                                               tables: [Table<StructWithNullable>(name: "max_test", columns: Column(name: "value", keyPath: \StructWithNullable.value))])
    }
    
    override func tearDownWithError() throws {
        self.storage = nil
        self.apiProvider = nil
    }
    
    func testMin() throws {
        try testCase(#function, routine: {
            struct MinTest {
                var value: Int = 0
                var nullableValue: Int? = 0
                var unknown = 0
            }
            let apiProvider = SQLiteApiProviderMock()
            apiProvider.forwardsCalls = true
            let storage = try Storage(filename: "",
                                      apiProvider: apiProvider,
                                      tables: [Table<MinTest>(name: "min_test",
                                                              columns:
                                                                Column(name: "value", keyPath: \MinTest.value),
                                                                Column(name: "null_value", keyPath: \MinTest.nullableValue))])
            try storage.syncSchema(preserve: false)
            try section("error", routine: {
                try section("error notMappedType", routine: {
                    do {
                        _ = try storage.max(\Unknown.value)
                        XCTAssert(false)
                    }catch SQLiteORM.Error.typeIsNotMapped{
                        XCTAssert(true)
                    }catch{
                        XCTAssert(false)
                    }
                })
                try section("error columnNotFound", routine: {
                    do {
                        _ = try storage.max(\MinTest.unknown)
                        XCTAssert(false)
                    }catch SQLiteORM.Error.columnNotFound{
                        XCTAssert(true)
                    }catch{
                        XCTAssert(false)
                    }
                })
            })
            try section("no error", routine: {
                let db = storage.connection.dbMaybe!
                var expectedResult: Int?
                var result: Int?
                var expectedApiCalls = [SQLiteApiProviderMock.Call]()
                try section("not nullable field", routine: {
                    try section("no rows", routine: {
                        expectedResult = nil
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MIN(value) FROM min_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3Step(.ignore)),
                            .init(id: 5, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("1 row", routine: {
                        try storage.replace(object: MinTest(value: 10))
                        expectedResult = 10
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MIN(value) FROM min_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueInt(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("2 rows", routine: {
                        try storage.replace(object: MinTest(value: 4))
                        try storage.replace(object: MinTest(value: 6))
                        expectedResult = 4
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MIN(value) FROM min_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueInt(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    apiProvider.resetCalls()
                    result = try storage.min(\MinTest.value)
                    XCTAssertEqual(result, expectedResult)
                    XCTAssertEqual(apiProvider.calls, expectedApiCalls)
                })
                try section("nullable field", routine: {
                    try section("no rows", routine: {
                        expectedResult = nil
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MIN(null_value) FROM min_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3Step(.ignore)),
                            .init(id: 5, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("1 row", routine: {
                        try storage.replace(object: MinTest(value: 0, nullableValue: 10))
                        expectedResult = 10
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MIN(null_value) FROM min_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueInt(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("2 rows", routine: {
                        try storage.replace(object: MinTest(value: 0, nullableValue: 4))
                        try storage.replace(object: MinTest(value: 0, nullableValue: 6))
                        expectedResult = 4
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MIN(null_value) FROM min_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueInt(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    apiProvider.resetCalls()
                    result = try storage.min(\MinTest.nullableValue)
                    XCTAssertEqual(result, expectedResult)
                    XCTAssertEqual(apiProvider.calls, expectedApiCalls)
                })
            })
        })
    }
    
    func testMax() throws {
        try testCase(#function, routine: {
            struct MaxTest {
                var value: Int = 0
                var nullableValue: Int? = 0
                var unknown = 0
            }
            let apiProvider = SQLiteApiProviderMock()
            apiProvider.forwardsCalls = true
            let storage = try Storage(filename: "",
                                      apiProvider: apiProvider,
                                      tables: [Table<MaxTest>(name: "max_test",
                                                              columns:
                                                                Column(name: "value", keyPath: \MaxTest.value),
                                                                Column(name: "null_value", keyPath: \MaxTest.nullableValue))])
            try storage.syncSchema(preserve: false)
            try section("error", routine: {
                try section("error notMappedType", routine: {
                    do {
                        _ = try storage.max(\Unknown.value)
                        XCTAssert(false)
                    }catch SQLiteORM.Error.typeIsNotMapped{
                        XCTAssert(true)
                    }catch{
                        XCTAssert(false)
                    }
                })
                try section("error columnNotFound", routine: {
                    do {
                        _ = try storage.max(\MaxTest.unknown)
                        XCTAssert(false)
                    }catch SQLiteORM.Error.columnNotFound{
                        XCTAssert(true)
                    }catch{
                        XCTAssert(false)
                    }
                })
            })
            try section("no error", routine: {
                let db = storage.connection.dbMaybe!
                var expectedResult: Int?
                var result: Int?
                var expectedApiCalls = [SQLiteApiProviderMock.Call]()
                try section("not nullable field", routine: {
                    try section("no rows", routine: {
                        expectedResult = nil
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MAX(value) FROM max_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3Step(.ignore)),
                            .init(id: 5, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("1 row", routine: {
                        try storage.replace(object: MaxTest(value: 10))
                        expectedResult = 10
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MAX(value) FROM max_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueInt(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("2 rows", routine: {
                        try storage.replace(object: MaxTest(value: 4))
                        try storage.replace(object: MaxTest(value: 6))
                        expectedResult = 6
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MAX(value) FROM max_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueInt(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    apiProvider.resetCalls()
                    result = try storage.max(\MaxTest.value)
                    XCTAssertEqual(result, expectedResult)
                    XCTAssertEqual(apiProvider.calls, expectedApiCalls)
                })
                try section("nullable field", routine: {
                    try section("no rows", routine: {
                        expectedResult = nil
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MAX(null_value) FROM max_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3Step(.ignore)),
                            .init(id: 5, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("1 row", routine: {
                        try storage.replace(object: MaxTest(value: 0, nullableValue: 10))
                        expectedResult = 10
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MAX(null_value) FROM max_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueInt(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("2 rows", routine: {
                        try storage.replace(object: MaxTest(value: 0, nullableValue: 4))
                        try storage.replace(object: MaxTest(value: 0, nullableValue: 6))
                        expectedResult = 6
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT MAX(null_value) FROM max_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueInt(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    apiProvider.resetCalls()
                    result = try storage.max(\MaxTest.nullableValue)
                    XCTAssertEqual(result, expectedResult)
                    XCTAssertEqual(apiProvider.calls, expectedApiCalls)
                })
            })
        })
    }
    
    func testGroupConcat() throws {
        try testCase(#function, routine: {
            struct GroupConcatTest {
                var value = Int(0)
                var unknown = Int(0)
            }
            let apiProvider = SQLiteApiProviderMock()
            apiProvider.forwardsCalls = true
            let storage = try Storage(filename: "",
                                      apiProvider: apiProvider,
                                      tables: [Table<GroupConcatTest>(name: "group_concat_test",
                                                                      columns: Column(name: "value", keyPath: \GroupConcatTest.value, constraints: primaryKey()))])
            try storage.syncSchema(preserve: false)
            try section("error", routine: {
                try section("error notMappedType", routine: {
                    do {
                        _ = try storage.count(\Unknown.value)
                        XCTAssert(false)
                    }catch SQLiteORM.Error.typeIsNotMapped{
                        XCTAssert(true)
                    }catch{
                        XCTAssert(false)
                    }
                })
                try section("error columnNotFound", routine: {
                    do {
                        _ = try storage.count(\GroupConcatTest.unknown)
                        XCTAssert(false)
                    }catch SQLiteORM.Error.columnNotFound{
                        XCTAssert(true)
                    }catch{
                        XCTAssert(false)
                    }
                })
            })
            try section("no error", routine: {
                let db = storage.connection.dbMaybe!
                var expectedResult = [String?]()
                var result: String?
                var expectedApiCalls = [SQLiteApiProviderMock.Call]()
                try section("1 argument", routine: {
                    try section("no rows", routine: {
                        expectedResult = [nil]
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT GROUP_CONCAT(value) FROM group_concat_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3Step(.ignore)),
                            .init(id: 5, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("one row", routine: {
                        try storage.replace(object: GroupConcatTest(value: 1))
                        expectedResult = ["1"]
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT GROUP_CONCAT(value) FROM group_concat_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueText(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("two rows", routine: {
                        try storage.replace(object: GroupConcatTest(value: 3))
                        try storage.replace(object: GroupConcatTest(value: 5))
                        expectedResult = ["3,5", "5,3"]
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT GROUP_CONCAT(value) FROM group_concat_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueText(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    apiProvider.resetCalls()
                    result = try storage.groupConcat(\GroupConcatTest.value)
                })
                try section("2 arguments", routine: {
                    try section("no rows", routine: {
                        expectedResult = [nil]
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT GROUP_CONCAT(value, '-') FROM group_concat_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3Step(.ignore)),
                            .init(id: 5, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("one row", routine: {
                        try storage.replace(object: GroupConcatTest(value: 3))
                        expectedResult = ["3"]
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT GROUP_CONCAT(value, '-') FROM group_concat_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueText(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    try section("two rows", routine: {
                        try storage.replace(object: GroupConcatTest(value: 3))
                        try storage.replace(object: GroupConcatTest(value: 5))
                        expectedResult = ["3-5", "5-3"]
                        expectedApiCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT GROUP_CONCAT(value, '-') FROM group_concat_test", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                            .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                            .init(id: 4, callType: .sqlite3ValueText(.ignore)),
                            .init(id: 5, callType: .sqlite3Step(.ignore)),
                            .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    apiProvider.resetCalls()
                    result = try storage.groupConcat(\GroupConcatTest.value, separator: "-")
                })
                XCTAssert(expectedResult.contains(result))
                XCTAssertEqual(apiProvider.calls, expectedApiCalls)
            })
        })
    }
    
    func testCount() throws {
        struct CountTest: Initializable {
            var value: Double?
            var unknown: Double?
        }
        try testCase(#function, routine: {
            let apiProvider = SQLiteApiProviderMock()
            apiProvider.forwardsCalls = true
            let storage = try Storage(filename: "",
                                      apiProvider: apiProvider,
                                      tables: [Table<CountTest>(name: "count_test",
                                                                columns: Column(name: "value", keyPath: \CountTest.value))])
            try storage.syncSchema(preserve: false)
            try section("error", routine: {
                try section("notMappedType", routine: {
                    do {
                        _ = try storage.count(\Unknown.value)
                        XCTAssert(false)
                    }catch SQLiteORM.Error.typeIsNotMapped{
                        XCTAssert(true)
                    }catch{
                        XCTAssert(false)
                    }
                })
                try section("columnNotFound", routine: {
                    do {
                        _ = try storage.count(\CountTest.unknown)
                        XCTAssert(false)
                    }catch SQLiteORM.Error.columnNotFound{
                        XCTAssert(true)
                    }catch{
                        XCTAssert(false)
                    }
                })
            })
            try section("no error", routine: {
                let db = storage.connection.dbMaybe!
                var expectedCount = 0
                var expectedCalls = [SQLiteApiProviderMock.Call]()
                try section("no rows", routine: {
                    expectedCount = 0
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT COUNT(value) FROM count_test", -1, .ignore, nil)),
                        .init(id: 1, callType: .sqlite3Step(.ignore)),
                        .init(id: 2, callType: .sqlite3ColumnInt(.ignore, 0)),
                        .init(id: 3, callType: .sqlite3Step(.ignore)),
                        .init(id: 4, callType: .sqlite3Finalize(.ignore)),
                    ]
                })
                try section("one row with null", routine: {
                    try storage.replace(object: CountTest(value: nil))
                    expectedCount = 0
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT COUNT(value) FROM count_test", -1, .ignore, nil)),
                        .init(id: 1, callType: .sqlite3Step(.ignore)),
                        .init(id: 2, callType: .sqlite3ColumnInt(.ignore, 0)),
                        .init(id: 3, callType: .sqlite3Step(.ignore)),
                        .init(id: 4, callType: .sqlite3Finalize(.ignore)),
                    ]
                })
                try section("three rows without null", routine: {
                    try storage.replace(object: CountTest(value: 10))
                    try storage.replace(object: CountTest(value: 20))
                    try storage.replace(object: CountTest(value: 30))
                    expectedCount = 3
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT COUNT(value) FROM count_test", -1, .ignore, nil)),
                        .init(id: 1, callType: .sqlite3Step(.ignore)),
                        .init(id: 2, callType: .sqlite3ColumnInt(.ignore, 0)),
                        .init(id: 3, callType: .sqlite3Step(.ignore)),
                        .init(id: 4, callType: .sqlite3Finalize(.ignore)),
                    ]
                })
                apiProvider.resetCalls()
                let count = try storage.count(\CountTest.value)
                XCTAssertEqual(count, expectedCount)
                XCTAssertEqual(apiProvider.calls, expectedCalls)
            })
        })
    }
    
    func testCountAll() throws {
        struct CountTest: Initializable {
            var value = Double(0)
        }
        try testCase(#function, routine: {
            let apiProvider = SQLiteApiProviderMock()
            apiProvider.forwardsCalls = true
            let storage = try Storage(filename: "",
                                      apiProvider: apiProvider,
                                      tables: [Table<CountTest>(name: "count_test",
                                                                columns: Column(name: "value", keyPath: \CountTest.value))])
            try storage.syncSchema(preserve: false)
            try section("error notMapedType", routine: {
                do {
                    _ = try storage.count(all: Unknown.self)
                    XCTAssert(false)
                }catch SQLiteORM.Error.typeIsNotMapped{
                    XCTAssert(true)
                }catch{
                    XCTAssert(false)
                }
            })
            try section("no error", routine: {
                var expectedCount = 0
                var expectedCalls = [SQLiteApiProviderMock.Call]()
                let db = storage.connection.dbMaybe!
                try section("no rows", routine: {
                    expectedCount = 0
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT COUNT(*) FROM count_test", -1, .ignore, nil)),
                        .init(id: 1, callType: .sqlite3Step(.ignore)),
                        .init(id: 2, callType: .sqlite3ColumnInt(.ignore, 0)),
                        .init(id: 3, callType: .sqlite3Step(.ignore)),
                        .init(id: 4, callType: .sqlite3Finalize(.ignore)),
                    ]
                })
                try section("3 rows", routine: {
                    try storage.replace(object: CountTest(value: 1))
                    try storage.replace(object: CountTest(value: 2))
                    try storage.replace(object: CountTest(value: 3))
                    expectedCount = 3
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT COUNT(*) FROM count_test", -1, .ignore, nil)),
                        .init(id: 1, callType: .sqlite3Step(.ignore)),
                        .init(id: 2, callType: .sqlite3ColumnInt(.ignore, 0)),
                        .init(id: 3, callType: .sqlite3Step(.ignore)),
                        .init(id: 4, callType: .sqlite3Finalize(.ignore)),
                    ]
                })
                apiProvider.resetCalls()
                let count = try storage.count(all: CountTest.self)
                XCTAssertEqual(count, expectedCount)
                XCTAssertEqual(apiProvider.calls, expectedCalls)
            })
        })
    }
    
    func testAvg() throws {
        try testCase(#function) {
            let apiProvider = SQLiteApiProviderMock()
            apiProvider.forwardsCalls = true
            let storage = try Storage(filename: "",
                                      apiProvider: apiProvider,
                                      tables: [Table<AvgTest>(name: "avg_test",
                                                              columns: Column(name: "value", keyPath: \AvgTest.value))])
            try storage.syncSchema(preserve: false)
            try section("error") {
                try section("columnNotFound") {
                    do {
                        _ = try storage.avg(\AvgTest.unused)
                        XCTAssert(false)
                    }catch SQLiteORM.Error.columnNotFound{
                        XCTAssert(true)
                    }catch{
                        XCTAssert(false)
                    }
                }
                try section("notMapedType") {
                    do {
                        _ = try storage.avg(\Unknown.value)
                        XCTAssert(false)
                    }catch SQLiteORM.Error.typeIsNotMapped{
                        XCTAssert(true)
                    }catch{
                        XCTAssert(false)
                    }
                }
            }
            try section("no error") {
                let db = storage.connection.dbMaybe!
                var expectedCalls = [SQLiteApiProviderMock.Call]()
                var expectedResult: Double? = nil
                try section("insert nothing") {
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT AVG(value) FROM avg_test", -1, .ignore, nil)),
                        .init(id: 1, callType: .sqlite3Step(.ignore)),
                        .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                        .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                        .init(id: 4, callType: .sqlite3Step(.ignore)),
                        .init(id: 5, callType: .sqlite3Finalize(.ignore)),
                    ]
                    expectedResult = nil
                }
                try section("insert something", routine: {
                    try storage.replace(object: AvgTest(value: 1))
                    try storage.replace(object: AvgTest(value: 4))
                    try storage.replace(object: AvgTest(value: 10))
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3PrepareV2(db, "SELECT AVG(value) FROM avg_test", -1, .ignore, nil)),
                        .init(id: 1, callType: .sqlite3Step(.ignore)),
                        .init(id: 2, callType: .sqlite3ColumnValue(.ignore, 0)),
                        .init(id: 3, callType: .sqlite3ValueType(.ignore)),
                        .init(id: 4, callType: .sqlite3ValueDouble(.ignore)),
                        .init(id: 5, callType: .sqlite3Step(.ignore)),
                        .init(id: 6, callType: .sqlite3Finalize(.ignore)),
                    ]
                    expectedResult = Double(1 + 4 + 10) / 3
                })
                apiProvider.resetCalls()
                let avgValue = try storage.avg(\AvgTest.value)
                XCTAssertEqual(avgValue, expectedResult)
                XCTAssertEqual(apiProvider.calls, expectedCalls)
            }
        }
    }
}
