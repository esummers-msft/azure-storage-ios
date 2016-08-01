// -----------------------------------------------------------------------------------------
// <copyright file="AZSCloudTableClient.h" company="Microsoft">
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
#import "AZSCloudClient.h"
#import "AZSEnums.h"
#import "AZSMacros.h"

AZS_ASSUME_NONNULL_BEGIN

@class AZSStorageUri;
@class AZSStorageCredentials;
@class AZSCloudTable;
@class AZSTableResultSegment;
@class AZSContinuationToken;
@class AZSTableRequestOptions;
@class AZSOperationContext;

// TODO: Figure out how to get this typedef to work with Appledocs.
//typedef void (^AZSListTablesSegmentedHandler) (NSError *, AZSTableResultSegment *);

/** The AZSCloudTableClient represents a the table service for a given storage account.
 
 The AZSCloudTableClient is used to perform service-level operations, including listing tables and
 (forthcoming) setting service-level properties.
 */
@interface AZSCloudTableClient : AZSCloudClient

/** The default AZSTableRequestOptions to use for all service calls made from this client.
 
 If you make a service call with the library and either do not provide an AZSTableRequestOptions object, or do
 not set some subset of the options, the options set in this object will be used as defaults.  This object is
 used for both calls made on this client object, and calls made with AZSCloudTable objects
 created from this AZSCloudTableClient object.*/
@property (strong, AZSNullable) AZSTableRequestOptions *defaultRequestOptions;

- (instancetype)initWithStorageUri:(AZSStorageUri *) storageUri credentials:(AZSStorageCredentials *) credentials AZS_DESIGNATED_INITIALIZER;

/** Initialize a local AZSCloudTable object
 
 This creates an AZSCloudTable object with the input name.
 
 TODO: Consider renaming this 'tableFromName'.  This is better Objective-C style, but may confuse users into
 thinking that this method creates a table on the service, which is does not.
 
 @warning This method does not make a service call.  If properties, metadata, etc have been set on the service
 for this table, this will not be reflected in the local table object.
 @param tableName The name of the table (part of the URL)
 @return The new table object.
 */
- (AZSCloudTable *)tableReferenceFromName:(NSString *)tableName;

// TODO: Figure out the correct way to appledoc the continuationHandler parameters.

/** Performs one segmented table listing operation.
 
 This method lists the tables on the table service for the associated account.  It will perform exactly one REST
 call, which will list tables beginning with the table represented in the AZSContinuationToken.  If no token
 is provided, it will list tables from the beginning.
 
 Any number of tables can be listed, from zero up to a set maximum.  Even if this method returns zero results, if
 the AZSContinuationToken in the result is not nil, there may be more tables on the service that have not been listed.
 
 @param continuationToken The token representing where the listing operation should start.
 @param completionHandler The block of code to execute with the results of the listing operation.
 
 | Parameter name | Description |
 |----------------|-------------|
 |NSError *       | Nil if the operation succeeded without error, error with details about the failure otherwise.|
 |AZSTableResultSegment * | The result segment containing the result of the listing operation.|
 */
- (void)listTablesSegmentedWithContinuationToken:(AZSNullable AZSContinuationToken *)continuationToken completionHandler:(void (^) (NSError * __AZSNullable, AZSTableResultSegment * __AZSNullable))completionHandler;

/** Performs one segmented table listing operation.
 
 This method lists the tables on the table service for the associated account.  It will perform exactly one REST
 call, which will list tables beginning with the table represented in the AZSContinuationToken.  If no token
 is provided, it will list tables from the beginning.  Only tables that begin with the input prefix will be listed.
 
 Any number of tables can be listed, from zero up to 'maxResults'.  Even if this method returns zero results, if
 the AZSContinuationToken in the result is not nil, there may be more tables on the service that have not been listed.
 
 @param continuationToken The token representing where the listing operation should start.
 @param prefix The prefix to use for table listing.  Only tables that begin with the input prefix
 will be listed.
 @param tableListingDetails Any additional data that should be returned in the listing operation.
 @param maxResults The maximum number of results to return.  The service will return up to this number of results.
 @param requestOptions The options to use for the request.
 @param operationContext The operation context to use for the call.
 @param completionHandler The block of code to execute with the results of the listing operation.
 
 | Parameter name | Description |
 |----------------|-------------|
 |NSError * | Nil if the operation succeeded without error, error with details about the failure otherwise.|
 |AZSTableResultSegment * | The result segment containing the result of the listing operation.|
 */
- (void)listTablesSegmentedWithContinuationToken:(AZSNullable AZSContinuationToken *)continuationToken prefix:(AZSNullable NSString *)prefix maxResults:(NSInteger)maxResults requestOptions:(AZSNullable AZSTableRequestOptions *)requestOptions operationContext:(AZSNullable AZSOperationContext *)operationContext completionHandler:(void (^) (NSError * __AZSNullable, AZSTableResultSegment * __AZSNullable))completionHandler;
@end

AZS_ASSUME_NONNULL_END