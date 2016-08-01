// -----------------------------------------------------------------------------------------
// <copyright file="AZSCloudTableClient.m" company="Microsoft">
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
#import "AZSCloudTable.h"
#import "AZSCloudTableClient.h"
#import "AZSEnums.h"
#import "AZSExecutor.h"
#import "AZSMacros.h"
#import "AZSCloudTable.h"
#import "AZSNoOpAuthenticationHandler.h"
#import "AZSSharedKeyTableAuthenticationHandler.h"
#import "AZSStorageCommand.h"
#import "AZSResponseParser.h"
#import "AZSTableRequestOptions.h"

@interface AZSCloudTableClient()

@end

@implementation AZSCloudTableClient

- (instancetype)initWithStorageUri:(AZSStorageUri *) storageUri credentials:(AZSStorageCredentials *) credentials
{
    return (self = [super initWithStorageUri:storageUri credentials:credentials]);
}

- (AZSCloudTable *)tableReferenceFromName:(NSString *)tableName
{
    return [[AZSCloudTable alloc] initWithName:tableName client:self];
}

- (void)listTablesSegmentedWithContinuationToken:(AZSNullable AZSContinuationToken *)continuationToken completionHandler:(void (^) (NSError * __AZSNullable, AZSTableResultSegment * __AZSNullable))completionHandler
{
    [self listTablesSegmentedWithContinuationToken:continuationToken prefix:nil maxResults:-1 requestOptions:nil operationContext:nil completionHandler:completionHandler];
}

- (void)listTablesSegmentedWithContinuationToken:(AZSNullable AZSContinuationToken *)continuationToken prefix:(AZSNullable NSString *)prefix maxResults:(NSInteger)maxResults requestOptions:(AZSNullable AZSTableRequestOptions *)requestOptions operationContext:(AZSNullable AZSOperationContext *)operationContext completionHandler:(void (^) (NSError * __AZSNullable, AZSTableResultSegment * __AZSNullable))completionHandler
{
    if (!operationContext)
    {
        operationContext = [[AZSOperationContext alloc] init];
    }
    
    // TODO: Why is this cast necessary?
    AZSTableRequestOptions *modifiedOptions = (AZSTableRequestOptions *) [[AZSTableRequestOptions copyOptions:requestOptions] applyDefaultsFromOptions:self.defaultRequestOptions];
    AZSStorageCommand * command = [[AZSStorageCommand alloc] initWithStorageCredentials:self.credentials storageUri:self.storageUri operationContext:operationContext];
    command.allowedStorageLocation = AZSAllowedStorageLocationPrimaryOrSecondary;
    
    [command setBuildRequest:^ NSMutableURLRequest * (NSURLComponents *urlComponents, NSTimeInterval timeout, AZSOperationContext *operationContext)
     {
         return nil;//[AZSTableRequestFactory listTablesWithPrefix:prefix containerListingDetails:containerListingDetails maxResults:maxResults continuationToken:continuationToken urlComponents:urlComponents timeout:timeout operationContext:operationContext];
     }];
    
    [command setAuthenticationHandler:self.authenticationHandler];
    
    [command setPreProcessResponse:^id(NSHTTPURLResponse * urlResponse, AZSRequestResult * requestResult, AZSOperationContext * operationContext) {
        return [AZSResponseParser preprocessResponseWithResponse:urlResponse requestResult:requestResult operationContext:operationContext];
    }];
    
    [command setPostProcessResponse:^id(NSHTTPURLResponse *urlResponse, AZSRequestResult *requestResult, NSOutputStream *outputStream, AZSOperationContext *operationContext, NSError **error) {
        /*AZSListTablesResponse *listTablesResponse = [AZSListTablesResponse parseListTablesResponseWithData:[outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey] operationContext:operationContext error:error];
        
        if (*error)
        {
            return nil;
        }
        
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:[listTablesResponse.containerListItems count]];
        for (AZSTableListItem *tableListItem in listTablesResponse.containerListItems)
        {
            AZSCloudBlobContainer *container = [[AZSCloudTable alloc] initWithName:containerListItem.name client:self];
            container.properties = containerListItem.properties;
            container.metadata = containerListItem.metadata;
            [results addObject:container];
        }
        
        AZSContinuationToken *continuationToken = nil;
        if (listContainersResponse.nextMarker != nil && listContainersResponse.nextMarker.length > 0)
        {
            continuationToken = [AZSContinuationToken tokenFromString:listContainersResponse.nextMarker withLocation:requestResult.targetLocation];
        }*/
        return nil;//[AZSContainerResultSegment segmentWithResults:results continuationToken:continuationToken];
    }];
    
    [AZSExecutor ExecuteWithStorageCommand:command requestOptions:modifiedOptions operationContext:operationContext completionHandler:completionHandler];
}

-(void)setAuthenticationHandlerWithCredentials:(AZSStorageCredentials *)credentials
{
    if ([credentials isSharedKey])
    {
        self.authenticationHandler = [[AZSSharedKeyTableAuthenticationHandler alloc] initWithStorageCredentials:credentials];
    }
    else
    {
        self.authenticationHandler = [[AZSNoOpAuthenticationHandler alloc] init];
    }
}

@end