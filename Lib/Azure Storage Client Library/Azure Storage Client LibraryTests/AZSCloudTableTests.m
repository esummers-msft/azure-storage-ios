// -----------------------------------------------------------------------------------------
// <copyright file="AZSCloudTableTests.m" company="Microsoft">
//    Copyright 2016 Microsoft Corporation
//
//    Licensed under the MIT License;
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//      http://spdx.org/licenses/MIT
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
// </copyright>
// -----------------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import "AZSTestHelpers.h"
#import "AZSClient.h"
#import "AZSCoder.h"

AZS_ASSUME_NONNULL_BEGIN
@interface AZSSampleEntity : NSObject<NSCoding>

@property(strong) NSString *pk;
@property(strong) NSString *rk;
@property(strong) NSData *binary;
@property BOOL boolean;
@property double float64;
@property int32_t int32;
@property int64_t int64;
@property(strong) NSDate *date;
@property(strong) NSUUID *guid;

-(instancetype)initWithCoder:(NSCoder * __AZSNullable)aDecoder;

@end
AZS_ASSUME_NONNULL_END

@implementation AZSSampleEntity

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self) {
        self.pk = [aDecoder decodeObjectForKey:AZSCTableEntityPartitionKey];
        self.rk = [aDecoder decodeObjectForKey:AZSCTableEntityRowKey];
        self.binary = [aDecoder decodeObjectForKey:@"binary"];
        self.boolean = [aDecoder decodeBoolForKey:@"boolean"];
        self.float64 = [aDecoder decodeDoubleForKey:@"double"];
        self.int32 = [aDecoder decodeInt32ForKey:@"int32"];
        self.int64 = [aDecoder decodeInt64ForKey:@"int64"];
        self.date = [aDecoder decodeObjectForKey:@"datetime"];
        self.guid = [aDecoder decodeObjectForKey:@"guid"];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.pk forKey:AZSCTableEntityPartitionKey];
    [aCoder encodeObject:self.rk forKey:AZSCTableEntityRowKey];
    [aCoder encodeObject:self.binary forKey:@"binary"];
    [aCoder encodeBool:self.boolean forKey:@"boolean"];
    [aCoder encodeDouble:self.float64 forKey:@"double"];
    [aCoder encodeInt32:self.int32 forKey:@"int32"];
    [aCoder encodeInt64:self.int64 forKey:@"int64"];
    [aCoder encodeObject:self.date forKey:@"datetime"];
    [aCoder encodeObject:self.guid forKey:@"guid"];
}

-(BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    else if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
    AZSSampleEntity *entity = (AZSSampleEntity *)object;
    return [self.pk isEqualToString:entity.pk] &&
           [self.rk isEqualToString:entity.rk] &&
           [self.binary isEqualToData:entity.binary] &&
           [self.guid isEqual:entity.guid] &&
            self.boolean == entity.boolean &&
            self.int32 == entity.int32 &&
            self.int64 == entity.int64 &&
            self.float64 == entity.float64 &&
            fabs([self.date timeIntervalSinceDate:entity.date]) < AZSCDateAccuracyDelta;
}

@end

@interface AZSCloudTableTests : AZSTestBase
@end

@implementation AZSCloudTableTests

- (void)testStaticEntity
{
    AZSSampleEntity *ent = [[AZSSampleEntity alloc] initWithCoder:nil];
    
    ent.pk = @"testPK";
    ent.rk = @"testRK";
    ent.binary = [@"testing" dataUsingEncoding:NSUTF8StringEncoding];
    ent.boolean = YES;
    ent.float64 = 0.25;
    ent.int32 = 2147483647; // MAX_INT32
    ent.int64 = 2147483648; // MAX_INT32 + 1
    ent.date = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    ent.guid = [NSUUID UUID];
    
    AZSCoder *coder = [[AZSCoder alloc] init];
    [ent encodeWithCoder:coder];
    AZSSampleEntity *ent2 = [[AZSSampleEntity alloc] initWithCoder:coder];
    XCTAssertEqualObjects(ent, ent2);
    XCTAssertNil(coder.codingError);
    
    ent.boolean = NO;
    ent.float64 = -0.000000003;
    ent.int32 = -2147483648;          // MIN_INT32
    ent.int64 = -9223372036854775808; // MIN_INT64
    
    coder = [[AZSCoder alloc] init];
    [ent encodeWithCoder:coder];
    ent2 = [[AZSSampleEntity alloc] initWithCoder:coder];
    XCTAssertEqualObjects(ent, ent2);
    XCTAssertNil(coder.codingError);
}

