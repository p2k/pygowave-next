
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

#import "PyGoWaveController.h"
#import "PyGoWaveOperations.h"
#import "CoreFoundation/CFUUID.h"
#import "JSON.h"

@implementation PyGoWaveController

@synthesize state = m_state, hostName = m_stompServer;

#pragma mark Initialization and Deallocation

- (id)init
{
	if (self = [super init]) {
		m_allWaves = [NSMutableDictionary new];
		m_allWavelets = [NSMutableDictionary new];
		m_allParticipants = [NSMutableDictionary new];
		m_participantsTodo = [NSMutableSet new];
		m_openWavelets = [NSMutableSet new];
		m_mcached = [NSMutableDictionary new];
		m_mpending = [NSMutableDictionary new];
		m_draftblips = [NSMutableDictionary new];
		m_ispending = [NSMutableDictionary new];
		m_cachedGadgetList = [NSMutableArray new];
		m_stompServer = [@"localhost" copy];
		m_stompPort = 61613;
		m_stompUsername = [@"pygowave_client" copy];
		m_stompPassword = [@"pygowave_client" copy];
		m_conn = nil;
		m_state = PyGoWaveController_ClientDisconnected;
		m_lastSearchId = 0;
		m_participantsTodoCollect = NO;
	}
	return self;
}

- (void)dealloc
{
	[m_stompServer release];
	[m_stompUsername release];
	[m_stompPassword release];
	[m_pingTimer release];
	[m_pendingTimer release];
	[m_conn release];
	[m_username release];
	[m_password release];
	[m_waveAccessKeyTx release];
	[m_waveAccessKeyRx release];
	[m_viewerId release];
	[m_createdWaveId release];
	[m_allWaves release];
	[m_allWavelets release];
	[m_allParticipants release];
	[m_participantsTodo release];
	[m_openWavelets release];
	[m_mcached release];
	[m_mpending release];
	[m_draftblips release];
	[m_ispending release];
	[m_cachedGadgetList release];
	[m_waveAccessKeyRx release];
	[m_waveAccessKeyTx release];
	[super dealloc];
}

#pragma mark -
#pragma mark Private methods

- (unsigned long long)timestamp
{
	NSTimeInterval s = [[NSDate date] timeIntervalSince1970];
	return (unsigned long long)(s * 1000.0);
}

- (void)resetPingTimer
{
	if (m_pingTimer != nil) {
		[m_pingTimer invalidate];
		[m_pingTimer release];
	}
	m_pingTimer = [[NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(pingTimer_timeout:) userInfo:nil repeats:YES] retain];
}

- (void)killPendingTimer
{
	if (m_pendingTimer != nil) {
		[m_pendingTimer invalidate];
		[m_pendingTimer release];
	}
	m_pendingTimer = nil;
}

- (void)resetPendingTimer
{
	[self killPendingTimer];
	m_pendingTimer = [[NSTimer timerWithTimeInterval:10.0 target:self selector:@selector(pendingTimer_timeout:) userInfo:nil repeats:NO] retain];
}

- (void)pendingTimer_timeout:(NSTimer*)aTimer
{
	//TODO
}

- (void)addWave:(PyGoWaveWaveModel*)aWave initialMode:(BOOL)bInitialMode
{
	NSAssert([m_allWaves valueForKey:aWave.waveId] == nil, @"Wave was already present");
	[m_allWaves setValue:aWave forKey:aWave.waveId];
	for (PyGoWaveWavelet * wavelet in [aWave allWavelets]) {
		[m_allWavelets setValue:wavelet forKey:wavelet.waveletId];
		PyGoWaveOpManager * mcached = [[PyGoWaveOpManager alloc] initWithWaveId:aWave.waveId waveletId:wavelet.waveletId contributorId:m_viewerId];
		[mcached addBeforeOperationsInsertedObserver:self selector:@selector(mcached_afterOperationsInserted:)];
		[wavelet addParticipantsChangedObserver:self selector:@selector(wavelet_participantsChanged:)];
		[m_mcached setValue:mcached forKey:wavelet.waveletId];
		[mcached release];
		PyGoWaveOpManager * mpending = [[PyGoWaveOpManager alloc] initWithWaveId:aWave.waveId waveletId:wavelet.waveletId contributorId:m_viewerId];
		[m_mpending setValue:mpending forKey:wavelet.waveletId];
		[mpending release];
		[m_ispending setValue:[NSNumber numberWithBool:NO] forKey:wavelet.waveletId];
	}
	BOOL created = NO;
	if (m_createdWaveId != nil && [m_createdWaveId isEqual:aWave.waveId]) {
		[m_createdWaveId release];
		m_createdWaveId = nil;
		created = YES;
	}
	[self postNotificationName:@"waveAdded"
					  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
								aWave.waveId, @"waveId",
								[NSNumber numberWithBool:created], @"created",
								[NSNumber numberWithBool:bInitialMode], @"initial",
								nil]
					coalescing:NO];
}

- (void)removeWaveWithId:(NSString*)aId
{
	PyGoWaveWaveModel * wave = [[m_allWaves valueForKey:aId] retain];
	NSAssert(wave != nil, @"Wave was not found");
	[self postNotificationName:@"waveAboutToBeRemoved"
					  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aId, @"waveId", nil]
					coalescing:NO];
	for (PyGoWaveWavelet * wavelet in [wave allWavelets])
		[m_allWavelets removeObjectForKey:wavelet.waveletId];
	[m_allWaves removeObjectForKey:aId];
	[wave autorelease];
}

- (void)clearWaves
{
	for (NSString * aId in [m_allWaves allKeys])
		[self removeWaveWithId:aId];
}

