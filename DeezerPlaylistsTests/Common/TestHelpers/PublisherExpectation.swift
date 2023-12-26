//
//  PublisherExpectation.swift
//  DeezerPlaylistsTests
//
//  Created by Christopher James on 26/12/2023.
//

import Foundation
import XCTest
import Combine

/// A Combine subscriber which records all events published by a publisher.
///
/// You create a Recorder with the `Publisher.record()` method:
///
///     let publisher = ["foo", "bar", "baz"].publisher
///     let recorder = publisher.record()
///
/// You can build publisher expectations from the Recorder. For example:
///
///     let elements = try wait(for: recorder.elements, timeout: 1)
///     XCTAssertEqual(elements, ["foo", "bar", "baz"])
public class Recorder<Input, Failure: Error>: Subscriber {
    public typealias Input = Input
    public typealias Failure = Failure
    
    private enum RecorderExpectation {
        case onInput(XCTestExpectation, remainingCount: Int)
        case onCompletion(XCTestExpectation)
        
        var expectation: XCTestExpectation {
            switch self {
            case let .onCompletion(expectation):
                return expectation
            case let .onInput(expectation, remainingCount: _):
                return expectation
            }
        }
    }
    
    /// The recorder state
    private enum State {
        /// Publisher is not subscribed yet. The recorder may have an
        /// expectation to fulfill.
        case waitingForSubscription(RecorderExpectation?)
        
        /// Publisher is subscribed. The recorder may have an expectation to
        /// fulfill. It keeps track of all published elements.
        case subscribed(Subscription, RecorderExpectation?, [Input])
        
        /// Publisher is completed. The recorder keeps track of all published
        /// elements and completion.
        case completed([Input], Subscribers.Completion<Failure>)
        
        var elementsAndCompletion: (elements: [Input], completion: Subscribers.Completion<Failure>?) {
            switch self {
            case .waitingForSubscription:
                return (elements: [], completion: nil)
            case let .subscribed(_, _, elements):
                return (elements: elements, completion: nil)
            case let .completed(elements, completion):
                return (elements: elements, completion: completion)
            }
        }
        
        var recorderExpectation: RecorderExpectation? {
            switch self {
            case let .waitingForSubscription(exp), let .subscribed(_, exp, _):
                return exp
            case .completed:
                return nil
            }
        }
    }
    
    private let lock = NSLock()
    private var state = State.waitingForSubscription(nil)
    private var consumedCount = 0
    
    /// The elements and completion recorded so far.
    var elementsAndCompletion: (elements: [Input], completion: Subscribers.Completion<Failure>?) {
        synchronized {
            state.elementsAndCompletion
        }
    }
    
    /// Use Publisher.record()
    fileprivate init() { }
    
    deinit {
        if case let .subscribed(subscription, _, _) = state {
            subscription.cancel()
        }
    }
    
    private func synchronized<T>(_ execute: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try execute()
    }
    
    // MARK: - PublisherExpectation API
    
    /// Registers the expectation so that it gets fulfilled when publisher
    /// publishes elements or completes.
    ///
    /// - parameter expectation: An XCTestExpectation.
    /// - parameter includingConsumed: This flag controls how elements that were
    ///   already published at the time this method is called fulfill the
    ///   expectation. If true, all published elements fulfill the expectation.
    ///   If false, only published elements that are not consumed yet fulfill
    ///   the expectation. For example, the Prefix expectation uses true, but
    ///   the NextOne expectation uses false.
    func fulfillOnInput(_ expectation: XCTestExpectation, includingConsumed: Bool) {
        synchronized {
            preconditionCanFulfillExpectation()
            
            let expectedFulfillmentCount = expectation.expectedFulfillmentCount
            
            switch state {
            case .waitingForSubscription:
                let exp = RecorderExpectation.onInput(expectation, remainingCount: expectedFulfillmentCount)
                state = .waitingForSubscription(exp)
                
            case let .subscribed(subscription, _, elements):
                let maxFulfillmentCount = includingConsumed
                    ? elements.count
                    : elements.count - consumedCount
                let fulfillmentCount = min(expectedFulfillmentCount, maxFulfillmentCount)
                expectation.fulfill(count: fulfillmentCount)
                
                let remainingCount = expectedFulfillmentCount - fulfillmentCount
                if remainingCount > 0 {
                    let exp = RecorderExpectation.onInput(expectation, remainingCount: remainingCount)
                    state = .subscribed(subscription, exp, elements)
                }
                
            case .completed:
                expectation.fulfill(count: expectedFulfillmentCount)
            }
        }
    }
    
