
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
#import "PyGoWaveOperations.h"
#import <CommonCrypto/CommonDigest.h>

@implementation PyGoWaveParticipant

@synthesize participantId = m_participantId, displayName = m_displayName, thumbnailUrl = m_thumbnailUrl;
@synthesize profileUrl = m_profileUrl, online = m_online, bot = m_bot;

#pragma mark Initialization and Deallocation

- (id)initWithParticipantId:(NSString *)participantId
{
	if (self = [super init]) {
		m_participantId = [participantId copy];
		m_displayName = [NSString new];
		m_profileUrl = [NSString new];
		m_thumbnailUrl = [NSString new];
	}
	return self;
}

- (void)dealloc
{
	[m_participantId release];
	[m_displayName release];
	[m_profileUrl release];
	[m_thumbnailUrl release];
	[super dealloc];
}

#pragma mark Overwritten setters

- (void)setDisplayName:(NSString *)value
{
	if (![m_displayName isEqual:value]) {
		[m_displayName release];
		m_displayName = [value copy];
		[self postNotificationName:@"dataChanged"];
	}
}

- (void)setThumbnailUrl:(NSString *)value
{
	if (![m_thumbnailUrl isEqual:value]) {
		[m_thumbnailUrl release];
		m_thumbnailUrl = [value copy];
		[self postNotificationName:@"dataChanged"];
	}
}

- (void)setProfileUrl:(NSString *)value
{
	if (![m_profileUrl isEqual:value]) {
		[m_profileUrl release];
		m_profileUrl = [value copy];
		[self postNotificationName:@"dataChanged"];
	}
}

- (void)setBot:(BOOL)value
{
	if (m_bot != value) {
		m_bot = value;
		[self postNotificationName:@"dataChanged"];
	}
}

- (void)setOnline:(BOOL)value
{
	if (m_online != value) {
		m_online = value;
		[self postNotificationName:@"onlineStateChanged"];
	}
}

#pragma mark Public methods

- (void)updateDataWithDict:(NSDictionary *)obj byServer:(NSString*)server
{
	self.displayName = [obj valueForKey:@"displayName"];
	NSString * value = [obj valueForKey:@"thumbnailUrl"];
	if ([value hasPrefix:@"/"])
		value = [NSString stringWithFormat: @"http://%@%@", server, value];
	self.thumbnailUrl = value;
	self.profileUrl = [obj valueForKey:@"profileUrl"];
	self.bot = [[obj valueForKey:@"isBot"] boolValue];
}

- (NSDictionary *)toGadgetFormat
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			self.participantId, @"id",
			self.displayName, @"displayName",
			self.thumbnailUrl, @"thumbnailUrl",
			nil];
}

#pragma mark Observer add/remove methods

- (void)addDataChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"dataChanged"];
}
- (void)removeDataChangedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"dataChanged"];
}

- (void)addOnlineStateChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"onlineStateChanged"];
}
- (void)removeOnlineStateChangedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"onlineStateChanged"];
}

@end

#pragma mark -

@implementation PyGoWaveAnnotation

@synthesize blip = m_blip, name = m_name, start = m_start, end = m_end, value = m_value;

#pragma mark Initialization and Deallocation

- (id)initWithBlip:(PyGoWaveBlip*)aBlip name:(NSString*)aName start:(NSInteger)aStart end:(NSInteger)aEnd value:(NSString*)aValue
{
	if (self = [super init]) {
		m_blip = aBlip; // Not retaining parent object
		m_name = [aName copy];
		m_start = aStart;
		m_end = aEnd;
		m_value = [aValue copy];
	}
	return self;
}

- (void)dealloc
{
	[m_name release];
	[m_value release];
	[super dealloc];
}

@end

#pragma mark -

@implementation PyGoWaveElement

@synthesize blip = m_blip, elementId = m_id, elementType = m_type, position = m_pos;

// Hidden class method
+ (NSInteger)newTempId
{
	static NSInteger lastTempId = 0;
	lastTempId--;
	return lastTempId;
}

#pragma mark Initialization and Deallocation

- (id)initWithBlip:(PyGoWaveBlip*)aBlip elementId:(NSInteger)aId position:(NSInteger)aPosition elementType:(PyGoWaveElementType)aType properties:(NSDictionary*)someProperties
{
	if (self = [super init]) {
		m_blip = aBlip; // Not retaining parent object
		if (aId < 0)
			m_id = [PyGoWaveElement newTempId];
		else
			m_id = aId;
		m_pos = aPosition;
		m_type = aType;
		m_properties = [someProperties mutableCopy];
	}
	return self;
}

- (void)dealloc
{
	[m_properties release];
	[super dealloc];
}

@end

#pragma mark -

@implementation PyGoWaveGadgetElement

#pragma mark Initialization and Deallocation

- (id)initWithBlip:(PyGoWaveBlip*)aBlip elementId:(NSInteger)aId position:(NSInteger)aPosition properties:(NSDictionary*)someProperties
{
	return [super initWithBlip:aBlip elementId:aId position:aPosition elementType:PyGoWaveElementType_GADGET properties:someProperties];
}

#pragma mark Public methods

