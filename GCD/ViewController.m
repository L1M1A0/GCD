//
//  ViewController.m
//  GCD
//
//  Created by LiZhenbiao on 2019/5/2.
//  Copyright © 2019 Lizb. All rights reserved.
//

#import "ViewController.h"
#if DEBUG
#define NSLog(FORMAT, ...) fprintf(stderr,"\n%s line:%d content:%s\n", __FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(FORMAT, ...) nil
#endif

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>{
    NSArray *titles;
}

@end

@implementation ViewController

#pragma mark - UI
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    titles = @[
  @{@"title":@"异步函数 + 并行队列",@"detail":@"开启多条子线程，任务并行执行"},
  @{@"title":@"异步函数 + 串行队列",@"detail":@"开启一条子线程，任务是有序的在子线程上执行"},
  @{@"title":@"异步函数 + 主队列"  ,@"detail":@"不开启子线程，任务是在主线程中有序执行"},
  @{@"title":@"同步函数 + 并行队列",@"detail":@"不会开启子线程，任务是有序执行"},
  @{@"title":@"同步函数 + 串行队列",@"detail":@"不会开启线程，任务是有序执行。易发生死锁，使用时要注意"},
  @{@"title":@"死锁",@"detail":@"场景1，崩溃"},
  @{@"title":@"死锁",@"detail":@"场景2，崩溃"},
  @{@"title":@"GCD实现线程间通信",@"detail":@""},
  @{@"title":@"dispatch_once_t",@"detail":@"保证某段代码在程序运行过程中只被执行1次"},
  @{@"title":@"dispatch_after_and_time",@"detail":@"延迟将任务提交到队列中，不要理解成延迟执行任务"},
  @{@"title":@"dispatch_apply",@"detail":@""},
  @{@"title":@"dispatch_barrier_async",@"detail":@""},
  @{@"title":@"dispatch_group",@"detail":@""},
  @{@"title":@"",@"detail":@""},
  @{@"title":@"",@"detail":@""},
  @{@"title":@"",@"detail":@""},
  @{@"title":@"",@"detail":@""},];
    UITableView *tabel = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    tabel.dataSource = self;
    tabel.delegate = self;
    [self.view addSubview:tabel];
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return titles.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ta  = @"fasgjogjsa";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ta];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ta];
    }
    cell.textLabel.text = titles[indexPath.row][@"title"];
    cell.detailTextLabel.text = titles[indexPath.row][@"detail"];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) { [self asyncConcurrent]; }
    else if (indexPath.row == 1){ [self asyncSerial]; }
    else if (indexPath.row == 2){ [self asyncMain]; }
    else if (indexPath.row == 3){ [self syncConcurrent]; }
    else if (indexPath.row == 4){ [self syncMain]; }
    else if (indexPath.row == 5){ [self deadLock1]; }
    else if (indexPath.row == 6){ [self deadLock2]; }
    else if (indexPath.row == 7){ [self GCDCommunication]; }
    else if (indexPath.row == 8){ [self dispatch_once_1]; }
    else if (indexPath.row == 9){ [self dispatch_after_and_time]; }
    else if (indexPath.row == 10){ [self applyDemo]; }
    else if (indexPath.row == 11){ [self barrierDemo];}
    else if (indexPath.row == 12){ [self dispatch_group];}
    else if (indexPath.row == 13){ }
    else if (indexPath.row == 14){ }
    else if (indexPath.row == 15){ }
    
    NSLog(@"cellTitle：%@",titles[indexPath.row]);
}

#pragma mark - GCD 高级使用总结 https://www.jianshu.com/p/77c5051aede2

