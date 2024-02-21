//
//  UIComponents.swift
//  ConnectToLS_Mohsen_Master
//
//  Created by Olivier NERON DE SURGY on 17/02/2024.
//

import SwiftUI

/// composant style de Champ de saisie Litesoft a
/// - Parameters:
///      - label :  label affiché en petit, en haut à gauche du champ (petit placeholder permanent)
///      - size : taille de la police de caractères
public struct LSFieldStyle: ViewModifier {      // Design provisoire. A MODIFIER
    var label: String
    var size: CGFloat
    public init(label: String, size: CGFloat) {
        self.label = label
        self.size = size
    }
    public func body(content: Content) -> some View {
        content
            .font(.system(size: size))
            .padding(.horizontal, 5)
            .padding(.top, 18)
            .padding(.bottom, 6)
            .foregroundColor(.black)
            .frame(maxWidth: 340)
            .background(Color(.white))
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.5), radius: 8, x: 3, y: 3)
            .autocapitalization(.none)  // empêche le remplacement automatique d'une minuscule par une majuscule
            .autocorrectionDisabled(true)  // supprime l'autocorrection d'orthographe automatique
            .overlay(Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .offset(x: 5)
                , alignment: .topLeading)
    }
}

/// modificateur appliquant le style Champ de saisie à un champ de saisie
public extension View {
     func lsFieldStyle(size: CGFloat, label: String) -> some View {
         modifier(LSFieldStyle(label: label, size: size))
      }
}

/// composant TextField Litesoft
/// - Parameters:
///    - label : petit label jouant le rôle de placeholder
///    - size : taille de police de caractères
public struct LabelledTextField: View {
    var label: String
    var size: CGFloat
    @Binding var inputText: String
    public init(label: String, size: CGFloat, inputText: Binding<String>) {
        self.label = label
        self.size = size
        self._inputText = inputText
    }
    public var body: some View {
        TextField("...", text: $inputText)
            .lsFieldStyle(size: size, label: label)
    }
}

/// isEmailAddress teste si une chaîne est bien une adresse e-mail ou pas.
/// - Warning : Dans le pattern d'expression régulière (le second argument de NSPredicate) ici utilisé, les back-slash ont été doublés car \ est un caractère d'échappement Swift.
/// Ce pattern provient de  https://regexplib.com  qui donne ces quelques précisions :
///   "Most email validation regexps are outdated and ignore the fact that domain names can contain any foreign character these days,
///     as well as the fact that anything before @ is acceptable.
///    The only roman alphabet restriction is in the TLD, which for a long time has been more than 2 or 3 chars (.museum, .aero, .info).
///    The only dot restriction is that . cannot be placed directly after @.
///    This pattern captures any valid, reallife email adress.
///   - Matches :   whatever@somewhere.museum | foreignchars@myforeigncharsdomain.nu | me+mysomething@mydomain.com  ;
///   - Non-Matches :  a@b.c | me@.my.com | a@b.comFOREIGNCHAR"
public func isEmailAddress(_ aString: String) -> Bool {
    let emailPattern = NSPredicate(format: "SELF MATCHES %@", "^.+@[^\\.].*\\.[a-z]{2,}$")
    return emailPattern.evaluate(with: aString)
}

/// composant SecureField Litesoft
/// - Parameters:
///    - label : petit label jouant le rôle de placeholder
///    - size : taille de police de caractères
public struct LabelledSecureField: View {
    var label: String
    var size: CGFloat
    @Binding var inputText: String
    
    public init(label: String, size: CGFloat, inputText: Binding<String> ) {
        self.label = label
        self.size = size
        self._inputText = inputText
    }
    
    public var body: some View {
        SecureField("...", text: $inputText)
            .lsFieldStyle(size: size, label: label)
    }
}

/// composant champ de saisie show/hide Litesoft
/// - Parameters:
///    - label : petit label jouant le rôle de placeholder
///    - size : taille de police de caractères
public struct ShowHidePwdField: View {
    var label: String
    var size: CGFloat
    @Binding var passWord: String
    @State private var isSecure = true
    
    public init(label: String, size: CGFloat, passWord: Binding<String>, isSecure: Bool = true) {
        self.label = label
        self.size = size
        self._passWord = passWord
        self.isSecure = isSecure
    }
    
    public var body: some View {
            HStack {
                if isSecure{
                    LabelledSecureField(label: label, size: size, inputText: $passWord)
                } else {
                    LabelledTextField(label: label, size: size, inputText: $passWord)
                }
                
                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye" : "eye.slash") // oeil à droite
                        .foregroundColor(.gray)
                        .background(.white)
                }.offset(x: -40)
            }
            .offset(x: 17)
    }
}

/// style de bouton de validation Litesoft
/// - Parameters:
///    - label : label du bouton
///    - size : taille de police de caractères
///    - enabled : si true, prend la couleur donné en dernier argument ; gris clair si false
///    - color : couleur de fond du bouton
public struct ValidationButtonStyle: View {         // Design provisoire. A MODIFIER
    var label: String
    var size: CGFloat
    var enabled: Bool
    var color: Color
    public init(label: String, size: CGFloat, enabled: Bool, color: Color) {
        self.label = label
        self.size = size
        self.enabled = enabled
        self.color = color
    }
    public var body: some View {
        Text(label)
            .font(.system(size: size))
            .foregroundColor(.white)
            .padding(.horizontal, 15)
            .padding(6)
            .background(enabled ? color : Color(.lightGray))
            .cornerRadius(20)
    }
}

