//
//  RightSideMenuViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/12/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <Parse/Parse.h>
#import "MFSideMenu.h"
#import "Constants.h"
#import "MBProgressHUD.h"


#import "MessageDetailViewController.h"
#import "UserProfileViewController.h"
#import "FindFriendViewController.h"


@interface RightSideMenuViewController : PFQueryTableViewController

- (IBAction)doClickFindFriendsBtn:(id)sender;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
