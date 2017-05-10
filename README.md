# Perfect System Monitor Demo [简体中文](README.zh_CN.md)

<p align="center">
    <a href="http://perfect.org/get-involved.html" target="_blank">
        <img src="http://perfect.org/assets/github/perfect_github_2_0_0.jpg" alt="Get Involved with Perfect!" width="854" />
    </a>
</p>

<p align="center">
    <a href="https://github.com/PerfectlySoft/Perfect" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_1_Star.jpg" alt="Star Perfect On Github" />
    </a>  
    <a href="http://stackoverflow.com/questions/tagged/perfect" target="_blank">
        <img src="http://www.perfect.org/github/perfect_gh_button_2_SO.jpg" alt="Stack Overflow" />
    </a>  
    <a href="https://twitter.com/perfectlysoft" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_3_twit.jpg" alt="Follow Perfect on Twitter" />
    </a>  
    <a href="http://perfect.ly" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_4_slack.jpg" alt="Join the Perfect Slack" />
    </a>
</p>

<p align="center">
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat" alt="Swift 3.0">
    </a>
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Platforms-OS%20X%20%7C%20Linux%20-lightgray.svg?style=flat" alt="Platforms OS X | Linux">
    </a>
    <a href="http://perfect.org/licensing.html" target="_blank">
        <img src="https://img.shields.io/badge/License-Apache-lightgrey.svg?style=flat" alt="License Apache">
    </a>
    <a href="http://twitter.com/PerfectlySoft" target="_blank">
        <img src="https://img.shields.io/badge/Twitter-@PerfectlySoft-blue.svg?style=flat" alt="PerfectlySoft Twitter">
    </a>
    <a href="http://perfect.ly" target="_blank">
        <img src="http://perfect.ly/badge.svg" alt="Slack Status">
    </a>
</p>

This project demonstrates how to use [Perfect SysInfo](https://github.com/PerfectlySoft/Perfect-SysInfo) library to monitor realtime performance of server.

Ensure you have installed and activated the latest Swift 3.1 tool chain.



## Download, Build & Run

Use the following commands in terminal to quick install & run this demo:

```

$ git clone https://github.com/PerfectExamples/SystemMonitor-Demo.git
$ cd SystemMonitor-Demo
$ swift build
$ ./.build/debug/SystemMonitor

```

If success, the terminal should display something like ` [INFO] Starting HTTP server localhost on 0.0.0.0:8888`.

Then you can check the server status by browsing `http://localhost:8888`:

<p><img src=scrshot.jpg></p>


## Walk Through

This project is based on Perfect Template. If you are not familiar with Perfect server, please try [Perfect Template Start Project](https://github.com/PerfectlySoft/PerfectTemplate) first.

### API Routes

This server contains two routes, `/api` for server JSON query of real time polling. `/**` is actually mapping to `/index.html` as homepage.

``` swift

"routes":[
  ["method":"get", "uri":"/api", "handler":handler],
  ["method":"get", "uri":"/**", "handler":PerfectHTTPServer.HTTPHandler.staticFiles,
   "documentRoot":"./webroot"]
]
```

### System Information

Considering that `SysInfo` has a rich set of system information so it is necessary to pick up those info which is really needed.

The following code filters out a few basic metrics to monitor and translate into a JSON string. Please note the OS differences:

- CPU usage: average idle time, system time and user time, in percentage.
- Free memory
- Network I/O
- Disk I/O


``` swift

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

```

### Request / Response Handler

Once got the request, the server will immediately send back the JSON:

``` swift

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

```

### index.html

The homepage is very simple: use `promises` to download the data and render it by a certain chart framework, such as `ChartJS`:

``` javascript

/// setup a chart
function setup(api) {
  var ctx = document.getElementById(api).getContext("2d");
  return new Chart(ctx, {
    type: 'line',
    data: {  datasets: datagroups[api]   },
    options: {
        scales: {
            xAxes: [{
                type: 'linear',
                position: 'bottom'
            }]
        }
    }
  });
}//end setup

/// polling data from server api by promises, decode JSON and render in chart
function update(){
  fetch('http://' + window.location.host + '/api',{method: 'get'})
  .then( (resp) => { return resp.json() })
  .then( (obj) => {

    var chart = charts["cpu"];
    var dset = chart.chart.config.data.datasets;
    appendDataTo(dset, "CPU-idle", counter, obj.idle);
    appendDataTo(dset, "CPU-user", counter, obj.usr);
    appendDataTo(dset, "CPU-system", counter, obj.sys);
    chart.update();

    var chart = charts["mem"];
    var dset = chart.chart.config.data.datasets;
    appendDataTo(dset, "MEM-free", counter, obj.free);
    chart.update();

    var chart = charts["net"];
    var dset = chart.chart.config.data.datasets;
    appendDataTo(dset, "NET-recv", counter, obj.rcv);
    appendDataTo(dset, "NET-snd", counter, obj.snd);
    chart.update();

    var chart = charts["ios"];
    var dset = chart.chart.config.data.datasets;
    appendDataTo(dset, "DISK-read", counter, obj.rd);
    appendDataTo(dset, "DISK-write", counter, obj.wr);
    chart.update();

    counter += 1;

  });
}//end function

/// repeatedly polling data every second
window.setInterval(update, 1000);

```

## Issues

We are transitioning to using JIRA for all bugs and support related issues, therefore the GitHub issues has been disabled.

If you find a mistake, bug, or any other helpful suggestion you'd like to make on the docs please head over to [http://jira.perfect.org:8080/servicedesk/customer/portal/1](http://jira.perfect.org:8080/servicedesk/customer/portal/1) and raise it.

A comprehensive list of open issues can be found at [http://jira.perfect.org:8080/projects/ISS/issues](http://jira.perfect.org:8080/projects/ISS/issues)

## Further Information
For more information on the Perfect project, please visit [perfect.org](http://perfect.org).


## Now WeChat Subscription is Available (Chinese)
<p align=center><img src="https://raw.githubusercontent.com/PerfectExamples/Perfect-Cloudinary-ImageUploader-Demo/master/qr.png"></p>