#pragma mark GCD 简介 并行队列、 串行队列
/**
 作者：yanhooIT
 链接：https://www.jianshu.com/p/77c5051aede2
 来源：简书
 简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。
 
 //参考文章
 //GCD使用经验与技巧浅谈 https://www.jianshu.com/p/5617ad407678
 //为GCD队列绑定NSObject类型上下文数据-利用__bridge_retained(transfer)转移内存管理权 http://tutuge.me/2015/03/29/bind-data-to-gcd-queue/
 //使用Dispatch Groups来管理多个Web Services请求 https://www.jianshu.com/p/5617ad407678

 
 
 GCD全称：Grand Central Dispatch，译为大型的中枢调度器, 纯C语言实现，提供了非常多强大的功能
 
 GCD的优势：
 GCD是苹果公司为多核的并行运算提出的解决方案
 GCD会自动利用更多的CPU内核（如：双核、四核）
 GCD会自动管理线程的生命周期（创建线程、调度任务、销毁线程）
 程序猿只需要告诉GCD想要执行什么任务，不需要编写任何管理线程的代码
 
 GCD的两个核心概念：任务和队列
 任务：执行什么操作
 队列：用来存放任务，分为：并行队列和串行队列，队列本质：用于控制任务的执行方式
 代码标识：dispatch_queue_t
 
 并行队列
 英文：Concurrent Dispatch Queue
 可以让多个任务并发执行，以提高执行效率，并发功能仅在异步（dispatch_async）函数下才有效
 代码标识： DISPATCH_QUEUE_CONCURRENT
 
 串行队列
 英文：Serial Dispatch Queue
 在当前线程中让任务一个接着一个地执行
 串行队列标识：本质就是NULL，但建议不要写成NULL，可读性不好
 代码标识：DISPATCH_QUEUE_SERIAL
 
 // 队列类型
 // 第一个参数：队列名称
 // 第二个参数：队列类型
 dispatch_queue_create(const char *label, dispatch_queue_attr_t attr);
 
 //创建队列示例：并行队列
 dispatch_queue_t queue = dispatch_queue_create(queueName, DISPATCH_QUEUE_CONCURRENT);

*/

/**
 创建队列 - 并行
 */
