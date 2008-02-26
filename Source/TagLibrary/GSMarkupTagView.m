/* -*-objc-*-
   GSMarkupTagView.m

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: March 2002

   This file is part of GNUstep Renaissance

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
#include <TagCommonInclude.h>
#include "GSMarkupTagView.h"
#include "GSAutoLayoutDefaults.h"

#ifndef GNUSTEP
# include <Foundation/Foundation.h>
# include <AppKit/AppKit.h>
# include "GNUstep.h"
#else
# include <Foundation/NSString.h>
# include <AppKit/NSView.h>
#endif

#include <NSViewSize.h>

@implementation GSMarkupTagView

+ (NSString *) tagName
{
  return @"view";
}

+ (Class) platformObjectClass
{
  return [NSView class];
}

+ (BOOL) useInstanceOfAttribute
{
  return YES;
}

- (id) initPlatformObject: (id)platformObject
{
  /* Choose a reasonable size to start with.  Starting with a zero
   * size is not a good choice as it can easily cause problems of
   * subviews getting negative sizes etc.  If we have a hardcoded
   * size, it's a good idea to use it from the start; if so, we'll
   * also skip the -sizeToFitContent later.
   */
  NSRect frame = NSMakeRect (0, 0, 100, 100);
  NSString *width;
  NSString *height;

  width = [_attributes objectForKey: @"width"];
  if (width != nil)
    {
      float w = [width floatValue];
      if (w > 0)
	{
	  frame.size.width = w;
	}
    }
  
  height = [_attributes objectForKey: @"height"];
  if (height != nil)
    {
      float h = [height floatValue];
      if (h > 0)
	{
	  frame.size.height = h;
	}
    }

  platformObject = [platformObject initWithFrame: frame];

  /* nextKeyView, previousKeyView are outlets :-), done
   * automatically.  */

  return platformObject;
}

/* This is done at init time, but should be done *after* all other
 * initialization - so it is in a separate method which subclasses
 * can/must call at the end of their initPlatformObject: method.  */
- (id) postInitPlatformObject: (id)platformObject
{
  /* If no width or no height is specified, we need to use
   * -sizeToFitContent to choose a good size.
   */
  if (([_attributes objectForKey: @"width"] == nil)
      || ([_attributes objectForKey: @"height"] == nil))
    {
      [(NSView *)platformObject sizeToFitContent];
    }

  /* Now set the hardcoded frame if any.  */
  {
    NSRect frame = [platformObject frame];
    NSString *x, *y, *width, *height;
    BOOL needToSetFrame = NO;
    
    x = [_attributes objectForKey: @"x"];
    if (x != nil)
      {
	frame.origin.x = [x floatValue];
	needToSetFrame = YES;
      }

    y = [_attributes objectForKey: @"y"];
    if (y != nil)
      {
	frame.origin.y = [y floatValue];
	needToSetFrame = YES;
      }

    width = [_attributes objectForKey: @"width"];
    if (width != nil)
      {
	float w = [width floatValue];
	if (w > 0)
	  {
	    frame.size.width = w;
	    needToSetFrame = YES;
	  }
      }

    height = [_attributes objectForKey: @"height"];
    if (height != nil)
      {
	float h = [height floatValue];
	if (h > 0)
	  {
	    frame.size.height = h;
	    needToSetFrame = YES;
	  }
      }
    if (needToSetFrame)
      {
	[platformObject setFrame: frame];
      }
  }

  /* We don't normally use autoresizing masks, except in special
   * cases: stuff contained inside NSBox objects mostly.  As a
   * simplification for those cases, by default we want a subview to
   * get any autoresizing stuff which the superview generates (we will
   * then always turn off generating the autoresizing in the superview
   * except in the special cases).
   */
  [platformObject setAutoresizingMask: 
		     NSViewWidthSizable | NSViewHeightSizable];
  

  /* You can set autoresizing masks if you're trying to build views in the
   * old hardcoded size style.  Else, it's pretty useless.
   *
   * Subclasses have each one their own default autoresizing mask.  We
   * only modify the existing one if a different one is specified in
   * the .gsmarkup file.  The format for specifying them is as in
   * autoresizingMask="hw" for NSViewHeightSizable |
   * NSViewWidthSizable, and autoresizingMask="" for nothing,
   * autoresizingMask="xXhy" for NSViewMinXMargin | NSViewMaxXMargin |
   * NSViewHeightSizable | NSViewMinYMargin.
   */
  {
    unsigned autoresizingMask = [platformObject autoresizingMask];
    NSString *autoresizingMaskString = [_attributes objectForKey: 
						      @"autoresizingMask"];

    if (autoresizingMaskString != nil)
      {
	int i, count = [autoresizingMaskString length];
	unsigned newAutoresizingMask = 0;
	
	for (i = 0; i < count; i++)
	  {
	    unichar c = [autoresizingMaskString characterAtIndex: i];

	    switch (c)
	      {
	      case 'h':
		newAutoresizingMask |= NSViewHeightSizable;
		break;
	      case 'w':
		newAutoresizingMask |= NSViewWidthSizable;
		break;
	      case 'x':
		newAutoresizingMask |= NSViewMinXMargin;
		break;
	      case 'X':
		newAutoresizingMask |= NSViewMaxXMargin;
		break;
	      case 'y':
		newAutoresizingMask |= NSViewMinYMargin;
		break;
	      case 'Y':
		newAutoresizingMask |= NSViewMaxYMargin;
		break;
	      default:
		break;
	      }
	  }
      if (newAutoresizingMask != autoresizingMask)
        {	
          [platformObject setAutoresizingMask: newAutoresizingMask];
        }
      }
  }
  
  {
    /* This attribute is only there for people wanting to use the old
     * legacy OpenStep autoresizing system.  We ignore it otherwise.
     */
    int autoresizesSubviews = [self boolValueForAttribute: @"autoresizesSubviews"];

    if (autoresizesSubviews == 0)
      {
	[platformObject setAutoresizesSubviews: NO];
      }
    else if (autoresizesSubviews == 1)
      {
	[platformObject setAutoresizesSubviews: YES];
      }
  }

  if ([self boolValueForAttribute: @"hidden"] == 1)
    {
      [platformObject setHidden: YES];
    }

  {
    NSString *toolTip = [self localizedStringValueForAttribute: @"toolTip"];
    if (toolTip != nil)
      {
	[platformObject setToolTip: toolTip];
      }
  }

  if (([self class] == [GSMarkupTagView class]) 
      || [self shouldTreatContentAsSubviews])
    {
      /* Extract the contents of the tag.  Contents are subviews that
       * get added to us.  This should only be used in special cases
       * or when the (legacy) OpenStep autoresizing system is used
       * (also, splitviews use it).  In all other cases, vbox and hbox
       * and similar autoresizing containers should be used.
       */
      int i, count = [_content count];
      
      /* Go in the order found in the XML file, so that the list of
       * views in the XML file goes from the ones below to the
       * ones above.
       * Ie, in
       *  <view id="1">
       *    <view id="2" />
       *    <view id="3" />
       *  </view>
       * view 3 appears over view 2.
       */
      for (i = 0; i < count; i++)
	{
	  GSMarkupTagView *v = [_content objectAtIndex: i];
	  NSView *view = [v platformObject];
	  
	  if (view != nil  &&  [view isKindOfClass: [NSView class]])
	    {
	      [platformObject addSubview: view];
	    }
	}
    }

  return platformObject;
}

