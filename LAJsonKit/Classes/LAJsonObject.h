//
//  LAJsonObject.h
//  Pods
//
//  Created by LakeR on 16/7/26.
//
//

#import <Foundation/Foundation.h>
#import "LAReformatter.h"


@interface LAJsonObject : NSObject<LAReformatter,LAObjectConverter>

-(instancetype)initWithDictionary:(NSDictionary *)dic error:(NSError **)error;

@end
