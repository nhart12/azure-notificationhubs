//----------------------------------------------------------------
//  Copyright (c) Microsoft Corporation. All rights reserved.
//----------------------------------------------------------------

#import "SBURLConnection.h"
#import "SBNotificationHubHelper.h"

@implementation SBURLConnection

StaticHandleBlock _staticHandler;

+ (void) setStaticHandler:(StaticHandleBlock)staticHandler
{
    _staticHandler = staticHandler;
}

- (void) sendRequest: (NSURLRequest*) request completion:(void (^)(NSHTTPURLResponse*,NSData*,NSError*))completion;
{
    if( _staticHandler != nil)
    {
        SBStaticHandlerResponse* mockResponse = _staticHandler(request);
        if( mockResponse != nil)
        {
            if(completion)
            {
                NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:[request URL] statusCode:200 HTTPVersion:nil headerFields:mockResponse.Headers];
                completion(response,mockResponse.Data,nil);
            }
            return;
        }
    }

    NSURLSession* session = [NSURLSession sharedSession];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable c_data, NSURLResponse * _Nullable c_response, NSError * _Nullable c_error) {
        completion((NSHTTPURLResponse*)c_response, c_data, c_error);
    }];

    if (task)
        [task resume];
    else
    {
        NSString* msg = [NSString stringWithFormat:@"Initiate request failed for %@",[request description]];
        completion(nil,nil,[SBNotificationHubHelper errorWithMsg:msg code:-1]);
    }
}

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    if( _staticHandler != nil)
    {
        SBStaticHandlerResponse* mockResponse  = _staticHandler(request);
        if( mockResponse != nil)
        {
            (*response) = [[NSHTTPURLResponse alloc] initWithURL:[request URL] statusCode:200 HTTPVersion:nil headerFields:mockResponse.Headers];
            
            return mockResponse.Data;
        }
    }

    __block NSData* b_data = nil;
    
    dispatch_semaphore_t wait = dispatch_semaphore_create(0);

    [self sendRequest:request completion:^(NSHTTPURLResponse* c_response, NSData* c_data, NSError* c_error) {
        
        b_data = c_data;
        
        if (response)
            *response = c_response;
        
        if (error)
            *error = c_error;
        
        dispatch_semaphore_signal(wait);
    }];
    
    dispatch_semaphore_wait(wait, DISPATCH_TIME_FOREVER);
    
    return b_data;
}

@end
