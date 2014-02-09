//
//  TEIconFromFilepath.m
//  DelayedLauncher
//
//  Created by Greg Slepak on 3/25/10.
//  Copyright 2010 Tao Effect LLC. All rights reserved.
//

#import "TEIconFromFilepath.h"
#import "Common.h"

@implementation TEIconFromFilepath

+ (Class)transformedValueClass { return [NSImage class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
    return (value == nil) ? nil : [[NSWorkspace sharedWorkspace] iconForFile:value];
}

@end