- (void)sendJsonTo:(NSString*)aDestination
	   messageType:(NSString*)aMessageType
		  property:(NSObject*)aProperty
{
	if (m_waveAccessKeyTx == nil) return;
	NSMutableDictionary * obj = [NSMutableDictionary new];
	[obj setValue:aMessageType forKey:@"type"];
	if (aProperty != nil)
		[obj setValue:aProperty forKey:@"property"];
	NSDictionary * header = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithFormat:@"%@.%@.clientop", m_waveAccessKeyTx, aDestination], @"destination",
		@"wavelet.topic", @"exchange",
		@"application/json", @"content-type",
		nil
	];
	[m_conn sendMessage:[obj JSONRepresentation] customHeader:header];
	if (m_state == PyGoWaveController_ClientOnline)
		[self resetPingTimer];
}
- (void)sendJsonTo:(NSString*)aDestination
	   messageType:(NSString*)aMessageType
{
	[self sendJsonTo:aDestination messageType:aMessageType property:nil];
}

- (void)pingTimer_timeout:(NSTimer*)aTimer
{
	[self sendJsonTo:@"manager" messageType:@"PING" property:[NSString stringWithFormat:@"%llu", [self timestamp]]];
}

- (void)subscribeWaveletWithId:(NSString*)aId open:(BOOL)bOpen
{
	NSDictionary * header = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithFormat:@"%@.%@.waveop", m_waveAccessKeyRx, aId], @"routing_key",
		@"wavelet.topic", @"exchange",
		@"true", @"exclusive",
		nil
	];
	[m_conn subscribeToDestination:[NSString stringWithFormat:@"%@.%@.waveop", m_waveAccessKeyRx, aId] withHeader:header];
	
	if (bOpen)
		[self sendJsonTo:aId messageType:@"WAVELET_OPEN"];
}

- (void)unsubscribeWaveletWithId:(NSString*)aId close:(BOOL)bClose
{
	if (bClose)
		[self sendJsonTo:aId messageType:@"WAVELET_CLOSE"];
	
	[m_conn unsubscribeFromDestination:[NSString stringWithFormat:@"%@.%@.waveop", m_waveAccessKeyRx, aId]];
	[m_openWavelets removeObject:aId];
}
- (void)unsubscribeWaveletWithId:(NSString*)aId
{
	[self unsubscribeWaveletWithId:aId close:YES];
}

- (void)postErrorOccurredNotification:(NSString*)aTag description:(NSString*)aDescription waveletId:(NSString*)aWaveletId
{
	[self postNotificationName:@"errorOccurred"
					  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
								aWaveletId, @"waveletId",
								aTag, @"tag",
								aDescription, @"desc",
								nil]
					coalescing:NO];
}

- (void)collectParticipants
{
	m_participantsTodoCollect = YES;
}

- (void)retrieveParticipants
{
	// Retrieve missing participants
	if ([m_participantsTodo count] > 0) {
		[self sendJsonTo:@"manager" messageType:@"PARTICIPANT_INFO" property:[m_participantsTodo allObjects]];
		[m_participantsTodo removeAllObjects];
	}
	m_participantsTodoCollect = NO;
}

- (PyGoWaveWavelet*)newWaveletWithDict:(NSDictionary*)aDict waveletId:(NSString*)aWaveletId wave:(PyGoWaveWaveModel*)aWave
{
	NSArray * participants = [aDict valueForKey:@"participants"];
	
	PyGoWaveWavelet * aWavelet = [aWave createWaveletWithId:aWaveletId
		creator:[self participantById:[aDict valueForKey:@"creator"]]
		title:[aDict valueForKey:@"title"]
		isRoot:[[aDict valueForKey:@"isRoot"] boolValue]
		created:[NSDate dateWithTimeIntervalSince1970:(double)[[aDict valueForKey:@"creationTime"] unsignedIntValue]]
		lastModified:[NSDate dateWithTimeIntervalSince1970:(double)[[aDict valueForKey:@"lastModifiedTime"] unsignedIntValue]]
		version:[[aDict valueForKey:@"version"] intValue]
	];
	
	for (NSString * aParticipantId in participants)
		[aWavelet addParticipant:[self participantById:aParticipantId]];
	
	return aWavelet;
}

- (void)updateWavelet:(PyGoWaveWavelet*)aWavelet withDict:(NSDictionary*)aDict
{
	NSSet * participants = [NSSet setWithArray:[aDict valueForKey:@"participants"]];
	
	aWavelet.title = [aDict valueForKey:@"title"];
	aWavelet.lastModified = [NSDate dateWithTimeIntervalSince1970:(double)[[aDict valueForKey:@"lastModifiedTime"] unsignedIntValue]];
	
	NSMutableSet * newParticipants = [participants mutableCopy];
	NSMutableSet * oldParticipants = [NSMutableSet setWithArray:[aWavelet allParticipantIDs]];
	[newParticipants minusSet:oldParticipants];
	[oldParticipants minusSet:participants];
	
	for (NSString * aParticipantId in newParticipants)
		[aWavelet addParticipant:[self participantById:aParticipantId]];
	for (NSString * aParticipantId in oldParticipants)
		[aWavelet removeParticipantById:aParticipantId];
}

- (BOOL)waveletHasPendingOperations:(NSString*)aWaveletId
{
	NSNumber * p = [m_ispending valueForKey:aWaveletId];
	NSAssert(p != nil, @"Wavelet not found");
	return [p boolValue] || ![[m_mpending valueForKey:aWaveletId] isEmpty];
}

