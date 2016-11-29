//
//  Database.h
//  DatabaseConnectivity
//
//  Created by jetani kalpesh on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sqlite3.h>

#define kDatabaseName @"afft"
#define kDatabaseExt @"sqlite"

@interface Database : NSObject {
	sqlite3 *ObjDB;
}

@property (nonatomic,assign) sqlite3 *ObjDB;
+(Database *)sharedInstance;
+(NSString *)GetDatabasePath;
+(void)copyDatabaseFileToCachePath;

//HIDEN from Outside -(sqlite3_stmt *)prepare:(NSString *)sql;
-(NSDictionary *)lookupRowForSQL:(NSString *)sql;
-(NSMutableArray *)lookupAllForSQL:(NSString *)sql ;

+(BOOL)lookupChangeForSQL:(NSString *)sql;

//HARD CODED LOGIC
+(BOOL)lookupChangeForSQLDictionary:(NSDictionary *)dictSql insertOrUpdate:(NSString *)DML ClauseAndCondition:(NSString *)ClauseAndCondition TableName:(NSString *)tblName;

// jetani kalpesh
@end




