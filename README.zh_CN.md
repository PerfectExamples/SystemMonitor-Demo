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

本服务器包含两个基本路由，一个是`/api`，用于读取服务器的JSON实时报告，而`/**`则实际上就是映射了`index.html`作为主页。

``` swift

"routes":[
  ["method":"get", "uri":"/api", "handler":handler],
  ["method":"get", "uri":"/**", "handler":PerfectHTTPServer.HTTPHandler.staticFiles,
   "documentRoot":"./webroot"]
]
```

### 系统信息

考虑到 `SysInfo` 能够提供的系统指标非常丰富，因此有必要只选择需要的指标进行监控。

下列代码过滤出了少量用于监控的指标，并转换为一个JSON字符串。请注意操作系统的差异：

- CPU 用量: 平均空闲事件、系统占用和用户占用，所有指标为百分比
- 空闲内存数量
- 网络吞吐量
- 磁盘吞吐量


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

### 请求/响应 处理器

收到请求后，服务器立刻将系统信息的JSON字符串发回给客户：

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

### 问题报告、内容贡献和客户支持

我们目前正在过渡到使用JIRA来处理所有源代码资源合并申请、修复漏洞以及其它有关问题。因此，GitHub 的“issues”问题报告功能已经被禁用了。

如果您发现了问题，或者希望为改进本文提供意见和建议，[请在这里指出](http://jira.perfect.org:8080/servicedesk/customer/portal/1).

在您开始之前，请参阅[目前待解决的问题清单](http://jira.perfect.org:8080/projects/ISS/issues).

## 更多信息
关于本项目更多内容，请参考[perfect.org](http://perfect.org).

## 扫一扫 Perfect 官网微信号
<p align=center><img src="https://raw.githubusercontent.com/PerfectExamples/Perfect-Cloudinary-ImageUploader-Demo/master/qr.png"></p>