- (NSDictionary *)fields
{
	NSDictionary * theFields = [m_properties valueForKey:@"fields"];
	if (theFields != nil)
		return [NSDictionary dictionaryWithDictionary:theFields];
	else
		return [[NSDictionary new] autorelease];
}

- (NSDictionary *)userPrefs
{
	NSDictionary * theUserPrefs = [m_properties valueForKey:@"userprefs"];
	if (theUserPrefs != nil)
		return [NSDictionary dictionaryWithDictionary:theUserPrefs];
	else
		return [[NSDictionary new] autorelease];
}

- (NSString*)url
{
	NSString * theUrl = [m_properties valueForKey:@"url"];
	if (theUrl != nil)
		return [theUrl copy];
	else
		return [[NSString new] autorelease];
}

- (void)applyDelta:(NSDictionary*)delta
{
	NSMutableDictionary * fields = [m_properties valueForKey:@"fields"];
	if (fields == nil)
		fields = [NSMutableDictionary new];
	else
		[fields retain];
	for (NSString * key in delta) {
		if (key == nil)
			[fields removeObjectForKey:key];
		else {
			id value = [[[delta valueForKey:key] copy] autorelease];
			[fields setValue:value forKey:key];
		}
	}
	[m_properties setValue:fields forKey:@"fields"];
	[fields release];
	[self postNotificationName:@"stateChange"];
}

- (void)setUserPrefWithKey:(NSString*)key toValue:(NSString*)value
{
	NSMutableDictionary * userPrefs = [m_properties valueForKey:@"userprefs"];
	if (userPrefs == nil)
		userPrefs = [NSMutableDictionary new];
	else
		[userPrefs retain];
	[userPrefs setValue:[NSString stringWithString:value] forKey:key];
	[m_properties setValue:userPrefs forKey:@"userprefs"];
	[userPrefs release];
	[self postNotificationName:@"userPrefSet"
					  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
								key, @"key",
								value, @"value",
								nil]
					coalescing:NO];
}

#pragma mark Observer add/remove methods

- (void)addStateChangeObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"stateChange"];
}
- (void)removeStateChangeObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"stateChange"];
}

- (void)addUserPrefSetObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"userPrefSet"];
}
- (void)removeUserPrefSetObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"userPrefSet"];
}

@end

#pragma mark -

@implementation PyGoWaveWaveModel

@synthesize waveId = m_waveId, viewerId = m_viewerId, rootWavelet = m_rootWavelet, participantProvider = m_pp;

#pragma mark Initialization and Deallocation

- (id)initWithWaveId:(NSString*)aWaveId viewerId:(NSString*)aViewerId participantProvider:(NSObject <PyGoWaveParticipantProvider>*)pp
{
	if (self = [super init]) {
		m_waveId = [aWaveId copy];
		m_viewerId = [aViewerId copy];
		m_wavelets = [NSMutableDictionary new];
		m_pp = [pp retain];
	}
	return self;
}

- (void)dealloc
{
	[m_waveId release];
	[m_viewerId release];
	[m_wavelets release];
	[m_pp release];
	[super dealloc];
}

#pragma mark Public methods

- (void)loadFromSnapshot:(NSDictionary*)obj
{
	NSDictionary * rootWavelet = [obj valueForKey:@"wavelet"];
	NSString * waveletId = [rootWavelet valueForKey:@"waveletId"];
	
	PyGoWaveWavelet * rootWaveletObj = [self createWaveletWithId:waveletId
														 creator:[m_pp participantById:[rootWavelet valueForKey:@"creator"]]
														   title:[rootWavelet valueForKey:@"title"]
														  isRoot:YES
														 created:parseJsonTimestamp([rootWavelet valueForKey:@"creationTime"])
													lastModified:parseJsonTimestamp([rootWavelet valueForKey:@"lastModifiedTime"])
														 version:[[rootWavelet valueForKey:@"version"] intValue]];
	
	for (NSString * partId in [rootWavelet valueForKey:@"participants"])
		[rootWaveletObj addParticipant:[m_pp participantById:partId]];
	
	[rootWaveletObj loadBlipsFromSnapshot:[obj valueForKey:@"blips"] rootBlipId:[rootWavelet valueForKey:@"rootBlipId"]];
}

- (PyGoWaveWavelet*)createWaveletWithId:(NSString*)aId
{
	return [self createWaveletWithId:aId creator:nil title:@"" isRoot:NO created:nil lastModified:nil version:0];
}
- (PyGoWaveWavelet*)createWaveletWithId:(NSString*)aId
								creator:(PyGoWaveParticipant*)aCreator
{
	return [self createWaveletWithId:aId creator:aCreator title:@"" isRoot:NO created:nil lastModified:nil version:0];
}
- (PyGoWaveWavelet*)createWaveletWithId:(NSString*)aId
								creator:(PyGoWaveParticipant*)aCreator
								  title:(NSString*)aTitle
{
	return [self createWaveletWithId:aId creator:aCreator title:aTitle isRoot:NO created:nil lastModified:nil version:0];
}
- (PyGoWaveWavelet*)createWaveletWithId:(NSString*)aId
								creator:(PyGoWaveParticipant*)aCreator
								  title:(NSString*)aTitle
								 isRoot:(BOOL)bRoot
								created:(NSDate*)bCreated
						   lastModified:(NSDate*)bLastModified
								version:(NSInteger)aVersion
{
	PyGoWaveWavelet * wavelet = [[PyGoWaveWavelet alloc] initWithWave:self waveletId:aId creator:aCreator title:aTitle isRoot:bRoot created:bCreated lastModified:bLastModified version:aVersion];
	[m_wavelets setValue:wavelet forKey:aId];
	NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithString:aId], @"waveletId",
		[NSNumber numberWithBool:bRoot], @"isRoot", nil
	];
	[self postNotificationName:@"waveletAdded"
					  userInfo:info
					coalescing:NO];
	return [wavelet autorelease];
}

