//
//  LAMediator.swift
//  Pods
//
//  Created by 胡恒恺 on 16/6/27.
//
//

import Foundation
import ObjectiveC


@objc public protocol LAModual {
}


@objc public class LAMediator : NSObject {
    let MediatorDomain = "com.laker.mediator"
    
    public enum MediatorErrorCode : Int {
        case ErrorNoScheme = 100,ErrorNoTarget,ErrorNoAction,ErrorNotModualTarget,ErrorNilUrl,ErrorParameter
    }

    public class func shareInstance()->LAMediator{
        struct Singleton{
            static var onceToken : dispatch_once_t = 0
            static var instance : LAMediator?
        }
        dispatch_once(&Singleton.onceToken,{
            Singleton.instance = LAMediator()
        })
        return Singleton.instance!
    }
    
    // MARK: - swift API
    public func performActionWithURL(url : NSURL?) throws -> AnyObject?{
        guard let _ = url else{
            throw errorWithCode(MediatorErrorCode.ErrorNilUrl)
        }
        
        let urlTypes : [[String : AnyObject]]? = (NSBundle.mainBundle().infoDictionary?["CFBundleURLTypes"] as? [ [String : AnyObject] ])
        var schemes : [String] = []
        
        urlTypes?.forEach({ (urlType : [String : AnyObject]) in
            (urlType["CFBundleURLSchemes"] as? [String])?.forEach({ (scheme : String) in
                schemes.append(scheme)
            })
        })

        if !schemes.contains(url!.scheme) {
            throw errorWithCode(MediatorErrorCode.ErrorNoScheme)
        }

        let components : NSURLComponents? = NSURLComponents(URL: url!, resolvingAgainstBaseURL: false)
        var parameter : [String:String] = [:]
        components?.queryItems?.forEach({ (queryItem : NSURLQueryItem)  in
            parameter[queryItem.name] = queryItem.value
        })
        
        
        return try self.performTarget(url!.host, action: url!.path?.stringByReplacingOccurrencesOfString("/", withString: ""), parameter: parameter,fromURL: true)
    }
    
    
    public func performTarget(target : String?, action : String?, parameter : [String:AnyObject] ) throws -> AnyObject? {
        return try self.performTarget(target, action: action, parameter: parameter, fromURL: false)
    }
    
    
    public func performTarget(target : String?, action : String?, parameter : [String:AnyObject] ,fromURL: Bool) throws -> AnyObject? {
        guard let _ = target , _ = action else{
            throw errorWithCode(MediatorErrorCode.ErrorParameter)
        }
        
        let targetClass : AnyClass? = NSClassFromString(target!)
        let target : AnyObject? = targetClass?.alloc()
        
        guard let _ = target as? LAModual else{
            throw errorWithCode(MediatorErrorCode.ErrorNotModualTarget)
        }
        let action : Selector? = NSSelectorFromString(action!+":param:")
        
        guard let _ = target, let _ = action else {
            throw errorWithCode(MediatorErrorCode.ErrorNoTarget)
        }
        
        if target?.respondsToSelector(action!) == true {
            var navController = UIApplication.sharedApplication().keyWindow?.rootViewController
            if navController?.isKindOfClass(UINavigationController.classForCoder()) == false {
                navController = navController?.navigationController
            }
            return target?.performSelector(action!,withObject: navController, withObject: parameter)?.takeUnretainedValue()
        }
        else{
            let notFoundAction : Selector = NSSelectorFromString("notFound:")
            if target?.respondsToSelector(notFoundAction) == true {
                return target?.performSelector(notFoundAction, withObject: parameter)?.takeUnretainedValue()
            }
            else{
                throw errorWithCode(MediatorErrorCode.ErrorNoAction)
            }
        }

    }

    
    // MARK: - Objc wrapper API
    public func objcPerformActionWithURL(url : NSURL?) -> AnyObject?{
        do{
           return try performActionWithURL(url)
        }
        catch let error as NSError {
            return error
        }
    }
    
    public func objcPerformTarget(target : String!, action : String!, parameter : [String:AnyObject]) -> AnyObject? {
        do {
            return try performTarget(target, action: action, parameter: parameter)
        }
        catch let error as NSError {
            return error
        }
    }
    
    
    // MARK: - help functions
    func errorWithCode(code : MediatorErrorCode) -> NSError {
        return NSError(domain: MediatorDomain, code:code.rawValue, userInfo: ["description":"\(code)"])
    }
    
    
    
    
}
