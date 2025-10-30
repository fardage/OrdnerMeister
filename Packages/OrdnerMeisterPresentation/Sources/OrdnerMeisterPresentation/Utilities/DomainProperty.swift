import Combine
import Foundation

/// A Publisher wrapper that maintains the current value and allows synchronous access
public class DomainProperty<Value>: Publisher {
    public typealias Output = Value
    public typealias Failure = Never

    private let publisher: AnyPublisher<Value, Never>
    private var lastReceivedValue: Value!

    public var currentValue: Value {
        publisher.sink { [weak self] value in
            self?.lastReceivedValue = value
        }.cancel()

        return lastReceivedValue
    }

    fileprivate init<P: Publisher>(_ publisher: P) where P.Output == Value, P.Failure == Never {
        self.publisher = publisher.eraseToAnyPublisher()

        publisher.sink { [weak self] value in
            self?.lastReceivedValue = value
        }.cancel()

        assert(lastReceivedValue != nil)
    }

    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, S.Input == Value {
        publisher.receive(subscriber: subscriber)
    }
}

extension Publisher where Failure == Never {
    /// Creates a `DomainProperty` from the publisher.
    public func domainProperty() -> DomainProperty<Output> {
        DomainProperty(self)
    }
}

public extension DomainProperty {
    static func constant(_ value: Value) -> DomainProperty<Value> {
        DomainProperty(Just(value))
    }
}

public extension DomainProperty {
    func map<T>(_ transform: @escaping (Value) -> T) -> DomainProperty<T> {
        publisher.map(transform).domainProperty()
    }
}