- (PyGoWaveWavelet*)waveletById:(NSString*)aId
{
	return [m_wavelets valueForKey:aId];
}

- (NSArray*)allWavelets
{
	return [m_wavelets allValues];
}

- (void)removeWaveletById:(NSString*)aId
{
	PyGoWaveWavelet * wavelet = [[m_wavelets valueForKey:aId] retain];
	if (wavelet == nil)
		return;
	[self postNotificationName:@"waveletAboutToBeRemoved"
					  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithString:aId], @"waveletId", nil]
					coalescing:NO];
	[m_wavelets removeObjectForKey:aId];
	if (wavelet == m_rootWavelet)
		m_rootWavelet = nil;
	[wavelet autorelease];
}

#pragma mark Observer add/remove methods

- (void)addWaveletAddedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"waveletAdded"];
}
- (void)removeWaveletAddedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"waveletAdded"];
}

- (void)addWaveletAboutToBeRemovedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"waveletAboutToBeRemoved"];
}
- (void)removeWaveletAboutToBeRemovedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"waveletAboutToBeRemoved"];
}

@end

#pragma mark -

@implementation PyGoWaveWavelet

@synthesize version = m_version, isRoot = m_root, waveletId = m_id, title = m_title, status = m_status, created = m_created, lastModified = m_lastModified;

#pragma mark Initialization and Deallocation

- (id)initWithWave:(PyGoWaveWaveModel*)aWave
		 waveletId:(NSString*)aWaveletId
{
	return [self initWithWave:aWave waveletId:aWaveletId creator:nil title:@"" isRoot:NO created:nil lastModified:nil version:0];
}
- (id)initWithWave:(PyGoWaveWaveModel*)aWave
		 waveletId:(NSString*)aWaveletId
		   creator:(PyGoWaveParticipant*)aCreator
{
	return [self initWithWave:aWave waveletId:aWaveletId creator:aCreator title:@"" isRoot:NO created:nil lastModified:nil version:0];
}
- (id)initWithWave:(PyGoWaveWaveModel*)aWave
		 waveletId:(NSString*)aWaveletId
		   creator:(PyGoWaveParticipant*)aCreator
			 title:(NSString*)aTitle
{
	return [self initWithWave:aWave waveletId:aWaveletId creator:aCreator title:aTitle isRoot:NO created:nil lastModified:nil version:0];
}
- (id)initWithWave:(PyGoWaveWaveModel*)aWave
		 waveletId:(NSString*)aWaveletId
		   creator:(PyGoWaveParticipant*)aCreator
			 title:(NSString*)aTitle
			isRoot:(BOOL)bRoot
		   created:(NSDate*)bCreated
	  lastModified:(NSDate*)bLastModified
		   version:(NSInteger)aVersion
{
	if (self = [super init]) {
		m_wave = aWave; // Not retaining parent object
		
		m_id = [aWaveletId copy];
		m_creator = [aCreator retain];
		m_title = [aTitle copy];
		m_root = bRoot;
		if (bCreated == nil)
			m_created = [[NSDate date] retain];
		else
			m_created = [bCreated copy];
		if (bLastModified == nil)
			m_lastModified = [[NSDate date] retain];
		else
			m_lastModified = [bLastModified copy];
		m_version = aVersion;
		
		m_participants = [NSMutableDictionary new];
		m_blips = [NSMutableArray new];
		m_status = [@"clean" copy];
		
		if (bRoot) {
			if ([aWave rootWavelet] == nil)
				[aWave setRootWavelet:self];
			else
				m_root = NO;
		}
	}
	return self;
}
- (void)dealloc
{
	[m_id release];
	[m_creator release];
	[m_title release];
	[m_created release];
	[m_lastModified release];
	
	[m_participants release];
	[m_blips release];
	[m_status release];
	
	[super dealloc];
}

- (NSString*)waveId
{
	return m_wave.waveId;
}

#pragma mark Overwritten getters/setters

- (void)setTitle:(NSString*)value
{
	if (![m_title isEqual:value]) {
		[m_title release];
		m_title = [value copy];
		[self postNotificationName:@"titleChanged" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithString:value], @"title", nil]];
	}
}

- (NSInteger)participantCount
{
	return [m_participants count];
}

- (void)setStatus:(NSString*)value
{
	if (![m_status isEqual:value]) {
		[m_status release];
		m_status = [value copy];
		[self postNotificationName:@"statusChange" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithString:value], @"status", nil]];
	}
}

