// -----------------------------------------------------------------------------------------
// <copyright file="AZSCloudTable.h" company="Microsoft">
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

@class AZSAccessCondition;
@class AZSStorageUri;
@class AZSStorageCredentials;
@class AZSOperationContext;
@class AZSTableRequestOptions;
@class AZSTableOperation;
@class AZSTableQuery;
@class AZSContinuationToken;
@class AZSCloudTableClient;
@class AZSTableResultSegment;

@interface AZSCloudTable : NSObject

@property(copy) NSString *name;
@property(strong, readonly) AZSStorageUri *storageUri;
@property(strong, readonly) AZSCloudTableClient *client;

/** Initializes a newly allocated AZSCloudTable object.
 
 @param tableName The name of this table.
 @param client The AZSCloudTableClient representing the table service that this table is in.
 @returns The newly allocated object.
 */
- (instancetype)initWithName:(NSString *)tableName client:(AZSCloudTableClient *)client AZS_DESIGNATED_INITIALIZER;

/** Initializes a newly allocated AZSCloudTable object.
 
 @param tableAbsoluteUrl The absolute URL to this table.
 @param error A pointer to a NSError*, to be set in the event of failure.
 @returns The newly allocated object.
 */
- (instancetype)initWithUrl:(NSURL *)tableAbsoluteUrl error:(NSError **)error;

/** Initializes a newly allocated AZSCloudTable object.
 
 @param tableAbsoluteUrl The absolute URL to this table.
 @param credentials The AZSStorageCredentials used to authenticate to the table.
 @param error A pointer to a NSError*, to be set in the event of failure.
 @returns The newly allocated object.
 */
- (instancetype)initWithUrl:(NSURL *)tableAbsoluteUrl credentials:(AZSNullable AZSStorageCredentials *)credentials error:(NSError **)error;

/** Initializes a newly allocated AZSCloudTable object.
 
 @param tableAbsoluteUri The StorageURI to this table.
 @param error A pointer to a NSError*, to be set in the event of failure.
 @returns The newly allocated object.
 */
- (instancetype)initWithStorageUri:(AZSStorageUri *)tableAbsoluteUri error:(NSError **)error;

/** Initializes a newly allocated AZSCloudTable object.
 
 @param tableAbsoluteUri The StorageURI to this table.
 @param credentials The AZSStorageCredentials used to authenticate to the table.
 @param error A pointer to a NSError*, to be set in the event of failure.
 @returns The newly allocated object.
 */
- (instancetype)initWithStorageUri:(AZSStorageUri *)tableAbsoluteUri credentials:(AZSNullable AZSStorageCredentials *)credentials error:(NSError **)error AZS_DESIGNATED_INITIALIZER;

/** Creates the table on the service.  Will fail if the table already exists.
 
 @param completionHandler The block of code to execute when the create call completes.
 
 | Parameter name | Description |
 |----------------|-------------|
 |NSError *       | Nil if the operation succeeded without error, error with details about the failure otherwise.|
 */
- (void)createTableWithCompletionHandler:(void (^)(NSError* __AZSNullable))completionHandler;

/** Makes a service call to detect whether or not the table already exists on the service.
 
 @param completionHandler The block of code to execute when the exists call completes.
 
 | Parameter name | Description |
 |----------------|-------------|
 |NSError *       | Nil if the operation succeeded without error, error with details about the failure otherwise.|
 |BOOL            | YES if the table exists on the service, NO otherwise.|
 */
- (void)existsWithCompletionHandler:(void (^)(NSError* __AZSNullable, BOOL))completionHandler;

/** Makes a service call to detect whether or not the table already exists on the service.
 
 @param accessCondition The access condition for the request.
 @param requestOptions The options to use for the request.
 @param operationContext The operation context to use for the call.
 @param completionHandler The block of code to execute when the exists call completes.
 
 | Parameter name | Description |
 |----------------|-------------|
 |NSError *       | Nil if the operation succeeded without error, error with details about the failure otherwise.|
 |BOOL            | YES if the table exists on the service, NO otherwise.|
 */
- (void)existsWithAccessCondition:(AZSNullable AZSAccessCondition *)accessCondition requestOptions:(AZSNullable AZSTableRequestOptions *)requestOptions operationContext:(AZSNullable AZSOperationContext *)operationContext completionHandler:(void (^)(NSError* __AZSNullable, BOOL))completionHandler;

/** Creates the table on the service.  Will return success if the table already exists.
 
 @param completionHandler The block of code to execute when the create call completes.
 
 | Parameter name | Description |
 |----------------|-------------|
 |NSError *       | Nil if the operation succeeded without error, error with details about the failure otherwise.|
 |BOOL            | YES if the table was created by this operation, NO otherwise.|
 */
- (void)createTableIfNotExistsWithCompletionHandler:(void (^)(NSError* __AZSNullable, BOOL))completionHandler;

/** Creates the table on the service.  Will return success if the table already exists.
 
 @param accessCondition The access condition for the request.
 @param requestOptions The options to use for the request.
 @param operationContext The operation context to use for the call.
 @param completionHandler The block of code to execute when the create call completes.
 
 | Parameter name | Description |
 |----------------|-------------|
 |NSError *       | Nil if the operation succeeded without error, error with details about the failure otherwise.|
 |BOOL            | YES if the table was created by this operation, NO otherwise.|
 */
- (void)createTableIfNotExistsWithAccessCondition:(AZSAccessCondition * __AZSNullable)accessCondition requestOptions:(AZSTableRequestOptions * __AZSNullable)requestOptions operationContext:(AZSOperationContext * __AZSNullable)operationContext completionHandler:(void (^)(NSError* __AZSNullable, BOOL))completionHandler;

@end

AZS_ASSUME_NONNULL_END