/// :nodoc:
extension SQLInterpolation {
    
    // MARK: - TableRecord
    
    /// Appends the table name of the record type.
    ///
    ///     // SELECT * FROM player
    ///     let request: SQLRequest<Player> = "SELECT * FROM \(Player.self)"
    public mutating func appendInterpolation<T>(_ table: T.Type)
        where T: TableRecord
    {
        appendLiteral(table.databaseTableName.quotedDatabaseIdentifier)
    }
    
    /// Appends the table name of the record type.
    ///
    ///     // SELECT * FROM player
    ///     let request: SQLRequest<Player> = "SELECT * FROM \(Player.self)"
    @_disfavoredOverload
    public mutating func appendInterpolation(_ table: TableRecord.Type) {
        appendLiteral(table.databaseTableName.quotedDatabaseIdentifier)
    }
    
    /// Appends the table name of the record.
    ///
    ///     // INSERT INTO player ...
    ///     let player: Player = ...
    ///     let request: SQLRequest<Player> = "INSERT INTO \(tableOf: player) ..."
    public mutating func appendInterpolation<T>(tableOf record: T)
        where T: TableRecord
    {
        appendInterpolation(type(of: record))
    }
    
    /// Appends the table name of the record.
    ///
    ///     // INSERT INTO player ...
    ///     let player: Player = ...
    ///     let request: SQLRequest<Player> = "INSERT INTO \(tableOf: player) ..."
    @_disfavoredOverload
    public mutating func appendInterpolation(tableOf record: TableRecord) {
        appendInterpolation(type(of: record))
    }
    
    /// Appends the selection of the record type.
    ///
    ///     // SELECT * FROM player
    ///     let player: Player = ...
    ///     let request: SQLRequest<Player> = "SELECT \(columnsOf: Player.self) FROM player"
    ///
    ///     // SELECT p.* FROM player p
    ///     let player: Player = ...
    ///     let request: SQLRequest<Player> = "SELECT \(columnsOf: Player.self, tableAlias: "p") FROM player p"
    public mutating func appendInterpolation<T>(columnsOf record: T.Type, tableAlias: String? = nil)
        where T: TableRecord
    {
        let alias = TableAlias(name: tableAlias ?? T.databaseTableName)
        elements.append(contentsOf: T.databaseSelection
            .map { CollectionOfOne(.selectable($0.qualifiedSelectable(with: alias))) }
            .joined(separator: CollectionOfOne(.sql(", "))))
    }
    
    // MARK: - SQLSelectable
    
    /// Appends the selectable SQL.
    ///
    ///     // SELECT * FROM player
    ///     let request: SQLRequest<Player> = """
    ///         SELECT \(AllColumns()) FROM player
    ///         """
    public mutating func appendInterpolation<T>(_ selection: T)
        where T: SQLSelectable
    {
        elements.append(.selectable(selection))
    }
    
    /// Appends the selectable SQL, or NULL if it is nil.
    ///
    ///     // SELECT * FROM player
    ///     let request: SQLRequest<Player> = """
    ///         SELECT \(AllColumns()) FROM player
    ///         """
    @_disfavoredOverload
    public mutating func appendInterpolation(_ selection: SQLSelectable?) {
        if let selection = selection {
            elements.append(.selectable(selection))
        } else {
            appendLiteral("NULL")
        }
    }
    
    // MARK: - SQLOrderingTerm
    
    /// Appends the ordering SQL.
    ///
    ///     // SELECT name FROM player ORDER BY name DESC
    ///     let request: SQLRequest<Player> = """
    ///         SELECT * FROM player ORDER BY \(Column("name").desc)
    ///         """
    public mutating func appendInterpolation<T>(_ orderingTerm: T)
        where T: SQLOrderingTerm
    {
        elements.append(.orderingTerm(orderingTerm))
    }
    
    /// Appends the ordering SQL.
    ///
    ///     // SELECT name FROM player ORDER BY name DESC
    ///     let request: SQLRequest<Player> = """
    ///         SELECT * FROM player ORDER BY \(Column("name").desc)
    ///         """
    @_disfavoredOverload
    public mutating func appendInterpolation(_ orderingTerm: SQLOrderingTerm) {
        elements.append(.orderingTerm(orderingTerm))
    }

    // MARK: - SQLExpressible
    
    /// Appends the expression SQL.
    ///
    ///     // SELECT name FROM player
    ///     let request: SQLRequest<String> = """
    ///         SELECT \(Column("name")) FROM player
    ///         """
    public mutating func appendInterpolation<T>(_ expressible: T)
        where T: SQLExpressible
    {
        elements.append(.expression(expressible.sqlExpression))
    }
    
    /// Appends the expression SQL.
    ///
    ///     // SELECT name FROM player
    ///     let request: SQLRequest<String> = """
    ///         SELECT \(Column("name")) FROM player
    ///         """
    public mutating func appendInterpolation<T>(_ expressible: T)
        where T: SQLExpressible & SQLSelectable & SQLOrderingTerm
    {
        elements.append(.expression(expressible.sqlExpression))
    }
    
