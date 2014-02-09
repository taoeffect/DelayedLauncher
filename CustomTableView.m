//
//  CustomTableView.m
//  DelayedLauncher
//
//  Created by Greg Slepak on 3/25/10.
//  Copyright 2010 Tao Effect LLC. All rights reserved.
//

#import "CustomTableView.h"
#import "Controller.h"
#import "Common.h"

@implementation CustomTableView

- (void)awakeFromNib
{
	log_debug("%s", __func__);
	launchedColor = [[NSColor colorWithCalibratedWhite:0 alpha:0.3] retain];
}

- (void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect
{
	NSRect rowRect = [self rectOfRow:rowIdx];
	[super drawRow:rowIndex clipRect:clipRect];
	if ( rowIndex == rowIdx && shouldHighlight ) {
//		log_debug("drawing row: center[%g,%g] size[%g,%g]", NSMinX(rowRect),NSMinY(rowRect),NSWidth(rowRect),NSHeight(rowRect));
		rowRect.size.height -= 1;
		rowRect.origin.y += 1;
		rowRect.size.width -= 1;
		rowRect.origin.x += 1;
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:rowRect];
		//[[NSColor alternateSelectedControlColor] set];
		[[NSColor redColor] set];
		[path setLineWidth:2];//[[self window] userSpaceScaleFactor]];
		[path stroke];
	}
	else
	{
		Controller *controller = (Controller*)[NSApp delegate];
		NSMutableDictionary *item = [[controller itemList] objectAtIndex:rowIndex];
		if ( [controller countingDown] && [[item objectForKey:@"launched"] boolValue] )
		{
			//log_debug("highlighting launched row: %d", rowIndex);
			rowRect = [self rectOfRow:rowIndex];
			[launchedColor set];
			[NSBezierPath fillRect:rowRect];
		}
	}
}
- (void)setShouldHighlight:(BOOL)val rowAtIndex:(int)idx
{
	shouldHighlight = val;
	rowIdx = idx;
}
@end
