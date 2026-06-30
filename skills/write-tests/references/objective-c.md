# Objective-C test conventions

## Framework & placement
- Use **XCTest**. Mocking: **OCMock**.
- Tests live in <App>Tests/, file name: <Class>Tests.m
- Each test class subclasses `XCTestCase`.

## Standard imports
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "UserRepository.h"

## Naming
- Method names describe behavior: `- (void)testReturnsUserWhenApiSucceeds`
- Use `setUp` / `tearDown` for shared fixtures; nil out mocks in `tearDown`.

## Mocking idiom (OCMock — ObjC-specific, do not mix with Swift Testing/XCTest stubs)
id mockApi = OCMProtocolMock(@protocol(UserApi));
OCMStub([mockApi fetchUser:@"1"]).andReturn(testUser);          // success
OCMStub([mockApi fetchUser:@"1"]).andThrow(someError);          // failure
OCMVerify([mockApi fetchUser:@"1"]);                            // verify call
// For async/callback APIs, capture the block:
OCMStub([mockApi fetchUser:OCMOCK_ANY completion:[OCMArg invokeBlockWithArgs:testUser, nil]]);

## Async rule
Use `XCTestExpectation` for async; test both the success and failure callbacks.

## Worked example
@interface UserRepositoryTests : XCTestCase
@property (nonatomic, strong) id mockApi;
@property (nonatomic, strong) UserRepository *repo;
@end

@implementation UserRepositoryTests

- (void)setUp {
    [super setUp];
    self.mockApi = OCMProtocolMock(@protocol(UserApi));
    self.repo = [[UserRepository alloc] initWithApi:self.mockApi];
}

- (void)tearDown {
    self.mockApi = nil;
    self.repo = nil;
    [super tearDown];
}

- (void)testReturnsUserOnSuccess {
    XCTestExpectation *exp = [self expectationWithDescription:@"fetch"];
    OCMStub([self.mockApi fetchUser:@"1"
                         completion:[OCMArg invokeBlockWithArgs:testUser, [NSNull null], nil]]);

    [self.repo getUser:@"1" completion:^(User *user, NSError *error) {
        XCTAssertEqualObjects(user, testUser);
        XCTAssertNil(error);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testReturnsErrorOnFailure {
    XCTestExpectation *exp = [self expectationWithDescription:@"fetch"];
    NSError *netError = [NSError errorWithDomain:@"net" code:-1 userInfo:nil];
    OCMStub([self.mockApi fetchUser:@"1"
                         completion:[OCMArg invokeBlockWithArgs:[NSNull null], netError, nil]]);

    [self.repo getUser:@"1" completion:^(User *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
