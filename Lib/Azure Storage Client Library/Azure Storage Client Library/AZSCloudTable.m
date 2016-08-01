// -----------------------------------------------------------------------------------------
// <copyright file="AZSCloudTable.m" company="Microsoft">
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
#import "AZSClient.h"
#import "AZSEnums.h"
#import "AZSExecutor.h"
#import "AZSMacros.h"
#import "AZSCloudTable.h"
#import "AZSCloudTableClient.h"
#import "AZSNavigationUtil.h"
#import "AZSUtil.h"
#import "AZSStorageCommand.h"
#import "AZSTableOperation.h"
#import "AZSTableRequestOptions.h"

@interface AZSCloudTable()

- (instancetype)init AZS_DESIGNATED_INITIALIZER;

// The table containing all of the account's tables.
+ (AZSCloudTable *)tablesTableForClient:(AZSCloudTableClient *)client;

@end

@implementation AZSCloudTable

- (instancetype)init
{
    self = [super init];
    return (self = nil);
}

- (instancetype)initWithName:(NSString *)tableName client:(AZSCloudTableClient *)client
{
    self = [super init];
    
    if (self) {
        _name = tableName;
        _client = client;
        _storageUri = [AZSStorageUri appendToStorageUri:_client.storageUri pathToAppend:_name];
    }
    
    return self;
}

- (instancetype)initWithUrl:(NSURL *)tableAbsoluteUrl error:(NSError **)error
{
    return [self initWithUrl:tableAbsoluteUrl credentials:nil error:error];
}

- (instancetype)initWithUrl:(NSURL *)tableAbsoluteUrl credentials:(AZSNullable AZSStorageCredentials *)credentials error:(NSError **)error
{
    return [self initWithStorageUri:[[AZSStorageUri alloc] initWithPrimaryUri:tableAbsoluteUrl] credentials:credentials error:error];
}

- (instancetype)initWithStorageUri:(AZSStorageUri *)tableAbsoluteUri error:(NSError **)error
{
    return [self initWithStorageUri:tableAbsoluteUri credentials:nil error:error];
}

- (instancetype)initWithStorageUri:(AZSStorageUri *)tableAbsoluteUri credentials:(AZSNullable AZSStorageCredentials *)credentials error:(NSError **)error
{
    self = [super init];
    if (self)
    {
        NSMutableArray *parseQueryResults = [AZSNavigationUtil parseBlobQueryAndVerifyWithStorageUri:tableAbsoluteUri];
        
        if (([credentials isSAS] || [credentials isSharedKey]) && (![parseQueryResults[1] isKindOfClass:[NSNull class]] && ([parseQueryResults[1] isSAS] || [parseQueryResults[1] isSharedKey]))) {
            *error = [NSError errorWithDomain:AZSErrorDomain code:AZSEInvalidArgument userInfo:nil];
            [[AZSUtil operationlessContext] logAtLevel:AZSLogLevelError withMessage:@"Multiple credentials provided."];
            return nil;
        }
        
        credentials = credentials ?: ([parseQueryResults[1] isKindOfClass:[NSNull class]] ? nil : parseQueryResults[1]);
        
        _storageUri = ([parseQueryResults[0] isKindOfClass:[NSNull class]] ? nil : parseQueryResults[0]);
        _client = [[AZSCloudTableClient alloc] initWithStorageUri: [AZSNavigationUtil getServiceClientBaseAddressWithStorageUri:_storageUri usePathStyle:[AZSUtil usePathStyleAddressing:[tableAbsoluteUri primaryUri]] error:error] credentials:credentials];
        if (*error) {
            return nil;
        }
        
        _name = [AZSNavigationUtil getContainerNameWithContainerAddress:_storageUri.primaryUri isPathStyle:[AZSUtil usePathStyleAddressing:_storageUri.primaryUri]];
        
        // TODO: Properties and metadata?
    }
    
    return self;
}

- (void)createTableWithCompletionHandler:(void (^)(NSError* __AZSNullable))completionHandler
{
    [self createTableWithAccessCondition:nil requestOptions:nil operationContext:nil completionHandler:completionHandler];
}

