'''
Description:
Author: 焦国峰
Github: https://github.com/clement-jiao
Date: 2022-04-07 15:04:42
LastEditors: clement-jiao
LastEditTime: 2022-04-07 15:04:42
再也不改版！
'''

import os
import time
import json
import boto3
import asyncio
import aiohttp
import requests
from datetime import datetime

CloudWatchLogs = boto3.client("logs")
cloudwatch = boto3.client('cloudwatch')


# putImageUrl = "https://open.feishu.cn/open-apis/image/v4/put/"
# getChatlistUrl = "https://open.feishu.cn/open-apis/chat/v4/list"
# sendMessageUrl = "https://open.feishu.cn/open-apis/message/v4/send/"
# accessTokenUrl = "https://open.feishu.cn/open-apis/auth/v3/app_access_token/internal/"

putImageUrl = "https://open.larksuite.com/open-apis/image/v4/put/"
getChatlistUrl = "https://open.larksuite.com/open-apis/chat/v4/list"
sendMessageUrl = "https://open.larksuite.com/open-apis/message/v4/send/"
accessTokenUrl = "https://open.larksuite.com/open-apis/auth/v3/app_access_token/internal/"

app_id = os.environ["app_id"]
app_secret = os.environ["app_secret"]

data = {"app_id": app_id, "app_secret": app_secret}
header = {
    "Content-Type": "application/json; charset=utf-8",
    "Authorization": ""
}


# 代码很烂，以后空了再优化吧 -_-!


def getTenantTokenAndChatId():
    tenant_access_token_Response = requests.get(accessTokenUrl, params=data, headers=header)
    tenant_access_token_Response_toJson = tenant_access_token_Response.json()
    tenant_access_token = tenant_access_token_Response_toJson[
        "tenant_access_token"] if tenant_access_token_Response_toJson.get("code") == 0 else None

    getChatlistUrlParam = {"page_size": 100}
    header["Authorization"] = f"Bearer {tenant_access_token}"

    getChatlist = requests.get(getChatlistUrl, params=getChatlistUrlParam, headers=header)
    getChatlist_toJson = getChatlist.json()

    # print(tenant_access_token,getChatlist_toJson)

    groups = getChatlist_toJson.get("data", {}).get("groups", None)
    if groups:
        chatId_list = [chat_id.get("chat_id", None) for chat_id in groups]
        return (tenant_access_token, chatId_list)


async def sendMetricImage(client, tenant_access_token, binaryFile):
    # header = {"Authorization": f"Bearer {tenant_access_token}", 'Connection': 'keep-alive', 'Referer': f"{putImageUrl}"}
    header = {"Authorization": f"Bearer {tenant_access_token}", 'Connection': 'keep-alive'}
    async with client.post(putImageUrl, data={"image_type": "message", "image": binaryFile},
                           headers=header) as larkResponse:
        # print(put_images_requests)

        return await larkResponse.json()


async def getImageKey(tenant_access_token, BinaryFile):
    async with aiohttp.ClientSession() as client:
        uploadImage_toJson = await sendMetricImage(client, tenant_access_token, BinaryFile["fileContent"])

    print(uploadImage_toJson)
    if uploadImage_toJson.get("code", None) == 0 and uploadImage_toJson.get("msg", None) == "ok":
        return {"image_key": uploadImage_toJson.get("data", {}).get("image_key"), "fileName": BinaryFile["fileName"]}
    else:
        print("lark Api Error, errorCode: {0}, errorMessage: {1}".format(uploadImage_toJson["code"],uploadImage_toJson["msg"]))
        exit(1)
        raise Exception("lark Api Error, errorCode: {0}, errorMessage: {1}".format(uploadImage_toJson["code"],uploadImage_toJson["msg"]))


def getLogRecord(ptr):
    logRecordPointer = CloudWatchLogs.get_log_record(
        logRecordPointer=ptr
    )
    return logRecordPointer


def formatLogsUrl(log):
    import re
    import urllib.parse
    pattern = re.findall("[a-zA-z]+://[^\s]*", log)
    if pattern:
        parseResult = urllib.parse.urlparse(pattern[0])
        urlDomain = f"{parseResult.netloc}".replace(".", "-")
        fullDomain = f"{parseResult.scheme}://{parseResult.netloc}"
        log = str(log).replace(fullDomain, urlDomain)
        return log
    else:
        return False


