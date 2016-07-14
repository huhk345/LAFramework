//
//  WebViewURLIntercept.m
//  Pods
//
//  Created by LakeR on 16/7/13.
//
//

#import "QNSURLSessionDemux.h"
#import "CacheStoragePolicy.h"
#import "WebViewURLIntercept.h"

static NSString * kRecursiveRequestFlagProperty = @"com.laker.webviewURLProtocal";

typedef void (^ChallengeCompletionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * credential);

static id<WebViewURLProtocolDelegate> sDelegate;

@interface WebViewURLIntercept()

@property (atomic, strong, readwrite) NSThread *                        clientThread;       ///< The thread on which we should call the client.

/*! The run loop modes in which to call the client.
 *  \details The concurrency control here is complex.  It's set up on the client
 *  thread in -startLoading and then never modified.  It is, however, read by code
 *  running on other threads (specifically the main thread), so we deallocate it in
 *  -dealloc rather than in -stopLoading.  We can be sure that it's not read before
 *  it's set up because the main thread code that reads it can only be called after
 *  -startLoading has started the connection running.
 */

@property (atomic, copy,   readwrite) NSArray *                         modes;
@property (atomic, assign, readwrite) NSTimeInterval                    startTime;          ///< The start time of the request; written by client thread only; read by any thread.
@property (atomic, strong, readwrite) NSURLSessionDataTask *            task;               ///< The NSURLSession task for that request; client thread only.
@property (atomic, strong, readwrite) NSURLAuthenticationChallenge *    pendingChallenge;
@property (atomic, copy,   readwrite) ChallengeCompletionHandler        pendingChallengeCompletionHandler;  ///< The completion handler that matches pendingChallenge; main thread only.

@property (atomic, assign, readwrite) BOOL                              needProcess;
@property (atomic, strong, readwrite) NSMutableData *                   mutableData;
@end


@implementation WebViewURLIntercept

+(void)load{
    [NSURLProtocol registerClass:self];
}

+ (id<WebViewURLProtocolDelegate>)delegate{
    id<WebViewURLProtocolDelegate> result;
    
    @synchronized (self) {
        result = sDelegate;
    }
    return result;
}

+ (void)setDelegate:(id<WebViewURLProtocolDelegate>)newValue{
    @synchronized (self) {
        sDelegate = newValue;
    }
}

+ (QNSURLSessionDemux *)sharedDemux{
    static dispatch_once_t      sOnceToken;
    static QNSURLSessionDemux * sDemux;
    dispatch_once(&sOnceToken, ^{
        NSURLSessionConfiguration *     config;
        
        config = [NSURLSessionConfiguration defaultSessionConfiguration];
        // You have to explicitly configure the session to use your own protocol subclass here
        // otherwise you don't see redirects <rdar://problem/17384498>.
        config.protocolClasses = @[ self ];
        sDemux = [[QNSURLSessionDemux alloc] initWithConfiguration:config];
    });
    return sDemux;
}