- (void)transferOperationsForWaveletWithId:(NSString*)aWaveletId
{
	PyGoWaveOpManager * mp = [m_mpending valueForKey:aWaveletId];
	NSAssert(mp != nil, @"Wavelet not found");
	PyGoWaveOpManager * mc = [m_mcached valueForKey:aWaveletId];
	PyGoWaveWavelet * model = [m_allWavelets valueForKey:aWaveletId];
	
	if (mp.isEmpty)
		[mp putOperations:[mc fetchOperations]];
	
	if (mp.isEmpty)
		return;
	
	[m_ispending setValue:[NSNumber numberWithBool:YES] forKey:aWaveletId];
	[self resetPendingTimer];
	
	[self sendJsonTo:aWaveletId messageType:@"OPERATION_MESSAGE_BUNDLE" property:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:model.version], @"version", [mp serializeOperations], @"operations", nil]];
}

- (void)processMessageBundleForWavelet:(PyGoWaveWavelet*)aWavelet
								 isAck:(BOOL)bAck
				   serialOpsOrNewblips:(id)sOpsOrNewblips
							   version:(NSInteger)aVersion
							  blipsums:(NSDictionary*)sBlipsums 
							 timestamp:(NSDate*)aTimestamp
						 contributorId:(NSString*)aContributorId
{
	PyGoWaveOpManager * mpending = [m_mpending valueForKey:aWavelet.waveletId];
	PyGoWaveOpManager * mcached = [m_mcached valueForKey:aWavelet.waveletId];
	
	if (bAck) {
		PyGoWaveOpManager * delta = [[PyGoWaveOpManager alloc] initWithWaveId:aWavelet.waveId waveletId:aWavelet.waveletId contributorId:aContributorId];
		[delta addSerializedOperations:(NSArray*)sOpsOrNewblips];
		
		NSMutableArray * ops = [NSMutableArray new];
		
		// Iterate over all operations
		for (PyGoWaveOperation * incoming in [delta operations]) {
			// Transform pending operations, iterate over results
			for (PyGoWaveOperation * tr in [mpending transformInputOperation:incoming]) {
				// Transform cached operations, save results
				[ops addObject:[mcached transformInputOperation:tr]];
			}
		}
		
		// Apply operations
		[self collectParticipants];
		[aWavelet applyOperations:ops timestamp:aTimestamp contributorId:aContributorId];
		[self retrieveParticipants];
		
		// Set version and checkup
		aWavelet.version = aVersion;
		if (![self waveletHasPendingOperations:aWavelet.waveletId] && mcached.isEmpty)
			[aWavelet checkSync:sBlipsums];
		[ops release];
	}
	else { // ACK message
		[self killPendingTimer];
		aWavelet.version = aVersion;
		[mpending fetchOperations];
		
		// Update Blip IDs
		NSMutableArray * draftblips = [m_draftblips valueForKey:aWavelet.waveletId];
		NSDictionary * idDict = sOpsOrNewblips;
		for (NSString * aTempId in idDict) {
			NSString * aBlipId = [idDict valueForKey:aTempId];
			[aWavelet updateBlipId:aTempId toBlipId:aBlipId];
			[mcached unlockBlipOpsWithId:aTempId];
			[mcached updateBlipId:aTempId toBlipId:aBlipId];
			if ([draftblips containsObject:aTempId]) {
				[draftblips removeObject:aTempId];
				[draftblips addObject:aBlipId];
				[mcached lockBlipOpsWithId:aBlipId];
			}
		}
		
		if (!mcached.isEmpty) {
			if (mcached.canFetch)
				[self transferOperationsForWaveletWithId:aWavelet.waveletId];
		}
		else {
			// All done, we can do a check-up
			[aWavelet checkSync:sBlipsums];
			[m_ispending setValue:[NSNumber numberWithBool:NO] forKey:aWavelet.waveletId];
		}
	}
}

- (void)queueMessageBundleForWavelet:(PyGoWaveWavelet*)aWavelet
							   isAck:(BOOL)bAck
				 serialOpsOrNewblips:(NSObject*)sOpsOrNewblips
							 version:(NSInteger)aVersion
							blipsums:(NSDictionary*)sBlipsums
						   timestamp:(NSDate*)aTimestamp
					   contributorId:(NSString*)aContributorId
{
	//TODO
	[self processMessageBundleForWavelet:aWavelet isAck:bAck serialOpsOrNewblips:sOpsOrNewblips version:aVersion blipsums:sBlipsums timestamp:aTimestamp contributorId:aContributorId];
}
	