def getMetricImageField():
    items_dict = getItems("Metrics")

    count = 0
    for name, item in items_dict.items():
        item = f'{json.dumps(item)}'
        response = cloudwatch.get_metric_widget_image(
            MetricWidget=item,
            OutputFormat='png'
        )
        if response['ResponseMetadata'].get('HTTPStatusCode') == 200:
            yield {"fileContent": response['MetricWidgetImage'], "fileName": name}


def elMetricMessage(message):
    imageDiv = {
        "tag": "img",
        "img_key": message["image_key"],
        "alt": {
            "tag": "plain_text",
            "content": message["fileName"]
        }
    }
    return imageDiv


def elLogsMessage(queryResult):
    # 列出日志标头
    # 列出倒序排列列前三个日志样本
    # 最大数量：100 ，扫描结果：{len(resultsCount)}
    # 列出 URL (固定)
    # 如果没有错误日志
    # 列出标头
    # 最大数量：100 ，扫描结果：0
    logName = queryResult["logName"]
    results = queryResult["response"]
    itemDetail = queryResult["itemDetail"]

    resultsCount = queryResult["responseCount"]
    resultsCountStr = resultsCount if resultsCount < 100 else f"大于等于 100"

    tmpDiv = {"tag": "div", "text": {"tag": "lark_md", "content": ""}}

    fullLogMessageList = [{"tag": "div", "text": {"tag": "lark_md", "content": f"**{logName}**"}}]

    resultStatistics = [{"tag": "div", "text": {"tag": "lark_md", "content": f"搜索结果：{resultsCountStr}"},
                         "extra": {"tag": "overflow", "options": [
                             {"text": {"tag": "plain_text", "content": "Log Insights URL"}, "value": "document",
                              "url": f"{itemDetail['url']}"}]}}]
    if resultsCount:
        fullLogMessageField = ''

        for i, res in zip(range(3), results["results"]):
            ptr = [field["value"] for field in res if field["field"] == '@ptr'][0]
            fullLog = getLogRecord(ptr)
            log = str(fullLog["logRecord"]["@message"]).strip()
            formatUrl = formatLogsUrl(log)

            fullLogMessageField = formatUrl if formatUrl else log
            # fullLogMessageField += fullLogMessage + " \n"
            tmpDiv["text"]["content"] = fullLogMessageField
            fullLogMessageList.append(tmpDiv)
    fullLogMessageList += resultStatistics
    print(fullLogMessageList)
    return fullLogMessageList



def elInstanceMessage(instancesResult):
    url = instancesResult['URL']
    service = instancesResult["service"]
    RegionName = instancesResult["Region"]
    identifier_list = instancesResult["identifier_list"]

    fullInstancesMessageList = [
        {"tag": "div", "text": {"tag": "lark_md", "content": f"**{RegionName}/{service}**"}},
        {"tag": "div", "text": {"tag": "lark_md", "content": "\n".join(identifier_list)}},
        {"tag": "div", "text": {"tag": "lark_md", "content": f"区域: {RegionName}\t实例: {service}\t数量:{len(identifier_list)}"},
        "extra": {"tag": "overflow", "options": [{"text": {"tag": "plain_text", "content": "Instances URL"}, "value": "document","url": f"{url}"}]}}]

    return fullInstancesMessageList


async def getResult(queryResult):
    count = 0
    while count <= 20:

        response = CloudWatchLogs.get_query_results(
            queryId=queryResult["queryId"]
        )
        if response["status"] == "Complete":
            responseCount = len(response["results"])
            queryResult["responseCount"] = responseCount
            queryResult["response"] = response
            return queryResult
        else:
            await asyncio.sleep(1)

        count += 1