-(void)createQueueCONCURRENT{
    
    /**
     方式1 ：直接创建并行队列
     
     // 第一个参数：队列名称
     // 第二个参数：队列类型：并行队列
     */
    dispatch_queue_t queue1 = dispatch_queue_create("yanhooQueue", DISPATCH_QUEUE_CONCURRENT);
    
    /**
     方式2 ：获取全局并发队列
     
     //全局并发队列的优先级
     //DISPATCH_QUEUE_PRIORITY_HIGH 2               // 高
     //DISPATCH_QUEUE_PRIORITY_DEFAULT 0            // 默认(中)
     //DISPATCH_QUEUE_PRIORITY_LOW (-2)             // 低
     //DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN // 后台
     
     // 第一个参数：队列优先级
     // 第二个参数：保留参数，暂时无用，用0即可
     */
    dispatch_queue_t queue2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

/**
 创建队列 - 串行
 */
-(void)createQueueSERIAL{
    /**
     方式1：直接创建一个串型队列
     创建串行队列（队列类型传递DISPATCH_QUEUE_SERIAL或者NULL）
     
     第一个参数：队列名称
     第二个参数：队列类型：并行队列
     */
    dispatch_queue_t queue1 = dispatch_queue_create("yanhooQueue", DISPATCH_QUEUE_SERIAL);

    /**
     获取主队列：主队列是一种特殊的串行队列
     主队列中的任务，都会放到主线程中执行
     */
    dispatch_queue_t queue2 = dispatch_get_main_queue();
}
#pragma mark - GCD 简介  异步(async)函数 和 同步(sync)函数
#pragma mark GCD 异步(async)函数
/**
 同步(sync)函数 和 异步(async)函数
 
 函数作用：将任务添加到队列中
 函数类型：决定是否有开启新线程的能力

 同步函数：不具备开启新线程的能力，只能在当前线程中执行任务
 // queue：队列。block：任务
 dispatch_sync(dispatch_queue_t queue, dispatch_block_t block);
 
 异步函数：具备开启线程的能力，但不一定开启新线程，比如：当前队列为主队列，异步函数也不会开启新的线程
 // queue：队列。block：任务
 dispatch_async(dispatch_queue_t queue, dispatch_block_t block);

 经验总结：
 1. 通过异步函数添加任务到队列中，任务不会立即执行
 2. 通过同步函数添加任务到队列中，任务会立即执行

 程序猿只需要做下列事情，剩下的事情就交给GCD来完成了：
 1. 指定函数类型：是否具备开启新线程的能力
 2. 指定队列类型：决定任务的执行方式
 3. 确定要执行的任务，并通过函数将任务添加到队列中，任务的执行遵循队列的FIFO原则：先进先出，后进后出
 
 函数和队列组合后的执行效果：
             并发队列     手动创建的串行队列         主队列
———————————————————————————————————————————————————————————————
 同步（sync) :  没有           没有                没有           | 是否开启新线程
               串行           串行                串行           | 执行任务的方式or类型
———————————————————————————————————————————————————————————————
 异步(async):   有             有                 没有           | 是否开启新线程
               并发           串行                串行           | 执行任务的方式or类型
———————————————————————————————————————————————————————————————
 注：1. 异步+并发队列：适用于多个任务并发执行
    2. 异步+串行队列：适用于，当任务有先后顺序要求时，只会开启一个子线程
 */

/**
 异步函数 + 并行队列
 开启多条子线程，任务并行执行
 */
- (void)asyncConcurrent
{
    // 1.创建并行队列
    //    dispatch_queue_t queue = dispatch_queue_create("yanhooQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // 2.通过异步函数将将任务加入队列
    dispatch_async(queue, ^{
        for (NSInteger i = 0; i<10; i++) {
            NSLog(@"异步函数 + 并行队列——1：%@", [NSThread currentThread]);
        }
    });
    dispatch_async(queue, ^{
        for (NSInteger i = 0; i<10; i++) {
            NSLog(@"异步函数 + 并行队列——2：%@", [NSThread currentThread]);
        }
    });
    dispatch_async(queue, ^{
        for (NSInteger i = 0; i<10; i++) {
            NSLog(@"异步函数 + 并行队列——3：%@", [NSThread currentThread]);
        }
    });
    
    // 证明：异步函数添加任务到队列中，任务【不会】立即执行
    NSLog(@"异步函数 + 并行队列--end");
    
    // 释放队列，ARC中无需也不允许调用这个方法
    //dispatch_release(queue);
}

/**
 异步函数 + 串行队列
 开启一条子线程，任务是有序的在子线程上执行
 */
- (void)asyncSerial
{
    // 1.创建串行队列
    dispatch_queue_t queue = dispatch_queue_create("yanhooQueue", DISPATCH_QUEUE_SERIAL);
    //    dispatch_queue_t queue = dispatch_queue_create("yanhooQueue", NULL);
    
    // 2.通过异步函数将任务加入队列
    dispatch_async(queue, ^{
        NSLog(@"异步函数 + 串行队列——1：%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"异步函数 + 串行队列——2：%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"异步函数 + 串行队列——3：%@", [NSThread currentThread]);
    });
    
    // 证明：异步函数添加任务到队列中，任务【不会】立马执行
    NSLog(@"异步函数 + 串行队列——----end");
}

/**
 异步函数 + 主队列
 不开启子线程，任务是在主线程中有序执行
 */
- (void)asyncMain
{
    // 1.获得主队列
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    // 2.通过异步函数将任务加入队列
    dispatch_async(queue, ^{
        NSLog(@"异步函数 + 主队列——1：%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"异步函数 + 主队列——2：%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"异步函数 + 主队列——3：%@", [NSThread currentThread]);
    });
}

#pragma mark GCD 简介 同步(sync)函数

/**
 同步函数 + 并行队列
 不会开启子线程，任务是有序执行
 */
- (void)syncConcurrent
{
    // 1.获得全局的并发队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // 2.通过同步函数将任务加入队列
    dispatch_sync(queue, ^{
        NSLog(@"同步函数 + 并行队列——1：%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"同步函数 + 并行队列——2：%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"同步函数 + 并行队列——3：%@", [NSThread currentThread]);
    });
    
    // 证明：同步函数添加任务到队列中，任务【立马执行】
    NSLog(@"同步函数 + 并行队列——end");
}

/**
 同步函数 + 串行队列
 不会开启线程，任务是有序执行。易发生死锁，使用时要注意

 下面的用法会发生死锁吗？
 答案：上面的用法不会发生死锁，原因分析如下：
 
 虽然都是在主线程上执行的，但任务在不同的队列中所以不会发生阻塞
 syncMain函数是在主队列中，其他的任务是在新建的串行队列中
 */
- (void)syncMain
{
    // 1.创建串行队列
    dispatch_queue_t queue = dispatch_queue_create("yanhooQueue", DISPATCH_QUEUE_SERIAL);
    
    // 2.将任务加入队列
    dispatch_sync(queue, ^{
        NSLog(@"同步函数 + 串行队列——1：%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"同步函数 + 串行队列——2：%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"同步函数 + 串行队列——3：%@", [NSThread currentThread]);
    });
    NSLog(@"同步函数 + 串行队列——end");

}


#pragma mark GCD 简介 同步(sync)函数 死锁场景示例
/**
 死锁的几种场景 场景1
 */
-(void)deadLock1{

    dispatch_queue_t queue = dispatch_queue_create("yanhooQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(queue, ^{
        NSLog(@"deadLock1——1：%@", [NSThread currentThread]);
        
        // 这里阻塞了
        dispatch_sync(queue, ^{
            NSLog(@"deadLock1——2：%@", [NSThread currentThread]);
        });
    });
    NSLog(@"deadLock1——end");
}