#pragma mark - NSURLProtocal override methods
+ (BOOL)canInitWithRequest:(NSURLRequest *)request{
    NSString* userAgent = request.allHTTPHeaderFields[@"User-Agent"];
    if (userAgent && [[self getWebViewUserAgentTest] evaluateWithObject:userAgent] &&
        [[self propertyForKey:kRecursiveRequestFlagProperty inRequest:request] boolValue] != YES &&
        [[request.HTTPMethod lowercaseString] isEqualToString:@"get"]) {
        return YES;
    }else{
        return NO;
    }
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request{
    return request;
}


+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading{
    NSMutableURLRequest *   recursiveRequest;
    NSMutableArray *        calculatedModes;
    NSString *              currentMode;
    
    // At this point we kick off the process of loading the URL via NSURLSession.
    // The thread that calls this method becomes the client thread.
    
    assert(self.clientThread == nil);           // you can't call -startLoading twice
    assert(self.task == nil);
    
    // Calculate our effective run loop modes.  In some circumstances (yes I'm looking at
    // you UIWebView!) we can be called from a non-standard thread which then runs a
    // non-standard run loop mode waiting for the request to finish.  We detect this
    // non-standard mode and add it to the list of run loop modes we use when scheduling
    // our callbacks.  Exciting huh?
    //
    // For debugging purposes the non-standard mode is "WebCoreSynchronousLoaderRunLoopMode"
    // but it's better not to hard-code that here.
    
    assert(self.modes == nil);
    calculatedModes = [NSMutableArray array];
    [calculatedModes addObject:NSDefaultRunLoopMode];
    currentMode = [[NSRunLoop currentRunLoop] currentMode];
    if ( (currentMode != nil) && ! [currentMode isEqual:NSDefaultRunLoopMode] ) {
        [calculatedModes addObject:currentMode];
    }
    self.modes = calculatedModes;
    assert([self.modes count] > 0);
    
    // Create new request that's a clone of the request we were initialised with,
    // except that it has our 'recursive request flag' property set on it.
    
    recursiveRequest = [[self request] mutableCopy];
    assert(recursiveRequest != nil);
    
    [[self class] setProperty:@YES forKey:kRecursiveRequestFlagProperty inRequest:recursiveRequest];
    
    self.startTime = [NSDate timeIntervalSinceReferenceDate];
    
    // Latch the thread we were called on, primarily for debugging purposes.
    
    self.clientThread = [NSThread currentThread];
    
    self.mutableData = [NSMutableData data];
    
    // Once everything is ready to go, create a data task with the new request.
    
    self.task = [[[self class] sharedDemux] dataTaskWithRequest:recursiveRequest delegate:self modes:self.modes];
    assert(self.task != nil);
    
    [self.task resume];
}

- (void)stopLoading{
    // The implementation just cancels the current load (if it's still running).
    
    DLogDebug(@"protocol %p stop (elapsed %.1f)",self, [NSDate timeIntervalSinceReferenceDate] - self.startTime);
    assert(self.clientThread != nil);           // someone must have called -startLoading
    
    // Check that we're being stopped on the same thread that we were started
    // on.  Without this invariant things are going to go badly (for example,
    // run loop sources that got attached during -startLoading may not get
    // detached here).
    //
    // I originally had code here to bounce over to the client thread but that
    // actually gets complex when you consider run loop modes, so I've nixed it.
    // Rather, I rely on our client calling us on the right thread, which is what
    // the following assert is about.
    
    assert([NSThread currentThread] == self.clientThread);
    
    [self cancelPendingChallenge];
    if (self.task != nil) {
        [self.task cancel];
        self.task = nil;
        // The following ends up calling -URLSession:task:didCompleteWithError: with NSURLErrorDomain / NSURLErrorCancelled,
        // which specificallys traps and ignores the error.
    }
    // Don't nil out self.modes; see property declaration comments for a a discussion of this.
}



#pragma mark * Authentication challenge handling

/*! Performs the block on the specified thread in one of specified modes.
 *  \param thread The thread to target; nil implies the main thread.
 *  \param modes The modes to target; nil or an empty array gets you the default run loop mode.
 *  \param block The block to run.
 */

- (void)performOnThread:(NSThread *)thread modes:(NSArray *)modes block:(dispatch_block_t)block{
    // thread may be nil
    // modes may be nil
    assert(block != nil);
    
    if (thread == nil) {
        thread = [NSThread mainThread];
    }
    if ([modes count] == 0) {
        modes = @[ NSDefaultRunLoopMode ];
    }
    [self performSelector:@selector(onThreadPerformBlock:) onThread:thread withObject:[block copy] waitUntilDone:NO modes:modes];
}

/*! A helper method used by -performOnThread:modes:block:. Runs in the specified context
 *  and simply calls the block.
 *  \param block The block to run.
 */

- (void)onThreadPerformBlock:(dispatch_block_t)block{
    assert(block != nil);
    block();
}

/*! Called by our NSURLSession delegate callback to pass the challenge to our delegate.
 *  \description This simply passes the challenge over to the main thread.
 *  We do this so that all accesses to pendingChallenge are done from the main thread,
 *  which avoids the need for extra synchronisation.
 *
 *  By the time this runes, the NSURLSession delegate callback has already confirmed with
 *  the delegate that it wants the challenge.
 *
 *  Note that we use the default run loop mode here, not the common modes.  We don't want
 *  an authorisation dialog showing up on top of an active menu (-:
 *
 *  Also, we implement our own 'perform block' infrastructure because Cocoa doesn't have
 *  one <rdar://problem/17232344> and CFRunLoopPerformBlock is inadequate for the
 *  return case (where we need to pass in an array of modes; CFRunLoopPerformBlock only takes
 *  one mode).
 *  \param challenge The authentication challenge to process; must not be nil.
 *  \param completionHandler The associated completion handler; must not be nil.
 */

- (void)didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(ChallengeCompletionHandler)completionHandler{
    assert(challenge != nil);
    assert(completionHandler != nil);
    assert([NSThread currentThread] == self.clientThread);
    DLogDebug(@"protocol %p challenge %@ received",self, [[challenge protectionSpace] authenticationMethod]);
    
    [self performOnThread:nil modes:nil block:^{
        [self mainThreadDidReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    }];
}

/*! The main thread side of authentication challenge processing.
 *  \details If there's already a pending challenge, something has gone wrong and
 *  the routine simply cancels the new challenge.
 *  \param challenge The authentication challenge to process; must not be nil.
 *  \param completionHandler The associated completion handler; must not be nil.
 */

- (void)mainThreadDidReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(ChallengeCompletionHandler)completionHandler{
    assert(challenge != nil);
    assert(completionHandler != nil);
    assert([NSThread isMainThread]);
    
    if (self.pendingChallenge != nil) {
        
        // Our delegate is not expecting a second authentication challenge before resolving the
        // first.  Likewise, NSURLSession shouldn't send us a second authentication challenge
        // before we resolve the first.  If this happens, assert, log, and cancel the challenge.
        //
        // Note that we have to cancel the challenge on the thread on which we received it,
        // namely, the client thread.
        DLogDebug(@"protocol %p challenge %@ cancelled; other challenge pending", self,  [[challenge protectionSpace] authenticationMethod]);
        [self clientThreadCancelAuthenticationChallenge:challenge completionHandler:completionHandler];
    } else {
        id<WebViewURLProtocolDelegate>  strongDelegate;
        
        strongDelegate = [[self class] delegate];
        
        // Remember that this challenge is in progress.
        
        self.pendingChallenge = challenge;
        self.pendingChallengeCompletionHandler = completionHandler;
        
        // Pass the challenge to the delegate.
        BOOL result = YES;
        if ([strongDelegate respondsToSelector:@selector(WebViewURLProtocol:didReceiveAuthenticationChallenge:)]) {
            DLogDebug(@"protocol %p challenge %@ passed to delegate", self , [[challenge protectionSpace] authenticationMethod]);
            result = [strongDelegate WebViewURLProtocol:self didReceiveAuthenticationChallenge:self.pendingChallenge];
        }
        NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        NSURLCredential *credential = nil;
        if (result) {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            if (credential) {
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else {
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
        
        
        if (completionHandler) {
            completionHandler(disposition, credential);
        }

        
    }
}


/*! Cancels an authentication challenge that hasn't made it to the pending challenge state.
 *  \details This routine is called as part of various error cases in the challenge handling
 *  code.  It cancels a challenge that, for some reason, we've failed to pass to our delegate.
 *
 *  The routine is always called on the main thread but bounces over to the client thread to
 *  do the actual cancellation.
 *  \param challenge The authentication challenge to cancel; must not be nil.
 *  \param completionHandler The associated completion handler; must not be nil.
 */

- (void)clientThreadCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(ChallengeCompletionHandler)completionHandler{
#pragma unused(challenge)
    assert(challenge != nil);
    assert(completionHandler != nil);
    assert([NSThread isMainThread]);
    
    [self performOnThread:self.clientThread modes:self.modes block:^{
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }];
}

/*! Cancels an authentication challenge that /has/ made to the pending challenge state.
 *  \details This routine is called by -stopLoading to cancel any challenge that might be
 *  pending when the load is cancelled.  It's always called on the client thread but
 *  immediately bounces over to the main thread (because .pendingChallenge is a main
 *  thread only value).
 */

- (void)cancelPendingChallenge{
    assert([NSThread currentThread] == self.clientThread);
    
    // Just pass the work off to the main thread.  We do this so that all accesses
    // to pendingChallenge are done from the main thread, which avoids the need for
    // extra synchronisation.
    
    [self performOnThread:nil modes:nil block:^{
        if (self.pendingChallenge == nil) {
            // This is not only not unusual, it's actually very typical.  It happens every time you shut down
            // the connection.  Ideally I'd like to not even call -mainThreadCancelPendingChallenge when
            // there's no challenge outstanding, but the synchronisation issues are tricky.  Rather than solve
            // those, I'm just not going to log in this case.
            //
            // [[self class] customHTTPProtocol:self logWithFormat:@"challenge not cancelled; no challenge pending"];
        } else {
            id<WebViewURLProtocolDelegate>  strongeDelegate;
            NSURLAuthenticationChallenge *  challenge;
            
            strongeDelegate = [[self class] delegate];
            
            challenge = self.pendingChallenge;
            self.pendingChallenge = nil;
            self.pendingChallengeCompletionHandler = nil;
            
            if ([strongeDelegate respondsToSelector:@selector(customHTTPProtocol:didCancelAuthenticationChallenge:)]) {
                DLogDebug(@"protocol %p challenge %@ cancellation passed to delegate", self , [[challenge protectionSpace] authenticationMethod]);
                [strongeDelegate WebViewURLProtocol:self didCancelAuthenticationChallenge:challenge];
            } else {
                DLogError(@"protocol %p challenge %@ cancellation failed; no delegate method", self ,[[challenge protectionSpace] authenticationMethod]);
            }
        }
    }];
}

- (void)resolveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge withCredential:(NSURLCredential *)credential
{
    assert(challenge == self.pendingChallenge);
    // credential may be nil
    assert([NSThread isMainThread]);
    assert(self.clientThread != nil);
    
    if (challenge != self.pendingChallenge) {
        DLogError(@"protocol %p challenge resolution mismatch (%@ / %@)", self, challenge, self.pendingChallenge);
        // This should never happen, and we want to know if it does, at least in the debug build.
        assert(NO);
    } else {
        ChallengeCompletionHandler  completionHandler;
        
        // We clear out our record of the pending challenge and then pass the real work
        // over to the client thread (which ensures that the challenge is resolved on
        // the same thread we received it on).
        
        completionHandler = self.pendingChallengeCompletionHandler;
        self.pendingChallenge = nil;
        self.pendingChallengeCompletionHandler = nil;
        
        [self performOnThread:self.clientThread modes:self.modes block:^{
            if (credential == nil) {
                DLogDebug(@"protocol %p challenge %@ resolved without credential", self, [[challenge protectionSpace] authenticationMethod]);
                completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
            } else {
                DLogDebug(@"protocol %p challenge %@ resolved with <%@ %p>", self, [[challenge protectionSpace] authenticationMethod], [credential class], credential);
                completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            }
        }];
    }
}

#pragma mark * NSURLSession delegate callbacks

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler{
    NSMutableURLRequest *    redirectRequest;
    
#pragma unused(session)
#pragma unused(task)
    assert(task == self.task);
    assert(response != nil);
    assert(newRequest != nil);
#pragma unused(completionHandler)
    assert(completionHandler != nil);
    assert([NSThread currentThread] == self.clientThread);
    
    DLogDebug(@"protocol %p will redirect from %@ to %@",self, [response URL], [newRequest URL]);
    
    // The new request was copied from our old request, so it has our magic property.  We actually
    // have to remove that so that, when the client starts the new request, we see it.  If we
    // don't do this then we never see the new request and thus don't get a chance to change
    // its caching behaviour.
    //
    // We also cancel our current connection because the client is going to start a new request for
    // us anyway.
    
    assert([[self class] propertyForKey:kRecursiveRequestFlagProperty inRequest:newRequest] != nil);
    
    redirectRequest = [newRequest mutableCopy];
    [[self class] removePropertyForKey:kRecursiveRequestFlagProperty inRequest:redirectRequest];
    
    // Tell the client about the redirect.
    
    [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
    
    // Stop our load.  The CFNetwork infrastructure will create a new NSURLProtocol instance to run
    // the load of the redirect.
    
    // The following ends up calling -URLSession:task:didCompleteWithError: with NSURLErrorDomain / NSURLErrorCancelled,
    // which specificallys traps and ignores the error.
    
    [self.task cancel];
    
    [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
    BOOL        result;
    id<WebViewURLProtocolDelegate> strongeDelegate;
    
#pragma unused(session)
#pragma unused(task)
    assert(task == self.task);
    assert(challenge != nil);
    assert(completionHandler != nil);
    assert([NSThread currentThread] == self.clientThread);
    
    // Ask our delegate whether it wants this challenge.  We do this from this thread, not the main thread,
    // to avoid the overload of bouncing to the main thread for challenges that aren't going to be customised
    // anyway.
    
    strongeDelegate = [[self class] delegate];
    
    result = [[[challenge protectionSpace] authenticationMethod] isEqual:NSURLAuthenticationMethodServerTrust];

    // If the client wants the challenge, kick off that process.  If not, resolve it by doing the default thing.
    
    if (result) {
        DLogDebug(@"protocol %p can authenticate %@", self, [[challenge protectionSpace] authenticationMethod]);
        [self didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    } else {
        DLogDebug(@"protocol %p cannot authenticate %@", self , [[challenge protectionSpace] authenticationMethod]);
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSURLCacheStoragePolicy cacheStoragePolicy;
    NSInteger               statusCode;
    
#pragma unused(session)
#pragma unused(dataTask)
    assert(dataTask == self.task);
    assert(response != nil);
    assert(completionHandler != nil);
    assert([NSThread currentThread] == self.clientThread);
    
    // Pass the call on to our client.  The only tricky thing is that we have to decide on a
    // cache storage policy, which is based on the actual request we issued, not the request
    // we were given.
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        cacheStoragePolicy = CacheStoragePolicyForRequestAndResponse(self.task.originalRequest, (NSHTTPURLResponse *) response);
        statusCode = [((NSHTTPURLResponse *) response) statusCode];
    } else {
        assert(NO);
        cacheStoragePolicy = NSURLCacheStorageNotAllowed;
        statusCode = 42;
    }
    
    DLogDebug(@"protocol %p received response %zd / %@ with cache storage policy %zu", self , (ssize_t) statusCode, [response URL], (size_t) cacheStoragePolicy);
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSString *contentType = [((NSHTTPURLResponse *)response) allHeaderFields][@"Content-Type"];
        if ([contentType containsString:@"javascript"] || [contentType containsString:@"html"]) {
            self.needProcess = YES;
        }
        
    }
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:cacheStoragePolicy];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
#pragma unused(session)
#pragma unused(dataTask)
    assert(dataTask == self.task);
    assert(data != nil);
    assert([NSThread currentThread] == self.clientThread);
    
    // Just pass the call on to our client.
    if(self.needProcess){
        [self.mutableData appendData:data];
    }else{
        [[self client] URLProtocol:self didLoadData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
// An NSURLSession delegate callback.  We pass this on to the client.
{
#pragma unused(session)
#pragma unused(task)
    assert( (self.task == nil) || (task == self.task) );        // can be nil in the 'cancel from -stopLoading' case
    assert([NSThread currentThread] == self.clientThread);
    
    // Just log and then, in most cases, pass the call on to our client.
    
    if (error == nil) {
        DLogDebug(@"protocol %p success",self);
        if(self.needProcess){
            [self.client URLProtocol:self didLoadData:self.mutableData];
        }
        
        [[self client] URLProtocolDidFinishLoading:self];
    } else if ( [[error domain] isEqual:NSURLErrorDomain] && ([error code] == NSURLErrorCancelled) ) {
        // Do nothing.  This happens in two cases:
        //
        // o during a redirect, in which case the redirect code has already told the client about
        //   the failure
        //
        // o if the request is cancelled by a call to -stopLoading, in which case the client doesn't
        //   want to know about the failure
    } else {
        DLogDebug(@"protocal %p error %@ / %d",self, [error domain], (int) [error code]);
        [[self client] URLProtocol:self didFailWithError:error];
    }
    
    // We don't need to clean up the connection here; the system will call, or has already called, 
    // -stopLoading to do that.
}


+ (NSPredicate *)getWebViewUserAgentTest{
    static dispatch_once_t once;
    static NSPredicate *predicate;
    dispatch_once(&once, ^{
        predicate = [NSComparisonPredicate predicateWithFormat:@"self MATCHES '^Mozilla.*Mac OS X.*AppleWebKit.*'"];
    });
    return predicate;
}

@end
