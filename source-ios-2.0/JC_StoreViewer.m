/*
 *	Copyright 2013, Jake Chasan, jakechasan.com
 *
 *	All rights reserved.
 *
 *	Redistribution and use in source and binary forms, with or without modification, are 
 *	permitted provided that the following conditions are met:
 *
 *	Redistributions of source code must retain the above copyright notice which includes the
 *	name(s) of the copyright holders. It must also retain this list of conditions and the 
 *	following disclaimer. 
 *
 *	Redistributions in binary form must reproduce the above copyright notice, this list 
 *	of conditions and the following disclaimer in the documentation and/or other materials 
 *	provided with the distribution. 
 *
 *	Neither the name of Jake Chasan, or jakechasan.com nor the names of its contributors
 *	may be used to endorse or promote products derived from this software without specific
 *	prior written permission.
 *
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 *	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 *	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 *	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
 *	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 *	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
 *	OF SUCH DAMAGE. 
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "JSON.h"
#import "BT_application.h"
#import "BT_strings.h"
#import "BT_viewUtilities.h"
#import "BT_appDelegate.h"
#import "BT_item.h"
#import "BT_debugger.h"
#import "BT_viewControllerManager.h"
#import "JC_StoreViewer.h"

@implementation Jc_storeviewer

//viewDidLoad
- (void)viewDidLoad
{
	[BT_debugger showIt:self theMessage:@"viewDidLoad"];
	[super viewDidLoad];
    
    
    //Check if device is running iOS 6
    float currentVersion = 6.0;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= currentVersion)
    {
    [BT_debugger showIt:self theMessage:@"Device is capable of showing the Store"];

        if([self connectedToInternet])
        {
        [BT_debugger showIt:self theMessage:@"Device is connected to the Internet"];
            
        //Remove view from Heirechy
        UIViewController *storeController;
        storeController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
        
        [self showStore:storeController];
        }
        else
        {
            [self alertInternetError];
        }
        
    }
    else
    {
        //Remove view from Heirechy
        UIViewController *alertiOSError;
        alertiOSError = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
        [self showiOSAlert:alertiOSError];
    }
}

//view will appear
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[BT_debugger showIt:self theMessage:@"viewWillAppear"];
	
	//flag this as the current screen
	BT_appDelegate *appDelegate = (BT_appDelegate *)[[UIApplication sharedApplication] delegate];	
	appDelegate.rootApp.currentScreenData = self.screenData;
	
	//setup navigation bar and background
	[BT_viewUtilities configureBackgroundAndNavBar:self theScreenData:[self screenData]];
}

//Showing the iTunes Store/App Store
- (void)showStore:(UIViewController *)storeController
{
    bool transition;
    self.transitonStart =  [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"transitionStart" defaultValue:@"YES"];
    
    if([self.transitonStart isEqualToString:@"YES"])
        transition=TRUE;
    else
        transition=FALSE;
    
    self.iTunesItemID =  [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iTunesItemID" defaultValue:@""];
    
    // Initialize Product View Controller
    SKStoreProductViewController *storeProductViewController = [[SKStoreProductViewController alloc] init];
    
    // Configure View Controller
    [storeProductViewController setDelegate:self];
    [storeProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier : self.iTunesItemID} completionBlock:^(BOOL result, NSError *error) {
        if (error) {
            [BT_debugger showIt:self theMessage:@"Error with the Internet Connection"];
        } else {
            // Present Store Product View Controller
            [self presentViewController:storeProductViewController animated:transition completion:nil];
            [BT_debugger showIt:self theMessage:@"Launched the Store Viewer"];

        }
    }];
}

- (BOOL)connectedToInternet
{
    BOOL checkNetwork = YES;
    BOOL isNetworkActive;
    
    if (checkNetwork) { // Since checking the reachability of a host can be expensive, cache the result and perform the reachability check once.
        checkNetwork = NO;
        
        Boolean success;
        const char *host_name = "google.com"; // your data source host name
        
        SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, host_name);
        SCNetworkReachabilityFlags flags;
        success = SCNetworkReachabilityGetFlags(reachability, &flags);
        isNetworkActive = success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);
        CFRelease(reachability);
    }
    return isNetworkActive;
}

//Dismiss Store
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    bool transition;
    self.transitonEnd =  [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"transitionEnd" defaultValue:@"YES"];
    
    if([self.transitonEnd isEqualToString:@"YES"])
        transition=TRUE;
    else
        transition=FALSE;
    
    [self dismissViewControllerAnimated:transition completion:nil];
    [self viewControllerRemoval:(TRUE)];
    [BT_debugger showIt:self theMessage:@"Dismissed Store Viewer"];
}

//If there is no internet connection
- (void)alertInternetError
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Could not connect to iTunes"
                            
                                                      message:@"Please check your interenet connection, and try again."
                            
                                                     delegate:self
                            
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];
}

//If iOS is not greater than 6.0
- (void)showiOSAlert:(UIViewController *)alertiOSError
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"iOS 6 or Greater Required"
                            
                                                      message:@"Please update your iOS device to the latest operating system."
                            
                                                     delegate:self
                            
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex

//Button Selection
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    //Button 1 Selected
    if([title isEqualToString:@"OK"])
    {
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"Back to Main Screen"]];
        [self viewControllerRemoval:TRUE];
    }
    
}

//Remove the screen below
- (void)viewControllerRemoval:(BOOL)animated
{
    [self.navigationController popViewControllerAnimated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

//dealloc
-(void)dealloc
{
    [super dealloc];
}


@end







