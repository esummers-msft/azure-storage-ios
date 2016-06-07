// -----------------------------------------------------------------------------------------
// <copyright file="AZSCoder.m" company="Microsoft">
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

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "AZSConstants.h"
#import "AZSEnums.h"
#import "AZSErrors.h"
#import "AZSMacros.h"
#import "AZSCoder.h"
#import "AZSUtil.h"

@interface AZSCoder()

// Maps each property name to @[AZSEdmType, property value]
@property(strong) NSMutableDictionary *properties;

// This is a map from property value to the keys with which it has been conditionally encoded
@property(strong) NSMutableDictionary *conditionals;

// This is a map from each Edm.Binary's property name to an NSData representing it
@property(strong) NSMutableDictionary *binaries;

@end

@implementation AZSCoder

-(instancetype)init
{
    self = [super init];
    if (self) {
        _properties = [NSMutableDictionary dictionaryWithCapacity:2];
        _conditionals = [NSMutableDictionary dictionary];
        _binaries = [NSMutableDictionary dictionary];
        
        static dispatch_once_t once;
        dispatch_once(&once, ^() {
            // Track supported methods.
            unsigned int count;
            Method *methods = class_copyMethodList([self class], &count);
            NSMutableSet *supportedMethods = [NSMutableSet set];
            
            for (long i = 0; i < count; i++) {
                Method m = methods[i];
                [supportedMethods addObject:NSStringFromSelector(method_getName(m))];
            }
            
            // Handle unsupported encode/decode methods.
            methods = class_copyMethodList([NSCoder class], &count);
            for (long i = 0; i < count; i++) {
                Method m = methods[i];
                NSString *name = NSStringFromSelector(method_getName(m));
                
                if (![supportedMethods containsObject:name] && [name containsString:AZSCCode]) {
                    if([[NSString stringWithUTF8String:method_copyReturnType(m)] isEqualToString:AZSCVoid]) {
                        method_setImplementation(m, (IMP)unimplementedEncodeIMP);
                    }
                    else {
                        method_setImplementation(m, (IMP)unimplementedDecodeIMP);
                    }
                }
            }
        });
    }
    
    return self;
}

void unimplementedEncodeIMP(id self, SEL _cmd)
{
    AZSCoder *coder = (AZSCoder *)self;
    coder->_codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEInvalidArgument userInfo:nil];
}

void* unimplementedDecodeIMP(id self, SEL _cmd)
{
    AZSCoder *coder = (AZSCoder *)self;
    coder->_codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEInvalidArgument userInfo:nil];
    return NULL;
}

-(BOOL)decodeBoolForKey:(NSString *)key
{
    if (!_codingError) {
        if (([self.properties[key][0] intValue] == AZSEdmBoolean)) {
            return [self.properties[key][1] boolValue];
        }
    
        _codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEParseError userInfo:nil];
    }
    
    return nil;
}

-(const uint8_t *)decodeBytesForKey:(NSString *)key returnedLength:(NSUInteger *)lengthp
{
    if (!_codingError) {
        NSArray *property = self.properties[key];
        if ([property[0] intValue] == AZSEdmBinary) {
            if (!self.binaries[key]) {
                self.binaries[key] = [[NSData alloc] initWithBase64EncodedString:property[1] options:0];
            }
            
            NSData *data = self.binaries[key];
            *lengthp = data.length;
            return data.bytes;
        }
        
        _codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEParseError userInfo:nil];
    }
    
    *lengthp = 0;
    return NULL;
}

-(double)decodeDoubleForKey:(NSString *)key
{
    if (!_codingError) {
        if ([self.properties[key][0] intValue] == AZSEdmDouble) {
            return [self.properties[key][1] doubleValue];
        }
    
        _codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEParseError userInfo:nil];
    }
    
    return 0;
}

-(float)decodeFloatForKey:(NSString *)key
{
    if (!_codingError) {
        if ([self.properties[key][0] intValue] == AZSEdmDouble) {
            return [self.properties[key][1] floatValue];
        }
    
        _codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEParseError userInfo:nil];
    }
    
    return 0;
}

-(int)decodeIntForKey:(NSString *)key
{
    return [self decodeInt32ForKey:key];
}

-(int32_t)decodeInt32ForKey:(NSString *)key
{
    if (!_codingError) {
        if ([self.properties[key][0] intValue] == AZSEdmInt32) {
            return (int)[self.properties[key][1] integerValue];
        }
    
        _codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEParseError userInfo:nil];
    }
    
    return 0;
}

-(int64_t)decodeInt64ForKey:(NSString *)key
{
    if (!_codingError) {
        if ([self.properties[key][0] intValue] == AZSEdmInt64) {
            return [self.properties[key][1] longLongValue];
        }
    
        _codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEParseError userInfo:nil];
    }
    
    return 0;
}

-(NSInteger)decodeIntegerForKey:(NSString *)key
{
    return [self decodeInt64ForKey:key];
}