- (void)processMessageWithWaveletId:(NSString*)aId type:(NSString*)aType property:(id)aProperty
{
	if ([aType isEqual:@"ERROR"]) {
		[self postErrorOccurredNotification:[aProperty valueForKey:@"tag"] description:[aProperty valueForKey:@"desc"] waveletId:aId];
		return;
	}
	// Manager messages
	if ([aId isEqual:@"manager"]) {
		if ([aType isEqual:@"WAVE_LIST"]) {
			[self clearWaves]; // Clear all; this message is only received once per connection
			[self collectParticipants];
			NSDictionary * propertyDict = aProperty;
			for (NSString * aWaveId in propertyDict) {
				PyGoWaveWaveModel * aWave = [[PyGoWaveWaveModel alloc] initWithWaveId:aWaveId viewerId:m_viewerId participantProvider:self];
				NSDictionary * sWavelets = [propertyDict valueForKey:aWaveId];
				for (NSString * aWaveletId in sWavelets)
					[self newWaveletWithDict:[sWavelets valueForKey:aWaveletId] waveletId:aWaveletId wave:aWave];
				[self addWave:aWave initialMode:YES];
				[aWave release];
			}
			[self retrieveParticipants];
		}
		else if ([aType isEqual:@"WAVELET_LIST"]) {
			NSDictionary * propertyDict = aProperty;
			NSString * aWaveId = [propertyDict valueForKey:@"waveId"];
			if ([m_allWaves valueForKey:aWaveId] == nil) { // New wave
				PyGoWaveWaveModel * aWave = [[PyGoWaveWaveModel alloc] initWithWaveId:aWaveId viewerId:m_viewerId participantProvider:self];
				NSDictionary * sWavelets = [propertyDict valueForKey:@"wavelets"];
				[self collectParticipants];
				for (NSString * aWaveletId in sWavelets)
					[self newWaveletWithDict:[sWavelets valueForKey:aWaveletId] waveletId:aWaveletId wave:aWave];
				[self addWave:aWave initialMode:NO];
				[aWave release];
				[self retrieveParticipants];
			}
			else { // Update old
				PyGoWaveWaveModel * aWave = [m_allWaves valueForKey:aWaveId];
				NSDictionary * sWavelets = [propertyDict valueForKey:@"wavelets"];
				for (NSString * aWaveletId in sWavelets) {
					PyGoWaveWavelet * aWavelet = [aWave waveletById:aWaveletId];
					[self collectParticipants];
					if (aWavelet != nil)
						[self updateWavelet:aWavelet withDict:[sWavelets valueForKey:aWaveletId]];
					else
						[self newWaveletWithDict:[sWavelets valueForKey:aWaveletId] waveletId:aWaveletId wave:aWave];
					[self retrieveParticipants];
				}
			}
		}
		else if ([aType isEqual:@"PARTICIPANT_INFO"]) {
			NSDictionary * propertyDict = aProperty;
			[self collectParticipants];
			for (NSString * aId in propertyDict)
				[[self participantById:aId] updateDataWithDict:[propertyDict valueForKey:aId] byServer:m_stompServer];
			[m_participantsTodo removeAllObjects]; // Trash
			[self retrieveParticipants];
		}
		else if ([aType isEqual:@"PONG"]) {
			unsigned long long ts = [self timestamp];
			unsigned long long sentTs = [aProperty longLongValue];
			if (sentTs != 0 && sentTs < ts)
				NSLog(@"Controller: Latency is %llums", ts-sentTs);
		}
		else if ([aType isEqual:@"PARTICIPANT_SEARCH"]) {
			NSDictionary * propertyDict = aProperty;
			if ([[propertyDict valueForKey:@"result"] isEqual:@"OK"]) {
				NSMutableArray * ids = [NSMutableArray new];
				[self collectParticipants];
				for (NSString * aId in [propertyDict valueForKey:@"data"]) {
					[self participantById:aId];
					[ids addObject:aId];
				}
				[self retrieveParticipants];
				[self postNotificationName:@"participantSearchResults" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:m_lastSearchId], @"searchId", ids, @"ids", nil]];
				[ids release];
			}
			else if ([[propertyDict valueForKey:@"result"] isEqual:@"TOO_SHORT"])
				[self postNotificationName:@"participantSearchResultsInvalid" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:m_lastSearchId], @"searchId", [propertyDict valueForKey:@"data"], @"minimumLetters", nil]];
		}
		else if ([aType isEqual:@"WAVELET_ADD_PARTICIPANT"]) {
			NSDictionary * propertyDict = aProperty;
			NSString * pid = [propertyDict valueForKey:@"id"];
			NSString * aWaveletId = [propertyDict valueForKey:@"waveletId"];
			PyGoWaveWavelet * aWavelet = [m_allWavelets valueForKey:aWaveletId];
			if (aWavelet == nil) {
				if ([pid isEqual:m_viewerId]) // Someone added me to a new wave, joy!
					[self sendJsonTo:@"manager" messageType:@"WAVELET_LIST" property:[NSDictionary dictionaryWithObjectsAndKeys:[propertyDict valueForKey:@"waveId"], @"waveId", nil]]; // Get the details
			}
			else
				[aWavelet addParticipant:[self participantById:pid]];
		}
		else if ([aType isEqual:@"WAVELET_REMOVE_PARTICIPANT"]) {
			NSDictionary * propertyDict = aProperty;
			NSString * pid = [propertyDict valueForKey:@"id"];
			NSString * aWaveletId = [propertyDict valueForKey:@"waveletId"];
			PyGoWaveWavelet * aWavelet = [m_allWavelets valueForKey:aWaveletId];
			if (aWavelet != nil)
				[aWavelet removeParticipantById:pid];
		}
		else if ([aType isEqual:@"WAVELET_CREATED"]) {
			NSDictionary * propertyDict = aProperty;
			NSString * aWaveId = [propertyDict valueForKey:@"waveId"];
			if ([m_allWaves valueForKey:aWaveId] == nil) {
				[m_createdWaveId release];
				m_createdWaveId = aWaveId;
			}
			[self sendJsonTo:@"manager" messageType:@"WAVELET_LIST" property:[NSDictionary dictionaryWithObjectsAndKeys:aWaveId, @"waveId", nil]]; // Reload wave
		}
		else if ([aType isEqual:@"GADGET_LIST"]) {
			NSArray * propertyArray = aProperty;
			[m_cachedGadgetList removeAllObjects];
			[m_cachedGadgetList addObjectsFromArray:propertyArray];
			[self postNotificationName:@"updateGadgetList" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:m_cachedGadgetList, @"gadgetList", nil]];
		}
		return;
	}
	
	// Wavelet messages
	PyGoWaveWavelet * aWavelet = [m_allWavelets valueForKey:aId];
	NSAssert(aWavelet != nil, @"Wavelet not found");
	if ([aType isEqual:@"WAVELET_OPEN"]) {
		NSDictionary * propertyDict = aProperty;
		NSDictionary * blips = [propertyDict valueForKey:@"blips"];
		NSDictionary * waveletDict = [propertyDict valueForKey:@"wavelet"];
		NSString * aRootBlipId = [waveletDict valueForKey:@"rootBlipId"];
		[aWavelet loadBlipsFromSnapshot:blips rootBlipId:aRootBlipId];
		[m_openWavelets addObject:aWavelet.waveletId];
		[self postNotificationName:@"waveletOpened"
						  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									aWavelet.waveletId, @"waveletId",
									[NSNumber numberWithBool:aWavelet.isRoot], @"isRoot",
									nil]
						coalescing:NO];
	}
	else if ([aType isEqual:@"OPERATION_MESSAGE_BUNDLE"]) {
		NSDictionary * propertyDict = aProperty;
		[self queueMessageBundleForWavelet:aWavelet
									 isAck:NO
					   serialOpsOrNewblips:[propertyDict valueForKey:@"operations"]
								   version:[[propertyDict valueForKey:@"version"] intValue]
								  blipsums:[propertyDict valueForKey:@"blipsums"]
								 timestamp:parseJsonTimestamp([propertyDict valueForKey:@"timestamp"])
							 contributorId:[propertyDict valueForKey:@"contributor"]
		];
	}
	else if ([aType isEqual:@"OPERATION_MESSAGE_BUNDLE_ACK"]) {
		NSDictionary * propertyDict = aProperty;
		[self queueMessageBundleForWavelet:aWavelet
									 isAck:YES
					   serialOpsOrNewblips:[propertyDict valueForKey:@"newblips"]
								   version:[[propertyDict valueForKey:@"version"] intValue]
								  blipsums:[propertyDict valueForKey:@"blipsums"]
								 timestamp:parseJsonTimestamp([propertyDict valueForKey:@"timestamp"])
							 contributorId:[propertyDict valueForKey:@"contributor"]
		];
	}
}