- (NSDictionary*)allParticipantsForGadget
{
	NSMutableDictionary * dict = [NSMutableDictionary new];
	for (NSString * pId in m_participants)
		[dict setValue:[[m_participants valueForKey:pId] toGadgetFormat] forKey:pId];
	NSDictionary * ret = [NSDictionary dictionaryWithDictionary:dict];
	[dict release];
	return ret;
}

- (void)setLastModified:(NSDate*)value
{
	if (![m_lastModified isEqual:value]) {
		[m_lastModified release];
		m_lastModified = [value copy];
		[self postNotificationName:@"lastModifiedChanged" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[[value copy] autorelease], @"lastModified", nil]];
	}
}

#pragma mark Public methods

- (NSArray*)allParticipantIDs
{
	return [m_participants allKeys];
}

- (NSArray*)allBlipIDs
{
	NSMutableArray * array = [NSMutableArray new];
	for (PyGoWaveBlip * blip in m_blips)
		[array addObject:blip.blipId];
	NSArray * ret = [NSArray arrayWithArray:array];
	[array release];
	return ret;
}

- (PyGoWaveParticipant*)creator
{
	return m_creator;
}

- (PyGoWaveWaveModel*)waveModel
{
	return m_wave;
}

- (void)addParticipant:(PyGoWaveParticipant*)aParticipant
{
	if ([m_participants valueForKey:aParticipant.participantId] == nil) {
		[m_participants setValue:aParticipant forKey:aParticipant.participantId];
		[self postNotificationName:@"participantsChanged"];
	}
}

- (void)removeParticipantById:(NSString*)aId
{
	if ([m_participants valueForKey:aId] != nil) {
		[m_participants removeObjectForKey:aId];
		[self postNotificationName:@"participantsChanged"];
	}
}

- (PyGoWaveParticipant*)participantById:(NSString*)aId;
{
	return [m_participants valueForKey:aId];
}

- (NSArray*)allParticipants
{
	return [m_participants allValues];
}

- (PyGoWaveBlip*)appendBlipWithCreator:(PyGoWaveParticipant*)aCreator
{
	return [self insertBlipAtIndex:[m_blips count] blipId:@"" content:@"" elements:nil creator:aCreator contributors:nil isRoot:NO lastModified:nil version:0 submitted:NO];
}
- (PyGoWaveBlip*)appendBlipWithId:(NSString*)aId
{
	return [self insertBlipAtIndex:[m_blips count] blipId:aId content:@"" elements:nil creator:nil contributors:nil isRoot:NO lastModified:nil version:0 submitted:NO];
}
- (PyGoWaveBlip*)appendBlipWithId:(NSString*)aId
						  content:(NSString*)sContent
						 elements:(NSArray*)sElements
						  creator:(PyGoWaveParticipant*)aCreator
					 contributors:(NSArray*)sContributors
						   isRoot:(BOOL)bRoot
					 lastModified:(NSDate*)bLastModified
						  version:(NSInteger)aVersion
						submitted:(BOOL)bSubmitted
{
	return [self insertBlipAtIndex:[m_blips count] blipId:aId content:sContent elements:sElements creator:aCreator contributors:sContributors isRoot:bRoot lastModified:bLastModified version:aVersion submitted:bSubmitted];
}

- (PyGoWaveBlip*)insertBlipAtIndex:(NSInteger)index
							blipId:(NSString*)aId
{
	return [self insertBlipAtIndex:index blipId:aId content:@"" elements:nil creator:nil contributors:nil isRoot:NO lastModified:nil version:0 submitted:NO];
}
- (PyGoWaveBlip*)insertBlipAtIndex:(NSInteger)index
							blipId:(NSString*)aId
						   content:(NSString*)sContent
						  elements:(NSArray*)sElements
						   creator:(PyGoWaveParticipant*)aCreator
					  contributors:(NSArray*)sContributors
							isRoot:(BOOL)bRoot
					  lastModified:(NSDate*)bLastModified
						   version:(NSInteger)aVersion
						 submitted:(BOOL)bSubmitted
{
	PyGoWaveBlip * blip = [[PyGoWaveBlip alloc] initWithWavelet:self blipId:aId content:sContent elements:sElements parent:nil creator:aCreator contributors:sContributors isRoot:bRoot lastModified:bLastModified version:aVersion submitted:bSubmitted];
	[m_blips insertObject:blip atIndex:index];
	[self postNotificationName:@"blipInserted"
					  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithInt:index], @"index",
								[NSString stringWithString:aId], @"blipId",
								nil]
					coalescing:NO];
	return [blip autorelease];
}

- (void)deleteBlipWithId:(NSString*)aId
{
	int blipCount = [m_blips count];
	for (int i = 0; i < blipCount; i++) {
		PyGoWaveBlip * blip = [m_blips objectAtIndex:i];
		if ([blip.blipId isEqual:aId]) {
			[[blip retain] autorelease];
			[m_blips removeObjectAtIndex:i];
			[self postNotificationName:@"blipDeleted"
							  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithString:aId], @"blipId", nil]
							coalescing:NO];
			break;
		}
	}
}