-(id)decodeObjectForKey:(NSString *)key
{
    // Dictionary
    if ([key isEqualToString:AZSCTableEntityProperties]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:self.properties.count];
        for (NSString *k in self.properties) {
            if (![k isEqualToString:AZSCTableEntityPartitionKey] && ![k isEqualToString:AZSCTableEntityRowKey]) {
                dict[k] = [self decodeObjectForKey:k];
            }
        }
        
        return dict;
    }
    // DateTime
    else if ([self.properties[key][0] intValue] == AZSEdmDateTime) {
        return [AZSUtil dateFromRoundtripFormat:self.properties[key][1]];
    }
    // Binary
    else if ([self.properties[key][0] intValue] == AZSEdmBinary) {
        NSUInteger length;
        return [[NSData alloc] initWithBytes:[self decodeBytesForKey:key returnedLength:&length] length:length];
    }
    // Guid
    else if ([self.properties[key][0] intValue] == AZSEdmGuid) {
        return [[NSUUID alloc] initWithUUIDString:self.properties[key][1]];
    }
    // String
    else if ([self.properties[key][0] intValue] == AZSEdmString) {
        return self.properties[key][1];
    }
    // Int32
    else if ([self.properties[key][0] intValue] == AZSEdmInt32) {
        return self.properties[key][1];
    }
    // Int 64
    else if ([self.properties[key][0] intValue] == AZSEdmInt64) {
        return @([self.properties[key][1] longLongValue]);
    }
    // Double
    else if ([self.properties[key][0] intValue] == AZSEdmDouble) {
        return self.properties[key][1];
    }
    // Boolean
    else if ([self.properties[key][0] intValue] == AZSEdmBoolean) {
        return self.properties[key][1];
    }
    // Invalid Type
    else if (![key isEqualToString:AZSCTableEntityEtag] && ![key isEqualToString:AZSCTableEntityTimestamp]) {
        _codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEParseError userInfo:nil];
    }
    
    return nil;
}

-(void)encodeBool:(BOOL)boolv forKey:(NSString *)key
{
    self.properties[key] = @[@(AZSEdmBoolean), @(boolv)];
}

-(void)encodeBytes:(const uint8_t *)bytesp length:(NSUInteger)lenv forKey:(NSString *)key
{
    // This will be converted into a string to be stored in self.properties
    [self encodeObject:[NSData dataWithBytesNoCopy:(void *)bytesp length:lenv freeWhenDone:NO] forKey:key];
}

-(void)encodeDouble:(double)realv forKey:(NSString *)key
{
    self.properties[key] = @[@(AZSEdmDouble), @(realv)];
}

-(void)encodeFloat:(float)realv forKey:(NSString *)key
{
    [self encodeDouble:realv forKey:key];
}

-(void)encodeInt:(int)intv forKey:(NSString *)key
{
    [self encodeInt32:intv forKey:key];
}

-(void)encodeInt32:(int32_t)intv forKey:(NSString *)key
{
    self.properties[key] = @[@(AZSEdmInt32), @(intv)];
}

-(void)encodeInt64:(int64_t)intv forKey:(NSString *)key
{
    self.properties[key] = @[@(AZSEdmInt64), [NSString stringWithFormat:@"%lld", intv]];
}

-(void)encodeInteger:(NSInteger)intv forKey:(NSString *)key
{
    [self encodeInt64:intv forKey:key];
}

-(void)encodeConditionalObject:(id)object forKey:(NSString *)key
{
    if (!self.conditionals[object]) {
        // If this object has never been previously encoded, make a set to store its key until it is unconditionally encoded.
        self.conditionals[object] = [NSMutableSet setWithObject:key];
    }
    else if (self.conditionals[object] == [NSNull null]) {
        // If this object has previously been unconditionally encoded, encode it now.
        [self encodeObject:object forKey:key];
    }
    else {
        // Otherwise wait to encode it until it has been encoded unconditionally.
        [self.conditionals[object] addObject:key];
    }
}

-(void)encodeObject:(id)object forKey:(NSString *)key
{
    if (self.conditionals[object] != [NSNull null]) {
        NSSet *keys = self.conditionals[object];
        
        // When this object is conditionally encoded later, encode it immediately.
        self.conditionals[object] = [NSNull null];
        if (keys) {
            // If this object has been conditionally encoded, encode it now.
            for (NSString *k in keys) {
                [self encodeObject:object forKey:k];
            }
        }
    }
    
    // DateTime
    if ([object isKindOfClass:[NSDate class]]) {
        self.properties[key] = @[@(AZSEdmDateTime), [AZSUtil convertDateToRoundtripFormat:object]];
    }
    // Binary
    else if ([object isKindOfClass:[NSData class]]) {
        self.binaries[key] = nil;
        self.properties[key] = @[@(AZSEdmBinary), [object base64EncodedStringWithOptions:0]];
    }
    // Int32, Int 64, Double, Boolean
    else if ([object isKindOfClass:[NSNumber class]]) {
        switch ([object objCType][0]) {
            case 'i': // Int32
                [self encodeInt32:[object intValue] forKey:key];
                break;
                
            case 'l': // Int 64
            case 'q':
                [self encodeInt64:[object longLongValue] forKey:key];
                break;
                
            case 'd': // Double
                [self encodeDouble:[object doubleValue] forKey:key];
                break;
                
            case 'c': // Boolean
                [self encodeBool:[object boolValue] forKey:key];
                break;
                
            default:  // Invalid Type
                _codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEInvalidArgument userInfo:nil];
                return;
        }
    }
    // Guid
    else if ([object isKindOfClass:[NSUUID class]]) {
        self.properties[key] = @[@(AZSEdmGuid), [object UUIDString]];
    }
    // String
    else if ([object isKindOfClass:[NSString class]]) {
        self.properties[key] = @[@(AZSEdmString), object];
    }
    // Dictionary (must have key = AZSCTableEntityProperties)
    else if ([object isKindOfClass:[NSDictionary class]] && [key isEqualToString:AZSCTableEntityProperties]) {
        for (id k in object) {
            if (![k respondsToSelector:@selector(isEqualToString:)] || [k isEqualToString:AZSCTableEntityProperties]) {
                // Nesting dictionaries is unsupported.
                _codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEInvalidArgument userInfo:nil];
                return;
            }
            
            [self encodeObject:object[k] forKey:k];
        }
    }
    // Invalid Type
    else {
        // TODO: Add helpful error messages once the error piping is clear.
        _codingError = [NSError errorWithDomain:AZSErrorDomain code:AZSEInvalidArgument userInfo:nil];
        return;
    }
}

@end