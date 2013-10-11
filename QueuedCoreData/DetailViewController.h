//
//  DetailViewController.h
//  QueuedCoreData
//
//  Created by Dan Zinngrabe on 10/11/13.
//  Copyright (c) 2013 quellish. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
