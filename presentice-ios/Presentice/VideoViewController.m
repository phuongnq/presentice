//
//  VideoViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/7/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "VideoViewController.h"

@interface VideoViewController ()

@end

@implementation VideoViewController {
//    NSMutableArray *actionList;
}

@synthesize videoNameLabel;
@synthesize postedUserLabel;
@synthesize viewNumLabel;
@synthesize noteView;

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = kActivityClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = kActivityDescriptionKey;
        
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

    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    //asyn to get profile picture
    [PresenticeUtitily setImageView:self.userProfilePicture forUser:[self.answerVideoObj objectForKey:kVideoUserKey]];
    videoNameLabel.text = [self.answerVideoObj objectForKey:kVideoNameKey];
    postedUserLabel.text = [[self.answerVideoObj objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
    viewNumLabel.text = [PresenticeUtitily stringNumberOfKey:kVideoViewsKey inObject:self.answerVideoObj];
    noteView.text = [NSString stringWithFormat:@"Note for viewer: \n%@",[self.answerVideoObj objectForKey:kVideoNoteKey]];
    [noteView boldSubstring:@"Note for viewer:"];
    
    
    // Set tap gesture on user profile picture
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHandleTapOnImageView)];
    [singleTap setNumberOfTapsRequired:1];
    self.userProfilePicture.userInteractionEnabled = YES;
    [self.userProfilePicture addGestureRecognizer:singleTap];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
#pragma play movie
    // Set up movieController
    self.movieController = [[MPMoviePlayerController alloc] init];
    [self.movieController setContentURL:self.movieURL];
    [self.movieController.view setFrame:CGRectMake(0, 0, 320, 380)];
    [self.videoView addSubview:self.movieController.view];
    
    // Using the Movie Player Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.movieController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterFullScreen:) name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
    
    self.movieController.controlStyle =  MPMovieControlStyleEmbedded;
    self.movieController.shouldAutoplay = YES;
    self.movieController.repeatMode = NO;
    [self.movieController prepareToPlay];
    [self.movieController play];
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
}