/* This is ignored unless it returns YES, in which cases it forces
 * loading all content tags as subviews.
 */
- (BOOL) shouldTreatContentAsSubviews
{
  return NO;
}

- (int) gsAutoLayoutHAlignment
{
  NSString *halign;

  if ([self boolValueForAttribute: @"hexpand"] == 1)
    {
      return GSAutoLayoutExpand;
    }

  halign = [_attributes objectForKey: @"halign"];

  if (halign != nil)
    {
      if ([halign isEqualToString: @"expand"])
	{
	  return GSAutoLayoutExpand;
	}
      else if ([halign isEqualToString: @"wexpand"])
	{
	  return GSAutoLayoutWeakExpand;
	}
      else if ([halign isEqualToString: @"min"])
	{
	  return GSAutoLayoutAlignMin;
	}
      else if ([halign isEqualToString: @"left"])
	{
	  return GSAutoLayoutAlignMin;
	}
      else if ([halign isEqualToString: @"center"])
	{
	  return GSAutoLayoutAlignCenter;
	}
      else if ([halign isEqualToString: @"max"])
	{
	  return GSAutoLayoutAlignMax;
	}
      else if ([halign isEqualToString: @"right"])
	{
	  return GSAutoLayoutAlignMax;
	}
    }

  return 255;
}

- (int) gsAutoLayoutVAlignment
{
  NSString *valign;

  if ([self boolValueForAttribute: @"vexpand"] == 1)
    {
      return GSAutoLayoutExpand;
    }

  valign = [_attributes objectForKey: @"valign"];

  if (valign != nil)
    {
      if ([valign isEqualToString: @"expand"])
	{
	  return GSAutoLayoutExpand;
	}
      else if ([valign isEqualToString: @"wexpand"])
	{
	  return GSAutoLayoutWeakExpand;
	}
      else if ([valign isEqualToString: @"min"])
	{
	  return GSAutoLayoutAlignMin;
	}
      else if ([valign isEqualToString: @"bottom"])
	{
	  return GSAutoLayoutAlignMin;
	}
      else if ([valign isEqualToString: @"center"])
	{
	  return GSAutoLayoutAlignCenter;
	}
      else if ([valign isEqualToString: @"max"])
	{
	  return GSAutoLayoutAlignMax;
	}
      else if ([valign isEqualToString: @"top"])
	{
	  return GSAutoLayoutAlignMax;
	}
    }

  return 255;
}

@end
