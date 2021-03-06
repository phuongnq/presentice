//
//  FriendListViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/9/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "FriendListViewController.h"

@interface FriendListViewController ()

@end

@implementation FriendListViewController {
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = kActivityClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = kActivityTypeKey;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 5;
    }
    self.tabBarController.hidesBottomBarWhenPushed = YES;
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"get in friend list");
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshTable:(NSNotification *) notification {
    // Reload the recipes
    [self loadObjects];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTable" object:nil];
}

- (PFQuery *)queryForTable {
    // Query all followActivities where toUser is followed by the currentUser
    PFQuery *followingFriendQuery = [PresenticeUtitily followingFriendsOfUser:[PFUser currentUser]];
    
    [followingFriendQuery orderByAscending:kUpdatedAtKey];
    return followingFriendQuery;
}

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"friendListIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    PFUser *user = [object objectForKey:kActivityToUserKey];
    
    // Configure the cell
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
    UILabel *userName = (UILabel *)[cell viewWithTag:101];
    [PresenticeUtitily setImageView:userProfilePicture forUser:user];
    userName.text = [user objectForKey:kUserDisplayNameKey];

    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"objectsDidLoad message list error: %@", [error localizedDescription]);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFUser *toUser = [[self objectAtIndexPath:indexPath] objectForKey:kActivityToUserKey];
    
    MessageDetailViewController *destViewController = [[MessageDetailViewController alloc] init];
    
    PFQuery *messageQuery = [PFQuery queryWithClassName:kMessageClassKey];
    [messageQuery whereKey:kMessageUsersKey containsAllObjectsInArray:@[[PFUser currentUser], toUser]];
    [messageQuery includeKey:kMessageUsersKey];
    [messageQuery includeKey:kMessageFromUserKey];
    [messageQuery includeKey:kMessageToUserKey];
    
    [messageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (objects.count == 0) {
//                NSLog(@"fuck there is no object");
                PFObject *messageObj = [PFObject objectWithClassName:kMessageClassKey];
                
                NSMutableArray *users = [[NSMutableArray alloc] initWithArray:@[[PFUser currentUser],toUser]];    // Add two users to the "users" field
                NSSortDescriptor *aSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"objectId" ascending:YES];
                [users sortUsingDescriptors:[NSArray arrayWithObject:aSortDescriptor]];
                
                [messageObj setObject:users forKey:kMessageUsersKey];
                [messageObj setObject:[PFUser currentUser] forKey:kMessageFromUserKey];
                [messageObj setObject:toUser forKey:kMessageToUserKey];
                
                NSMutableArray *messages = [[NSMutableArray alloc] init];
                [messageObj setObject:messages forKey:kMessageContentKey];
                
                PFACL *messageACL = [PFACL ACL];
                [messageACL setReadAccess:YES forUser:[PFUser currentUser]];
                [messageACL setReadAccess:YES forUser:toUser];
                [messageACL setWriteAccess:YES forUser:[PFUser currentUser]];
                [messageACL setWriteAccess:YES forUser:toUser];
                messageObj.ACL = messageACL;
                
                destViewController.messageObj = messageObj;
            } else {
//                NSLog(@"fuck there is %d object", objects.count);
                destViewController.messageObj = [objects lastObject];
            }
            
//            NSLog(@"destViewController.messageObj = %@",destViewController.messageObj);
            
            destViewController.toUser = toUser;
            
            [self.navigationController pushViewController:destViewController animated:YES];
        } else {
            // Log details of the failure
            NSLog(@"Could not find message Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)showRightMenu:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}

@end
