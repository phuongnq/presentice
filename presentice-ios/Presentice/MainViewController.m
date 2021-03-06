//
//  MainViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/31/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController {
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
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
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


#pragma query table objects

- (PFQuery *)queryForTable {
    
    // Query all followActivities where toUser is followed by the currentUser
    PFQuery *followingFriendQuery = [PresenticeUtitily followingFriendsOfUser:[PFUser currentUser]];
    
    // Get all videos that are viewable from the currentUser
    PFQuery *visibleVideoQuery = [PresenticeUtitily videosCanBeViewedByUser:[PFUser currentUser]];
    
    PFQuery *videoRelatedActivityQuery = [PresenticeUtitily activitiesRelatedToFriendsOfUser:[PFUser currentUser]];
    [videoRelatedActivityQuery whereKey:kActivityTypeKey containedIn:@[@"answer", @"review", @"postQuestion"]];
    [videoRelatedActivityQuery whereKey:kActivityTargetVideoKey matchesQuery:visibleVideoQuery];
    
    PFQuery *registerActivityQuery = [PFQuery queryWithClassName:self.parseClassName];
    [registerActivityQuery whereKey:kActivityTypeKey equalTo:@"register"];
    [registerActivityQuery whereKey:kActivityFromUserKey matchesKey:kActivityToUserKey inQuery:followingFriendQuery];
    
    PFQuery *activitiesQuery = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:videoRelatedActivityQuery, registerActivityQuery, nil]];
    
    [activitiesQuery includeKey:kActivityFromUserKey];
    [activitiesQuery includeKey:kActivityTargetVideoKey];
    [activitiesQuery includeKey:@"targetVideo.user"];
    [activitiesQuery includeKey:@"targetVideo.asAReplyTo"];
    [activitiesQuery includeKey:@"targetVideo.toUser"];
    [activitiesQuery includeKey:@"targetVideo.reviews"];
    [activitiesQuery includeKey:kActivityToUserKey];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        activitiesQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [activitiesQuery orderByDescending:kUpdatedAtKey];
    return activitiesQuery;
}

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.

#pragma mark - UITableViewDataSource

