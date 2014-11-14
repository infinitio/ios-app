//
//  InfinitLinkTransactionsController.h
//  Infinit
//
//  Created by Christopher Crone on 13/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitLinkTransactionsController : UIViewController <UITableViewDataSource,
                                                                 UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* table_view;

@end
