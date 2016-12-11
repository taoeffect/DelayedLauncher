//
//  Controller.m
//  DelayedLauncher
//
//  Created by Greg Slepak on 12/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Carbon/Carbon.h>

#import "Controller.h"
#import "TEApplication.h"
#import "TEIconFromFilepath.h"
#import "ImageAndProgressCell.h"
#import "CustomTableView.h"
#import "LoginItemsAE.h"
#import "Common.h"

#define MyDragType @"MyDragType"

#define OpenedBeforeKey @"OpenedBeforeKey"
#define LoginItemsCheckKey @"LoginItemsCheckKey"
#define ItemsKey @"ItemsKey"
#define DelayKey @"DelayKey"
#define PreferencesVersionKey @"PreferencesVersionKey"

#define FilePathKey @"FilePathKey"
#define IconKey		@"IconKey"
#define HideKey		@"HideKey"

#define QUIT_TIME 5
#define DEFAULT_DELAY 20.0

// TODO: add reveal in finder contextual menu to each item

OSStatus loginListContainsApp(NSString *appPath, NSMutableArray **copyCats, BOOL *answer)
{
	NSArray *loginItems = nil;
	OSStatus err;
	int i;
	
	FAIL_IF(!copyCats, err = kNSLNullListPtr; log_err("null list given"));
	if ( answer ) *answer = NO;
	if ( *copyCats == nil ) *copyCats = [NSMutableArray array];
	
	DO_FAILABLE(err, LIAECopyLoginItems, (CFArrayRef *)&loginItems);
	
	NSString *appName = [appPath lastPathComponent];
	
	for (i=0; i < [loginItems count]; ++i)
	{
		NSDictionary *item = [loginItems objectAtIndex:i];
		NSURL *itemURL = [item objectForKey:(NSString*)kLIAEURL];
		NSString *itemPath = [itemURL path];
		
		if ( [itemPath rangeOfString:appName].location != NSNotFound )
		{
			if ( [itemPath isEqualToString:appPath] == NO ) {
				log_warn("Login Item %@ found but located in wrong place!", appPath);
				[*copyCats addObject:itemPath];
			}
			else if ( answer ) {
				*answer = YES; // it's in the list as it should be
			}
		}
	}
	
fail_label:
	[loginItems release];
	return err;	
}

OSStatus removeLoginItem(NSString *itemPath)
{
	NSArray *loginItems = nil;
	OSStatus err, i, deleted = nbpNotFound;
	
	DO_FAILABLE(err, LIAECopyLoginItems, (CFArrayRef *)&loginItems);
	
	
	for (i=0; i < [loginItems count]; ++i) {
		if ( [itemPath isEqualToString:[[[loginItems objectAtIndex:i] objectForKey:(NSString*)kLIAEURL] path]] ) {
			LIAERemove(i);
			deleted = 0;
			break;
		}
	}
fail_label:
	[loginItems release];
	return err || deleted;
}

@implementation Controller

- (id)init
{
	if ( (self = [super init]) != nil ) {
		// set user defaults
		NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
		[defaults setObject:[NSNumber numberWithDouble:DEFAULT_DELAY] forKey:DelayKey];
		[defaults setObject:[NSMutableArray array] forKey:ItemsKey];
		NSUserDefaults *stdDefs = [NSUserDefaults standardUserDefaults];
		
		[stdDefs registerDefaults:defaults];
		
		itemList = [[NSMutableArray alloc] initWithArray:[stdDefs objectForKey:ItemsKey]];
		
		if ( [stdDefs integerForKey:PreferencesVersionKey] == 1 )
		{
			log_debug("converting from version 1...");
			//ENUMERATE(NSMutableDictionary *, item, [itemList objectEnumerator])
			for ( unsigned i=0; i < [itemList count]; ++i )
			{
				// we do it this way because 10.4 doesn't allow treating NSDictionaries as NSMutableDictionaries
				NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[itemList objectAtIndex:i]];
				[item removeObjectForKey:IconKey];
				if ( i == 0 )
					[item setObject:[stdDefs objectForKey:DelayKey] forKey:DelayKey];
				else
					[item setObject:[NSNumber numberWithDouble:0] forKey:DelayKey];
				[itemList replaceObjectAtIndex:i withObject:item];
			}
			log_debug("converted to version 2!");
		}
		[[NSUserDefaults standardUserDefaults] setInteger:2 forKey:PreferencesVersionKey];
		
		// these are runtime values but are saved to the preferences... so we need to get rid of them
		// we also need to observe the HideKey
		for ( unsigned i=0; i < [itemList count]; ++i ) {
			NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[itemList objectAtIndex:i]];
			[item removeObjectForKey:@"launched"];
			[item addObserver:self forKeyPath:HideKey options:0 context:NULL];
			[itemList replaceObjectAtIndex:i withObject:item];
		}
		
		[self addObserver:self forKeyPath:@"countingDown" options:NSKeyValueObservingOptionNew context:NULL];
		
		// on 10.4 this seems necessary. For some reason this works fine without it on 10.5 and 10.6.
		[NSValueTransformer setValueTransformer:[[TEIconFromFilepath new] autorelease] forName:@"TEIconFromFilepath"];
	}
	return self;
}

