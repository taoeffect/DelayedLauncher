//
//  CustomTableView.h
//  DelayedLauncher
//
//  Created by Greg Slepak on 3/25/10.
//  Copyright 2010 Tao Effect LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CustomTableView : NSTableView {
	NSColor *launchedColor;
	BOOL shouldHighlight;
	int rowIdx;
}

- (void)setShouldHighlight:(BOOL)val rowAtIndex:(int)idx;
@end
