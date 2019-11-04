//
//  CameraViewController.swift
//  SparkPerso
//
//  Created by AL on 14/01/2018.
//  Copyright © 2018 AlbanPerli. All rights reserved.
//

import UIKit
import DJISDK
import VideoPreviewer
//import ImageDetect

class CameraViewController: UIViewController {

    @IBOutlet weak var extractedFrameImageView: UIImageView!
    
    @IBOutlet weak var resultLabel: UILabel!
    
    let prev1 = VideoPreviewer()
    @IBOutlet weak var cameraView: UIView!
    
    let prev2 = VideoPreviewer()
    @IBOutlet weak var camera2View: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let _ = DJISDKManager.product() {
            if let camera = self.getCamera(){
                camera.delegate = self
                self.setupVideoPreview()
            }
            
            GimbalManager.shared.setup(withDuration: 1.0, defaultPitch: -28.0)
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func lookFront(_ sender: Any) {
        GimbalManager.shared.lookFront()
    }
    
    @IBAction func lookUnder(_ sender: Any) {
        GimbalManager.shared.lookUnder()
    }
    @IBAction func startStopCameraButtonClicked(_ sender: UIButton) {
        
        self.prev1?.snapshotThumnnail { (image) in
            if let img = image {
                print(img.size)
                self.extractedFrameImageView.image = img
                
                
                if let dataImg = UIImagePNGRepresentation(img){
                    let strId = UUID().uuidString
                    var url = getDocumentsDirectory()
                    let imgUrl = url.appendingPathComponent("MonNom"+strId+".png")
                    try! dataImg.write(to: imgUrl)
                }
                
            }
        }
        
        /*
         Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.prev1?.snapshotThumnnail { (image) in
                
                if let img = image {
                    print(img.size)
                    // Resize it and put it in a neural network! :)
                
                    if let infos = ImageRecognition.shared.predictUsingCoreML(image: img){
                        self.extractedFrameImageView.image = infos.0
                        self.resultLabel.text = infos.1
                    }else{
                        self.extractedFrameImageView.image = nil
                        self.resultLabel.text = ""
                    }
                    
                    /*
                    img.detector.crop(type: DetectionType.face) { result in
                        DispatchQueue.main.async { [weak self] in
                            switch result {
                            case .success(let croppedImages):
                                // When the `Vision` successfully find type of object you set and successfuly crops it.
                                self?.extractedFrameImageView.image = croppedImages.first
                            case .notFound:
                                // When the image doesn't contain any type of object you did set, `result` will be `.notFound`.
                                print("Not Found")
                            case .failure(let error):
                                // When the any error occured, `result` will be `failure`.
                                print(error.localizedDescription)
                            }
                        }
                    }
                     */
                    
                }
            }
        }
        */
    }
    
    @IBAction func captureModeValueChanged(_ sender: UISegmentedControl) {
        
    }
    
    func getCamera() -> DJICamera? {
        // Check if it's an aircraft
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
             return mySpark.camera
        }
        
        return nil
    }
    
    func setupVideoPreview() {
        
        // Prev1 est de type VideoPreviewer
        // Camera view est une view liée depuis le storyboard
        
        prev1?.setView(self.cameraView)
        /*
        // ...
        // plus loin
        // ...
        // ReceivedData est l'équivalent de ton callBack de reception
        WebSocketManager.shared.receivedData{ data in
            // On extrait les bytes de data sous la forme d'un pointeur sur UInt8
            data.withUnsafeBytes { (bytes:UnsafePointer<UInt8>) in
                // On push ces fameux bytes dans la vue
                prev1?.push(UnsafeMutablePointer(mutating: bytes), length: Int32(data.count))
            }
        }
        */
        
        
        //prev2?.setView(self.camera2View)
        //VideoPreviewer.instance().setView(self.cameraView)
        if let _ = DJISDKManager.product(){
            let video = DJISDKManager.videoFeeder()
            
            DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        }
        prev1?.start()
        //prev2?.start()
        //VideoPreviewer.instance().start()
    }
    
    func resetVideoPreview() {
        prev1?.unSetView()
       // prev2?.unSetView()
        DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let camera = self.getCamera() {
            camera.delegate = nil
        }
        self.resetVideoPreview()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CameraViewController:DJIVideoFeedListener {
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        print([UInt8](videoData).count)
        videoData.withUnsafeBytes { (bytes:UnsafePointer<UInt8>) in
            prev1?.push(UnsafeMutablePointer(mutating: bytes), length: Int32(videoData.count))
            prev2?.push(UnsafeMutablePointer(mutating: bytes), length: Int32(videoData.count))
        }
        
    }

}

extension CameraViewController:DJISDKManagerDelegate {
    func appRegisteredWithError(_ error: Error?) {
        
    }
    
    
}

extension CameraViewController:DJICameraDelegate {
    
}

