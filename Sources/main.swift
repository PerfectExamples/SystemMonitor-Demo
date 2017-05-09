//
//  main.swift
//  SystemMonitor-Demo
//
//  Created by Rockford Wei on 5/09/17.
//	Copyright (C) 2017 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2017 - 2018 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//


import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectSysInfo
#if os(Linux)
#else
import CoreFoundation
#endif

func handler(data: [String:Any]) throws -> RequestHandler {
	return {
		req , res in
    var report = ""
    let function = req.urlVariables["device"] ?? ""
    do {
      switch function {
      case "cpu":
        #if os(Linux)
          report = try SysInfo.CPU.jsonEncodedString()
        #else
          try autoreleasepool(invoking: {
            report = try SysInfo.CPU.jsonEncodedString()
          })
        #endif
      case "mem":
        #if os(Linux)
          report = try SysInfo.Memory.jsonEncodedString()
        #else
          try autoreleasepool(invoking: {
            report = try SysInfo.Memory.jsonEncodedString()
          })
        #endif
      case "net":
        #if os(Linux)
          report = try SysInfo.Net.jsonEncodedString()
        #else
          try autoreleasepool(invoking: {
            report = try SysInfo.Net.jsonEncodedString()
          })
        #endif
      case "ios":
        #if os(Linux)
          report = try SysInfo.Disk.jsonEncodedString()
        #else
          try autoreleasepool(invoking: {
            report = try SysInfo.Disk.jsonEncodedString()
          })
        #endif
      case "favicon.ico":
        res.completed()
        return
      default:
        res.status = .notFound
        res.completed()
        return
      }
    }catch {
      res.status = .badGateway
      res.completed()
      return
    }
		res.setHeader(.contentType, value: "text/json")
    .appendBody(string: report)
    .completed()
	}
}

let confData = [
	"servers": [
		[
			"name":"localhost",
			"port":8888,
			"routes":[
				["method":"get", "uri":"/{device}", "handler":handler],
				["method":"get", "uri":"/**", "handler":PerfectHTTPServer.HTTPHandler.staticFiles,
				 "documentRoot":"./webroot"]
			]
		]
	]
]

do {
	// Launch the servers based on the configuration data.
	try HTTPServer.launch(configurationData: confData)
} catch {
	fatalError("\(error)") // fatal error launching one of the servers
}
