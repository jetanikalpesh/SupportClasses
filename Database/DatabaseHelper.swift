//
//  DatabaseHelper.swift
//  DatabaseConnectivity
//
//  Created by Kalpesh-Jetani on 24/11/16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

import Foundation

class TestManager {
    
    static let shared_instance : TestManager = TestManager()
    var arrayCategories : [DataModelCategory] = []
    
    func setUpCategories(){
        if arrayCategories.count == 0 {            
            let category_JSON = getDBCategories()
            for category in category_JSON {
                self.arrayCategories.append(DataModelCategory.init(dictionary: category as! [String : Any]))
            }
        }
    }
    
    func getDBCategories()-> NSMutableArray
    {
        let selectSQL  = "SELECT tb_categories.id as category_id, tb_categories.title FROM tb_categories"
        return Database.sharedInstance().lookupAll(forSQL: selectSQL)
    }
    
    func categoryAtIndex(index:Int)-> DataModelCategory?{
        if self.arrayCategories.count > index && index >= 0{
            return self.arrayCategories[index]
        }
        return nil
    }
}

class DataModelCategory {
    
    //category_id,title
    
    var category_id : Int?
    var title : String?
    
    var questions : [DataModelQuestion]?
    
    init(dictionary : [String:Any]){
        category_id = dictionary["category_id"] as? Int
        title = dictionary["title"] as? String
        
        self.setUpQuestions()
    }

    func setUpQuestions(){
        if self.questions == nil{
            self.questions = []
            if self.category_id != nil{
                let question_JSON = getDBQuestionsByCategoryID(category_id: self.category_id!)
                for question in question_JSON {
                    self.questions?.append(DataModelQuestion.init(dictionary: question as! [String : Any]))
                }
            }
        }
    }
    
    func getDBQuestionsByCategoryID(category_id: Int)-> NSMutableArray
    {
        let selectSQL  = "SELECT tb_questions.id as question_id, tb_questions.pillar_weight, tb_questions.question, tb_questions.score_group, tb_questions.type FROM tb_questions where tb_questions.category_id = \(category_id) and score_group != 0"
        return Database.sharedInstance().lookupAll(forSQL: selectSQL)
    }
    
    func questionAtIndex(index:Int)-> DataModelQuestion?{
        if self.questions != nil{
            if self.questions!.count > index && index >= 0{
                return self.questions![index]
            }
        }
        return nil
    }
}

class DataModelQuestion {
    
    //question_id, question, score_group, pillar_weight, type
    
    var question_id : Int?
    var question : String?
    var score_group : Int?
    var pillar_weight : Float?
    var typeValue : Int?
   
    var options : [DataModelOption]?

    var type: enumCellType = enumCellType.eSimple
    var selectedOptions : [DataModelOption] = []
    

    init(dictionary : [String:Any]) {
        
        question_id = dictionary["question_id"] as? Int
        question = dictionary["question"] as? String
        score_group = dictionary["score_group"] as? Int
        pillar_weight = dictionary["pillar_weight"] as? Float
        typeValue = dictionary["type"] as? Int
        
        if typeValue == 1 {
            self.type = enumCellType.eSimple
        }
        else if typeValue == 2 {
            self.type = enumCellType.eYesNo_Multi
        }
        
        self.setUpOptions()
    }
    
    func setSelectedOption(modelOption : DataModelOption){
        if self.type == .eSimple {
            self.selectedOptions.removeAll()
            self.selectedOptions.append(modelOption)
        } else {
            self.selectedOptions.append(modelOption)
        }
    }
    
    func removeSelectedOption(modelOption : DataModelOption){
        
        if let index : Int = self.selectedOptions.indexOfObjecttt(object: modelOption){
            self.selectedOptions.remove(at: index)
        }
    }
    
    func getSelectedOptions() -> [DataModelOption]{
        return self.selectedOptions
    }
    
    func setUpOptions() {
        
        if self.options == nil {
            self.options = []
            if self.question_id != nil{
                let option_JSON = getDBOptionsByQuestionID(question_id: self.question_id!)
                for option in option_JSON {
                    
                    //set type: enumCellType
                    self.options?.append(DataModelOption.init(dictionary: option as! [String : Any]))
                }
            }
        }
    }

    func getDBOptionsByQuestionID(question_id: Int)-> NSMutableArray
    {
        let selectSQL  = "SELECT tb_options.id as option_id, tb_options.option_title, tb_options.option_frequency, tb_options.score_weight FROM tb_options where tb_options.question_id = \(question_id)"
        return Database.sharedInstance().lookupAll(forSQL: selectSQL)
    }
}

class DataModelOption : Equatable {
    
    //option_id, option_title, option_frequency, score_weight
    var option_id : Int?
    var option_title : String?
    var option_frequency : Int?
    var score_weight : Float?
    
    var type: enumCellType = enumCellType.eSimple
    
    init(dictionary : [String:Any]){
        option_id = dictionary["option_id"] as? Int
        option_title = dictionary["option_title"] as? String
        option_frequency = dictionary["option_frequency"] as? Int
        score_weight = dictionary["score_weight"] as? Float
    }
    
    static func == (lhs: DataModelOption, rhs: DataModelOption) -> Bool {
        
        if lhs.option_id == rhs.option_id && lhs.option_title == rhs.option_title {
            return true
        }
        return false
    }
}





