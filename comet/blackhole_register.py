#! /usr/bin/python2.7
# -*- coding: utf-8 -*-
# python 脚本插件目前只支持使用 python2.7 标准库里的模块和函数
 
from __future__ import print_function
import json
import httplib
 
class ResultStatus:
    success = "success"
    fail = "fail"
    running = "running"
 
# 字段详细含义请见 info 插件文档
class Plugin:
    def __init__(self):
        with open("./metadata.json", "r") as f:
            meta_data = json.loads(f.read())
        print(meta_data)
        self.plugin = meta_data["plugin"]
        self.env = meta_data["env"]
        self.activity_env = meta_data["activity_env"]
        self.callback_url = meta_data["callback_url"]
        self.activity_id = meta_data["activity_id"]
        self.process_id = meta_data["process_id"]
        self.sponsor = meta_data["sponsor"]
        self.dealer = meta_data["dealer"]
        self.process_status = meta_data["process_status"]
        self.extend = meta_data["extend"]
 
    def write_result(self, status, message, data):
        # type: (str, str, object) -> object
        """
        write_result 是以文件的方式输出插件执行结果的方法
        插件执行的过程完成之后调用这个方法输出结果
        :param status: str 插件执行的结果，可选 success, fail, running
        :param message: str 对此次插件执行结果的描述
        :param data: dict| object 额外的输出结果，将被更新至流程上下文中以供流程全局使用
        :return: None
        """
        result = {
            "status": status,
            "message": message,
            "data": data
        }
        with open("./result.json", "w") as f:
            print(json.dumps(result), file=f)
        return
 
    def post(self, domain, path, headers, data):
        """
        简单封装的 post http 调用方法, 支持 json request/resp
        :param domain: 接口域名，如 "localhost:20000"
        :param path:接口路径，　如： /api/v1/workflow/init
        :param headers:, 接口请求头
        :param data: dict 接口请求体（body)
        :return:
        """
        conn = httplib.HTTPConnection(domain)
        headers.update({"content-type": "application/json"})
        data = json.dumps(data)
        conn.request("POST", path, body=data, headers=headers)
        return json.loads(conn.getresponse().read())
 
    def get(self, domain, path, headers, data):
        """
        简单封装的 http get 调用方法, 支持 json request/resp
        :param domain: 接口域名，如 "localhost:20000"
        :param path:接口路径，　如： /api/v1/workflow/init
        :param headers:, 接口请求头
        :param data: dict 接口查询参数
        :return:
        """
        conn = httplib.HTTPConnection(domain)
        headers.update({"content-type": "application/json"})
        data = json.dumps(data)
        conn.request("GET", path, body=data, headers=headers)
        return json.loads(conn.getresponse().read())
 
 
def get_data(plugin_env):
    """
    plugin_env["userInfo"]  ["部门:哔哩哔哩/流量生态部/算法3组/策略组", "昵称:hejun01", "名称:hejun01"]
    """
    username = plugin_env["userInfo"][2].split(":")[-1]
    departments = plugin_env["userInfo"][0].split("/")
    assert len(departments) >= 3, "Unrecognized department"
    department = departments[1]
    assert department in [ u"人工智能技术部", u"流量生态部", u"人工智能平台部" ], "only suppert ai"
    team = departments[2]

    data = {
         "username": username,
         "mobile": plugin_env["mobile"],
         "workid": plugin_env["workid"],
         "team": team,
    }
    return data
 
if __name__ == '__main__':
    print("启动 python 插件")
    plugin = Plugin()
    ## 请在此处开始你的插件的过程
    ## print 的日志将直接被 comet 引用到
    post_data = {}

    if plugin.process_status  == "success":
        print("管理员同意,开始POST调用接口")
        print("POST调用接口数据")
        print(plugin.env)
        data = get_data(plugin.env)
        post_data = plugin.post("blackhole.bilibili.co", "/api/users", {}, data)
        print("blackhole数据")
        print(post_data)
    elif plugin.process_status == "deny":
        print("流程拒绝,不做操作")
    else:
        print("流程取消")
    
    # print("开始GET调用接口")
    # get_data = plugin.get("10.70.66.17:10008", "/echo/", {}, {"data": plugin.env})
    # print("GET调用接口数据")
    # print(get_data)
    print("调用成功,输出插件执行结果")
    ## 输出结果
    plugin.write_result(ResultStatus.success, "ok", post_data)