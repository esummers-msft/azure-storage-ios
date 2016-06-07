// -----------------------------------------------------------------------------------------
// <copyright file="AZSDynamicTableEntity.h" company="Microsoft">
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
#import "AZSEnums.h"
#import "AZSMacros.h"

AZS_ASSUME_NONNULL_BEGIN

@interface AZSDynamicTableEntity : NSObject<NSCoding>

/* Unique identifier for a partition within a particular table. */
@property(strong) NSString *rowKey;

/* Unique identifier for an entity within a particular table. */
@property(strong) NSString *partitionKey;

/* Value used to determine whether an entity has changed since last read. */
@property(strong, readonly, AZSNullable) NSString *etag;

/* The service's record of when the entity was last modified. */
@property(strong, readonly, AZSNullable) NSDate *timestamp;

/* A map from the property names to valid values for this particular DynamicTableEntity. */
@property(strong, AZSNullable) NSDictionary *properties;

/** Initializes a newly allocated AZSDynamicTableEntity object.
 
 @param partitionKey The partition key for this entity.
 @param rowKey The rowkey for this entity.
 @param properties The dictionary of properties for this entity.
 @return The newly allocated instance.
 */
- (instancetype) initWithPartitionKey:(NSString *)partitionKey rowKey:(NSString *)rowKey properties:(NSDictionary *)properties AZS_DESIGNATED_INITIALIZER;

/** Initializes a newly allocated AZSDynamicTableEntity object.
 
 @param decoder The NSCoder from which to decode this entity's properties.
 @return The newly allocated instance.
 */
- (instancetype) initWithCoder:(NSCoder *)decoder AZS_DESIGNATED_INITIALIZER;

/** Encodes this entity using the given NSCoder.
 
 @param encoder The NSCoder from which to encode this entity's properties.
 */
- (void) encodeWithCoder:(NSCoder *)encoder;

@end

AZS_ASSUME_NONNULL_END