
/*
 * This file is part of the PyGoWave NeXT/ObjC Client API
 *
 * Copyright (C) 2010 Patrick Schneider <patrick.p2k.schneider@googlemail.com>
 *
 * This library is free software: you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; see the file
 * COPYING.LESSER.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "PyGoWaveBase.h"

@implementation PyGoWaveObject

- (void)addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString *)notificationName
{
	[[NSNotificationCenter defaultCenter] addObserver:notificationObserver selector:notificationSelector name:notificationName object:self];
}

- (void)removeObserver:(id)notificationObserver name:(NSString *)notificationName
{
	[[NSNotificationCenter defaultCenter] removeObserver:notificationObserver name:notificationName object:self];
}

- (void)postNotificationName:(NSString *)notificationName
{
	[self postNotificationName:notificationName userInfo:nil coalescing:YES];
}

- (void)postNotificationName:(NSString *)notificationName userInfo:(NSDictionary *)userInfo
{
	[self postNotificationName:notificationName userInfo:userInfo coalescing:YES];
}

- (void)postNotificationName:(NSString *)notificationName userInfo:(NSDictionary *)userInfo coalescing:(BOOL)coalescing
{
	[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:notificationName object:self userInfo:userInfo]
											   postingStyle:NSPostASAP
											   coalesceMask:(coalescing ? NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender : NSNotificationNoCoalescing)
												   forModes:nil];
}

@end
