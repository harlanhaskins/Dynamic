import Foundation
import Testing

@testable import Dynamic

struct LoggingScope: SuiteTrait, TestScoping {
    func provideScope(for test: Test, testCase: Test.Case?, performing function: () async throws -> Void) async throws {
        Dynamic.loggingEnabled = true
        try await function()
    }
}

extension SuiteTrait where Self == LoggingScope {
    static var withLogging: LoggingScope { LoggingScope() }
}

@Suite(.withLogging)
@MainActor
final class DynamicTests {
    @Test
    func initialization() {
        let className = "NSDateFormatter"

        let formatter1 = ObjC.NSDateFormatter()
        #expect(formatter1.asObject?.className == className, "Parameterless init")
        #expect(formatter1.asObject is DateFormatter, "Parameterless init - Bridging")

        let formatter2 = ObjC.NSDateFormatter.`init`()
        #expect(formatter2.asObject?.className == className, "Parameterless init with explicit init")
    }

    @Test
    func initWithParameters() {
        let uuidString = "68753A44-4D6F-1226-9C60-0050E4C00067"
        let className = "__NSConcreteUUID"

        let uuid1 = ObjC.NSUUID(UUIDString: uuidString)

        #expect(uuid1.asObject?.className == className, "Parameterized init")
        #expect(uuid1.UUIDString.asString == uuidString)

        let uuid2 = ObjC.NSUUID.initWithUUIDString(uuidString)
        #expect(uuid2.asObject?.className == className, "Parameterized init with explicit init")
        #expect(uuid2.UUIDString.asString == uuidString)
    }

    @Test
    func testClassMethods() {
        let uuidClassName = "__NSConcreteUUID"
        let uuid = ObjC.NSUUID.UUID()
        #expect(uuid.asObject?.className == uuidClassName, "Class methods")

        let exceptionClassName = "NSException"
        let name = "Dummy"
        let reason = "Testing"
        let userInfo = ["Foo": "Bar"] as NSDictionary
        let exception = ObjC.NSException.exceptionWithName(name, reason: reason, userInfo: userInfo)
        #expect(exception.asObject?.className == exceptionClassName, "Class methods")
        #expect(exception.name.asString == name, "Properties passed to the constructor")
        #expect(exception.reason.asString == reason, "Properties passed to the constructor")
        #expect(exception.userInfo.asDictionary == userInfo, "Properties passed to the constructor")
    }

    @Test
    func testProperties() {
        let host = "example.com"
        let urlString = "https://\(host)/"
        let urlComponents = ObjC.NSURLComponents.componentsWithString(urlString)
        #expect(urlComponents.host.asString == host, "Properties passed to the constructor")

        let host2 = "example2.com"
        urlComponents.host = host2
        #expect(urlComponents.host.asString == host2, "Setting properties")

        let queryItems = [NSURLQueryItem(name: "foo", value: "bar")] as NSArray
        urlComponents.queryItems = queryItems
        #expect(urlComponents.queryItems.asArray == queryItems, "Setting properties")
        #expect(urlComponents.URL == NSURL(string: "https://example2.com/?foo=bar"))

        let progress = ObjC.NSProgress.progressWithTotalUnitCount(100)
        progress.completedUnitCount = 50
        #expect(progress.fractionCompleted == 0.5, "Setting numeric properties")

        let queue = ObjC.NSOperationQueue()
        #expect(!queue.isSuspended!)
        queue.isSuspended = true
        #expect(queue.isSuspended!, "Setting boolean properties with 'is' prefix")
    }

    @Test
    func blocks() async {
        // swiftlint:disable:next nesting
        typealias VoidBlock = @convention(block) () -> Void

        var closure1Called = false
        let progress = ObjC.NSProgress.progressWithTotalUnitCount(100)
        progress.cancellationHandler = {
            closure1Called = true
        } as VoidBlock
        progress.cancel()

        var closure2Called = false
        let operation = ObjC.NSBlockOperation.blockOperationWithBlock({
            closure2Called = true
        } as VoidBlock)
        ObjC.NSOperationQueue.mainQueue.addOperation(operation)

        try? await Task.sleep(for: .milliseconds(100))
        #expect(closure1Called)
        #expect(closure2Called)
    }

