//
//  Database.m
//  DatabaseConnectivity
//
//  Created by jetani kalpesh on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Database.h"
#import <UIKit/UIKit.h>

@implementation Database
@synthesize ObjDB;

static Database *singleton = nil;

- (id)init {
    static BOOL initialized = NO;
    if (!initialized) {
        self = [super init];
        singleton = self;
        initialized = YES;
        
    }
    return self;
}

+ (Database *)sharedInstance
{
    if (!singleton)
        singleton =[[Database alloc] init];
    return singleton;
}

+(NSString*) GetDatabasePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) ;
    NSString *documentsDirectory = [paths objectAtIndex:0] ;
	return [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",kDatabaseName,kDatabaseExt]];
}

+(void)copyDatabaseFileToCachePath {
    
    NSString *databaseFile = [[NSBundle mainBundle] pathForResource:kDatabaseName ofType:kDatabaseExt];
    
    NSString *dbPath=[Database GetDatabasePath];
    
    NSFileManager *fm=[NSFileManager defaultManager];
    
    if(![fm fileExistsAtPath:dbPath])
    {
        [fm copyItemAtPath:databaseFile toPath:dbPath error:nil];
    }
    
}


-(NSDictionary *)lookupRowForSQL:(NSString *)sql
{
	
    if(sqlite3_open([[Database GetDatabasePath]UTF8String], &ObjDB)!=SQLITE_OK)
    {
        sqlite3_close(ObjDB);
        //KK
        //NSAssert(0, @"Failed to open database");
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to open database" message:@"Database path is Wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        //[alert show];
        return nil;
    }
    
    sqlite3_stmt *statement;
	id result;
	NSMutableDictionary *thisDict = [NSMutableDictionary dictionary];
    
	if ((statement = [self prepare:sql])) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			for (int i = 0 ; i < sqlite3_column_count(statement) ; i++)
            {
                
                if (sqlite3_column_decltype(statement,i) != NULL &&
					strcasecmp(sqlite3_column_decltype(statement,i),"Boolean") == 0)
                {
					result = [NSNumber numberWithBool:(BOOL)sqlite3_column_int(statement,i)];
				}
                else if (sqlite3_column_type(statement, i) == SQLITE_TEXT)
                {
					result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)];
				}
                else if (sqlite3_column_type(statement,i) == SQLITE_INTEGER)
                {
					result = [NSNumber numberWithInt:(int)sqlite3_column_int(statement,i)];
				}
                else if (sqlite3_column_type(statement,i) == SQLITE_FLOAT)
                {
					result = [NSNumber numberWithFloat:(float)sqlite3_column_double(statement,i)];
				}
                else if (sqlite3_column_type(statement, i) == SQLITE_BLOB)
                {
                    int length = sqlite3_column_bytes(statement, i);
                    result = [NSData dataWithBytes:sqlite3_column_blob(statement, i) length:length];
                }
                
                else
                {
					const unsigned char *tempresult = sqlite3_column_text(statement, i);
					if(tempresult==NULL)
						result=@"";
					else
						result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)];
				}
                
				if (result)
                {
					[thisDict setObject:result
								 forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement,i)]];
				}
			}
		}
	}
	sqlite3_finalize(statement);
    sqlite3_close(ObjDB);
    
	return thisDict;
}

