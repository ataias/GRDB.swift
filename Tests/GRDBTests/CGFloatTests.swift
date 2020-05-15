import XCTest
#if os(Linux)
import Foundation
#else
import CoreGraphics
#endif
import GRDB

class CGFloatTests: GRDBTestCase {
    

    func testCGFLoat() throws {
	#if os(Linux)
	// nothing
	#else
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.execute(sql: "CREATE TABLE points (x DOUBLE, y DOUBLE)")
            
            let x: CGFloat = 1
            let y: CGFloat? = nil
            try db.execute(sql: "INSERT INTO points VALUES (?,?)", arguments: [x, y])
            
            let row = try Row.fetchOne(db, sql: "SELECT * FROM points")!
            let fetchedX: CGFloat = row["x"]
            let fetchedY: CGFloat? = row["y"]
            XCTAssertEqual(x, fetchedX)
            XCTAssertTrue(fetchedY == nil)
        }
	#endif
    }
}
