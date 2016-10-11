//
//  LAMediator.swift
//  Pods
//
//  Created by LakeR on 16/6/27.
//
//

import Foundation
import ObjectiveC


@objc public protocol LAModual {
}


@objc open class LAMediator : NSObject {
    struct Singleton{
        static var onceToken : Int = 0
        static var instance : LAMediator?
    }
    
    static var __once: () = {
            Singleton.instance = LAMediator()
        }()
    let MediatorDomain = "com.laker.mediator"
    
    public enum MediatorErrorCode : Int {
        case errorNoScheme = 100,errorNoTarget,errorNoAction,errorNotModualTarget,errorNilUrl,errorParameter
    }
    
    open class func shareInstance()->LAMediator{

        _ = LAMediator.__once
        return Singleton.instance!
    }
    
    // MARK: - swift API
    open func performActionWithURL(_ url : URL?) throws -> AnyObject?{
        guard let _ = url else{
            throw errorWithCode(MediatorErrorCode.errorNilUrl)
        }
        
        let urlTypes : [[String : AnyObject]]? = (Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [ [String : AnyObject] ])
        var schemes : [String] = []
        
        urlTypes?.forEach({ (urlType : [String : AnyObject]) in
            (urlType["CFBundleURLSchemes"] as? [String])?.forEach({ (scheme : String) in
                schemes.append(scheme)
            })
        })
        
        if !schemes.contains(url!.scheme!) {
            throw errorWithCode(MediatorErrorCode.errorNoScheme)
        }
        
        let components : URLComponents? = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        var parameter : [String:String] = [:]
        components?.queryItems?.forEach({ (queryItem : URLQueryItem)  in
            parameter[queryItem.name] = queryItem.value
        })
        
        
        return try self.performTarget(url!.host, action: url!.path.replacingOccurrences(of: "/", with: ""), parameter: parameter as [String : AnyObject],fromURL: true)
    }
    
    
    open func performTarget(_ target : String?, action : String?, parameter : [String:AnyObject] ) throws -> AnyObject? {
        return try self.performTarget(target, action: action, parameter: parameter, fromURL: false)
    }
    
    
    open func performTarget(_ target : String?, action : String?, parameter : [String:AnyObject] ,fromURL: Bool) throws -> AnyObject? {
        guard let _ = target , let _ = action else{
            throw errorWithCode(MediatorErrorCode.errorParameter)
        }
        
        let targetClass : AnyClass? = NSClassFromString(target!)
        let target : AnyObject? = targetClass?.alloc()
        
        guard let _ = target as? LAModual else{
            throw errorWithCode(MediatorErrorCode.errorNotModualTarget)
        }
        let action : Selector? = NSSelectorFromString(action!+":param:")
        
        guard let _ = target, let _ = action else {
            throw errorWithCode(MediatorErrorCode.errorNoTarget)
        }
        
        if target?.responds(to: action!) == true {
            var navController = UIApplication.shared.keyWindow?.rootViewController
            if !(navController is UINavigationController) {
                navController = navController?.navigationController
            }
            return target?.perform(action!,with: navController, with: parameter)?.takeUnretainedValue()
        }
        else{
            let notFoundAction : Selector = NSSelectorFromString("notFound:")
            if target?.responds(to: notFoundAction) == true {
                return target?.perform(notFoundAction, with: parameter)?.takeUnretainedValue()
            }
            else{
                throw errorWithCode(MediatorErrorCode.errorNoAction)
            }
        }
        
    }
    
    
    // MARK: - Objc wrapper API
    open func objcPerformActionWithURL(_ url : URL?) -> AnyObject?{
        do{
            return try performActionWithURL(url)
        }
        catch let error as NSError {
            return error
        }
    }
    
    open func objcPerformTarget(_ target : String!, action : String!, parameter : [String:AnyObject]) -> AnyObject? {
        do {
            return try performTarget(target, action: action, parameter: parameter)
        }
        catch let error as NSError {
            return error
        }
    }
    
    
    // MARK: - help functions
    func errorWithCode(_ code : MediatorErrorCode) -> NSError {
        return NSError(domain: MediatorDomain, code:code.rawValue, userInfo: ["description":"\(code)"])
    }
    
    
    
    
}