- (NSMutableArray *)lookupAllForSQL:(NSString *)sql
{
    if(sqlite3_open([[Database GetDatabasePath]UTF8String], &ObjDB)!=SQLITE_OK){
        sqlite3_close(ObjDB);
        //KK
        //NSAssert(0, @"Failed to open database");
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to open database" message:@"Database path is Wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        //[alert show];
        return nil;
    }
    
	sqlite3_stmt *statement;
	id result;
	
	NSString *path = [Database GetDatabasePath];
	
	NSMutableArray *thisArray = [NSMutableArray array];
	if(sqlite3_open([path UTF8String], &ObjDB) == SQLITE_OK)
	{
        if ((statement = [self prepare:sql])) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSMutableDictionary *thisDict = [NSMutableDictionary dictionary];
                
                for (int i = 0 ; i < sqlite3_column_count(statement) ; i++) {
                    
                    if (sqlite3_column_decltype(statement,i) != NULL &&
                        strcasecmp(sqlite3_column_decltype(statement,i),"Boolean") == 0) {
                        result = [NSNumber numberWithBool:(BOOL)sqlite3_column_int(statement,i)];
                    } else if (sqlite3_column_type(statement, i) == SQLITE_TEXT) {
                        result = [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    } else if (sqlite3_column_type(statement,i) == SQLITE_INTEGER) {
                        result = [NSNumber numberWithInt:(int)sqlite3_column_int(statement,i)];
                    } else if (sqlite3_column_type(statement,i) == SQLITE_FLOAT) {
                        result = [NSNumber numberWithFloat:(float)sqlite3_column_double(statement,i)];
                    } else if (sqlite3_column_type(statement, i) == SQLITE_BLOB){
                        int length = sqlite3_column_bytes(statement, i);
                        result = [NSData dataWithBytes:sqlite3_column_blob(statement, i) length:length];
                    }
                    
                    else {
                        const unsigned char *tempresult = sqlite3_column_text(statement, i);
                        if(tempresult==NULL)
                            result=@"";
                        else
                            result = [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    }
                    
                    if (result)
                    {
                        [thisDict setObject:result
                                     forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement,i)]];
                    }
                }
                
                [thisArray addObject:[NSMutableDictionary dictionaryWithDictionary:thisDict]];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(ObjDB);
	}
	
	return thisArray;
}

- (sqlite3_stmt *)prepare:(NSString *)sql
{
    //NSLog(@"\n\n%@\n\n\n\n",sql);
	const char *utfsql = [sql UTF8String];
	sqlite3_stmt *statement;
	
	if (sqlite3_prepare_v2([self ObjDB],utfsql,-1,&statement,NULL) == SQLITE_OK) {
		return statement;
	} else {
		NSLog(@"STATEMENT:%@ \nError while creating add statement.'%s'", sql,sqlite3_errmsg(ObjDB));
		return 0;
	}
}

+(BOOL)lookupChangeForSQL:(NSString *)sql
{
    
    BOOL isTransComplete = NO;
    NSString *str = sql;
    sqlite3 *database;
    
    if(sqlite3_open([[Database GetDatabasePath] UTF8String],&database) == SQLITE_OK) {
        
        sqlite3_stmt *cmp_sqlStmt;
        
        // converting query to UTF8string.
        const char *sqlStmt=[str UTF8String];
        
        // preparing for execution of statement.
        if(sqlite3_prepare_v2(database, sqlStmt, -1, &cmp_sqlStmt, NULL)==SQLITE_OK) {
            BOOL isStatementPrepared = sqlite3_prepare_v2(database, sqlStmt, -1, &cmp_sqlStmt, NULL);
            
            if (isStatementPrepared == SQLITE_OK)
            {
                NSLog(@"Success");
                unsigned int isTransactionCompleted = sqlite3_step(cmp_sqlStmt);
                //SQLITE_BUSY, SQLITE_DONE, SQLITE_ROW, SQLITE_ERROR, or SQLITE_MISUSE.
                if (isTransactionCompleted == SQLITE_BUSY) {
                    NSLog(@"\n\n\n##ERROR :: DATABASE :: SQLITE_BUSY\n\n\n");
                } else if (isTransactionCompleted == SQLITE_DONE) {
                    NSLog(@"\n\n\n##ERROR :: DATABASE :: SQLITE_DONE\n\n\n");
                } else if (isTransactionCompleted == SQLITE_ROW) {
                    NSLog(@"\n\n\n##ERROR :: DATABASE :: SQLITE_ROW\n\n\n");
                } else if (isTransactionCompleted == SQLITE_ERROR) {
                    NSLog(@"\n\n\n##ERROR :: DATABASE :: SQLITE_ERROR\n\n\n");
                } else if (isTransactionCompleted == SQLITE_MISUSE) {
                    NSLog(@"\n\n\n##ERROR :: DATABASE :: SQLITE_MISUSE\n\n\n");
                }
                isTransComplete = TRUE;
            }
            else
            {
                NSLog(@"UnSuccess");
                NSLog(@"\n\n\n&&&&&&&&&&& ERROR :###: Preparing Statement &&&&&&&&&&&\n\n\n");
            }
        }
        sqlite3_finalize(cmp_sqlStmt);
    }
    
    sqlite3_close(database);
    
    return isTransComplete;
}

