//
//  ConnectionPool.swift
//  SwiftKnex
//
//  Created by Yuki Takei on 2017/01/12.
//
//

import Foundation

public enum ConnectionPoolError: Error {
    case failedToGetConnectionFromPool
}

public final class ConnectionPool: ConnectionType {
    public let url: URL
    public let user: String
    public let password: String?
    public let database: String?
    public let minPoolSize: UInt
    public let maxPoolSize: UInt
    
    var connections: [Connection]
    
    public var pooledConnectionCount: Int {
        return connections.count
    }
    
    public var availableConnection: Int {
        return connections.filter({ !$0.isUsed }).count
    }
    
    private var _isClosed = true
    
    public var isShowSQLLog = false {
        didSet {
            for c in connections {
                c.isShowSQLLog = isShowSQLLog
            }
        }
    }
    
    public var isClosed: Bool {
        return _isClosed
    }
    
    let cond = Cond()
    
    public init(url: URL, user: String, password: String? = nil, database: String? = nil, minPoolSize: UInt = 1, maxPoolSize: UInt = 5) throws {
        self.url = url
        self.user = user
        self.password = password
        self.database = database
        self.minPoolSize = minPoolSize
        self.maxPoolSize = maxPoolSize
        
        self.connections = try (0..<maxPoolSize).map { _ in
            return try Connection(url: url, user: user, password: password, database: database)
        }
        
        #if os(Linux)
        let _ = Timer.scheduledTimer(withTimeInterval: TimeInterval(3600), repeats: true) { _ in
            print("timer! \"SELECT 1\"")
            do {
                for con in self.connections {
                    if con.isUsed {
                        continue
                    }
                    
                    con.reserve()
                    let _ = try con.query("SELECT 1")
                    con.release()
                }
            }
            catch {
                print("failed to \"SELECT 1\"")
            }
        }
        #endif
    }
    
    public func query(_ sql: String, bindParams params: [Any]) throws -> QueryResult {
        let con = try getConnection()
        var result: QueryResult
        do {
            result = try con.query(sql, bindParams: params)
        }
        catch {
            if let e = error as? SocketError {
                switch e {
                case .alreadyClosed:
                    try con.reopen()
                    result = try con.query(sql, bindParams: params)
                default: throw error
                }
            }
            else if let e = error as? StreamError {
                switch e {
                case .alreadyClosed:
                    try con.reopen()
                    result = try con.query(sql, bindParams: params)
                default: throw error
                }
            }
            else {
                throw error
            }
        }
        
        if !con.isTransacting {
            con.release()
        }
        
        return result
    }
    
    public func query(_ sql: String) throws -> QueryResult {
        let con = try getConnection()
        var result: QueryResult
        do {
            result = try con.query(sql)
        }
        catch {
            if let e = error as? SocketError {
                switch e {
                case .alreadyClosed:
                    try con.reopen()
                    result = try con.query(sql)
                default: throw error
                }
            }
            else if let e = error as? StreamError {
                switch e {
                case .alreadyClosed:
                    try con.reopen()
                    result = try con.query(sql)
                default: throw error
                }
            }
            else {
                throw error
            }
        }
        
        if !con.isTransacting {
            con.release()
        }
        
        return result
    }
    
    func getConnection(_ retryCount: Int = 0) throws -> Connection {
        // TODO should implement timeout
        if Double(retryCount) > (0.1 * 10) * 5 {
            throw ConnectionPoolError.failedToGetConnectionFromPool
        }
        
        cond.mutex.lock()
        defer { cond.mutex.unlock() }
        for con in connections {
            if con.isUsed {
                continue
            }
            
            con.reserve()
            return con
        }
        
        _ = cond.wait(timeout: 0.1)
        
        return try getConnection(retryCount + 1)
    }
    
    public func close () throws {
        for c in connections {
            try c.close()
        }
        _isClosed = true
    }
}