    /// Appends the expression SQL, or NULL if it is nil.
    ///
    ///     // SELECT name FROM player
    ///     let request: SQLRequest<String> = """
    ///         SELECT \(Column("name")) FROM player
    ///         """
    @_disfavoredOverload
    public mutating func appendInterpolation(_ expressible: SQLExpressible?) {
        if let expressible = expressible {
            elements.append(.expression(expressible.sqlExpression))
        } else {
            appendLiteral("NULL")
        }
    }
    
    // MARK: - CodingKey
    
    /// Appends the name of the coding key.
    ///
    ///     // SELECT name FROM player
    ///     let request: SQLRequest<String> = "
    ///         SELECT \(CodingKey.name) FROM player
    ///         """
    public mutating func appendInterpolation<T>(_ key: T)
        where T: CodingKey
    {
        appendInterpolation(Column(key.stringValue))
    }
    
    /// Appends the name of the coding key.
    ///
    ///     // SELECT name FROM player
    ///     let request: SQLRequest<String> = "
    ///         SELECT \(CodingKey.name) FROM player
    ///         """
    public mutating func appendInterpolation<T>(_ key: T)
        where T: CodingKey & SQLExpressible & SQLSelectable & SQLOrderingTerm
    {
        appendInterpolation(Column(key.stringValue))
    }
    
    /// Appends the name of the coding key.
    ///
    ///     // SELECT name FROM player
    ///     let request: SQLRequest<String> = "
    ///         SELECT \(CodingKey.name) FROM player
    ///         """
    @_disfavoredOverload
    public mutating func appendInterpolation(_ key: CodingKey) {
        appendInterpolation(Column(key.stringValue))
    }
    
    // MARK: - SQLRequestProtocol
    
    /// Appends the request SQL (not wrapped inside parentheses).
    ///
    ///     let subquery = Player.select(max(Column("score")))
    ///     // or
    ///     let subQuery: SQLRequest<Int> = "SELECT MAX(score) FROM player"
    ///
    ///     // SELECT name FROM player WHERE score = (SELECT MAX(score) FROM player)
    ///     let request: SQLRequest<Player> = """
    ///         SELECT * FROM player WHERE score = (\(subquery))
    ///         """
    public mutating func appendInterpolation<T>(_ request: T)
        where T: SQLRequestProtocol
    {
        elements.append(.subquery(request))
    }
    
    /// Appends the request SQL (not wrapped inside parentheses).
    ///
    ///     let subquery = Player.select(max(Column("score")))
    ///     // or
    ///     let subQuery: SQLRequest<Int> = "SELECT MAX(score) FROM player"
    ///
    ///     // SELECT name FROM player WHERE score = (SELECT MAX(score) FROM player)
    ///     let request: SQLRequest<Player> = """
    ///         SELECT * FROM player WHERE score = (\(subquery))
    ///         """
    @_disfavoredOverload
    public mutating func appendInterpolation(_ request: SQLRequestProtocol) {
        elements.append(.subquery(request))
    }
    
    // MARK: - Sequence
    
    /// Appends a sequence of expressions, wrapped in parentheses.
    ///
    ///     // SELECT * FROM player WHERE id IN (?,?,?)
    ///     let ids = [1, 2, 3]
    ///     let request: SQLRequest<Player> = """
    ///         SELECT * FROM player WHERE id IN \(ids)
    ///         """
    ///
    /// If the sequence is empty, an empty subquery is appended:
    ///
    ///     // SELECT * FROM player WHERE id IN (SELECT NULL WHERE NULL)
    ///     let ids: [Int] = []
    ///     let request: SQLRequest<Player> = """
    ///         SELECT * FROM player WHERE id IN \(ids)
    ///         """
    public mutating func appendInterpolation<T>(_ sequence: T)
        where T: Sequence, T.Element: SQLExpressible
    {
        appendInterpolation(sequence.lazy.map(\.sqlExpression))
    }
    
    /// Appends a sequence of expressions, wrapped in parentheses.
    ///
    ///     // SELECT * FROM player WHERE a IN (b, c + 2)
    ///     let expressions = [Column("b"), Column("c") + 2]
    ///     let request: SQLRequest<Player> = """
    ///         SELECT * FROM player WHERE a IN \(expressions)
    ///         """
    ///
    /// If the sequence is empty, an empty subquery is appended:
    ///
    ///     // SELECT * FROM player WHERE a IN (SELECT NULL WHERE NULL)
    ///     let expressions: [SQLExpression] = []
    ///     let request: SQLRequest<Player> = """
    ///         SELECT * FROM player WHERE a IN \(expressions)
    ///         """
    public mutating func appendInterpolation<T>(_ sequence: T)
        where T: Sequence, T.Element == SQLExpression
    {
        let e: [SQLLiteral.Element] = sequence.map { .expression($0.sqlExpression) }
        if e.isEmpty {
            appendLiteral("(SELECT NULL WHERE NULL)")
        } else {
            appendLiteral("(")
            elements.append(contentsOf: e.map(CollectionOfOne.init(_:)).joined(separator: CollectionOfOne(.sql(","))))
            appendLiteral(")")
        }
    }
    
    // When a value is both an expression and a sequence of expressions,
    // favor the expression side. Use case: Foundation.Data interpolation.
    /// :nodoc:
    public mutating func appendInterpolation<T>(_ expressible: T)
        where T: Sequence, T: SQLExpressible, T.Element: SQLExpressible
    {
        elements.append(.expression(expressible.sqlExpression))
    }
}
