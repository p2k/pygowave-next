
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


enum {
	PyGoWaveOperation_DOCUMENT_NOOP = 0,
	PyGoWaveOperation_DOCUMENT_INSERT,
	PyGoWaveOperation_DOCUMENT_DELETE,
	PyGoWaveOperation_DOCUMENT_ELEMENT_INSERT,
	PyGoWaveOperation_DOCUMENT_ELEMENT_DELETE,
	PyGoWaveOperation_DOCUMENT_ELEMENT_DELTA,
	PyGoWaveOperation_DOCUMENT_ELEMENT_SETPREF,
	PyGoWaveOperation_WAVELET_ADD_PARTICIPANT,
	PyGoWaveOperation_WAVELET_REMOVE_PARTICIPANT,
	PyGoWaveOperation_WAVELET_APPEND_BLIP,
	PyGoWaveOperation_BLIP_CREATE_CHILD,
	PyGoWaveOperation_BLIP_DELETE
};
typedef NSInteger PyGoWaveOperationType;

@interface PyGoWaveOperation : NSObject <NSCopying>
{
	PyGoWaveOperationType m_type;
	NSString * m_waveId;
	NSString * m_waveletId;
	NSString * m_blipId;
	NSInteger m_index;
	id m_property;
}
@property (readonly) PyGoWaveOperationType type;
@property (readonly) NSString * waveId;
@property (readonly) NSString * waveletId;
@property (nonatomic, copy) NSString * blipId;
@property NSInteger index;
@property (nonatomic, readonly) NSInteger length;
@property (nonatomic, readonly) BOOL isNull;
@property (nonatomic, readonly) BOOL isInsert;
@property (nonatomic, readonly) BOOL isDelete;
@property (nonatomic, readonly) BOOL isChange;
@property (nonatomic, copy) id property;

- (id)initWithType:(PyGoWaveOperationType)aType
			waveId:(NSString*)aWaveId
		 waveletId:(NSString*)aWaveletId;
- (id)initWithType:(PyGoWaveOperationType)aType
			waveId:(NSString*)aWaveId
		 waveletId:(NSString*)aWaveletId
			blipId:(NSString*)aBlipId
			 index:(NSInteger)aIndex
		  property:(id)aProperty;
- (void)dealloc;

- (id)copyWithZone:(NSZone *)zone;

- (BOOL)isCompatibleToOperation:(PyGoWaveOperation*)aOperation;

- (void)resizeToLength:(NSInteger)aLength;

- (void)insertString:(NSString*)aString atIndex:(NSInteger)aIndex;
- (void)deleteStringAtIndex:(NSInteger)aIndex withLength:(NSInteger)aLength;

- (NSDictionary*)serialize;
+ (id)operationWithSerialized:(NSDictionary*)aSerialized;

+ (NSString*)stringFromType:(PyGoWaveOperationType)aType;
+ (PyGoWaveOperationType)typeFromString:(NSString*)aType;

@end


@interface PyGoWaveOpManager : PyGoWaveObject
{
	NSString * m_waveId;
	NSString * m_waveletId;
	NSString * m_contributorId;
	NSMutableArray * m_operations;
	NSMutableArray * m_lockedBlips;
}
@property (readonly) NSString * waveId;
@property (readonly) NSString * waveletId;
@property (readonly) NSString * contributorId;
@property (readonly, nonatomic) BOOL isEmpty;
@property (readonly, nonatomic) BOOL canFetch;

- (id)initWithWaveId:(NSString*)aWaveId waveletId:(NSString*)aWaveletId contributorId:(NSString*)aContributorId;
- (void)dealloc;

- (NSArray*)transformInputOperation:(PyGoWaveOperation*)aInputOperation;

- (NSArray*)fetchOperations;
- (void)putOperations:(NSArray*)sOperations;

- (NSArray*)serializeOperations;
- (NSArray*)serializeAndFetchOperations:(BOOL)bFetch;
- (void)addSerializedOperations:(NSArray*)sSerializedOperations;

- (void)documentInsert:(NSString*)aText atIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId;
- (void)documentDeleteFromStart:(NSInteger)aStart toEnd:(NSInteger)aEnd inBlipWithId:(NSString*)aBlipId;

- (void)documentElementInsertAtIndex:(NSInteger)aIndex type:(NSInteger)aType properties:(NSDictionary*)sProperties inBlipWithId:(NSString*)aBlipId;
- (void)documentElementDeleteAtIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId;

- (void)documentElementApplyDelta:(NSDictionary*)aDelta atIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId;
- (void)documentElementSetUserPrefWithKey:(NSString*)aKey toValue:(NSString*)aValue atIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId;

- (void)waveletAddParticipantWithId:(NSString*)aId;
- (void)waveletRemoveParticipantWithId:(NSString*)aId;
- (void)waveletAppendBlipWithTempId:(NSString*)aTempId;

- (void)blipDeleteWithId:(NSString*)aId;
- (void)blipCreateChildWithTempId:(NSString*)aTempId forBlipWithId:(NSString*)aBlipId;

- (NSArray*)operations;

- (void)insertOperation:(PyGoWaveOperation*)aOperation atIndex:(NSInteger)aIndex;
- (void)removeOperationAtIndex:(NSInteger)aIndex;
- (void)removeOperationsFromStart:(NSInteger)aStart toEnd:(NSInteger)aEnd;

- (void)updateBlipId:(NSString*)aTempId toBlipId:(NSString*)aBlipId;

- (void)lockBlipOpsWithId:(NSString*)aId;
- (void)unlockBlipOpsWithId:(NSString*)aId;

- (void)addOperationChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeOperationChangedObserver:(id)notificationObserver;

- (void)addBeforeOperationsRemovedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeBeforeOperationsRemovedObserver:(id)notificationObserver;

- (void)addAfterOperationsRemovedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeAfterOperationsRemovedObserver:(id)notificationObserver;

- (void)addBeforeOperationsInsertedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeBeforeOperationsInsertedObserver:(id)notificationObserver;

- (void)addAfterOperationsInsertedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeAfterOperationsInsertedObserver:(id)notificationObserver;

@end
