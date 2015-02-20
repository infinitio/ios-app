//
//  InfinitUIMetrics.h
//  Infinit
//
//  Created by Christopher Crone on 19/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#ifndef Infinit_InfinitUIMetrics_h
#define Infinit_InfinitUIMetrics_h

typedef NS_ENUM(NSUInteger, InfinitUIEvents)
{
  // General
  InfinitUIEventAppOpen,
  InfinitUIEventAccessContacts,
  InfinitUIEventAccessGallery,
  InfinitUIEventAccessNotifications,
  // Send gallery view
  InfinitUIEventSendGalleryViewOpen,
  InfinitUIEventSendGallerySelectedElement,
  // Send recipient view
  InfinitUIEventSendRecipientViewOpen,
  InfinitUIEventSendRecipientViewToField,
  InfinitUIEventSendRecipientViewEmailAddress,
  InfinitUIEventSendRecipientViewSelectAddressBookContact,
  InfinitUIEventSendRecipientViewSelectSwagger,
  InfinitUIEventSendRecipientViewSelectFavorite,
  InfinitUIEventSendRecipientViewSend,
  // Contact view
  InfinitUIEventContactViewOpen,
  InfinitUIEventContactViewFavorite,
};

typedef NS_ENUM(NSUInteger, InfinitUIMethods)
{
  InfinitUIMethodNone,
  InfinitUIMethodNew,
  InfinitUIMethodRepeat,
  InfinitUIMethodAdd,
  InfinitUIMethodRemove,
  InfinitUIMethodNo,
  InfinitUIMethodYes,
  InfinitUIMethodTap,
  InfinitUIMethodType,
  InfinitUIMethodContact,
  InfinitUIMethodTabBar,
  InfinitUIMethodSendGalleryNext,
};

#endif