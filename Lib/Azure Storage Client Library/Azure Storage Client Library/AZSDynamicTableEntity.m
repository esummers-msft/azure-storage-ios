// -----------------------------------------------------------------------------------------
// <copyright file="AZSDynamicTableEntity.m" company="Microsoft">
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
#import "AZSConstants.h"
#import "AZSEnums.h"
#import "AZSMacros.h"
#import "AZSDynamicTableEntity.h"

@interface AZSDynamicTableEntity()

- (instancetype) init AZS_DESIGNATED_INITIALIZER;

@end

@implementation AZSDynamicTableEntity

- (instancetype) init
{
    return nil;
}

- (instancetype) initWithPartitionKey:(NSString *)partitionKey rowKey:(NSString *)rowKey  properties:(NSDictionary *)properties
{
    self = [super init];
    if (self) {
        _partitionKey = partitionKey;
        _rowKey = rowKey;
        _properties = properties;
    }
    
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        if ([decoder containsValueForKey:AZSCTableEntityPartitionKey]) {
            _partitionKey = [decoder decodeObjectForKey:AZSCTableEntityPartitionKey];
        }
        
        if ([decoder containsValueForKey:AZSCTableEntityRowKey]) {
            _rowKey = [decoder decodeObjectForKey:AZSCTableEntityRowKey];
        }
        
        _properties = [decoder decodeObjectForKey:AZSCTableEntityProperties];
        
        if ([decoder containsValueForKey:AZSCTableEntityEtag]) {
            _etag = [decoder decodeObjectForKey:AZSCTableEntityEtag];
        }
        
        if ([decoder containsValueForKey:AZSCTableEntityTimestamp]) {
            _timestamp = [decoder decodeObjectForKey:AZSCTableEntityTimestamp];
        }
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.properties forKey:AZSCTableEntityProperties];
    
    if (self.partitionKey.length > 0) {
        [encoder encodeObject:self.partitionKey forKey:AZSCTableEntityPartitionKey];
    }
    
    if (self.rowKey.length > 0) {
        [encoder encodeObject:self.rowKey forKey:AZSCTableEntityRowKey];
    }
}

- (BOOL) isEqual:(id)ent
{
    if (self == ent) {
        return YES;
    }
    else if (![ent respondsToSelector:@selector(properties)]) {
        return NO;
    }
    
    AZSDynamicTableEntity *entity = (AZSDynamicTableEntity *)ent;
    if (self.properties.count != entity.properties.count) {
        return NO;
    }
    
    if (![self.partitionKey isEqualToString:entity.partitionKey] ||
            ![self.rowKey isEqualToString:entity.rowKey]) {
        return NO;
    }
    
    for (NSString *key in self.properties) {
        if ([self.properties[key] isEqual:entity.properties[key]]) {
            continue;
        }
        // Edm.String
        else if ([self.properties[key] respondsToSelector:@selector(isEqualToString:)]
                 && [entity.properties[key] respondsToSelector:@selector(isEqualToString:)]
                 && [self.properties[key] isEqualToString:entity.properties[key]]) {
            
            continue;
        }
        // Edm.Binary
        else if ([self.properties[key] respondsToSelector:@selector(isEqualToData:)]
                 && [entity.properties[key] respondsToSelector:@selector(isEqualToData:)]
                 && [self.properties[key] isEqualToData:entity.properties[key]]) {
            
            continue;
        }
        // Edm.Boolean, Edm.Int32, Edm.Int64, Edm.Double
        else if ([self.properties[key] respondsToSelector:@selector(isEqualToNumber:)]
                 && [entity.properties[key] respondsToSelector:@selector(isEqualToNumber:)]
                 && [self.properties[key] isEqualToNumber:entity.properties[key]]) {
            
            continue;
        }
        // Edm.DateTime
        else if ([self.properties[key] respondsToSelector:@selector(timeIntervalSinceDate:)]
                 && [entity.properties[key] respondsToSelector:@selector(timeIntervalSinceDate:)]) {
            
            if(fabs([self.properties[key] timeIntervalSinceDate: entity.properties[key]]) > AZSCDateAccuracyDelta) {
                return NO;
            }
            
            continue;
        }
        // Unrecognized
        else {
            return NO;
        }
    }
    
    return YES;
}

@end