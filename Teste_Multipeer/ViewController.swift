//
//  ViewController.swift
//  Teste_Multipeer
//
//  Created by Matheus Lima Ferreira on 4/21/20.
//  Copyright © 2020 Matheus Lima Ferreira. All rights reserved.
//

import MultipeerConnectivity
import UIKit

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    var images =  [UIImage]()
    
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCAdvertiserAssistant?
    
    var mcNearbyServiceAdvertiser: MCNearbyServiceAdvertiser?
    var serviceNearbyBrowser: MCNearbyServiceBrowser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Selfie Share"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        self.mcNearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "teste")
        self.mcNearbyServiceAdvertiser?.delegate = self
        self.serviceNearbyBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: "teste")
        self.serviceNearbyBrowser?.delegate = self
        self.mcSession = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: .required)
        
        mcSession?.delegate = self
        
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)
        
        if let imageView = cell.viewWithTag(1000) as? UIImageView{
            imageView.image = images[indexPath.item]
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    private func startHosting(action: UIAlertAction) {
        guard let mcSession = mcSession  else { return }
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "teste", discoveryInfo: nil, session: mcSession)
        
        self.mcNearbyServiceAdvertiser?.startAdvertisingPeer()
        mcAdvertiserAssistant?.start()
    }
    
    private func joinSession(action: UIAlertAction) {
        guard let mcSession = mcSession  else { return }
        
        self.serviceNearbyBrowser?.delegate = self
        self.serviceNearbyBrowser?.startBrowsingForPeers()
        let mcBrowser = MCBrowserViewController(serviceType: "teste", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        
        images.insert(image, at: 0)
        collectionView.reloadData()
        
        guard let mcSession = mcSession  else { return }
        
        if mcSession.connectedPeers.count > 0 {
            if let imageData = image.pngData() {
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch  {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName) ")
        case .connecting:
            print("Connecting...: \(peerID.displayName) ")
        case .notConnected:
            print("Not connected: \(peerID.displayName) ")
        @unknown default:
            print("Unknow state received: \(peerID.displayName) ")
            
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let image = UIImage(data: data) {
                self.images.insert(image, at: 0)
                self.collectionView.reloadData()
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
  
    
  
}

extension ViewController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard let mcSession = mcSession else { return }

        print("didReceiveInvitationFromPeer: \(peerID.displayName)")
        invitationHandler(true, mcSession)
      }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
}

extension ViewController: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("found peer: \(peerID.displayName)")
        guard let mcSession = mcSession else { return }
        browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
      }
      
      func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lostPeer: \(peerID.displayName)")
      }
}
