// -----------------------------------------------------------------------------------------
// <copyright file="AZSTableRequestFactory.m" company="Microsoft">
//    Copyright 2015 Microsoft Corporation
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

#import "AZSTableRequestFactory.h"
#import "AZSAccessCondition.h"
#import "AZSCoder.h"
#import "AZSConstants.h"
#import "AZSContinuationToken.h"
#import "AZSEnums.h"
#import "AZSCopyState.h"
#import "AZSRequestFactory.h"
#import "AZSUtil.h"

@implementation AZSTableRequestFactory

+(NSMutableURLRequest *) insertTableEntity:(id<NSCoding>)entity AccessCondition:(AZSAccessCondition *)accessCondition urlComponents:(NSURLComponents *)urlComponents timeout:(NSTimeInterval)timeout
{
    NSMutableURLRequest *request = [AZSRequestFactory postRequestWithUrlComponents:urlComponents timeout:timeout];
    
    [AZSRequestFactory applyAccessConditionToRequest:request condition:accessCondition];
    
    AZSCoder *coder = [[AZSCoder alloc] init];
    [entity encodeWithCoder:coder];
    
    NSError *error;
    NSDictionary *properties = [coder decodeObjectForKey:AZSCTableEntityPropertiesInternal];
    
    // TODO: handle error
    NSData *body = [NSJSONSerialization dataWithJSONObject:properties options:0 error:&error];
    
    [request setHTTPBody:body];
    [request addValue:@"application/json" forHTTPHeaderField:AZSCContentType];
    
    return request;
}

+(NSMutableURLRequest *) retrieveTableEntityWithPartitionKey:(NSString *)partitionKey rowKey:(NSString *)rowKey accessCondition:(AZSAccessCondition *)accessCondition urlComponents:(NSURLComponents *)urlComponents timeout:(NSTimeInterval)timeout
{
    // TODO: IOS 8 - update this to use urlComponents.queryItems
    NSString *identifier = nil;
    if (rowKey) {
        identifier = [NSString stringWithFormat:@"PartitionKey='%@',RowKey='%@'", partitionKey, rowKey];
    }
    else {
        identifier = [NSString stringWithFormat:@"'%@'", partitionKey];
    }
    
    urlComponents.path = [AZSRequestFactory appendToPath:urlComponents.path stringToAppend:identifier];
    NSMutableURLRequest *request = [AZSRequestFactory getRequestWithUrlComponents:urlComponents timeout:timeout];
    //[request addValue:@"application/json" forHTTPHeaderField:AZSCContentType];
    
    [AZSRequestFactory applyAccessConditionToRequest:request condition:accessCondition];
    [request addValue:@"application/json;odata=minimalmetadata" forHTTPHeaderField:AZSCAccept];
    
    return request;
}

@end