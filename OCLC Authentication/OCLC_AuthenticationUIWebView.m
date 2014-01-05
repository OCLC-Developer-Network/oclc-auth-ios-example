/*******************************************************************************
 * Copyright 2014 OCLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

// OCLC_AuthenticationUIWebView.m

#import "OCLC_AuthenticationUIWebView.h"

@implementation OCLC_AuthenticationUIWebView {
    
    NSDictionary *requestParameters;
    NSMutableDictionary *resultParameters;
}

@synthesize authenticationDelegate;

- (id)initWithFrame:(CGRect)frame {
    NSLog(@"OCLC_AuthenticationUIWebView initWithframe");

    self = [super initWithFrame:frame];
    if (self) {
        // Set UIWebViewDelegate to self
        //
        // When https requests are made to this UIWebView, the delegate methods
        // in this class will be called to handle the responses.
        self.delegate = self;
    }
    return self;
}

/**
 * This is the entry method to the class. It builds the URL and executes
 * the token request
 */
- (void)getToken: (NSDictionary *)request {
    NSLog(@"OCLC_AuthenticationUIWebView getToken");
    
    requestParameters = request;
    
    // Build the initial request URL. We store this globally to the class
    // because a failed request may be retried, and no request variables would
    // have changed.
    //
    // Note that parameters with special characters must be URL Encoded. In
    // this case, the redirectUrl contains slashes so it is encoded.
    
    NSURL *myUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@"
                     @"/authorizeCode?client_id=%@"
                     @"&authenticatingInstitutionId=%@"
                     @"&contextInstitutionId=%@"
                     @"&redirect_uri=%@"
                     @"&response_type=%@"
                     @"&scope=%@",
                     requestParameters[@"authenticatingServerBaseUrl"],
                     requestParameters[@"wskey"],
                     requestParameters[@"authenticatingInstitutionId"],
                     requestParameters[@"contextInstitutionId"],
                     [self urlEncode: requestParameters[@"redirectUrl"]],
                     requestParameters[@"responseType"],
                     [self urlEncode:requestParameters[@"scopes"]]]
                    ];
    
    
    NSMutableURLRequest *myRequest = [NSMutableURLRequest
                                      requestWithURL: myUrl
                                      cachePolicy:NSURLCacheStorageAllowed
                                      timeoutInterval:60.0];
    
    [myRequest setHTTPShouldHandleCookies:YES];
    
    [self loadRequest:myRequest];
}


/**
 * After a URL request is created, but before the request is made, this
 * callback method executes. Inspect the URL to see what the request is.
 * During sign in, a series of "redirects" are sent to the UIWebView "browser",
 * and each executes as soon as it is sent. We want to watch for the
 * "Redirect URI" - because it is not meant to be called, but instead contains
 * the token and other information that we requested.
 */
- (BOOL)webView: (UIWebView *)webView
        shouldStartLoadWithRequest: (NSURLRequest *)request
        navigationType: (UIWebViewNavigationType)navigationType {
    
    NSLog(@"Loading:  %@",request.URL.absoluteString);
    
    // Search for the redirect URI in the request URI. It should be at
    // position 0. If not found, return "YES" to allow the request to be made.
    if ([[request.URL.absoluteString lowercaseString]
         rangeOfString:[requestParameters[@"redirectUrl"]
                        lowercaseString]].location != 0) {
             
             return YES;
             
         // If the redirect URI was found, parse the parameters and return
         // "NO" because we do not want to load the redirect URI in the
         // browser.
         } else {
             
             NSArray *urlArray = [request.URL.absoluteString
                                  componentsSeparatedByString:@"#"];
             NSArray *parameterArray = [NSArray new];
             resultParameters = [NSMutableDictionary new];
             
             // Parse the token and other parameters from the URI string
             if ([urlArray count] > 0) {
                parameterArray = [urlArray[1] componentsSeparatedByString:@"&"];
                for (NSString *item in parameterArray) {
                     [resultParameters
                        setObject:[item
                        componentsSeparatedByString:@"="][1]
                        forKey:[item componentsSeparatedByString:@"="][0]];
                }
             }
             return NO;
             
         }
}

/**
 * Fires when loading of data from the http request begins - and turns on the
 * activity indicator.
 */
- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"OCLC_AuthenticationUIWebView  webViewDidStartLoad");
    
    [authenticationDelegate displayActivityIndicator];
}

/**
 * Fires when loading of data from the http request is complete - and turns off
 * the activity indicator. If the internet is disconnected, leave the activity
 * spinner in place and display a message.
 */
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"OCLC_AuthenticationUIWebView  webViewDidFinishLoad");
    
    [authenticationDelegate hideActivityIndicator];
}

/**
 * This UIWebView delegate fires when the load completes with a network error.
 * However, error 102 is actually a success condition - when the URL to be
 * loaded is the redirect URI. Other error conditions display a message.
 */
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"OCLC_AuthenticationUIWebView didFailLoadWithError");
    
    // This error was created by the "shouldStartLoadWithRequest" method above
    // by returning "NO" on purpose. We returned "NO" because we intercepted the
    // redirect URI in the returned URL, which, and it indicates that the token
    // (or an error message) have been received.
    
    [authenticationDelegate hideActivityIndicator];
    
    if (error.code == 102) {
        
        [self loadRequest:[NSURLRequest
                          requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        [self authenticationComplete];
        
        // Sign in failed for an unknown reason. Display an error message. Note
        // that failure to connect to the internet is already handled so this
        // condition should never occur unless a bug in the code messes up the
        // URL request. If it does happen, it displays an error message in an
        // alert box for the developer to see.
    } else {
        NSLog(@"Unexpected error.code = %i",error.code);
    }
    
}

/**
 * We are done. Notify the parent UIViewController that we have token.
 */
- (void)authenticationComplete {
    NSLog(@"OCLC_AuthenticationUIWebView authenticationComplete");
    
    [authenticationDelegate authenticatedSuccess: YES result: resultParameters];
}

/**
 * We don't do anything special with a timeout failure - just pass through to
 * authenticationFailure. However, you could add code to restart the login
 * automatically for a second try.
 */
- (void)requestTimedOut {
    NSLog(@"OCLC_AuthenticationUIWebView requestTimedOut");
    
    [self authenticationFailure];
}

/**
 * We failed to get a token and/or the internet connection was lost during the
 * attempt. If it was the internet connection that was lost, then you have to
 * kill the UIWebView's loading attempt.
 */
- (void)authenticationFailure {
    NSLog(@"OCLC_AuthenticationUIWebView authenticationFailure");
    
    [self stopLoading];
    [authenticationDelegate authenticatedSuccess: NO result: resultParameters];
}

/**
 * Method added to NSString to perform URLEncoding.
 *
 * Apple's built in method, stringByAddingPercentEscapesUsingEncoding, does not
 * encode "/" or "&", which is a known bug. So we roll our own here.
 */
-(NSString*) urlEncode: (NSString *)string
{
    NSString *encodedString = (NSString *)CFBridgingRelease(
      CFURLCreateStringByAddingPercentEscapes(
        NULL,
        (CFStringRef)string,
        NULL,
        (CFStringRef)@"!*'();:@&=+$,/?%#[]",
        kCFStringEncodingUTF8 ));
    return encodedString;
}

@end