- (PyGoWaveBlip*)blipByIndex:(NSInteger)aIndex
{
	if (aIndex < 0 || aIndex >= [m_blips count])
		return nil;
	return [m_blips objectAtIndex:aIndex];
}

- (PyGoWaveBlip*)blipById:(NSString*)aId
{
	for (PyGoWaveBlip * blip in m_blips) {
		if ([blip.blipId isEqual:aId])
			return blip;
	}
	return nil;
}

- (NSArray*)allBlips
{
	return [NSArray arrayWithArray:m_blips];
}

- (void)checkSync:(NSDictionary*)blipsums
{
	BOOL valid = YES;
	
	for (NSString * blipId in blipsums) {
		PyGoWaveBlip * blip = [self blipById:blipId];
		if (blip != nil && ![blip checkSyncWithSum:[blipsums valueForKey:blipId]])
			valid = NO;
	}
	
	if (valid)
		self.status = @"clean";
	else
		self.status = @"invalid";
}

- (void)applyOperations:(NSArray*)sOperations timestamp:(NSDate*)aTimestamp contributorId:(NSString*)aContributorId
{
	NSObject <PyGoWaveParticipantProvider> * pp = [m_wave participantProvider];
	PyGoWaveParticipant * c = [pp participantById:aContributorId];
	
	for (PyGoWaveOperation * op in sOperations) {
		if (![op.blipId isEqual:@""]) {
			PyGoWaveBlip * blip = [self blipById:op.blipId];
			if (blip == nil)
				continue;
			switch(op.type) {
				case PyGoWaveOperation_DOCUMENT_NOOP:
					break;
				case PyGoWaveOperation_DOCUMENT_DELETE:
					[blip deleteTextAtIndex:op.index length:[op.property intValue] contributor:c];
					break;
				case PyGoWaveOperation_DOCUMENT_INSERT:
					[blip insertTextAtIndex:op.index text:op.property contributor:c];
					break;
				case PyGoWaveOperation_DOCUMENT_ELEMENT_DELETE:
					[blip deleteElementAtIndex:op.index contributor:c];
					break;
				case PyGoWaveOperation_DOCUMENT_ELEMENT_INSERT:
					[blip insertElementAtIndex:op.index type:[[op.property valueForKey:@"type"] intValue] properties:[op.property valueForKey:@"properties"] contributor:c];
					break;
				case PyGoWaveOperation_DOCUMENT_ELEMENT_DELTA:
					[blip applyElementDelta:op.property atIndex:op.index contributor:c];
					break;
				case PyGoWaveOperation_DOCUMENT_ELEMENT_SETPREF:
					[blip setElementUserPrefWithKey:[op.property valueForKey:@"key"] toValue:[op.property valueForKey:@"value"] atIndex:op.index contributor:c];
					break;
				case PyGoWaveOperation_BLIP_DELETE:
					[self deleteBlipWithId:op.blipId];
					break;
				default:
					break;
			}
			[blip setLastModified:aTimestamp];
		}
		else {
			switch (op.type) {
				case PyGoWaveOperation_WAVELET_ADD_PARTICIPANT:
					[self addParticipant:[pp participantById:op.property]];
					break;
				case PyGoWaveOperation_WAVELET_REMOVE_PARTICIPANT:
					[self removeParticipantById:op.property];
					break;
				case PyGoWaveOperation_WAVELET_APPEND_BLIP:
					[self appendBlipWithId:[op.property valueForKey:@"blipId"] content:@"" elements:nil creator:c contributors:nil isRoot:NO lastModified:aTimestamp version:0 submitted:NO];
					break;
				default:
					break;
			}
		}
	}
}

- (void)updateBlipId:(NSString*)tempId toBlipId:(NSString*)blipId
{
	PyGoWaveBlip * blip = [self blipById:tempId];
	if (blip != nil)
		blip.blipId = blipId;
}

