
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

#import "PyGoWaveModel.h"
#import "STOMP/CRVStompClient.h"


enum {
	PyGoWaveController_ClientDisconnected = 0,
	PyGoWaveController_ClientConnected,
	PyGoWaveController_ClientOnline
};
typedef NSInteger PyGoWaveControllerClientState;

@interface PyGoWaveController : PyGoWaveObject <CRVStompClientDelegate, PyGoWaveParticipantProvider>
{
	CRVStompClient * m_conn;
	BOOL m_connected;
	NSTimer * m_pingTimer;
	NSTimer * m_pendingTimer;

	NSString * m_stompServer;
	NSInteger m_stompPort;
	NSString * m_stompUsername;
	NSString * m_stompPassword;

	NSString * m_username;
	NSString * m_password;

	NSString * m_waveAccessKeyTx;
	NSString * m_waveAccessKeyRx;
	NSString * m_viewerId;

	PyGoWaveControllerClientState m_state;

	NSMutableDictionary * m_allWaves;
	NSMutableDictionary * m_allWavelets;
	NSMutableDictionary * m_allParticipants;
	BOOL m_participantsTodoCollect;
	NSMutableSet * m_participantsTodo;
	NSMutableSet * m_openWavelets;

	NSMutableDictionary * m_mcached;
	NSMutableDictionary * m_mpending;
	NSMutableDictionary * m_draftblips;
	NSMutableDictionary * m_ispending;

	NSInteger m_lastSearchId;
	NSString * m_createdWaveId;

	NSMutableArray * m_cachedGadgetList;
}
@property (readonly) PyGoWaveControllerClientState state;
@property (readonly, nonatomic, copy) NSString * hostName;
@property (readonly, nonatomic) PyGoWaveParticipant * viewer;

#pragma mark Initialization and Deallocation

- (id)init;
- (void)dealloc;

#pragma mark -
#pragma mark Public methods

- (void)connectToHost:(NSString*)aHost username:(NSString*)aUsername password:(NSString*)aPassword;
- (void)connectToHost:(NSString*)aHost username:(NSString*)aUsername password:(NSString*)aPassword stompPort:(NSInteger)aStompPort stompUsername:(NSString*)aStompUsername stompPassword:(NSString*)aStompPassword;
- (void)reconnectToHostWithUsername:(NSString*)aUsername password:(NSString*)aPassword;
- (void)disconnectFromHost;

- (PyGoWaveWaveModel*)waveWithId:(NSString*)aId;
- (PyGoWaveWavelet*)waveletWithId:(NSString*)aId;

- (NSInteger)searchForParticipantWithQuery:(NSString*)aQuery;

- (NSArray*)gadgetList;

- (void)textInserted:(NSString*)aText atIndex:(NSInteger)aIndex inBlipId:(NSString*)aBlipId ofWaveletId:(NSString*)aWaveletId;
- (void)textDeletedFromStart:(NSInteger)aStart toEnd:(NSInteger)aEnd inBlipWithId:(NSString*)aBlipId ofWaveletWithId:(NSString*)aWaveletId;
- (void)elementInsertAtIndex:(NSInteger)aIndex type:(NSInteger)aType properties:(NSDictionary*)sProperties inBlipWithId:(NSString*)aBlipId ofWaveletWithId:(NSString*)aWaveletId;
- (void)elementDeleteAtIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId ofWaveletWithId:(NSString*)aWaveletId;
- (void)elementDeltaSubmitted:(NSDictionary*)aDelta atIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId ofWaveletWithId:(NSString*)aWaveletId;
- (void)elementSetUserPrefWithKey:(NSString*)aKey toValue:(NSString*)aValue atIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId ofWaveletWithId:(NSString*)aWaveletId;

- (void)appendBlipToWaveletWithId:(NSString*)aWaveletId;
- (void)deleteBlipWithId:(NSString*)aId ofWaveletWithId:(NSString*)aWaveletId;
- (void)draftBlipWithId:(NSString*)aId ofWaveletWithId:(NSString*)aWaveletId enabled:(BOOL)bEnabled;

- (void)openWaveletWithId:(NSString*)aId;
- (void)closeWaveletWithId:(NSString*)aId;
- (void)addParticipantWithId:(NSString*)aId toWaveletWithId:(NSString*)aWaveletId;
- (void)createNewWaveWithTitle:(NSString*)aTitle;
- (void)createNewWaveletWithTitle:(NSString*)aTitle inWaveWithId:(NSString*)aWaveId;
- (void)leaveWaveletWithId:(NSString*)aId;

- (void)refreshGadgetList;
- (void)refreshGadgetListForced:(BOOL)bForced;

#pragma mark -
#pragma mark PyGoWaveParticipantProvider

- (PyGoWaveParticipant *)participantById:(NSString *)aParticipntId;

#pragma mark -
#pragma mark Observer add/remove methods

/* StateChanged
 state	NSNumber/int
*/
- (void)addStateChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeStateChangedObserver:(id)notificationObserver;

/* ErrorOccurred
 waveletId	NSString
 tag		NSString
 desc		NSString
*/
- (void)addErrorOccurredObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeErrorOccurredObserver:(id)notificationObserver;

/* WaveletOpened
 waveletId	NSString
 isRoot		NSNumber/BOOL
*/
- (void)addWaveletOpenedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeWaveletOpenedObserver:(id)notificationObserver;

/* ParticipantSearchResults
 searchId	NSNumber/int
 ids		NSArray[NSString]
*/
- (void)addParticipantSearchResultsObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeParticipantSearchResultsObserver:(id)notificationObserver;

/* ParticipantSearchResultsInvalid
 searchId		NSNumber/int
 minimumLetters	NSNumber/int
*/
- (void)addParticipantSearchResultsInvalidObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeParticipantSearchResultsInvalidObserver:(id)notificationObserver;

/* WaveAdded
 waveId		NSString
 created	NSNumber/BOOL
 initial	NSNumber/BOOL
*/
- (void)addWaveAddedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeWaveAddedObserver:(id)notificationObserver;

/* WaveAboutToBeRemoved
 waveId		NSString
*/
- (void)addWaveAboutToBeRemovedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeWaveAboutToBeRemovedObserver:(id)notificationObserver;

/* UpdateGadgetList
 gadgetList	NSArray[NSDictionary]
*/
- (void)addUpdateGadgetListObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeUpdateGadgetListObserver:(id)notificationObserver;

@end