    /// Registers the expectation so that it gets fulfilled when
    /// publisher completes.
    func fulfillOnCompletion(_ expectation: XCTestExpectation) {
        synchronized {
            preconditionCanFulfillExpectation()
            
            switch state {
            case .waitingForSubscription:
                let exp = RecorderExpectation.onCompletion(expectation)
                state = .waitingForSubscription(exp)
                
            case let .subscribed(subscription, _, elements):
                let exp = RecorderExpectation.onCompletion(expectation)
                state = .subscribed(subscription, exp, elements)
                
            case .completed:
                expectation.fulfill()
            }
        }
    }
    
    /// Returns a value based on the recorded state of the publisher.
    ///
    /// - parameter value: A function which returns the value, given the
    ///   recorded state of the publisher.
    /// - parameter elements: All recorded elements.
    /// - parameter completion: The eventual publisher completion.
    /// - parameter remainingElements: The elements that were not consumed yet.
    /// - parameter consume: A function which consumes elements.
    /// - parameter count: The number of consumed elements.
    /// - returns: The value
    func value<T>(_ value: (
        _ elements: [Input],
        _ completion: Subscribers.Completion<Failure>?,
        _ remainingElements: ArraySlice<Input>,
        _ consume: (_ count: Int) -> ()) throws -> T)
        rethrows -> T
    {
        try synchronized {
            let (elements, completion) = state.elementsAndCompletion
            let remainingElements = elements[consumedCount...]
            return try value(elements, completion, remainingElements, { count in
                precondition(count >= 0)
                precondition(count <= remainingElements.count)
                consumedCount += count
            })
        }
    }
    
    /// Checks that recorder can fulfill an expectation.
    ///
    /// The reason this method exists is that a recorder can fulfill a single
    /// expectation at a given time. It is a programmer error to wait for two
    /// expectations concurrently.
    ///
    /// This method MUST be called within a synchronized block.
    private func preconditionCanFulfillExpectation() {
        if let exp = state.recorderExpectation {
            // We are already waiting for an expectation! Is it a programmer
            // error? Recorder drops references to non-inverted expectations
            // when they are fulfilled. But inverted expectations are not
            // fulfilled, and thus not dropped. We can't quite know if an
            // inverted expectations has expired yet, so just let it go.
            precondition(exp.expectation.isInverted, "Already waiting for an expectation")
        }
    }
    
    // MARK: - Subscriber
    
    public func receive(subscription: Subscription) {
        synchronized {
            switch state {
            case let .waitingForSubscription(exp):
                state = .subscribed(subscription, exp, [])
            default:
                XCTFail("Publisher recorder is already subscribed")
            }
        }
        subscription.request(.unlimited)
    }
    
    public func receive(_ input: Input) -> Subscribers.Demand {
        return synchronized {
            switch state {
            case let .subscribed(subscription, exp, elements):
                var elements = elements
                elements.append(input)
                
                if case let .onInput(expectation, remainingCount: remainingCount) = exp {
                    assert(remainingCount > 0)
                    expectation.fulfill()
                    if remainingCount > 1 {
                        let exp = RecorderExpectation.onInput(expectation, remainingCount: remainingCount - 1)
                        state = .subscribed(subscription, exp, elements)
                    } else {
                        state = .subscribed(subscription, nil, elements)
                    }
                } else {
                    state = .subscribed(subscription, exp, elements)
                }
                
                return .unlimited
                
            case .waitingForSubscription:
                XCTFail("Publisher recorder got unexpected input before subscription: \(String(reflecting: input))")
                return .none
                
            case .completed:
                XCTFail("Publisher recorder got unexpected input after completion: \(String(reflecting: input))")
                return .none
            }
        }
    }
    
    public func receive(completion: Subscribers.Completion<Failure>) {
        synchronized {
            switch state {
            case let .subscribed(_, exp, elements):
                if let exp = exp {
                    switch exp {
                    case let .onCompletion(expectation):
                        expectation.fulfill()
                    case let .onInput(expectation, remainingCount: remainingCount):
                        expectation.fulfill(count: remainingCount)
                    }
                }
                state = .completed(elements, completion)
                
            case .waitingForSubscription:
                XCTFail("Publisher recorder got unexpected completion before subscription: \(String(describing: completion))")
                
            case .completed:
                XCTFail("Publisher recorder got unexpected completion after completion: \(String(describing: completion))")
            }
        }
    }
}