extern char **environ;

- (void)awakeFromNib
{
	[slider setContinuous:YES];
	[delayTextField setHidden:YES];
	[warningField setHidden:YES];
	[playPauseButton setHidden:YES];
	[contextualMenu setAutoenablesItems:NO];
	[self updateDelayTextField];
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, MyDragType, nil]];
	//for (int i=0; environ[i]; ++i ) log_debug("%s", environ[i]);
}

- (void)applicationDidFinishLaunching:(NSNotification *)n
{
	BOOL firstRun = ![[NSUserDefaults standardUserDefaults] boolForKey:OpenedBeforeKey];
	
	if ( firstRun )
	{
		log_debug("first launch detected");
		
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = @"Welcome to DelayedLauncher!";
		alert.informativeText = @"Drag items you want launched onto the table, they will be opened after the specified delays the next time this program runs.\n\nFor best results, add DelayedLauncher to your list of login items.";
		[alert addButtonWithTitle:@"OK"];
		[alert runModal];
		
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:OpenedBeforeKey];
		[window makeKeyAndOrderFront:self];
		return;
	}
	
//	if ( ([TEApplication launchModifiers] & cmdKey) > 0 ) {
//		[warningField setStringValue:@"launch stopped"];
//		[window makeKeyAndOrderFront:self];
//		return;
//	}
	
	if ( [itemList count] > 0 )
	{
		BOOL loginItemsChecked = [[NSUserDefaults standardUserDefaults] boolForKey:LoginItemsCheckKey];
		if ( !loginItemsChecked )
		{
			NSString *ourPath = [[NSBundle mainBundle] bundlePath];
			NSMutableArray *copyCats = nil;
			BOOL inLoginItems;
			OSStatus err = loginListContainsApp(ourPath, &copyCats, &inLoginItems);
			
			if ( err == noErr )
			{
				ENUMERATE(NSString *, copyCat, [copyCats objectEnumerator]) {
					log_info("removing copycat: %@", copyCat);
					removeLoginItem(copyCat);
				}
				
				if ( !inLoginItems )
				{
					NSAlert *alert = [[NSAlert alloc] init];
					alert.messageText = @"Do you want to add DelayedLauncher to Login Items?";
					alert.informativeText = @"For best results, DelayedLauncher can add itself to the list of login items so that it automatically runs whenever you login to your account.\n\nAdd DelayedLauncher to the login items? You can always remove it later.";
					[alert addButtonWithTitle:@"Yes"];
					[alert addButtonWithTitle:@"No"];
					if ( [alert runModal] == NSAlertFirstButtonReturn )
					{
						log_info("added self to login items");
						LIAEAddURLAtEnd((CFURLRef)[NSURL fileURLWithPath:ourPath], NO);
					}
				}
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:LoginItemsCheckKey];
			}
		}
		
		currentTimeLeft = [[self currentDelay] intValue];
		[warningField setStringValue:@""];
		[self setValue:NSYES forKey:@"countingDown"];
		[[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timer:) userInfo:nil repeats:YES] fire];
	}
}

// On Mac OS 10.5 and above, NSTableView and NSOutlineView have better contextual menu support. We now see a highlighted item for what was clicked on, and can access that item to do particular things (such as dynamically change the menu, as we do here!). Each of the contextual menus in the nib file have the delegate set to be the AppController instance. In menuNeedsUpdate, we dynamically update the menus based on the currently clicked upon row/column pair.
// The above comment is from the DragNDropOutlineView developer example
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	clickedRow = [tableView clickedRow];
	// setting things enabled like this requires that setAutoenablesItems is set to NO (see -awakeFromNib)
	if ( clickedRow == -1 )
		[[menu itemAtIndex:0] setEnabled:NO];
	else
		[[menu itemAtIndex:0] setEnabled:YES];
}

- (IBAction)revealInFinder:sender;
{
	if ( clickedRow != -1 ) {
		NSDictionary *item = [itemList objectAtIndex:clickedRow];
		[[NSWorkspace sharedWorkspace] selectFile:[item objectForKey:FilePathKey] inFileViewerRootedAtPath:@""];
	}
}


