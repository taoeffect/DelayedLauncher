//
//  GradientBGView.m
//  DelayedLauncher
//
//  Created by Greg Slepak on 3/23/10.
//  Copyright 2010 Tao Effect LLC. All rights reserved.
//

#import "GradientBGView.h"
#import "CTGradient.h"

@implementation GradientBGView

- (id)initWithFrame:(NSRect)frame
{
    if ( (self = [super initWithFrame:frame]) )
	{
        [self setFocusRingType:NSFocusRingTypeNone];
		
		NSColor *colors[4];
		colors[0] = [NSColor colorWithCalibratedRed:0.05 green:0.09 blue:0.1 alpha:1];
		colors[1] = [NSColor colorWithCalibratedRed:0.25 green:0.27 blue:0.31 alpha:1];
		colors[2] = [NSColor colorWithCalibratedRed:0.36 green:0.4 blue:0.47 alpha:1];
		
		gradient = [CTGradient gradientWithBeginningColor:colors[0] endingColor:colors[2]];
		gradient = [gradient addColorStop:colors[1] atPosition:0.1];
		[gradient retain];
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
	[gradient fillRect:[self bounds] angle:270];
}

@end