extension Recorder {
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to emit one element, or to complete.
    ///
    /// When waiting for this expectation, a `RecordingError.notEnoughElements`
    /// is thrown if the publisher does not publish one element after last
    /// waited expectation. The publisher error is thrown if the publisher fails
    /// before publishing the next element.
    ///
    /// Otherwise, the next published element is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfTwoElementsPublishesElementsInOrder() throws {
    ///         let publisher = ["foo", "bar"].publisher
    ///         let recorder = publisher.record()
    ///
    ///         var element = try wait(for: recorder.next(), timeout: 1)
    ///         XCTAssertEqual(element, "foo")
    ///
    ///         element = try wait(for: recorder.next(), timeout: 1)
    ///         XCTAssertEqual(element, "bar")
    ///     }
    public func next() -> PublisherExpectations.NextOne<Input, Failure> {
        PublisherExpectations.NextOne(recorder: self)
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to emit `count` elements, or to complete.
    ///
    /// When waiting for this expectation, a `RecordingError.notEnoughElements`
    /// is thrown if the publisher does not publish `count` elements after last
    /// waited expectation. The publisher error is thrown if the publisher fails
    /// before publishing the next `count` elements.
    ///
    /// Otherwise, an array of exactly `count` elements is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfThreeElementsPublishesTwoThenOneElement() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///
    ///         var elements = try wait(for: recorder.next(2), timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar"])
    ///
    ///         elements = try wait(for: recorder.next(1), timeout: 1)
    ///         XCTAssertEqual(elements, ["baz"])
    ///     }
    ///
    /// - parameter count: The number of elements.
    public func next(_ count: Int) -> PublisherExpectations.Next<Input, Failure> {
        PublisherExpectations.Next(recorder: self, count: count)
    }
}

// MARK: - Publisher + Recorder

extension Publisher {
    /// Returns a subscribed Recorder.
    ///
    /// For example:
    ///
    ///     let publisher = ["foo", "bar", "baz"].publisher
    ///     let recorder = publisher.record()
    ///
    /// You can build publisher expectations from the Recorder. For example:
    ///
    ///     let elements = try wait(for: recorder.elements, timeout: 1)
    ///     XCTAssertEqual(elements, ["foo", "bar", "baz"])
    public func record() -> Recorder<Output, Failure> {
        let recorder = Recorder<Output, Failure>()
        subscribe(recorder)
        return recorder
    }
}

// MARK: - Convenience

extension XCTestExpectation {
    fileprivate func fulfill(count: Int) {
        for _ in 0..<count {
            fulfill()
        }
    }
}


/// A name space for publisher expectations
public enum PublisherExpectations { }

/// The base protocol for PublisherExpectation. It is an implementation detail
/// that you are not supposed to use, as shown by the underscore prefix.
///
/// :nodoc:
public protocol _PublisherExpectationBase {
    /// Sets up an XCTestExpectation. This method is an implementation detail
    /// that you are not supposed to use, as shown by the underscore prefix.
    func _setup(_ expectation: XCTestExpectation)
    
    /// Returns an object that waits for the expectation. If nil, expectation
    /// is waited by the XCTestCase.
    func _makeWaiter() -> XCTWaiter?
}

extension _PublisherExpectationBase {
    /// :nodoc:
    public func _makeWaiter() -> XCTWaiter? { nil }
}

/// The protocol for publisher expectations.
///
/// You can build publisher expectations from Recorder returned by the
/// `Publisher.record()` method.
///
/// For example:
///
///     // The expectation for all published elements until completion
///     let publisher = ["foo", "bar", "baz"].publisher
///     let recorder = publisher.record()
///     let expectation = recorder.elements
///
/// When a test grants some time for the expectation to fulfill, use the
/// XCTest `wait(for:timeout:description)` method:
///
///     // SUCCESS: no timeout, no error
///     func testArrayPublisherPublishesArrayElements() throws {
///         let publisher = ["foo", "bar", "baz"].publisher
///         let recorder = publisher.record()
///         let expectation = recorder.elements
///         let elements = try wait(for: expectation, timeout: 1)
///         XCTAssertEqual(elements, ["foo", "bar", "baz"])
///     }
///
/// On the other hand, when the expectation is supposed to be immediately
/// fulfilled, use the PublisherExpectation `get()` method in order to grab the
/// expected value:
///
///     // SUCCESS: no error
///     func testArrayPublisherSynchronouslyPublishesArrayElements() throws {
///         let publisher = ["foo", "bar", "baz"].publisher
///         let recorder = publisher.record()
///         let elements = try recorder.elements.get()
///         XCTAssertEqual(elements, ["foo", "bar", "baz"])
///     }
public protocol PublisherExpectation: _PublisherExpectationBase {
    /// The type of the expected value.
    associatedtype Output
    
