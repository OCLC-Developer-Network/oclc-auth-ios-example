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

// OCLC_ViewController
//
// Class for a simple UIViewController which was created when constructing a
// default iPhone single view application using XCode 4.6
//
// Creates and calls the AuthenticationUIWebView class to handle authentication
// and displays the results. Permits the user to sign in again, clear the
// cookies and displays a timer to show how much longer the access_token
// will remain valid. An activity indicator "spinner" is also displayed to
// inform the user when the AuthenticationUIWebView class is waiting for
// a result from the authentication server
//
// Sample usage:
//
// * This class is created automatically by XCode when generating a single
//   view application.
// * See the comments in AuthenticationUIWebView.h for details on how to
//   an authentication UIWebView controller was added to this class.
//

#import <UIKit/UIKit.h>
#import "OCLC_AuthenticationUIWebView.h"

// The delegate object use to intercept method calls from
// OCLC_AuthenticationUIWebView
@interface OCLC_ViewController : UIViewController <AuthenticationDelegate>

@property (retain, nonatomic) NSDictionary *requestParameters;
@property (retain, nonatomic) NSDictionary *resultParameters;

@end
