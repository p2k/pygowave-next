
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

@interface PyGoWaveObject : NSObject
{
}

- (void)addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString *)notificationName;
- (void)removeObserver:(id)notificationObserver name:(NSString *)notificationName;

- (void)postNotificationName:(NSString *)notificationName;
- (void)postNotificationName:(NSString *)notificationName userInfo:(NSDictionary *)userInfo;
- (void)postNotificationName:(NSString *)notificationName userInfo:(NSDictionary *)userInfo coalescing:(BOOL)doCoalescing;

@end
