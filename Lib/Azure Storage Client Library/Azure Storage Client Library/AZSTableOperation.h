// -----------------------------------------------------------------------------------------
// <copyright file="AZSTableOperation.h" company="Microsoft">
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

@class AZSCloudTable;
@class AZSAccessCondition;
@class AZSOperationContext;
@class AZSTableRequestOptions;

AZS_ASSUME_NONNULL_BEGIN

@interface AZSTableOperation : NSObject

@property(strong) Class<NSCoding> entityClass; // uses AZSDynamicTableEntity as a default

- (instancetype) init;

+ (instancetype) insertEntity:(id<NSCoding>)entity; // delete, merge, etc will be similar
+ (instancetype) retrieveEntityWithPartitionKey:(NSString *)pk rowKey:(NSString *)rk entityType:(Class<NSCoding> __AZSNullable)type;

- (void)executeOnTable:(AZSCloudTable *)table completionHandler:(void (^)(NSError *, id<NSCoding>))completionHandler;
- (void)executeOnTable:(AZSCloudTable *)table accessCondition:(AZSAccessCondition *)accessCondition requestOptions:(AZSTableRequestOptions *)requestOptions operationContext:(AZSOperationContext *)operationContext completionHandler:(void (^)(NSError *, id<NSCoding>))completionHandler;

@end

AZS_ASSUME_NONNULL_END