/**
 死锁的几种场景 场景2
 
 原因分析
 使用同步函数在任务执行过程中往任务所在的串行队列中添加任务就会导致任务间互相等待，造成死锁
 别忘了同步函数添加任务到队列中，任务会立即执行，如果是异步函数就不会发生死锁
 */
-(void)deadLock2{
    // 获得主队列
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    // 这里阻塞了
    dispatch_sync(queue, ^{
        NSLog(@"deadLock2——1-----%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"deadLock2——2-----%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"deadLock2——3-----%@", [NSThread currentThread]);
    });
    NSLog(@"deadLock2——end");
}


#pragma mark GCD实现线程间通信
-(void)GCDCommunication{
    // 全局并发队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // 异步函数
    dispatch_async(queue, ^ {
        NSLog(@"GCD实现线程间通信，执行耗时的任务,coding...1");
        //【标记1】回到主线程，执行UI刷新操作
    //【标记1】处也可以用同步函数回到主线程，但是同步函数会导致添加的新任务立即执行，导致必须等添加到主队列的任务执行完才会继续执行，也不是不能这么用，看具体场景是否需要等待主队列的任务执行完毕才继续往后执行
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSLog(@"GCD实现线程间通信，coding...2");
            // 还可以嵌套：再回到子线程做其他事情
            dispatch_async(queue, ^ {
                NSLog(@"GCD实现线程间通信，coding...3");
            });
        });
        NSLog(@"GCD实现线程间通信，coding...4");
    });
    NSLog(@"GCD实现线程间通信，coding...5");

}


#pragma mark - GCD中其他常用函数
#pragma mark dispatch_once_t
/**
 dispatch_once_t
 函数作用：保证某段代码在程序运行过程中只被执行1次
 */
-(void)dispatch_once_1{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 只执行1次的代码(这个函数本身是【线程安全】的)
        NSLog(@"dispatch_once: 只执行1次的代码");
    });
}

#pragma mark dispatch_after和dispatch_time_t
/**
 函数作用：延迟将任务提交到队列中，不要理解成延迟执行任务
 */
-(void)dispatch_after_and_time{
    
    /**
     dispatch_time_t
     第一个参数一般是DISPATCH_TIME_NOW，表示从现在开始
     第二个参数就是真正的延时时间，单位为纳秒
     关于NSEC_PER_SEC的解释可以查看我这篇文章 https://www.jianshu.com/p/29af03f87d86
     */
    dispatch_queue_t queue = dispatch_queue_create("rara", DISPATCH_QUEUE_CONCURRENT);
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
    dispatch_after(time, queue, ^ {
        // 此任务被延迟提交到队列中
        NSLog(@"dispatch_after_and_time_5");
    });
}