    func testExplicitUnwrapping() {
        // swiftlint:disable:next nesting
        struct NSOperatingSystemVersion {
            var majorVersion: Int
            var minorVersion: Int
            var patchVersion: Int
        }

        let processInfo1 = ProcessInfo.processInfo
        let processInfo2 = ObjC.NSProcessInfo.processInfo

        #expect(processInfo1.processIdentifier == processInfo2.processIdentifier.asInt32, "Int32")
        #expect(processInfo1.processorCount == processInfo2.processorCount.asInt, "Int")
        #expect(processInfo1.physicalMemory == processInfo2.physicalMemory.asUInt64, "UInt64")
        #expect(processInfo1.systemUptime == processInfo2.systemUptime.asDouble ?? 0, "Double")
        #expect(processInfo1.arguments as NSArray == processInfo2.arguments.asArray, "Array")
        #expect(processInfo1.arguments == processInfo2.arguments.asInferred(), "Array")
        #expect(processInfo1.environment as NSDictionary == processInfo2.environment, "Dictionary")
        #expect(processInfo1.processName == processInfo2.processName.asString, "String")

        let version1 = processInfo1.operatingSystemVersion
        let version2: NSOperatingSystemVersion? = processInfo2.operatingSystemVersion.asInferred()
        #expect(version1.majorVersion == version2?.majorVersion, "Struct")

        #expect(processInfo1.isOperatingSystemAtLeast(version1) == processInfo2.isOperatingSystemAtLeastVersion(version2).asBool, "Bool")
    }

    func testImplicitUnwrapping() {
        // swiftlint:disable:next nesting
        struct NSOperatingSystemVersion {
            var majorVersion: Int
            var minorVersion: Int
            var patchVersion: Int
        }

        let processInfo1 = ProcessInfo.processInfo
        let processInfo2 = ObjC.NSProcessInfo.processInfo

        #expect(processInfo1.processIdentifier == processInfo2.processIdentifier, "Int32")
        #expect(processInfo1.processorCount == processInfo2.processorCount, "Int")
        #expect(processInfo1.physicalMemory == processInfo2.physicalMemory, "UInt64")
        #expect(Int(processInfo1.systemUptime) == Int(processInfo2.systemUptime ?? 0), "Double")
        #expect(processInfo1.arguments == processInfo2.arguments, "Array")
        #expect(processInfo1.environment == processInfo2.environment, "Dictionary")
        #expect(processInfo1.processName == processInfo2.processName, "String")

        let version1 = processInfo1.operatingSystemVersion
        let version2: NSOperatingSystemVersion? = processInfo2.operatingSystemVersion
        #expect(version1.majorVersion == version2?.majorVersion, "Struct")

        #expect(processInfo1.isOperatingSystemAtLeast(version1) == processInfo2.isOperatingSystemAtLeastVersion(version2), "Bool")

        let formatter1 = ObjC.NSDateFormatter()
        #expect(type(of: formatter1) == Dynamic.self, "Type should be Dynamic")

        let formatter2: NSObject? = ObjC.NSDateFormatter()
        #expect(formatter2?.className == "NSDateFormatter", "Value isn't unwrapped")

        let formatter3 = { () -> NSObject? in
            ObjC.NSDateFormatter()
        }()
        #expect(formatter3?.className == "NSDateFormatter", "Value isn't unwrapped")

        formatter1.dateFormat = ObjC("yyyy-MM-dd HH:mm:ss")
        let date = ObjC.NSDate(timeIntervalSince1970: 1_600_000_000)
        let string: String? = formatter1.stringFromDate(date)
        let newDate: Date? = formatter1.dateFromString(string)
        #expect(date.asInferred() == newDate, "Value isn't unwrapped")

        #expect(date.asObject == formatter1.dateFromString(formatter1.stringFromDate(date)), "Value isn't unwrapped")
    }

