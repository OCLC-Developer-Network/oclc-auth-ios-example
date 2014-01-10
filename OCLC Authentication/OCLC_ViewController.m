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

// OCLC_ViewController.m

#import "OCLC_ViewController.h"
#import "OCLC_AuthenticationUIWebView.h"

@interface OCLC_ViewController ()

@end

@implementation OCLC_ViewController {
    
    // The custom UIWebView that will handle the authentication.
    OCLC_AuthenticationUIWebView *authenticationWebView;
    
    // Boolean to keep track of whether the access token is valid or not.
    BOOL isAccessTokenValid;
    
    // Buttons added to the screen
    UIButton *clearCookiesButton;
    UIButton *signInAgainButton;
    
    // The activity indicator (spinner) to inform the user that the
    // authentication process is busy communicating with the server.
    UIActivityIndicatorView *activityIndicator;
    
    // Labels added to the screen
    UILabel *accessTokenTimeRemainingLabel;
    UILabel *resultParametersLabel;
    
    // The access token timer. An access token has a lifespan of around
    // 20 minutes (1200 seconds) typically, before another must be
    // requested.
    NSTimer *accessTokenExpirationTimer;
    double accessTokenTimeRemaining;
}

/**
 * The view loaded. Add the display items to the screen. I do that here so the
 * user can see all the code, rather than in a binary storyboard graphic file.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Add "Clear Cookies" button.
    clearCookiesButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [clearCookiesButton addTarget:self
                           action:@selector(handleClearCookiesButton:)
                 forControlEvents:UIControlEventTouchUpInside];
    
    [clearCookiesButton setTitle:@"Clear Cookies"
                        forState: UIControlStateNormal];
    
    clearCookiesButton.frame =
    CGRectMake(10,self.view.frame.size.height-54,125,44);
    [self.view addSubview:clearCookiesButton];
    
    // Add "Sign In Again" button.
    signInAgainButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [signInAgainButton addTarget:self
                          action:@selector(handleSignInAgainButton:)
                forControlEvents:UIControlEventTouchUpInside];
    
    [signInAgainButton setTitle:@"Sign In Again"
                       forState: UIControlStateNormal];
    
    signInAgainButton.frame =
    CGRectMake(self.view.frame.size.width-135,
               self.view.frame.size.height-54,125,44);
    
    [self.view addSubview:signInAgainButton];
    
    // Add Token Expiration label.
    accessTokenTimeRemainingLabel =
    [[UILabel alloc]
     initWithFrame:CGRectMake(18, self.view.frame.size.height-86, 283, 21)];
    
    [accessTokenTimeRemainingLabel
     setFont:[UIFont fontWithName:@"Courier New" size:13.0f]];
    
    [accessTokenTimeRemainingLabel setTextColor:[UIColor blackColor]];
    
    [accessTokenTimeRemainingLabel
     setText: @"Access Token Time Remaining: expired"];
    
    [self.view addSubview:accessTokenTimeRemainingLabel];
    
    // Add activity spinner.
    activityIndicator =
    [[UIActivityIndicatorView alloc]
     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.frame =CGRectMake(self.view.frame.size.width/2-25,
                                        self.view.frame.size.height/2-50,50,50);
    
    activityIndicator.color = [UIColor grayColor];
    
    [activityIndicator startAnimating];
    
    // Execute the authentication.
    isAccessTokenValid = NO;
    
    [self authenticate];
}

/**
 * Utility function - in this example, we have nothing to delete if memory
 * runs short so we leave it in the default state.
 */
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Creates the authentication UIWebView, loads the authentication parameters
 * from a property list file and and executes the token request.
 */

- (void)authenticate {
    // Get the path to the authentication parameters file
    NSString *plistCatPath = [[NSBundle mainBundle]
                              pathForResource:@"authenticationList" ofType:@"plist"];
    
    // Load the authentication parameters into _requestParameters.
    _requestParameters = [[NSDictionary alloc]
                          initWithContentsOfFile:plistCatPath];
    
    NSLog(@"\n\n**************\n%@\n**************\n\n",_requestParameters);
    
    // If the parameters are null, the user probably forgot to set them
    // in the authenticationList.plist properties file.
    if ([_requestParameters[@"wskey"] isEqualToString:@""] ||
        [_requestParameters[@"authenticatingInstitutionId"] isEqualToString:@""] ||
        [_requestParameters[@"contextInstitutionId"] isEqualToString:@""] ||
        [_requestParameters[@"redirectUrl"] isEqualToString:@""] ||
        [_requestParameters[@"scope"] isEqualToString:@""]) {
        
        [self displayNoAuthenticationParametersMessage];
        
    } else {
        
        // Create our custom UIWebView so that it fills the iPhone screen.
        authenticationWebView = [[OCLC_AuthenticationUIWebView alloc]
                                 initWithFrame:CGRectMake
                                 (0, 20, self.view.frame.size.width,
                                  self.view.frame.size.height-100)];
        
        // Our custom UIWebView has a delegate so that it can tell this class that
        // it is done authenticating.
        authenticationWebView.authenticationDelegate = self;
        
        // Add our custom UIWebView to this view controllers screen.
        [self.view addSubview:authenticationWebView];
        
        // Make the token request.
        [authenticationWebView getToken:_requestParameters];
    }
}

/**
 * This callback is executed when the UIWebView has completed the token request.
 * We dispose of the UIWebView and display the results.
 *
 * @success - A boolean. If false, a timeout or loss of connection may have
 *            occured. In that case, result may be null.
 *
 * @result - NSDictionary object containing the parameters and values that
 *           were returned on the redirect URI.
 */