- (void)loadBlipsFromSnapshot:(NSDictionary*)blips rootBlipId:(NSString*)aRootBlipId
{
	NSObject <PyGoWaveParticipantProvider> * pp = [m_wave participantProvider];
	
	// Remove existing
	while ([m_blips count] > 0) {
		PyGoWaveBlip * blip = [m_blips lastObject];
		[self deleteBlipWithId:blip.blipId];
	}
	
	// Ordering
	NSMutableDictionary * created = [NSMutableDictionary new];
	for (NSString * blipId in blips) {
		NSDictionary * blip = [blips valueForKey:blipId];
		[created setValue:blipId forKey:[blip valueForKey:@"creationTime"]];
	}
	NSArray * sortedKeys = [[created allKeys] sortedArrayUsingFunction:sortJsonTimestamp context:NULL];
	NSMutableArray * sortedIds = [NSMutableArray new];
	for (NSNumber * key in sortedKeys)
		[sortedIds addObject:[created objectForKey:key]];
	[created release];
	
	for (NSString * blipId in sortedIds) {
		NSDictionary * blip = [blips valueForKey:blipId];
		NSMutableArray * contributors = [NSMutableArray new];
		for (NSString * cId in [blip valueForKey:@"contributors"])
			[contributors addObject:[pp participantById:cId]];
		
		NSMutableArray * blipElements = [NSMutableArray new];
		for (NSDictionary * element in [blip valueForKey:@"elements"]) {
			PyGoWaveElement * elementObj;
			if ([[element valueForKey:@"type"] intValue] == PyGoWaveElementType_GADGET)
				elementObj = [[PyGoWaveGadgetElement alloc] initWithBlip:nil
															   elementId:[[element valueForKey:@"id"] intValue]
																position:[[element valueForKey:@"index"] intValue]
															  properties:[element valueForKey:@"properties"]];
			else
				elementObj = [[PyGoWaveElement alloc] initWithBlip:nil
														 elementId:[[element valueForKey:@"id"] intValue]
														  position:[[element valueForKey:@"index"] intValue]
													   elementType:[[element valueForKey:@"type"] intValue]
														properties:[element valueForKey:@"properties"]];
			[blipElements addObject:[elementObj autorelease]];
		}
		
		[self appendBlipWithId:blipId
					   content:[blip valueForKey:@"content"]
					  elements:blipElements
					   creator:[pp participantById:[blip valueForKey:@"creator"]]
				  contributors:contributors
						isRoot:[blipId isEqual:aRootBlipId]
				  lastModified:parseJsonTimestamp([blip valueForKey:@"lastModifiedTime"])
					   version:[[blip valueForKey:@"version"] intValue]
					 submitted:[[blip valueForKey:@"submitted"] boolValue]];
		
		[blipElements release];
		[contributors release];
	}
	[sortedIds release];
}

#pragma mark Observer add/remove methods

- (void)addParticipantsChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"participantsChanged"];
}
- (void)removeParticipantsChangedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"participantsChanged"];
}

- (void)addBlipInsertedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"blipInserted"];
}
- (void)removeBlipInsertedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"blipInserted"];
}

- (void)addBlipDeletedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"blipDeleted"];
}
- (void)removeBlipDeletedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"blipDeleted"];
}

- (void)addStatusChangeObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"statusChange"];
}
- (void)removeStatusChangeObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"statusChange"];
}

- (void)addTitleChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"titleChanged"];
}
- (void)removeTitleChangedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"titleChanged"];
}

- (void)addLastModifiedChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"lastModifiedChanged"];
}
- (void)removeLastModifiedChangedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"lastModifiedChanged"];
}

@end

#pragma mark -

@implementation PyGoWaveBlip

@synthesize isRoot = m_root, blipId = m_id, content = m_content, lastModified = m_lastModified;

// Hidden class method
+ (NSString*)newTempId
{
	static int lastTempId = 0;
	lastTempId++;
	return [NSString stringWithFormat:@"TBD_%02d", lastTempId];
}

#pragma mark Initialization and Deallocation

- (id)initWithWavelet:(PyGoWaveWavelet*)aWavelet
			   blipId:(NSString*)aBlipId
{
	return [self initWithWavelet:aWavelet
						  blipId:aBlipId
						 content:@""
						elements:nil
						  parent:nil
						 creator:nil
					contributors:nil
						  isRoot:NO
					lastModified:nil
						 version:0
					   submitted:NO];
}
- (id)initWithWavelet:(PyGoWaveWavelet*)aWavelet
			   blipId:(NSString*)aBlipId
			  content:(NSString*)aContent
			 elements:(NSArray*)sElements
			   parent:(PyGoWaveBlip*)aParent
			  creator:(PyGoWaveParticipant*)aCreator
		 contributors:(NSArray*)sContributors
			   isRoot:(BOOL)bRoot
		 lastModified:(NSDate*)bLastModified
			  version:(NSInteger)aVersion
			submitted:(BOOL)bSubmitted
{
	if (self = [super init]) {
		m_wavelet = aWavelet; // Not retaining parent object
		if ([aBlipId isEqual:@""])
			m_id = [PyGoWaveBlip newTempId];
		else
			m_id = [aBlipId copy];
		m_parent = [aParent retain];
		m_content = [aContent mutableCopy];
		m_annotations = [NSMutableArray new];
		if (sElements == nil)
			m_elements = [NSMutableArray new];
		else
			m_elements = [sElements mutableCopy];
		for (PyGoWaveElement * element in m_elements)
			element.blip = self;
		m_creator = [aCreator retain];
		m_contributors = [NSMutableDictionary new];
		for (PyGoWaveParticipant * c in sContributors)
			[m_contributors setValue:c forKey:c.participantId];
		if ([m_contributors count] == 0)
			[m_contributors setValue:aCreator forKey:aCreator.participantId];
		m_root = bRoot;
		if (bLastModified == nil)
			m_lastModified = [[NSDate date] retain];
		else
			m_lastModified = [bLastModified copy];
		m_version = aVersion;
		m_submitted = bSubmitted;
		m_outofsync = NO;
	}
	return self;
}

- (void)dealloc
{
	[m_id release];
	[m_parent release];
	[m_content release];
	[m_annotations release];
	[m_elements release];
	[m_creator release];
	[m_contributors release];
	[m_lastModified release];
	[super dealloc];
}

#pragma mark Overwritten setters

