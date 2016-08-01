// -----------------------------------------------------------------------------------------
// <copyright file="AZSTableQuery.h" company="Microsoft">
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
#import "AZSTableFilter.h"

@class AZSAccessCondition;
@class AZSContinuationToken;
@class AZSCloudTableClient;
@class AZSOperationContext;
@class AZSTableRequestOptions;
@class AZSTableResultSegment;

AZS_ASSUME_NONNULL_BEGIN

@interface AZSTableQuery : NSObject

@property NSInteger segmentSize; // maxResults per segment

@property(strong) AZSTableFilter *filter;
@property(strong) NSMutableSet *properties; // contains names of properties selected, uses “*” if left empty
@property(strong) Class<NSCoding> entityClass; // uses AZSDynamicTableEntity as a default

// determines AZSEdmType from table name, pk, rk, property name, and property value
@property(copy) AZSEdmType(^propertyResolver)(NSString *, NSString *, NSString *, NSString *, NSString *);

- (instancetype) init AZS_DESIGNATED_INITIALIZER;

- (void)executeSegmentedWithTableClient:(AZSCloudTableClient *)client completionHandler:(void (^)(NSError *, AZSTableResultSegment *))completionHandler;
- (void)executeSegmentedWithTableClient:(AZSCloudTableClient *)client accessCondition:(AZSAccessCondition *)accessCondition requestOptions:(AZSTableRequestOptions *)requestOptions operationContext:(AZSOperationContext *)operationContext continuationToken:(AZSContinuationToken *)token completionHandler:(void (^)(NSError *, AZSTableResultSegment *))completionHandler;

@end

AZS_ASSUME_NONNULL_END