#pragma mark dispatch_suspend 和 dispatch_resume
/**
 dispatch_suspend
 函数作用：只能挂起队列中还未执行的任务，正在运行的任务是无法挂起的
 
 dispatch_resume
 函数作用：只能恢复队列中还未执行的任务
 */

#pragma mark dispatch_apply
/**
 dispatch_apply
 
 此函数和dispatch_sync函数一样，会等待处理结束，所以建议在dispatch_async中使用此函数
 此函数必须结合并行队列才能发挥作用
 函数作用：可以快速完成对顺序没有要求的集合遍历，因为执行顺序不确定
 使用说明
 */
- (void)applyDemo {
//    dispatch_apply(10, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
//        // 执行10次代码，会开启多条线程来执行任务，执行顺序不确定
//    });
    
    //示例：文件剪切
    NSString *from = @"/Users/xxx/Desktop/From";
    NSString *to = @"/Users/xxx/Desktop/To";
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSArray *subpaths = [mgr subpathsAtPath:from];
    
    // 并行队列才会起作用
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply(subpaths.count, queue, ^(size_t index) {
        NSString *subpath = subpaths[index];
        NSString *fromFullpath = [from stringByAppendingPathComponent:subpath];
        NSString *toFullpath = [to stringByAppendingPathComponent:subpath];
        // 剪切
        [mgr moveItemAtPath:fromFullpath toPath:toFullpath error:nil];
        
        NSLog(@"%@---%@", [NSThread currentThread], subpath);
    });
}

#pragma mark dispatch_barrier_async
/**
 dispatch_barrier_async
 
 必须是并行队列，且不能使用全局的并行队列，实践证明不管用
 函数作用：在此函数前面的任务执行完成后此函数才开始执行，在此函数后面的任务等此函数执行完成后才会执行
 */
- (void)barrierDemo
{
    //【不能】使用全局并发队列
    dispatch_queue_t queue = dispatch_queue_create("yanhooQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        NSLog(@"dispatch_barrier_async--1：%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"dispatch_barrier_async--2：%@", [NSThread currentThread]);
    });
    
    // 在它前面的任务执行结束后它才执行，在它后面的任务等它执行完成后才会执行
    dispatch_barrier_async(queue, ^{
        NSLog(@"dispatch_barrier_async-barrier：%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"dispatch_barrier_async--3：%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"dispatch_barrier_async--4：%@", [NSThread currentThread]);
    });
}

#pragma mark - dispatch_group

/**
 dispatch_group
 必须是并行队列才起作用
 需求描述
 
 现有三个任务：任务A、任务B、任务C
 任务C需要等到任务A和任务B都完成后才执行
 任务A和任务B执行没有先后顺序
 
 使用dispatch_group可以实现上面的需求
 // 创建队列组 dispatch_group_t
 dispatch_group_t group =  dispatch_group_create();
 
 添加任务分两种情况：
 自己可以控制并创建队列，使用dispatch_group_async
 
 //1. 省去创建group、queue代码......
 dispatch_group_async(group, queue, ^{
 // 添加任务A到group
 });
 
 dispatch_group_async(group, queue, ^{
 // 添加任务B到group
 });
 
 2. 无法控制队列，即使用的队列不是你创建的（如：AFNetworking异步添加任务），此时可以使用dispatch_group_enter，dispatch_group_leave控制任务的执行顺序
 
 - (void)type2{
     // 使用dispatch_group_enter，dispatch_group_leave可以方便的将一系列网络请求打包起来
     AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
 
     // 添加任务A到group
     // ---打标记---
     dispatch_group_enter(group);
     [manager GET:@"http://www.baidu.com" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
             // do something
 
             // ---删除标记---
             dispatch_group_leave(group);
 
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // do something
             // ---删除标记---
             dispatch_group_leave(group);
     }];
 
     // 添加任务B到group类似上面的操作
 }
 
 添加结束任务也分为两种情况:
 1. dispatch_group_notify（推荐）：不会阻塞当前线程，马上返回
 dispatch_group_notify(group, dispatch_get_main_queue(), ^ {
    // do something
 });
 
 
 2. dispatch_group_wait（不推荐）：阻塞当前线程，直到dispatch group中的所有任务完成才会返回
 // 第二个参数是超时时间
 dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
 
 //完整示例如下：
 */