async def getInstanceCount(instanceRegion, services):
    services_info  = getItems("check_count").get(instanceRegion)

    rds = boto3.client('rds', region_name=instanceRegion)
    ec2 = boto3.client('ec2', region_name=instanceRegion)

    instancesResult = dict(identifier_list=[], Region=instanceRegion,service=services, URL=services_info.get(services))

    if services == "RDS":
        db_instances = rds.describe_db_instances()
        for RDSIdentifier in db_instances.get("DBInstances"):
            RDS_state_fields = f"{RDSIdentifier.get('DBInstanceStatus').ljust(16, ' ')} \t{RDSIdentifier.get('DBInstanceIdentifier')}"
            instancesResult["identifier_list"].append(RDS_state_fields)

    if services == "EC2":
        ec2_Response = ec2.describe_instances()
        ec2_instances = [instances for instances in ec2_Response.get("Reservations")]

        for i in ec2_instances:
            InstancesInfo = i.get("Instances")[0]
            for EC2Name in InstancesInfo.get("Tags"):
                if EC2Name.get("Key") == "Name":
                    EC2_state_fields = f"{InstancesInfo.get('State').get('Name').ljust(16, ' ')} \t{EC2Name.get('Value')}"
                    instancesResult["identifier_list"].append(EC2_state_fields)

    return instancesResult


def getItems(itemsKey):
    with open("./items.json", 'r') as load_json:
        try:
            items_dict = json.load(load_json)
            return items_dict[itemsKey]
        except KeyError as keyError:
            print(keyError)
            raise keyError
        except Exception as e:
            print("json file format error")
            raise e


def getAllLogQueryId(items):
    currentTime = int(time.time())

    for logName, itemDetail in items.items():
        res = CloudWatchLogs.start_query(
            logGroupName=logName,
            startTime=currentTime - 60 * 60 * 24,
            endTime=currentTime,
            queryString=itemDetail["queryDetail"],
            limit=100
        )
        if res.get("queryId"):
            yield {"queryId": res.get("queryId"), "logName": logName, "itemDetail": itemDetail}


def getLogTasks(loop):

    tasks = []
    items = getItems('log')
    logQueryId_toList = [queryId for queryId in getAllLogQueryId(items)]

    for queryResult in logQueryId_toList:
        task = loop.create_task(getResult(queryResult))
        tasks.append(task)
    return tasks


def getInstanceCountTasks(loop):
    tasks = []
    items = getItems("check_count")

    for instanceRegion in items:
        for services in items.get(instanceRegion):
            task = loop.create_task(getInstanceCount(instanceRegion,services))
            tasks.append(task)
    return tasks


def getMetricMessageTasks(loop, tenant_access_token):
    tasks = []
    items = getItems('Metrics')

    for BinaryFile in getMetricImageField():
        task = loop.create_task(getImageKey(tenant_access_token, BinaryFile))
        tasks.append(task)
    return tasks


def formatMessage(message):
    if "image_key" in message:
        div = elMetricMessage(message)
    elif "logName" in message:
        # return list
        div = elLogsMessage(message)
    else:
        div = elInstanceMessage(message)
    return div


def sendMessage(elements_list, chat_id):
    imageMessage = dict(chat_id="", msg_type="interactive", update_multi=False, card={
        "config": {
            "wide_screen_mode": True,
        },
        "header": {
            "title": {
                "tag": "plain_text",
                "content": f"{time.strftime('%Y年%m月%d日', time.localtime())} 亚马逊日常巡检"
            }
        },
        "elements": []
    })

    imageMessage["chat_id"] = chat_id
    imageMessage["card"]["elements"] += elements_list

    sendResponse = requests.post(sendMessageUrl, data=json.dumps(imageMessage), headers=header)
    print(sendResponse.content)

def unlock(lock):
    print('callback releasing lock')
    lock.release()

async def asyncmain(event_loop, tasks):
    await asyncio.wait(tasks)


def lambda_handler(event, content):
    startTime = time.time()
    tenant_access_token, chatId_list = getTenantTokenAndChatId()
    print({"tenant_access_token":tenant_access_token, "chatId_list":chatId_list})
    event_loop = asyncio.get_event_loop()

    lock = asyncio.Lock()

    tasks = []
    elements_list = []
    tasks += getMetricMessageTasks(event_loop, tenant_access_token)
    tasks += getLogTasks(event_loop)
    tasks += getInstanceCountTasks(event_loop)

    event_loop.run_until_complete(asyncmain(event_loop, tasks))

    for task in tasks:
        result = task.result()
        element_div = formatMessage(result)
        if isinstance(element_div, list):
            elements_list += element_div
        else:
            elements_list.append(element_div)

    for chat_id in chatId_list:
        # pass
        sendMessage(elements_list, chat_id)

    endTime = time.time()
    print(f"持续时间：{endTime-startTime}")
