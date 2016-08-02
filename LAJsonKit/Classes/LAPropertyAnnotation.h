//
//  LAPropertyAnnotation.h
//  Pods
//
//  Created by LakeR on 16/8/1.
//
//

#import <Foundation/Foundation.h>

@interface LAPropertyAnnotation : NSObject

@property (nonatomic,copy) NSString *property;

@property (nonatomic,strong) NSString *reformatter;

@property (nonatomic,strong) NSString *typeReference;

@property (nonatomic,assign) BOOL ignore;

- (instancetype)initWithDictionary:(NSDictionary *)dic;

@end
