import XCTest
@testable import SQLiteORM

class StorageNonCrudTests: XCTestCase {
    struct User: Initializable, Equatable {
        var id = 0
        var name = ""
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.id == rhs.id && lhs.name == rhs.name
        }
    }
    
    struct Visit: Initializable {
        var id = 0
    }
    
    func testGetAll() throws {
        try testCase(#function, routine: {
            let apiProvider = SQLiteApiProviderMock()
            apiProvider.forwardsCalls = true
            let createStorage = { (filename: String) throws -> Storage in
                let storage = try Storage(filename: filename,
                                          apiProvider: apiProvider,
                                          tables: [Table<User>(name: "users",
                                                               columns:
                                                                Column(name: "id", keyPath: \User.id, constraints: primaryKey(), notNull()),
                                                               Column(name: "name", keyPath: \User.name, constraints: notNull()))])
                try storage.syncSchema(preserve: false)
                return storage
            }
            try section("error", routine: {
                let storage = try createStorage("")
                do {
                    let visits: [Visit] = try storage.getAll()
                    XCTAssert(false)
                    _ = visits
                }catch SQLiteORM.Error.typeIsNotMapped {
                    XCTAssert(true)
                }catch{
                    XCTAssert(false)
                }
            })
            try section("no error", routine: {
                var inMemory = false
                try section("file", routine: {
                    inMemory = false
                })
                try section("memory", routine: {
                    inMemory = true
                })
                let filename = inMemory ? "" : "db.sqlite"
                if !inMemory {
                    remove(filename)
                }
                let storage = try createStorage(filename)
                var expectedCalls = [SQLiteApiProviderMock.Call]()
                if inMemory {
                    let db = storage.connection.dbMaybe!
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3PrepareV2(.value(db), "SELECT * FROM users", -1, .ignore, nil)),
                        .init(id: 1, callType: .sqlite3Step(.ignore)),
                        .init(id: 2, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 3, callType: .sqlite3Finalize(.ignore)),
                    ]
                }else{
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3Open(filename, .ignore)),
                        .init(id: 1, callType: .sqlite3PrepareV2(.ignore, "SELECT * FROM users", -1, .ignore, nil)),
                        .init(id: 2, callType: .sqlite3Step(.ignore)),
                        .init(id: 3, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 4, callType: .sqlite3Finalize(.ignore)),
                        .init(id: 5, callType: .sqlite3Close(.ignore)),
                    ]
                }
                apiProvider.resetCalls()
                var users: [User] = try storage.getAll()
                XCTAssertEqual(apiProvider.calls, expectedCalls)
                XCTAssertEqual(users, [])
                
                try storage.replace(User(id: 3, name: "Ted"))
                if inMemory {
                    let db = storage.connection.dbMaybe!
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3PrepareV2(.value(db), "SELECT * FROM users", -1, .ignore, nil)),
                        .init(id: 1, callType: .sqlite3Step(.ignore)),
                        .init(id: 2, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 3, callType: .sqlite3ColumnInt(.ignore, 0)),
                        .init(id: 4, callType: .sqlite3ColumnText(.ignore, 1)),
                        .init(id: 5, callType: .sqlite3Step(.ignore)),
                        .init(id: 6, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 7, callType: .sqlite3Finalize(.ignore)),
                    ]
                }else{
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3Open(filename, .ignore)),
                        .init(id: 1, callType: .sqlite3PrepareV2(.ignore, "SELECT * FROM users", -1, .ignore, nil)),
                        .init(id: 2, callType: .sqlite3Step(.ignore)),
                        .init(id: 3, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 4, callType: .sqlite3ColumnInt(.ignore, 0)),
                        .init(id: 5, callType: .sqlite3ColumnText(.ignore, 1)),
                        .init(id: 6, callType: .sqlite3Step(.ignore)),
                        .init(id: 7, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 8, callType: .sqlite3Finalize(.ignore)),
                        .init(id: 9, callType: .sqlite3Close(.ignore)),
                    ]
                }
                apiProvider.resetCalls()
                users = try storage.getAll()
                XCTAssertEqual(apiProvider.calls, expectedCalls)
                XCTAssertEqual(users, [User(id: 3, name: "Ted")])
                
                apiProvider.resetCalls()
                if inMemory {
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3PrepareV2(.ignore, "SELECT * FROM users WHERE users.id == 5", -1, .ignore, nil)),
                        .init(id: 1, callType: .sqlite3Step(.ignore)),
                        .init(id: 2, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 3, callType: .sqlite3Finalize(.ignore)),
                    ]
                }else{
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3Open(filename, .ignore)),
                        .init(id: 1, callType: .sqlite3PrepareV2(.ignore, "SELECT * FROM users WHERE users.id == 5", -1, .ignore, nil)),
                        .init(id: 2, callType: .sqlite3Step(.ignore)),
                        .init(id: 3, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 4, callType: .sqlite3Finalize(.ignore)),
                        .init(id: 5, callType: .sqlite3Close(.ignore)),
                    ]
                }
                users = try storage.getAll(where_(equal(lhs: \User.id, rhs: 5)))
                XCTAssertEqual(apiProvider.calls, expectedCalls)
                XCTAssertEqual(users, [])
                
                apiProvider.resetCalls()
                if inMemory {
                    let db = storage.connection.dbMaybe!
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3PrepareV2(.value(db), "SELECT * FROM users WHERE users.id == 3", -1, .ignore, nil)),
                        .init(id: 1, callType: .sqlite3Step(.ignore)),
                        .init(id: 2, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 3, callType: .sqlite3ColumnInt(.ignore, 0)),
                        .init(id: 4, callType: .sqlite3ColumnText(.ignore, 1)),
                        .init(id: 5, callType: .sqlite3Step(.ignore)),
                        .init(id: 6, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 7, callType: .sqlite3Finalize(.ignore)),
                    ]
                }else{
                    expectedCalls = [
                        .init(id: 0, callType: .sqlite3Open(filename, .ignore)),
                        .init(id: 1, callType: .sqlite3PrepareV2(.ignore, "SELECT * FROM users WHERE users.id == 3", -1, .ignore, nil)),
                        .init(id: 2, callType: .sqlite3Step(.ignore)),
                        .init(id: 3, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 4, callType: .sqlite3ColumnInt(.ignore, 0)),
                        .init(id: 5, callType: .sqlite3ColumnText(.ignore, 1)),
                        .init(id: 6, callType: .sqlite3Step(.ignore)),
                        .init(id: 7, callType: .sqlite3ColumnCount(.ignore)),
                        .init(id: 8, callType: .sqlite3Finalize(.ignore)),
                        .init(id: 9, callType: .sqlite3Close(.ignore)),
                    ]
                }
                apiProvider.resetCalls()
                users = try storage.getAll(where_(equal(lhs: \User.id, rhs: 3)))
                XCTAssertEqual(apiProvider.calls, expectedCalls)
                XCTAssertEqual(users, [User(id: 3, name: "Ted")])
            })
        })
    }
    
    func testDeleteAll() throws {
        try testCase(#function, routine: {
            let apiProvider = SQLiteApiProviderMock()
            apiProvider.forwardsCalls = true
            let createStorage = { (filename: String) throws -> Storage in
                let storage = try Storage(filename: filename,
                                          apiProvider: apiProvider,
                                          tables: [Table<User>(name: "users",
                                                               columns:
                                                                Column(name: "id", keyPath: \User.id, constraints: primaryKey(), notNull()),
                                                               Column(name: "name", keyPath: \User.name, constraints: notNull()))])
                try storage.syncSchema(preserve: false)
                return storage
            }
            try section("error", routine: {
                let storage = try createStorage("")
                do {
                    try storage.delete(all: Visit.self)
                    XCTAssert(false)
                }catch SQLiteORM.Error.typeIsNotMapped {
                    XCTAssert(true)
                }catch{
                    XCTAssert(false)
                }
            })
            try section("no error", routine: {
                var expectedCalls = [SQLiteApiProviderMock.Call]()
                var sqliteCalls = [SQLiteApiProviderMock.Call]()
                try section("no conditions", routine: {
                    var filename = ""
                    try section("file", routine: {
                        filename = "db.sqlite"
                        remove(filename)
                        expectedCalls = [
                            .init(id: 0, callType: .sqlite3Open(filename, .ignore)),
                            .init(id: 1, callType: .sqlite3PrepareV2(.ignore, "DELETE FROM users", -1, .ignore, nil)),
                            .init(id: 2, callType: .sqlite3Step(.ignore)),
                            .init(id: 3, callType: .sqlite3Finalize(.ignore)),
                            .init(id: 4, callType: .sqlite3Close(.ignore)),
                        ]
                    })
                    try section("memory", routine: {
                        expectedCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(.ignore, "DELETE FROM users", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    let storage = try createStorage(filename)
                    try storage.syncSchema(preserve: false)
                    apiProvider.resetCalls()
                    try storage.delete(all: User.self)
                    sqliteCalls = apiProvider.calls
                })
                try section("with conditions", routine: {
                    var filename = ""
                    try section("file", routine: {
                        filename = "db.sqlite"
                        remove(filename)
                        expectedCalls = [
                            .init(id: 0, callType: .sqlite3Open(filename, .ignore)),
                            .init(id: 1, callType: .sqlite3PrepareV2(.ignore, "DELETE FROM users WHERE users.id < 10", -1, .ignore, nil)),
                            .init(id: 2, callType: .sqlite3Step(.ignore)),
                            .init(id: 3, callType: .sqlite3Finalize(.ignore)),
                            .init(id: 4, callType: .sqlite3Close(.ignore)),
                        ]
                    })
                    try section("memory", routine: {
                        expectedCalls = [
                            .init(id: 0, callType: .sqlite3PrepareV2(.ignore, "DELETE FROM users WHERE users.id < 10", -1, .ignore, nil)),
                            .init(id: 1, callType: .sqlite3Step(.ignore)),
                            .init(id: 2, callType: .sqlite3Finalize(.ignore)),
                        ]
                    })
                    let storage = try createStorage(filename)
                    try storage.syncSchema(preserve: false)
                    apiProvider.resetCalls()
                    try storage.delete(all: User.self, where_(lesserThan(lhs: \User.id, rhs: 10)))
                    sqliteCalls = apiProvider.calls
                })
                XCTAssertEqual(sqliteCalls, expectedCalls)
            })
        })
    }
}