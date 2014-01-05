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

// OCLC_AuthenticationUIWebView
//
// This UIWebView class for iOS handles OCLC authentication using the OAuth2
// pattern to obtain an Access Token.
//
// This class is not intended to be re-used. Create a new instance each time
// you need to authenticate.
//
// Sample usage:
//
// AUTHENTICATION PARAMETERS:
// (Set the authentication parameters in authenticationList.plist)
//
//   <key>authenticatingServerBaseUrl</key>
//   <string>[OCLC Authentication server base url]</string>
//
//   <key>wskey</key>
//   <string>[Your Web Services Key client ID]</string>
//
//   <key>authenticatingInstitutionId</key>
//   <string>[institutionID]</string>
//
//   <key>contextInstitutionId</key>
//   <string>[institutionID]</string>
//
//   <key>redirectUrl</key>
//   <string>[your redirect URL; should NOT begin with "http://"]</string>
//
//    - we watch for the redirectUrl during the OAuth2 flow, and when it
//      is detected, we strip the token from it and do not actually redirect
//      to it. To prevent tokens from being returned to browsers, we do
//      not permit the redirectUrl to be preceeded with "http://". Instead
//      you should use something like "myAppName://mobile_authentication"
//
//   <key>scope</key>
//   <string>[list of service scopes, separated by a space]</string>
//
//   <key>responseType</key>
//   <string>token</string>
//
//
// REQUEST PARAMETERS
//
//   authenticatingServerBaseUrl - base url of the OCLC authentication server
//
//   wskey                       - the clientID portion of the Web Services Key
//
//   authenticatingInstitutionId - the ID of the institution that is
//                                 granting the user authorization
//
//   contextInstitutionId        - the ID of the instution for which the
//                                 token will be valid. Often the same as the
//                                 authenticatingInstitutionId
//
//   redirectUrl                 - the URL that returns the token.
//                                 * for mobile applications, the redirect URL
//                                   must not begin with "http://", but rather
//                                   an identifier unique to your application.
//                                   For example:  myRepairManualApp://redirect
//
//   scope                       - the services the token will be valid for
//
//   response type               - always "token"
//
//
// RESULT PARAMETERS
//
// The delegate method, AuthenticationDelegate, allows this class to inform
// the parent UIViewController of status, and return a result. The result
// method returns a boolean indicating if the attempt succeeded in getting
// a result, and an NSDictionary result. Note that a successful result could
// still have an error parameter in the result list.
//
//   authenticatedSuccess: [YES/NO]
//
//   result: @{
//             @"error",@"",
//             @"error_description",@"",
//             @"access_token",@"",
//             @"principalID",@"",
//             @"principalIDNS",@"",
//             @"context_institution_id",@"",
//             @"token_type",@"bearer",
//             @"expires_in",@"1199",
//             @"expires_at",@"2013-09-30 20:55:04Z",
//             @"",@"",
//           }
//
//   error             - null, or system_error
//   error_description - null, or invalid_request, invalid_token,
//                                token_revoked, token_expired,
//                                access_denied, server_error
//
//   access_token           - token used to make calls against OCLC services
//   principalID            - user identifier code
//   principalIDNS          - user domain identifier code
//   context_institution_id - institution the token is valid for
//   token_type             - bearer
//   expires_in             - seconds until access_token expires
//   expires_at             - ISO 8601 time that the access_token expires
//
//
// Finally, two delegate methods handle the activity indicator that is
// activated while this class is busy communicating with the server:
//
//   displayActivityIndicator - show the spinner
//   hideActivityIndicator    - hide the spinner
//

#import <UIKit/UIKit.h>

@protocol AuthenticationDelegate <NSObject>

- (void)authenticatedSuccess: (BOOL) success result: (NSDictionary *) result;
- (void)displayActivityIndicator;
- (void)hideActivityIndicator;

@end

@interface OCLC_AuthenticationUIWebView : UIWebView <UIWebViewDelegate> {
    id <AuthenticationDelegate> authenticationDelegate;
}

// The delegate for handling the authenticatedSuccess and activity indicator
// callbacks
@property (strong, nonatomic) id <AuthenticationDelegate>authenticationDelegate;

// Entry point to the class. Initiates a token request and returns the result
// using the authenticatedSuccess delegate method.
//
// Request parameters are passed in an NSDictionary object
//
- (void)getToken: (NSDictionary *)request;

@end
