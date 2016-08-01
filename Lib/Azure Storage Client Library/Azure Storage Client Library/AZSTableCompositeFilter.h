// <copyright file="AZSTableCompositeFilter.h" company="Microsoft">
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

AZS_ASSUME_NONNULL_BEGIN

@interface AZSTableCompositeFilter : AZSTableFilter

@property(readonly) int32_t filterCount; // number of property filters can’t exceed 15
@property(readonly) AZSTableCompositeFilterOperator operation; // And, Or, Not
@property(strong, readonly) AZSTableFilter *filter1;
@property(strong, readonly) AZSTableFilter *filter2;

@end

AZS_ASSUME_NONNULL_END