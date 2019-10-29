// Copyright 2019 CEX.​IO Ltd (UK)
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
//
//  Created by Ihor Vovk on 5/21/19.

import Foundation
import RxSwift
import Starscream
import CocoaLumberjack

class SocketManager {
    
    init() {
        socket.disableSSLCertValidation = true
        socket.delegate = self
        socket.pongDelegate = self
    }
    
    func subscribe(event: String, subscriptionMessage: @escaping () -> SocketMessage) -> Observable<SocketMessage> {
        return .create { [weak self] observer -> Disposable in
            guard let `self` = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            let subscribeEvent = self.socketStatusSubject.distinctUntilChanged().filter { $0 == .connected }.subscribe { [weak self] status in
                guard let `self` = self else { return }
                
                let message = subscriptionMessage()
                if let data = message.dataRepresentation {
                    self.socket.write(data: data)
                }
            }
            
            let observeEvent = self.socketMessageSubject.filter { $0.event == event }.subscribe(onNext: { message in
                observer.onNext(message)
            }, onError: { error in
                observer.onError(error)
            }, onCompleted: {
                observer.onCompleted()
            })
            
            return Disposables.create(self.connectedSocket.subscribe(), subscribeEvent, observeEvent)
        }
    }
    
    // MARK: - Implementation
    
    private enum SocketStatus {
        case connected
        case disconnected
    }
    
    private let socket: WebSocket = {
        if let configurationPath = Bundle(for: SocketManager.self).path(forResource: "Configuration", ofType: "plist"), let configuration = NSDictionary(contentsOfFile: configurationPath), let webSocketURL = configuration["WebSocketURL"] as? String {
            return WebSocket(url: URL(string: webSocketURL)!)
        } else {
            DDLogError("Failed to find web socket URL")
            return WebSocket(url: URL(string: "https://apple.com")!)
        }
    }()
    
    private let socketStatusSubject = BehaviorSubject<SocketStatus>(value: .disconnected)
    private let socketMessageSubject = PublishSubject<SocketMessage>()
    private let socketPongSubject = PublishSubject<Void>()
    
    private lazy var connectedSocket: Observable<Void> = {
        return Observable.create { [weak self] observer -> Disposable in
            guard let `self` = self else {
                return Disposables.create()
            }
            
            let connectSocket = Observable<Int>.timer(.seconds(0), period: .seconds(5), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if !self.socket.isConnected {
                    self.socket.connect()
                }
            })
            
            let pingSocket = self.socketStatusSubject.distinctUntilChanged().filter { $0 == .connected }.flatMapLatest { _ -> Observable<Int> in
                return Observable<Int>.timer(.seconds(0), period: .seconds(30), scheduler: MainScheduler.instance).takeUntil(self.socketStatusSubject.filter { $0 == .disconnected })
            }.do(onNext: { [weak self] _ in
                self?.socket.write(ping: Data())
            }).flatMapLatest { _ -> Observable<Int> in
                return Observable<Int>.timer(.seconds(1), period: nil, scheduler: MainScheduler.instance).takeUntil(self.socketPongSubject)
            }.subscribe(onNext: { [weak self] _ in
                self?.socket.disconnect()
            })
            
            let disconnectSocket = Disposables.create  { [weak self] in
                self?.socket.disconnect()
            }
            
            return Disposables.create(connectSocket, pingSocket, disconnectSocket)
        }.share()
    }()
}

extension SocketManager: WebSocketDelegate {
    
    public func websocketDidConnect(socket: WebSocketClient) {
        socketStatusSubject.onNext(.connected)
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        socketStatusSubject.onNext(.disconnected)
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        if let message = SocketMessage(text: text) {
            socketMessageSubject.onNext(message)
        }
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        if let message = SocketMessage(data: data) {
            socketMessageSubject.onNext(message)
        }
    }
}

extension SocketManager: WebSocketPongDelegate {
    
    func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        socketPongSubject.onNext(())
    }
}
