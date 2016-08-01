// -----------------------------------------------------------------------------------------
// <copyright file="AZSTableOperation.m" company="Microsoft">
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
#import "AZSCoder.h"
#import "AZSEnums.h"
#import "AZSExecutor.h"
#import "AZSMacros.h"
#import "AZSTableOperation.h"
#import "AZSTableRequestFactory.h"
#import "AZSTableRequestOptions.h"
#import "AZSDynamicTableEntity.h"
#import "AZSResponseParser.h"
#import "AZSStorageCommand.h"

@interface AZSTableOperation()

@property (nonatomic, copy) void(^executeBlock)(AZSCloudTable *, AZSAccessCondition *, AZSTableRequestOptions *, AZSOperationContext *, void (^)(NSError *, id<NSCoding>));
@property BOOL echoContent;

-(instancetype) initWithExecuteBlock:(void(^)(AZSCloudTable *, AZSAccessCondition *, AZSTableRequestOptions *, AZSOperationContext *, void (^)(NSError *, id<NSCoding>)))block AZS_DESIGNATED_INITIALIZER;

@end

@implementation AZSTableOperation

-(instancetype) init
{
    return [self initWithExecuteBlock:^(AZSCloudTable *table, AZSAccessCondition *accessCondition, AZSTableRequestOptions *requestOptions, AZSOperationContext *operationContext, void (^block)(NSError *, id<NSCoding>)) {}];
}

-(instancetype) initWithExecuteBlock:(void(^)(AZSCloudTable *, AZSAccessCondition *, AZSTableRequestOptions *, AZSOperationContext *, void (^)(NSError *, id<NSCoding>)))block
{
    self = [super init];
    
    if (self) {
        self.echoContent = YES;
        self.entityClass = [AZSDynamicTableEntity class];
        self.executeBlock = block;
    }
    
    return self;
}

+ (instancetype) insertEntity:(id<NSCoding>)entity
{
    AZSTableOperation *op = [[AZSTableOperation alloc] init];
    __weak AZSTableOperation *weakOp = op;
    
    op.executeBlock = ^(AZSCloudTable *table, AZSAccessCondition *accessCondition, AZSTableRequestOptions *requestOptions, AZSOperationContext *operationContext, void (^completionHandler)(NSError *, id<NSCoding>)) {
        AZSStorageCommand *command = [[AZSStorageCommand alloc] initWithStorageCredentials:table.client.credentials storageUri:table.storageUri operationContext:operationContext];
        
        [command setBuildRequest:^ NSMutableURLRequest *(NSURLComponents *urlComponents, NSTimeInterval timeout, AZSOperationContext *operationContext)
         {
             return [AZSTableRequestFactory insertTableEntity:entity AccessCondition:accessCondition urlComponents:urlComponents timeout:timeout];
         }];
        
        [command setAuthenticationHandler:table.client.authenticationHandler];
        
        [command setPreProcessResponse:^id(NSHTTPURLResponse *urlResponse, AZSRequestResult *requestResult, AZSOperationContext *operationContext) {
            return [AZSResponseParser preprocessResponseWithResponse:urlResponse requestResult:requestResult operationContext:operationContext];
        }];
        
        [command setPostProcessResponse:^id(NSHTTPURLResponse *urlResponse, AZSRequestResult *requestResult, NSOutputStream *outputStream, AZSOperationContext *operationContext, NSError **error) {
            if (weakOp.echoContent) {
                NSData *responseBody = [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
                NSError *err;
                AZSCoder *coder = [[AZSCoder alloc] initWithJsonDictionary:[NSJSONSerialization JSONObjectWithData:responseBody options:0 error:&err]];
                
                // TODO: Wrap err?
                return err ?: [[AZSDynamicTableEntity alloc] initWithCoder:coder];
            }
            
            return requestResult;
        }];
        
        [AZSExecutor ExecuteWithStorageCommand:command requestOptions:requestOptions operationContext:operationContext completionHandler:completionHandler];
        return;
    };
    
    return op;
}

+ (instancetype) retrieveEntityWithPartitionKey:(NSString *)pk rowKey:(NSString *)rk entityType:(Class<NSCoding>)type;
{
    AZSTableOperation *op = [[AZSTableOperation alloc] init];
    
    op.executeBlock = ^(AZSCloudTable *table, AZSAccessCondition *accessCondition, AZSTableRequestOptions *requestOptions, AZSOperationContext *operationContext, void (^completionHandler)(NSError *, id<NSCoding>)) {
        AZSStorageCommand *command = [[AZSStorageCommand alloc] initWithStorageCredentials:table.client.credentials storageUri:table.storageUri operationContext:operationContext];
        
        [command setBuildRequest:^ NSMutableURLRequest *(NSURLComponents *urlComponents, NSTimeInterval timeout, AZSOperationContext *operationContext)
         {
             return [AZSTableRequestFactory retrieveTableEntityWithPartitionKey:pk rowKey:rk accessCondition:accessCondition urlComponents:urlComponents timeout:timeout];
         }];
        
        [command setAuthenticationHandler:table.client.authenticationHandler];
        
        [command setPreProcessResponse:^id(NSHTTPURLResponse *urlResponse, AZSRequestResult *requestResult, AZSOperationContext *operationContext) {
            return [AZSResponseParser preprocessResponseWithResponse:urlResponse requestResult:requestResult operationContext:operationContext];
        }];
        
        [command setPostProcessResponse:^id(NSHTTPURLResponse *urlResponse, AZSRequestResult *requestResult, NSOutputStream *outputStream, AZSOperationContext *operationContext, NSError **error) {
            NSData *responseBody = [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
            NSError *err;
            AZSCoder *coder = [[AZSCoder alloc] initWithJsonDictionary:[NSJSONSerialization JSONObjectWithData:responseBody options:NSJSONReadingAllowFragments error:&err]];
            
            if (err) {
                return err;
            }
            
            // TODO: Wrap err?
            id<NSCoding> entity;
            if (type) {
                entity = [[(Class) type alloc] initWithCoder:coder];
            }
            else {
                entity = [[AZSDynamicTableEntity alloc] initWithCoder:coder];
            }
            
            return entity;
        }];
        
        [AZSExecutor ExecuteWithStorageCommand:command requestOptions:requestOptions operationContext:operationContext completionHandler:completionHandler];
        return;
    };
    
    return op;
}

- (void)executeOnTable:(AZSCloudTable *)table completionHandler:(void (^)(NSError *, id<NSCoding>))completionHandler
{
    [self executeOnTable:table accessCondition:nil requestOptions:nil operationContext:nil completionHandler:completionHandler];
}

- (void)executeOnTable:(AZSCloudTable *)table accessCondition:(AZSAccessCondition *)accessCondition requestOptions:(AZSTableRequestOptions *)requestOptions operationContext:(AZSOperationContext *)operationContext completionHandler:(void (^)(NSError *, id<NSCoding>))completionHandler
{
    if (!operationContext) {
        operationContext = [[AZSOperationContext alloc] init];
    }
    
    // TODO: apply defaults to options
    
    self.executeBlock(table, accessCondition, requestOptions, operationContext, completionHandler);
}

@end