    /// Returns the expected value, or throws an error if the
    /// expectation fails.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no error
    ///     func testArrayPublisherSynchronouslyPublishesArrayElements() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         let elements = try recorder.elements.get()
    ///         XCTAssertEqual(elements, ["foo", "bar", "baz"])
    ///     }
    func get() throws -> Output
}

extension XCTestCase {
    /// Waits for the publisher expectation to fulfill, and returns the
    /// expected value.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayPublisherPublishesArrayElements() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         let elements = try wait(for: recorder.elements, timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar", "baz"])
    ///     }
    ///
    /// - parameter publisherExpectation: The publisher expectation.
    /// - parameter timeout: The number of seconds within which the expectation
    ///   must be fulfilled.
    /// - parameter description: A string to display in the test log for the
    ///   expectation, to help diagnose failures.
    /// - throws: An error if the expectation fails.
    public func wait<R: PublisherExpectation>(
        for publisherExpectation: R,
        timeout: TimeInterval,
        description: String = "")
        throws -> R.Output
    {
        let expectation = self.expectation(description: description)
        publisherExpectation._setup(expectation)
        if let waiter = publisherExpectation._makeWaiter() {
            waiter.wait(for: [expectation], timeout: timeout)
        } else {
            wait(for: [expectation], timeout: timeout)
        }
        return try publisherExpectation.get()
    }
}

extension PublisherExpectations {
    /// A publisher expectation which waits for the recorded publisher to emit
    /// one element, or to complete.
    ///
    /// When waiting for this expectation, a `RecordingError.notEnoughElements`
    /// is thrown if the publisher does not publish one element after last
    /// waited expectation. The publisher error is thrown if the publisher fails
    /// before publishing the next element.
    ///
    /// Otherwise, the next published element is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfTwoElementsPublishesElementsInOrder() throws {
    ///         let publisher = ["foo", "bar"].publisher
    ///         let recorder = publisher.record()
    ///
    ///         var element = try wait(for: recorder.next(), timeout: 1)
    ///         XCTAssertEqual(element, "foo")
    ///
    ///         element = try wait(for: recorder.next(), timeout: 1)
    ///         XCTAssertEqual(element, "bar")
    ///     }
    public struct NextOne<Input, Failure: Error>: PublisherExpectation {
        let recorder: Recorder<Input, Failure>
        
        public func _setup(_ expectation: XCTestExpectation) {
            recorder.fulfillOnInput(expectation, includingConsumed: false)
        }
        
        /// Returns the expected output, or throws an error if the
        /// expectation fails.
        ///
        /// For example:
        ///
        ///     // SUCCESS: no error
        ///     func testArrayOfTwoElementsSynchronouslyPublishesElementsInOrder() throws {
        ///         let publisher = ["foo", "bar"].publisher
        ///         let recorder = publisher.record()
        ///
        ///         var element = try recorder.next().get()
        ///         XCTAssertEqual(element, "foo")
        ///
        ///         element = try recorder.next().get()
        ///         XCTAssertEqual(element, "bar")
        ///     }
        public func get() throws -> Input {
            try recorder.value { (_, completion, remainingElements, consume) in
                if let next = remainingElements.first {
                    consume(1)
                    return next
                }
                if case let .failure(error) = completion {
                    throw error
                } else {
                    throw RecordingError.notEnoughElements
                }
            }
        }
        
        /// Returns an inverted publisher expectation which waits for the
        /// recorded publisher to emit one element, or to complete.
        ///
        /// When waiting for this expectation, a RecordingError is thrown if the
        /// publisher does not publish one element after last waited
        /// expectation. The publisher error is thrown if the publisher fails
        /// before publishing one element.
        ///
        /// For example:
        ///
        ///     // SUCCESS: no timeout, no error
        ///     func testPassthroughSubjectDoesNotPublishAnyElement() throws {
        ///         let publisher = PassthroughSubject<String, Never>()
        ///         let recorder = publisher.record()
        ///         try wait(for: recorder.next().inverted, timeout: 1)
        ///     }
        public var inverted: NextOneInverted<Input, Failure> {
            return NextOneInverted(recorder: recorder)
        }
    }
    
