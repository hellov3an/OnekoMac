import os.log

enum Log {
    static let engine  = Logger(subsystem: "com.onekomac", category: "engine")
    static let render  = Logger(subsystem: "com.onekomac", category: "render")
    static let input   = Logger(subsystem: "com.onekomac", category: "input")
    static let skin    = Logger(subsystem: "com.onekomac", category: "skin")
    static let store   = Logger(subsystem: "com.onekomac", category: "store")
}
