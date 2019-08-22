//
//  HomePageViewController.swift
//  Trekker
//
//  Created by Jason Mandozzi on 8/19/19.
//  Copyright © 2019 Jason Mandozzi. All rights reserved.
//

import UIKit
import MapKit

class HomePageViewController: UIViewController {
    
    let screenSize = UIScreen.main.bounds.size
    
    let currentLongitude = CoreLocationController.shared.locationManager.location?.coordinate.longitude
    let currentLatitude = CoreLocationController.shared.locationManager.location?.coordinate.latitude
    
    var searchResults: [HikeJSON] = []
    
    //Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        CoreLocationController.shared.activateLocationServices()
        getMyRegion()
        fetchHikes ()
        detailView.alpha = 1
        detailView.frame = CGRect(x: 0, y: self.screenSize.height, width: self.screenSize.width, height: self.screenSize.height / 3.5)
        // Do any additional setup after loading the view.
    }
    
    override func loadView() {
        super.loadView()
        addSubViews()
        setUpMainStackView()
    }
    
    func getMyRegion() {
        DispatchQueue.main.async {
            guard let latitude = CoreLocationController.shared.locationManager.location?.coordinate.latitude, let longitude = CoreLocationController.shared.locationManager.location?.coordinate.longitude else {return}
            let userCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let mySpan = MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
            let myRegion = MKCoordinateRegion(center: userCoordinates, span: mySpan)
            self.mapView.setRegion(myRegion, animated: true)
        }
    }
    
    func createAnnotations(hikeArray: [HikeJSON]) {
        for hike in hikeArray {
            DispatchQueue.main.async {
                guard let long = hike.longitude, let lat = hike.latitude else {return}
                let annotations = MKPointAnnotation()
                annotations.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                self.mapView.addAnnotation(annotations)
            }
        }
    }
    
    func fetchHikes() {
        guard let currentLat = currentLatitude,
        let currentLon = currentLongitude
        else { return }
        guard let url = NetworkController.sharedInstance.buildURL(baseURL: HikeAPIStrings.baseURL, components: [HikeAPIStrings.components], queryItems: [HikeAPIStrings.latitudeQuery : "\(currentLat)", HikeAPIStrings.longitudeQuery : "\(currentLon)", HikeAPIStrings.apiKey : HikeAPIStrings.apiKeyValue]) else { return }
        NetworkController.sharedInstance.getDataFromURL(url: url) { (data) in
            
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                let topLevelJSON = try decoder.decode(TopLevelJSON.self, from: data)
                guard let trails = topLevelJSON.trails else { return }
                self.searchResults = trails
            } catch {
                print ("Error in \(#function) : \(error.localizedDescription) /n---/n \(error)")
                return
            }
            self.createAnnotations(hikeArray: self.searchResults)
        }
    }
    
    //Hike Detail View
    let detailView: UIView = {
        let view = UIView()
        view.backgroundColor = .green
        return view
    }()
    
    let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalCentering
        stackView.spacing = 15
        return stackView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Helvetca", size: 14)
        label.text = "Hike Name"
        label.textColor = .black
        return label
    }()
    
    func addSubViews() {
        self.view.addSubview(detailView)
        self.view.addSubview(mainStackView)
    }
    
    func setUpMainStackView() {
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(nameLabel)
    }
    
    func constrainView() {
        mainStackView.anchor(top: detailView.topAnchor, bottom: detailView.bottomAnchor, leading: detailView.leadingAnchor, trailing: detailView.trailingAnchor, topPadding: 5, bottomPadding: -5, leadingPadding: 5, trailingPadding: -5)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension HomePageViewController: MKMapViewDelegate {
    

    
    func showDetailView() {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseIn, animations: {
                self.detailView.alpha = 1
                self.detailView.frame = CGRect(x: 0, y: self.screenSize.height - (self.screenSize.height/3), width: self.screenSize.width, height: self.screenSize.height / 3)
            }, completion: nil)
    }
    
    func hideDetailView() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
            self.detailView.frame = CGRect(x: 0, y: self.screenSize.height, width: self.screenSize.width, height: 0)
        }, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        DispatchQueue.main.async {
            self.showDetailView()
        }
    }
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        DispatchQueue.main.async {
            self.hideDetailView()
        }
    }
}
