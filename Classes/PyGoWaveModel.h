
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

// Aww, no namespaces... That means prefix everything...

#import "PyGoWaveBase.h"

@interface PyGoWaveParticipant : PyGoWaveObject
{
	NSString *m_participantId;
	NSString *m_displayName;
	NSString *m_thumbnailUrl;
	NSString *m_profileUrl;
	BOOL m_online;
	BOOL m_bot;
}
@property (nonatomic, copy, readonly) NSString *participantId;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *thumbnailUrl;
@property (nonatomic, copy) NSString *profileUrl;
@property (nonatomic) BOOL online;
@property (nonatomic) BOOL bot;

- (id)initWithParticipantId:(NSString *)participantId;
- (void)dealloc;

- (void)updateDataWithDict:(NSDictionary *)obj byServer:(NSString*)server;
- (NSDictionary *)toGadgetFormat;

// Convenience methods to add/remove Observers

- (void)addDataChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeDataChangedObserver:(id)notificationObserver;

- (void)addOnlineStateChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeOnlineStateChangedObserver:(id)notificationObserver;

@end

#pragma mark -

@protocol PyGoWaveParticipantProvider

- (PyGoWaveParticipant *)participantById:(NSString *)aParticipntId;

@end


@class PyGoWaveWavelet, PyGoWaveBlip, PyGoWaveOperation;

#pragma mark -

@interface PyGoWaveAnnotation : PyGoWaveObject
{
	PyGoWaveBlip * m_blip;
	NSString * m_name;
	NSInteger m_start;
	NSInteger m_end;
	NSString * m_value;
}
@property (readonly) PyGoWaveBlip *blip;
@property (nonatomic, copy) NSString *name;
@property NSInteger start;
@property NSInteger end;
@property (nonatomic, copy) NSString *value;

- (id)initWithBlip:(PyGoWaveBlip*)aBlip name:(NSString*)aName start:(NSInteger)aStart end:(NSInteger)aEnd value:(NSString*)aValue;
- (void)dealloc;

@end

#pragma mark -

enum {
	PyGoWaveElementType_NOTHING = 0,
	PyGoWaveElementType_INLINE_BLIP = 1,
	PyGoWaveElementType_GADGET = 2,
	PyGoWaveElementType_INPUT = 3,
	PyGoWaveElementType_CHECK = 4,
	PyGoWaveElementType_LABEL = 5,
	PyGoWaveElementType_BUTTON = 6,
	PyGoWaveElementType_RADIO_BUTTON = 7,
	PyGoWaveElementType_RADIO_BUTTON_GROUP = 8,
	PyGoWaveElementType_PASSWORD = 9,
	PyGoWaveElementType_IMAGE = 10
};
typedef NSInteger PyGoWaveElementType;

@interface PyGoWaveElement : PyGoWaveObject
{
	PyGoWaveBlip * m_blip;
	NSInteger m_id;
	NSInteger m_pos;
	PyGoWaveElementType m_type;
	NSMutableDictionary * m_properties;
}
@property (retain) PyGoWaveBlip *blip;
@property (readonly) NSInteger elementId;
@property (readonly) NSInteger elementType;
@property NSInteger position;

- (id)initWithBlip:(PyGoWaveBlip*)aBlip elementId:(NSInteger)aId position:(NSInteger)aPosition elementType:(PyGoWaveElementType)aType properties:(NSDictionary*)someProperties;
- (void)dealloc;

@end

#pragma mark -

@interface PyGoWaveGadgetElement : PyGoWaveElement
{
}
@property (readonly, nonatomic) NSDictionary *fields;
@property (readonly, nonatomic) NSDictionary *userPrefs;
@property (readonly, nonatomic) NSString *url;

- (id)initWithBlip:(PyGoWaveBlip*)aBlip elementId:(NSInteger)aId position:(NSInteger)aPosition properties:(NSDictionary*)someProperties;

- (void)applyDelta:(NSDictionary*)delta;
- (void)setUserPrefWithKey:(NSString*)key toValue:(NSString*)value;

// Convenience methods to add/remove Observers

- (void)addStateChangeObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeStateChangeObserver:(id)notificationObserver;

- (void)addUserPrefSetObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeUserPrefSetObserver:(id)notificationObserver;

@end

#pragma mark -

@interface PyGoWaveWaveModel : PyGoWaveObject
{
	PyGoWaveWavelet * m_rootWavelet;
	NSString * m_waveId;
	NSString * m_viewerId;
	NSMutableDictionary * m_wavelets;
	NSObject <PyGoWaveParticipantProvider> * m_pp;
}
@property (readonly, copy) NSString * waveId;
@property (readonly, copy) NSString * viewerId;
@property (retain) PyGoWaveWavelet * rootWavelet;
@property (retain) NSObject <PyGoWaveParticipantProvider> * participantProvider;

- (id)initWithWaveId:(NSString*)aWaveId viewerId:(NSString*)aViewerId participantProvider:(NSObject <PyGoWaveParticipantProvider>*)pp;
- (void)dealloc;

