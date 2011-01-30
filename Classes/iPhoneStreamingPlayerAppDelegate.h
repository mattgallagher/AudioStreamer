//
//  iPhoneStreamingPlayerAppDelegate.h
//  iPhoneStreamingPlayer
//
//  Created by Matt Gallagher on 28/10/08.
//  Copyright Matt Gallagher 2008. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <UIKit/UIKit.h>

@class iPhoneStreamingPlayerViewController;

@interface iPhoneStreamingPlayerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    iPhoneStreamingPlayerViewController *viewController;
	BOOL uiIsVisible;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet iPhoneStreamingPlayerViewController *viewController;
@property (nonatomic) BOOL uiIsVisible;
@end

