//
//  LevelMeterView.h
//  iPhoneStreamingPlayer
//
//  Created by Carlos Oliva G. on 07-08-10.
//  Copyright 2010 iDev Software. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif



#if TARGET_OS_IPHONE
@interface LevelMeterView : UIView 
#else
@interface LevelMeterView : NSView 
#endif
{
	CGFloat leftValue;
	CGFloat rightValue;
}

- (void)updateMeterWithLeftValue:(CGFloat)left rightValue:(CGFloat)right;


@end
