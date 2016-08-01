// -----------------------------------------------------------------------------------------
// <copyright file="AZSTableRequestOptions.h" company="Microsoft">
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
#import "AZSRequestOptions.h"

AZS_ASSUME_NONNULL_BEGIN

@interface AZSTableRequestOptions : AZSRequestOptions

@property AZSMetadataLevel metadataLevel; // minimalmetadata(default) or nometadata

-(instancetype)init AZS_DESIGNATED_INITIALIZER;

-(instancetype)applyDefaultsFromOptions:(AZSTableRequestOptions * __AZSNullable)sourceOptions;

@end

AZS_ASSUME_NONNULL_END