- (void)timer:(NSTimer *)timer
{
	if ( __likely(countingDown) )
	{
		if ( --currentTimeLeft <= 0 )
		{
			NSMutableDictionary *item;
			if ( launched )
			{
				[NSApp terminate:self];
			}
			else if ( (item = [self currentItem]) != nil )
			{
				[item setObject:NSYES forKey:@"launched"];
				NSString *path = [item objectForKey:FilePathKey];
				BOOL hide = [[item objectForKey:HideKey] boolValue];
				if ( [[NSFileManager defaultManager] fileExistsAtPath:path] )
				{
					NSBundle *bundle = [NSBundle bundleWithPath:path];
					if ( bundle && [bundle bundleIdentifier] )
						[self launchAppBundle:bundle hide:hide];
					else
					{
						log_debug("opening file: %@", path);
						[[NSWorkspace sharedWorkspace] openFile:path];
					}
				}
				[self showProgressForCurrentRow];
				currentTimeLeft = [[self currentDelay] intValue];
			}
			else
			{
				launched = YES;
				currentTimeLeft = QUIT_TIME;
			}
		}
		[warningField setStringValue:NSSTR_FMT("%s in: %d", (launched ? "quitting" : "launching"), currentTimeLeft)];
	}
}

- (int)nextLaunchIndex
{
	int idx = [self currentLaunchIndex];
	return ( idx != -1 && ++idx < [itemList count] ) ? idx : -1;
}

- (int)currentLaunchIndex
{
	int idx = -1;
	unsigned count = [itemList count];
	for (unsigned i=0; i<count; i++) {
		NSDictionary *item = [itemList objectAtIndex:i];
		if ( ![[item objectForKey:@"launched"] boolValue] ) {
			idx = (int)i;
			break;
		}
	}
	return idx;
}

- (void)showProgressForCurrentRow
{
	[tableView setShouldHighlight:countingDown rowAtIndex:[self currentLaunchIndex]];
	[tableView setNeedsDisplay:YES];
}

- (void)launchAppBundle:(NSBundle*)bundle hide:(BOOL)hide
{
	log_debug("opening bundle with path: %@", [bundle bundlePath]);
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSWorkspaceLaunchOptions options = NSWorkspaceLaunchDefault;
	if ( hide ) options |= NSWorkspaceLaunchAndHide;
	BOOL success = [workspace launchAppWithBundleIdentifier:[bundle bundleIdentifier]
													options:options
							 additionalEventParamDescriptor:NULL
										   launchIdentifier:nil];
	if ( !success ) {
		log_warn("couldn't launch app w/workspace, trying alternate for: %@", [bundle bundlePath]);
		if ( [workspace openFile:[bundle bundlePath]] == NO ) {
			log_err("couldn't launch: %@", [bundle bundlePath]);
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
					    change:(NSDictionary *)change
					   context:(void *)context
{
	if ( [keyPath isEqualToString:HideKey] ) {
		[self saveToDisk];
	}
	else if ( [keyPath isEqualToString:@"countingDown"] )
	{
		if ( countingDown )
		{
			[playPauseButton setImage:[NSImage imageNamed:@"Pause"]];
			[warningField setHidden:NO];
			[playPauseButton setHidden:NO];
		}
		else
		{
			[playPauseButton setImage:[NSImage imageNamed:@"Play"]];
		}
		[self showProgressForCurrentRow];
	}
}

- (IBAction)openPreferences:(id)sender
{
	if ( ![window isVisible] ) [window center];
	[window makeKeyAndOrderFront:self];
}
- (IBAction)removeSelectedItems:(id)sender
{
	ENUMERID(obj, [[arrayController selectedObjects] objectEnumerator]) {
		[obj removeObserver:self forKeyPath:HideKey];
	}
	[arrayController remove:sender];
	[self saveToDisk];
}

- (IBAction)fire:(id)sender
{
	[self updateDelayTextField];
	if ( [[NSApp currentEvent] type] == NSEventTypeLeftMouseDown ) {
		[delayTextField setHidden:NO];
		if ( countingDown )
			[self setValue:NSNO forKey:@"countingDown"];
	} else if ( [[NSApp currentEvent] type] == NSEventTypeLeftMouseUp ) {
		[delayTextField setHidden:YES];
		[self saveToDisk];
	}
}

- (IBAction)toggleCountdown:(id)sender
{
	[self setValue:[NSNumber numberWithBool:!countingDown] forKey:@"countingDown"];
}

- (IBAction)launchNow:(id)sender
{
	
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)theItem
{
	SEL action = [theItem action];
	if ( action == @selector(removeSelectedItems:) )
		return [tableView numberOfSelectedRows] > 0;
	return YES;
}

double tenToThe(int power) {
	int x = 10, i;
	if ( power == 0 ) return 1;
	if ( power < 0 ) return pow(10, power);
	for (i=1; i<power; ++i) x *= 10;
	return x;
}

int decimalPlace(double x, int place) {
	double big   = floor(x * tenToThe(place));
	double small = floor(x * tenToThe(place-1)) * 10;
	return big - small;
}

- (void)updateDelayTextField
{
	double delaySec = [slider doubleValue];
	double delayMin = delaySec/60.0;
	
	if ( delaySec < 0.5 )
		[delayTextField setStringValue:@"Immediately"];
	else if ( round(delaySec) == 1.0 )
		[delayTextField setStringValue:@"1 second"];
	else if ( delaySec < 59.5 )
		[delayTextField setStringValue:NSSTR_FMT("%.0f seconds", delaySec)];
	else if ( delaySec >= 59.5 ) {
		int tenths = decimalPlace(delayMin, 1);
		int hundredths = decimalPlace(delayMin, 2);
		
		if ( (tenths == 0 && hundredths < 5) || (tenths == 9 && hundredths >= 5 ) )
			[delayTextField setStringValue:NSSTR_FMT("%.0f minute%s", delayMin, delayMin < 1.05 ? "" : "s")];
		else
			[delayTextField setStringValue:NSSTR_FMT("%.1f minutes", delayMin)];
	}
}

- (NSMutableDictionary*)currentItem
{
	int idx = [self currentLaunchIndex];
	return (idx < [itemList count] && idx != -1) ? [itemList objectAtIndex:idx] : nil;
}
- (NSNumber*)currentDelay
{
	return [[self currentItem] objectForKey:DelayKey];
}

- (void)setItemList:(NSMutableArray*)aList
{
	if ( aList == itemList ) return;
	ASSIGN(itemList, aList);
}
- (NSMutableArray*)itemList
{
	return itemList;
}

- (void)saveToDisk
{
	[[NSUserDefaults standardUserDefaults] setObject:itemList forKey:ItemsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)addItemWithPath:(NSString*)path atIndex:(unsigned)idx
{
	ENUMERATE(NSMutableDictionary *, dict, [itemList objectEnumerator]) {
		if ( [[dict objectForKey:FilePathKey] isEqualToString:path] ) {
			NSAlert *alert = [[NSAlert alloc] init];
			alert.messageText = @"Duplicate";
			alert.informativeText = [NSString stringWithFormat:@"'%@' is already in the list.", [path lastPathComponent]];
			[alert addButtonWithTitle:@"OK"];
			[alert runModal];
			return NO;
		}
	};
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithDouble:(idx == 0 ? DEFAULT_DELAY : 0)] forKey:DelayKey];
	[dict setObject:path forKey:FilePathKey];
	[dict setObject:[NSNumber numberWithBool:NO] forKey:HideKey];
	[arrayController insertObject:dict atArrangedObjectIndex:idx];
	[dict addObserver:self forKeyPath:HideKey options:0 context:NULL];
	return YES;
}

ACC_COMBOP_M(BOOL, countingDown, CountingDown)

#pragma mark -
#pragma mark Table View Shit

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	return !countingDown || ![[[itemList objectAtIndex:rowIndex] objectForKey:@"launched"] boolValue];
}

// begin dragging
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	// Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:MyDragType] owner:self];
    [pboard setData:data forType:MyDragType];
    return YES;
}

