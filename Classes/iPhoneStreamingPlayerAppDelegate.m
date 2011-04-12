//
//  iPhoneStreamingPlayerAppDelegate.m
//  iPhoneStreamingPlayer
//
//  Created by Matt Gallagher on 28/10/08.
//  Copyright Matt Gallagher 2008. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

#import "iPhoneStreamingPlayerAppDelegate.h"
#import "iPhoneStreamingPlayerViewController.h"
#import "AudioStreamer.h"

@implementation iPhoneStreamingPlayerAppDelegate

@synthesize window;
@synthesize viewController;

@synthesize uiIsVisible;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
	
	[viewController buttonPressed:nil];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}

- (void)presentAlertWithTitle:(NSNotification *)notification
{
	if (!uiIsVisible)
		return;
	NSString *title = [[notification userInfo] objectForKey:@"title"];
	NSString *message = [[notification userInfo] objectForKey:@"message"];
#ifdef TARGET_OS_IPHONE
	UIAlertView *alert = [
						  [[UIAlertView alloc]
						   initWithTitle:title
						   message:message
						   delegate:self
						   cancelButtonTitle:NSLocalizedString(@"OK", @"")
						   otherButtonTitles: nil]
						  autorelease];
	[alert
	 performSelector:@selector(show)
	 onThread:[NSThread mainThread]
	 withObject:nil
	 waitUntilDone:NO];
#else
	NSAlert *alert =
	[NSAlert
	 alertWithMessageText:title
	 defaultButton:NSLocalizedString(@"OK", @"")
	 alternateButton:nil
	 otherButton:nil
	 informativeTextWithFormat:message];
	[alert
	 performSelector:@selector(runModal)
	 onThread:[NSThread mainThread]
	 withObject:nil
	 waitUntilDone:NO];
#endif
}
- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
	self.uiIsVisible = NO;
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	self.uiIsVisible = NO;
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
	self.uiIsVisible = YES;
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(presentAlertWithTitle:)
	 name:ASPresentAlertWithTitleNotification
	 object:nil];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	self.uiIsVisible = YES;
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	self.uiIsVisible = NO;
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:ASPresentAlertWithTitleNotification
	 object:nil];
}


@end
