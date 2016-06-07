// -----------------------------------------------------------------------------------------
// <copyright file="AZSCoder.h" company="Microsoft">
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

@interface AZSCoder : NSCoder

@property(strong, readonly) NSError *codingError;

/** Conditionally encodes a reference to the object and associates it with the
 key only if the object was previously or is later encoded unconditionally.
 Note: The object's isEqual: method is used to determine whether it has been
 encoded unconditionally.
 
 @param object The object to conditionally encode.
 @param key The key to associate object with.
 */
-(void)encodeConditionalObject:(id)object forKey:(NSString *)key;

@end