//
//  MasterViewController.h
//  QueuedCoreData
//
//  Created by Dan Zinngrabe on 10/11/13.
//  Copyright (c) 2013 quellish. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