- (void)authenticatedSuccess:(BOOL)success
                      result:(NSMutableDictionary *)result {
    NSLog(@"\n\n%c\n%@\n\n",success,result);
    
    _resultParameters = result;
    
    // Start the Access Token expiration timer if an "expires_in" parameter was
    // returned.
    if ([result objectForKey:@"expires_in"] != nil) {
        
        accessTokenTimeRemaining =
        [[result objectForKey:@"expires_in"] floatValue];
        
        // Make sure the timer wasn't already defined. If so, null it out.
        if (accessTokenExpirationTimer.isValid) {
            [accessTokenExpirationTimer invalidate];
        }
        
        // Create a new 1 second long, repeating timer so we can count down the
        // remaining seconds in the access token's lifetime.
        // Calls decrementAccessTokenTimer: below every second when active.
        accessTokenExpirationTimer = [NSTimer
                                      scheduledTimerWithTimeInterval:1.0
                                      target:self
                                      selector:@selector(decrementAccessTokenTimer:)
                                      userInfo:nil
                                      repeats:YES];
        
        // If no token time remaining was sent, display a "n/a" message
    } else {
        [accessTokenTimeRemainingLabel
         setText: @"Error in Authentication Process"];
    }
    
    // Dispose of the custom UIWebView.
    // We use the webview once for signing in. To sign in again, we create a
    // new one. They are not meant for re-use!
    [authenticationWebView removeFromSuperview];
    authenticationWebView = nil;
    
    // Create the resultParametersLabel if it does not exist
    if (resultParametersLabel == nil) {
        resultParametersLabel = [[UILabel alloc]
                                 initWithFrame:CGRectMake
                                 (10, 20, self.view.frame.size.width - 20,
                                  self.view.frame.size.height - 100)];
        [resultParametersLabel
         setFont:[UIFont fontWithName:@"Courier New" size:11.0f]];
        [resultParametersLabel setTextColor:[UIColor blackColor]];
        resultParametersLabel.numberOfLines=20;
        [self.view addSubview:resultParametersLabel];
    }
    
    // Display the result parameters on the iPhone screen.
    if (success) {
        resultParametersLabel.text =
        [NSString stringWithFormat:@"SUCCESS\n%@",result];
        isAccessTokenValid = YES;
    } else {
        resultParametersLabel.text =
        [NSString stringWithFormat:@"FAILURE\n%@",result];
        isAccessTokenValid = NO;
    }
    
}

/**
 * Handle the "Sign In Again" button
 *
 * Simply executes the authenticate method. Note - once authentication occurs
 * once, the app retains cookies that will cause future authentications
 * attempts bypass the IDM Sign In Screen.
 *
 * To test signing in from scratch, use the "Clear Cookies" button.
 *
 */
- (IBAction)handleSignInAgainButton:(id)sender {
    NSLog(@"Sign in Again button pressed.");
    [self authenticate];
}

/**
 * Handle the "Clear Cookies" button.
 *
 * Clears the cookies assigned to this app by systematically looping through
 * them and deleting them. Logs them for your edification.
 */
- (IBAction)handleClearCookiesButton:(id)sender {
    NSLog(@"Clear Cookies button pressed.");
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage =[NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies]) {
        NSLog(@"%@",cookie);
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 * Decrement the Access Token timer and display the new value.
 */
- (void)decrementAccessTokenTimer:(id)sender {
    
    accessTokenTimeRemaining--;
    
    if (accessTokenTimeRemaining < 0) {
        [accessTokenTimeRemainingLabel
         setText: @"Access Token Time Remaining: expired"];
        [accessTokenExpirationTimer invalidate];
        isAccessTokenValid = NO;
    } else {
        [accessTokenTimeRemainingLabel setText:
         [NSString stringWithFormat:@"Access Token Time Remaining: %d",
          (int)accessTokenTimeRemaining]];
    }
}


/**
 * Display the Activity Indicator. This is a delagate method from
 * OCLC_AuthenticationUIWebView.
 */
- (void) displayActivityIndicator {
    [self.view addSubview:activityIndicator];
}

/**
 * Hide the Activity Indicator. This is a delagate method from
 * OCLC_AuthenticationUIWebView.
 */
- (void) hideActivityIndicator {
    [activityIndicator removeFromSuperview];
}

/**
 * This authentication demo ships with the authentication parameters nulled
 * out in the authenticationList.plist file. Display a warning message if
 * the user tries to run the demo without configuring the properties.
 */
- (void) displayNoAuthenticationParametersMessage {
    if (resultParametersLabel == nil) {
        resultParametersLabel = [[UILabel alloc]
                                 initWithFrame:CGRectMake
                                 (10, 20, self.view.frame.size.width - 20,
                                  self.view.frame.size.height - 100)];
        [resultParametersLabel
         setFont:[UIFont fontWithName:@"Courier New" size:11.0f]];
        [resultParametersLabel setTextColor:[UIColor blackColor]];
        resultParametersLabel.numberOfLines=20;
        [self.view addSubview:resultParametersLabel];
    }
    
    // Display a warning message
    resultParametersLabel.text = @"Missing authentication parameters in the "
    "properties file \"authenticationList.plist\"\n\nBe sure to configure the\n* "
    "wskey\n* authenticatingInstitutionId\n* contextInstitutionId\n* "
    "redirectURL\n* scope(s)\n";
}

@end