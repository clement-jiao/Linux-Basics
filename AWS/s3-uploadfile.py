import os
import json
import boto3
import time
import inspect, re

checkTime = time.strftime("%Y%m%d%H%M%S", time.localtime())

S3Name = "cash"
S3Path = f"clement-test/check/{checkTime}/"
CDNName = "https://d216xxxxxxw55o.cloXXXXXXXt.net/"
WebHookUrl = "https://open.feishu.cn/open-apis/bot/v2/hook/eae5e233-3af5-4468-aXXXXX-ddff3304"

AWS_ACCESS_KEY_ID = ""
AWS_SECRET_ACCESS_KEY = ""

cloudwatch = boto3.client('cloudwatch')
s3 = boto3.client('s3',
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY)


with open("./items.json",'r') as load_json:
    items_dict = json.load(load_json)

for name,item in items_dict["items"].items():
    item = f'{json.dumps(item)}'
    response = cloudwatch.get_metric_widget_image(
            MetricWidget=item,
            OutputFormat='png'
        )

#     if response['ResponseMetadata'].get('HTTPStatusCode') == 200:
#         print('11')
#         with open(f'/home/ec2-user/environment/awsOpenApi/{name}.png','wb') as f:
#             f.write(response['MetricWidgetImage'])



def upload_file(file_name, bucket, object_name=None):
    """Upload a file to an S3 bucket

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = file_name

    # Upload the file
    s3_client = boto3.client('s3')
    try:
        response = s3_client.upload_file(file_name, bucket, object_name)
    except ClientError as e:
        logging.error(e)
        return False
    return True


# dirlist = os.listdir('./')
# print(dirlist)

# for path in dirlist:
#     if 'png' in path:
#         print(path)


def print_files(currentPath):
    lsdir = os.listdir(currentPath)
    directorys = [i for i in lsdir if os.path.isdir(os.path.join(currentPath, i))]
    if directorys:
        for directory in directorys:
            print_files(os.path.join(currentPath, directory))
    files = [i for i in lsdir if os.path.isfile(os.path.join(currentPath,i))]
    for file in files:
        if 'png' in file:
            print(currentPath, file)
            yield (currentPath, file)
        
def sendInfo(cloudfrontUrl):
    pass


# for currentPath,file in print_files('.'):
#     print(currentPath, file)
#     uploadFile = os.path.join(currentPath, file).replace('./','')
#     S3FilePath = f"{S3Path}{uploadFile}"
#     cloudfrontUrl = f"{CDNName}{S3FilePath}"
#     with open(f"{os.path.join(currentPath, file)}", "rb") as f:

#         try:
#             s3.upload_fileobj(f, S3Name, S3FilePath)
#             print(cloudfrontUrl)
#         except Exception as  e:
#             raise e
