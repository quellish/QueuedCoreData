//
//  MasterViewController.h
//  QueuedCoreData
//
//  Created by Dan Zinngrabe on 10/11/13.
//  Copyright (c) 2013 quellish. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController

/**
 *  initWithParentContext:
 *  @abstract Creates a new controller given a parent context, allowing the controller to instantiate it's own child.
 *
 *  @param context The parent context
 *
 *  @return The controller
 */
- (instancetype) initWithParentContext:(NSManagedObjectContext *) context;
- (void) setParentContext:(NSManagedObjectContext *)context;

@end
