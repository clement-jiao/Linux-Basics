'''
@Description:
@Author: 焦国峰
@Github: https://github.com/clement-jiao
@Date: 2020-04-22 09:50:18
@LastEditors: clement-jiao
@LastEditTime: 2020-04-22 11:21:25
'''
#!/usr/local/bin/python
#coding: utf-8
__author__ = 'zdz8207'
import json
import urllib.request
import sys

def get_data(ip):
  myurl = "http://ip.taobao.com/service/getIpInfo.php?ip=" + ip
  # jsondata = json.loads(urllib.urlopen('http://ip.taobao.com/service/getIpInfo.php?ip'))
  res = urllib.request.urlopen(myurl)
  print(res)
  #{u'code': 0, u'data': {u'ip': u'119.124.101.221', u'city':
  #其中code的值的含义为，0：成功，1：失败。{u'code': 1, u'data': u'invaild ip.'}

  #print(jsondata)

  # if jsondata['code'] == 1:
  #   jsondata['data'] = {'region':'','city':'','isp':''}
  # return (jsondata['data']['region'], jsondata['data']['city'], jsondata['data']['isp'])

if __name__ == "__main__":
  # 211.162.62.161 61.135.157.156 220.198.192.0 119.124.101.221
  result = get_data("211.162.62.161")
  # print(result[0]+result[1]+result[2])
  print(result)