    func testEdgeCases() {
        let error = ObjC.NSDateFormatter().invalidMethod()
        #expect(error.asObject is Error, "Calling non existing method should return error")
        #expect(error.isError, "isError should return true for errors")

        let errorChained = error.thisMethodCallHasNoEffect(123).randomProperty
        #expect(errorChained === error, "Calling methods and properties form error should return the same object")

        let null = ObjC.nil
        #expect(null.asObject == nil, "Wrapped nil should return nil")

        let nullChained = null.thisMethodCallHasNoEffect(123).randomProperty
        #expect(nullChained === null, "Calling methods and properties form <nil> should return the same object")

        let formatter = ObjC.NSDateFormatter()
        #expect(formatter.stringFromDate(Date()) == "", "Should return an empty string")
        formatter.dateFormat = ObjC("yyyy-MM-dd HH:mm:ss")
        #expect(formatter.stringFromDate(Date()) != "", "Should NOT return an empty string")

        formatter.dateFormat = .nil
        #expect(formatter.stringFromDate(Date()) == "", "Should return an empty string")
        formatter.dateFormat = ObjC("yyyy-MM-dd HH:mm:ss")
        #expect(formatter.stringFromDate(Date()) != "", "Should NOT return an empty string")

        formatter.dateFormat = nil as String? // or String?.none
        #expect(formatter.stringFromDate(Date()) == "", "Should return an empty string")
    }

    func testAlternativeMethodNames() {
        let formatter = ObjC.NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        #expect(
            formatter.stringFromDate(Date()).asString ==
                formatter.stringFrom(date: Date()),
            "Alternative methods should work as the original")

        #expect(
            formatter.stringFromDate(Date()).asString ==
                formatter.string(fromDate: Date()),
            "Alternative methods should work as the original")

        let progress1 = ObjC.NSProgress.progressWithTotalUnitCount(99)
        let progress2 = ObjC.NSProgress.progress(withTotalUnitCount: 99)
        #expect(
            progress1.totalUnitCount.asInt == progress2.totalUnitCount.asInt,
            "Alternative methods should work as the original")
    }

    func testHiddenAPI() {
        do {
            let selector = NSSelectorFromString("lowercaseString")
            let target = NSString("ABC")
            let methodSignature: NSObject? = ObjC(target).methodSignatureForSelector(selector)
            let invocation = ObjC.NSInvocation.invocationWithMethodSignature(methodSignature)
            invocation.selector = selector
            invocation.invokeWithTarget(target)
            var result: NSString?
            _ = withUnsafeMutablePointer(to: &result) { pointer in
                invocation.getReturnValue(pointer)
            }
            #expect(result == "abc", "Can't use hidden API")
            if let string = result {
                _ = Unmanaged.passRetained(string).takeUnretainedValue()
            }
        }

        do {
            let selector = NSSelectorFromString("stringByPaddingToLength:withString:startingAtIndex:")
            let target = NSString("ABC")
            let methodSignature: NSObject? = ObjC(target).methodSignatureForSelector(selector)
            let invocation = ObjC.NSInvocation.invocationWithMethodSignature(methodSignature)
            invocation.selector = selector

            let length: Int = 6
            let padString = "0123" as NSString
            let index: Int = 1
            _ = withUnsafePointer(to: length) { pointer in
                invocation.setArgument(pointer, atIndex: 2)
            }
            _ = withUnsafePointer(to: padString) { pointer in
                invocation.setArgument(pointer, atIndex: 3)
            }
            _ = withUnsafePointer(to: index) { pointer in
                invocation.setArgument(pointer, atIndex: 4)
            }
            invocation.invokeWithTarget(target)
            var result: NSString?
            _ = withUnsafeMutablePointer(to: &result) { pointer in
                invocation.getReturnValue(pointer)
            }
            #expect(result == "ABC123", "Can't use hidden API")
            if let string = result {
                _ = Unmanaged.passRetained(string).takeUnretainedValue()
            }
        }
    }
}

extension NSObject {
    var className: String { String(describing: type(of: self)) }
}
