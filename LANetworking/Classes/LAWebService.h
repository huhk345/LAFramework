//
//  LAWebService.h
//  Pods
//
//  Created by LakeR on 16/7/2.
//
//

#import <Foundation/Foundation.h>
@class RACSignal;

#pragma mark - Class Annotation

#define BASEURL(unused) class ___Annotations___;


#pragma mark - Method Annotation

//RESTful http Method
#define GET(unused)     required
#define POST(unused)    required
#define DELETE(unused)  required
#define PUT(unused)     required
#define PATCH(unused)   required
#define HEAD(unused)    required

//http headers
#define Headers(...)    required


//body type default is formData
#define FormData        required
#define FormUrlEncode   required
#define FormRaw         required

//Cache time example: Cache(1D) Cache(1H)
#define Cache(unused)   required

//network param like
#define Part(unused)









#define LANSignal(unused)   RACSignal*

@protocol LAWebService <NSObject>

- (NSDictionary*)methodAnnotation;

@end
