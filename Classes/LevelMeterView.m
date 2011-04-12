//
//  LevelMeterView.m
//  iPhoneStreamingPlayer
//
//  Created by Carlos Oliva G. on 07-08-10.
//  Copyright 2010 iDev Software. All rights reserved.
//

#import "LevelMeterView.h"

#define kMeterViewFullWidth 275.0


@implementation LevelMeterView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
#if TARGET_OS_IPHONE
		self.backgroundColor = [UIColor blackColor];
#endif
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
#if TARGET_OS_IPHONE
- (void)drawRect:(CGRect)rect {
    // Drawing code
	[[UIColor whiteColor] set];
	[@"L" drawInRect:CGRectMake(0.0, 10.0, 15.0, 15.0) withFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
	[@"R" drawInRect:CGRectMake(0.0, 35.0, 15.0, 15.0) withFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [UIColor greenColor].CGColor);
	CGContextFillRect(context, CGRectMake(15.0, 10.0, kMeterViewFullWidth * leftValue, 15.0));
	CGContextFillRect(context, CGRectMake(15.0, 35.0, kMeterViewFullWidth * rightValue, 15.0));
	CGContextFlush(context);
}
#else
static CGColorRef CGColorCreateFromNSColor (CGColorSpaceRef colorSpace, NSColor *color)
{
   NSColor *deviceColor = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
   
   CGFloat components[4];
   [deviceColor getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
   
   return CGColorCreate (colorSpace, components);
}

- (void)drawRect:(NSRect)dirtyRect
{
   // Draw the background color.
   [[NSColor blackColor] setFill];
   NSRectFill(dirtyRect);
   
   // Draw the text labels.
   NSDictionary *attribDict = 
   [NSDictionary dictionaryWithObjectsAndKeys: 
    [NSColor whiteColor], NSForegroundColorAttributeName, 
    [NSFont systemFontOfSize:14], NSFontAttributeName, 
    nil];
	
   [@"L" drawInRect:CGRectMake(0.0, 35.0, 15.0, 15.0) withAttributes:attribDict];
   [@"R" drawInRect:CGRectMake(0.0, 10.0, 15.0, 15.0) withAttributes:attribDict];
   
   // Draw the level meter.
   CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
   CGContextSaveGState(context);
   
   NSColor *nsColor = [NSColor greenColor];
   CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB ();
   CGColorRef color = CGColorCreateFromNSColor (colorSpace, nsColor);
   CGColorSpaceRelease (colorSpace);
   
	CGContextSetFillColorWithColor(context, color);
	CGContextFillRect(context, CGRectMake(15.0, 35.0, kMeterViewFullWidth * leftValue, 15.0));
	CGContextFillRect(context, CGRectMake(15.0, 10.0, kMeterViewFullWidth * rightValue, 15.0));
	CGContextFlush(context);
   
   CGColorRelease(color);
   
   CGContextRestoreGState(context);

}
#endif


- (void)updateMeterWithLeftValue:(CGFloat)left rightValue:(CGFloat)right {
	leftValue = left;
	rightValue = right;
#if TARGET_OS_IPHONE
	[self setNeedsDisplay];
#else
	[self setNeedsDisplay:YES];
#endif
}

- (void)dealloc {
    [super dealloc];
}


@end