- (void)retrieveParticipantWithId:(NSString*)aId
{
	[self sendJsonTo:@"manager" messageType:@"PARTICIPANT_INFO" property:[NSArray arrayWithObject:aId]];
}

- (void)mcached_afterOperationsInserted:(NSNotification*)notification
{
	PyGoWaveOpManager * mcached = [notification object];
	NSAssert(mcached != nil, @"");
	NSString * aWaveletId = mcached.waveletId;
	if (![self waveletHasPendingOperations:aWaveletId])
		[self transferOperationsForWaveletWithId:aWaveletId];
}

- (void)wavelet_participantsChanged:(NSNotification*)notification
{
	PyGoWaveWavelet * aWavelet = [notification object];
	NSAssert(aWavelet != nil, @"");
	if ([aWavelet participantById:m_viewerId] == nil) { // I got kicked
		PyGoWaveWaveModel * aWave = [aWavelet waveModel];
		NSString * aWaveletId = aWavelet.waveletId;
		if (aWavelet == aWave.rootWavelet) // It was the root wavelet, oh no!
			[self removeWaveWithId:aWave.waveId];
		else { // Some other wavelet I was on, phew...
			[aWave removeWaveletById:aWaveletId];
			[m_allWavelets removeObjectForKey:aWaveletId];
		}
		// Wavelet has been closed implicitly
		[m_openWavelets removeObject:aWaveletId];
	}
}

#pragma mark -
#pragma mark Public methods

- (PyGoWaveParticipant*)viewer
{
	return [self participantById:m_viewerId];
}

- (void)connectToHost:(NSString*)aHost
			 username:(NSString*)aUsername
			 password:(NSString*)aPassword
{
	[self connectToHost:aHost username:aUsername password:aPassword stompPort:61613 stompUsername:@"pygowave_client" stompPassword:@"pygowave_client"];
}
- (void)connectToHost:(NSString*)aHost
			 username:(NSString*)aUsername
			 password:(NSString*)aPassword
			stompPort:(NSInteger)aStompPort
		stompUsername:(NSString*)aStompUsername
		stompPassword:(NSString*)aStompPassword
{
	[m_stompServer release];
	m_stompServer = [aHost copy];
	m_stompPort = aStompPort;
	[m_stompUsername release];
	m_stompUsername = [aStompUsername copy];
	[m_stompPassword release];
	m_stompPassword = [aStompPassword copy];
	[self reconnectToHostWithUsername:aUsername password:aPassword];
}

- (void)reconnectToHostWithUsername:(NSString*)aUsername password:(NSString*)aPassword
{
	[m_username release];
	m_username = [aUsername copy];
	[m_password release];
	m_password = [aPassword copy];
	NSLog(@"Controller: Connecting to %@:%d...", m_stompServer, m_stompPort);
	if (m_conn != nil)
		[self disconnectFromHost];
	m_conn = [[CRVStompClient alloc] initWithHost:m_stompServer port:m_stompPort login:m_username passcode:m_password delegate:self autoconnect:YES];
}

- (void)disconnectFromHost
{
	if (m_conn == nil)
		return;
	if (m_connected) {
		for (NSString * aId in m_openWavelets)
			[self unsubscribeWaveletWithId:aId];
		[self sendJsonTo:@"manager" messageType:@"DISCONNECT"];
	}
	[m_conn disconnect];
}