- (void)createTableWithAccessCondition:(AZSAccessCondition *)accessCondition requestOptions:(AZSTableRequestOptions *)requestOptions operationContext:(AZSOperationContext *)operationContext completionHandler:(void (^)(NSError* __AZSNullable))completionHandler
{
    AZSTableRequestOptions *modifiedOptions = [((AZSTableRequestOptions *) [AZSTableRequestOptions copyOptions:requestOptions]) applyDefaultsFromOptions:self.client.defaultRequestOptions];
    const AZSDynamicTableEntity *tableEntry = [[AZSDynamicTableEntity alloc] initWithPartitionKey:AZSCEmptyString rowKey:AZSCEmptyString properties:@{@"TableName" : self.name}];
    
    AZSTableOperation *create = [AZSTableOperation insertEntity:tableEntry];
    [create executeOnTable:[AZSCloudTable tablesTableForClient:self.client] accessCondition:accessCondition requestOptions:modifiedOptions operationContext:operationContext completionHandler:^(NSError *error, id<NSCoding> response) {
        completionHandler(error);
    }];
}

- (void)createTableIfNotExistsWithCompletionHandler:(void (^)(NSError* __AZSNullable, BOOL))completionHandler
{
    [self createTableIfNotExistsWithAccessCondition:nil requestOptions:nil operationContext:nil completionHandler:completionHandler];
}

- (void)createTableIfNotExistsWithAccessCondition:(AZSAccessCondition *)accessCondition requestOptions:(AZSTableRequestOptions *)requestOptions operationContext:(AZSOperationContext *)operationContext completionHandler:(void (^)(NSError* __AZSNullable, BOOL))completionHandler
{
    [self existsWithAccessCondition:accessCondition requestOptions:requestOptions operationContext:operationContext completionHandler:^(NSError *error, BOOL exists) {
        if (error) {
            completionHandler(error, NO);
        }
        else {
            if (exists) {
                completionHandler(nil, NO);
            }
            else {
                [self createTableWithAccessCondition:accessCondition requestOptions:requestOptions operationContext:operationContext completionHandler:^(NSError *error) {
                    if (error) {
                        completionHandler(error, NO);
                    }
                    else {
                        completionHandler(nil, YES);
                    }
                }];
            }
        }
    }];
}

- (void)existsWithCompletionHandler:(void (^)(NSError* __AZSNullable, BOOL))completionHandler
{
    [self existsWithAccessCondition:nil requestOptions:nil operationContext:nil completionHandler:completionHandler];
}

- (void)existsWithAccessCondition:(AZSNullable AZSAccessCondition *)accessCondition requestOptions:(AZSNullable AZSTableRequestOptions *)requestOptions operationContext:(AZSNullable AZSOperationContext *)operationContext completionHandler:(void (^)(NSError* __AZSNullable, BOOL))completionHandler
{
    AZSTableRequestOptions *modifiedOptions = [((AZSTableRequestOptions *) [AZSTableRequestOptions copyOptions:requestOptions]) applyDefaultsFromOptions:self.client.defaultRequestOptions];
    
    AZSTableOperation *retrieve = [AZSTableOperation retrieveEntityWithPartitionKey:self.name rowKey:nil entityType:nil];
    // TODO: full overload
    [retrieve executeOnTable:[AZSCloudTable tablesTableForClient:self.client] accessCondition:accessCondition requestOptions:modifiedOptions operationContext:operationContext completionHandler:^(NSError *error, id<NSCoding> response) {
        NSError *temp = error;
        int errorCode;
        do {
            errorCode = [temp.userInfo[AZSCHttpStatusCode] intValue];
            
            if (errorCode == 404) {
                error = nil;
                break;
            }
            
            temp = temp.userInfo[@"InnerError"];
        } while (temp && errorCode < 100);
        
        completionHandler(error, response != nil);
    }];
}

+ (AZSCloudTable *)tablesTableForClient:(AZSCloudTableClient *)client {
    return [[AZSCloudTable alloc] initWithName:@"Tables" client:client];
}

@end