-(void)dispatch_group{
    
    // 创建队列组
    dispatch_group_t group =  dispatch_group_create();
    
    // 获取全局并发队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // 添加任务A到group
    dispatch_group_async(group, queue, ^{
        // 添加任务A到group
        NSLog(@"添加任务A到group--1：%@", [NSThread currentThread]);

    });
    
    // 添加任务B到group
    dispatch_group_async(group, queue, ^{
        // 添加任务B到group
        NSLog(@"添加任务B到group--2：%@", [NSThread currentThread]);
    });
    
    // 当任务A和任务B都执行完后到此来执行任务C
    dispatch_group_notify(group, queue, ^{
        // 如果这里还有基于上面两个任务的结果继续执行一些代码，建议还是放到子线程中，等代码执行完毕后在回到主线程
        NSLog(@"添加任务C到group--3：%@", [NSThread currentThread]);

        // 回到主线程
//        dispatch_async(group, dispatch_get_main_queue(), ^ {
//            // 执行相关UI显示代码...
//        });
    });
 
}



#pragma mark dispatch_set_context与dispatch_set_finalizer_f的配合使用

/**
 
 函数作用：为队列设置任意类型的数据，并在合适的时候取出来用
 函数定义
 
 // 设置context
 void dispatch_set_context(dispatch_object_t object, void *context);
 
 // 获取context
 void* dispatch_get_context(dispatch_object_t object);
 
 参数介绍:
 第一个参数object：一般指通过dispatch_queue_create创建的队列
 
 dispatch_set_context函数完成了将context绑定到指定的GCD队列上
 dispatch_get_context函数完成了从指定的GCD队列获取对应的context
 context是一个void类型指针，学过C语言的朋友应该都知道，void类型指针可以指向任意类型，context在这里可以是任意类型的指针
 
 补充：Foundation对象 和 Core Foundation对象间的转换，俗称桥接，请查看这篇文章
 https://www.jianshu.com/p/47a6fa134a27

 完整示例
 
 @interface Data : NSObject
 @property(assign, nonatomic) int number;
 @end
 
 @implementation Data
 
 // 便于观察对象何时被释放
 - (void)dealloc
 {
    NSLog(@"Data dealloc...");
 }
 
 @end

 -----------------------------------------------------------------------------------------
 
 // 定义队列的finalizer函数，用于释放context内存
 void cleanStaff(void *context) {
     // 这里用__bridge转换，不改变内存管理权
     Data *data = (__bridge Data *)(context);
     NSLog(@"In clean, context number: %d", data.number);
 
     // 释放context的内存！
     CFRelease(context);
 }
 
 - (void)testBody
 {
     // 创建队列
     dispatch_queue_t queue = dispatch_queue_create("yanhooQueue", DISPATCH_QUEUE_CONCURRENT);
 
     // 创建Data类型context数据并初始化
     Data *myData = [Data new];
     myData.number = 10;
 
     // 绑定context
     // 这里用__bridge_retained将OC对象转换为C对象，将context的内存管理权从ARC移除，交由我们自己手动释放！
     dispatch_set_context(queue, (__bridge_retained void *)(myData));
 
     // 设置finalizer函数，用于在队列执行完成后释放对应context内存
     dispatch_set_finalizer_f(queue, cleanStaff);
 
     dispatch_async(queue, ^ {
         // 获取队列的context数据
         // 这里用__bridge将C对象装换为OC对象转换，并没有改变内存管理权
         Data *data = (__bridge Data *)(dispatch_get_context(queue));
         // 打印
         NSLog(@"1: context number: %d", data.number);
         // 修改context保存的数据
         data.number = 20;
     });
 }

 
 */


@end
