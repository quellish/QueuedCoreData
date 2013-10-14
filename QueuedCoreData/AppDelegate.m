//
//  AppDelegate.m
//  QueuedCoreData
//
//  Created by Dan Zinngrabe on 10/11/13.
//  Copyright (c) 2013 quellish. All rights reserved.
//

#import "AppDelegate.h"

#import "MasterViewController.h"

@interface AppDelegate()
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation AppDelegate
@synthesize window;
@synthesize managedObjectModel;
@synthesize persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)__unused application didFinishLaunchingWithOptions:(NSDictionary *)__unused launchOptions {
    NSManagedObjectContext  *context    = nil;
    // Override point for customization after application launch.
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    
    // Note the the recommented best practice is to pass controllers a context that is discardable:
    // https://developer.apple.com/library/ios/releasenotes/DataManagement/RN-CoreData/index.html#//apple_ref/doc/uid/TP40010637
    
    MasterViewController *controller = (MasterViewController *)navigationController.topViewController;
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [self persistentStoreCoordinator];
    // This will create a new child context in the controller. In a real application you may use an informal protocol, etc. to get a new child context for a given persistent store coordinator.
    [controller setParentContext:context];
    
    return YES;
}

#pragma mark - Core Data stack


- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel == nil) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"QueuedCoreData" withExtension:@"momd"];
        managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return managedObjectModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator == nil){
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"QueuedCoreData.sqlite"];
        
        NSError *error = nil;
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {

            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