- (void)testStaticEntityRoundtrip
{
    AZSSampleEntity *ent = [[AZSSampleEntity alloc] initWithCoder:nil];
    
    ent.pk = @"testPK";
    ent.rk = @"testRK";
    ent.binary = [@"testing" dataUsingEncoding:NSUTF8StringEncoding];
    ent.boolean = YES;
    ent.float64 = 0.25;
    ent.int32 = 1;
    ent.int64 = 9000000000;
    ent.date = [NSDate dateWithTimeIntervalSinceNow:0];
    ent.guid = [NSUUID UUID];
    
    AZSCoder *coder = [[AZSCoder alloc] init];
    [ent encodeWithCoder:coder];
    
    // Store properties as data
    NSError *error;
    NSData *data = [NSData dataWithBytesNoCopy:calloc(50000, sizeof(uint8_t)) length:50000 freeWhenDone:YES];
    NSOutputStream *outStream = [NSOutputStream outputStreamToBuffer:(uint8_t *)data.bytes capacity:data.length];
    [outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outStream open];
    NSMutableDictionary *props = [coder performSelector:@selector(properties)];
    [NSJSONSerialization writeJSONObject:props toStream:outStream options:0 error:&error];
    
    XCTAssertNil(error);
    [outStream close];
    
    // Read properties from data
    NSString *str = [NSString stringWithUTF8String:(char *)data.bytes];
    NSInputStream *inStream = [NSInputStream inputStreamWithData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    [inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inStream open];
    props = [NSJSONSerialization JSONObjectWithStream:inStream options:NSJSONReadingMutableContainers error:&error];
    
    XCTAssertNil(error);
    [inStream close];
    
    // Reset coder with roundtripped properties
    coder = [[AZSCoder alloc] init];
    [coder performSelector:@selector(setProperties:) withObject:props];
    
    AZSSampleEntity *ent2 = [[AZSSampleEntity alloc] initWithCoder:coder];
    XCTAssertEqualObjects(ent, ent2);
    XCTAssertNil(coder.codingError);
}

- (void)testDynamicEntity
{
    NSDictionary *props =
        @{@"binary":[@"testing" dataUsingEncoding:NSUTF8StringEncoding],
          @"bool":@YES,
          @"double":@(0.25),
          @"int32":@(1),
          @"int64":@(9000000000),
          @"date":[NSDate dateWithTimeIntervalSinceNow:0],
          @"guid":[NSUUID UUID],
          @"string":AZSCTrue};
    
    AZSDynamicTableEntity *ent = [[AZSDynamicTableEntity alloc] initWithPartitionKey:@"testPK" rowKey:@"testRK" properties:props];
    AZSCoder *coder = [[AZSCoder alloc] init];
    [ent encodeWithCoder:coder];
    AZSDynamicTableEntity *ent2 = [[AZSDynamicTableEntity alloc] initWithCoder:coder];

    XCTAssertEqualObjects(ent, ent2);
    XCTAssertNil(coder.codingError);
}

- (void)testEncodeDecodeBinary
{
    // Encode string as data
    AZSCoder *coder = [[AZSCoder alloc] init];
    NSString *testString = @"testing";
    NSData *data = [testString dataUsingEncoding:NSUTF8StringEncoding];
    [coder encodeBytes:data.bytes length:data.length forKey:@"binary"];
    
    uint8_t *bytes;
    for (int i = 0; i < 10; i++) {
        // Decode and store the byte array
        NSUInteger length;
        @autoreleasepool {
            length = 0;
            bytes = (uint8_t *) [coder decodeBytesForKey:@"binary" returnedLength:&length];
        }
        
        // Compare the bytes in the array to those in the original data object
        for (int j = 0; j < MIN(data.length, length); j++) {
            XCTAssertEqual(((uint8_t *) data.bytes)[j], bytes[j]);
        }
        
        // Ensure both have the same number of bytes and that there are no coding errors
        XCTAssertEqual(data.length, length);
        XCTAssertNil(coder.codingError);
        
        // Give the processor a chance to free any orphaned data objects
        [NSThread sleepForTimeInterval:.001];
    }
    
    // Ensure no issues arose after the final sleep
    for (int j = 0; j < testString.length; j++) {
        XCTAssertEqual(((uint8_t *) data.bytes)[j], bytes[j]);
    }
    
    XCTAssertNil(coder.codingError);
}

- (void)testDynamicEntityDateTime
{
    // TODO: Make sure to test that whole number of seconds and mightnight on January 1st roundtrip correctly from the service.
    
    // 09-07-1969 06:13:19.6666667
    NSDate *dateTime = [NSDate dateWithTimeIntervalSince1970:-10000000.3333333];
    for (int i = 0; i < 1000; i++) {
        NSDictionary *props = @{@"date":dateTime};
        
        // Roundtrip entity through AZSCoder
        AZSDynamicTableEntity *ent = [[AZSDynamicTableEntity alloc] initWithPartitionKey:@"testPK" rowKey:@"testRK" properties:props];
        AZSCoder *coder = [[AZSCoder alloc] init];
        [ent encodeWithCoder:coder];
        AZSDynamicTableEntity *ent2 = [[AZSDynamicTableEntity alloc] initWithCoder:coder];
       
        NSString *date = [coder performSelector:@selector(properties)][@"date"][1];
    
        XCTAssertEqualObjects(ent, ent2);
        XCTAssertNil(coder.codingError);
        
        // Ensure date string representation roundtrips too.
        coder = [[AZSCoder alloc] init];
        [ent2 encodeWithCoder:coder];
        NSString *date2 = [coder performSelector:@selector(properties)][@"date"][1];
        
        XCTAssertNil(coder.codingError);
        XCTAssertEqualObjects(date, date2);
        
        // Test both above and below XX.5000000
        dateTime = [NSDate dateWithTimeIntervalSinceReferenceDate:(dateTime.timeIntervalSinceReferenceDate + 2500000.499)];
    }
}

- (void)testConditionalObject
{
    NSString *testStringExpected1 = @"expected1";
    NSString *testStringExpected2 = @"expected2";
    NSString *testStringUnexpected = @"unexpected";
    AZSCoder *coder = [[AZSCoder alloc] init];
    
    // Ensure conditional objects encoded after they've been encoded unconditionally get correctly encoded.
    [coder encodeObject:testStringExpected1 forKey:@"unconditional"];
    [coder encodeConditionalObject:testStringExpected1 forKey:@"post1"];
    [coder encodeConditionalObject:testStringExpected1 forKey:@"post2"];
    
    XCTAssertNil(coder.codingError);
    XCTAssertEqualObjects(testStringExpected1, [coder decodeObjectForKey:@"post1"]);
    XCTAssertEqualObjects(testStringExpected1, [coder decodeObjectForKey:@"post2"]);
    
    // Ensure conditional objects encoded before they've been encoded unconditionally get correctly encoded.
    [coder encodeConditionalObject:testStringExpected2 forKey:@"pre1"];
    [coder encodeConditionalObject:testStringExpected2 forKey:@"pre2"];
    [coder encodeObject:testStringExpected2 forKey:@"unconditional2"];
    
    XCTAssertNil(coder.codingError);
    XCTAssertEqualObjects(testStringExpected2, [coder decodeObjectForKey:@"pre1"]);
    XCTAssertEqualObjects(testStringExpected2, [coder decodeObjectForKey:@"pre2"]);
    
    // Ensure objects that are only encoded conditionally do not get encoded at all.
    [coder encodeConditionalObject:testStringUnexpected forKey:@"unexpected1"];
    [coder encodeConditionalObject:testStringUnexpected forKey:@"unexpected2"];
    
    XCTAssertNil([coder decodeObjectForKey:@"unexpected1"]);
    XCTAssertNil([coder decodeObjectForKey:@"unexpected2"]);
    XCTAssertNotNil(coder.codingError);
}

- (void)testUnsupportedMethods
{
    AZSCoder *coder = [[AZSCoder alloc] init];
    NSUInteger num;
    [coder decodeValueOfObjCType:"" at:@""];
    XCTAssertNotNil(coder.codingError);
    
    coder = [[AZSCoder alloc] init];
    XCTAssertTrue(NULL == [coder decodeBytesWithReturnedLength:&num]);
    XCTAssertNotNil(coder.codingError);
    
    coder = [[AZSCoder alloc] init];
    XCTAssertNil([coder decodeObjectOfClass:[AZSCoder class] forKey:@"key"]);
    XCTAssertNotNil(coder.codingError);
    
    coder = [[AZSCoder alloc] init];
    [coder encodeRootObject:coder];
    XCTAssertNotNil(coder.codingError);
    
    coder = [[AZSCoder alloc] init];
    [coder encodeValueOfObjCType:"" at:(void *)coder];
    XCTAssertNotNil(coder.codingError);
    
    coder = [[AZSCoder alloc] init];
    [coder encodeDataObject:[NSData data]];
    XCTAssertNotNil(coder.codingError);
}

@end