- (void)loadFromSnapshot:(NSDictionary*)obj;
- (PyGoWaveWavelet*)createWaveletWithId:(NSString*)aId;
- (PyGoWaveWavelet*)createWaveletWithId:(NSString*)aId
								creator:(PyGoWaveParticipant*)aCreator;
- (PyGoWaveWavelet*)createWaveletWithId:(NSString*)aId
								creator:(PyGoWaveParticipant*)aCreator
								  title:(NSString*)aTitle;
- (PyGoWaveWavelet*)createWaveletWithId:(NSString*)aId
								creator:(PyGoWaveParticipant*)aCreator
								  title:(NSString*)aTitle
								 isRoot:(BOOL)bRoot
								created:(NSDate*)bCreated
						   lastModified:(NSDate*)bLastModified
								version:(NSInteger)aVersion;

- (PyGoWaveWavelet*)waveletById:(NSString*)aId;
- (NSArray*)allWavelets;
- (void)removeWaveletById:(NSString*)aId;

- (void)addWaveletAddedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeWaveletAddedObserver:(id)notificationObserver;

- (void)addWaveletAboutToBeRemovedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeWaveletAboutToBeRemovedObserver:(id)notificationObserver;

@end

#pragma mark -

@interface PyGoWaveWavelet : PyGoWaveObject
{
	PyGoWaveWaveModel * m_wave;
	
	NSString * m_id;
	PyGoWaveParticipant * m_creator;
	NSString * m_title;
	BOOL m_root;
	NSDate * m_created;
	NSDate * m_lastModified;
	NSInteger m_version;
	
	NSMutableDictionary * m_participants;
	NSMutableArray * m_blips;
	PyGoWaveBlip * m_rootBlip;
	NSString * m_status;
}
@property NSInteger version;
@property (readonly) BOOL isRoot;
@property (readonly, copy) NSString * waveletId;
@property (readonly, nonatomic, copy) NSString * waveId;
@property (nonatomic, copy) NSString * title;
@property (readonly, nonatomic) NSInteger participantCount;
@property (nonatomic, copy) NSString * status;
@property (readonly, nonatomic, copy) NSDate * created;
@property (nonatomic, copy) NSDate * lastModified;
@property (readonly, nonatomic, copy) NSDictionary * allParticipantsForGadget;

- (id)initWithWave:(PyGoWaveWaveModel*)aWave
		 waveletId:(NSString*)aWaveletId;
- (id)initWithWave:(PyGoWaveWaveModel*)aWave
		 waveletId:(NSString*)aWaveletId
		   creator:(PyGoWaveParticipant*)aCreator;
- (id)initWithWave:(PyGoWaveWaveModel*)aWave
		 waveletId:(NSString*)aWaveletId
		   creator:(PyGoWaveParticipant*)aCreator
			 title:(NSString*)aTitle;
- (id)initWithWave:(PyGoWaveWaveModel*)aWave
		 waveletId:(NSString*)aWaveletId
		   creator:(PyGoWaveParticipant*)aCreator
			 title:(NSString*)aTitle
			isRoot:(BOOL)bRoot
		   created:(NSDate*)bCreated
	  lastModified:(NSDate*)bLastModified
		   version:(NSInteger)aVersion;
- (void)dealloc;

- (NSArray*)allParticipantIDs;

- (NSArray*)allBlipIDs;

- (PyGoWaveParticipant*)creator;
- (PyGoWaveWaveModel*)waveModel;

- (void)addParticipant:(PyGoWaveParticipant*)aParticipant;
- (void)removeParticipantById:(NSString*)aId;

- (PyGoWaveParticipant*)participantById:(NSString*)aId;
- (NSArray*)allParticipants;

- (PyGoWaveBlip*)appendBlipWithCreator:(PyGoWaveParticipant*)aCreator;
- (PyGoWaveBlip*)appendBlipWithId:(NSString*)aId;
- (PyGoWaveBlip*)appendBlipWithId:(NSString*)aId
						  content:(NSString*)sContent
						 elements:(NSArray*)sElements
						 creator:(PyGoWaveParticipant*)aCreator
					 contributors:(NSArray*)sContributors
						   isRoot:(BOOL)bRoot
					 lastModified:(NSDate*)bLastModified
						  version:(NSInteger)aVersion
						submitted:(BOOL)bSubmitted;

- (PyGoWaveBlip*)insertBlipAtIndex:(NSInteger)index
							blipId:(NSString*)aId;
- (PyGoWaveBlip*)insertBlipAtIndex:(NSInteger)index
							blipId:(NSString*)aId
						   content:(NSString*)sContent
						  elements:(NSArray*)sElements
						   creator:(PyGoWaveParticipant*)aCreator
					  contributors:(NSArray*)sContributors
							isRoot:(BOOL)bRoot
					  lastModified:(NSDate*)bLastModified
						   version:(NSInteger)aVersion
						 submitted:(BOOL)bSubmitted;

