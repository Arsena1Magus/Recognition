//
//  Extensions.swift
//  WhoAreYou
//
//  Created by Никита Петров on 05.11.2021.
//  Copyright © 2021 M'haimdat omar. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(identifier: String, infos: [InfoModel], handler: ((UIAlertAction) -> Void)?) {
        var title: String = "Внимание"
        var message: String = "Посторонний посетитель"
        if infos.isEmpty {
            title = "Ошибка"
            message = "Отсутствуют данные о сотрудниках"
        } else {
            if identifier != "Unknown" {
                title = "Информация о сотруднике"
                if let model = infos.first(where: {$0.id == identifier}) {
                    message = ""
                    message += "ФИО - " + model.name + "\n"
                    message += "Возраст - " + model.age + "\n"
                    message += "Должность - " + model.position + "\n"
                    message += "Уровень доступа - " + model.level + "\n"
                    message += "Работает с " + model.time
                }
            }
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Готово", style: .cancel, handler: handler)
        cancel.titleTextColor = UIColor(red: 0.133, green: 0.745, blue: 0.329, alpha: 1)
        alertController.addAction(cancel)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension UIAlertAction {
    var titleTextColor: UIColor? {
        get {
            return self.value(forKey: "titleTextColor") as? UIColor
        } set {
            self.setValue(newValue, forKey: "titleTextColor")
        }
    }
}
