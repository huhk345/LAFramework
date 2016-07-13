//
//  WebViewURLIntercept.h
//  Pods
//
//  Created by LakeR on 16/7/13.
//
//

#import <Foundation/Foundation.h>
@class WebViewURLIntercept;

@protocol WebViewURLProtocolDelegate <NSObject>

@optional

/*! Called by an CustomHTTPProtocol instance to ask the delegate whether it's prepared to handle
 *  a particular authentication challenge.  Can be called on any thread.
 *  \param protocol The protocol instance itself; will not be nil.
 *  \param protectionSpace The protection space for the authentication challenge; will not be nil.
 *  \returns Return YES if you want the -customHTTPProtocol:didReceiveAuthenticationChallenge: delegate
 *  callback, or NO for the challenge to be handled in the default way.
 */

- (BOOL)WebViewURLProtocol:(WebViewURLIntercept *)protocol canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;

/*! Called by an CustomHTTPProtocol instance to request that the delegate process on authentication
 *  challenge. Will be called on the main thread. Unless the challenge is cancelled (see below)
 *  the delegate must eventually resolve it by calling -resolveAuthenticationChallenge:withCredential:.
 *  \param protocol The protocol instance itself; will not be nil.
 *  \param challenge The authentication challenge; will not be nil.
 */

- (void)WebViewURLProtocol:(WebViewURLIntercept *)protocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

/*! Called by an CustomHTTPProtocol instance to cancel an issued authentication challenge.
 *  Will be called on the main thread.
 *  \param protocol The protocol instance itself; will not be nil.
 *  \param challenge The authentication challenge; will not be nil; will match the challenge
 *  previously issued by -customHTTPProtocol:canAuthenticateAgainstProtectionSpace:.
 */

- (void)WebViewURLProtocol:(WebViewURLIntercept *)protocol didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end

@interface WebViewURLIntercept : NSURLProtocol


@end
