### ES 常用索引

hot_rollover_delete_6M：每月滚动，每六个月删除

```json
{
  "policy": {
    "policy_id": "hot_rollover_delete_6M",
    "description": "Retain 6 months of data",
    "last_updated_time": 1629355963358,
    "schema_version": 1,
    "error_notification": null,
    "default_state": "hot",
    "states": [
      {"name": "hot",
        "actions": [],
        "transitions": [
          {"state_name": "rollover",
            "conditions": {
              "min_index_age": "31d"}
          }]
      },
      {"name": "rollover",
        "actions": [
          {"rollover": {}}
        ],
        "transitions": [
          {"state_name": "delete",
            "conditions": {"min_index_age": "180d"}
          }
        ]
      },
      {"name": "delete",
        "actions": [
          {"delete": {}}
        ],
        "transitions": []
      }
    ],
    "ism_template": null
  }
}
```

hot_rollover_delete_3M：每月滚动，每三个月删除

```json
{
  "policy": {
    "policy_id": "hot_rollover_delete_3M",
    "description": "Retain 3 months of data",
    "last_updated_time": 1623060556707,
    "schema_version": 1,
    "error_notification": null,
    "default_state": "hot",
    "states": [
      {"name": "hot",
        "actions": [],
        "transitions": [
          {"state_name": "rollover",
            "conditions": {"min_index_age": "30d"}
          }
        ]
      },
      {
        "name": "rollover",
        "actions": [
          {"rollover": {}}
        ],
        "transitions": [
          {
            "state_name": "delete",
            "conditions": {"min_index_age": "91d"}
          }
        ]
      },
      {
        "name": "delete",		# 动作名称
        "actions": [	{"delete": {}	 }],	# 执行的动作
        "transitions": []		# 触发条件
      }
    ],
    "ism_template": [
      {
        "last_updated_time": 1626052627577,
        "index_patterns": ["likes-*"],		# 匹配的策略
        "priority": 1		# 策略应用优先级
      },
      {
        "last_updated_time": 1626052627577,
        "index_patterns": ["follows-*"],
        "priority": 2
      },
      {
        "last_updated_time": 1626052627577,
        "index_patterns": ["clement-*"],
        "priority": 3
      }
    ]
  }
}
```

hot_rollover_20G：数据永久保留，每20G滚动一次

```json
{
  "policy": {
    "policy_id": "hot_rollover_20G",
    "description": "Reach 20Gb Rollover",
    "last_updated_time": 1631866647040,
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
            "conditions": {"min_size": "20gb"}
          }
        ]
      },
      {
        "name": "rollover",
        "actions": [
          {"rollover": {}}
        ],
        "transitions": []
      }
    ],
    "ism_template": [
      {
        "index_patterns": [
          "devclement-*",
          "dynamo-user-*"
        ],
        "priority": 51,
        "last_updated_time": 1629349501858
      }
    ]
  }
}
```

hot_persistent_data：永久保留数据

```json
{
  "policy": {
    "policy_id": "hot_persistent_data",
    "description": "hot Persistent Data",
    "last_updated_time": 1630317327593,
    "schema_version": 1,
    "error_notification": null,
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "actions": [],
        "transitions": []
      }
    ],
    "ism_template": [
      {
        "index_patterns": [
          "filebeat-*",
          "dynamo-*",
          "serverlogs-config-*"
        ],
        "priority": 50,
        "last_updated_time": 1626052627577
      }
    ]
  }
}
```

