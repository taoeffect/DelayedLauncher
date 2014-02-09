//
//  ImageAndProgressCell.m
//  DelayedLauncher
//
//  Created by Greg Slepak on 3/25/10.
//  Copyright 2010 Tao Effect LLC. All rights reserved.
//

#import "ImageAndProgressCell.h"

@implementation ImageAndProgressCell

- (id)initImageCell:(NSImage *)anImage
{
	if ( (self = [super initImageCell:anImage]) ) {
		NSSize cellSize = [self cellSize];
		progress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, cellSize.width, cellSize.height)];
		[progress setIndeterminate:YES];
		[progress setUsesThreadedAnimation:NO];
		[progress setStyle:NSProgressIndicatorSpinningStyle];
		[progress startAnimation:nil];
	}
	return self;
}

//- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
//{
//	if ( showProgress && !dontShowThisTime )
//	{
//		log_debug("drawing frame: center[%g,%g] size[%g,%g]", NSMinX(cellFrame),NSMinY(cellFrame),NSWidth(cellFrame),NSHeight(cellFrame));
//		[progress setFrame:cellFrame];
//		[controlView lockFocus];
//		[progress drawRect:cellFrame];
//		[controlView unlockFocus];
//	}
//	else [super drawWithFrame:cellFrame inView:controlView];
//	dontShowThisTime = NO;
//}

ACC_COMBOP_M(BOOL, showProgress, ShowProgress)
ACC_COMBOP_M(BOOL, dontShowThisTime, DontShowThisTime)
@end
