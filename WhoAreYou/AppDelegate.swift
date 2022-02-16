//
//  AppDelegate.swift
//  WhoAreYou
//
//  Created by M'haimdat omar on 27-07-2019.
//  Copyright © 2019 M'haimdat omar. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let controller = ViewController()
        // Переопределение точки для настройки после запуска приложения.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {
        // Вызывается, когда приложение готово к завершению.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         Постоянный контейнер для приложения.
         Эта реализация создает и возвращает контейнер.
         Это свойство не является обязательным, поскольку есть допустимые условия ошибки.
        */
        let container = NSPersistentContainer(name: "WhoAreYou")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Типичные причины ошибки здесь включают:
                    * Родительский каталог не существует, не может быть создан или запрещает запись.
                    * Постоянное хранилище недоступно из-за разрешений или защиты данных, когда устройство заблокировано.
                    * На устройстве закончилось место.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

