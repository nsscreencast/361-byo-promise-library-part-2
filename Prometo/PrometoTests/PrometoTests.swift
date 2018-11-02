//
//  PrometoTests.swift
//  PrometoTests
//
//  Created by Ben Scheirman on 10/25/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import XCTest
@testable import Prometo

class PrometoTests: XCTestCase {

    func testInitializeWithAValue() {
        let promise = Promise(value: 5)
        
        XCTAssertNotNil(promise.value)
        if let value = promise.value {
            XCTAssertEqual(value, 5)
        }
    }
    
    func testFulfillPromiseSetsValue() {
        let promise = Promise<String>()
        XCTAssertNil(promise.value)
        
        promise.fulfill("ok")
        
        XCTAssertNotNil(promise.value)
        if let value = promise.value {
            XCTAssertEqual(value, "ok")
        }
    }
    
    func testFulfillCallsThenBlock() {
        let promise = Promise<String>()
        
        let exp = expectation(description: "did not call then block")
        _ = promise.then { value in
            exp.fulfill()
            XCTAssertEqual(value, "ok")
        }
        
        promise.fulfill("ok")
        wait(for: [exp], timeout: 1.0)
    }
    
    func testFailCallsCatchBlock() {
        let promise = Promise<String>()
        
        let exp = expectation(description: "did not call catch block")
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        
        promise.then { _ in
            XCTFail()
        }.catch { error in
            exp.fulfill()
            let e = error as NSError
            XCTAssertEqual(e.domain, "test")
            XCTAssertEqual(e.code, 1)
        }
        
        promise.fail(testError)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testFailSetsError() {
        let promise = Promise<String>()
        
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        promise.fail(testError)
        XCTAssertNotNil(promise.error)
        if let error = promise.error as NSError? {
            XCTAssertEqual(error, testError)
        }
    }
    
    func testMapTransformsFutureValue() {
        let promise = Promise<Int>()
        
        let exp = expectation(description: "did not call then block")
        
        promise.map { x in
            return String(x)
        }.then { value in
            exp.fulfill()
            XCTAssertEqual(value, "5")
        }.catch { _ in
            XCTFail()
        }
        
        promise.fulfill(5)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testMapCarriesOverErrors() {
        let promise = Promise<Int>()
        
        let exp = expectation(description: "did not call catch block")
        
        promise.map { x in
            return String(x)
        }.then { _ in
            XCTFail()
        }.catch { error in
            exp.fulfill()
            let e = error as NSError
            XCTAssertEqual(e.domain, "test")
            XCTAssertEqual(e.code, 1)
        }
        
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        promise.fail(testError)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testEnsureCallsBlockEvenAfterThen() {
        let promise = Promise<Int>()
        
        let exp = expectation(description: "did not call ensure block")
        
        var thenCalled = false
        promise.then { _ in
            thenCalled = true
        }.ensure {
            exp.fulfill()
            XCTAssert(thenCalled)
        }
        promise.fulfill(1)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testEnsureCallsBlockEvenInError() {
        let promise = Promise<Int>()
        
        let exp = expectation(description: "did not call ensure block")
        
        var catchCalled = false
        promise.then { _ in
            //
        }.catch { _ in
            catchCalled = true
        }.ensure {
            exp.fulfill()
            XCTAssert(catchCalled)
        }
        
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        promise.fail(testError)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testAddingCallbacksAfterFulfill() {
        let promise = Promise<Int>()
        promise.fulfill(4)
        
        let exp = expectation(description: "did not call block")

        _ = promise.then { _ in
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