/*
 1.0 Storage Classes and Datatypes
 
 Each value stored in an SQLite database (or manipulated by
 the database engine) has one of the following storage classes:
 
 NULL.      The value is a NULL value.
 
 INTEGER.   The value is a signed integer, stored in 1, 2, 3, 4, 6,
 or 8 bytes depending on the magnitude of the value.
 
 REAL.      The value is a floating point value, stored as an 8-byte
 IEEE floating point number.
 
 TEXT.      The value is a text string, stored using the database
 encoding (UTF-8, UTF-16BE or UTF-16LE).
 
 BLOB.      The value is a blob of data, stored exactly as
 it was input.
 
 */


+(BOOL)lookupChangeForSQLDictionary:(NSDictionary *)dictSql insertOrUpdate:(NSString *)DML ClauseAndCondition:(NSString *)ClauseAndCondition TableName:(NSString *)tblName
{
    //NSLog(@"dict Sql == >> %@\n\n",dictSql);

    NSArray *arrKeys = [[NSArray alloc]initWithArray:[dictSql allKeys]];
    
    NSMutableArray *arrBlob_data = [[NSMutableArray alloc] init];
    NSMutableArray *arrBlob_name = [[NSMutableArray alloc] init];
    
    NSMutableArray *arrColumnName = [[NSMutableArray alloc] init];
    NSMutableArray *arrColumnValue = [[NSMutableArray alloc] init];
    
    for (int k=0; k<[arrKeys count]; k++)
    {
        NSString *key = [arrKeys objectAtIndex:k];
        id obj = [dictSql objectForKey:key];
    
    // #### TESTING OBJECT LOG ####
    //NSLog(@"== Key == >> %@",key);
    //if ([obj isKindOfClass:[UIImage class]] || [obj isKindOfClass:[NSData class]])
    //{
    //      NSLog(@"== obj == >> Object is NOT NIL");
    //}
    //else
    //{
    //    NSLog(@"== obj == >> %@",obj);
    //}
        
        
        if ([obj isKindOfClass:[NSString class]])
        {
            // TESTED OK //KK
            
            NSString *string = (NSString *)obj;
            [arrColumnName addObject:key];
            [arrColumnValue addObject:[Database stringByReplaceQueryQuoteAndBindQuote:string]];
        }
        else if ([obj isKindOfClass:[UIImage class]]) 
        {
            // TESTED OK //KK
            
            UIImage *image = (UIImage *)obj;
            NSData *imgData = UIImagePNGRepresentation(image);
            if (imgData == Nil || [imgData isEqual:[NSNull null]] )
            {
                imgData = UIImageJPEGRepresentation(image, 0.9);//Compression qulaity..
                if (imgData.length == 0 || imgData == Nil || [imgData isEqual:[NSNull null]] )
                {
                    [arrBlob_data addObject:@""];
                    [arrBlob_name addObject:key];
                }
                else
                {
                    [arrBlob_data addObject:imgData];
                    [arrBlob_name addObject:key];
                }
            }
            else
            {
                [arrBlob_data addObject:imgData];
                [arrBlob_name addObject:key];
            }
        }
        else if ([obj isKindOfClass:[NSData class]]) 
        {
            // TESTED OK //KK
            
            NSData *imgData = (NSData *)obj;
            if (imgData.length ==0 || imgData == Nil || [imgData isEqual:[NSNull null]] )
            {
                [arrBlob_data addObject:@""];
                [arrBlob_name addObject:key];
            }
            else
            {
                [arrBlob_data addObject:imgData];
                [arrBlob_name addObject:key];
            }
        }
        else if ([obj isKindOfClass:[NSNumber class]])
        {
#warning not Tested Function for NSNumber
            
            if (CFNumberIsFloatType ((CFNumberRef)obj)) 
            {
                // FLOAT & LONG VALUES
                long long fval = [obj longLongValue];
                [arrColumnName addObject:key];
                [arrColumnValue addObject:[NSString stringWithFormat:@"%lld",fval]];
            }
            else  
            {
                // INT & BOOL VALUES
                int fval = [obj intValue];
                [arrColumnName addObject:key];
                [arrColumnValue addObject:[NSString stringWithFormat:@"%d",fval]];
            }
        }
        else if ([obj isKindOfClass:[NSDate class]])
        {
#warning not Tested Function for NSDate
            
            NSDate *objDate = ((NSDate *)obj);
            NSString *stringDate = [Database sqlColumnRepresentationDate:objDate];
            if (stringDate != nil && stringDate.length != 0)
            {
                [arrColumnName addObject:key];
                NSLog(@"stringDate == %@",stringDate);
                [arrColumnValue addObject:[Database stringByReplaceQueryQuoteAndBindQuote:stringDate]];
            }
        }
        else if (obj != nil && ![obj isEqual:[NSNull null]])
        {
            // Tested OK //KK
            
            [arrColumnName addObject:key];
#warning please Test Then Use it...
            [arrColumnValue addObject:[NSString stringWithFormat:@"%@",[obj description]]];
        }
        else
        {
            //this part of code should never Execute  ...
            
            [arrColumnName addObject:key];
            [arrColumnValue addObject:[NSString stringWithFormat:@"''"]];
        }
    }
    
    //=====================  Query Start ===================== //
    
    NSString *sql= @"";
    
    //===================================================//
    //=====================  Insert =====================//
    //===================================================//
    if ([DML caseInsensitiveCompare:@"insert"] == NSOrderedSame)
    {
        [arrColumnName addObjectsFromArray:arrBlob_name];
        
        NSString  *columsNames = [[NSString alloc]initWithString: [arrColumnName componentsJoinedByString:@","]];
        
        NSMutableString *columnValues = [[NSMutableString alloc]initWithString: [arrColumnValue componentsJoinedByString:@","]];
        
        if([arrBlob_data count]>0)
        {
            [columnValues appendString:@","];
            
            for (int j=0; j<[arrBlob_data count]; j++)
            {
                [columnValues appendString:@"?"];
                if (j != [arrBlob_data count]-1) {
                    [columnValues appendString:@","];
                }
            }
        }
        
        sql = [NSString stringWithFormat:@"insert into %@ (%@) values (%@)",tblName,columsNames,columnValues];
        NSLog(@" Query == >>  %@\n\n",sql);
    }
    
    else
        
    //===================================================//
    //=====================  Update =====================//
    //===================================================//
    
     if ([DML caseInsensitiveCompare:@"update"] == NSOrderedSame && ClauseAndCondition != nil)
     {
        NSMutableString *stringUpdate = [[NSMutableString alloc]initWithString:@""];

        for (int m=0; m<[arrColumnName count]; m++)
        {
            [stringUpdate appendFormat:@"%@=%@",[arrColumnName objectAtIndex:m],[arrColumnValue objectAtIndex:m]];

            if (m != [arrColumnName count]-1 || [arrBlob_name count] != 0)
            {
                [stringUpdate appendString:@","];
            }
        }
         
        for (int m=0; m<[arrBlob_name count]; m++)
        {
            [stringUpdate appendFormat:@"%@=?",[arrBlob_name objectAtIndex:m]];
            
            if (m != [arrBlob_name count]-1)
            {
                [stringUpdate appendString:@","];
            }
        }
        
        sql = [NSString stringWithFormat:@"update %@ set %@ %@",tblName,stringUpdate,ClauseAndCondition];
    }
    
    // VALIDATE BLOB
    if ([arrBlob_name count] != [arrBlob_data count])
    {
        @try
        {
            //you may like to handle this Exception Out-side of Database Class
            [NSException raise:@"Invalid Blob data" format:@"could not find any key value Coding for blob"];
        }
        @catch (NSException *exception)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error" message:exception.description delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
            [alert show];
        }
        @finally
        {
            return FALSE;
        }
    }
    
    NSLog(@"\n\n\n\nQUERY :: %@\n\n\n",sql);
    
    //===================================================//
    //============ Prepare & Execute Query ==============//
    //===================================================//
    
    BOOL isTransComplete = NO;
    NSString *str = sql;
    sqlite3 *database;
    
    NSLog(@"\n\narr Blob Count == %lu : %lu  (bug if is is not Equal)\n\n",(unsigned long)[arrBlob_data count],(unsigned long)[arrBlob_name count]);
    
    if(sqlite3_open([[Database GetDatabasePath] UTF8String],&database) == SQLITE_OK)
    {
        const char *sqlStmt = [str UTF8String];
        
        sqlite3_stmt *cmp_sqlStmt;
        if(sqlite3_prepare_v2(database, sqlStmt, -1, &cmp_sqlStmt, NULL) == SQLITE_OK)
        {
            int returnValue = sqlite3_prepare_v2(database, sqlStmt, -1, &cmp_sqlStmt, NULL);

            for (int l=0; l<[arrBlob_name count]; l++)
            {
                NSData *blob = [arrBlob_data objectAtIndex:l];
                if(blob != nil && blob.length != 0)
                {
                    sqlite3_bind_blob(cmp_sqlStmt, l+1, [blob bytes], [blob length], NULL);
                }
                else
                {
                    sqlite3_bind_blob(cmp_sqlStmt, l+1, nil, -1, NULL);
                }
            }
            
            if (returnValue==SQLITE_OK)
            {
                NSLog(@"\n\n\tSuccess\n\n");
                isTransComplete = YES;
            }
            else
            {
                NSLog(@"\n\n\tUnSuccess\n\n");
            }
            
            sqlite3_step(cmp_sqlStmt);
        }
        else
        {
            NSLog(@"=== Invalide Query ::%@::  & Created sqlite3_stmt ==>>  %@ ",str,cmp_sqlStmt);
        }
        sqlite3_finalize(cmp_sqlStmt);
    }
	sqlite3_close(database);
    return isTransComplete;
}

