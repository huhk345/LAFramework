//
//  LAReformater.h
//  Pods
//
//  Created by LakeR on 16/7/4.
//
//

#import <Foundation/Foundation.h>

#define JsonIncludeNull  class __annotation__;


#define JsonIgnore                  end @interface __CLASS__()
#define JsonMap(unused)             end @interface __CLASS__()
#define JsonFormat(unused)          end @interface __CLASS__()
#define JsonTypeReference(unused)   end @interface __CLASS__()



@protocol LAReformatter <NSObject>

@required
-(void)convertFromDictionary:(NSDictionary *)dictionary;

@end


@protocol LAObjectConverter <NSObject>

@optional
-(NSString *)convertToString:(NSError **)error;

@optional
-(NSDictionary *)convertToDictionary:(NSError **)error;


@end
