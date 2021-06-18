

### template


```json
# GET /_template/* 查看所有

PUT /_template/template-clement
{
  "order": 0,
  "index_patterns": [	# 匹配的索引
    "likes-*"
  ],
  "settings": {
    "index": {
      "number_of_shards": "1",
      "number_of_replicas": "1",
      "opendistro": {
        "index_state_management": {
          "policy_id": "hot_rollover_delete_3M",	# 绑定策略id
          "rollover_alias": "likes"		# 执行 rollover 时的别名，有别于下面 aliases 字段
        }
      }
    }
  },
  "mappings": {		# 索引字段
    "properties": {
      "error_message": {
        "index": "false",
        "type": "text",
        "fields": {
          "keyword": {
            "type": "keyword"
          }
        }
      },
      "country": {
        "index": "true",
        "type": "keyword"
      },
      "campaign_team": {
        "index": "true",
        "type": "keyword"
      },
      "app_version": {
        "index": "true",
        "type": "keyword"
      },
      "photo_id": {
        "type": "keyword"
      },
      "ip": {
        "type": "ip"
      },
      "team": {
        "index": "true",
        "type": "keyword"
      },
      "instagram_id": {
        "index": "true",
        "type": "long"
      },
      "is_auto": {
        "index": "true",
        "type": "keyword"
      },
      "result": {
        "index": "true",
        "type": "keyword"
      },
      "bundle_id": {
        "index": "true",
        "type": "keyword"
      },
      "location": {
        "type": "geo_point"
      },
      "time": {
        "format": "yyyy-MM-dd HH:mm:ss",
        "type": "date"
      },
      "is_bot": {
        "index": "true",
        "type": "keyword"
      },
      "spam": {
        "index": "true",
        "type": "keyword"
      },
      "campaign_id": {
        "index": "true",
        "type": "long"
      }
    }
  },
  "aliases": {}
}
```



### policy

```json
# "policy_id":"hot_rollover_delete_3M" 亚马逊不建议使用该字段，其他可尝试使用

POST /clement-000604
{
  "policy": {
    "policy_id": "hot_rollover_delete_3M",
    "description": "hot rollover delete 3M for likes",
    "last_updated_time": 1622785417311,
    "schema_version": 1,
    "error_notification": null,
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "actions": [],
        "transitions": [
          {
            "state_name": "rollover",
            "conditions": {
              "min_index_age": "1m"
            }
          }
        ]
      },
      {
        "name": "rollover",
        "actions": [
          {
            "rollover": {}
          }
        ],
        "transitions": [
          {
            "state_name": "delete",
            "conditions": {
              "min_index_age": "3m"
            }
          }
        ]
      },
      {
        "name": "delete",
        "actions": [
          {
            "delete": {}
          }
        ],
        "transitions": []
      }
    ]
  }
}
```



关于es的一个博客

[Elasticsearch 技术分析（三）： 索引别名Aliases问题 - JaJian - 博客园 (cnblogs.com)](https://www.cnblogs.com/jajian/p/10152681.html)
