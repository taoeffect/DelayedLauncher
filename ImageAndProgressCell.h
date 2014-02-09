//
//  ImageAndProgressCell.h
//  DelayedLauncher
//
//  Created by Greg Slepak on 3/25/10.
//  Copyright 2010 Tao Effect LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface ImageAndProgressCell : NSImageCell {
	NSProgressIndicator *progress;
	BOOL showProgress;
	BOOL dontShowThisTime;
}

ACC_COMBO_H(BOOL, showProgress, ShowProgress)
ACC_COMBO_H(BOOL, dontShowThisTime, DontShowThisTime)

@end