- (void)deleteBlipWithId:(NSString*)aId;
- (PyGoWaveBlip*)blipByIndex:(NSInteger)aIndex;
- (PyGoWaveBlip*)blipById:(NSString*)aId;
- (NSArray*)allBlips;

- (void)checkSync:(NSDictionary*)blipsums;

- (void)applyOperations:(NSArray*)sOperations timestamp:(NSDate*)aTimestamp contributorId:(NSString*)aContributorId;

- (void)updateBlipId:(NSString*)tempId toBlipId:(NSString*)blipId;

- (void)loadBlipsFromSnapshot:(NSDictionary*)blips rootBlipId:(NSString*)aRootBlipId;

- (void)addParticipantsChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeParticipantsChangedObserver:(id)notificationObserver;

- (void)addBlipInsertedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeBlipInsertedObserver:(id)notificationObserver;

- (void)addBlipDeletedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeBlipDeletedObserver:(id)notificationObserver;

- (void)addStatusChangeObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeStatusChangeObserver:(id)notificationObserver;

- (void)addTitleChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeTitleChangedObserver:(id)notificationObserver;

- (void)addLastModifiedChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeLastModifiedChangedObserver:(id)notificationObserver;

@end

#pragma mark -

@interface PyGoWaveBlip : PyGoWaveObject
{
	PyGoWaveWavelet * m_wavelet;
	NSString * m_id;
	NSMutableString * m_content;
	NSMutableArray * m_elements;
	PyGoWaveBlip * m_parent;
	PyGoWaveParticipant * m_creator;
	NSDictionary * m_contributors;
	BOOL m_root;
	NSDate * m_lastModified;
	NSInteger m_version;
	BOOL m_submitted;
	BOOL m_outofsync;
	NSMutableArray * m_annotations;
}
@property (nonatomic, copy) NSString * blipId;
@property (readonly) BOOL isRoot;
@property (readonly, nonatomic, copy) NSString * content;
@property (nonatomic, copy) NSDate * lastModified;

- (id)initWithWavelet:(PyGoWaveWavelet*)aWavelet
			   blipId:(NSString*)aBlipId;
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
			submitted:(BOOL)bSubmitted;
- (void)dealloc;

- (PyGoWaveParticipant*)creator;

- (NSArray*)allContributors;

- (void)addContributor:(PyGoWaveParticipant*)aContributor;

- (PyGoWaveWavelet*)wavelet;
- (PyGoWaveElement*)elementById:(NSInteger)aId;
- (PyGoWaveElement*)elementAtIndex:(NSInteger)aIndex;
- (NSArray*)elementsWithinStart:(NSInteger)start andEnd:(NSInteger)end;
- (NSArray*)allElements;

- (void)insertElementAtIndex:(NSInteger)aIndex
						type:(PyGoWaveElementType)aType
				  properties:(NSDictionary*)sProperties
				 contributor:(PyGoWaveParticipant*)aContributor;
- (void)deleteElementAtIndex:(NSInteger)aIndex
				 contributor:(PyGoWaveParticipant*)aContributor;
- (void)insertTextAtIndex:(NSInteger)aIndex
					 text:(NSString*)aText
			  contributor:(PyGoWaveParticipant*)aContributor;
- (void)deleteTextAtIndex:(NSInteger)aIndex
				   length:(NSInteger)aLength
			  contributor:(PyGoWaveParticipant*)aContributor;
- (void)applyElementDelta:(NSDictionary*)aDelta
				  atIndex:(NSInteger)aIndex
			  contributor:(PyGoWaveParticipant*)aContributor;
- (void)setElementUserPrefWithKey:(NSString*)aKey
						  toValue:(NSString*)aValue
						  atIndex:(NSInteger)aIndex
					  contributor:(PyGoWaveParticipant*)aContributor;

- (BOOL)checkSyncWithSum:(NSString*)aSum;

- (void)addInsertedTextObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeInsertedTextObserver:(id)notificationObserver;

- (void)addDeletedTextObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeDeletedTextObserver:(id)notificationObserver;

- (void)addInsertedElementObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeInsertedElementObserver:(id)notificationObserver;

- (void)addDeletedElementObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeDeletedElementObserver:(id)notificationObserver;

- (void)addOutOfSyncObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeOutOfSyncObserver:(id)notificationObserver;

- (void)addLastModifiedChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeLastModifiedChangedObserver:(id)notificationObserver;

- (void)addIdChangedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeIdChangedObserver:(id)notificationObserver;

- (void)addContributorAddedObserver:(id)notificationObserver selector:(SEL)notificationSelector;
- (void)removeContributorAddedObserver:(id)notificationObserver;

@end

#pragma mark -

NSDate * parseJsonTimestamp(NSNumber * nts);
NSNumber * toJsonTimestamp(NSDate * datetime);
NSInteger sortJsonTimestamp(id num1, id num2, void *context);
