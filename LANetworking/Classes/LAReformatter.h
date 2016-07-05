//
//  LAReformater.h
//  Pods
//
//  Created by LakeR on 16/7/4.
//
//

#import <Foundation/Foundation.h>

@protocol LAReformatter <NSObject>

-(id)convertToObject:(NSDictionary *)dictionary;

@end


@protocol LAObjectConvert <NSObject>

@optional
-(NSString *)convertToString:(NSError **)error;

@optional
-(NSDictionary *)convertToDictionary:(NSError **)error;


@end
