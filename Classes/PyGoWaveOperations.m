
/*
 * This file is part of the PyGoWave ObjC/NeXT Client API
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

#import "PyGoWaveOperations.h"


@implementation PyGoWaveOperation

@synthesize type = m_type, waveId = m_waveId, waveletId = m_waveletId, blipId = m_blipId, index = m_index, property = m_property;

#pragma mark Initialization and Deallocation

- (id)initWithType:(PyGoWaveOperationType)aType
			waveId:(NSString*)aWaveId
		 waveletId:(NSString*)aWaveletId
{
	return [self initWithType:aType waveId:aWaveId waveletId:aWaveletId blipId:@"" index:-1 property:nil];
}
- (id)initWithType:(PyGoWaveOperationType)aType
			waveId:(NSString*)aWaveId
		 waveletId:(NSString*)aWaveletId
			blipId:(NSString*)aBlipId
			 index:(NSInteger)aIndex
		  property:(id)aProperty
{
	if (self = [super init]) {
		m_type = aType;
		m_waveId = [aWaveId copy];
		m_waveletId = [aWaveletId copy];
		m_blipId = [aBlipId copy];
		m_index = aIndex;
		m_property = [aProperty copy];
	}
	return self;
}

- (void)dealloc
{
	[m_waveId release];
	[m_waveletId release];
	[m_blipId release];
	[m_property release];
	[super dealloc];
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	return [[PyGoWaveOperation allocWithZone:zone]
			initWithType:m_type
			waveId:m_waveId
			waveletId:m_waveletId
			blipId:m_blipId
			index:m_index
			property:m_property];
}

#pragma mark Public methods

- (BOOL)isNull
{
	if (m_type == PyGoWaveOperation_DOCUMENT_INSERT)
		return self.length == 0;
	else if (m_type == PyGoWaveOperation_DOCUMENT_DELETE)
		return [m_property intValue] == 0;
	return NO;
}

- (BOOL)isCompatibleToOperation:(PyGoWaveOperation*)aOperation
{
	if (![m_waveId isEqual:aOperation.waveId] || ![m_waveletId isEqual:aOperation.waveletId] || ![m_blipId isEqual:aOperation.blipId])
		return NO;
	return YES;
}

- (BOOL)isInsert
{
	return m_type == PyGoWaveOperation_DOCUMENT_INSERT || m_type == PyGoWaveOperation_DOCUMENT_ELEMENT_INSERT;
}
- (BOOL)isDelete
{
	return m_type == PyGoWaveOperation_DOCUMENT_DELETE || m_type == PyGoWaveOperation_DOCUMENT_ELEMENT_DELETE;
}
- (BOOL)isChange
{
	return m_type == PyGoWaveOperation_DOCUMENT_ELEMENT_DELTA || m_type == PyGoWaveOperation_DOCUMENT_ELEMENT_SETPREF;
}

- (NSInteger)length
{
	if (m_type == PyGoWaveOperation_DOCUMENT_INSERT)
		return [m_property length];
	else if (m_type == PyGoWaveOperation_DOCUMENT_DELETE)
		return [m_property intValue];
	else if (m_type == PyGoWaveOperation_DOCUMENT_ELEMENT_INSERT || m_type == PyGoWaveOperation_DOCUMENT_ELEMENT_DELETE)
		return 1;
	return 0;
}
- (void)resizeToLength:(NSInteger)aLength
{
	if (m_type == PyGoWaveOperation_DOCUMENT_DELETE) {
		[m_property release];
		m_property = [[NSNumber numberWithInt:aLength] retain];
	}
}

- (void)insertString:(NSString*)aString atIndex:(NSInteger)aIndex
{
	if (m_type == PyGoWaveOperation_DOCUMENT_INSERT) {
		NSString * newString = [m_property stringByReplacingCharactersInRange:NSMakeRange(aIndex, 0) withString:aString];
		[m_property release];
		m_property = [newString retain];
	}
}
- (void)deleteStringAtIndex:(NSInteger)aIndex withLength:(NSInteger)aLength
{
	if (m_type == PyGoWaveOperation_DOCUMENT_INSERT) {
		NSString * newString = [m_property stringByReplacingCharactersInRange:NSMakeRange(aIndex, aLength) withString:@""];
		[m_property release];
		m_property = [newString retain];
	}
}

- (NSDictionary*)serialize
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[PyGoWaveOperation stringFromType:m_type], @"type",
		m_waveId, @"waveId",
		m_waveletId, @"waveletId",
		m_blipId, @"blipId",
		[NSNumber numberWithInt:m_index], @"index",
		m_property == nil ? [NSNumber numberWithInt:0] : m_property, @"property",
		nil
	];
}

+ (id)operationWithSerialized:(NSDictionary*)aSerialized
{
	PyGoWaveOperation * op = [[self alloc]
		initWithType:[self typeFromString:[aSerialized valueForKey:@"type"]]
			  waveId:[aSerialized valueForKey:@"waveId"]
		   waveletId:[aSerialized valueForKey:@"waveletId"]
			  blipId:[aSerialized valueForKey:@"blipId"]
			   index:[[aSerialized valueForKey:@"index"] intValue]
			property:[aSerialized valueForKey:@"property"]
	];
	return [op autorelease];
}

+ (NSString*)stringFromType:(PyGoWaveOperationType)aType
{
	switch (aType) {
		case PyGoWaveOperation_DOCUMENT_NOOP:
			return @"DOCUMENT_NOOP";
		case PyGoWaveOperation_DOCUMENT_INSERT:
			return @"DOCUMENT_INSERT";
		case PyGoWaveOperation_DOCUMENT_DELETE:
			return @"DOCUMENT_DELETE";
		case PyGoWaveOperation_DOCUMENT_ELEMENT_INSERT:
			return @"DOCUMENT_ELEMENT_INSERT";
		case PyGoWaveOperation_DOCUMENT_ELEMENT_DELETE:
			return @"DOCUMENT_ELEMENT_DELETE";
		case PyGoWaveOperation_DOCUMENT_ELEMENT_DELTA:
			return @"DOCUMENT_ELEMENT_DELTA";
		case PyGoWaveOperation_DOCUMENT_ELEMENT_SETPREF:
			return @"DOCUMENT_ELEMENT_SETPREF";
		case PyGoWaveOperation_WAVELET_ADD_PARTICIPANT:
			return @"WAVELET_ADD_PARTICIPANT";
		case PyGoWaveOperation_WAVELET_REMOVE_PARTICIPANT:
			return @"WAVELET_REMOVE_PARTICIPANT";
		case PyGoWaveOperation_WAVELET_APPEND_BLIP:
			return @"WAVELET_APPEND_BLIP";
		case PyGoWaveOperation_BLIP_CREATE_CHILD:
			return @"BLIP_CREATE_CHILD";
		case PyGoWaveOperation_BLIP_DELETE:
			return @"BLIP_DELETE";
	}
	return @"DOCUMENT_NOOP";
}

+ (PyGoWaveOperationType)typeFromString:(NSString*)aType
{
	if ([aType isEqual:@"DOCUMENT_INSERT"])
		return PyGoWaveOperation_DOCUMENT_INSERT;
	else if ([aType isEqual:@"DOCUMENT_DELETE"])
		return PyGoWaveOperation_DOCUMENT_DELETE;
	else if ([aType isEqual:@"DOCUMENT_ELEMENT_INSERT"])
		return PyGoWaveOperation_DOCUMENT_ELEMENT_INSERT;
	else if ([aType isEqual:@"DOCUMENT_ELEMENT_DELETE"])
		return PyGoWaveOperation_DOCUMENT_ELEMENT_DELETE;
	else if ([aType isEqual:@"DOCUMENT_ELEMENT_DELTA"])
		return PyGoWaveOperation_DOCUMENT_ELEMENT_DELTA;
	else if ([aType isEqual:@"DOCUMENT_ELEMENT_SETPREF"])
		return PyGoWaveOperation_DOCUMENT_ELEMENT_SETPREF;
	else if ([aType isEqual:@"WAVELET_ADD_PARTICIPANT"])
		return PyGoWaveOperation_WAVELET_ADD_PARTICIPANT;
	else if ([aType isEqual:@"WAVELET_REMOVE_PARTICIPANT"])
		return PyGoWaveOperation_WAVELET_REMOVE_PARTICIPANT;
	else if ([aType isEqual:@"WAVELET_APPEND_BLIP"])
		return PyGoWaveOperation_WAVELET_APPEND_BLIP;
	else if ([aType isEqual:@"BLIP_CREATE_CHILD"])
		return PyGoWaveOperation_BLIP_CREATE_CHILD;
	else if ([aType isEqual:@"BLIP_DELETE"])
		return PyGoWaveOperation_BLIP_DELETE;
	return PyGoWaveOperation_DOCUMENT_NOOP;
}

@end

#pragma mark -

@implementation PyGoWaveOpManager

@synthesize waveId = m_waveId, waveletId = m_waveletId, contributorId = m_contributorId;

#pragma mark Initialization and Deallocation

- (id)initWithWaveId:(NSString*)aWaveId waveletId:(NSString*)aWaveletId contributorId:(NSString*)aContributorId
{
	if (self = [super init]) {
		m_waveId = [aWaveId copy];
		m_waveletId = [aWaveletId copy];
		m_contributorId = [aContributorId copy];
		m_operations = [NSMutableArray new];
		m_lockedBlips = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[m_waveId release];
	[m_waveletId release];
	[m_contributorId release];
	[m_operations release];
	[m_lockedBlips release];
	[super dealloc];
}

#pragma mark Public methods

- (BOOL)isEmpty
{
	return [m_operations count] == 0;
}

- (BOOL)canFetch
{
	for (PyGoWaveOperation * op in m_operations) {
		if (![m_lockedBlips containsObject:op.blipId])
			return YES;
	}
	return NO;
}

// Internal
- (void)postOperationChangedWithIndex:(NSInteger)aIndex
{
	[self postNotificationName:@"operationChanged" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:aIndex], @"index", nil]];
}

- (NSArray*)transformInputOperation:(PyGoWaveOperation*)aInputOperation
{
	PyGoWaveOperation * new_op = nil;
	NSMutableArray * op_lst = [NSMutableArray new];
	[op_lst addObject:[[aInputOperation copy] autorelease]];
	int i = 0;
	while (i < [m_operations count]) {
		PyGoWaveOperation * myop = [m_operations objectAtIndex:i];
		int j = 0;
		while (j < [op_lst count]) {
			PyGoWaveOperation * op = [op_lst objectAtIndex:j];
			if (![op isCompatibleToOperation:myop])
				continue;
			int end = 0;
			if (op.isDelete && myop.isDelete) {
				if (op.index < myop.index) {
					end = op.index + op.length;
					if (end <= myop.index) {
						myop.index -= op.length;
						[self postOperationChangedWithIndex:i];
					}
					else if (end < (myop.index + myop.length)) {
						[op resizeToLength:myop.index - op.index];
						[myop resizeToLength:myop.length - (end - myop.index)];
						myop.index = op.index;
						[self postOperationChangedWithIndex:i];
					}
					else {
						[op resizeToLength:op.length - myop.length];
						myop = nil;
						[self removeOperationAtIndex:i];
						i--;
						break;
					}
				}
				else {
					end = myop.index + myop.length;
					if (op.index >= end)
						op.index -= myop.length;
					else if (op.index + op.length <= end) {
						[myop resizeToLength:myop.length - op.length];
						[op_lst removeObjectAtIndex:j];
						op = nil;
						j--;
						if (myop.isNull) {
							myop = nil;
							[self removeOperationAtIndex:i];
							i--;
							break;
						}
						else
							[self postOperationChangedWithIndex:i];
					}
					else {
						[myop resizeToLength:myop.length - (end - op.index)];
						[self postOperationChangedWithIndex:i];
						[op resizeToLength:op.length - (end - op.index)];
						op.index = myop.index;
					}
				}
			}
			else if (op.isDelete && myop.isInsert) {
				if (op.index < myop.index) {
					if (op.index + op.length <= myop.index) {
						myop.index -= op.length;
						[self postOperationChangedWithIndex:i];
					}
					else {
						new_op = [op copy];
						[op resizeToLength:myop.index - op.index];
						[new_op resizeToLength:new_op.length - op.length];
						[op_lst insertObject:new_op atIndex:j + 1];
						[new_op release];
						myop.index -= op.length;
						[self postOperationChangedWithIndex:i];
					}
				}
				else
					op.index += myop.length;
			}
			else if (op.isInsert && myop.isDelete) {
				if (op.index <= myop.index) {
					myop.index += op.length;
					[self postOperationChangedWithIndex:i];
				}
				else if (op.index >= (myop.index + myop.length))
					op.index -= myop.length;
				else {
					new_op = [myop copy];
					[myop resizeToLength:op.index - myop.index];
					[self postOperationChangedWithIndex:i];
					[new_op resizeToLength:new_op.length - myop.length];
					[self insertOperation:new_op atIndex:i + 1];
					[new_op release];
					op.index = myop.index;
				}
			}
			else if (op.isInsert && myop.isInsert) {
				if (op.index <= myop.index) {
					myop.index += op.length;
					[self postOperationChangedWithIndex:i];
				}
				else
					op.index += myop.length;
			}
			else if (op.isChange && myop.isDelete) {
				if (op.index > myop.index) {
					if (op.index <= (myop.index + myop.length))
						op.index = myop.index;
					else
						op.index -= myop.length;
				}
			}
			else if (op.isChange && myop.isInsert) {
				if (op.index >= myop.index)
					op.index += myop.length;
			}
			else if (op.isDelete && myop.isChange) {
				if (op.index < myop.index) {
					if (myop.index <= (op.index + op.length)) {
						myop.index = op.index;
						[self postOperationChangedWithIndex:i];
					}
					else {
						myop.index -= op.length;
						[self postOperationChangedWithIndex:i];
					}
				}
			}
			else if (op.isInsert && myop.isChange) {
				if (op.index <= myop.index) {
					myop.index += op.length;
					[self postOperationChangedWithIndex:i];
				}
			}
			else if ((op.type == PyGoWaveOperation_WAVELET_ADD_PARTICIPANT && myop.type == PyGoWaveOperation_WAVELET_ADD_PARTICIPANT)
					|| (op.type == PyGoWaveOperation_WAVELET_REMOVE_PARTICIPANT && myop.type == PyGoWaveOperation_WAVELET_REMOVE_PARTICIPANT)) {
				if ([op.property isEqual:myop.property]) {
					myop = nil;
					[self removeOperationAtIndex:i];
					i--;
					break;
				}
			}
			else if (op.type == PyGoWaveOperation_BLIP_DELETE && [op.blipId length] != 0 && [myop.blipId length] != 0) {
				myop = nil;
				[self removeOperationAtIndex:i];
				i--;
				break;
			}
			j++;
		}
		i++;
	}
	return [op_lst autorelease];
}

- (NSArray*)fetchOperations
{
	NSMutableArray * ops = [NSMutableArray new];
	int i = 0, s = 0;
	while (i < [m_operations count]) {
		PyGoWaveOperation * op = [m_operations objectAtIndex:i];
		if ([m_lockedBlips containsObject:op.blipId]) {
			if (i - s > 0) {
				[self removeOperationsFromStart:s toEnd:i-1];
				i -= s+1;
			}
			s = i+1;
		}
		else
			[ops addObject:op];
		i++;
	}
	if (i - s > 0)
		[self removeOperationsFromStart:s toEnd:i-1];
	
	NSArray * ret = [NSArray arrayWithArray:ops];
	[ops release];
	return ret;
}

- (void)putOperations:(NSArray*)sOperations
{
	if ([sOperations count] == 0)
		return;
	int start = [m_operations count];
	int end = start + [sOperations count] - 1;
	NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:start], @"start", [NSNumber numberWithInt:end], @"end", nil];
	[self postNotificationName:@"beforeOperationsInserted"
					  userInfo:info
					coalescing:NO];
	[m_operations addObjectsFromArray:sOperations];
	[self postNotificationName:@"afterOperationsInserted"
					  userInfo:info
					coalescing:NO];
}

- (NSArray*)serializeOperations
{
	return [self serializeAndFetchOperations:NO];
}

- (NSArray*)serializeAndFetchOperations:(BOOL)bFetch
{
	NSArray * ops;
	if (bFetch)
		ops = [self fetchOperations];
	else
		ops = m_operations;
	
	NSMutableArray * sOps = [NSMutableArray new];
	for (PyGoWaveOperation * op in ops)
		[sOps addObject:[op serialize]];
	
	NSArray * ret = [NSArray arrayWithArray:sOps];
	[sOps release];
	return ret;
}

- (void)addSerializedOperations:(NSArray*)sSerializedOperations
{
	NSMutableArray * ops = [NSMutableArray new];
	for (NSDictionary * op in sSerializedOperations)
		[ops addObject:[PyGoWaveOperation operationWithSerialized:op]];
	[self putOperations:ops];
	[ops release];
}

- (void)mergeInsertOperation:(PyGoWaveOperation*)newop
{
	PyGoWaveOperation * op = nil;
	int i = 0;
	if (newop.type == PyGoWaveOperation_DOCUMENT_ELEMENT_DELTA) {
		for (i = 0; i < [m_operations count]; i++) {
			op = [m_operations objectAtIndex:i];
			NSDictionary * ndmap = newop.property;
			if (op.type == PyGoWaveOperation_DOCUMENT_ELEMENT_DELTA && [[ndmap valueForKey:@"id"] isEqual:[op.property valueForKey:@"id"]]) {
				NSMutableDictionary * dmap = [op.property mutableCopy];
				NSMutableDictionary * delta = [[dmap valueForKey:@"delta"] mutableCopy];
				NSDictionary * newdelta = [ndmap valueForKey:@"delta"];
				for (NSString * key in newdelta)
					[delta setValue:[newdelta valueForKey:key] forKey:key];
				[dmap setValue:[NSDictionary dictionaryWithDictionary:delta] forKey:@"delta"];
				op.property = [NSDictionary dictionaryWithDictionary:dmap];
				[self postOperationChangedWithIndex:i];
				[delta release];
				[dmap release];
				return;
			}
		}
	}
	i = [m_operations count] - 1;
	if (i >= 0) {
		op = [m_operations objectAtIndex:i];
		if (newop.type == PyGoWaveOperation_DOCUMENT_INSERT && op.type == PyGoWaveOperation_DOCUMENT_INSERT) {
			if (newop.index >= op.index && newop.index <= op.index+op.length) {
				[op insertString:newop.property atIndex:newop.index - op.index];
				[self postOperationChangedWithIndex:i];
				return;
			}
		}
		else if (newop.type == PyGoWaveOperation_DOCUMENT_DELETE && op.type == PyGoWaveOperation_DOCUMENT_INSERT) {
			if (newop.index >= op.index && newop.index < op.index+op.length) {
				int remain = op.length - (newop.index - op.index);
				if (remain > newop.length) {
					[op deleteStringAtIndex:(newop.index-op.index) withLength:newop.length];
					[newop resizeToLength:0];
				}
				else {
					[op deleteStringAtIndex:(newop.index-op.index) withLength:remain];
					[newop resizeToLength:newop.length-remain];
				}
				if (op.isNull) {
					[self removeOperationAtIndex:i];
					i--;
				}
				else
					[self postOperationChangedWithIndex:i];
				if (newop.isNull)
					return;
			}
			else if (newop.index < op.index && newop.index+newop.length > op.index) {
				if (newop.index+newop.length >= op.index+op.length) {
					[newop resizeToLength:newop.length-op.length];
					[self removeOperationAtIndex:i];
					i--;
				}
				else {
					int dlength = newop.index+newop.length - op.index;
					[newop resizeToLength:newop.length - dlength];
					[op deleteStringAtIndex:0 withLength:dlength];
					[self postOperationChangedWithIndex:i];
				}
			}
		}
		else if (newop.type == PyGoWaveOperation_DOCUMENT_DELETE && op.type == PyGoWaveOperation_DOCUMENT_DELETE) {
			if (newop.index == op.index) {
				[op resizeToLength:op.length+newop.length];
				[self postOperationChangedWithIndex:i];
				return;
			}
			if (newop.index == (op.index - newop.length)) {
				op.index -= newop.length;
				[op resizeToLength:op.length+newop.length];
				[self postOperationChangedWithIndex:i];
				return;
			}
		}
		else if ((newop.type == PyGoWaveOperation_WAVELET_ADD_PARTICIPANT && op.type == PyGoWaveOperation_WAVELET_ADD_PARTICIPANT)
				|| (newop.type == PyGoWaveOperation_WAVELET_REMOVE_PARTICIPANT && op.type == PyGoWaveOperation_WAVELET_REMOVE_PARTICIPANT)) {
			if ([newop.property isEqual:op.property])
				return;
		}
	}
	[self insertOperation:newop atIndex:i+1];
	return;
}

#pragma mark Operation generators

- (void)documentInsert:(NSString*)aText atIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId
{
	PyGoWaveOperation * op = [[PyGoWaveOperation alloc]
		initWithType:PyGoWaveOperation_DOCUMENT_INSERT
			  waveId:m_waveId
		   waveletId:m_waveletId
			  blipId:aBlipId
			   index:aIndex
			property:aText
	];
	[self mergeInsertOperation:op];
	[op release];
}

- (void)documentDeleteFromStart:(NSInteger)aStart toEnd:(NSInteger)aEnd inBlipWithId:(NSString*)aBlipId
{
	PyGoWaveOperation * op = [[PyGoWaveOperation alloc]
		initWithType:PyGoWaveOperation_DOCUMENT_DELETE
			  waveId:m_waveId
		   waveletId:m_waveletId
			  blipId:aBlipId
			   index:aStart
			property:[NSNumber numberWithInt:aEnd-aStart]
	];
	[self mergeInsertOperation:op];
	[op release];
}

- (void)documentElementInsertAtIndex:(NSInteger)aIndex type:(NSInteger)aType properties:(NSDictionary*)sProperties inBlipWithId:(NSString*)aBlipId
{
	PyGoWaveOperation * op = [[PyGoWaveOperation alloc]
		initWithType:PyGoWaveOperation_DOCUMENT_ELEMENT_INSERT
			  waveId:m_waveId
		   waveletId:m_waveletId
			  blipId:aBlipId
			   index:aIndex
			property:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:aType], @"type", sProperties, @"properties", nil]
	];
	[self mergeInsertOperation:op];
	[op release];
}

- (void)documentElementDeleteAtIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId
{
	PyGoWaveOperation * op = [[PyGoWaveOperation alloc]
		initWithType:PyGoWaveOperation_DOCUMENT_ELEMENT_DELETE
			  waveId:m_waveId
		   waveletId:m_waveletId
			  blipId:aBlipId
			   index:aIndex
			property:nil
	];
	[self mergeInsertOperation:op];
	[op release];
}

- (void)documentElementApplyDelta:(NSDictionary*)aDelta atIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId
{
	PyGoWaveOperation * op = [[PyGoWaveOperation alloc]
		initWithType:PyGoWaveOperation_DOCUMENT_ELEMENT_DELTA
			  waveId:m_waveId
		   waveletId:m_waveletId
			  blipId:aBlipId
			   index:aIndex
			property:aDelta
	];
	[self mergeInsertOperation:op];
	[op release];
}

- (void)documentElementSetUserPrefWithKey:(NSString*)aKey toValue:(NSString*)aValue atIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId
{
	PyGoWaveOperation * op = [[PyGoWaveOperation alloc]
		initWithType:PyGoWaveOperation_DOCUMENT_ELEMENT_SETPREF
			  waveId:m_waveId
		   waveletId:m_waveletId
			  blipId:aBlipId
			   index:aIndex
			property:[NSDictionary dictionaryWithObjectsAndKeys:aKey, @"key", aValue, @"value", nil]
	];
	[self mergeInsertOperation:op];
	[op release];
}

- (void)waveletAddParticipantWithId:(NSString*)aId
{
	PyGoWaveOperation * op = [[PyGoWaveOperation alloc]
		initWithType:PyGoWaveOperation_WAVELET_ADD_PARTICIPANT
			  waveId:m_waveId
		   waveletId:m_waveletId
			  blipId:@""
			   index:-1
			property:aId
	];
	[self mergeInsertOperation:op];
	[op release];
}

- (void)waveletRemoveParticipantWithId:(NSString*)aId
{
	PyGoWaveOperation * op = [[PyGoWaveOperation alloc]
		initWithType:PyGoWaveOperation_WAVELET_REMOVE_PARTICIPANT
			  waveId:m_waveId
		   waveletId:m_waveletId
			  blipId:@""
			   index:-1
			property:aId
	];
	[self mergeInsertOperation:op];
	[op release];
}

- (void)waveletAppendBlipWithTempId:(NSString*)aTempId
{
	PyGoWaveOperation * op = [[PyGoWaveOperation alloc]
		initWithType:PyGoWaveOperation_WAVELET_APPEND_BLIP
			  waveId:m_waveId
		   waveletId:m_waveletId
			  blipId:@""
			   index:-1
			property:[NSDictionary dictionaryWithObjectsAndKeys:m_waveId, @"waveId", m_waveletId, @"waveletId", aTempId, @"blipId", nil]
	];
	[self mergeInsertOperation:op];
	[op release];
}

- (void)blipDeleteWithId:(NSString*)aId
{
	PyGoWaveOperation * op = [[PyGoWaveOperation alloc]
		initWithType:PyGoWaveOperation_BLIP_DELETE
			  waveId:m_waveId
		   waveletId:m_waveletId
			  blipId:aId
			   index:-1
			property:nil
	];
	[self mergeInsertOperation:op];
	[op release];
}

- (void)blipCreateChildWithTempId:(NSString*)aTempId forBlipWithId:(NSString*)aBlipId
{
	PyGoWaveOperation * op = [[PyGoWaveOperation alloc]
		initWithType:PyGoWaveOperation_BLIP_CREATE_CHILD
			  waveId:m_waveId
		   waveletId:m_waveletId
			  blipId:aBlipId
			   index:-1
			property:[NSDictionary dictionaryWithObjectsAndKeys:m_waveId, @"waveId", m_waveletId, @"waveletId", aTempId, @"blipId", nil]
	];
	[self mergeInsertOperation:op];
	[op release];
}

- (NSArray*)operations
{
	return [NSArray arrayWithArray:m_operations];
}

- (void)insertOperation:(PyGoWaveOperation*)aOperation atIndex:(NSInteger)aIndex
{
	if (aIndex > [m_operations count] || aIndex < 0)
		return;
	NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:aIndex], @"start", [NSNumber numberWithInt:aIndex], @"end", nil];
	[self postNotificationName:@"beforeOperationsInserted"
					  userInfo:info
					coalescing:NO];
	[m_operations insertObject:aOperation atIndex:aIndex];
	[self postNotificationName:@"afterOperationsInserted"
					  userInfo:info
					coalescing:NO];
}

- (void)removeOperationAtIndex:(NSInteger)aIndex
{
	if (aIndex < 0 || aIndex >= [m_operations count])
		return;
	NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:aIndex], @"start", [NSNumber numberWithInt:aIndex], @"end", nil];
	[self postNotificationName:@"beforeOperationsRemoved"
					  userInfo:info
					coalescing:NO];
	[m_operations removeObjectAtIndex:aIndex];
	[self postNotificationName:@"afterOperationsRemoved"
					  userInfo:info
					coalescing:NO];
}

- (void)removeOperationsFromStart:(NSInteger)aStart toEnd:(NSInteger)aEnd
{
	if (aStart < 0 || aEnd < 0 || aStart > aEnd || aStart >= [m_operations count] || aEnd >= [m_operations count])
		return;
	NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:aStart], @"start", [NSNumber numberWithInt:aEnd], @"end", nil];
	[self postNotificationName:@"beforeOperationsRemoved"
					  userInfo:info
					coalescing:NO];
	[m_operations removeObjectsInRange:NSMakeRange(aStart, aEnd-aStart+1)];
	[self postNotificationName:@"afterOperationsRemoved"
					  userInfo:info
					coalescing:NO];
}

- (void)updateBlipId:(NSString*)aTempId toBlipId:(NSString*)aBlipId
{
	for (int i = 0; i < [m_operations count]; i++) {
		PyGoWaveOperation * op = [m_operations objectAtIndex:i];
		if ([op.blipId isEqual:aTempId]) {
			op.blipId = aBlipId;
			[self postNotificationName:@"operationChanged" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:i], @"index", nil]];
		}
	}
}

- (void)lockBlipOpsWithId:(NSString*)aId
{
	if (![m_lockedBlips containsObject:aId])
		[m_lockedBlips addObject:aId];
}

- (void)unlockBlipOpsWithId:(NSString*)aId
{
	[m_lockedBlips removeObject:aId];
}

#pragma mark Observer add/remove methods

- (void)addOperationChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"operationChanged"];
}
- (void)removeOperationChangedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"operationChanged"];
}

- (void)addBeforeOperationsRemovedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"beforeOperationsRemoved"];
}
- (void)removeBeforeOperationsRemovedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"beforeOperationsRemoved"];
}

- (void)addAfterOperationsRemovedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"afterOperationsRemoved"];
}
- (void)removeAfterOperationsRemovedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"afterOperationsRemoved"];
}

- (void)addBeforeOperationsInsertedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"beforeOperationsInserted"];
}
- (void)removeBeforeOperationsInsertedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"beforeOperationsInserted"];
}

- (void)addAfterOperationsInsertedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"afterOperationsInserted"];
}
- (void)removeAfterOperationsInsertedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"afterOperationsInserted"];
}

@end