-(BOOL)lookupChangeForSQL:(NSString *)sql
{
    BOOL isTransComplete = NO;
    NSString *str = sql;
    
    if(sqlite3_open([[Database GetDatabasePath] UTF8String],&ObjDB) == SQLITE_OK)
    {
        sqlite3_stmt *cmp_sqlStmt;
        
        // converting query to UTF8string.
        const char *sqlStmt=[str UTF8String];
        
        // preparing for execution of statement.
        if(sqlite3_prepare_v2(ObjDB, sqlStmt, -1, &cmp_sqlStmt, NULL)==SQLITE_OK)
        {
            BOOL isStatementPrepared = sqlite3_prepare_v2(ObjDB, sqlStmt, -1, &cmp_sqlStmt, NULL);
            
            if (isStatementPrepared == SQLITE_OK)
            {
                NSLog(@"Success");
                unsigned int isTransactionCompleted = sqlite3_step(cmp_sqlStmt);
                //SQLITE_BUSY, SQLITE_DONE, SQLITE_ROW, SQLITE_ERROR, or SQLITE_MISUSE.
                if (isTransactionCompleted == SQLITE_BUSY) {
                    NSLog(@"\n\n\n##ERROR :: DATABASE :: SQLITE_BUSY\n\n\n");
                } else if (isTransactionCompleted == SQLITE_DONE) {
                    NSLog(@"\n\n\n##ERROR :: DATABASE :: SQLITE_DONE\n\n\n");
                } else if (isTransactionCompleted == SQLITE_ROW) {
                    NSLog(@"\n\n\n##ERROR :: DATABASE :: SQLITE_ROW\n\n\n");
                } else if (isTransactionCompleted == SQLITE_ERROR) {
                    NSLog(@"\n\n\n##ERROR :: DATABASE :: SQLITE_ERROR\n\n\n");
                } else if (isTransactionCompleted == SQLITE_MISUSE) {
                    NSLog(@"\n\n\n##ERROR :: DATABASE :: SQLITE_MISUSE\n\n\n");
                }
                isTransComplete = TRUE;
            }
            else
            {
                NSLog(@"UnSuccess");
                NSLog(@" \n\n\n&&&&&&&&&&& ERROR :###: Preparing Statement &&&&&&&&&&&\n\n\n");
            }
        }
        sqlite3_finalize(cmp_sqlStmt);
    }
    
    sqlite3_close(ObjDB);
    
    return isTransComplete;
    
}

