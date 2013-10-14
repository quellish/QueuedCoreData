//
//  MasterViewController.m
//  QueuedCoreData
//
//  Created by Dan Zinngrabe on 10/11/13.
//  Copyright (c) 2013 quellish. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

@interface MasterViewController ()<NSFetchedResultsControllerDelegate>
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@property (strong, nonatomic) NSFetchedResultsController    *fetchedResultsController;
@property (strong, nonatomic) UIRefreshControl IBOutlet     *refreshControl;
@property (strong, nonatomic) NSManagedObjectContext     *managedObjectContext;


@end

@implementation MasterViewController
@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize refreshControl;

- (instancetype) initWithParentContext:(NSManagedObjectContext *) context {
    if (self = [super init]){
        // Create a new child
        [self setParentContext:context];
    }
    return self;
}

- (void) setParentContext:(NSManagedObjectContext *)context {
    // Create a new child context
    // You have the option of using two different concurrency types:
    // NSPrivateQueueConcurrencyType: All Core Data operations for the receiver happen on the private queue. This also means that the NSFetchedResultsController will send delegate callbacks from that queue, which will almost always not be on the main thread.
    // NSMainQueueConcurrencyType: All Core Data operations for the receiver will happen on the main queue. This isn't as bad as you may thing, as the parent context is the one managing the persistent store coordinator. That means that (if you're Doing It Right™) nearly all of your heavy Core Data work is being done there, not the main queue. You should not block the UI with core data operations. There are also a number of ways you can creatively chain together parent and child contexts to minimize the impact on the UI (if any).
    NSManagedObjectContext  *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    // Of course, if you were really clever you might use a private queue, but have a separate NSFetchedResultsControllerDelegate that trampolines the callbacks through the main queue to here.
    [moc setParentContext:context];
    managedObjectContext = moc;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
    [self.navigationItem setRightBarButtonItems:@[addButton,saveButton] animated:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)__unused sender
{
    NSManagedObjectContext  *context            = nil;
    NSEntityDescription     *entity             = nil;
    NSManagedObject         *newManagedObject   = nil;
    
    context = [self.fetchedResultsController managedObjectContext];
    if (context != nil){
        entity = [[self.fetchedResultsController fetchRequest] entity];
        newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
        
        // Save only our context, not through the parents.
        [self saveContext:context recursively:NO];
    }
}

- (void) save:(id)__unused sender {
    NSManagedObjectContext  *context =  nil;
    context = [[self fetchedResultsController] managedObjectContext];
    
    // Save this context, and only this context. This will NOT save all the way down to the store, but
    // you will get all the notifications, events, etc. you expect for this context. You are updating a set of changes, saving all the way down
    // would commit them.
    [self saveContext:context recursively:YES];
    
}

// Simple pull to refresh. This will run your query again, if that's your thing. No error handling for the demo.
- (IBAction)refetch:(id) sender {
    NSError *error  = nil;
    if ([[self fetchedResultsController] performFetch:&error]){
        [sender endRefreshing];
    }
}

// Save the context recursively all the way down to the store.
- (void) saveContext:(NSManagedObjectContext *)context recursively:(BOOL)recurse{
    
    [context performBlock:^{
        NSError *error  = nil;
        
        if ([context save:&error]){
            if (recurse){
                [self saveContext:[context parentContext] recursively:recurse];
            }
        } else {
            // handle error
        }
    }];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView
{
    return (NSInteger)[[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger   result  = 0;
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:(NSUInteger)section];
    // Hit an exception here on iOS 6 and 7? Your cache is corrupt.
    if ([sectionInfo objects] != nil){
        result = (NSInteger)[sectionInfo numberOfObjects];
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)__unused tableView canEditRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)__unused tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        [self saveContext:context recursively:NO];
    }   
}

- (BOOL)tableView:(UITableView *)__unused tableView canMoveRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)__unused sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setValue:object forKey:@"detailItem"];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (fetchedResultsController == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        // Set the batch size to a suitable number.
        [fetchRequest setFetchBatchSize:20];
        
        // Edit the sort key as appropriate.
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
        NSArray *sortDescriptors = @[sortDescriptor];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        aFetchedResultsController.delegate = self;
        self.fetchedResultsController = aFetchedResultsController;
        
        NSError *error = nil;
        if (![self.fetchedResultsController performFetch:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)__unused controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)__unused controller didChangeSection:(id <NSFetchedResultsSectionInfo>)__unused sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)__unused controller didChangeObject:(id)__unused anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)__unused controller
{
    [self.tableView endUpdates];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([[[self fetchedResultsController] fetchedObjects] count] > 0){
        NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
        cell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
    }
}

@end
