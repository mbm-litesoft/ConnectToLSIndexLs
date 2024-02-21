//
//  APIConnectView.swift
//  ConnectToLS_Mohsen_Master
//
//  Created by Olivier NERON DE SURGY on 12/02/2024.
//

import SwiftUI

/// Fenêtre de connexion d'un utilisateur à l'API de connexion du serveur Litesoft
/// - Parameters:
///   - environment: détermine si la connexion est à faire sur un environnement de test, de preprod ou de prod
///   - appToken : jeton d'autorisation de l'appli
///   Entrée/sortie :
///   - user: contient les données de compte utilisateur si la connexion est un succès
///   - isDone: booléen qui fait fermer la fenêtre quand on le passe à true
public struct ConnectView: View {
// Design et font provisoires. A MODIFIER
    let environment: Envirnmt
    let appToken: String
    @Binding var user: LSUser?
    @Binding var isDone: Bool
    
    public init(environment: Envirnmt ,appToken: String , user: Binding<LSUser?>, isDone: Binding<Bool>) {
        self.environment = environment
        self.appToken = appToken
        self._user = user
        self._isDone = isDone
    }
    
    @Environment(\.dismiss) var dismiss  // pour désallouer la vue en mémoire
    
    
    
    @State private var message: String = ""  // message affiché en cas d'échec de connexion
    @State private var showAlert: Bool = false  // booléen pour afficher un popup d'alerte
    @State private var login: String = "admin@litesoft.solutions"   // login saisi    A MODIFIER  par ""
    @State private var password: String = "LiteSoft!2011"  // mot de passe saisi    A MODIFIER  par ""
    @State private var pendingConnexion = false  // true quand la connexion est tentée, pour affichage d'un progressView
    @State private var isConnected = false  // true si la connexion est un succès
    
    public var body: some View {
        VStack {
            // logo Litesoft (basse def) et titre
            Group{
                Image("LogoLS", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
                Text(environment.rawValue)
                Spacer()
            
                Text("Connexion au serveur")
                    .foregroundStyle(.primary)
                    .font(.system(size: 28))
            }

            Spacer()
            
            // champs de saisie customisés
            LabelledTextField(label: "Identifiant (adresse e-mail)", size: 18, inputText: $login)
                .padding(.bottom, 30)
            ShowHidePwdField(label: "Mot de passe", size: 18, passWord: $password)

            Spacer()
            
            //bouton qui lance la tentative de connexion au serveur LiteSoft.
            Button(action: {
                // si adresse e-mail invalide, popup d'alerte et on sort
                guard isEmailAddress(login) else {
                    message = "Adresse e-mail invalide"
                    showAlert = true
                    return
                }
                
                pendingConnexion = true
                
                //essai de connexion
                Task {
                    (isConnected, message, user) = await connectAccount(environment: environment, login: login, password: password, appToken: appToken)
                    pendingConnexion = false
                    
                    // si le compte user n'est pas identifié par le serveur
                    // ou s'il y a une autre erreur, alerte et on sort
                    guard isConnected else {
                        showAlert = true
                        return
                    }
                    
                    // si la connexion est OK un message de succès est affiché (cf. plus bas)
                    // et on ferme la fenêtre au bout de 2 secondes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        isDone = true
                        dismiss()
                    }
                }
            }, label: {
            // bouton de connexion gris et désactivé tant qu'il n'y pas de saisie valide
            // ou si on attend la réponse du serveur
                ValidationButtonStyle(label: "Se connecter", size: 21, enabled: (login.count > 5) && (password.count > 0) && !pendingConnexion, color: .blue)
            } )
            .disabled(pendingConnexion || (login.count < 6) || password.isEmpty)
            
            Spacer()
            
            // progressView visible tant qu'on attend la réponse du serveur
            ProgressView()
                .opacity(pendingConnexion ? 1.0 : 0.0)
            
            // si connexion OK, on affiche un message de succès
            // sinon on affiche un bouton qui permet de fermer la fenêtre
            if isConnected {
                Text("Connexion établie !")
                    .foregroundStyle(.green)
            } else {
                Button(action: {
                    isDone = true
                    dismiss()
                }, label: {
                    ValidationButtonStyle(label: "Fermer", size: 18, enabled: true, color: .blue)
                        .opacity(pendingConnexion ? 0.0 : 1.0)
                })
            }
 
            Spacer()
        }
        // affichage du popup d'alert
        .alert(message, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
            }
        }
    }
}

#Preview {
    ConnectView(environment: .test , appToken: "", user: .constant(LSUser()), isDone: .constant(false))
}