// validates it
- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	if ( op != NSTableViewDropAbove ) return NSDragOperationNone;
	NSArray *types = [[info draggingPasteboard] types];
	
	if ( [types containsObject:NSFilenamesPboardType] || [types containsObject:MyDragType] )
		return NSDragOperationEvery;
	
	return NSDragOperationNone;
}

// end dragging
- (BOOL)tableView:(NSTableView *)aTableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pboard = [info draggingPasteboard];
	
	if ( [[pboard types] containsObject:MyDragType] ) {
		// dragging within table
		NSData *rowData = [pboard dataForType:MyDragType];
		NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
		
		if ( ![rowIndexes containsIndex:row] )
		{
			NSArray *objects = [itemList objectsAtIndexes:rowIndexes];
			unsigned dstIdx = [rowIndexes firstIndex] < row ? row - [rowIndexes count] : row;
			[itemList removeObjectsAtIndexes:rowIndexes];
			//log_debug("Dragging ended on row: %d. IndexSet: %@. [itemList count] = %d. dstIdex = %d", row, rowIndexes, [itemList count], dstIdx);
			[itemList insertObjects:objects atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(dstIdx, [rowIndexes count])]];
			[arrayController rearrangeObjects]; // update the controller
		}
	}
	else
	{
		// otherwise we're being dragged onto from another location (probably Finder)
		NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
		ENUMERATE(NSString *, path, [paths reverseObjectEnumerator]) {
			[self addItemWithPath:path atIndex:row];
		}
	}
	[self showProgressForCurrentRow];
	[self saveToDisk];
	return YES;
}

// NOTE: these two methods are required to keep 10.4 from bitching about 
//       NSTableView's datasource not supporting them
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [itemList count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)c row:(int)r
{
	return nil;
}

@end