- (void)dealloc
{
    //
}

#pragma mark - Function
+ (NSString *)sqlColumnRepresentationDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSS"];
    }
    
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    
    return formattedDateString;
}

#pragma mark - Database Query Quote
+(NSString *)stringByReplaceQueryQuote:(NSString *)string
{
    return [string stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
}

+(NSString *)stringByReplaceQueryQuoteAndBindQuote:(NSString *)string
{
    //NSString *tmpStr = [self stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    return [NSString stringWithFormat:@"'%@'",[string stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
}


-(BOOL)insertBulkDataIntoTable:(NSString *)table dataArray:(NSMutableArray *)arrData {
    
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@",table];
    
    NSMutableString *appendData = [[NSMutableString alloc] init];
    
    for (NSMutableArray *arrValues in arrData) {
        
        [appendData appendString:@" SELECT "];
        
        for (NSString *str in arrValues) {
            
            NSString *strTemp = [[NSString stringWithFormat:@"%@",str] stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
            [appendData appendFormat:@" '%@',", strTemp];
        }
        
        NSString *str1 = [appendData substringToIndex:[appendData length] - 1];
        
        appendData = nil;
        appendData = [[NSMutableString alloc] initWithString:str1];
        
        str1 = nil;
        
        [appendData appendString:@" UNION ALL "];
    }
    
    NSString *str = [appendData substringToIndex:[appendData length] - 11];
    
    appendData = nil;
    appendData = [[NSMutableString alloc] initWithString:str];
    
    str = nil;
    
    query = [query stringByAppendingFormat:@" %@", appendData];
    
    
    return [Database lookupChangeForSQL:query];
    
    //return [SCSQLite executeSQL:query];
}

@end
/*
//
//  ViewController.swift
//  TestApp
//
//  Created by Kalpesh-Jetani on 05/12/16.
//  Copyright © 2016 OpenXcell Technolabs PVT. LTD. All rights reserved.
//

import UIKit

class CellDownloader : UITableViewCell {
    @IBOutlet var title : String?
    @IBOutlet var progressbar : UIProgressView?
    
}

class Song {
    var songDownloadLink : String?
    var songName : String?
}

class DownloadCell: UITableViewCell, NSURLSessionDelegate {
    
    
    @IBOutlet weak var lblSongName: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var progressCount: UILabel!
    
    var song: Song!
    
    var task: NSURLSessionTask!
    
    var percentageWritten: Float = 0.0
    var taskTotalBytesWritten = 0
    var taskTotalBytesExpectedToWrite = 0
    
    lazy var session: NSURLSession = {
        let config = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        config.allowsCellularAccess = false
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        return session
    }()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    func startDownload() {
        
        lblSongName.text = song.songName
        
        if self.task != nil {
            return
        }
        let url = NSURL(string: song.songDownloadLink!)!
        let req = NSMutableURLRequest(URL: url)
        let task = self.session.downloadTaskWithRequest(req)
        self.task = task
        task.resume()
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten writ: Int64, totalBytesExpectedToWrite exp: Int64) {
        taskTotalBytesWritten = Int(writ)
        taskTotalBytesExpectedToWrite = Int(exp)
        percentageWritten = Float(taskTotalBytesWritten) / Float(taskTotalBytesExpectedToWrite)
        progressBar.progress = percentageWritten
        progressCount.text = String(Int(percentageWritten*100)) + "%"
        
        print("(\(taskTotalBytesWritten) / \(taskTotalBytesExpectedToWrite))")
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error != nil {
            print("Completed with error: \(error)")
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        do {
            let documentsDirectoryURL =  NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
            progressCount.text = "Done!"
            progressBar.progress = 100.0
            
            try NSFileManager().moveItemAtURL(location, toURL: documentsDirectoryURL.URLByAppendingPathComponent(song.songName! + ".mp3")!)
            
            ////Handling Badge Values
            //let tabBar = UIApplication.sharedApplication().keyWindow?.rootViewController as! UITabBarController
            //let downloadVC = tabBar.viewControllers?[1] as! DownloadViewController
            //let badgeValue = Int(downloadVC.tabBarItem.badgeValue!)! - 1
            //downloadVC.tabBarItem.badgeValue = String(badgeValue)
            //
            //if badgeValue == 0 {
            //    downloadVC.tabBarItem.badgeValue = nil
            //}
            
        } catch {
            print("Error occurred during saving.")
            progressCount.text = String(error)
        }
        
    }
}

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {

    var array : [Song] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    //MARK:- TableViewDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell : CellDownloader = tableView.dequeueReusableCellWithIdentifier("CellDownloader", forIndexPath: indexPath) as! CellDownloader
        
        cell.title = array[indexPath.row].songName
        cell.progressbar?.progress = 1.0
        return cell
    }
    
}


*/