    /// An inverted publisher expectation which waits for the recorded publisher
    /// to emit one element, or to complete.
    ///
    /// When waiting for this expectation, a RecordingError is thrown if the
    /// publisher does not publish one element after last waited expectation.
    /// The publisher error is thrown if the publisher fails before
    /// publishing one element.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testPassthroughSubjectDoesNotPublishAnyElement() throws {
    ///         let publisher = PassthroughSubject<String, Never>()
    ///         let recorder = publisher.record()
    ///         try wait(for: recorder.next().inverted, timeout: 1)
    ///     }
    public struct NextOneInverted<Input, Failure: Error>: PublisherExpectation {
        let recorder: Recorder<Input, Failure>
        
        public func _setup(_ expectation: XCTestExpectation) {
            expectation.isInverted = true
            recorder.fulfillOnInput(expectation, includingConsumed: false)
        }
        
        public func get() throws {
            try recorder.value { (_, completion, remainingElements, consume) in
                if remainingElements.isEmpty == false {
                    return
                }
                if case let .failure(error) = completion {
                    throw error
                }
            }
        }
    }
}

extension PublisherExpectations {
    /// A publisher expectation which waits for the recorded publisher to emit
    /// `count` elements, or to complete.
    ///
    /// When waiting for this expectation, a `RecordingError.notEnoughElements`
    /// is thrown if the publisher does not publish `count` elements after last
    /// waited expectation. The publisher error is thrown if the publisher fails
    /// before publishing the next `count` elements.
    ///
    /// Otherwise, an array of exactly `count` elements is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfThreeElementsPublishesTwoThenOneElement() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///
    ///         var elements = try wait(for: recorder.next(2), timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar"])
    ///
    ///         elements = try wait(for: recorder.next(1), timeout: 1)
    ///         XCTAssertEqual(elements, ["baz"])
    ///     }
    public struct Next<Input, Failure: Error>: PublisherExpectation {
        let recorder: Recorder<Input, Failure>
        let count: Int
        
        init(recorder: Recorder<Input, Failure>, count: Int) {
            precondition(count >= 0, "Can't take a prefix of negative length")
            self.recorder = recorder
            self.count = count
        }
        
        public func _setup(_ expectation: XCTestExpectation) {
            if count == 0 {
                // Such an expectation is immediately fulfilled, by essence.
                expectation.expectedFulfillmentCount = 1
                expectation.fulfill()
            } else {
                expectation.expectedFulfillmentCount = count
                recorder.fulfillOnInput(expectation, includingConsumed: false)
            }
        }
        
        /// Returns the expected output, or throws an error if the
        /// expectation fails.
        ///
        /// For example:
        ///
        ///     // SUCCESS: no error
        ///     func testArrayOfThreeElementsSynchronouslyPublishesTwoThenOneElement() throws {
        ///         let publisher = ["foo", "bar", "baz"].publisher
        ///         let recorder = publisher.record()
        ///
        ///         var elements = try recorder.next(2).get()
        ///         XCTAssertEqual(elements, ["foo", "bar"])
        ///
        ///         elements = try recorder.next(1).get()
        ///         XCTAssertEqual(elements, ["baz"])
        ///     }
        public func get() throws -> [Input] {
            try recorder.value { (_, completion, remainingElements, consume) in
                if remainingElements.count >= count {
                    consume(count)
                    return Array(remainingElements.prefix(count))
                }
                if case let .failure(error) = completion {
                    throw error
                } else {
                    throw RecordingError.notEnoughElements
                }
            }
        }
    }
}

/// An error that may be thrown when waiting for publisher expectations.
public enum RecordingError: Error {
    /// The publisher did not complete.
    case notCompleted
    
    /// The publisher did not publish enough elements.
    /// For example, see `recorder.single`.
    case notEnoughElements
    
    /// The publisher did publish too many elements.
    /// For example, see `recorder.single`.
    case tooManyElements
}

extension RecordingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notCompleted:
            return "RecordingError.notCompleted"
        case .notEnoughElements:
            return "RecordingError.notEnoughElements"
        case .tooManyElements:
            return "RecordingError.tooManyElements"
        }
    }
}