/**
 * delegage method
 * number of rows of table
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = self.objects.count;
    if (self.paginationEnabled && sections != 0)
        sections++;
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == self.objects.count) {
        return 0.0f;
    }
    return 10.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake( 0.0f, 0.0f, self.tableView.bounds.size.width, 16.0f)];
    return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == self.objects.count) {
        return 0.0f;
    }
    return 5.0f;
}


- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    // overridden, since we want to implement sections
    if (indexPath.section < self.objects.count) {
        return [self.objects objectAtIndex:indexPath.section];
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section >= self.objects.count) {
        return 70;
    } else {
        if ([[[self.objects objectAtIndex:indexPath.section] objectForKey:kActivityTypeKey] isEqualToString:@"answer"] ) {
            return 50;
        } else if ([[[self.objects objectAtIndex:indexPath.section] objectForKey:kActivityTypeKey] isEqualToString:@"review"]) {
            return 85;
        } else if ([[[self.objects objectAtIndex:indexPath.section] objectForKey:kActivityTypeKey] isEqualToString:@"postQuestion"]) {
            return 85;
        } else if ([[[self.objects objectAtIndex:indexPath.section] objectForKey:kActivityTypeKey] isEqualToString:@"register"]) {
            return 50;
        } else {
            return 120;
        }
    }
}

/**
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.objects count];
}
**/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    
    if (indexPath.section == self.objects.count) {
        // this behavior is normally handled by PFQueryTableViewController, but we are using sections for each object and we must handle this ourselves
        UITableViewCell *cell = [self tableView:tableView cellForNextPageAtIndexPath:indexPath];
        return cell;
    } else {
        if ([[object objectForKey:kActivityTypeKey] isEqualToString:@"answer"]) {
            NSString *simpleTableIdentifier = @"answerListIdentifier";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
            }
            
            // Configure the cell
            UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
            UILabel *description = (UILabel *)[cell viewWithTag:101];
            UILabel *postedTime = (UILabel *)[cell viewWithTag:102];
            UILabel *viewsNum = (UILabel *)[cell viewWithTag:103];
            
            [PresenticeUtitily setImageView:userProfilePicture forUser:[object objectForKey:kActivityFromUserKey]];
            description.text = [NSString stringWithFormat:@"%@ has posted %@",
                                [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                                [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
            [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
            [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]]];
            postedTime.text = [NSString stringWithFormat:@"%@", [[[NSDate alloc] initWithTimeInterval:0 sinceDate:object.createdAt] dateTimeUntilNow]];
            viewsNum.text = [PresenticeUtitily stringNumberOfKey:kVideoViewsKey inObject:[object objectForKey:kActivityTargetVideoKey]];
            
            
            NSLog(@"can currentUser view this video = %hhd", [PresenticeUtitily canUser:[PFUser currentUser] viewVideo:object]);
            
            return cell;
        } else if ([[object objectForKey:kActivityTypeKey] isEqualToString:@"review"]) {
            NSString *simpleTableIdentifier = @"reviewListIdentifier";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
            }
            
            // Configure the cell
            UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
            UILabel *description = (UILabel *)[cell viewWithTag:101];
            UILabel *postedTime = (UILabel *)[cell viewWithTag:102];
            UILabel *comment = (UILabel *)[cell viewWithTag:103];
            UILabel *viewsNum = (UILabel *)[cell viewWithTag:104];
            
            
            [PresenticeUtitily setImageView:userProfilePicture forUser:[object objectForKey:kActivityFromUserKey]];
            description.text = [NSString stringWithFormat:@"%@ has reviewed %@'s %@",
                                [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                                [[object objectForKey:kActivityToUserKey] objectForKey:kUserDisplayNameKey],
                                [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
            [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
            [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityToUserKey] objectForKey:kUserDisplayNameKey]]];
            [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]]];
            postedTime.text = [NSString stringWithFormat:@"%@", [[[NSDate alloc] initWithTimeInterval:0 sinceDate:object.createdAt] dateTimeUntilNow]];
            viewsNum.text = [PresenticeUtitily stringNumberOfKey:kVideoViewsKey inObject:[object objectForKey:kActivityTargetVideoKey]];
            comment.text = [object objectForKey:kActivityDescriptionKey];

            return cell;
        } else if ([[object objectForKey:kActivityTypeKey] isEqualToString:@"postQuestion"]) {
            NSString *simpleTableIdentifier = @"postQuestionListIdentifier";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
            }
            
            // Configure the cell
            UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
            UILabel *description = (UILabel *)[cell viewWithTag:101];
            UILabel *postedTime = (UILabel *)[cell viewWithTag:102];
            UILabel *comment = (UILabel *)[cell viewWithTag:103];
            UILabel *viewsNum = (UILabel *)[cell viewWithTag:104];
            
            [PresenticeUtitily setImageView:userProfilePicture forUser:[object objectForKey:kActivityFromUserKey]];
            description.text = [NSString stringWithFormat:@"%@ has posted a new question %@",
                                [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                                [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
            [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
            [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]]];
            postedTime.text = [NSString stringWithFormat:@"%@", [[[NSDate alloc] initWithTimeInterval:0 sinceDate:object.createdAt] dateTimeUntilNow]];
            viewsNum.text = [PresenticeUtitily stringNumberOfKey:kVideoViewsKey inObject:[object objectForKey:kActivityTargetVideoKey]];
            comment.text = [object objectForKey:kActivityDescriptionKey];
            
            return cell;
        } else if ([[object objectForKey:kActivityTypeKey] isEqualToString:@"register"]) {
            NSString *simpleTableIdentifier = @"registerListIdentifier";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
            }
            
            // Configure the cell
            UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
            UILabel *description = (UILabel *)[cell viewWithTag:101];
            UILabel *postedTime = (UILabel *)[cell viewWithTag:102];
            
            [PresenticeUtitily setImageView:userProfilePicture forUser:[object objectForKey:kActivityFromUserKey]];
            description.text = [NSString stringWithFormat:@"%@ has joined Presentice",
                                [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]];
            [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
            postedTime.text = [NSString stringWithFormat:@"%@", [[[NSDate alloc] initWithTimeInterval:0 sinceDate:object.createdAt] dateTimeUntilNow]];
            
            return cell;
        } else {
            NSString *simpleTableIdentifier = @"answerListIdentifier";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
            }
            return cell;
        }
    }
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}
/**
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showAnswerfromAnswerDescription"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        VideoViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.section];
        PFObject *videoObj = [object objectForKey:kActivityTargetVideoKey];
        
        destViewController.movieURL = [PresenticeUtitily s3URLForObject:videoObj];
        destViewController.answerVideoObj = videoObj;
        
    } else if ([segue.identifier isEqualToString:@"showAnswerFromReviewDescription"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        VideoViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.section];
        PFObject *videoObj = [object objectForKey:kActivityTargetVideoKey];
        
        destViewController.movieURL = [PresenticeUtitily s3URLForObject:videoObj];
        destViewController.answerVideoObj = videoObj;
        
    } else if ([segue.identifier isEqualToString:@"showQuestionFromQuestionDescription"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        QuestionDetailViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.section];
        PFObject *videoObj = [object objectForKey:kActivityTargetVideoKey];
        
        destViewController.movieURL = [PresenticeUtitily s3URLForObject:videoObj];
        destViewController.questionVideoObj = videoObj;
        
    } else if ([segue.identifier isEqualToString:@"showUserFromRegisterDescription"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        UserProfileViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.section];
        PFUser *userObj = [object objectForKey:kActivityFromUserKey];
        
        NSLog(@"user object: %@", userObj);
        destViewController.userObj = userObj;
    }
}
**/
/**
 * segue for table cell
 * click to direct to video play view
 * pass video name, video url
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    if (indexPath.section < [self.objects count] ) {
        PFObject *activityObject = [self.objects objectAtIndex:indexPath.section];
        if ([@[@"answer", @"review"] containsObject:[activityObject objectForKey:kActivityTypeKey]]) {
            PFObject *videoObj = [activityObject objectForKey:kActivityTargetVideoKey];
            if ([[videoObj objectForKey:kVideoVisibilityKey] isEqualToString:@"onlyMe"]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't view video" message:@"This video owner does not allow you to view it. Request her by sending a message" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else if ([[videoObj objectForKey:kVideoVisibilityKey] isEqualToString:@"open"]) {
                VideoViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"videoViewController"];
                destViewController.movieURL = [PresenticeUtitily s3URLForObject:videoObj];
                destViewController.answerVideoObj = videoObj;
                [self.navigationController pushViewController:destViewController animated:YES];
            }
        } else if ([[activityObject objectForKey:kActivityTypeKey] isEqualToString:@"postQuestion"]) {
            QuestionDetailViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"questionDetailViewController"];
            PFObject *videoObj = [activityObject objectForKey:kActivityTargetVideoKey];
            destViewController.movieURL = [PresenticeUtitily s3URLForObject:videoObj];
            destViewController.questionVideoObj = videoObj;
            [self.navigationController pushViewController:destViewController animated:YES];
        } else if ([[activityObject objectForKey:kActivityTypeKey] isEqualToString:@"register"]) {
            UserProfileViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
            destViewController.userObj = [activityObject objectForKey:kActivityFromUserKey];
            [self.navigationController pushViewController:destViewController animated:YES];
        }
    } else {
        [self loadNextPage];
    }
}

- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)showRightMenu:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}

#pragma mark - AmazonServiceRequestDelegate

-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response {
}

- (void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data {
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError called: %@", error);
}

-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception {
    NSLog(@"didFailWithServiceException called: %@", exception);
}

@end