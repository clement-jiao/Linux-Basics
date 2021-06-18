import os
import time
import json
import boto3
import requests
from icecream import ic
ic()

cloudwatch = boto3.client('cloudwatch')

putImageUrl = "https://open.feishu.cn/open-apis/image/v4/put/"
getChatlistUrl = "https://open.feishu.cn/open-apis/chat/v4/list"
sendMessageUrl = "https://open.feishu.cn/open-apis/message/v4/send/"
accessTokenUrl = "https://open.feishu.cn/open-apis/auth/v3/app_access_token/internal/"


# app_id = os.environ["app_id"]
# app_secret = os.environ["app_secret"]

app_id = 'cli_a0b6f91bba78100c'
app_secret = 'j5WOF9FtdDXXqbIaeDlK0bHk70B2bB7V'

data = {"app_id": app_id,"app_secret": app_secret}
header = {
    "Content-Type": "application/json; charset=utf-8",
    "Authorization": ""
}

def getTenantTokenAndChatId():
    """
    getChatlist_toJosn: {'code': 0,
        'data': {'groups': [{'avatar': 'https://p1-lark-file.byteimg.com/img/lark.avatar/ace6a05d-a838-490b-afe0-4e8e4fc905bg~100x100.jpg',
                              'chat_id': 'oc_6e599c90e4dc717462ff28dd545870c3',
                              'description': '',
                              'name': '111',
                              'owner_open_id': 'ou_baacdca85aa06260618d0acb7b13b992',
                              'owner_user_id': '1957a542'}],
                  'has_more': False,
                  'page_token': '0'},
         'msg': 'ok'}
    """
    
    tenant_access_token_Response = requests.get(accessTokenUrl,params=data, headers=header)
    tenant_access_token_Response_toJson = tenant_access_token_Response.json()
    tenant_access_token = tenant_access_token_Response_toJson["tenant_access_token"] if tenant_access_token_Response_toJson.get("code") == 0 else None
    
    getChatlistUrlParam = {"page_size":100}
    header["Authorization"] = f"Bearer {tenant_access_token}"
    
    getChatlist = requests.get(getChatlistUrl, params=getChatlistUrlParam, headers=header)
    getChatlist_toJosn = getChatlist.json()

    groups = getChatlist_toJosn.get("data", {}).get("groups", None)
    if groups:
        chatId_list = [chat_id.get("chat_id", None) for chat_id in groups]
        return (tenant_access_token, chatId_list)


def getImageKey(tenant_access_token, binaryFile):
    
    uploadImageResponse = requests.post(putImageUrl, data={"image_type": "message"}, files={"image":binaryFile}, headers={"Authorization": f"Bearer {tenant_access_token}"}, stream=True)
    uploadImageResponse.raise_for_status()
    uploadImage_toJson = uploadImageResponse.json()
    
    if uploadImage_toJson.get("code", None) == 0 and uploadImage_toJson.get("msg", None) == "ok":
        return uploadImage_toJson.get("data", {}).get("image_key")
    else:
        raise Exception("Call Api Error, errorCode is %s" % uploadImage_toJson["code"])


def getImageBinaryFile():
    with open("./items.json",'r') as load_json:
        try:
            items_dict = json.load(load_json)
        except Exception as e:
            print("json file format error")
            raise e
        
    for name,item in items_dict["items"].items():
        item = f'{json.dumps(item)}'
        response = cloudwatch.get_metric_widget_image(
                MetricWidget=item,
                OutputFormat='png'
            )
    
        if response['ResponseMetadata'].get('HTTPStatusCode') == 200:
            yield {"fileContent": response['MetricWidgetImage'], "fileName":name}
            

def sendMessage(message):
    sendResponse = requests.post(sendMessageUrl, data=json.dumps(message), headers=header)


def elMessage(tenant_access_token):
    # elements list message
    for BinaryFile in getImageBinaryFile():
        imageKey = getImageKey(tenant_access_token, BinaryFile["fileContent"])

        imageDiv = {
            "tag": "img",
            "img_key": imageKey,
            "alt": {
                "tag": "plain_text",
                "content": BinaryFile["fileName"]
            }
        }
        
        # imageMessage["card"]["elements"].append(imageDiv)
        yield imageDiv 


def lambda_handler(event, context):
    tenant_access_token, chatId_list = getTenantTokenAndChatId()
    elements_list = [el for el in elMessage(tenant_access_token)]
    imageMessage = {
            "chat_id": "",
            "msg_type": "interactive",
            "update_multi": False,
            "card": {
                "elements": [
                        {
                        "tag": "div",
                        "text": {
                            "tag": "lark_md",
                            "content": f"**{time.strftime('%Y年%m月%d日', time.localtime())}亚马逊日常巡检**"
                            }
                        }
                    ]
                }
        }
    for chat_id in chatId_list:
        imageMessage["chat_id"] = chat_id
        imageMessage["card"]["elements"] += elements_list

        sendMessage(imageMessage)
        ic()
    ic()
lambda_handler(1,2)