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

extension SysInfo {
  static var express: String? {
    get {
      #if os(Linux)
        guard
          let cpu = SysInfo.CPU["cpu"],
          let mem = SysInfo.Memory["MemAvailable"],
          let net = SysInfo.Net["enp0s3"],
          let dsk = SysInfo.Disk["sda"],
          let wr = dsk["writes_completed"],
          let rd = dsk["reads_completed"]
          else {
            return nil
        }
      #else
        guard
          let cpu = SysInfo.CPU["cpu"],
          let mem = SysInfo.Memory["free"],
          let net = SysInfo.Net["en0"],
          let dsk = SysInfo.Disk["disk0"],
          let wr = dsk["bytes_written"],
          let rd = dsk["bytes_read"]
          else {
            return nil
        }
      #endif
      guard
        let idl = cpu["idle"],
        let user = cpu["user"],
        let system = cpu["system"],
        let nice = cpu["nice"],
        let rcv = net["i"],
        let snd = net["o"]
        else {
          return nil
      }

      let total = (idl + user + system + nice) / 100
      let idle =  idl / total
      let usr = user / total
      let sys = system / total
      let MB = UInt64(1048576)
      let report : [String: Int]
          = ["idle": idle, "usr": usr, "sys": sys, "free": mem,
             "rcv": rcv, "snd": snd,
             "rd": Int(rd / MB), "wr": Int(wr / MB)]
      do {
        return try report.jsonEncodedString()
      }catch {
        return nil
      }//end do
    }
  }
}

func handler(data: [String:Any]) throws -> RequestHandler {
	return {
		_ , res in
    guard let report = SysInfo.express else {
      res.status = .badGateway
      res.completed()
      return
    }//end
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
				["method":"get", "uri":"/api", "handler":handler],
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