- (void)setBlipId:(NSString*)value
{
	if (![m_id isEqual:value]) {
		[m_id release];
		m_id = [value copy];
		[self postNotificationName:@"idChanged" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithString:value], @"id", nil]];
	}
}

- (void)setLastModified:(NSDate*)value
{
	if (![m_lastModified isEqual:value]) {
		[m_lastModified release];
		m_lastModified = [value copy];
		[self postNotificationName:@"lastModifiedChanged" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[[value copy] autorelease], @"lastModified", nil]];
	}
}

#pragma mark Public methods

- (PyGoWaveParticipant*)creator
{
	return m_creator;
}

- (NSArray*)allContributors
{
	return [m_contributors allValues];
}

- (void)addContributor:(PyGoWaveParticipant*)aContributor
{
	if ([m_contributors valueForKey:aContributor.participantId] != nil) {
		[m_contributors setValue:aContributor forKey:aContributor.participantId];
		[self postNotificationName:@"contributorAdded"
						  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aContributor.participantId, @"id", nil]
						coalescing:NO];
	}
}

- (PyGoWaveWavelet*)wavelet
{
	return m_wavelet;
}

- (PyGoWaveElement*)elementById:(NSInteger)aId
{
	for (PyGoWaveElement * element in m_elements) {
		if (element.elementId == aId)
			return element;
	}
	return nil;
}

- (PyGoWaveElement*)elementAtIndex:(NSInteger)aIndex
{
	for (PyGoWaveElement * element in m_elements) {
		if (element.position == aIndex)
			return element;
	}
	return nil;
}

- (NSArray*)elementsWithinStart:(NSInteger)start andEnd:(NSInteger)end
{
	NSMutableArray * lst = [NSMutableArray new];
	for (PyGoWaveElement * element in m_elements) {
		if (element.position >= start && element.position < end)
			[lst addObject:element];
	}
	NSArray * ret = [NSArray arrayWithArray:lst];
	[lst release];
	return ret;
	
}

- (NSArray*)allElements
{
	return [NSArray arrayWithArray:m_elements];
}

- (void)insertElementAtIndex:(NSInteger)aIndex
						type:(PyGoWaveElementType)aType
				  properties:(NSDictionary*)sProperties
				 contributor:(PyGoWaveParticipant*)aContributor
{
	[self addContributor:aContributor];
	
	[m_content insertString:@"\n" atIndex:aIndex];
	for (PyGoWaveElement * element in m_elements) {
		if (element.position >= aIndex)
			element.position += 1;
	}
	for (PyGoWaveAnnotation * anno in m_annotations) {
		if (anno.start >= aIndex)
			anno.start += 1;
			anno.end += 1;
	}
	
	PyGoWaveElement * elt;
	if (aType == PyGoWaveElementType_GADGET)
		elt = [[PyGoWaveGadgetElement alloc] initWithBlip:self elementId:-1 position:aIndex properties:sProperties];
	else
		elt = [[PyGoWaveElement alloc] initWithBlip:self elementId:-1 position:aIndex elementType:aType properties:sProperties];
	[m_elements addObject:elt];
	[elt release];
	
	m_wavelet.status = @"dirty";
	
	[self postNotificationName:@"insertedElement"
					  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:aIndex], @"index", nil]
					coalescing:NO];
}

- (void)deleteElementAtIndex:(NSInteger)aIndex
				 contributor:(PyGoWaveParticipant*)aContributor
{
	[self addContributor:aContributor];
	
	int elementsCount = [m_elements count];
	for (int i = 0; i < elementsCount; i++) {
		PyGoWaveElement * elt = [m_elements objectAtIndex:i];
		if (elt.position == aIndex) {
			[elt retain];
			[m_elements removeObjectAtIndex:i];
			
			[m_content deleteCharactersInRange:NSMakeRange(aIndex, 1)];
			for (PyGoWaveElement * element in m_elements) {
				if (element.position >= aIndex)
					element.position -= 1;
			}
			for (PyGoWaveAnnotation * anno in m_annotations) {
				if (anno.start >= aIndex) {
					anno.start -= 1;
					anno.end -= 1;
				}
			}
			[self postNotificationName:@"deletedElement"
							  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:aIndex], @"index", nil]
							coalescing:NO];
			[elt autorelease];
			break;
		}
	}
}

- (void)insertTextAtIndex:(NSInteger)aIndex
					 text:(NSString*)aText
			  contributor:(PyGoWaveParticipant*)aContributor
{
	[self addContributor:aContributor];
	
	[m_content insertString:aText atIndex:aIndex];
	
	NSInteger length = [aText length];
	
	for (PyGoWaveElement * element in m_elements) {
		if (element.position >= aIndex)
			element.position += length;
	}
	
	for (PyGoWaveAnnotation * anno in m_annotations) {
		if (anno.start >= aIndex)
			anno.start += length;
			anno.end += length;
	}
	
	m_wavelet.status = @"dirty";
	
	[self postNotificationName:@"insertedText"
					  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithInt:aIndex], @"index",
								[NSString stringWithString:aText], @"text",
								nil]
					coalescing:NO];
}