- (PyGoWaveWaveModel*)waveWithId:(NSString*)aId
{
	return [m_allWaves valueForKey:aId];
}

- (PyGoWaveWavelet*)waveletWithId:(NSString*)aId
{
	return [m_allWavelets valueForKey:aId];
}

- (NSInteger)searchForParticipantWithQuery:(NSString*)aQuery
{
	[self sendJsonTo:@"manager" messageType:@"PARTICIPANT_SEARCH" property:aQuery];
	return ++m_lastSearchId;
}

- (NSArray*)gadgetList
{
	if ([m_cachedGadgetList count] == 0)
		[self refreshGadgetList];
	return m_cachedGadgetList;
}

- (void)textInserted:(NSString*)aText atIndex:(NSInteger)aIndex inBlipId:(NSString*)aBlipId ofWaveletId:(NSString*)aWaveletId
{
	PyGoWaveWavelet * w = [m_allWavelets valueForKey:aWaveletId]; NSAssert(w != nil, @"Wavelet not found");
	PyGoWaveBlip * b = [w blipById:aBlipId]; NSAssert(b != nil, @"Blip not found");
	[[m_mcached valueForKey:aWaveletId] documentInsert:aText atIndex:aIndex inBlipWithId:aBlipId];
	[b insertTextAtIndex:aIndex text:aText contributor:[self viewer]];
	b.lastModified = [NSDate date];
}

- (void)textDeletedFromStart:(NSInteger)aStart toEnd:(NSInteger)aEnd inBlipWithId:(NSString*)aBlipId ofWaveletWithId:(NSString*)aWaveletId
{
	PyGoWaveWavelet * w = [m_allWavelets valueForKey:aWaveletId]; NSAssert(w != nil, @"Wavelet not found");
	PyGoWaveBlip * b = [w blipById:aBlipId]; NSAssert(b != nil, @"Blip not found");
	[[m_mcached valueForKey:aWaveletId] documentDeleteFromStart:aStart toEnd:aEnd inBlipWithId:aBlipId];
	[b deleteTextAtIndex:aStart length:aEnd-aStart contributor:[self viewer]];
	b.lastModified = [NSDate date];
}

- (void)elementInsertAtIndex:(NSInteger)aIndex type:(NSInteger)aType properties:(NSDictionary*)sProperties inBlipWithId:(NSString*)aBlipId ofWaveletWithId:(NSString*)aWaveletId
{
	PyGoWaveWavelet * w = [m_allWavelets valueForKey:aWaveletId]; NSAssert(w != nil, @"Wavelet not found");
	PyGoWaveBlip * b = [w blipById:aBlipId]; NSAssert(b != nil, @"Blip not found");
	[[m_mcached valueForKey:aWaveletId] documentElementInsertAtIndex:aIndex type:aType properties:sProperties inBlipWithId:aBlipId];
	[b insertElementAtIndex:aIndex type:aType properties:sProperties contributor:[self viewer]];
	b.lastModified = [NSDate date];
}

- (void)elementDeleteAtIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId ofWaveletWithId:(NSString*)aWaveletId
{
	PyGoWaveWavelet * w = [m_allWavelets valueForKey:aWaveletId]; NSAssert(w != nil, @"Wavelet not found");
	PyGoWaveBlip * b = [w blipById:aBlipId]; NSAssert(b != nil, @"Blip not found");
	[[m_mcached valueForKey:aWaveletId] documentElementDeleteAtIndex:aIndex inBlipWithId:aBlipId];
	[b deleteElementAtIndex:aIndex contributor:[self viewer]];
	b.lastModified = [NSDate date];
}

- (void)elementDeltaSubmitted:(NSDictionary*)aDelta atIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId ofWaveletWithId:(NSString*)aWaveletId
{
	PyGoWaveWavelet * w = [m_allWavelets valueForKey:aWaveletId]; NSAssert(w != nil, @"Wavelet not found");
	PyGoWaveBlip * b = [w blipById:aBlipId]; NSAssert(b != nil, @"Blip not found");
	[[m_mcached valueForKey:aWaveletId] documentElementApplyDelta:aDelta atIndex:aIndex inBlipWithId:aBlipId];
	[b applyElementDelta:aDelta atIndex:aIndex contributor:[self viewer]];
	b.lastModified = [NSDate date];
}

- (void)elementSetUserPrefWithKey:(NSString*)aKey toValue:(NSString*)aValue atIndex:(NSInteger)aIndex inBlipWithId:(NSString*)aBlipId ofWaveletWithId:(NSString*)aWaveletId
{
	PyGoWaveWavelet * w = [m_allWavelets valueForKey:aWaveletId]; NSAssert(w != nil, @"Wavelet not found");
	PyGoWaveBlip * b = [w blipById:aBlipId]; NSAssert(b != nil, @"Blip not found");
	[[m_mcached valueForKey:aWaveletId] documentElementSetUserPrefWithKey:aKey toValue:aValue atIndex:aIndex inBlipWithId:aBlipId];
	[b setElementUserPrefWithKey:aKey toValue:aValue atIndex:aIndex contributor:[self viewer]];
	b.lastModified = [NSDate date];
}

- (void)appendBlipToWaveletWithId:(NSString*)aWaveletId
{
	PyGoWaveWavelet * w = [m_allWavelets valueForKey:aWaveletId]; NSAssert(w != nil, @"Wavelet not found");
	PyGoWaveBlip * newBlip = [w appendBlipWithCreator:[self viewer]];
	[[m_mcached valueForKey:aWaveletId] waveletAppendBlipWithTempId:newBlip.blipId];
	[[m_mcached valueForKey:aWaveletId] lockBlipOpsWithId:newBlip.blipId];
}

