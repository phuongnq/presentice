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
    AmazonS3Client *s3Client;
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (PFQuery *)queryForTable {
    PFQuery *activitiesQuery = [PFQuery queryWithClassName:self.parseClassName];
    [activitiesQuery whereKey:kActivityTypeKey containedIn:@[@"answer", @"review", @"postQuestion", @"register"]];
    [activitiesQuery includeKey:kActivityFromUserKey];
    [activitiesQuery includeKey:kActivityTargetVideoKey];
    [activitiesQuery includeKey:@"targetVideo.user"];
    [activitiesQuery includeKey:@"targetVideo.asAReplyTo"];
    [activitiesQuery includeKey:@"targetVideo.toUser"];
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

#pragma table methods
/**
 * delegage method
 * number of rows of table
 */

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"answer"] ) {
        return 90;
    } else if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"review"]) {
        return 120;
    } else if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"postQuestion"]) {
        return 120;
    } else if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"register"]) {
        return 72;
    } else {
        return 120;
    }
}

/**
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.objects count];
}
**/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    
    if ([[object objectForKey:kActivityTypeKey] isEqualToString:@"answer"]) {
        NSString *simpleTableIdentifier = @"answerListIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        
        // Configure the cell
        UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
        UILabel *description = (UILabel *)[cell viewWithTag:101];
        UILabel *activityType = (UILabel *)[cell viewWithTag:102];
        UILabel *viewsNum = (UILabel *)[cell viewWithTag:103];
        
        //asyn to get profile picture
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *profileImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[Constants facebookProfilePictureofUser:[object objectForKey:kActivityFromUserKey]]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                userProfilePicture.image = [UIImage imageWithData:profileImageData];
            });
        });

        description.text = [NSString stringWithFormat:@"%@ has posted %@!",
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                            [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
        activityType.text = [NSString stringWithFormat:@"%@", [object objectForKey:kActivityTypeKey]];
        viewsNum.text = [NSString stringWithFormat:@"view: %@",[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoViewsKey]];
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
        UILabel *activityType = (UILabel *)[cell viewWithTag:102];
        UILabel *comment = (UILabel *)[cell viewWithTag:103];
        UILabel *answerVideoName = (UILabel *)[cell viewWithTag:104];
        
        userProfilePicture.image = [UIImage imageWithData:
                                    [NSData dataWithContentsOfURL:
                                     [NSURL URLWithString:
                                      [Constants facebookProfilePictureofUser:
                                       [object objectForKey:kActivityFromUserKey]]]]];
        
        description.text = [NSString stringWithFormat:@"%@ has reviewed %@'s%@!",
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                            [[object objectForKey:kActivityToUserKey] objectForKey:kUserDisplayNameKey],
                            [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
        activityType.text = [NSString stringWithFormat:@"%@", [object objectForKey:kActivityTypeKey]];
        comment.text = [object objectForKey:kActivityDescriptionKey];
        answerVideoName.text = [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey];
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
        UILabel *activityType = (UILabel *)[cell viewWithTag:102];
        UILabel *comment = (UILabel *)[cell viewWithTag:103];
        UILabel *questionVideoName = (UILabel *)[cell viewWithTag:104];
        
        userProfilePicture.image = [UIImage imageWithData:
                                    [NSData dataWithContentsOfURL:
                                     [NSURL URLWithString:
                                      [Constants facebookProfilePictureofUser:
                                       [object objectForKey:kActivityFromUserKey]]]]];
        
        description.text = [NSString stringWithFormat:@"%@ has posted a new question %@!",
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                            [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
        activityType.text = [NSString stringWithFormat:@"%@", [object objectForKey:kActivityTypeKey]];
        comment.text = [object objectForKey:kActivityDescriptionKey];
        questionVideoName.text = [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey];
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
        
        userProfilePicture.image = [UIImage imageWithData:
                                    [NSData dataWithContentsOfURL:
                                     [NSURL URLWithString:
                                      [Constants facebookProfilePictureofUser:
                                       [object objectForKey:kActivityFromUserKey]]]]];
        
        description.text = [NSString stringWithFormat:@"%@ has joined Presentice!",
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]];
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

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showAnswerfromAnswerDescription"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        VideoViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        PFObject *videoObj = [object objectForKey:kActivityTargetVideoKey];
        
        destViewController.movieURL = [self s3URL:[Constants transferManagerBucket] :videoObj];
        NSLog(@"video url: %@", [self s3URL:[Constants transferManagerBucket] :videoObj]);
        NSLog(@"answer video object: %@", videoObj);
        destViewController.answerVideoObj = videoObj;
    } else if ([segue.identifier isEqualToString:@"showAnswerFromReviewDescription"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        VideoViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        PFObject *videoObj = [object objectForKey:kActivityTargetVideoKey];
        
        destViewController.movieURL = [self s3URL:[Constants transferManagerBucket] :videoObj];
        NSLog(@"video url: %@", [self s3URL:[Constants transferManagerBucket] :videoObj]);
        NSLog(@"answer video object: %@", videoObj);
        destViewController.answerVideoObj = videoObj;
    } else if ([segue.identifier isEqualToString:@"showQuestionFromQuestionDescription"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        QuestionDetailViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        PFObject *videoObj = [object objectForKey:kActivityTargetVideoKey];
        
        destViewController.movieURL = [self s3URL:[Constants transferManagerBucket] :videoObj];
        NSLog(@"video url: %@", [self s3URL:[Constants transferManagerBucket] :videoObj]);
        NSLog(@"answer video object: %@", videoObj);
        destViewController.questionVideoObj = videoObj;
    } else if ([segue.identifier isEqualToString:@"showUserFromRegisterDescription"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        UserProfileViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        PFUser *userObj = [object objectForKey:kActivityFromUserKey];
        
        NSLog(@"answer video object: %@", userObj);
        destViewController.userObj = userObj;
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

#pragma Amazon implemented methods

/**
 * get the URL from S3
 * param: bucket name
 * param: Parse Video object (JSON)
 * This one is the modified one of the commented-out above
 **/

- (NSURL*)s3URL: (NSString*)bucketName :(PFObject*)object {
    // Init connection with S3Client
    s3Client = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
    @try {
        // Set the content type so that the browser will treat the URL as an image.
        S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
        override.contentType = @" ";
        // Request a pre-signed URL to picture that has been uplaoded.
        S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
        // Video name
        gpsur.key = [NSString stringWithFormat:@"%@", [object objectForKey:kVideoURLKey]];
        //bucket name
        gpsur.bucket  = bucketName;
        // Added an hour's worth of seconds to the current time.
        gpsur.expires = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600];
        
        gpsur.responseHeaderOverrides = override;
        
        // Get the URL
        NSError *error;
        NSURL *url = [s3Client getPreSignedURL:gpsur error:&error];
        return url;
    }
    @catch (NSException *exception) {
        NSLog(@"Cannot list S3 %@",exception);
    }
}

@end