- (void)deleteTextAtIndex:(NSInteger)aIndex
				   length:(NSInteger)aLength
			  contributor:(PyGoWaveParticipant*)aContributor
{
	[self addContributor:aContributor];
	
	[m_content deleteCharactersInRange:NSMakeRange(aIndex, aLength)];
	
	for (PyGoWaveElement * element in m_elements) {
		if (element.position >= aIndex)
			element.position -= aLength;
	}
	
	for (PyGoWaveAnnotation * anno in m_annotations) {
		if (anno.start >= aIndex)
			anno.start -= aLength;
			anno.end -= aLength;
	}
	
	m_wavelet.status = @"dirty";
	
	[self postNotificationName:@"deletedText"
					  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithInt:aIndex], @"index",
								[NSNumber numberWithInt:aLength], @"length",
								nil]
					coalescing:NO];
}

- (void)applyElementDelta:(NSDictionary*)aDelta
				  atIndex:(NSInteger)aIndex
			  contributor:(PyGoWaveParticipant*)aContributor
{
	[self addContributor:aContributor];
	
	PyGoWaveElement * elt = [self elementAtIndex:aIndex];
	if (elt == nil || elt.elementType != PyGoWaveElementType_GADGET)
		return;
	PyGoWaveGadgetElement * gElt = (PyGoWaveGadgetElement*) elt;
	[gElt applyDelta:aDelta];
}

- (void)setElementUserPrefWithKey:(NSString*)aKey
						  toValue:(NSString*)aValue
						  atIndex:(NSInteger)aIndex
					  contributor:(PyGoWaveParticipant*)aContributor
{
	[self addContributor:aContributor];
	
	PyGoWaveElement * elt = [self elementAtIndex:aIndex];
	if (elt == nil || elt.elementType != PyGoWaveElementType_GADGET)
		return;
	PyGoWaveGadgetElement * gElt = (PyGoWaveGadgetElement*) elt;
	[gElt setUserPrefWithKey:aKey toValue:aValue];
}

- (BOOL)checkSyncWithSum:(NSString*)aSum
{
	NSString * mySum = nil;
	
	// Calculate SHA-1 and create hex-string
	{
		CC_SHA1_CTX ctx;
		uint8_t * hashBytes = calloc(sizeof(uint8_t), CC_SHA1_DIGEST_LENGTH);
		
		const char * data = [m_content UTF8String];
		
		CC_SHA1_Init(&ctx);
		CC_SHA1_Update(&ctx, (const void*)data, strlen(data));
		CC_SHA1_Final(hashBytes, &ctx);
		
		NSMutableString * buildMySum = [NSMutableString new];
		for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
			[buildMySum appendFormat:@"%02x", hashBytes[i]];
		mySum = [NSString stringWithString:buildMySum];
		
		[buildMySum release];
		free(hashBytes);
	}
	
	if (![aSum isEqual:mySum]) {
		m_outofsync = YES;
		[self postNotificationName:@"outOfSync"];
		return NO;
	}
	return YES;
}

#pragma mark Observer add/remove methods

- (void)addInsertedTextObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"insertedText"];
}
- (void)removeInsertedTextObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"insertedText"];
}

- (void)addDeletedTextObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"deletedText"];
}
- (void)removeDeletedTextObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"deletedText"];
}

- (void)addInsertedElementObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"insertedElement"];
}
- (void)removeInsertedElementObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"insertedElement"];
}

- (void)addDeletedElementObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"deletedElement"];
}
- (void)removeDeletedElementObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"deletedElement"];
}

- (void)addOutOfSyncObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"outOfSync"];
}
- (void)removeOutOfSyncObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"outOfSync"];
}

- (void)addLastModifiedChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"lastModifiedChanged"];
}
- (void)removeLastModifiedChangedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"lastModifiedChanged"];
}

- (void)addIdChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"idChanged"];
}
- (void)removeIdChangedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"idChanged"];
}

- (void)addContributorAddedObserver:(id)notificationObserver selector:(SEL)notificationSelector
{
	[self addObserver:notificationObserver selector:notificationSelector name:@"contributorAdded"];
}
- (void)removeContributorAddedObserver:(id)notificationObserver
{
	[self removeObserver:notificationObserver name:@"contributorAdded"];
}

@end

#pragma mark -
#pragma mark Timestamp related functions

NSDate * parseJsonTimestamp(NSNumber * nts)
{
	unsigned long long ts = [nts unsignedLongLongValue];
	NSTimeInterval s = ((double)ts) / 1000.0;
	return [NSDate dateWithTimeIntervalSince1970:s];
}

NSNumber * toJsonTimestamp(NSDate * datetime)
{
	NSTimeInterval s = [datetime timeIntervalSince1970];
	unsigned long long ts = (unsigned long long)(s * 1000.0);
	return [NSNumber numberWithUnsignedLongLong:ts];
}

NSInteger sortJsonTimestamp(id num1, id num2, void * context)
{
	unsigned long long v1 = [num1 unsignedLongLongValue];
	unsigned long long v2 = [num2 unsignedLongLongValue];
	if (v1 < v2)
		return NSOrderedAscending;
	else if (v1 > v2)
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}
