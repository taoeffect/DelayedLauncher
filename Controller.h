//
//  Controller.h
//  DelayedLauncher
//
//  Created by Greg Slepak on 12/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@class CustomTableView;

@interface Controller : NSObject {
	IBOutlet NSWindow *window;
	IBOutlet CustomTableView *tableView;
	IBOutlet NSSlider *slider;
	IBOutlet NSTextField *delayTextField;
	IBOutlet NSArrayController *arrayController;
	IBOutlet NSTextField *warningField;
	IBOutlet NSButton *playPauseButton;
	IBOutlet NSMenu *contextualMenu;
	
	NSMutableArray *itemList;
	int currentTimeLeft;
	int currentItemIndex;
	int clickedRow;
	BOOL launched, countingDown;
}

- (IBAction)fire:(id)sender;
- (IBAction)openPreferences:(id)sender;
- (IBAction)removeSelectedItems:(id)sender;
- (IBAction)toggleCountdown:(id)sender;
- (IBAction)launchNow:(id)sender;
- (IBAction)revealInFinder:sender;

- (void)setItemList:(NSMutableArray*)aList;
- (NSMutableArray*)itemList;

ACC_COMBO_H(BOOL, countingDown, CountingDown)

// ---- private shit

- (void)updateDelayTextField;
- (void)saveToDisk;
- (void)showProgressForCurrentRow;
- (int)nextLaunchIndex;
- (int)currentLaunchIndex;

- (BOOL)addItemWithPath:(NSString*)path atIndex:(unsigned)idx;

- (void)launchAppBundle:(NSBundle*)bundle hide:(BOOL)hide;
- (NSMutableDictionary*)currentItem;
- (NSNumber*)currentDelay;

@end
