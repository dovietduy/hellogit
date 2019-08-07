//
//  ViewController.swift
//  Test1
//
//  Created by DuyDo on 7/15/19.
//  Copyright © 2019 DuyDo_VTI. All rights reserved.
//

import UIKit
import SQLite3
class ViewController: UIViewController {

    var db: OpaquePointer?
    var profileList = [Profile]()
    
    @IBOutlet weak var lblId: UILabel!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var tableProfile: UITableView!
    @IBOutlet weak var txtPhone: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableProfile.dataSource = self
        tableProfile.delegate = self
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("ProfileDB.sqlite")
        print(fileURL)
        //opening the database
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        //creating table
        let profile_table = "CREATE TABLE IF NOT EXISTS Profile (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT)"
        if sqlite3_exec(db, profile_table, nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }
        
    }
    
    @IBAction func btnAddClick(_ sender: Any) {
        let name = txtName.text
        let phone = txtPhone.text
        let profile = Profile(id : 0, name : name!, phone: phone!)
        addProfile(profile : profile)
    }

    @IBAction func btnLoadDataClick(_ sender: Any) {
        initValues()
    }

    func initValues(){
        profileList.removeAll()
        let query = "SELECT * FROM Profile"
        var stmt:OpaquePointer?

        if sqlite3_prepare(db, query, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print(errmsg)
            return
        }

        while(sqlite3_step(stmt) == SQLITE_ROW){
            let id = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let phone = String(cString: sqlite3_column_text(stmt, 2))
            profileList.append(Profile(id: id, name: String(describing: name),phone: String(describing: phone)))
        }
        self.tableProfile.reloadData()
    }
    
    
    func addProfile(profile : Profile) {
        let query = "INSERT INTO Profile (name,phone) VALUES ('\(String(describing: profile.name))', '\(String(describing: profile.phone))')"
        var errMessage: UnsafeMutablePointer<Int8>? = nil
        let result = sqlite3_exec(db, query, nil, nil, &errMessage)
        if(result != SQLITE_OK){
            sqlite3_close(db)
            print("Cau truy van bi loi")
            return
        }
        txtName.text=""
        txtPhone.text=""
        initValues()
        print("successfully")
    }
    @IBAction func btnUpdateClick(_ sender: Any) {
        let id : Int? = Int(lblId.text!)
        let name : String? = txtName.text
        let phone : String? = txtPhone.text
        let profile = Profile(id: id!, name: name!, phone: phone!)
        editProfile(profile: profile)
    }
    
    func editProfile(profile : Profile){
        let query = "UPDATE Profile " +
                    "SET name = '" + profile.name + "'," +
                    "phone = '" + profile.phone + "' " +
                    "WHERE id = '" + String(profile.id) + "'"
        var stmt : OpaquePointer?
        if sqlite3_prepare(db, query, -1, &stmt, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print(errmsg)
            return
        }
        if sqlite3_step(stmt) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print(errmsg)
            return
        }
        lblId.text = ""
        txtPhone.text = ""
        txtName.text = ""
        initValues()
        print("Edit successfully!")
    }
    
    func deleteProfile(profile : Profile) {
        let query = "DELETE FROM Profile WHERE id = '" + String(profile.id) + "' "
        var errMessage: UnsafeMutablePointer<Int8>? = nil
        let result = sqlite3_exec(db, query, nil, nil, &errMessage)
        if(result != SQLITE_OK){
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print(errmsg)
            sqlite3_close(db)
            return
        }
        initValues()
        print("Delete successfully!")
    }
    
    @IBAction func btnExportToCSV(_ sender: Any) {
        let fileManager = FileManager.default
        let dirPaths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsPath = dirPaths[0].path
//        do {
//            let fileList = try fileManager.contentsOfDirectory(atPath: docsDir)
//            for filename in fileList {
//                print(filename)
//            }
//        } catch let err {
//            print(err.localizedDescription)
//        }
//        let stDataToWrite = "Hello world".data(using: .utf8)
//
//        guard let fileName = dirPaths.append("/text.txt").path else {
//
//            return
//
//        }
    }
    @objc func btnEditClick(sender : UIButton){
        let index = sender.tag
        let indexPath = IndexPath(row: index, section: 0)
        var profile: Profile
        profile = profileList[indexPath.row]
        lblId.text = String(profile.id)
        txtName.text = profile.name
        txtPhone.text = profile.phone
        
    }
    
    @objc func btnClearClick(sender: UIButton){
        let index = sender.tag
        let indexPath = IndexPath(row: index, section: 0)
        var profile: Profile
        profile = profileList[indexPath.row]
        deleteProfile(profile: profile)
    }
    

}


extension ViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profileList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell" ) as! List_TableViewCell
        let profile: Profile
        profile = profileList[indexPath.row]
        cell.lblName.text = profile.name
        cell.lblPhone.text = profile.phone
        cell.lblId.text = String(profile.id)
        cell.btnEdit.tag = indexPath.row
        cell.btnClear.tag = indexPath.row
        cell.btnEdit.addTarget(self, action: #selector(btnEditClick(sender:)), for: UIControl.Event.touchUpInside)
        cell.btnClear.addTarget(self, action: #selector(btnClearClick(sender:)), for: UIControl.Event.touchUpInside)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
    }
}
