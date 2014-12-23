//
//  ImportContactsCell.h
//  Infinit
//
//  Created by Michael Dee on 12/23/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImportContactsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton* importPhoneContactsButton;
@property (weak, nonatomic) IBOutlet UIButton* importFacebookButton;
@property (weak, nonatomic) IBOutlet UIButton* findPeopleButton;
@property (weak, nonatomic) IBOutlet UILabel *lineOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *lineTwoLabel;

@end
