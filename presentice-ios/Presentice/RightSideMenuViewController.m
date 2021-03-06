//
//  RightSideMenuViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/12/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "RightSideMenuViewController.h"

@interface RightSideMenuViewController ()

@end

@implementation RightSideMenuViewController {
//    AmazonS3Client *s3Client;
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        NSLog(@"initWithCoder");
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
        self.objectsPerPage = 3;
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
    
//    //get facebook friend list
    [self facebookFriendsList];
}
- (void) viewWillAppear:(BOOL)animated {
    [self loadObjects];
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
    
    // Configure the cell
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
    UILabel *userName = (UILabel *)[cell viewWithTag:101];
    
    //asyn to get profile picture
    [PresenticeUtitily setImageView:userProfilePicture forUser:[object objectForKey:kActivityToUserKey]];
    
    userName.text = [[object objectForKey:kActivityToUserKey] objectForKey:kUserDisplayNameKey];
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    if (indexPath.row < [self.objects count] ) {
        UserProfileViewController *userProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
        userProfileViewController.userObj = [[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityToUserKey];
        UINavigationController *centerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainNavigationController"];
        [self.menuContainerViewController setCenterViewController:centerViewController];
        NSArray *controllers = [NSArray arrayWithObject:userProfileViewController];
        centerViewController.viewControllers = controllers;
        [self.menuContainerViewController setMenuState:MFSideMenuStateClosed];
    }
}
- (void) facebookFriendsList {
    [FBRequestConnection startWithGraphPath:@"me/friends"
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              NSArray *data = [result objectForKey:@"data"];
                              NSMutableArray *facebookIds = [[NSMutableArray alloc] initWithCapacity:[data count]];
                              NSLog(@"%d", [data count]);
                              for (NSDictionary *friendData in data) {
                                  [facebookIds addObject:[friendData objectForKey:@"id"]];
                              }
                              // cache friend data
                              [[PresenticeCache sharedCache] setFacebookFriends:facebookIds];
                              //facebookFriends = [[PresenticeCache sharedCache] facebookFriends];
                          }];
}
- (IBAction)doClickFindFriendsBtn:(id)sender {
    //redirect to Find Friends View
    FindFriendViewController *findFriendViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"findFriendViewController"];
    UINavigationController *centerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainNavigationController"];
    [self.menuContainerViewController setCenterViewController:centerViewController];
    NSArray *controllers = [NSArray arrayWithObject:findFriendViewController];
    centerViewController.viewControllers = controllers;
    [self.menuContainerViewController setMenuState:MFSideMenuStateClosed];
}
@end