- (void)deleteBlipWithId:(NSString*)aId ofWaveletWithId:(NSString*)aWaveletId
{
	PyGoWaveWavelet * w = [m_allWavelets valueForKey:aWaveletId]; NSAssert(w != nil, @"Wavelet not found");
	[[m_mcached valueForKey:aWaveletId] blipDeleteWithId:aId];
	[[m_draftblips valueForKey:aWaveletId] removeObject:aId];
	[w deleteBlipWithId:aId];
}

- (void)draftBlipWithId:(NSString*)aId ofWaveletWithId:(NSString*)aWaveletId enabled:(BOOL)bEnabled
{
	PyGoWaveWavelet * w = [m_allWavelets valueForKey:aWaveletId]; NSAssert(w != nil, @"Wavelet not found");
	NSMutableArray * draftblips = [m_draftblips valueForKey:aWaveletId];
	if (!bEnabled && [draftblips containsObject:aId]) {
		[draftblips removeObject:aId];
		if (![aId hasPrefix:@"TBD_"]) {
			PyGoWaveOpManager * mcached = [m_mcached valueForKey:aWaveletId];
			[mcached unlockBlipOpsWithId:aId];
			if (mcached.canFetch && ![self waveletHasPendingOperations:aWaveletId])
				[self transferOperationsForWaveletWithId:aWaveletId];
		}
	}
	else if (bEnabled && ![draftblips containsObject:aId]) {
		[draftblips addObject:aId];
		if (![aId hasPrefix:@"TBD_"]) {
			PyGoWaveOpManager * mcached = [m_mcached valueForKey:aWaveletId];
			[mcached lockBlipOpsWithId:aId];
		}
	}
}

- (void)openWaveletWithId:(NSString*)aId
{
	[self subscribeWaveletWithId:aId open:YES];
}

- (void)closeWaveletWithId:(NSString*)aId
{
	[self unsubscribeWaveletWithId:aId];
}

- (void)addParticipantWithId:(NSString*)aId toWaveletWithId:(NSString*)aWaveletId
{
	PyGoWaveWavelet * aWavelet = [m_allWavelets valueForKey:aWaveletId];
	if (aWavelet == nil)
		return;
	[[m_mcached valueForKey:aWaveletId] waveletAddParticipantWithId:aId];
	[aWavelet addParticipant:[self participantById:aId]];
}

- (void)createNewWaveWithTitle:(NSString*)aTitle
{
	[self createNewWaveletWithTitle:aTitle inWaveWithId:@""];
}

- (void)createNewWaveletWithTitle:(NSString*)aTitle inWaveWithId:(NSString*)aWaveId
{
	[self sendJsonTo:@"manager" messageType:@"WAVELET_CREATE" property:[NSDictionary dictionaryWithObjectsAndKeys:aWaveId, @"waveId", aTitle, @"title", nil]];
}

- (void)leaveWaveletWithId:(NSString*)aId
{
	PyGoWaveWavelet * aWavelet = [m_allWavelets valueForKey:aId];
	if (aWavelet == nil)
		return;
	[[m_mcached valueForKey:aId] waveletRemoveParticipantWithId:m_viewerId];
	[aWavelet removeParticipantById:m_viewerId];
}

- (void)refreshGadgetList
{
	[self refreshGadgetListForced:NO];
}

- (void)refreshGadgetListForced:(BOOL)bForced
{
	if ([m_cachedGadgetList count] == 0 || bForced)
		[self sendJsonTo:@"manager" messageType:@"GADGET_LIST"];
	else
		[self postNotificationName:@"updateGadgetList" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:m_cachedGadgetList, @"gadgetList", nil]];
}

#pragma mark CRVStompClientDelegate
- (void)stompClient:(CRVStompClient *)stompService messageReceived:(NSString *)body withHeader:(NSDictionary *)messageHeader
{
	if (m_state == PyGoWaveController_ClientConnected) {
		NSArray * msgs = [body JSONValue];
		NSAssert(msgs != nil, @"Error in parsing received JSON data!");
		NSAssert([msgs count] == 1, @"Login reply must contain a single message!");
		
		NSDictionary * msg = [msgs objectAtIndex:0];
		NSString * type = [msg valueForKey:@"type"];
		NSDictionary * prop = [msg valueForKey:@"property"];
		NSAssert(type != nil && prop != nil, @"Message lacks 'type' and 'property' field!");
		
		if ([type isEqual:@"ERROR"]) {
			[self postErrorOccurredNotification:[prop valueForKey:@"tag"] description:[prop valueForKey:@"desc"] waveletId:@"login"];
			return;
		}
		NSAssert([type isEqual:@"LOGIN"], @"Login reply must be a 'LOGIN' message!");
		
		NSString * rxKey = [prop valueForKey:@"rx_key"];
		NSString * txKey = [prop valueForKey:@"tx_key"];
		NSString * viewerId = [prop valueForKey:@"viewer_id"];
		NSAssert(rxKey != nil && txKey != nil && viewerId != nil, @"Login reply must contain the properties 'rx_key', 'tx_key' and 'viewer_id'!");
		
		[self unsubscribeWaveletWithId:@"login" close:NO];
		[m_waveAccessKeyRx release];
		m_waveAccessKeyRx = [rxKey copy];
		[m_waveAccessKeyTx release];
		m_waveAccessKeyTx = [txKey copy];
		[m_viewerId release];
		m_viewerId = [viewerId copy];
		[self subscribeWaveletWithId:@"manager" open:NO];
		[self resetPingTimer];
		m_state = PyGoWaveController_ClientOnline;
		NSLog(@"Controller: Online! Keys: %@/rx %@/tx", m_waveAccessKeyRx, m_waveAccessKeyTx);
		[self postNotificationName:@"stateChanged" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:m_state], @"state", nil]];
		
		[self sendJsonTo:@"manager" messageType:@"WAVE_LIST"];
	}
	else if (m_state == PyGoWaveController_ClientOnline) {
		NSArray * routing_key = [[messageHeader valueForKey:@"destination"] componentsSeparatedByString:@"."];
		
		if ([routing_key count] != 3 || ![[routing_key objectAtIndex:2] isEqual:@"waveop"]) {
			NSLog(@"Controller: Malformed routing key '%@'!", [messageHeader valueForKey:@"destination"]); return;
		}
		NSString * aWaveletId = [routing_key objectAtIndex:1];
		NSArray * msgs = [body JSONValue];
		if (msgs == nil) {
			NSLog(@"Controller: Error in parsing received JSON data!"); return;
		}
		for (NSDictionary * msg in msgs) {
			NSString * msgType = [msg valueForKey:@"type"];
			if (msgType != nil) {
				NSString * msgProperty = [msg valueForKey:@"property"];
				[self processMessageWithWaveletId:aWaveletId type:msgType property:msgProperty];
			}
			else {
				NSLog(@"Controller: Message lacks 'type' field!"); return;
			}
		}
	}
}

