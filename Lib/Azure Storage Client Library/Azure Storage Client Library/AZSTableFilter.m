// -----------------------------------------------------------------------------------------
// <copyright file="AZSTableFilter.m" company="Microsoft">
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
#import "AZSTableFilter.h"
#import "AZSTableCompositeFilter.h"
#import "AZSTablePropertyFilter.h"

@interface AZSTableFilter()

@property (strong) NSString* filterString;
@property NSInteger operation;

@end

@implementation AZSTableFilter

- (instancetype) init {
    self = [super init];
    
    if (self) {
        
    }
    
    return self;
}

- (AZSTableCompositeFilter *) notFilter {
    if ([self respondsToSelector:@selector(filterCount)]) {
        // TODO: Type check?
        AZSTableCompositeFilterOperator op = (AZSTableCompositeFilterOperator) self.operation;
        if (op == AZSTableFilterOperatorNot) {
            return [self performSelector:@selector(filter1)];
        }
    }
    
    AZSTableCompositeFilter *filter = [[AZSTableCompositeFilter alloc] init];
    filter.filterString = [NSString stringWithFormat:@"not(%@)", self.filterString];
    return filter;
}

- (AZSTableCompositeFilter *) andFilter:(AZSTableFilter *)filter {
    AZSTableCompositeFilter *andFilter = [[AZSTableCompositeFilter alloc] init];
    andFilter.filterString = [NSString stringWithFormat:@"%@ and %@", self.filterString, filter.filterString];
    return andFilter;
}

- (AZSTableCompositeFilter *) orFilter:(AZSTableFilter *)filter {
    AZSTableCompositeFilter *orFilter = [[AZSTableCompositeFilter alloc] init];
    orFilter.filterString = [NSString stringWithFormat:@"%@ or %@", self.filterString, filter.filterString];
    return orFilter;
}

- (NSString *) toString {
    return self.filterString;
}

+ (AZSTablePropertyFilter *) filterOnProperty:(NSString *)property operator:(AZSTableFilterOperator)operator value:(NSString *)value {
    NSString *operation = nil;
    switch (operator) {
        case AZSTableFilterOperatorEqual:
            operation = @"eq";
            break;
            
        case AZSTableFilterOperatorNotEqual:
            operation = @"ne";
            break;
            
        case AZSTableFilterOperatorLessThan:
            operation = @"lt";
            break;
            
        case AZSTableFilterOperatorGreaterThan:
            operation = @"gt";
            break;
            
        case AZSTableFilterOperatorLessThanOrEqual:
            operation = @"le";
            break;
            
        case AZSTableFilterOperatorGreaterThanOrEqual:
            operation = @"ge";
            break;
            
        default:
            // TODO: Error
            return nil;
    }
    
    AZSTablePropertyFilter *filter = [[AZSTablePropertyFilter alloc] init];
    filter.filterString = [NSString stringWithFormat:@"%@ %@ \"%@\"", property, operation, value];
    return filter;
}

@end