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

This server contains two routes, `/{device}` for mapping API of `/cpu`, `/mem`, `/net` and `/ios` for disk I/O. `/**` is actually mapping to `/index.html` as homepage.

``` swift

"routes":[
  ["method":"get", "uri":"/{device}", "handler":handler],
  ["method":"get", "uri":"/**", "handler":PerfectHTTPServer.HTTPHandler.staticFiles,
   "documentRoot":"./webroot"]
]
```

### Request / Response Handler

Once got the request, the server will parse out the actual api by calling `req.urlVariables["device"]`, then try to pull out actual info from `SysInfo.XXX`, translate this dictionary and send it back to the client as JSON string. Please note the different calling between mac / linux, which mainly focus on avoiding unnecessary dictionary caching in macOS.

``` swift

var report = ""
let function = req.urlVariables["device"] ?? ""
switch function {
case "cpu":
  #if os(Linux)
    report = try SysInfo.CPU.jsonEncodedString()
  #else
    try autoreleasepool(invoking: {
      report = try SysInfo.CPU.jsonEncodedString()
    })
  #endif

// then deal with mem / net and disk io ....
default:
  res.status = .notFound
  res.completed()
  return
}
res.setHeader(.contentType, value: "text/json")
.appendBody(string: report)
.completed()

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

/// pull data from server api by promises, decode JSON and render in chart
function update(api){
  fetch(url(api),{method: 'get'})
  .then( (resp) => { return resp.json() })
  .then( (obj) => {
    var chart = charts[api];
    switch (api) {
      case "cpu":
        var cpu = obj.cpu;
        appendDataTo(chart.chart.config.data.datasets, "CPU-idle", counter, cpu.idle);
        appendDataTo(chart.chart.config.data.datasets, "CPU-user", counter, cpu.user);
        appendDataTo(chart.chart.config.data.datasets, "CPU-system", counter, cpu.system);
        break;
        // other counters ...
    }//end switch
    chart.update();
  });
}//end function
```

## Issues

We are transitioning to using JIRA for all bugs and support related issues, therefore the GitHub issues has been disabled.

If you find a mistake, bug, or any other helpful suggestion you'd like to make on the docs please head over to [http://jira.perfect.org:8080/servicedesk/customer/portal/1](http://jira.perfect.org:8080/servicedesk/customer/portal/1) and raise it.

A comprehensive list of open issues can be found at [http://jira.perfect.org:8080/projects/ISS/issues](http://jira.perfect.org:8080/projects/ISS/issues)

## Further Information
For more information on the Perfect project, please visit [perfect.org](http://perfect.org).


## Now WeChat Subscription is Available (Chinese)
<p align=center><img src="https://raw.githubusercontent.com/PerfectExamples/Perfect-Cloudinary-ImageUploader-Demo/master/qr.png"></p>
