# Perfect System Monitor Demo

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

本项目展示了如何使用[Perfect SysInfo](https://github.com/PerfectlySoft/Perfect-SysInfo) 函数库来实时监控服务器当前性能指标。

请确保您的系统已经安装了Swift 3.1工具链。

## 下载、编译和运行

请打开终端并执行如下命令行进行下载、编译和运行：

```

$ git clone https://github.com/PerfectExamples/SystemMonitor-Demo.git
$ cd SystemMonitor-Demo
$ swift build
$ ./.build/debug/SystemMonitor

```

如果成功的化，终端会输出类似 ` [INFO] Starting HTTP server localhost on 0.0.0.0:8888` 的字样。

此时您可以打开浏览器并输入网址：`http://localhost:8888`:

<p><img src=scrshot.jpg></p>


## 源码简介

注意，如果您还不熟悉 Perfect 服务器，请首先尝试学习 [Perfect Template 服务器模板项目](https://github.com/PerfectlySoft/PerfectTemplate)。

### 接口函数路由

本服务器包含两个基本路由，一个是`/{device}`，用于映射具体的函数接口`/cpu`（中央处理器）、`/mem`（内存）、`/net`（网络和`/ios`（磁盘读写）。而`/**`则实际上就是映射了`index.html`作为主页。

``` swift

"routes":[
  ["method":"get", "uri":"/{device}", "handler":handler],
  ["method":"get", "uri":"/**", "handler":PerfectHTTPServer.HTTPHandler.staticFiles,
   "documentRoot":"./webroot"]
]
```

### 请求/响应 处理器

收到请求后，服务器会解析具体的接口请求，然后从`SysInfo.XXX`类对象中读取实际的实时信息，再进行json打包、发回给客户端。这里请注意 mac / linux 写法有差异，主要是在macOS上要避免没有必要的字典类数据缓存堆积。

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

主页内容就相对简单了：即使用`promises`（承诺线程）下载服务器数据并在某个绘图框架下渲染，比如使用 `ChartJS`:

``` javascript
/// 构造一个图表
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

/// 从服务器下拉实时数据，JSON解码并在图表中渲染
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

### 问题报告、内容贡献和客户支持

我们目前正在过渡到使用JIRA来处理所有源代码资源合并申请、修复漏洞以及其它有关问题。因此，GitHub 的“issues”问题报告功能已经被禁用了。

如果您发现了问题，或者希望为改进本文提供意见和建议，[请在这里指出](http://jira.perfect.org:8080/servicedesk/customer/portal/1).

在您开始之前，请参阅[目前待解决的问题清单](http://jira.perfect.org:8080/projects/ISS/issues).

## 更多信息
关于本项目更多内容，请参考[perfect.org](http://perfect.org).

## 扫一扫 Perfect 官网微信号
<p align=center><img src="https://raw.githubusercontent.com/PerfectExamples/Perfect-Cloudinary-ImageUploader-Demo/master/qr.png"></p>
