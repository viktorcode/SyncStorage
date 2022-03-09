import SwiftUI

/// Replacement for `@AppStorage` with iCloud synchronization
@propertyWrapper
public struct SyncStorage<Value>: DynamicProperty {
    private var box: SyncBox<Value>
    public var projectedValue: Binding<Value>
    public var wrappedValue: Value {
        get { box.value }
        nonmutating set { box.setValue(newValue) }
    }

    public init(wrappedValue: Value, _ key: String) where Value == Bool {
        self.init(key: key, value: wrappedValue) { kvs.getValue(for: $0) }
    }

    public init(wrappedValue: Value, _ key: String) where Value == Int {
        self.init(key: key, value: wrappedValue) { kvs.getValue(for: $0) }
    }

    public init(wrappedValue: Value, _ key: String) where Value == Double {
        self.init(key: key, value: wrappedValue) { kvs.getValue(for: $0) }
    }

    public init(wrappedValue: Value, _ key: String) where Value == String {
        self.init(key: key, value: wrappedValue) { kvs.getValue(for: $0) }
    }

    public init(wrappedValue: Value, _ key: String) where Value == Data {
        self.init(key: key, value: wrappedValue) { kvs.getValue(for: $0) }
    }

    public init(wrappedValue: Value, _ key: String) where Value == Bool? {
        self.init(key: key, value: wrappedValue) { kvs.getValue(for: $0) }
    }

    public init(wrappedValue: Value, _ key: String) where Value == Int? {
        self.init(key: key, value: wrappedValue) { kvs.getValue(for: $0) }
    }

    public init(wrappedValue: Value, _ key: String) where Value == Double? {
        self.init(key: key, value: wrappedValue) { kvs.getValue(for: $0) }
    }

    public init(wrappedValue: Value, _ key: String) where Value == String? {
        self.init(key: key, value: wrappedValue) { kvs.getValue(for: $0) }
    }

    public init(wrappedValue: Value, _ key: String) where Value == Data? {
        self.init(key: key, value: wrappedValue) { kvs.getValue(for: $0) }
    }

    public init(wrappedValue: Value, _ key: String) where Value: RawRepresentable, Value.RawValue == Int {
        self.init(key: key, value: wrappedValue) {
            kvs.getValue(for: $0).flatMap(Value.init)
        } valueSetter: { key, newValue in
            kvs.set(newValue?.rawValue, forKey: key) 
        }
    }

    public init(wrappedValue: Value, _ key: String) where Value: RawRepresentable, Value.RawValue == String {
        self.init(key: key, value: wrappedValue) {
            kvs.getValue(for: $0).flatMap(Value.init)
        } valueSetter: { key, newValue in
            kvs.set(newValue?.rawValue, forKey: key)
        }
    }

    public init<R>(wrappedValue: Value, _ key: String) where Value == R?, R: RawRepresentable, R.RawValue == Int {
        self.init(key: key, value: wrappedValue) { key in
            guard let stored: Int = kvs.getValue(for: key) else { return nil }
            return R.init(rawValue: stored)
        } valueSetter: { key, newValue in
            kvs.set(newValue??.rawValue, forKey: key)
        }
    }

    public init<R>(wrappedValue: Value, _ key: String) where Value == R?, R: RawRepresentable, R.RawValue == String {
        self.init(key: key, value: wrappedValue) { key in
            guard let stored: String = kvs.getValue(for: key) else { return nil }
            return R.init(rawValue: stored)
        } valueSetter: { key, newValue in
            kvs.set(newValue??.rawValue, forKey: key)
        }
    }

    private init(key: String, value: Value,
                 valueGetter: @escaping (String) -> Value?,
                 valueSetter: @escaping (String, Value?) -> Void =
                 { key, newValue in kvs.set(newValue, forKey: key) })
    {
        let box = SyncBox(value, key: key, getter: valueGetter, setter: valueSetter)
        self.box = box
        self.projectedValue = Binding {
            box.value
        } set: {
            box.setValue($0)
        }
    }
}

let kvs = NSUbiquitousKeyValueStore.default

/// Boxing value wrapper with iCloud synchronization
fileprivate final class SyncBox<Value> {
    typealias Getter = (String) -> Value?
    typealias Setter = (String, Value?) -> Void

    let key: String
    let set: Setter
    private(set) var value: Value

    init(_ initialValue: Value,
         key: String,
         getter: @escaping Getter,
         setter: @escaping Setter) {
        self.key = key
        set = setter
        value = getter(key) ?? initialValue

        CloudWatch.shared.subscribe(for: key) { [unowned self] in
            guard let stored: Value = getter(key) else { return }
            self.value = stored
        }
    }

    deinit {
        CloudWatch.shared.unsubscribe(key)
    }

    func setValue(_ newValue: Value) {
        value = newValue
        set(key, newValue)
    }
}

/// Monitors iCloud KVS updates
fileprivate final class CloudWatch {
    static let shared = CloudWatch()
    private var subscribers: [String : () -> Void] = [:]

    init() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            queue: .main) { [weak self]
                data in
                let keys = data.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] ?? []
                keys.forEach { name in
                    self?.subscribers[name]?()
                }
            }
        kvs.synchronize()
    }

    func subscribe(for key: String, _ subscriber: @escaping () -> Void) {
        subscribers[key] = subscriber
    }

    func unsubscribe(_ key: String) {
        subscribers.removeValue(forKey: key)
    }
}

extension NSUbiquitousKeyValueStore {

    func getValue(for key: String) -> Bool? {
        if self.object(forKey: key) == nil { return nil }
        return self.bool(forKey: key)
    }

    func getValue(for key: String) -> Int? {
        if self.object(forKey: key) == nil { return nil }
        return Int(self.longLong(forKey: key))
    }

    func getValue(for key: String) -> Double? {
        if self.object(forKey: key) == nil { return nil }
        return self.double(forKey: key)
    }

    func getValue(for key: String) -> String? {
        self.string(forKey: key)
    }

    func getValue(for key: String) -> Data? {
        self.data(forKey: key)
    }

    func getValue(for key: String) -> URL? {
        self.object(forKey: key) as? URL
    }
}
