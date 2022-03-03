// Copyright 2015-2022 Spotify AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if canImport(Combine)

import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Request {
    func publisher() -> ResponsePublisher<Void> {
        return ResponsePublisher(request: self)
    }

    func dataPublisher() -> ResponsePublisher<Data> {
        return ResponsePublisher(request: self)
    }

    func decodablePublisher<Value: Decodable>(decoder: ResponseDecoder = JSONDecoder()) -> ResponsePublisher<Value> {
        return ResponsePublisher(request: self, decoder: decoder)
    }

    func jsonPublisher(options: JSONSerialization.ReadingOptions = []) -> ResponsePublisher<Any> {
        return ResponsePublisher(request: self, options: options)
    }

    func serializablePublisher<Serializer: ResponseSerializer>(
        serializer: Serializer
    ) -> ResponsePublisher<Serializer.Output> {
        return ResponsePublisher(request: self, serializer: serializer)
    }
}

// MARK: -

private typealias ResponseProvider<Output> = (@escaping (Output) -> Void) -> Void

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct ResponsePublisher<Value>: Publisher {
    public typealias Output = Response<Value, Error>
    public typealias Failure = Never

    private let request: Request
    private let responseProvider: ResponseProvider<Output>

    fileprivate init(request: Request, responseProvider: @escaping ResponseProvider<Output>) {
        self.request = request
        self.responseProvider = responseProvider
    }

    public func receive<S: Subscriber>(subscriber: S) where S.Failure == Failure, S.Input == Output {
        let subscription = ResponseSubscription(
            request: request,
            responseProvider: responseProvider,
            subscriber: subscriber
        )
        subscriber.receive(subscription: subscription)
    }

    public func valuePublisher() -> AnyPublisher<Value, Error> {
        return setFailureType(to: Error.self).flatMap(\.result.publisher).eraseToAnyPublisher()
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension ResponsePublisher {
    init(request: Request) where Value == Void {
        self.init(request: request) { completion in
            request.response(completionHandler: completion)
        }
    }

    init(request: Request) where Value == Data {
        self.init(request: request) { completion in
            request.responseData(completionHandler: completion)
        }
    }

    init(request: Request, decoder: ResponseDecoder) where Value: Decodable {
        self.init(request: request) { completion in
            request.responseDecodable(decoder: decoder, completionHandler: completion)
        }
    }

    init(request: Request, options: JSONSerialization.ReadingOptions) where Value == Any {
        self.init(request: request) { completion in
            request.responseJSON(options: options, completionHandler: completion)
        }
    }

    init<Serializer: ResponseSerializer>(request: Request, serializer: Serializer) where Value == Serializer.Output {
        self.init(request: request) { completion in
            request.responseSerializable(serializer: serializer, completionHandler: completion)
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private final class ResponseSubscription<Output, DownstreamSubscriber: Subscriber>: Subscription where DownstreamSubscriber.Input == Output {
    private let request: Request
    private let responseProvider: ResponseProvider<Output>
    private let subscriber: DownstreamSubscriber

    init(request: Request, responseProvider: @escaping ResponseProvider<Output>, subscriber: DownstreamSubscriber) {
        self.request = request
        self.responseProvider = responseProvider
        self.subscriber = subscriber
    }

    func request(_ demand: Subscribers.Demand) {
        guard !request.isCancelled else { return }

        responseProvider { [subscriber] response in
            _ = subscriber.receive(response)
            subscriber.receive(completion: .finished)
        }
    }

    func cancel() {
        request.cancel()
    }
}

#endif
