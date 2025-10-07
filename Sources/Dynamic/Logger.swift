//
//  Dynamic
//  Created by Mhd Hejazi on 4/15/20.
//  Copyright © 2020 Samabox. All rights reserved.
//

import Foundation
import os

protocol Loggable: AnyObject {
    var loggingEnabled: Bool { get }
}

protocol Logger: AnyObject, Sendable {
    @discardableResult
    func log(_ group: LogGroup) -> any Logger

    @discardableResult
    func log(_ items: [Any]) -> any Logger

    @discardableResult
    func log(_ items: Any...) -> any Logger
}

extension Logger {
    func log(_ items: Any...) -> any Logger {
        log(items)
    }
}

extension Loggable {
    var loggingEnabled: Bool { false }
    var logUsingPrint: Bool { true }

    /// Lazily creates and stores a local debug logger as an associated object.
    var logger: Logger {
        let loggerKey = UnsafeRawPointer(bitPattern: Int(bitPattern: ObjectIdentifier(Logger.self)))!

        if let logger = objc_getAssociatedObject(self, loggerKey) as? Logger {
            return logger
        }
        let logger = PrintLogger()
        objc_setAssociatedObject(self, loggerKey, logger, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return logger
    }

    @discardableResult
    func log(_ items: Any...) -> Logger {
        guard loggingEnabled else { return DummyLogger.shared }
        return logger.log(items)
    }

    @discardableResult
    func log(_ group: LogGroup) -> Logger {
        guard loggingEnabled else { return DummyLogger.shared }
        return logger.log(group)
    }
}

enum LogGroup {
    case start, end
}

final class PrintLogger: Logger {
    private static let level = OSAllocatedUnfairLock(initialState: 0)

    @discardableResult
    func logUnchecked(_ items: [Any], level: Int, withBullet: Bool = true) -> Logger {
        let message = items.lazy.map { String(describing: $0) }.joined(separator: " ")
        var indent = String(repeating: " ╷  ", count: level)
        if !indent.isEmpty, withBullet {
            indent = indent.dropLast(2) + "‣ "
        }
        print(indent + message)
        return self
    }

    @discardableResult
    func log(_ items: [Any]) -> Logger {
        Self.level.withLockUnchecked { level in
            logUnchecked(items, level: level)
        }
    }

    @discardableResult
    func log(_ group: LogGroup) -> Logger {
        switch group {
        case .start: logGroupStart()
        case .end: logGroupEnd()
        }
        return self
    }

    private func logGroupStart() {
        Self.level.withLockUnchecked { level in
            logUnchecked([" ╭╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴"], level: level, withBullet: false)
            level += 1
        }
    }

    private func logGroupEnd() {
        Self.level.withLockUnchecked { level in
            guard level > 0 else { return }
            level -= 1
            logUnchecked([" ╰╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴"], level: level, withBullet: false)
        }
    }
}

final class DummyLogger: Logger {
    static let shared = DummyLogger()

    @discardableResult
    func log(_ items: [Any]) -> Logger {
        self
    }

    @discardableResult
    func log(_ group: LogGroup) -> Logger {
        self
    }
}
