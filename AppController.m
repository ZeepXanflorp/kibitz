/*
	$Id$

	Copyright 2006 Klaus Thul (klaus.thul@mac.com)
	This file is part of kibitz.

	kibitz is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by 
	the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

	kibitz is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along with kibitz; if not, write to the 
	Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import "AppController.h"
#import "SeekControl.h"

@implementation AppController

+ (void) initialize
{ 
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	ChessServerList *defaultServers = [[[ChessServerList alloc] init] autorelease];
	NSData *data;
	[defaultServers addNewServerName: @"Free Internet Chess Server (FICS)" Address: @"69.36.243.188" port: 5000 userName: nil userPassword: nil 
	 initCommands: @"iset seekremove 1\niset seekinfo 1\niset gameinfo 1\nset height 200\n"];
	data = [NSKeyedArchiver archivedDataWithRootObject:defaultServers];
	[defaultValues setObject:data forKey:@"ICSChessServers"];
	NSArray *defaultSeeks = [NSArray arrayWithObjects: [[[Seek alloc] init] autorelease], nil];
	data = [NSKeyedArchiver archivedDataWithRootObject: defaultSeeks];
	[defaultValues setObject: data forKey:@"Seeks"];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	gSounds = [[Sound alloc] init];
}

- (AppController *) init
{
	if ((self = [super init]) != nil) {
		serverConnections = [[NSMutableArray arrayWithCapacity: 20] retain];
	}
	return self;
}

- (void) awakeFromNib
{
	[self showChessServerSelectorWindow];
}

- (void) dealloc
{
	[chessServerListControl release];
	[serverConnections release];
	[super dealloc];
}

- (void) showChessServerSelectorWindow
{
	if (chessServerListControl == nil)
		chessServerListControl = [[ChessServerListControl alloc] initWithAppController: self];
	[chessServerListControl show: self];
}

- (IBAction) selectServer: (id) sender
{
	[self showChessServerSelectorWindow];
}

- (IBAction) newSeek: (id) sender
{
	if (seekControl == nil)
		seekControl = [(SeekControl *) [SeekControl alloc] initWithAppController: self];
	[seekControl show: sender];
}

- (void) connectChessServer: (ChessServer *) cs
{	
	ChessServerConnection *csc = [[[ChessServerConnection alloc] initWithChessServer: cs appController: self] autorelease]; 
	if (csc != nil) {
		[chessServerListControl close];
		[self willChangeValueForKey: @"serverConnections"];
		[serverConnections addObject: csc];
		[self didChangeValueForKey: @"serverConnections"];
		[seekControl setValue: csc forKey: @"selectedConnection"];
	}
}

- (void) closeServerConnection: (ChessServerConnection *) csc
{	
	NSLog(@"Close Server Connection");
	if (csc != nil) {
		[self willChangeValueForKey: @"serverConnections"];
		[serverConnections removeObject: csc];
		[self didChangeValueForKey: @"serverConnections"];
		if ([serverConnections count] == 0)
			[self showChessServerSelectorWindow]; 
	}
}

- (NSArray *) serverConnections
{
	return serverConnections;
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) sender
{
	if (([serverConnections count] == 0)
	 || (NSRunAlertPanel(@"Confirm quit", @"You are currently connected to a chess server. Quit anyway?", @"Yes", @"No", nil)
	     == NSAlertDefaultReturn))
		return NSTerminateNow;
	else
		return NSTerminateCancel;
}

@end
