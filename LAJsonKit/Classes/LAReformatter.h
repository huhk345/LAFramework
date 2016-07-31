//
//  LAReformater.h
//  Pods
//
//  Created by LakeR on 16/7/4.
//
//

#import <Foundation/Foundation.h>

#undef  __CLASS__
#define JsonIncludeNonNull  class __annotation__;


#define JsonIgnore          end @interface __CLASS__()
#define JsonMap(unused)     end @interface __CLASS__()
#define JsonFormat(unused)  end @interface __CLASS__()



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
