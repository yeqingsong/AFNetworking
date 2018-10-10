// GlobalTimelineViewController.m
//
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "GlobalTimelineViewController.h"

#import "Post.h"

#import "PostTableViewCell.h"
#define defaultPath [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/resume.plist"]

@import AFNetworking;

@interface GlobalTimelineViewController ()
{
    BOOL isResume;
    AFHTTPSessionManager *manager;
//    NSURLSessionDownloadTask *downloadTask;
    int64_t currentData;
    NSString*filePath;
}
@property (readwrite, nonatomic, strong) NSArray *posts;
/** 记录暂停时的数据**/
@property (nonatomic, strong) NSData *resumeData;
/** 创建一个文件管理对象**/
@property (nonatomic, strong) NSFileManager *filemanager;
/** 创建一个字典用来保存数据路径和下载进度**/
@property (nonatomic, strong) NSMutableDictionary *dataDic;

@end

@implementation GlobalTimelineViewController

- (void)reload:(__unused id)sender {
    self.navigationItem.rightBarButtonItem.enabled = NO;

    NSURLSessionTask *task = [Post globalTimelinePostsWithBlock:^(NSArray *posts, NSError *error) {
        if (!error) {
            self.posts = posts;
            [self.tableView reloadData];
        }
    }];

    [self.refreshControl setRefreshingWithStateOfTask:task];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.filemanager = [NSFileManager defaultManager];
    self.title = NSLocalizedString(@"AFNetworking", nil);
//    self.resumeData = [NSMutableData data];
    self.refreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, 100.0f)];
    [self.refreshControl addTarget:self action:@selector(reload:) forControlEvents:UIControlEventValueChanged];
    [self.tableView.tableHeaderView addSubview:self.refreshControl];

    self.tableView.rowHeight = 70.0f;
    self.posts = @[@"12123",@"12123",@"12123",@"12123",@"12123",@"12123",@"12123",@"12123",@"12123",@"12123",@"12123",@"12123",@"12123"];

    /* 创建网络下载对象 */
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.alamofire.iOS-Example"];
    //设置请求超时为10秒钟
    
    configuration.timeoutIntervalForRequest = 30;
    //在蜂窝网络情况下是否继续请求（上传或下载）
    configuration.allowsCellularAccess = YES;
    manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:configuration];
    [self saveDownFile];
    /* 下载地址 */
    NSURL *url = [NSURL URLWithString:@"https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    /* 下载路径 */
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
     filePath = [path stringByAppendingPathComponent:url.lastPathComponent];
//    __weak GlobalTimelineViewController* Wself = self;
    /* 开始请求下载 */
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        // @property int64_t totalUnitCount;  需要下载文件的总大小
        // @property int64_t completedUnitCount; 当前已经下载的大小

        NSLog(@"下载进度：%.0f％", downloadProgress.fractionCompleted * 100);
        self->currentData = downloadProgress.completedUnitCount ;
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        /* 设定下载到的位置 */
        return [NSURL fileURLWithPath:self->filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        NSLog(@"下载完成");
        
    }];
   
    isResume = YES;
   
    
    [downloadTask resume];
    
//    [self reload:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(__unused UITableView *)tableView
 numberOfRowsInSection:(__unused NSInteger)section
{
    return (NSInteger)[self.posts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[PostTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
//    cell.post = self.posts[(NSUInteger)indexPath.row];
    cell.textLabel.text = self.posts[(NSUInteger)indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

//- (CGFloat)tableView:(__unused UITableView *)tableView
//heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return [PostTableViewCell heightForCellWithPost:self.posts[(NSUInteger)indexPath.row]];
//}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (isResume == YES) {
        isResume = NO;
//        [downloadTask suspend];
        for (NSURLSessionDownloadTask *downloadTask in manager.downloadTasks) {
            if (downloadTask.state == NSURLSessionTaskStateRunning) {
                [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    
                    //            self->_resumeData = resumeData;
                    //            [self saveDownFile];
                }];
            }
        }
        
       
        
    }else{
        isResume = YES;
        
       NSData *downLoadHistoryData = [self.dataDic objectForKey:@"https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4"];
        
        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithResumeData:downLoadHistoryData progress:^(NSProgress * _Nonnull downloadProgress) {
            // @property int64_t totalUnitCount;  需要下载文件的总大小
            // @property int64_t completedUnitCount; 当前已经下载的大小
            
            NSLog(@"%f", (float)downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
            // 回到主队列刷新UI
           
            
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) { 
            return  [NSURL fileURLWithPath:self->filePath];
            
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            NSLog(@"下载完成");
        }];
        [downloadTask resume];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)saveDownFile
{
    NSURLSessionDownloadTask *task;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downLoadData:)
                                                 name:AFNetworkingTaskDidCompleteNotification
                                               object:task];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(downLoadData:)
//                                                 name:AFNetworkingTaskDidCompleteNotification
//                                               object:task];
    if ([self.filemanager fileExistsAtPath:defaultPath]) {
        self.dataDic = [NSMutableDictionary dictionaryWithContentsOfFile:defaultPath];
    }else{
        self.dataDic = [NSMutableDictionary dictionary];
        [self.dataDic writeToFile:defaultPath atomically:YES];
    }
    
    
    
    
    
//    //找到下载文件的路径
//    //temp文件夹路径
//    NSString *tempPath = NSTemporaryDirectory();
//    //获取文件夹内所有文件名
//    NSArray *subPaths = [self.filemanager subpathsAtPath:tempPath];
//    //拼接下载的文件路径，下载的文件是在最后一个
//    NSString *downFilePath = [tempPath stringByAppendingPathComponent:[subPaths lastObject]];
//    //caches文件夹
//    NSString *cachesPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[downFilePath lastPathComponent]];
//    //保存一下路径
//    [self.dataDic setObject:cachesPath forKey:@"filePath"];
//    //移动下载文件到caches文件夹
//    [self.filemanager moveItemAtPath:downFilePath toPath:cachesPath error:nil];
//    //保存resumeData，简历数据
//    if (self.resumeData) {
//        [self.dataDic setObject:self.resumeData forKey:@"resumeData"];
//    }
//
//    //保存下载进度
////    self.progressView.progress = 1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount;
//
//    [self.dataDic setObject:[NSNumber numberWithFloat:currentData] forKey:@"progress"];
//
//    [self.dataDic writeToFile:defaultPath atomically:YES];
    
}
-(void)downLoadData:(NSNotification *)Notification{
    if ([Notification.object isKindOfClass:[NSURLSessionDownloadTask class]]) {
        NSURLSessionDownloadTask *task = Notification.object;
        NSString* key = [task.currentRequest.URL absoluteString];
        NSError *error = Notification.userInfo[AFNetworkingTaskDidCompleteErrorKey];
        if (error) {
            if (error.code == -1001) {
                NSLog(@"下载出错,检查网络");
            }
            NSData* data = error.userInfo[NSURLSessionDownloadTaskResumeData];
            if (data) {
                [self.dataDic setObject:data forKey:key];
            }else{
                [self.dataDic setObject:@"" forKey:key];
            }
            ///atomically:NO代表不写入一个临时文件夹,yes先写入临时文件夹成功后在写入defaultPath文件夹
            [self.dataDic writeToFile:defaultPath atomically:NO];
        }else{
            [self.dataDic writeToFile:defaultPath atomically:YES];
        }
    }
}

@end
