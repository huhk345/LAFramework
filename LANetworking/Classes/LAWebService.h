//
//  LAWebService.h
//  Pods
//
//  Created by LakeR on 16/7/2.
//
//

#import <Foundation/Foundation.h>
@class RACSignal;


//RESTful http Method
#define GET(unused)
#define POST(unused)	
#define DELETE(unused)
#define PUT(unused)
#define PATCH(unused)


//Body Construct annotation
#define Body(unused)
#define Headers(...)
#define Cache(unused)

//
#define Part(unused)
#define Header(unused)



#define LANSignal(unused) RACSignal*

@protocol LAWebService <NSObject>

- (NSDictionary*)methodAnnotation;

@end