- (void)actionHandleTapOnImageView {
    UserProfileViewController *userProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
    userProfileViewController.userObj = [self.answerVideoObj objectForKey:kVideoUserKey];
    [self.navigationController pushViewController:userProfileViewController animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    // If currentUser is not the video's owner
    if (![[[PFUser currentUser] objectId] isEqualToString:[[self.answerVideoObj objectForKey:kVideoUserKey] objectId]]) {
        // Send a "viewed" notification
        if ([[[[self.answerVideoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"viewed"] isEqualToString:@"yes"]) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params setObject:[self.answerVideoObj objectForKey:kVideoNameKey] forKey:@"targetVideo"];
            [params setObject:[[self.answerVideoObj objectForKey:kVideoUserKey] objectId] forKey:@"toUser"];
            [params setObject:@"viewed" forKey:@"pushType"];
            [PFCloud callFunction:@"sendPushNotification" withParameters:params];
        }
        
        
        // Register view activity in to Acitivity Table
        PFQuery *activityQuery = [PFQuery queryWithClassName:kActivityClassKey];
        [activityQuery whereKey:kActivityTypeKey equalTo:@"view"];
        [activityQuery whereKey:kActivityFromUserKey equalTo:[PFUser currentUser]];
        [activityQuery whereKey:kActivityToUserKey equalTo:[self.answerVideoObj objectForKey:kVideoUserKey]];
        [activityQuery whereKey:kActivityTargetVideoKey equalTo:self.answerVideoObj];
        [activityQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                // Found activity record, so just overwrote it
                NSMutableDictionary *views = [[NSMutableDictionary alloc]initWithDictionary:[object objectForKey:kActivityContentKey]];
                [views setObject:@{@"date": [NSDate date]} forKey:[NSString stringWithFormat:@"%d", [[views allKeys] count]]];
                [object setObject:views forKey:kActivityContentKey];
                [object saveInBackground];
            } else {
                // No activity record, so create a new activity
                PFObject *activity = [PFObject objectWithClassName:kActivityClassKey];
                [activity setObject:@"view" forKey:kActivityTypeKey];
                [activity setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
                [activity setObject:[self.answerVideoObj objectForKey:kVideoUserKey] forKey:kActivityToUserKey];
                [activity setObject:self.answerVideoObj forKey:kActivityTargetVideoKey];
                [activity setObject:@{@"0":@{@"date": [NSDate date]}} forKey:kActivityContentKey];
                [activity saveInBackground];
            }
        }];
        
        // Increment views
        int viewsNum = [[self.answerVideoObj objectForKey:kVideoViewsKey] intValue];
        [self.answerVideoObj setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
        PFQuery *query = [PFQuery queryWithClassName:kVideoClassKey];
        [query getObjectInBackgroundWithId:[self.answerVideoObj objectId] block:^(PFObject *object, NSError *error) {
            [object setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
            [object saveInBackground];
        }];
        [self.answerVideoObj saveInBackground];
        NSLog(@"after videoObj = %@", self.answerVideoObj);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void) viewWillDisappear:(BOOL)animated {
    //stop playing video
    if([self.navigationController.viewControllers indexOfObject:self] == NSNotFound){
        //Release any retained subviews of the main view.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTable" object:nil];
        
        //release movie controller
        [self.movieController stop];
        [self.movieController.view removeFromSuperview];
        self.movieController = nil;
    }
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshTable:(NSNotification *) notification {
    // Reload the recipes
    [self loadObjects];
}

/**
- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTable" object:nil];
}
**/

- (PFQuery *)queryForTable {
    PFQuery *reviewListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [reviewListQuery includeKey:kActivityFromUserKey];   // Important: Include "fromUser" key in this query make receiving user info easier
    [reviewListQuery includeKey:kActivityToUserKey];
    [reviewListQuery includeKey:kActivityTargetVideoKey];
    [reviewListQuery whereKey:kActivityTypeKey equalTo:@"review"];
    [reviewListQuery whereKey:kActivityTargetVideoKey equalTo:self.answerVideoObj];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        reviewListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [reviewListQuery orderByDescending:kUpdatedAtKey];
    return reviewListQuery;
}


- (void)moviePlayBackDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}
- (void)willEnterFullScreen:(NSNotification *)notification {
    NSLog(@"Enter full screen mode");
}


#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Reviews of this video";
    } else {
        return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"reviewListIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
    UILabel *userName = (UILabel *)[cell viewWithTag:101];
    UILabel *comment = (UILabel *)[cell viewWithTag:104];
    
    userProfilePicture.image = [UIImage imageWithData:
                                [NSData dataWithContentsOfURL:
                                 [NSURL URLWithString:
                                  [PresenticeUtitily facebookProfilePictureofUser:
                                   [object objectForKey:kActivityFromUserKey]]]]];
    userProfilePicture.layer.cornerRadius = userProfilePicture.frame.size.width / 2;
    userProfilePicture.layer.masksToBounds = YES;
    
    userName.text = [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey];
    comment.text = [object objectForKey:kActivityDescriptionKey];
    
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
}

/**
 * segue for table cell
 * click to direct to video review
 * pass video object
 */

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toReviewView"]) {
        TakeReviewViewController *destViewController = segue.destinationViewController;
        destViewController.videoObj = self.answerVideoObj;
        NSLog(@"sent videoObject = %@", destViewController.videoObj);
    } else if ([segue.identifier isEqualToString:@"showReviewDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ReviewDetailViewController *destViewController = segue.destinationViewController;
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        destViewController.reviewObject = object;
    }
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"toReviewView"]) {
        if ([[[PFUser currentUser] objectId] isEqualToString:[[self.answerVideoObj objectForKey:kVideoUserKey] objectId]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You can not review yourself" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            return NO;
        }
    }
    return YES;
}

@end
