//
//  APIConnectComponents.swift
//  ConnectToLS_Mohsen_Master
//
//  Created by Olivier NERON DE SURGY on 12/02/2024.
//

import SwiftUI

///structure PostRequestData : composant pour envoyer une requête à une API Listesoft
public struct PostRequestData {
    let environment: Envirnmt
    let APIRoute: String
    let appToken: String?
    
    var urlServer = ""
    let httpMethod = "POST"
   public var headers = [
      "AuthorizationApp": "",
      "Content-Type": "application/json"
    ]
    
    /// Description
    /// - Parameters:
    ///   - environment: environment description
    ///   - APIRoute: APIRoute description
    ///   - appToken: appToken description
    public init(environment: Envirnmt, APIRoute: String, appToken: String? = nil) {   //l'appToken est optionnel car nécessaire seulement pour se connecter
        self.environment = environment
        switch environment {
            case .test: self.urlServer = "https://test.api.litesoft.solutions/"
            case .preprod : self.urlServer = "https://preprod.api.litesoft.solutions/"
            case .prod : self.urlServer = "https://2023.api.litesoft.solutions/"
        }
        self.APIRoute = APIRoute
        self.appToken = appToken
        self.headers["AuthorizationApp"] = appToken
    }
}

/// structure pour recevoir un JSON avec les données de compte d'utilisateur
public struct APIData: Decodable {
    var resultat: Bool = false
    var message: String = ""
    var psTokenJwt: String? = nil
    var psTokenUsr: String? = nil
   public init(resultat: Bool, message: String, psTokenJwt: String? = nil, psTokenUsr: String? = nil) {
        self.resultat = resultat
        self.message = message
        self.psTokenJwt = psTokenJwt
        self.psTokenUsr = psTokenUsr
    }
 }

/// structure de compte utilisateur  Litesoft
public struct LSUser : Codable {
   public var iss: String = ""
    public var psTokenUsr: String = ""  //jeton temporaire
    public var psTokenRef: String = ""
    public var data: LSUserData = LSUserData()
   public init() {
      
    }
}

public struct LSUserData : Codable {
    public var id: Int = 0
    public var nom: String = ""
    public var prenom: String = ""
    public var email: String = ""
    public var telephone: String = ""
    public var statut: Int = 0
    public var estTiers: Int = 0
    public var respDevis: Bool = false
    public var appWeb: Int = 0
    public var appMob: Int = 0
    public var psTokenUsrExp: String = ""
    public  var psTokenRefExp: String = ""
    public init() {
    }
}

/// Enum par laquelle on définit l'environnement de connexion
public enum Envirnmt: String {
    case test = "TEST"
    case preprod  = "PREPROD"
    case prod = "PROD"
}

/// composant connectAccount : tente une connexion à l'API de connexion du serveur Litesoft
/// - Parameters:
///     - environment : environnement de travail (.test, .preprod ou .prod)
///     - login : identifiant e-mail de l'utilisateur
///     - password : mot de passe de l'utilisateur
///     - appToken : clé d'application
/// - Returns:
///   - true si la connexion est un succès, false sinon
///   - message d'échec ou de sucès
///   - un compte d'utilisateur de type LSUser si la connexion est réussie, nil sinon
public func connectAccount(environment: Envirnmt, login: String, password: String, appToken: String) async -> (Bool, String, LSUser?) {
    var user: LSUser? = nil
    // instanciation de la structure de requête de connexion
    let postRequestData = PostRequestData(environment: environment, APIRoute: "utilisateur/connexion", appToken: appToken)
    
    // vérif de la syntaxe de l'URL
    guard let urlAPI = URL(string: postRequestData.urlServer + postRequestData.APIRoute) else {
        return (false, "URL de syntaxe incorrecte", nil)
    }
    
    //préparation de la requête de connexion
    var urlRequest = URLRequest(url: urlAPI)
    urlRequest.httpMethod = postRequestData.httpMethod
    urlRequest.allHTTPHeaderFields = postRequestData.headers
    
    // dictionnaire avec login et mot de passe pour mettre en JSON dans le body de la requête
    // (les noms des champs-clés sont définis par l'API LiteSoft) :
    let requestParam: [String: String] = [
        "psEmail": login,
        "psMotDePasse": password
    ]
    
    //encodage binaire du JSON à envoyer
    guard let jsonPostData = try? JSONEncoder().encode(requestParam) else {
        return (false, "échec d'encodage JSON de la requête de connexion", nil)
    }
    urlRequest.httpBody = jsonPostData
    
    // envoi de la requête par URLSession et réception de la réponse qui a un en-tête (response) et un contenu (data)
    var data = Data() // données binaires renvoyées par le serveur, à décoder en structure contenant un JWT
//        var response = URLResponse()  // réponse à l'appel URLSession, pas utile sauf pour test
    
    do {
//            (data, response) = try await URLSession.shared.data(for: urlRequest)
        (data, _) = try await URLSession.shared.data(for: urlRequest)
    } catch {
        return (false, "échec d'envoi de la requête de connexion", nil)
    }
    
    // affichage en console de l'en-tête de réponse, pour phase de test
//        if let httpResponse = response as? HTTPURLResponse {
//            print("HTTP RESPONSE: " + httpResponse.description)
//        }
    
    //  Décodage du message-réponse dans la structure Swift ad hoc.
    guard let apiData = try? JSONDecoder().decode(APIData.self, from: data) else {
        return (false, "échec d'obtention du résultat de la demande de connexion", nil)
    }
    // Si la connexion est refusée, on récupère le message de refus pour l'afficher et on sort
    guard apiData.resultat else {
        return (false, apiData.message, nil)
    }
   
    //Décodage base64 du tokenJwt
    let jsonString = getJwtBodyString(tokenstr: apiData.psTokenJwt ?? "TokenJwt manquant !")
    
    //remplissage de la structure Swift LSUser
    if let jsonUserData = jsonString.data(using: .utf8) {
        if let user_ = try? JSONDecoder().decode(LSUser.self, from: jsonUserData) {
            user = user_
        }
    }

    return(true, apiData.message, user)
}

/// composant getJwtBodyString : décode un JWT (token string base64) en JSON-String
public func getJwtBodyString(tokenstr: String) -> String {
    let segments = tokenstr.components(separatedBy: ".")
    var base64String = segments[1]
    let requiredLength = Int(4 * ceil(Float(base64String.count) / 4.0))
    let nbrPaddings = requiredLength - base64String.count
    if nbrPaddings > 0 {
        let padding = String().padding(toLength: nbrPaddings, withPad: "=", startingAt: 0)
        base64String = base64String.appending(padding)
    }
    base64String = base64String.replacingOccurrences(of: "-", with: "+")
    base64String = base64String.replacingOccurrences(of: "_", with: "/")
    let decodedData = Data(base64Encoded: base64String, options: Data.Base64DecodingOptions(rawValue: UInt(0)))

    let base64Decoded: String = String(data: decodedData! as Data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
    return base64Decoded
}
