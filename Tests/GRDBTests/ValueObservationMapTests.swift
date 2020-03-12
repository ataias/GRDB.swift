import XCTest
#if GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    #if SWIFT_PACKAGE
        import CSQLite
    #else
        import SQLite3
    #endif
    import GRDB
#endif

class ValueObservationMapTests: GRDBTestCase {
    func testMap() throws {
        func test(_ dbWriter: DatabaseWriter) throws {
            // We need something to change
            try dbWriter.write { try $0.execute(sql: "CREATE TABLE t(id INTEGER PRIMARY KEY AUTOINCREMENT)") }
            
            var counts: [String] = []
            let notificationExpectation = expectation(description: "notification")
            notificationExpectation.assertForOverFulfill = true
            notificationExpectation.expectedFulfillmentCount = 3
            
            // Create an observation
            var count = 0
            let observation = ValueObservation
                .tracking(DatabaseRegion.fullDatabase, fetch: { _ -> Int in
                    count += 1
                    return count
                })
                .map { count -> String in return "\(count)" }
            
            // Start observation
            let observer = observation.start(
                in: dbWriter,
                onError: { error in XCTFail("Unexpected error: \(error)") },
                onChange: { count in
                    counts.append(count)
                    notificationExpectation.fulfill()
            })
            try withExtendedLifetime(observer) {
                try dbWriter.writeWithoutTransaction { db in
                    try db.execute(sql: "INSERT INTO t DEFAULT VALUES")
                    try db.execute(sql: "INSERT INTO t DEFAULT VALUES")
                }
                
                waitForExpectations(timeout: 1, handler: nil)
                XCTAssertEqual(counts, ["1", "2", "3"])
            }
        }
        
        try test(makeDatabaseQueue())
        try test(makeDatabasePool())
    }
    
    func testMapPreservesConfiguration() {
        var observation = ValueObservation.tracking(DatabaseRegion(), fetch: { _ in })
        observation.requiresWriteAccess = true
        observation.scheduling = .unsafe
        
        let mappedObservation = observation.map { _ in }
        XCTAssertEqual(mappedObservation.requiresWriteAccess, observation.requiresWriteAccess)
        switch mappedObservation.scheduling {
        case .unsafe:
            break
        default:
            XCTFail()
        }
    }
}