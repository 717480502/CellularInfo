import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = scene as? UIWindowScene else {
            return
        }
        
        window = UIWindow(windowScene: windowScene)
        window!.rootViewController = MainUITabBarController()
        window!.makeKeyAndVisible()
    }
    
    /// App从后台返回前台的调用方法
    func sceneDidBecomeActive(_ scene: UIScene) {
        // 发送通知
        NotificationCenter.default.post(name: CellularDataController.cellularDataRefreshNotificationName, object: nil)
    }
    
    /// 分享ipcc文件到app以后的处理方法
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            handleIncomingIPCC(url: context.url)
        }
    }
    
    private func handleIncomingIPCC(url: URL) {
        guard url.pathExtension.lowercased() == "ipcc" else { return }
        
        DispatchQueue.main.async {
            guard let window = self.window,
                  let tabBar = window.rootViewController as? MainUITabBarController else {
                return
            }
            
            // 切换tab到工具这个tab
            tabBar.selectedIndex = 2
            
            guard let nav = tabBar.selectedViewController as? UINavigationController else {
                    return
                }
                
            // 先判断是不是用户恰好在IPCC管理界面
            if let managerViewController = nav.topViewController as? IPCCManagerViewController {
                // 已经在这个页面 直接调用
                managerViewController.importIPCCFileFromOtherApplication(url: url)
                
            } else { // 不在就创建VC并且push打开
                let managerViewController = IPCCManagerViewController()
                nav.pushViewController(managerViewController, animated: true)
                // 等动画都加载完成再去刷IPCC
                DispatchQueue.main.async {
                    // 调用安装IPCC的方法 这样才能保证弹窗出现
                    managerViewController.receiveFileFromOtherApplication(url: url)
                }
            }
        }
    }
    
}
