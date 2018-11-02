//
//  Promise.swift
//  Prometo
//
//  Created by Ben Scheirman on 10/25/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation

class Promise<T> {
    
    var value: T? {
        if case let .fulfilled(value) = state {
            return value
        }
        return nil
    }
    
    var error: Error? {
        if case let .failed(error) = state {
            return error
        }
        return nil
    }
    
    struct Callback {
        let onFulfill: ((T)->Void)?
        let onError: ((Error)->Void)?
    }
    
    enum State {
        case pending
        case fulfilled(T)
        case failed(Error)
        
        var isCompleted: Bool {
            if case .pending = self {
                return false
            }
            return true
        }
    }
    
    private var state: State {
        didSet {
            runCallbacks()
        }
    }
    
    private var callbacks: [Callback] = []
    
    init(value: T) {
        state = .fulfilled(value)
    }
    
    init() {
        state = .pending
    }
    
    func then(_ thenBlock: @escaping (T) -> Void) -> Promise<T> {
        
        appendCallback(onFulfill: thenBlock, onError: nil)
        
        return self
    }
    
    func ensure(_ ensureBlock: @escaping ()->Void) {
        appendCallback(
            onFulfill: { _ in ensureBlock() },
            onError: { _ in ensureBlock() })
    }
    
    @discardableResult
    func `catch`(_ errorBlock: @escaping (Error)->Void) -> Promise<T> {
        appendCallback(onFulfill: nil, onError: errorBlock)
        return self
    }
    
    func map<S>(_ transformBlock: @escaping (T)->S) -> Promise<S> {
        let promise = Promise<S>()
        then { value in
            let transformedValue = transformBlock(value)
            promise.fulfill(transformedValue)
        }.catch { e in
            promise.fail(e)
        }
        return promise
    }
    
    func fulfill(_ value: T) {
        state = .fulfilled(value)
    }
    
    func fail(_ error: Error) {
        state = .failed(error)
    }
    
    private func appendCallback(onFulfill: ((T)->Void)?, onError: ((Error)->Void)?) {
        let callback = Callback(onFulfill: onFulfill, onError: onError)
        callbacks.append(callback)
        
        if state.isCompleted {
            dispatchCallback(callback: callback)
        }
    }
    
    private func runCallbacks() {
        guard state.isCompleted else { return }
        for callback in callbacks {
            dispatchCallback(callback: callback)
        }
    }
    
    private func dispatchCallback(callback: Callback) {
        switch state {
        case .fulfilled(let value): callback.onFulfill?(value)
        case .failed(let error): callback.onError?(error)
        case .pending: return
        }
    }
}
