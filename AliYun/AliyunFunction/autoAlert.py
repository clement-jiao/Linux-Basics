# -*- coding: utf-8 -*-

import json
import time
import logging
import datetime
import requests

from aliyunsdkcore.client import AcsClient
from aliyunsdkcore.acs_exception.exceptions import ClientException
from aliyunsdkcore.acs_exception.exceptions import ServerException
from aliyunsdkdomain.request.v20180129.QueryDomainListRequest import QueryDomainListRequest

# To enable the initializer feature (https://help.aliyun.com/document_detail/158208.html)
# please implement the initializer function as below：
# def initializer(context):
#   logger = logging.getLogger()
#   logger.info('initializing')

def handler(event, context):
    
    logger = logging.getLogger()
    logger.info('hello world')

    header = {'content-type': 'application/json'}
    client = AcsClient('LTAI4G8YHgiM6DkvhfRWQ2kE', 'SgwL6RvtAFPFnqNzIDYXOf4kMpshHG', 'cn-shanghai')
    request = QueryDomainListRequest()
    request.set_accept_format('json')

    request.set_PageNum(1)
    request.set_PageSize(5)

    # query_domain_list_request = client.do_action_with_exception(request)
    # query_domain_list_response = json.loads(str(query_domain_list_request, encoding='utf-8'))

    query_domain_list_response = json.loads(str(event, encoding='utf-8'))
    domains = query_domain_list_response.get("Data",{}).get("Domain")
    tmp=""
    Content = {"tag": "div","text": {"content": "","tag": "lark_md"}}
    Template = {"msg_type":"interactive","card":{"config":{"wide_screen_mode":False,"enable_forward":False},"elements":[{"actions":[{"tag":"button","text":{"content":"进入控制台查看详情","tag":"lark_md"},"url":"https://dc.console.aliyun.com/","type":"default","value":{}}],"tag":"action"}],"header":{"title":{"content":"阿里云监控","tag":"plain_text"},"template":"red"}}}
    url = "https://open.feishu.cn/open-apis/bot/v2/hook/eae5e233-3af5-4468-a1dd-9924addffb04"
    if domains:
        for domain in domains:
            endtime = domain["ExpirationDateLong"]
            expiration = int(round(time.time() * 1000)) + int(86400*90*1000)
            if endtime < expiration:
                Content["text"]["content"] = "过期域名：{0}，\n过期时间：{1}".format(domain['DomainName'],domain["ExpirationDate"])
                Template["card"]["elements"].insert(-2,Content)
        #         tmp += "过期域名：{0}，\n过期时间：{1}\n".format(domain['DomainName'],domain["ExpirationDate"])
        # Content["text"]["content"] = tmp
        # Template["card"]["elements"].insert(0,Content)

        requests.post(url, headers=header, data=json.dumps(Template))

    # return json.dumps(templateResponse)

