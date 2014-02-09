//
//  TEApplication.m
//  DelayedLauncher
//
//  Created by Greg Slepak on 12/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "TEApplication.h"
#import "Common.h"

static int launchModifiers = 0;

@implementation TEApplication

+ (void)initialize
{
	log_debug("setting modifier keys");
	launchModifiers = GetCurrentKeyModifiers();
	//[super initialize];
}

+ (int)launchModifiers
{
	return launchModifiers;	
}

@end