- (void)stompClientDidDisconnect:(CRVStompClient *)stompService
{
	NSLog(@"Controller: Disconnected...");
	if (m_pingTimer != nil) {
		[m_pingTimer invalidate];
		[m_pingTimer release];
		m_pingTimer = nil;
	}
	[self killPendingTimer];
	m_state = PyGoWaveController_ClientDisconnected;
	[self clearWaves];
	[self postNotificationName:@"stateChanged" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:m_state], @"state", nil]];
	[m_conn autorelease];
	m_conn = nil;
	m_connected = NO;
}

- (void)stompClientDidConnect:(CRVStompClient *)stompService
{
	m_connected = YES;
	NSLog(@"Controller: Authenticating...");
	m_state = PyGoWaveController_ClientConnected;
	[self postNotificationName:@"stateChanged" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:m_state], @"state", nil]];
	
	[m_waveAccessKeyRx release];
	[m_waveAccessKeyTx release];
	
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	NSAssert(uuid != NULL, @"Could not generate an UUID");
	CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
	NSAssert(uuidStr != NULL, @"Could not create a string of an UUID");
	CFRelease(uuid);
	
	m_waveAccessKeyRx = [[(NSString*)uuidStr lowercaseString] retain];
	CFRelease(uuidStr);
	m_waveAccessKeyTx = [m_waveAccessKeyRx copy];
	
	[self subscribeWaveletWithId:@"login" open:NO];
	
	[self sendJsonTo:@"login" messageType:@"LOGIN" property:[NSDictionary dictionaryWithObjectsAndKeys:m_username, @"username", m_password, @"password", nil]];
	[m_password release]; // Delete Password after use
	m_password = nil;
}

- (void)serverDidSendReceipt:(CRVStompClient *)stompService withReceiptId:(NSString *)receiptId
{
	//Nothing to do yet
}

- (void)serverDidSendError:(CRVStompClient *)stompService withErrorMessage:(NSString *)aDescription detailedErrorMessage:(NSString *)theMessage
{
	NSString * desc = [NSString stringWithFormat:@"%@\n%@", aDescription, theMessage];
	[self postErrorOccurredNotification:@"STOMP_ERROR" description:desc waveletId:@"manager"];
}

#pragma mark -
#pragma mark PyGoWaveParticipantProvider

- (PyGoWaveParticipant *)participantById:(NSString *)aParticipntId
{
	PyGoWaveParticipant * p = [m_allParticipants valueForKey:aParticipntId];
	if (p == nil) {
		p = [[PyGoWaveParticipant alloc] initWithParticipantId:aParticipntId];
		[m_allParticipants setValue:p forKey:aParticipntId];
		[p release];
		if (m_participantsTodoCollect)
			[m_participantsTodo addObject:aParticipntId];
		else
			[self retrieveParticipantWithId:aParticipntId];
	}
	return p;
}

#pragma mark -
#pragma mark Observer add/remove methods

- (void)addStateChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"stateChanged"];
}
- (void)removeStateChangedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"stateChanged"];
}

- (void)addErrorOccurredObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"errorOccurred"];
}
- (void)removeErrorOccurredObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"errorOccurred"];
}

- (void)addWaveletOpenedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"waveletOpened"];
}
- (void)removeWaveletOpenedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"waveletOpened"];
}

- (void)addParticipantSearchResultsObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"participantSearchResults"];
}
- (void)removeParticipantSearchResultsObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"participantSearchResults"];
}

- (void)addParticipantSearchResultsInvalidObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"participantSearchResultsInvalid"];
}
- (void)removeParticipantSearchResultsInvalidObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"participantSearchResultsInvalid"];
}

- (void)addWaveAddedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"waveAdded"];
}
- (void)removeWaveAddedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"waveAdded"];
}

- (void)addWaveAboutToBeRemovedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"waveAboutToBeRemoved"];
}
- (void)removeWaveAboutToBeRemovedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"waveAboutToBeRemoved"];
}

- (void)addUpdateGadgetListObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"updateGadgetList"];
}
- (void)removeUpdateGadgetListObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"updateGadgetList"];
}

@end
